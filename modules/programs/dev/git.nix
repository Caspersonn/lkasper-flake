{ inputs, ... }: {
  flake.modules.nixos.dev-git = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ gh git-sync ];
  };
}
