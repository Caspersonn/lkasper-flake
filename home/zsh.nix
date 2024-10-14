{config,pkgs,...}: {

programs.zsh = {
	enable = true;
    enableAutosuggestions = true;
	zsh-autoenv.enable = true;
    syntaxHighlighting.enable = true;
	 
	oh-my-zsh = {
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

