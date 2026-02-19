{ inputs, ... }: {
  flake.modules.homeManager.kde = { pkgs, config, lib, ... }: {
    programs.plasma = {
      enable = true;
      workspace = {
        clickItemTo = "open";
        lookAndFeel = "org.kde.breezedark.desktop";
        cursor = {
          theme = "Bibata-Modern-Classic";
          size = 24;
        };
        iconTheme = "Papirus-Dark";
        wallpaper =
          "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1080x1920.png";
      };
      fonts = {
        general = {
          family = "Inter";
          pointSize = 11;
        };
        fixedWidth = {
          family = "JetBrainsMono Nerd Font";
          pointSize = 11;
        };
      };
      panels = [
        {
          location = "top";
          height = 28;
          floating = false;
          hiding = "none";
          widgets = [
            {
              kickoff = {
                icon = "nix-snowflake-white";
                label = "";
                sortAlphabetically = true;
              };
            }
            {
              applicationTitleBar = {
                behavior = { activeTaskSource = "activeTask"; };
                layout = {
                  elements = [ "windowTitle" ];
                  horizontalAlignment = "left";
                  showDisabledElements = "deactivated";
                  verticalAlignment = "center";
                };
                overrideForMaximized.enable = false;
                windowTitle = {
                  font = {
                    bold = true;
                    fit = "fixedSize";
                    size = 11;
                  };
                  hideEmptyTitle = true;
                  margins = {
                    bottom = 0;
                    left = 10;
                    right = 5;
                    top = 0;
                  };
                  source = "appName";
                };
              };
            }
            "org.kde.plasma.appmenu"
            "org.kde.plasma.panelspacer"
            {
              systemTray = {
                icons = {
                  spacing = "small";
                  scaleToFit = true;
                };
                items = {
                  shown = [
                    "org.kde.plasma.networkmanagement"
                    "org.kde.plasma.bluetooth"
                    "org.kde.plasma.volume"
                    "org.kde.plasma.battery"
                    "org.kde.plasma.brightness"
                  ];
                  hidden = [ "org.kde.plasma.clipboard" ];
                };
              };
            }
            {
              digitalClock = {
                calendar = {
                  firstDayOfWeek = "monday";
                  showWeekNumbers = false;
                };
                time = {
                  format = "24h";
                  showSeconds = "never";
                };
                date = {
                  enable = true;
                  format = "shortDate";
                  position = "besideTime";
                };
              };
            }
          ];
        }
        {
          location = "bottom";
          height = 58;
          lengthMode = "fit";
          alignment = "center";
          hiding = "dodgewindows";
          floating = true;
          widgets = [{
            iconTasks = {
              appearance = {
                fill = true;
                highlightWindows = true;
                iconSpacing = "small";
                indicateAudioStreams = true;
                rows = {
                  multirowView = "never";
                  maximum = 1;
                };
                showTooltips = true;
              };
              behavior = {
                grouping = {
                  method = "byProgramName";
                  clickAction = "cycle";
                };
                middleClickAction = "newInstance";
                minimizeActiveTaskOnClick = true;
                newTasksAppearOn = "right";
                showTasks = { onlyInCurrentActivity = true; };
                sortingMethod = "manually";
                unhideOnAttentionNeeded = true;
                wheel = {
                  ignoreMinimizedTasks = true;
                  switchBetweenTasks = true;
                };
              };
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:firefox.desktop"
                "applications:org.kde.konsole.desktop"
                "applications:org.kde.kate.desktop"
                "applications:org.kde.discover.desktop"
                "applications:systemsettings.desktop"
              ];
            };
          }];
        }
      ];
      desktop.widgets = [ ];
      kwin = {
        edgeBarrier = 0;
        cornerBarrier = false;
        effects = {
          blur.enable = true;
          desktopSwitching.animation = "slide";
          dimInactive.enable = true;
          translucency.enable = true;
          windowOpenClose.animation = "glide";
        };
        virtualDesktops = {
          rows = 1;
          number = 4;
          names = [ "Main" "Work" "Media" "Other" ];
        };
      };
      shortcuts = {
        ksmserver = { "Lock Session" = [ "Meta+Ctrl+Q" "Screensaver" ]; };
        kwin = {
          "Expose" = "Meta+Tab";
          "ExposeAll" = "Meta+A";
          "Walk Through Windows" = "Alt+Tab";
          "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Switch to Desktop 4" = "Meta+4";
          "Window Maximize" = "Meta+Up";
          "Window Minimize" = "Meta+Down";
          "Window Close" = "Meta+W";
          "Window Fullscreen" = "Meta+Ctrl+F";
          "Window to Desktop 1" = "Meta+Shift+1";
          "Window to Desktop 2" = "Meta+Shift+2";
          "Window to Desktop 3" = "Meta+Shift+3";
          "Window to Desktop 4" = "Meta+Shift+4";
        };
        "services/org.kde.krunner.desktop" = { "_launch" = "Meta+Space"; };
      };
      hotkeys.commands = {
        "launch-konsole" = {
          name = "Launch Terminal";
          key = "Meta+Return";
          command = "konsole";
        };
        "launch-dolphin" = {
          name = "Launch File Manager";
          key = "Meta+E";
          command = "dolphin";
        };
        "launch-firefox" = {
          name = "Launch Browser";
          key = "Meta+B";
          command = "firefox";
        };
      };
      window-rules = [{
        description = "Remove borders for maximized windows";
        match = { window-types = [ "normal" ]; };
        apply = {
          noborder = {
            value = true;
            apply = "force";
          };
        };
      }];
      powerdevil = {
        AC = {
          autoSuspend = {
            action = "sleep";
            idleTimeout = 1800;
          };
          turnOffDisplay = {
            idleTimeout = 600;
            idleTimeoutWhenLocked = 60;
          };
          dimDisplay = {
            enable = true;
            idleTimeout = 300;
          };
          powerButtonAction = "showLogoutScreen";
        };
        battery = {
          autoSuspend = {
            action = "sleep";
            idleTimeout = 900;
          };
          turnOffDisplay = {
            idleTimeout = 300;
            idleTimeoutWhenLocked = 30;
          };
          dimDisplay = {
            enable = true;
            idleTimeout = 120;
          };
          powerButtonAction = "sleep";
          whenSleepingEnter = "standbyThenHibernate";
        };
        lowBattery = {
          autoSuspend = {
            action = "hibernate";
            idleTimeout = 300;
          };
          whenLaptopLidClosed = "hibernate";
        };
      };
      kscreenlocker = {
        appearance = {
          alwaysShowClock = true;
          showMediaControls = true;
        };
        autoLock = true;
        lockOnResume = true;
        lockOnStartup = false;
        passwordRequired = true;
        passwordRequiredDelay = 5;
        timeout = 10;
      };
      configFile = {
        baloofilerc."Basic Settings"."Indexing-Enabled" = false;
        kwinrc."org.kde.kdecoration2" = {
          ButtonsOnLeft = "XIA";
          ButtonsOnRight = "";
        };
        kwinrc.Windows = {
          BorderlessMaximizedWindows = true;
          RollOverDesktops = true;
        };
        kwinrc.Compositing = {
          Backend = "OpenGL";
          GLCore = true;
          GLPreferBufferSwap = "a";
          GLTextureFilter = 2;
          HiddenPreviews = 5;
          OpenGLIsUnsafe = false;
        };
        plasmarc.Theme = { name = "breeze-dark"; };
        krunnerrc.General = {
          FreeFloating = true;
          RetainPriorSearch = false;
        };
        dolphinrc.General = {
          RememberOpenedTabs = true;
          ShowFullPath = true;
          ShowSpaceInfo = true;
        };
        konsolerc."Desktop Entry".DefaultProfile = "Profile.profile";
      };
    };
    home.packages = with pkgs; [
      inter
      jetbrains-mono
      papirus-icon-theme
      bibata-cursors
      kdePackages.plasma-browser-integration
      kdePackages.kdeconnect-kde
      kdePackages.filelight
      kdePackages.spectacle
      kdePackages.gwenview
    ];
    fonts.fontconfig.enable = true;
  };
}
