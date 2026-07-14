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

    # Allow the CD-rip watcher on the laptop to push finished albums into
    # navidrome's music folder over ssh. It rsyncs as user casper and
    # invokes rsync on this host through `sudo -n -u navidrome` so files
    # land owned by the navidrome user directly.
    environment.systemPackages = [ pkgs.rsync ];
    security.sudo.extraRules = [{
      users = [ "casper" ];
      runAs = "navidrome";
      commands = [{
        command = "${pkgs.rsync}/bin/rsync";
        options = [ "NOPASSWD" ];
      }];
    }];
  };
}
