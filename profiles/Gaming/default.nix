{ hostname, ...}: {
  imports = [

    ../../hosts/${hostname}

    # Core 
    ../../modules/packages/pkgs-gaming.nix
    ../../modules/packages/pkgs-essentials.nix
    ../../modules/packages/steam.nix
    ../../modules/packages/retroarch.nix

    # Services
    ../../modules/services/service-coolerd.nix
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix

    # Etc
    ../../modules/udev-skylanders-portal.nix
    ../../modules/secrets-casper.nix
  ];
}


