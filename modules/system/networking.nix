{ inputs, ... }: {
  flake.modules.nixos.networking = { config, pkgs, ... }: {
    networking.networkmanager.enable = true;
    networking.firewall.enable = false;
  };
}
