{config, lib, pkgs, toggl-cli, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
  # Essential technative applications
	awscli
  docker
  neofetch
  lynis
	gh
	python311Packages.toggl-cli
	ssm-session-manager-plugin
	teams-for-linux
	terraform
	terraform-docs
	tfswitch
  slack
	zoom-us
  aws-mfa
  rbw
  granted
  nodejs_22
  nodePackages.live-server
  cypress
  google-chrome
  terraform-ls
	(python311.withPackages(ps: with ps; [ 
  requests
  lxml
	pytz
	pip
  openai-whisper
  openai
  pydub
  python-dotenv
  tiktoken
  ]))
  ];
}

