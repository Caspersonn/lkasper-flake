{ hostname, ...}: {
  imports = [

    ../../hosts/${hostname}

    # Core
    ../../modules/packages/pkgs-essentials.nix

    # Services
    ../../modules/services/service-resolved.nix
    ../../modules/services/service-tailscale.nix
    ../../modules/services/service-docker.nix
    ../../modules/services/service-smb.nix
    ../../modules/services/service-vaultwarden.nix
    ../../modules/services/service-syncthing_server.nix
    ../../modules/services/service-atuin.nix
    ../../modules/services/service-mailserver.nix

    # Etc
    ../../modules/etc/secrets.nix
  ];
}

