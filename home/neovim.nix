{config, pkgs, ...}: 
let 
  nvim = ./dotfiles/.nvim;
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
          source ${nvim}/init.lua
          nnoremap <space>a :qa!<cr>
          nnoremap <space>t :NERDTree<cr>
        '';
        plugins = with pkgs.vimPlugins; [
        ];
      };
    }
