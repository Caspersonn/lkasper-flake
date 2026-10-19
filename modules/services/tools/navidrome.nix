{ ... }:
{
  flake.modules.nixos.navidrome = { config, lib, pkgs, ... }:
    let
      lastfmSecret = ../../../secrets/music-lastfm.age;
      # Optional until the Last.fm API account exists, see secrets/secrets.nix.
      hasLastfm = builtins.pathExists lastfmSecret;
    in
    {
      # ND_LASTFM_APIKEY / ND_LASTFM_SECRET
      age.secrets = lib.optionalAttrs hasLastfm {
        music-lastfm.file = lastfmSecret;
      };

      services.navidrome = {
        enable = true;
        openFirewall = true;
        environmentFile = lib.mkIf hasLastfm config.age.secrets.music-lastfm.path;

        settings = {
          Address = "0.0.0.0";
          MusicFolder = "/mnt/audio/music";
        };

        plugins = with pkgs.navidromePlugins; [
          listenbrainz-daily-playlist
        ];
      };

      services.nginx = {
        enable = true;
        virtualHosts."navidrome.inspiravita.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:4533";
            proxyWebsockets = true;
          };
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
