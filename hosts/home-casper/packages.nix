{config, lib, pkgs, agenix, toggl-cli, ... }:

{
  environment.systemPackages = with pkgs; [
	# lutris # Use flatpak version of Lutris
	agenix
	autojump
	awscli
	filezilla
	firefox
	flatpak
	fx-cast-bridge
	fzf
	gamescope
	gh
	git
	home-manager
	kdePackages.kate
	keepass
	mesa
	nodejs
	onlyoffice-bin
	pre-commit
	python3
	spotify	
	ssm-session-manager-plugin
  steam
	tmux
	unzip
  i2c-tools
	vscode
	wine
	wl-clipboard
	zoom-us
	zoxide
  pulseaudio
	zsh
   	discord
   	gnumake42
   	go
   	granted
   	gum
   	jq
   	neovim
    ];
}
