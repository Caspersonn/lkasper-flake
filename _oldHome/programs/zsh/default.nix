{config, ...}: {
  home.file = {
    ".ohmyzsh-casper" = {
      source = ./ohmyzsh-casper;
      recursive = true;
    };
  };
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      tfplan = "$HOME/git/wearetechnative/race/tfplan.sh";
      tfswitch = "mkdir -p ~/bin ; tfswitch -b $HOME/bin/terraform";
      tfapply = "$HOME/git/wearetechnative/race/tfapply.sh";
      tfdestroy = "$HOME/git/wearetechnative/race/tfdestroy.sh";
      aws-switch = ". bmc profsel";
      lin = "vi -c LinnyMenuOpen";
      ner = "vi -c Neotree";
      runbg = "$HOME/.config/hypr/scripts/runbg.sh";
      tses = "$HOME/lkasper-flake/home/programs/tmux/script/sessionizer.sh";
      aws-mfa = "$HOME/lkasper-flake/home/desktop-environments/hyprland/scripts/aws-mfa-auto.sh";
      bcd = "export AWS_PROFILE='TEC-playground-student14' && export CLAUDE_CODE_USE_BEDROCK=1 && export ANTHROPIC_MODEL='arn:aws:bedrock:eu-central-1:939665396134:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0' && export AWS_REGION=eu-central-1 && claude";
      bcdc = "export AWS_PROFILE='TEC-playground-student14' && export CLAUDE_CODE_USE_BEDROCK=1 && export ANTHROPIC_MODEL='arn:aws:bedrock:eu-central-1:939665396134:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0' && export AWS_REGION=eu-central-1 && claude -c";
    };
    initExtra = ''
      PATH=$HOME/bin:$PATH
      set -o allexport
      if [ -f /tmp/avante-bedrock ]; then
        source /tmp/avante-bedrock
      fi
      if [ -f /tmp/avante-openai ]; then
        source /tmp/avante-openai
      fi
      if [ -f /tmp/google-bedrock ]; then
        source /tmp/google-bedrock
      fi
      if [ -f /tmp/google-engine-bedrock ]; then
        source /tmp/google-engine-bedrock
      fi
      set +o allexport
    '';

    oh-my-zsh = {
      enable = true;
      theme = "casper";
      custom = "${config.home.homeDirectory}/.ohmyzsh-casper";
      #theme = "robbyrussell";
      #custom = "./custom-theme";
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
