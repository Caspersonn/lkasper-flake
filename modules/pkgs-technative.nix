{config, lib, pkgs, toggl-cli, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
  # Essential technative applications
	awscli
  aws-nuke
	gh
  postgresql
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
  nodejs_22
  matterbridge
  rbw
  remmina
  slack
  silver-searcher
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
  requests
  tiktoken
  telegram-text
  python-telegram-bot
  ]))
  ];
}

