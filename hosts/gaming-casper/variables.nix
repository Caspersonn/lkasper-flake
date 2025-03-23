{
  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "Luca Kasper";
  gitEmail = "lucakasper8@gmail.com";

  # Hyprland Settings
  extraMonitorSettings = "";

  # Waybar Settings
  clock24h = true;

  # Program Options
  browser = "firefox"; # Set Default Browser (google-chrome-stable for google-chrome)
  terminal = "ghostty"; # Set Default System Terminal
  keyboardLayout = "us";
  consoleKeyMap = "us";

  # Enable NFS
  enableNFS = true;

  # Enable Printing Support
  printEnable = false;

  # Set Stylix Image
  stylixImage = ../../wallpapers/wallpaper.jpg;

  # Set Waybar
  # Includes alternates such as waybar-curved.nix & waybar-ddubs.nix
  waybarChoice = ../../home/desktop-environments/hyprland/waybar/waybar.nix;

  # Set Animation style
  animChoice = ../../home/desktop-environments/hyprland/animations-def.nix;

  # Enable Thunar GUI File Manager
  thunarEnable = false;
}

