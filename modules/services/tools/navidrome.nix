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
  };
}
