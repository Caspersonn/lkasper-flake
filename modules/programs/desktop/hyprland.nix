{ inputs, ... }: {
  flake.modules.nixos.hyprland = { config, lib, pkgs, inputs, ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    services.power-profiles-daemon.enable = true;
    services.playerctld.enable = true;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs;
      [
        avizo
        bc
        blueman
        brightnessctl
        cava
        glib
        gruvbox-gtk-theme
        gruvbox-plus-icons
        gsettings-desktop-schemas
        hyprlock
        hyprpaper
        hyprshot
        hyprsunset
        kitty
        libnotify
        mpvpaper
        nautilus
        networkmanagerapplet
        nwg-bar
        nwg-displays
        pavucontrol
        playerctl
        power-profiles-daemon
        rofi
        sway
        swaynotificationcenter
        swayosd
        tuigreet
        uwsm
        waybar
        wiremix
        wlogout
        wofi
        wttrbar
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ] ++ lib.optionals (inputs ? swww)
      [ inputs.swww.packages.${pkgs.system}.swww ];

    hardware.graphics.extraPackages = with pkgs; [ libva libva-utils ];
  };
}
