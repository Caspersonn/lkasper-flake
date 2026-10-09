{ ... }: {
  flake.modules.nixos.fonts = { config, lib, pkgs, ... }:
    let
    SymbolsCustomNerdFont = pkgs.callPackage ./_package.nix { inherit pkgs; };
    in {

    fonts = {
      packages = [
        SymbolsCustomNerdFont
      ];
    };
  };
}

