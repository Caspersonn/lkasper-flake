{ pkgs, ... }: {
  virtualisation = {
    podman = {
      enable = true;
    };
  };

  environment.systemPackages = [
    pkgs.distrobox
    # pkgs.podman-tui # optional
    # pkgs.distrobox-tui # optional 
  ];
}
