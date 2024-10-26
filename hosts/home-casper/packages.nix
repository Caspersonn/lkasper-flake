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
	# lutris # Use flatpak version of Lutris
	nodejs
	onlyoffice-bin
	pre-commit
	python3
	mesa
	spotify	
	ssm-session-manager-plugin
	steam
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
