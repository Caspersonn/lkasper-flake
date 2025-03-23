{config, lib, pkgs, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
  # Essential technative applications
	awscli
  aws-nuke
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
	zoom-us
  aws-mfa
  cypress
  docker
  google-chrome
  granted
  gpt4all
  lynis
  nchat
  neofetch
  nodePackages.live-server
  nodejs_18
  redis
  matterbridge
  rbw
  remmina
  slack
  silver-searcher
  seafile-client
  quarto
  terraform-ls
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

