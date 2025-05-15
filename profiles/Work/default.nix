{hostname, ...}: {
  imports = [

    ../../hosts/${hostname}

    # Core
    ../../modules/packages/pkgs-essentials.nix
    ../../modules/packages/pkgs-technative.nix

    # Services
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix
    ../../modules/services/service-docker.nix
    ../../modules/services/service-smb.nix

    # Etc
    ../../modules/secrets-casper.nix
    ../../modules/udev-ddcutil.nix
  ];
}


