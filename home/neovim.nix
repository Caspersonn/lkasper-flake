{config, pkgs, ...}: {

   programs.neovim = {
	    enable = true;
  	    defaultEditor = true;
	    viAlias = true;
	    vimAlias = true;
		plugins = with pkgs.vimPlugins; [
		     neo-tree-nvim
			 tmux-nvim
			 (pkgs.vimUtils.buildVimPlugin {
               pname = "neovim-like-vscode";
               version = "1.0.0";
               src = pkgs.fetchFromGitHub {
                owner = "josethz00";
                repo = "neovim-like-vscode";
                rev = "main";  # Specify the branch or commit hash
                sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Replace with actual sha256
               };
            })
		];
	}; 
}

