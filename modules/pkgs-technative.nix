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
  slack
	zoom-us
  aws-mfa
  granted
  nodejs_22
  nodePackages.live-server
  cypress
  terraform-ls
	(python311.withPackages(ps: with ps; [ 
  requests
  lxml
	pytz
	pip
  ]))
  ];
}

