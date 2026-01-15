{hostname, ...}: {
  config.bambuStudio.enable = true;
  imports = [

    ../../hosts/${hostname}

    # Core
    ../../modules/packages/pkgs-essentials.nix
    ../../modules/packages/pkgs-technative.nix
    ../../modules/packages/pkgs-gui.nix
    ../../modules/packages/bambu-labs.nix
    ../../modules/packages/nix-ld.nix
    ../../modules/packages/chromium.nix

    # Services
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix
    ../../modules/services/service-docker.nix
    ../../modules/services/service-redis_psql_twenty.nix
    ../../modules/services/service-openvpn.nix
    ../../modules/services/service-wireguard.nix
    ../../modules/services/service-neo4j.nix
    ../../modules/services/service-printing.nix

    # Etc
    ../../modules/etc/secrets.nix
    ../../modules/etc/udev-ddcutil.nix
  ];
}


