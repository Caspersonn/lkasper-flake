{ inputs, ... }: {
  flake.modules.nixos.hardware-fwupd = { config, pkgs, unstable, ... }: {
    services.fwupd = {
      enable = true;
      package = unstable.fwupd;
    };
  };
}
