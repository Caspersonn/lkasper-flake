{ inputs, ... }: {
  flake.modules.nixos.flatpak = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ flatpak ];

    services.flatpak.enable = true;
  };
}
