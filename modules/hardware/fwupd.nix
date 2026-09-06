{ inputs, ... }: {
  flake.modules.nixos.hardware-fwupd = { config, pkgs, ... }: {
    services.fwupd.enable = true;
  };
}
