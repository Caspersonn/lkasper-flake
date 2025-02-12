{ config, pkgs, ...}: 
let
  zoxide = ./zoxide;
in
{

programs.zsh = {
	enable = true;
    autosuggestion.enable = true;
	syntaxHighlighting.enable = true;
	shellAliases = {
  tfplan = "$HOME/git/wearetechnative/race/tfplan.sh";
	tfswitch = "mkdir -p ~/bin ; tfswitch -b $HOME/bin/terraform";
	tfapply = "$HOME/git/wearetechnative/race/tfapply.sh";
	tfdestroy = "$HOME/git/wearetechnative/race/tfdestroy.sh";
  aws-switch = ". $HOME/git/wearetechnative/bmc/aws-profile-select.sh";
	lin = "vi -c LinnyMenuOpen";
	ner = "vi -c NERDTree";
	};
	initExtra = '' 
eval "$(zoxide init zsh)"
source ${zoxide}
PATH=$HOME/bin:$PATH 
	'';
	oh-my-zsh = {
        enable = true;
		theme = "robbyrussell";
    custom = "./custom-theme";
		plugins = [
		  "git"
		  "aws"
		  "fzf"
		  "node"
		  "autojump"
		  "dirhistory"
      "terraform"
	    ];
	};
};
}

