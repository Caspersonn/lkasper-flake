{config,pkgs,...}: {

programs.zsh = {
	enable = true;
    autosuggestion.enable = true;
	syntaxHighlighting.enable = true;
	shellAliases = {
    tfplan = "$HOME/git/wearetechnative/race/tfplan.sh";
	tfswitch = "tfswitch -b $HOME/bin/terraform";
	tfapply = "$HOME/git/wearetechnative/race/tfapply.sh";
	tfinit = "$HOME/git/wearetechnative/race/tfinit";
	tfdestroy = "$HOME/git/wearetechnative/race/tfdestroy.sh";
	};
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

