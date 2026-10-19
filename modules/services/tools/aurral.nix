{ ... }:
{
  # Discovery + requests; drives Lidarr and slskd, publishes to Navidrome/Jellyfin.
  flake.modules.nixos.aurral = { config, lib, ... }:
    let
      lastfmSecret = ../../../secrets/music-lastfm.age;
      # Optional until the Last.fm API account exists, see secrets/secrets.nix.
      hasLastfm = builtins.pathExists lastfmSecret;

      # Kept outside /mnt/audio/music so Navidrome/Jellyfin don't index it twice.
      aurralDir = "/mnt/audio/aurral";
      players = lib.filter (u: config.services.${u}.enable) [ "navidrome" "jellyfin" ];
    in
    {
      age.secrets = {
        # LIDARR_API_KEY
        music-lidarr-api.file = ../../../secrets/music-lidarr-api.age;
      } // lib.optionalAttrs hasLastfm {
        # LASTFM_API_KEY / LASTFM_API_SECRET
        music-lastfm.file = lastfmSecret;
      };

      services.aurral = {
        enable = true;
        port = 3001;
        openFirewall = false;

        dataDir = "/var/lib/aurral";

        # Read Lidarr's library and pick up slskd downloads.
        directories = [ "/mnt/audio/music" "/mnt/audio/slskd" ];

        environment = {
          DOWNLOAD_FOLDER = aurralDir;
          TRUST_PROXY = "true";
          AURRAL_PUBLIC_URL = "https://aurral.inspiravita.com";
        };
        environmentFile = config.age.secrets.music-lidarr-api.path;
      };

      systemd.services.aurral.serviceConfig.EnvironmentFile =
        lib.optional hasLastfm config.age.secrets.music-lastfm.path;

      # Navidrome runs chrooted with only MusicFolder bound; Aurral registers
      # its download folder as a second Navidrome library.
      systemd.services.navidrome.serviceConfig.BindReadOnlyPaths =
        lib.mkIf config.services.navidrome.enable [ aurralDir ];

      users.users = lib.genAttrs players (_: { extraGroups = [ "aurral" ]; }) // {
        aurral.extraGroups =
          lib.optional config.services.lidarr.enable "lidarr"
          ++ lib.optional config.services.slskd.enable "slskd";
      };

      # See slskd.nix: DOWNLOAD_FOLDER is created below this shared parent.
      systemd.tmpfiles.settings."10-audio-root"."/mnt/audio".d = {
        user = "root";
        group = "root";
        mode = "0755";
      };

      services.nginx = {
        enable = true;
        virtualHosts."aurral.inspiravita.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3001";
            proxyWebsockets = true;
          };
        };
      };
    };
}
