{ config, ... }: {
flake.modules.nixos.navidrome = {pkgs, ...}: {
    services.navidrome = {
      enable = true;
      settings.MusicFolder = "/mnt/audio/music";
      plugins = with pkgs; [
          listenbrainz-daily-playlist
      ];
    };
  };
}
