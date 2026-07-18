{ config, ... }: {
flake.modules.nixos.navidrome = {pkgs, ...}: {
    services.navidrome = {
      enable = true;
      openFirewall = true;
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
