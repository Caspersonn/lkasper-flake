{ hostname, ...}: {
  imports = [

    ../../hosts/${hostname}

    # Core
    ../../modules/packages/pkgs-gaming.nix
    ../../modules/packages/pkgs-essentials.nix
    ../../modules/packages/pkgs-technative.nix
    ../../modules/packages/pkgs-gui.nix
    ../../modules/packages/steam.nix

    # Services
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix
    ../../modules/services/service-syncthing_client.nix

    # Etc
    ../../modules/etc/secrets.nix
  ];
}


