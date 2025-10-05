{config, lib, pkgs, inputs, ...}:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable power-profiles-daemon
  services.power-profiles-daemon.enable = true;

  # Enable playerctl daemon
  services.playerctld.enable = true;

  # Force wayland on xwayland apps for better scaling
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Packages
  environment.systemPackages = with pkgs; [
    bc # GNU software calculator
    blueberry # Bluetooth configuration tool
    brightnessctl # This program allows you read and control device brightness
    cava # Console-based Audio Visualizer for Alsa
    greetd.tuigreet # The Login Manager (Sometimes Referred To As Display Manager)
    gruvbox-gtk-theme # GTK theme based on the Gruvbox colour palette
    gruvbox-plus-icons # Icon pack for Linux desktops based on the Gruvbox color scheme
    hyprlock # Hyprland's GPU-accelerated screen locking utility
    hyprpaper # Blazing fast wayland wallpaper utility
    hyprshot # Hyprshot is an utility to easily take screenshots in Hyprland using your mouse
    hyprsunset # Application to enable a blue-light filter on Hyprland
    inputs.elephant.packages.${system}.default
    inputs.swww.packages.${pkgs.system}.swww
    inputs.walker.packages.${system}.default
    kitty # Terminal
    libnotify # Sends notication to deamon
    mpvpaper # Video wallpaper program for wlroots based wayland compositors
    nautilus # File manager
    networkmanagerapplet # NetworkManager control applet for GNOME
    nwg-bar # GTK3-based button bar for sway and other wlroots-based compositors
    nwg-displays  #configure monitor configs via GUI
    pavucontrol # For Editing Audio Levels & Devices
    playerctl # Allows Changing Media Volume Through Scripts
    power-profiles-daemon # Makes user-selected power profiles handling available over D-Bus
    rofi # Window switcher, run dialog and dmenu replacement
    sway # I3-compatible tiling Wayland compositor
    swaynotificationcenter # Simple notification daemon with a GUI built for Sway
    swayosd # GTK based on screen display for keyboard shortcuts
    waybar # Status bar
    wlogout # Wayland based logout menu
    wofi # Launcher/menu program for wlroots based wayland compositors such as sway
    wttrbar # Simple but detailed weather indicator for Waybar using wttr.in
  ];

  # Login
  services.greetd = {
    enable = true;
    vt = 3;
    settings = {
      default_session = {
        user = "casper";
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      };
    };
  };

  # OpenGL
  hardware.graphics = {
    extraPackages = with pkgs; [
      libva
      libva-utils
    ];
  };
}
