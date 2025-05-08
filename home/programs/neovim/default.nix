{ pkgs,unstable, ... }:

{
  programs.neovim = {
    enable = true;
    package = unstable.neovim-unwrapped;
    defaultEditor = true;
  };

  home.file = {
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };
  };

  home.packages = [
    #    pkgs.lua51Packages.lua
    #    pkgs.luajitPackages.magick
    #    pkgs.lua51Packages.luarocks
    pkgs.gnumake
    pkgs.gcc
    pkgs.pkg-config
    pkgs.smug
    pkgs.typescript-language-server
    pkgs.lua-language-server

    pkgs.nil
    pkgs.terraform-ls
    pkgs.silver-searcher
    pkgs.fzf
    pkgs.ripgrep
  ];
}
