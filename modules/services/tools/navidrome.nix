{ ... }:
{
  # Music stack on kaito:
  #   Lidarr  - library manager / metadata (root: /mnt/audio/music/lidarr)
  #   slskd   - Soulseek client, download source for Aurral
  #   Aurral  - discovery + requests, drives Lidarr and slskd
  #   Navidrome / Jellyfin - playback servers reading the same folders
  # Integrations that only exist in the apps' databases are provisioned by
  # music-provision.nix. All credentials live in agenix secrets.
  flake.modules.nixos.navidrome = { config, lib, pkgs, ... }:
    let
      secret = name: ../../../secrets + "/${name}.age";
      # Optional until the Last.fm API account exists, see secrets/secrets.nix.
      hasLastfm = builtins.pathExists (secret "music-lastfm");

      musicDir = "/mnt/audio/music";
      aurralDir = "/mnt/audio/aurral";
      slskdDir = "/mnt/audio/slskd";

      proxy = port: {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
        };
      };
    in
    {
      age.secrets = {
        # LIDARR__AUTH__APIKEY (Lidarr) + LIDARR_API_KEY (Aurral), same key.
        music-lidarr-api.file = secret "music-lidarr-api";
        # SLSKD_SLSK_USERNAME/PASSWORD, SLSKD_USERNAME/PASSWORD, SLSKD_API_KEY.
        music-slskd.file = secret "music-slskd";
        # Web UI logins used by music-provision.
        music-credentials.file = secret "music-credentials";
      } // lib.optionalAttrs hasLastfm {
        # ND_LASTFM_APIKEY/ND_LASTFM_SECRET (Navidrome) + LASTFM_API_KEY/LASTFM_API_SECRET (Aurral).
        music-lastfm.file = secret "music-lastfm";
      };

      services.navidrome = {
        enable = true;
        openFirewall = true;
        environmentFile = lib.mkIf hasLastfm config.age.secrets.music-lastfm.path;

        settings = {
          Address = "0.0.0.0";
          MusicFolder = musicDir;
        };

        plugins = with pkgs.navidromePlugins; [
          listenbrainz-daily-playlist
        ];
      };

      # Navidrome runs chrooted with only MusicFolder bound; Aurral registers
      # its download folder as a second Navidrome library.
      systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = [ aurralDir ];

      services.lidarr = {
        enable = true;
        openFirewall = false;
        environmentFiles = [ config.age.secrets.music-lidarr-api.path ];
        settings = {
          server.bindaddress = "127.0.0.1";
          auth = {
            method = "Forms";
            required = "Enabled";
          };
        };
      };

      services.slskd = {
        enable = true;
        # Soulseek peer port (50300); forward it on the router for best speeds.
        openFirewall = true;
        domain = null;
        environmentFile = config.age.secrets.music-slskd.path;
        settings = {
          directories = {
            downloads = "${slskdDir}/downloads";
            incomplete = "${slskdDir}/incomplete";
          };
          # Sharing keeps peers from blocking us as a leecher.
          shares.directories = [ musicDir ];
        };
      };

      # Aurral moves finished downloads out of slskd's folder: group-writable.
      systemd.services.slskd.serviceConfig.UMask = "0002";

      services.aurral = {
        enable = true;
        port = 3001;
        openFirewall = false;

        dataDir = "/var/lib/aurral";

        # Read Lidarr's library and pick up slskd downloads.
        directories = [ musicDir slskdDir ];

        # Kept outside musicDir so Navidrome/Jellyfin don't index it twice.
        environment = {
          DOWNLOAD_FOLDER = aurralDir;
          TRUST_PROXY = "true";
          AURRAL_PUBLIC_URL = "https://aurral.inspiravita.com";
        };
        environmentFile = config.age.secrets.music-lidarr-api.path;
      };

      systemd.services.aurral.serviceConfig.EnvironmentFile =
        lib.optional hasLastfm config.age.secrets.music-lastfm.path;

      services.jellyfin = {
        enable = true;
        openFirewall = false;
      };

      users.users = {
        navidrome.extraGroups = [ "aurral" "lidarr" ];
        jellyfin.extraGroups = [ "aurral" "lidarr" ];
        aurral.extraGroups = [ "lidarr" "slskd" ];
      };

      systemd.tmpfiles.rules = [
        # Shared parent must be root-owned, otherwise tmpfiles refuses to create
        # the service-owned folders below it ("unsafe path transition").
        "d /mnt/audio 0755 root root -"
        "d ${musicDir}/lidarr 0755 lidarr lidarr -"
        "d ${slskdDir} 2770 slskd slskd -"
        "d ${slskdDir}/downloads 2770 slskd slskd -"
        "d ${slskdDir}/incomplete 2770 slskd slskd -"
      ];

      services.nginx = {
        enable = true;
        virtualHosts = {
          "navidrome.inspiravita.com" = proxy 4533;
          "jellyfin.inspiravita.com" = proxy 8096;
          "aurral.inspiravita.com" = proxy 3001;
          "lidarr.inspiravita.com" = proxy 8686;
        };
      };

      environment.systemPackages = [ pkgs.rsync ];

      security.sudo.extraRules = [{
        users = [ "casper" ];
        runAs = "navidrome";
        commands = [{
          command = "/run/current-system/sw/bin/rsync";
          options = [ "NOPASSWD" ];
        }];
      }];
    };
}
