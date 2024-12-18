{config, lib, pkgs, agenix, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
  # Essential GUI applications
  firefox
  keepass
  obs-studio
  obsidian
  onlyoffice-bin
  spotify
  filezilla
  firejail
  bitwarden-desktop
  video-trimmer

  # Essential NON-GUI applications
  agenix
  autojump
  lsof
  bitwarden-cli
  dig
  fzf
  gcc
  git
	gh
  gnumake42
  go
  gum
  home-manager
  jq
  neovim
  nodejs
  pre-commit
  ruby
  tmux
  unstable.hugo
  unzip
  wl-clipboard
  zoxide
  zsh
  f3
  usbutils
  epson-escpr
  epson-escpr2
  avahi
  busybox
  ];
}
