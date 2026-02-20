{ inputs, ... }: {
  flake.modules.nixos.lact = { config, pkgs, ... }: {
    services.lact.enable = true;
  };
}
