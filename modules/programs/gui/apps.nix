{ inputs, ... }: {
  flake.modules.nixos.gui-apps = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Office & Productivity
      libreoffice-qt6-fresh
      onlyoffice-desktopeditors
      signal-desktop
      discord

      # Media & Entertainment
      obs-studio
      video-trimmer
      blanket
      aonsoku
      supersonic-wayland

      # Development
      pgadmin4-desktopmode

      # Security & Utilities
      #bitwarden-desktop
      filezilla
      ddcutil
      winetricks

      # 3D printing
      orca-slicer
    ];

    services.avahi.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;

      raopOpenFirewall = true;

      extraConfig.pipewire."10-airplay" = {
        "context.modules" = [
          {
            name = "libpipewire-module-raop-discover";
            args = {
              "raop.latency.ms" = 500;
            };
          }
        ];
      };
    };

  };
}
