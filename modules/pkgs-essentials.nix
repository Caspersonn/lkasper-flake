{config, lib, pkgs, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
  # Essential GUI applications
  bitwarden-desktop
  filezilla
  firefox
  firejail
  obs-studio
  onlyoffice-bin
  spotify
  unstable.spotube # Open-source replacement for spotify
  video-trimmer
  winetricks

  # Essential NON-GUI applications
	gh
  android-tools
  avahi
  lsof
  libusb1
  bitwarden-cli
  busybox
  dig
  epson-escpr
  epson-escpr2
  f3
  gcc
  git-sync
  gnumake42
  go
  gum
  home-manager
  htop
  jq
  lsof
  neovim
  nodejs
  mailutils
  node2nix
  open-scq30
  pre-commit
  ruby
  smug
  tmux
  unstable.hugo
  unzip
  usbutils
  wl-clipboard
  zsh
  ];
}
