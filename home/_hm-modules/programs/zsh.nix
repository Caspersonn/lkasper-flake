{config,pkgs,...}: 
let
  zoxide = ./../../conf-dotfiles/zsh;
in
{

programs.zsh = {
	enable = true;
    autosuggestion.enable = true;
	syntaxHighlighting.enable = true;
	shellAliases = {
    tfplan = "$HOME/git/wearetechnative/race/tfplan.sh";
	tfswitch = "tfswitch -b $HOME/bin/terraform";
	tfapply = "$HOME/git/wearetechnative/race/tfapply.sh";
	tfdestroy = "$HOME/git/wearetechnative/race/tfdestroy.sh";
	};
	initExtra = '' 
eval "$(zoxide init zsh)"
source ${zoxide}/zoxide
PATH=$HOME/bin:$PATH 
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

