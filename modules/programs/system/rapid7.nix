{ inputs, ... }: {
  flake.modules.nixos.rapid7 = { config, pkgs, ... }: {
    services.rapid7.enable = true;
  };
}
