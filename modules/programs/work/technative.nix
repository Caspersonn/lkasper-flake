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
      attic-client
      aws-mfa
      aws-nuke
      awscli
      beam27Packages.elixir
      bruno
      docker
      erlang_28
      entr
      gh
      git-remote-codecommit
      gimp3
      granted
      hedgedoc
      inotify-tools
      inkscape-with-extensions
      lynis
      nchat
      neofetch
      postgresql_15
      python312Packages.distutils
      quarto
      rbw
      yarn
      redis
      slack
      ssm-session-manager-plugin
      solidtime-desktop
      teams-for-linux
      telegram-bot-api
      telegram-desktop
      fastfetch
      terraform-docs
      terraform-ls
      pritunl-client
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
