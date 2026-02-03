{ inputs, ... }: {
  flake.modules.nixos.bluetooth = { config, pkgs, ... }: {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
  };
}
