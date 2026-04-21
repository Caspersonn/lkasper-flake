{ inputs, unstable, ... }: {
  flake.modules.nixos.technative = { pkgs, ... }: {
    fonts.packages = with pkgs; [ lato ];

    security.acme = {
      defaults.email = "lucakasper8@gmail.com";
      acceptTerms = true;
    };

    environment.systemPackages = with pkgs; [
      inputs.jsonify-aws-dotfiles.packages."${pkgs.system}".jsonify-aws-dotfiles
      inputs.bmc.packages."${pkgs.system}".bmc
      inputs.race.packages."${pkgs.system}".race
      inputs.ssmsh.packages."${pkgs.system}".default
      inputs.aws-tui.packages."${pkgs.system}".default
      attic-client
      aws-mfa
      aws-nuke
      awscli
      beam27Packages.elixir
      bruno
      docker
      entr
      erlang_28
      fastfetch
      gh
      gimp3
      git-remote-codecommit
      granted
      hedgedoc
      inkscape-with-extensions
      inotify-tools
      lynis
      nchat
      neofetch
      ngrok
      postgresql_16_jit
      pritunl-client
      python312Packages.distutils
      quarto
      rbw
      redis
      slack
      solidtime-desktop
      ssm-session-manager-plugin
      teams-for-linux
      telegram-bot-api
      telegram-desktop
      terraform-docs
      terraform-ls
      yarn
      (texlive.combine {
        inherit (texlive)
          scheme-full datetime fmtcount textpos makecell lipsum footmisc
          background lato;
      })
      tfsec
      tfswitch
      typescript
      pkgs.unstable.zoom-us
      (python313.withPackages (ps:
        with ps; [
          jedi
          langchain
          langchain-community
          lxml
          pip
          pydub
          pyinstaller
          pylint
          python-dotenv
          pytz
          requests
          telegram-text
          tiktoken
          toggl-cli
          boto3
        ]))
    ];
  };
}
