{ inputs, ... }: {
  flake.modules.nixos.gui-apps = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Office & Productivity
      libreoffice-qt6-fresh
      onlyoffice-desktopeditors
      signal-desktop
      pkgs.unstable.discord
      pkgs.unstable.jan
      pkgs.unstable.newelle

      # Media & Entertainment
      obs-studio
      video-trimmer

      # Development
      pgadmin4-desktopmode
      cypress

      # Security & Utilities
      bitwarden-desktop
      firejail
      filezilla
      ddcutil
      winetricks

      # 3D printing
      orca-slicer
    ];
  };
}
