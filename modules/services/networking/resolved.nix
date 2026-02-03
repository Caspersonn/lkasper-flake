{ inputs, ... }: {
  flake.modules.nixos.resolved = { config, pkgs, ... }: {
    services.resolved.enable = true;
  };
}
