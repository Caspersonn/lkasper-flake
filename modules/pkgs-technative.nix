{config, lib, pkgs, toggl-cli, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
  # Essential technative applications
	awscli
	gh
	python311Packages.toggl-cli
	ssm-session-manager-plugin
	teams-for-linux
	terraform
	terraform-docs
	tfswitch
	zoom-us
  aws-mfa
  cypress
  docker
  google-chrome
  granted
  lynis
  nchat
  neofetch
  nodePackages.live-server
  nodejs_22
  rbw
  slack
  silver-searcher
  terraform-ls
	(python311.withPackages(ps: with ps; [ 
	pip
	pytz
  lxml
  openai
  openai-whisper
  pydub
  python-dotenv
  requests
  tiktoken
  ]))
  ];
}

