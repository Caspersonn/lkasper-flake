{ config, pkgs, ...}:
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
      ner = "vi -c Neotree";
    };
    initExtra = ''
      PATH=$HOME/bin:$PATH
      set -o allexport
      source /tmp/avante-bedrock
      set +o allexport
    '';

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      custom = "./custom-theme";
      plugins = [
        "git"
        "aws"
        "fzf"
        "autojump"
        "dirhistory"
        "terraform"
      ];
    };
  };
}

