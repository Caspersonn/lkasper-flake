{config, lib, pkgs, agenix, toggl-cli, ... }:

{
  environment.systemPackages = with pkgs; [
	agenix
	autojump
	awscli
	firefox
	fzf
	gh
	git
	home-manager
	kdePackages.kate
	keepass
	nodejs
	obsidian
	onlyoffice-bin
	pre-commit
	pre-commit
	slack
	spotify	
	ssm-session-manager-plugin
	teams-for-linux
	terraform
	terraform-docs
	tfswitch
	tmux
	unzip
	vscode
	wl-clipboard
	zoom-us
	zoxide
	zsh
    aws-mfa
    gnumake42
    go
    granted
    gum
    jq
    neovim
	(python311.withPackages(ps: with ps; [ 
    requests
    lxml
	pytz
	toggl-cli
    ]))
  ];
}
