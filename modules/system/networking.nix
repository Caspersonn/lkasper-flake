{ inputs, ... }: {
  flake.modules.nixos.networking = { config, pkgs, ... }: {
    networking.networkmanager.enable = true;
    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [ 5432 ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    networking.firewall.enable = true;

  };
}
