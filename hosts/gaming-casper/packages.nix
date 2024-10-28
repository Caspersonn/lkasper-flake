{config, lib, pkgs, agenix, toggl-cli, ... }:

{
  environment.systemPackages = with pkgs; [
	agenix
	autojump
	awscli
	filezilla
	firefox
	flatpak
	fzf
	gamescope
	gh
	git
	home-manager
	kdePackages.kate
	keepass
#	lutris # Use flatpak version of lutris
	nodejs
	onlyoffice-bin
	pre-commit
	python3
	spotify	
	ssm-session-manager-plugin
	steam
	protontricks
	tmux
	unzip
	vscode
	wine
	wl-clipboard
	zoom-us
	zsh
   	discord
   	gnumake42
   	go
   	granted
   	gum
   	jq
   	neovim
	zoxide
    ];
}