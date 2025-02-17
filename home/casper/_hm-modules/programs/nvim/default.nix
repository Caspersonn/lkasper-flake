{config, pkgs, ...}: 
let 
  nvim = ./nvim-conf;
in
  {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withPython3 = true;
      withNodeJs = true;
      extraConfig = ''
          source ${nvim}/plug.vim
          source ${nvim}/neovim.vim
          nnoremap <space>a :qa!<cr>
          nnoremap <space>t :NERDTree<cr>
          nnoremap <space>f :Ag<cr>
      '';
      plugins = with pkgs.vimPlugins; [
      ];
    };

    home.packages = [
      pkgs.terraform-ls
    ];

    home.file = {
      ".config/nvim/coc-settings.json" = {
        source = "${nvim}/coc-settings.json";
        recursive = false;
      }; 
    };
  }
