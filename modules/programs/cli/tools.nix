{ inputs, ... }: {
  flake.modules.nixos.cli-tools = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      inputs.rme.packages."${pkgs.stdenv.hostPlatform.system}".default
      # TUI Applications
      htop
      gum
      glow
      claude-monitor

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
      optnix
      pkgs.unstable.wineWow64Packages.waylandFull
      pkgs.unstable.wine64Packages.waylandFull

      # Security
      bitwarden-cli
      rbw
      pinentry-tty

      # Misc
      mailutils
      mods
      teamtype
      sc-im
    ];
  };
}
