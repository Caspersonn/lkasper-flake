{ config, lib, hostname, ... }:

let
  cfg = config.roles.desktop;
in

{ 
  options.roles.desktop = {
    enable = lib.mkEnableOption "Configure as desktop computer";
  };

  config = lib.mkIf cfg.enable {
    dconf.settings = {
      "org/gnome/desktop/interface/clock-show-weekday" = {
       clock-show-weekday = true;
      };

      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-hot-corners = false;
      };

      "org/gnome/shell" = {
        favorite-apps = [
          "firefox.desktop"
          "discord.desktop"
          "slack.desktop"
          "spotify.desktop"
          "bitwarden.desktop"
          "org.gnome.Nautilus.desktop"
          "com.mitchellh.ghostty.desktop"
          "org.gnome.settings.desktop"
        ];
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "night-light-slider-updated@vilsbeg.codeberg.org"
          "dash-to-panel@jderose9.github.com"
          "display-brightness-ddcutil@themightydeity.github.com"
          "multi-monitor-add-on@spin83.github.com"
      ];
    };

      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-fixed = false;
        intellihide-mode = "MAXIMIZED_WINDOWS";
        custom-theme-shrink = true;
        apply-custom-theme = true;
        show-show-apps-button = false;
        show-trash = false;
        show-mounts = false;
        show-icons-notifications-counter = false;
        mulit-monitor = true;
        always-center-icons = true;
        extend-height = true;
      };

      "org/gnome/shell/extensions/unite" = {
        show-appmenu-button = false;
        extend-left-box = false;
        restrict-to-primary-screen = false;
        window-buttons-placement = "right";
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
      };

      "org/gnome/shell/extensions/nightlightsliderupdated" = {
        enable-always = true;  
        show-always = true;
      };

      "org/gnome/shell/extensions/dash-to-panel" = {
        panel-element-positions = ''{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"centerMonitor"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"1":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"centerMonitor"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'';
        trans-use-custom-opacity = true;
        trans-use-dynamic-opacity = true;
        trans-dynamic-behavior = "MAXIMIZED_WINDOWS";
        panel-positions = ''{"0":"BOTTOM","1":"BOTTOM"}'';
        dot-style-focused = "DASHES";
      };

      # TODO: background working with image from internet (https://mjones.network/articles/declarative-desktop-env-config-with-nix.html)
      #"org/gnome/desktop/background" = {
      #  picture-uri      = "file:///home/casper/.local/share/backgrounds/2025-03-23-16-41-11-wallpaper.jpg";
      #  picture-uri-dark = "file:///home/casper/.local/share/backgrounds/2025-03-23-16-41-11-wallpaper.jpg";
      #};
    };
  };
}



