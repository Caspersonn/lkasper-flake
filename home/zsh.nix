{config, pkgs, ...}: {

programs.zsh = {
	enable = true;
    autosuggestions.enable = true;
	  zsh-autoenv.enable = true;
      syntaxHighlighting.enable = true;
	 
	  ohMyZsh = {
        enable = true;
		theme = "robbyrussell";
		plugins = [
		  "git"
		  "aws"
		  "fzf"
		  "node"
		  "autojump"
		  "dirhistory"
		  ];
        };
	};
}

