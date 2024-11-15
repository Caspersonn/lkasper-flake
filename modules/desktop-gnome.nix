{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    adw-gtk3
    gnomeExtensions.dock-from-dash
    gnomeExtensions.dash-to-dock
    gnomeExtensions.date-menu-formatter
    gnomeExtensions.gsconnect
    gnomeExtensions.night-light-slider-updated
    gnomeExtensions.unite
    gnomeExtensions.arcmenu
    gnome-extension-manager 
    gnome.gnome-tweaks
    gnome.mutter
  ];

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    # gedit # text editor
    epiphany # web browser
    geary # email reader
    # gnome-characters
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    yelp # Help view
    seahorse
    # gnome-contacts
    gnome-initial-setup
  ]);
  
  services = {
    xserver = {
      enable = true;
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverridePackages = [pkgs.gnome.mutter];
        extraGSettingsOverrides = ''
          [org.gnome.mutter]
          experimental-features=['variable-refresh-rate', 'scale-monitor-framebuffer']
        '';
      };
      displayManager.gdm.enable = true;
    };
  }; 
}
