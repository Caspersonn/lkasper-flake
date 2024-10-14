{config, lib, pkgs, agenix, toggl-cli, ... }:

{
  environment.systemPackages = with pkgs; [
    aws-mfa
    python311Packages.toggl-cli
    jq
    teams-for-linux
    gum
    granted
    go
    gnumake42
	kdePackages.kate
	slack
	keepass
	awscli
	tfswitch
	git
	gh
	zoom-us
	wl-clipboard
	vscode
	autojump
	fzf
	python3
	pre-commit
	terraform
	pre-commit
	python312Packages.toggl-cli
	lua
	z-lua
	ssm-session-manager-plugin
	nodejs
	tmux
	spotify	
	onlyoffice-bin
	obsidian
	firefox
    neovim
	zsh
  ];
}
