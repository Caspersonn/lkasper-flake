{ inputs, pkgs, unstable, ... }:

{

 home.packages = [
    inputs.nixvim.packages.x86_64-linux.default
];
  home.sessionVariables.EDITOR = "nvim";
  #  programs.neovim = {
  #    enable = true;
  #    package = unstable.neovim-unwrapped;
  #    defaultEditor = true;
  #
  #    # Image nvim
  #    extraLuaPackages = ps: [ ps.magick ];
  #    extraPackages = [ pkgs.imagemagick ];
  #  };
  #
  #  home.file = {
  #    ".config/nvim" = {
  #      source = ./nvim;
  #      recursive = true;
  #    };
  #  };
  #
  #  # Development tools and language servers
  #  home.packages = [
  #    # Build tools
  #    pkgs.gnumake
  #    pkgs.gcc
  #    pkgs.pkg-config
  #
  #    # Language servers
  #    pkgs.typescript-language-server
  #    pkgs.lua-language-server
  #    pkgs.nil                      # Nix language server
  #    pkgs.terraform-ls
  #    pkgs.pyright
  #    pkgs.typst
  #    pkgs.beamMinimal27Packages.elixir-ls
  #    pkgs.crystalline
  #
  #    # Search and navigation tools
  #    pkgs.silver-searcher
  #    pkgs.fzf
  #    pkgs.ripgrep
  #    pkgs.smug
  #  ];
}
