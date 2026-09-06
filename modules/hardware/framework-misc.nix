{ inputs, ... } : {
  flake.modules.nixos.hardware-frameworkmisc = { config, pkgs, ... }: {

    hardware.sensor.iio.enable = false;
    hardware.framework.amd-7040.preventWakeOnAC = true;

  };
}
