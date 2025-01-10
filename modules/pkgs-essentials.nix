{config, lib, pkgs, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
  # Essential GUI applications
  bitwarden-desktop
  filezilla
  firefox
  firejail
  keepass
  obs-studio
  obsidian
  onlyoffice-bin
  spotify
  video-trimmer

  # Essential NON-GUI applications
	gh
  autojump
  avahi
  bitwarden-cli
  busybox
  dig
  epson-escpr
  epson-escpr2
  f3
  fzf
  gcc
  git
  git-sync
  gnumake42
  go
  gum
  home-manager
  jq
  lsof
  neovim
  nodejs
  mailutils
  pre-commit
  ruby
  smug
  tmux
  unstable.hugo
  unzip
  usbutils
  wl-clipboard
  zoxide
  zsh
  ];
}
