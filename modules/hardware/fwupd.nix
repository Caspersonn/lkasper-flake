{ inputs, ... }: {
  flake.modules.nixos.fwupd = { config, pkgs, ... }: {
    services.fwupd.enable = true;
  };
}
