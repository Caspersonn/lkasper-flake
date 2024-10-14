{config,pkgs,...}: {

programs.zsh = {
	enable = true;
    enableAutosuggestions = true;
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

