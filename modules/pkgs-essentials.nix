{config, lib, pkgs, agenix, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
  # Essential GUI applications
  firefox
  keepass
  obs-studio
  obsidian
  onlyoffice-bin
  slack
  spotify
  filezilla

  # Essential NON-GUI applications
  agenix
  autojump
  dig
  fzf
  gcc
  git
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
  ];
}
