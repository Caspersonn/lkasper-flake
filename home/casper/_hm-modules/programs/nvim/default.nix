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
      programs.neovim.withNodeJs = true;
    }
