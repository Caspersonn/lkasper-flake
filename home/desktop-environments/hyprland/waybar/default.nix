{config, lib, pkgs, ...}:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
    settings = {
      mainBar = {
        layer = "top";
        height = 40;
        #spacing = 10;
        modules-left = ["hyprland/workspaces"];
        modules-center = ["clock" "custom/weather"];
        modules-right =["tray" "pulseaudio" "bluetooth" "network" "cpu" "memory" "battery" "power-profiles-daemon" "custom/power"];

        "hyprland/workspaces" = {
          disable-scroll = true;
          format = "{icon}";
          #  format-icons = {
          #    # Monitor 1
          #    "1" = "";
          #    "2" = "󰈹";
          #    "3" = "";
          #    "4" = "󰌨";
          #    "5" = "";
          #    # Monitor 2
          #    "11" = "";
          #    "12" = "󰈹";
          #    "13" = "";
          #    "14" = "";
          #    #active = "";
          #    default = "";
          #  };
        };

        cpu = {
          interval = 10;
          format = "{}% ";
          max-length = 10;
        };

        memory = {
          interval = 10;
          format = "{}% ";
          max-length = 10;
        };

        network = {
          # interface: "wlp2s0", // (Optional) To force the use of this interface
          format-wifi = "   ({signalStrength}%)";
          format-ethernet = "󰛳";
          format-disconnected = "⚠";
          on-click = "kitty -e nmtui";
        };

        pulseaudio = {
          format = "{icon}";
          format-bluetooth = "{icon}";
          format-muted = "";
          format-icons = {
              default = ["" ""];
          };
          on-click = "pavucontrol";
        };

        bluetooth = {
          format-on = "󰂯";
          format-off = "󰂲";
          format-disabled = "󰂲";
          format-connected-battery = "󰂯  {device_battery_percentage}%";
          #format-alt = "{device_alias} 󰂯";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\n{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\n{device_address}\n{device_battery_percentage}%";
          on-click = "blueberry";
        };

        "hyprland/window" = {
          max-length = 50;
        };

        battery = {
          interval = 15;
          format = "{capacity}% {icon}";
          format-icons = ["󰁺" "󰁽" "󰁿" "󰂀" "󰁹"];
          format-charging = "{capacity}% 󰂄";
          format-plugged = "{capacity}% 󰂅";
          full-at = 95;
          states = {
            "good" = 90;
            "warning" = 30;
            "critical" = 15;
          };
        };

        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            default = "";
            performance = "";
            balanced = "";
            power-saver = "";
          };
        };

        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          #format-alt = "{:%a, %d. %b  %H:%M}";
          format = "{:%a; %d %b, %I:%M %p}";
        };

        "custom/weather" = {
          format = "{}";
          tooltip = true;
          interval = 1800;
          exec = "wttrbar";
          return-type = "json";
        };

        tray = {
          spacing = 10;
        };
        "custom/power" = {
          format = "";
          tooltip = false;
          on-click = "wlogout";
        };
      };
    };
    style = ''
      /* Gruvbox colors */
      @define-color bg0_h #1d2021;
      @define-color bg0 #282828;
      @define-color bg1 #3c3836;
      @define-color bg2 #504945;
      @define-color bg3 #665c54;
      @define-color bg4 #7c6f64;
      @define-color fg0 #fbf1c7;
      @define-color fg1 #ebdbb2;
      @define-color fg2 #d5c4a1;
      @define-color fg3 #bdae93;
      @define-color fg4 #a89984;
      @define-color red #cc241d;
      @define-color green #98971a;
      @define-color yellow #d79921;
      @define-color blue #458588;
      @define-color purple #b16286;
      @define-color aqua #689d6a;
      @define-color orange #d65d0e;
      @define-color gray #928374;

      * {
        border: none;
        border-radius: 0;
        font-family: "Source Code Pro", "Font Awesome 6 Free";
        font-size: 14px;
        min-height: 0;
        transition-duration: 0.3s;
      }

      window#waybar {
        background: transparent;
        color: @fg1;
        padding: 0 10px; /* Add horizontal padding to the entire bar */
      }

      tooltip {
        background: @bg0_h;
        border: 2px solid @bg4;
        border-radius: 6px;
      }

      tooltip label {
        color: @fg1;
      }

      #clock {
        padding-left: 16px;
        border-radius: 10px 0px 0px 10px;
        transition: none;
        color: @fg3;
        background: @bg1;
        margin: 6px 0 0 0;
    }

    #custom-weather {
        padding-right: 16px;
        border-radius: 0px 10px 10px 0px;
        transition: none;
        color: @fg3;
        background: @bg1;
        margin: 6px 0 0 0;
        padding: 0 10px;
    }

      #workspaces {
        background: @bg1;
        border-radius: 10px;
        margin: 6px 0 0 8px;
        padding: 0 6px;
      }

      #workspaces button.active {
          color: @brgreen;
          font-weight: bold;
          text-shadow: 0px 0px 3px @brgreen;
      }

      #workspaces button {
        padding: 0 7px;
        color: @fg3;
        border-radius: 4px;
        margin: 4px 2px;
      }

      #workspaces button:hover {
        background: @bg2;
        color: @fg1;
      }

      #tray {
        background: @bg1;
        margin: 6px 0 0 0;
        padding: 0 10px;
        border-radius: 10px;
      }

      #pulseaudio {
        background: @bg1;
        color: @fg3;
        margin: 6px 0 0 10px;
        padding: 0 10px;
        border-radius: 10px 0px 0px 10px;
      }

      #pulseaudio.muted, #pulseaudio.source-muted {
        background: @bg2;
        color: @fg3;
      }

      #bluetooth {
        background: @bg1;
        color: @fg3;
        margin: 6px 0 0 0;
        padding: 0 10px;
        border-radius: 0px 0px 0px 0px;
      }

      #bluetooth.off, #bluetooth.disabled {
        background: @bg2;
        color: @fg3;
      }

      #network {
        background: @bg1;
        color: @fg3;
        margin: 6px 0 0 0;
        padding: 0 10px;
        border-radius: 0px 10px 10px 0px;
      }

      #network.disconnected {
        background: @bg1;
        color: @red;
      }

      #cpu {
        background: @bg1;
        color: @fg3;
        margin: 6px 0 0 10px;
        padding-right: 16px;
        padding: 0 10px;
        border-radius: 10px 0px 0px 10px;
      }

      #memory {
        background: @bg1;
        color: @fg3;
        margin: 6px 0 0 0;
        padding-left: 16px;
        padding: 0 10px;
        border-radius: 0px 10px 10px 0px;
      }

      #battery {
        background: @bg1;
        color: @fg3;
        margin: 6px 0 0 10px;
        padding: 0 10px;
        border-radius: 10px;
      }

      #power-profiles-daemon {
        background: @bg1;
        color: @fg3;
        margin: 6px 0 0 10px;
        padding-left: 16px;
        padding: 0 10px;
        border-radius: 10px 0px 0px 10px;
      }

      #battery.warning {
        color: @yellow;
      }

      #battery.critical {
        color: @red;
      }

      #battery.charging {
        color: @green;
      }

      #custom-power {
        background: @bg1;
        color: @fg3;
        margin: 6px 8px 0 0;
        padding-right: 16px;
        padding: 0 10px;
        border-radius: 0px 10px 10px 0px;
      }
    '';
  };
}
