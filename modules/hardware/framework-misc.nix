{ inputs, ... } : {
  flake.modules.nixos.framework-misc = { config, pkgs, ... }: {

    hardware.sensor.iio.enable = false;
    hardware.framework.amd-7040.preventWakeOnAC = true;

  };
}
