{hostname, ...}: {
  imports = [

    ../../hosts/${hostname}

    # Core
    ../../modules/packages/pkgs-essentials.nix
    ../../modules/packages/pkgs-technative.nix

    # Services
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix

    # Etc
    ../../modules/secrets-casper.nix
  ];
}


