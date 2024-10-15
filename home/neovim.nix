{config, pkgs, ...}: 
let 
   neovim-like-vscode = ./dotfiles/.nvim
in
{
   programs.neovim = {
	    enable = true;
  	    defaultEditor = true;
	    viAlias = true;
	    vimAlias = true;
            extraConfig = builtins.readFile "${neovim-like-vscode}/init.vim";
            plugins = with pkgs.vimPlugins; [
		neo-tree-nvim
	  	tmux-nvim
	    	];
  }; 
}
