{hostname, ...}: {
  imports = [

    ../../hosts/${hostname}

    # Core
    ../../modules/packages/pkgs-essentials.nix
    ../../modules/packages/pkgs-technative.nix
    ../../modules/packages/bambu-labs.nix

    # Services
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix
    ../../modules/services/service-docker.nix
    ../../modules/services/service-redis_psql_twenty.nix
    ../../modules/services/service-openvpn.nix

    # Etc
    ../../modules/etc/secrets.nix
    ../../modules/etc/udev-ddcutil.nix
  ];
}


