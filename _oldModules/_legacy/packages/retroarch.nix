{config, unstable, pkgs, lib, ...}:
{
  environment.systemPackages = with pkgs; [
    (retroarch.withCores (cores: with cores; [
      snes9x
      citra
      desmume
      melonds
    ]))
  ];
}
#{
#  environment.systemPackages = with pkgs; [
#    (retroarch.override {
#      cores = with libretro; [
#        snes9x
#        citra
#        desmume
#        melonds
#      ];
#    })
#  ];
#}
