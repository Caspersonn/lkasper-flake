{ inputs, ... }: {
  flake.modules.homeManager.kde = { pkgs, ... }:
    let whitesur = inputs.self.packages.${pkgs.system}.whitesur-kde;
    in {
      programs.plasma = {
        enable = true;
        overrideConfig = true;
        workspace = {
          clickItemTo = "open";
          lookAndFeel = "org.kde.breezedark.desktop";
          cursor.theme = "Bibata-Modern-Classic";
          cursor.size = 24;
          iconTheme = "WhiteSur-dark";
          colorScheme = "WhiteSurDark";
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
            hiding = "windowsgobelow";
            alignment = "center";
            lengthMode = "fit";
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
        whitesur
      ];
      home.activation.whitesur-kde = {
        after = [ "writeBoundary" ];
        before = [ ];
        data = ''
          mkdir -p $HOME/.local/share/aurorae/themes
          mkdir -p $HOME/.local/share/color-schemes
          mkdir -p $HOME/.local/share/plasma/desktoptheme
          mkdir -p $HOME/.config/Kvantum

          for d in ${whitesur}/share/aurorae/themes/*; do
            ln -sfn "$d" "$HOME/.local/share/aurorae/themes/$(basename $d)"
          done
          for f in ${whitesur}/share/color-schemes/*; do
            ln -sfn "$f" "$HOME/.local/share/color-schemes/$(basename $f)"
          done
          for d in ${whitesur}/share/plasma/desktoptheme/*; do
            ln -sfn "$d" "$HOME/.local/share/plasma/desktoptheme/$(basename $d)"
          done
          for d in ${whitesur}/share/Kvantum/*; do
            ln -sfn "$d" "$HOME/.config/Kvantum/$(basename $d)"
          done
        '';
      };
      fonts.fontconfig.enable = true;
    };
}
