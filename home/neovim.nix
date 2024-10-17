{config, pkgs, ...}: 
let 
   neovim-like-vscode = ./dotfiles/.nvim;
in
{
   programs.neovim = {
	    enable = true;
  	    defaultEditor = true;
	    viAlias = true;
	    vimAlias = true;
        extraConfig = ''
	source ${neovim-like-vscode}/init.vim
          nnoremap <space>a :qa!<cr>
          nnoremap <space>t :Telescope terraform_doc full_name=hashicorp/aws<cr>
        '';
            plugins = with pkgs.vimPlugins; [
		neo-tree-nvim
	  	tmux-nvim
	    	];
  };
}
