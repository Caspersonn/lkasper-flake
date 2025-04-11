{config, unstable, pkgs, lib, ...}:
{
  environment.systemPackages = with pkgs; [
    (retroarch.override {
      cores = with libretro; [
        snes9x
        citra
      ];
    })
  ];
}
