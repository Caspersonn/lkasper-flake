{config, lib, pkgs, unstable, ... }:
let
  cfg = config.roles.gnome;
  gnome = pkgs.gnome.overrideScope (gnomeFinal: gnomePrev: {
    mutter = gnomePrev.mutter.overrideAttrs (old: {
      src = pkgs.fetchFromGitLab  {
        domain = "gitlab.gnome.org";
        owner = "vanvugt";
        repo = "mutter";
        rev = "triple-buffering-v4-46";
        hash = "sha256-C2VfW3ThPEZ37YkX7ejlyumLnWa9oij333d5c4yfZxc=";
      };
    });
  });
in
{
  environment.systemPackages = with pkgs; [
    adw-gtk3
    gnomeExtensions.dash-to-panel
    gnomeExtensions.date-menu-formatter
    gnomeExtensions.night-light-slider-updated
    gnomeExtensions.brightness-control-using-ddcutil
    gnomeExtensions.appindicator
    gnome-extension-manager 
    gnome-tweaks
    mutter
  ];

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    ]) ++ (with pkgs; [
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
      displayManager.gdm.enable = true;
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverridePackages = [pkgs.mutter];
        extraGSettingsOverrides = ''
          [org.gnome.mutter]
          experimental-features=['scale-monitor-framebuffer']
        '';
      };
    };
  }; 
}
