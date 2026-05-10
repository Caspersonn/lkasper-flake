{ ... }: {
  flake.modules.homeManager.shared-zsh = { config, ... }: {
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
      initExtra = ''
        PATH=$HOME/bin:$PATH
        set -o allexport
        #compdef rme
        # rme zsh completion
        _rme() {
            compadd $(rme --completions)
        }
        compdef _rme rme
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
        plugins = [ "git" "fzf" "autojump" "dirhistory" ];
      };
    };
  };
}
