{ hostname, ...}: {
  imports = [

    ../../hosts/${hostname}

    # Core
    ../../modules/packages/pkgs-gaming.nix
    ../../modules/packages/pkgs-essentials.nix
    ../../modules/packages/steam.nix

    # Services
    ../../modules/services/service-coolerd.nix
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix
    ../../modules/services/service-syncthing_client.nix

    # Etc
    ../../modules/etc/udev-skylanders-portal.nix
    ../../modules/etc/secrets.nix
    ../../modules/etc/udev-ddcutil.nix
    ../../modules/etc/udev-steering-logitech.nix
  ];
}


