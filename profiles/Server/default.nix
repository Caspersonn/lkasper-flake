{ hostname, ...}: {
  imports = [

    ../../hosts/${hostname}

    # Core 
    ../../modules/packages/pkgs-gaming.nix
    ../../modules/packages/pkgs-essentials.nix
    ../../modules/packages/steam.nix

    # Services
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix
    ../../modules/services/service-docker.nix
    ../../modules/services/service-smb.nix
    ../../modules/services/service-vaultwarden.nix

    # Etc
    ../../modules/secrets-casper.nix
  ];
}

