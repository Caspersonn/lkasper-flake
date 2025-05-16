{config, lib, pkgs, ...}:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Force wayland on xwayland apps for better scaling
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Packages
  environment.systemPackages = with pkgs; [
    blueberry # Bluetooth configuration tool
    brightnessctl # This program allows you read and control device brightness
    greetd.tuigreet # The Login Manager (Sometimes Referred To As Display Manager)
    gruvbox-gtk-theme # GTK theme based on the Gruvbox colour palette
    gruvbox-plus-icons # Icon pack for Linux desktops based on the Gruvbox color scheme
    hyprlock # Hyprland's GPU-accelerated screen locking utility
    hyprpaper # Blazing fast wayland wallpaper utility
    hyprshot # Hyprshot is an utility to easily take screenshots in Hyprland using your mouse
    kitty # Terminal
    libnotify # Sends notication to deamon
    nautilus # File manager
    networkmanagerapplet # NetworkManager control applet for GNOME
    nwg-bar # GTK3-based button bar for sway and other wlroots-based compositors
    nwg-displays  #configure monitor configs via GUI
    pavucontrol # For Editing Audio Levels & Devices
    sway # I3-compatible tiling Wayland compositor
    swaynotificationcenter # Simple notification daemon with a GUI built for Sway
    swayosd # GTK based on screen display for keyboard shortcuts
    waybar # Status bar
    wlogout # Wayland based logout menu
    wofi # Launcher/menu program for wlroots based wayland compositors such as sway

    #rofi-wayland # app launcher
    #swayidle # Idle management daemon for Wayland
    #amfora # Fancy Terminal Browser For Gemini Protocol
    #appimage-run # Needed For AppImage Support
    #brave # Brave Browser
    #cmatrix # Matrix Movie Effect In Terminal
    #cowsay # Great Fun Terminal Program
    #docker-compose # Allows Controlling Docker From A Single File
    #duf # Utility For Viewing Disk Usage In Terminal
    #eza # Beautiful ls Replacement
    #ffmpeg # Terminal Video / Audio Editing
    #file-roller # Archive Manager
    #gedit # Simple Graphical Text Editor
    #gimp # Great Photo Editor
    #htop # Simple Terminal Based System Monitor
    #hyprpicker # Color Picker
    #eog # For Image Viewing
    #inxi # CLI System Information Tool
    #killall # For Killing All Instances Of Programs
    #lm_sensors # Used For Getting Hardware Temps
    #lolcat # Add Colors To Your Terminal Command Output
    #lshw # Detailed Hardware Information
    #mpv # Incredible Video Player
    #ncdu # Disk Usage Analyzer With Ncurses Interface
    #nixfmt-rfc-style # Nix Formatter
    #onefetch #provides zsaneyos build info on current system
    #pciutils # Collection Of Tools For Inspecting PCI Devices
    #picard # For Changing Music Metadata & Getting Cover Art
    #pkg-config # Wrapper Script For Allowing Packages To Get Info On Others
    #playerctl # Allows Changing Media Volume Through Scripts
    #rhythmbox
    #ripgrep # Improved Grep
    #socat # Needed For Screenshots
    #unrar # Tool For Handling .rar Files
    #unzip # Tool For Handling .zip Files
    #usbutils # Good Tools For USB Devices
    #v4l-utils # Used For Things Like OBS Virtual Camera
    #wget # Tool For Fetching Files With Links
    #yazi #TUI File Manager
    #ytmdl # Tool For Downloading Audio From YouTube

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
