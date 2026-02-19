{ ... }: {
  flake.modules.homeManager.kde = { pkgs, ... }: {
    programs.plasma = {
      enable = true;
      overrideConfig = true;
      workspace = {
        clickItemTo = "open";
        lookAndFeel = "org.kde.breezedark.desktop";
        cursor.theme = "Bibata-Modern-Classic";
        cursor.size = 24;
        iconTheme = "Papirus-Dark";
        wallpaper =
          "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1080x1920.png";
      };
      fonts.general.family = "Inter";
      fonts.general.pointSize = 11;
      fonts.fixedWidth.family = "JetBrainsMono Nerd Font";
      fonts.fixedWidth.pointSize = 11;
      panels = [
        {
          location = "top";
          height = 28;
          floating = false;
          hiding = "none";
          widgets = [
            {
              kickoff = {
                icon = "nix-snowflake";
                label = "";
                sortAlphabetically = true;
              };
            }
            {
              applicationTitleBar = {
                layout = {
                  elements = [ "windowTitle" ];
                  horizontalAlignment = "left";
                };
              };
            }
            "org.kde.plasma.appmenu"
            "org.kde.plasma.panelspacer"
            {
              systemTray = {
                items.shown = [
                  "org.kde.plasma.networkmanagement"
                  "org.kde.plasma.volume"
                  "org.kde.plasma.battery"
                ];
              };
            }
            {
              digitalClock = {
                date.enable = true;
                time.format = "24h";
              };
            }
          ];
        }
        {
          location = "bottom";
          height = 58;
          floating = true;
          hiding = "autohide";
          widgets = [{
            iconTasks = {
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:firefox.desktop"
                "applications:org.kde.konsole.desktop"
                "applications:org.kde.kate.desktop"
              ];
              appearance.showTooltips = true;
            };
          }];
        }
      ];
      kwin = {
        virtualDesktops = { number = 4; };
        effects = {
          blur.enable = true;
          dimInactive.enable = true;
          windowOpenClose.animation = "glide";
        };
      };
      shortcuts = {
        ksmserver."Lock Session" = [ "Meta+Ctrl+Q" "Screensaver" ];
        kwin = {
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Window Maximize" = "Meta+Up";
          "Window Minimize" = "Meta+Down";
          "Window Close" = "Meta+W";
        };
      };
      hotkeys.commands = {
        "launch-konsole" = {
          name = "Terminal";
          key = "Meta+Return";
          command = "konsole";
        };
        "launch-dolphin" = {
          name = "Files";
          key = "Meta+E";
          command = "dolphin";
        };
      };
      kscreenlocker = { autoLock = true; };
      powerdevil = { };
      configFile = {
        "kwinrc"."org.kde.kdecoration2" = {
          library = "org.kde.breeze";
          theme = "Breeze";
          ButtonsOnLeft = "XIA";
          ButtonsOnRight = "";
        };
        "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
      };
    };
    home.packages = with pkgs; [
      kdePackages.filelight
      kdePackages.spectacle
      kdePackages.gwenview
      inter
      jetbrains-mono
      kdePackages.qtstyleplugin-kvantum
    ];
    fonts.fontconfig.enable = true;
  };
}
