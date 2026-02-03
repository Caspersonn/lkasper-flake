{ inputs, ... }: {
  flake.modules.nixos.nixpkgs = { config, pkgs, ... }: {
    nixpkgs.config.allowUnfree = true;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  };
}
