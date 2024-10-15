{config,pkgs,...}: {

programs.zsh = {
	enable = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
	interactiveShellInit = ''
    export SHELL=${pkgs.zsh}/bin/zsh
    ''; 
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

