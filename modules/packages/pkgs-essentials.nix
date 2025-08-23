{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
  # GUI Applications - Browsers
  firefox
  librewolf
  chromium
  google-chrome

  # GUI Applications - Office & Productivity
  libreoffice-qt6-fresh
  onlyoffice-bin
  signal-desktop
  unstable.jan

  # GUI Applications - Media & Entertainment
  obs-studio
  spotify
  video-trimmer
  easyeffects

  # GUI Applications - Development
  pgadmin4-desktopmode
  cypress
  ghostty

  # GUI Applications - Security & Utilities
  bitwarden-desktop
  firejail
  filezilla
  unstable.discord
  ddcutil
  winetricks

  # TUI Applications
  tmux
  htop
  btop
  neovim
  gum

  # Development Tools - Version Control
  gh
  git-sync

  # Development Tools - Build & Languages
  gcc
  gnumake42
  go
  nodejs
  ruby
  cargo
  rustc
  home-manager
  node2nix
  pre-commit
  hugo

  # Language Servers & IDE Tools
  sqls
  gopls
  nixd
  marksman
  terraform-ls
  nodePackages.bash-language-server
  sumneko-lua-language-server
  nil
  rust-analyzer
  vscode-langservers-extracted
  tree-sitter

  # Formatters & Linters
  nixfmt-classic
  rustfmt
  nodePackages.prettier
  markdownlint-cli

  # System Utilities - Hardware & Device Management
  android-tools
  ddcui
  libusb1
  usbutils
  sof-firmware
  open-scq30
  epson-escpr
  epson-escpr2

  # System Utilities - Network & File Management
  wget
  avahi
  dig
  unzip
  csvtool
  f3
  jq
  wl-clipboard
  nmap

  # System Utilities - Misc
  polkit_gnome
  gnome-disk-utility
  gparted
  lsof
  bitwarden-cli
  smug
  zsh
  mailutils
  mods
  nerd-fonts.fira-code
  nerd-fonts.jetbrains-mono
  nerd-fonts.droid-sans-mono
  nerd-fonts.symbols-only
  aider-chat-full
  (python313.withPackages(ps: with ps; [
    tkinter
    sv-ttk
  ]))
  ];
}
