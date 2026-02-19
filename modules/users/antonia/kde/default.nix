{inputs, ... }: {
  flake.modules.homeManager.kde = { pkgs, config, lib, ... }:

    {
      programs.plasma = {
        enable = true;

        #
        # === WORKSPACE & APPEARANCE (macOS-like Dark Theme) ===
        #
        workspace = {
          clickItemTo = "open";
          lookAndFeel = "org.kde.breezedark.desktop";

          cursor = {
            theme = "Bibata-Modern-Classic"; # Elegant cursor similar to macOS
            size = 24;
          };

          iconTheme = "Papirus-Dark";

          # macOS-style wallpaper (you can customize this)
          wallpaper =
            "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1080x1920.png";

          # macOS-like smooth window animations
          windowDecorations = {
            library = "org.kde.breeze";
            theme = "Breeze";
          };
        };

        #
        # === FONTS (San Francisco-like) ===
        #
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

        #
        # === PANELS: macOS-style Top Bar + Bottom Dock ===
        #
        panels = [
          # Top Bar (macOS-style menu bar)
          {
            location = "top";
            height = 28;
            floating = false;
            hiding = "none";

            widgets = [
              # Application Menu (left side, like macOS)
              {
                kickoff = {
                  icon = "nix-snowflake-white";
                  label = "";
                  sortAlphabetically = true;
                };
              }

              # Application Title Bar (shows current app name)
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

              # Global Menu (macOS-style menu bar)
              "org.kde.plasma.appmenu"

              # Spacer to push right-side widgets to the right
              "org.kde.plasma.panelspacer"

              # System Tray (macOS-style)
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

              # Digital Clock (macOS-style)
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

          # Bottom Dock (macOS-style)
          {
            location = "bottom";
            height = 58;
            lengthMode = "fit";
            alignment = "center";
            hiding = "dodgewindows"; # Auto-hide when windows overlap
            floating = true;

            widgets = [
              # Icons-Only Task Manager (macOS-style dock)
              {
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
                    showTasks = "onlyInCurrentActivity";
                    sortMode = "manually";
                    unhideOnAttentionNeeded = true;
                    wheel = {
                      ignoreMinimizedTasks = true;
                      switchBetweenTasks = true;
                    };
                  };
                  # Pin essential applications (customize as needed)
                  launchers = [
                    "applications:org.kde.dolphin.desktop"
                    "applications:firefox.desktop"
                    "applications:org.kde.konsole.desktop"
                    "applications:org.kde.kate.desktop"
                    "applications:org.kde.discover.desktop"
                    "applications:systemsettings.desktop"
                  ];
                };
              }
            ];
          }
        ];

        #
        # === DESKTOP WIDGETS ===
        #
        desktop.widgets = [
          # Optional: Add a digital clock widget on desktop
          # Uncomment if you want a desktop clock
          # {
          #   digitalClock = {
          #     position = {
          #       horizontal = 1800;
          #       vertical = 50;
          #     };
          #     size = {
          #       width = 200;
          #       height = 100;
          #     };
          #   };
          # }
        ];

        #
        # === WINDOW MANAGEMENT (macOS-like behavior) ===
        #
        kwin = {
          # Smooth edges and corners
          edgeBarrier = 0;
          cornerBarrier = false;

          # Effects for smooth animations
          effects = {
            blur.enable = true;
            desktopSwitching.animation = "slide";
            dimInactive.enable = true;
            translucency.enable = true;
            windowOpenClose.animation = "glide";
          };

          # Virtual desktops (Spaces in macOS)
          virtualDesktops = {
            rows = 1;
            number = 4;
            names = [ "Main" "Work" "Media" "Other" ];
          };
        };

        #
        # === KEYBOARD SHORTCUTS (macOS-inspired) ===
        #
        shortcuts = {
          # Lock screen
          ksmserver = { "Lock Session" = [ "Meta+Ctrl+Q" "Screensaver" ]; };

          # Window management
          kwin = {
            # Mission Control style overview
            "Expose" = "Meta+Tab";
            "ExposeAll" = "Meta+A";

            # Window switching (Cmd+` style)
            "Walk Through Windows" = "Alt+Tab";
            "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";

            # Desktop switching (macOS Spaces)
            "Switch to Desktop 1" = "Meta+1";
            "Switch to Desktop 2" = "Meta+2";
            "Switch to Desktop 3" = "Meta+3";
            "Switch to Desktop 4" = "Meta+4";

            # Window management
            "Window Maximize" = "Meta+Up";
            "Window Minimize" = "Meta+Down";
            "Window Close" = "Meta+W";
            "Window Fullscreen" = "Meta+Ctrl+F";

            # Move window between desktops
            "Window to Desktop 1" = "Meta+Shift+1";
            "Window to Desktop 2" = "Meta+Shift+2";
            "Window to Desktop 3" = "Meta+Shift+3";
            "Window to Desktop 4" = "Meta+Shift+4";
          };

          # Application launching
          "services/org.kde.krunner.desktop" = {
            "_launch" = "Meta+Space"; # Spotlight-style launcher
          };
        };

        #
        # === CUSTOM HOTKEYS ===
        #
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

        #
        # === WINDOW RULES (macOS-like window behavior) ===
        #
        window-rules = [
          # Remove borders for maximized windows (macOS style)
          {
            description = "Remove borders for maximized windows";
            match = { window-types = [ "normal" ]; };
            apply = {
              noborder = {
                value = true;
                apply = "force";
              };
            };
          }
        ];

        #
        # === POWER MANAGEMENT ===
        #
        powerdevil = {
          AC = {
            autoSuspend = {
              action = "sleep";
              idleTimeout = 1800; # 30 minutes
            };
            turnOffDisplay = {
              idleTimeout = 600; # 10 minutes
              idleTimeoutWhenLocked = 60; # 1 minute
            };
            dimDisplay = {
              enable = true;
              idleTimeout = 300; # 5 minutes
            };
            powerButtonAction = "showLogoutScreen";
          };
          battery = {
            autoSuspend = {
              action = "sleep";
              idleTimeout = 900; # 15 minutes
            };
            turnOffDisplay = {
              idleTimeout = 300; # 5 minutes
              idleTimeoutWhenLocked = 30; # 30 seconds
            };
            dimDisplay = {
              enable = true;
              idleTimeout = 120; # 2 minutes
            };
            powerButtonAction = "sleep";
            whenSleepingEnter = "standbyThenHibernate";
          };
          lowBattery = {
            autoSuspend = {
              action = "hibernate";
              idleTimeout = 300; # 5 minutes
            };
            whenLaptopLidClosed = "hibernate";
          };
        };

        #
        # === SCREEN LOCKER ===
        #
        kscreenlocker = {
          appearance = {
            alwaysShowClock = true;
            showMediaControls = true;
          };
          autoLock = true;
          lockOnResume = true;
          lockOnStartup = false;
          passwordRequired = true;
          passwordRequiredDelay = 5; # 5 seconds grace period
          timeout = 10; # Lock after 10 minutes
        };

        #
        # === LOW-LEVEL CONFIGURATION ===
        #
        configFile = {
          # Disable file indexing (better performance)
          baloofilerc."Basic Settings"."Indexing-Enabled" = false;

          # macOS-style window buttons (close on left)
          kwinrc."org.kde.kdecoration2" = {
            ButtonsOnLeft = "XIA"; # Close, Minimize, Keep Above on left
            ButtonsOnRight = ""; # Nothing on right (or use "H" for help)
          };

          # Window decorations
          kwinrc.Windows = {
            BorderlessMaximizedWindows = true;
            RollOverDesktops = true;
          };

          # Compositor settings for smooth animations
          kwinrc.Compositing = {
            Backend = "OpenGL";
            GLCore = true;
            GLPreferBufferSwap = "a"; # Auto
            GLTextureFilter = 2; # Bilinear
            HiddenPreviews = 5; # Show previews
            OpenGLIsUnsafe = false;
          };

          # Plasma theme settings
          plasmarc.Theme = { name = "breeze-dark"; };

          # Configure KRunner (Spotlight-like)
          krunnerrc.General = {
            FreeFloating = true;
            RetainPriorSearch = false;
          };

          # Dolphin (File Manager) settings
          dolphinrc.General = {
            RememberOpenedTabs = true;
            ShowFullPath = true;
            ShowSpaceInfo = true;
          };

          # Konsole (Terminal) settings
          konsolerc."Desktop Entry".DefaultProfile = "Profile.profile";
        };
      };

      #
      # === ADDITIONAL PACKAGES FOR macOS-LIKE EXPERIENCE ===
      #
      home.packages = with pkgs; [
        # Fonts for macOS-like appearance
        inter
        jetbrains-mono

        # Icon themes
        papirus-icon-theme
        bibata-cursors

        # KDE enhancement tools
        kdePackages.plasma-browser-integration
        kdePackages.kdeconnect-kde

        # Additional utilities
        kdePackages.filelight # Disk usage analyzer (like macOS DaisyDisk)
        kdePackages.spectacle # Screenshot tool (like macOS Screenshot)
        kdePackages.gwenview # Image viewer
      ];

      #
      # === FONTS CONFIGURATION ===
      #
      fonts.fontconfig.enable = true;
    };
}
