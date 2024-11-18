{ ... }:

{
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
        "org.gnome.Nautilus.desktop"
        "org.gnome.Console.desktop"
        "obsidian.desktop"
        "org.gnome.settings.desktop"
      ];
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "night-light-slider-updated@vilsbeg.codeberg.org"
        "unite@hardpixel.eu"
        "arcmenu@arcmenu.com"
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
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    "org/gnome/shell/extensions/nightlightsliderupdated" = {
      enable-always = true;  
    };

  };
}
