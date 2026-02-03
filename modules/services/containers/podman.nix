{ inputs, ... }: {
  flake.modules.nixos.podman = { pkgs, ... }: {
    virtualisation.podman.enable = true;

    environment.systemPackages = [ pkgs.distrobox ];
  };
}
