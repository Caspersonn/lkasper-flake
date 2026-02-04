{ pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    # TUI Applications
    htop
    gum

    # Development Tools - Version Control
    gh
    git-sync

    # Development Tools - Build & Languages
    gcc
    gnumake42
    go
    ruby
    nodejs_24
    cargo
    rustc
    home-manager
    node2nix
    pre-commit
    hugo
    claude-code

    # Language Servers & IDE Tools
    sqls
    gopls
    nixd
    marksman
    nodePackages.bash-language-server
    lua-language-server
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
    whois
    ethtool
    wireguard-tools

    # System Utilities - Misc
    libffi
    libffi_3_3
    polkit_gnome
    gnome-disk-utility
    gparted
    lsof
    bitwarden-cli
    smug
    zsh
    rbw
    pinentry-tty
    mailutils
    mods
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
    unstable.aider-chat-full
    (python313.withPackages(ps: with ps; [
      openpyxl
      tkinter
      sv-ttk
    ]))
  ];
}
