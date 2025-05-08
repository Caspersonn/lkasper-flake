{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
  # Essential GUI applications
  bitwarden-desktop
  discord
  ddcutil
  chromium
  cypress
  filezilla
  firefox
  firejail
  ghostty
  librewolf
  libreoffice-qt6-fresh
  obs-studio
  onlyoffice-bin
  pgadmin4-desktopmode
  spotify
  librewolf
  google-chrome
  video-trimmer
  winetricks

  # Essential NON-GUI applications
  gh
  android-tools
  avahi
  ddcui
  lsof
  libusb1
  bitwarden-cli
  #busybox
  wget
  csvtool
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

  # language servers
  sqls
  gopls
  nixd
  marksman
  terraform-ls
  nodePackages.bash-language-server
  sumneko-lua-language-server
  neovim
  nil
  tree-sitter
  nerdfonts
  mailutils
  marksman
  rust-analyzer
  cargo
  rustc
  vscode-langservers-extracted
  nodejs

  mods
  node2nix
  open-scq30
  pre-commit
  sof-firmware
  ruby
  smug
  tmux
  hugo
  unzip
  usbutils
  wl-clipboard
  zsh
  markdownlint-cli

  # Formatters
  nixfmt-classic
  rustfmt
  nodePackages.prettier
  ruby
  ];
}
