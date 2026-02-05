{ inputs, ... }: {
  flake.modules.nixos.cli-tools = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # TUI Applications
      htop
      gum

      # Network & File Management
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
      file

      # System Utilities
      lsof
      smug
      zsh

      # Security
      bitwarden-cli
      rbw
      pinentry-tty

      # Misc
      mailutils
      mods
    ];
  };
}
