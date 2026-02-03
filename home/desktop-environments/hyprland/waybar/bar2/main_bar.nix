{
  layer = "top";
  height = 40;
  #spacing = 10;
  modules-left = ["hyprland/workspaces"];
  modules-center = ["clock" "custom/weather"];
  modules-right =["tray" "pulseaudio" "bluetooth" "network" "cpu" "memory" "battery" "power-profiles-daemon" "custom/power" "custom/notification"];

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

  "custom/notification" = {
    tooltip = false;
    format = "{icon}";
    format-icons = {
      notification = "";
      none = "";
      dnd-notification = "";
      dnd-none = "";
      inhibited-notification = "";
      inhibited-none = "";
      dnd-inhibited-notification = "";
      dnd-inhibited-none = "";
    };
    return-type = "json";
    exec-if = "which swaync-client";
    exec = "swaync-client -swb";
    on-click = "swaync-client -t -sw";
    on-click-right = "swaync-client -d -sw";
    escape = true;
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
    on-click = "ghostty -e wiremix";
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
    tooltip-format = "<tt><small>{calendar}</small></tt>";
    format = "{:%d %b, %H:%M}";
    calendar = {
      mode          = "year";
      mode-mon-col  = 3;
      weeks-pos     = "right";
      on-scroll     = 1;
      on-click-right= "mode";
      format = {
        months =     "<span color='#ffead3'><b>{}</b></span>";
        days =       "<span color='#bdae93'><b>{}</b></span>";
        weeks =      "<span color='#cc241d'><b>W{}</b></span>";
        weekdays =   "<span color='#928374'><b>{}</b></span>";
        today =      "<span color='#98971a'><b><u>{}</u></b></span>";
      };
    };
    actions = {
      on-click-right = "mode";
      on-click-forward = "tz_up";
      on-click-backward = "tz_down";
      on-scroll-up = "shift_up";
      on-scroll-down = "shift_down";
    };
  };

  "custom/weather" = {
    format = "{}";
    tooltip = true;
    interval = 1800;
    exec = "wttrbar --date-format '%m/%d' --location zwolle --hide-conditions";
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
}
