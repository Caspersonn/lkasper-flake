{config, pkgs, ...}

    neovim = {
	    enable = true;
  	    defaultEditor = true;
        extraConfig = lib.fileContents ~../home/dotfiles/init.vim;
	    viAlias = true;
	    vimAlias = true;
		plugins = with pkgs.vimPlugins; 
		   [
		     neo-tree-nvim
		     tmux-nvim 
		   ];
	      }; 
