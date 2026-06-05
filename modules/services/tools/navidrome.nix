{ config, ... }: {
flake.modules.nixos.navidrome = {
    services.navidrome = {
      enable = true;
      settings.MusicFolder = "/mnt/audio/music";
    };
  };
}
