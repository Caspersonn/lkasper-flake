{config, lib, pkgs, agenix, toggl-cli, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
	agenix
	autojump
	dig
  docker
	fzf
	gh
	git
	home-manager
	nodejs
	pre-commit
	ssm-session-manager-plugin
	tmux
	unzip
  gcc
	wl-clipboard
	zoxide
	zsh
  gnumake42
  go
  granted
  gum
  neovim
  nerdfonts
  #  python311Packages.toggl-cli
	#  (python311.withPackages(ps: with ps; [ 
  #  requests
  #  lxml
	#  pytz
	#  pip
  #    ]))
  ];
}
