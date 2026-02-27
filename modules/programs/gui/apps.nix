{ inputs, ... }: {
  flake.modules.nixos.gui-apps = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Office & Productivity
      libreoffice-qt6-fresh
      onlyoffice-desktopeditors
      signal-desktop
      pkgs.unstable.discord

      # Media & Entertainment
      obs-studio
      video-trimmer

      # Development
      pgadmin4-desktopmode

      # Security & Utilities
      bitwarden-desktop
      filezilla
      ddcutil
      winetricks

      # 3D printing
      orca-slicer
    ];
  };
}
