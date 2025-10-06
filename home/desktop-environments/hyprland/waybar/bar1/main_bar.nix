{
  layer = "top";
  position = "top";

  modules-left = [ "hyprland/workspaces" ];
  modules-center = [ "clock" "custom/weather" ];
  modules-right = [
    "pulseaudio"
    "custom/uptime"
    "battery"
    "network"
    "cpu"
    "memory"
    "custom/docker"
    "tray"
    "custom/lock"
    "custom/power"
  ];

  "hyprland/workspaces" = {
    format = "{name}: {icon}";
    format-icons = {
      active = "";
      default = "";
    };
  };

  tray = {
    icon-size = 16;
    spacing = 10;
  };

  "custom/music" = {
    format = "  {}";
    escape = true;
    interval = 5;
    tooltip = false;
    exec = "playerctl metadata --format='{{ artist }} - {{ title }}'";
    on-click = "playerctl play-pause";
    max-length = 50;
  };

  clock = {
    tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
    format = "{:%d/%m/%Y - %H:%M:%S}";
    interval = 1;
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

  network = {
    format-wifi = "󰤢 {bandwidthDownBits}";
    format-ethernet = "󰈀 {bandwidthDownBits}";
    format-disconnected = "󰤠 No Network";
    interval = 5;
    tooltip = false;
  };

  cpu = {
    interval = 1;
    format = "  {icon0}{icon1}{icon2}{icon3} {usage:>2}%";
    format-icons = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
  };

  memory = {
    interval = 30;
    format = "  {used:0.1f}G/{total:0.1f}G";
  };

  "custom/uptime" = {
    format = "{}";
    interval = 1600;
    exec = "sh -c '(uptime -p)'";
  };

  pulseaudio = {
    format = "{icon} {volume}%";
    format-muted = "";
    format-icons = {
      default = [ "" "" " " ];
    };
    on-click = "pavucontrol";
  };

  "custom/power" = {
    tooltip = false;
    on-click = "wlogout &";
    format = "⏻";
  };

  "custom/docker" = {
    format = "{}";
    return-type = "json";
    interval = 10;
    exec = "$(pwd)/scripts/docker-stats/docker-stats";
    tooltip = true;
  };

  #"custom/weather" = {
  #  format = "{}";
  #  tooltip = true;
  #  interval = 1800;
  #  exec = "$(pwd)/scripts/weather-stats/weather-stats";
  #  return-type = "json";
  #};
  "custom/weather" = {
    format = "{}";
    tooltip = true;
    interval = 1800;
    exec = "wttrbar --date-format '%m/%d' --location zwolle --hide-conditions";
    return-type = "json";
  };

}

