{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    # Essential technative applications
    attic-client
    aws-mfa
    aws-nuke
    aws-sam-cli
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
    lynis
    nchat
    neofetch
    nodePackages.live-server
    postgresql_15
    python312Packages.distutils
    quarto
    rbw
    yarn
    redis
    slack
    ssm-session-manager-plugin
    teams-for-linux
    telegram-bot-api
    telegram-desktop
    fastfetch
    terraform
    terraform-docs
    terraform-ls
    pritunl-client
    (texlive.combine {
      inherit (texlive) scheme-full datetime fmtcount textpos makecell lipsum footmisc background ; 
    })
    tfsec
    tfswitch
    typescript
    unstable.zoom-us
    (python313.withPackages(ps: with ps; [
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
}

