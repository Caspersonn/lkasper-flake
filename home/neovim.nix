{config, pkgs, ...}: {

    neovim = {
	    enable = true;
  	    defaultEditor = true;
	    viAlias = true;
	    vimAlias = true;
		plugins = with pkgs.vimPlugins; [
		     neo-tree-nvim
			 tmux-nvim
		     (pkgs.vimPlugins.buildVimPlugin {
               pname = "neovim-like-vscode";
                version = "1.0.0";  # You can update this with the actual version or commit hash you want
                src = pkgs.fetchFromGitHub {
                  owner = "josethz00";
                  repo = "neovim-like-vscode";
                  rev = "main";  # or a specific commit hash
                  sha256 = "sha256-16sgvv5h7fkkf0qc2k5k9fzdkip8ssk4zmzw30i1i9q170p1rnhv";  # replace this with the actual sha256 value
             };
            })
		];
	}; 
}

