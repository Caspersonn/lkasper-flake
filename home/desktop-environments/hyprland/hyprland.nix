{ hostname, pkgs, username, ... }:
let
  hypr_scripts = "/home/${username}/.config/hypr/scripts";
  inherit (import ../../../hosts/${hostname}/variables.nix) browser terminal file_manager;

in
{
  home.sessionVariables = {
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
    #SDL_VIDEODRIVER = "x11";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    WLR_NO_HARDWARE_CURSORS = "1";
    HYPRSHOT_DIR =  "$HOME/${username}/Pictures";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };

  programs.swaylock.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    plugins = [ pkgs.hyprlandPlugins.hyprsplit pkgs.hyprlandPlugins.hyprspace ];

    settings = {
      ################
      ### MONITORS ###
      ################

      # See https://wiki.hyprland.org/Configuring/Monitors/
      # Monitor config is done by nwg-displays
      source = "/home/${username}/.config/hypr/monitors.conf";

      ###################
      ### MY PROGRAMS ###
      ###################

      # See https://wiki.hyprland.org/Configuring/Keywords/

      # Set programs that you use
      "$terminal" = terminal;
      "$fileManager" = file_manager;
      "$menu" = "walker -H";
      "$browser" = browser;
      "$music" = "spotify";

      #################
      ### AUTOSTART ###
      #################

      exec-once = [
        "[workspace 1 silent] $terminal --command='smug lkasper'"
        "[workspace 2 silent] $browser"
        "[workspace 3 silent] $music"
        "avizo-service"
        "swaync"
        "hyprsunset -t 5000"
        "swww-daemon"
        "walker --gapplication-service"
        "elephant"
      ];

      #############################
      ### ENVIRONMENT VARIABLES ###
      #############################

      env = [
        "WLR_DRM_NO_ATOMIC,1"
        "GDK_SCALE,2"
        "XCURSOR_SIZE,24"
        "QT_SCALE_FACTOR,1.3"
      ];

      #####################
      ### LOOK AND FEEL ###
      #####################


      general = {
        gaps_in = 5;
        gaps_out = 6;
        border_size = 2;

        "col.active_border" = "rgb(968996) rgb(968e96) 45deg";
        "col.inactive_border" = "rgba(282828aa)";

        resize_on_border = false;

        allow_tearing = true;

        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = "yes, please :)";

        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
      };

      dwindle = {
        pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # You probably want this
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = -1; # Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = true; # If true disables the random hyprland logo / anime girl background. :(
      };

      xwayland = {
        force_zero_scaling = true;
        #use_nearest_neighbor = false;
      };

      #############
      ### INPUT ###
      #############

      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        follow_mouse = 1;
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

        touchpad = {
          natural_scroll = true;
          scroll_factor = 0.5;
        };
      };

      gestures = {
        #workspace_swipe = true;
        workspace_swipe_distance = 1000;
      };

      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      plugin = {
        hyprsplit = {
          num_workspaces = 10;
        };
      };

      ###################
      ### KEYBINDINGS ###
      ###################

      "$mainMod" = "SUPER"; # Sets "Windows" key as main modifier

      bind = [
        # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
        "$mainMod, T, exec, $terminal"
        "$mainMod, B, exec, $browser"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, L, exec, hyprlock"
        "$mainMod, D, exec, nwg-displays"
        "$mainMod, space, exec, $menu"
        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, P, pseudo,"
        "$mainMod, J, togglesplit,"
        "$mainMod, F, fullscreen"

        "$mainMod ALT, S, exec, hyprshot -m window"
        "$mainMod SHIFT, S, exec, hyprshot -m region"

        # power-profiles-daemon
        "$mainMod+Ctrl+Shift, W, exec, powerprofilesctl set power-saver"
        "$mainMod+Ctrl+Shift, E, exec, powerprofilesctl set balanced"
        "$mainMod+Ctrl+Shift, R, exec, powerprofilesctl set performance"


        # Change wallpapers
        "$mainMod ALT, C, exec, ${hypr_scripts}/wallpaperselect.sh"

        # Monitor manager
        "$mainMod ALT, M, exec, ${hypr_scripts}/monitorctl.sh"

        # Monitor manager
        "$mainMod SHIFT, O, exec, tses open"

        # Focus to other window
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Move to workspace
        "$mainMod, 1, split:workspace, 1"
        "$mainMod, 2, split:workspace, 2"
        "$mainMod, 3, split:workspace, 3"
        "$mainMod, 4, split:workspace, 4"
        "$mainMod, 5, split:workspace, 5"
        "$mainMod, 6, split:workspace, 6"
        "$mainMod, 7, split:workspace, 7"
        "$mainMod, 8, split:workspace, 8"
        "$mainMod, 9, split:workspace, 9"
        "$mainMod, 0, split:workspace, 10"
        "$mainMod, tab, workspace, m+1"
        "$mainMod SHIFT, tab, workspace, m-1"

        # Move application silently to workspace
        "$mainMod SHIFT, 1, split:movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, split:movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, split:movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, split:movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, split:movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, split:movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, split:movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, split:movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, split:movetoworkspacesilent, 9"
        "$mainMod SHIFT, 0, split:movetoworkspacesilent, 10"

        # Move application and follow to workspace
        "$mainMod CTRL, 1, split:movetoworkspace, 1"
        "$mainMod CTRL, 2, split:movetoworkspace, 2"
        "$mainMod CTRL, 3, split:movetoworkspace, 3"
        "$mainMod CTRL, 4, split:movetoworkspace, 4"
        "$mainMod CTRL, 5, split:movetoworkspace, 5"
        "$mainMod CTRL, 6, split:movetoworkspace, 6"
        "$mainMod CTRL, 7, split:movetoworkspace, 7"
        "$mainMod CTRL, 8, split:movetoworkspace, 8"
        "$mainMod CTRL, 9, split:movetoworkspace, 9"
        "$mainMod CTRL, 0, split:movetoworkspace, 10"

        "$mainMod SHIFT, right, resizeactive, 50 0"
        "$mainMod SHIFT, left, resizeactive, -50 0"
        "$mainMod SHIFT, up, resizeactive, 0 -50"
        "$mainMod SHIFT, down, resizeactive, 0 50"

        "$mainMod, S, split:swapactiveworkspaces, current +1"
        "$mainMod, G, split:grabroguewindows"
        #
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, volumectl -u up"
        ",XF86AudioLowerVolume, exec, volumectl -u down"
        ",XF86AudioMute, exec, volumectl toggle-mute"
        ",XF86AudioMicMute, exec, volumectl -m toggle-mute"
        ",XF86MonBrightnessUp, exec, lightctl up"
        ",XF86MonBrightnessDown, exec, lightctl down"
        ",Caps_Lock, exec, sleep 0.1 && swayosd-client --caps-lock-led input19::capslock"
      ];

      bindl = [
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPause, exec, playerctl play-pause"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioPrev, exec, playerctl previous"
      ];

      windowrulev2 = [
        "suppressevent maximize, class:.*"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        "float, class:org.gnome.Nautilus"
        "float, class:org.pulseaudio.pavucontrol"
        "float, class:nwg-displays, title:nwg-displays"
        "float, class:ddcui"
        "float, class:blueberry.py"
        "float, class:kitty"
        "size 50% 50%, class:nwg-displays, title:nwg-displays"
        "size 50% 50%, class:kitty"
        "size 40% 40%, class:org.gnome.Nautilus"
        "size 50% 50%, class:org.pulseaudio.pavucontrol"
      ];
    };
  };
}
