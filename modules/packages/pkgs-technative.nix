{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    # Essential technative applications
    awscli
    aws-nuke
    attic-client
    gh
    postgresql_15
    ssm-session-manager-plugin
    teams-for-linux
    terraform
    terraform-docs
    tfswitch
    tfsec
    telegram-bot-api
    telegram-desktop
    typescript
    unstable.zoom-us
    aws-mfa
    cypress
    docker
    google-chrome
    granted
    gpt4all
    git-remote-codecommit
    lynis
    nchat
    neofetch
    nodePackages.live-server
    nodejs_18
    redis
    rbw
    remmina
    slack
    silver-searcher
    seafile-client
    hedgedoc
    quarto
    terraform-ls
    python312Packages.distutils
    (python311.withPackages(ps: with ps; [ 
      pip
      pytz
      pyinstaller
      lxml
      langchain
      langchain-community
      openai
      openai-whisper
      pydub
      python-dotenv
      pylint
      jedi
      requests
      tiktoken
      telegram-text
      toggl-cli
      python-telegram-bot
    ]))
  ];
}

