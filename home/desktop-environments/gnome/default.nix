{ config, lib, hostname, username, pkgs, ... }:

let
  cfg = config.roles.desktop;
in

{
  options.roles.desktop = {
    enable = lib.mkEnableOption "Configure as desktop computer";
  };

  config = lib.mkIf cfg.enable {

    # Path for ddcutil
    home.file.".local/share/ddcutil/bin/ddcutil".source = "${pkgs.ddcutil}/bin/ddcutil";

    # Gnome settings
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
          "appindicatorsupport@rgcjonas.gmail.com"
        ];
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "night-light-slider-updated@vilsbeg.codeberg.org"
          "dash-to-panel@jderose9.github.com"
          "display-brightness-ddcutil@themightydeity.github.com"
          "multi-monitor-add-on@spin83.github.com"
          "display-brightness-ddcutil@themightydeity.github.com"
          "appindicatorsupport@rgcjonas.gmail.com"
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
        button-layout = "appmenu:close";
      };

      "org/gnome/shell/extensions/nightlightsliderupdated" = {
        enable-always = true;
        show-always = true;
        show-status-icon = false;
      };

      "org/gnome/shell/extensions/dash-to-panel" = {
        panel-element-positions = ''{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"centerMonitor"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"1":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"centerMonitor"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'';
        trans-use-custom-opacity = true;
        trans-use-dynamic-opacity = true;
        trans-dynamic-behavior = "MAXIMIZED_WINDOWS";
        panel-positions = ''{"0":"TOP","1":"TOP"}'';
        dot-style-focused = "DASHES";
      };

      "org/gnome/desktop/background" = {
        picture-uri      = "file:///home/${username}/lkasper-flake/wallpapers/wallpaper.jpg";
        picture-uri-dark = "file:///home/${username}/lkasper-flake/wallpapers/wallpaper.jpg";
      };

      "org/gnome/desktop/screensaver" = {
        picture-uri = "file:///home/${username}/lkasper-flake/wallpapers/wallpaper.jpg";
      };

      "org/gnome/shell/extensions/display-brightness-ddcutil" = {
        button-location = 1;
        ddcutil-binary-path =  "/home/${username}/.local/share/ddcutil/bin/ddcutil";
        tray-pos = "right";
        hide-system-indicator = true;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
      };
    };
  };
}



