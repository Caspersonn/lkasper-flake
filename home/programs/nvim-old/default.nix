{config, pkgs, ...}:
let
  nvim = ./nvim;
in
  {
    #    programs.neovim = {
    #      enable = true;
    #      defaultEditor = true;
    #      viAlias = true;
    #      vimAlias = true;
    #      withPython3 = true;
    #      withNodeJs = true;
    #      extraConfig = ''
    #          source ${nvim}/plug.vim
    #          source ${nvim}/neovim.vim
    #          source ${nvim}/init.lua
    #
    #      '';
    #      plugins = with pkgs.vimPlugins; [
    #        lazy-nvim
    #        vim-plug
    #      ];
    #      extraLuaPackages = ps: [ ps.magick ];
    #      extraPackages = [ pkgs.imagemagick ];
    #    };
    #
    #
    #
    #    home.packages = [
    #      pkgs.terraform-ls
    #    ];
    #
    #    home.file = {
    #      ".config/nvim/coc-settings.json" = {
    #        source = "${nvim}/coc-settings.json";
    #        recursive = false;
    #      };
    #    };
  }
