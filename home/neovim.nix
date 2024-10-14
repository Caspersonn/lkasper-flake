{config, pkgs, ...}: {

    neovim = {
	    enable = true;
  	    defaultEditor = true;
	    viAlias = true;
	    vimAlias = true;
		plugins = with pkgs.vimPlugins; [
		     neo-tree-nvim
			 tmux-nvim
		];
	}; 
}

