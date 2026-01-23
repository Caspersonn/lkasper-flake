{...}:
let
  hyprlockDir = "$HOME/.config/hypr";
  music = "${hyprlockDir}/scripts/playerlock.sh";
in

{
  home.sessionVariables = {
    hyprlockDir = hyprlockDir;
    music = music;
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      auth = {
        "fingerprint:enabled" = true;
      };

      background = {
        monitor = "";
        path = "$HOME/.cache/current-wallpaper";
        blur_passes = 3;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };

      general = {
        no_fade_in = false;
        grace = 0;
        disable_loading_bar = true;
      };

      image = [
        {
          monitor = "eDP-1";
          path = "$HOME/lkasper-flake/home/desktop-environments/hyprland/hyprlock/Profile Picture.jpg";
          border_size = 2;
          border_color = "rgba(255, 255, 255, 0)";
          size = 150;
          rounding = -1;
          rotate = 0;
          reload_time = -1;
          reload_cmd = "";
          position = "0, 40";
          halign = "center";
          valign = "center";
        }
      ];

      shape = [
        {
          monitor = "eDP-1";
          size = "300, 60";
          color = "rgba(255, 255, 255, .1)";
          rounding = -1;
          border_size = 0;
          border_color = "rgba(253, 198, 135, 0)";
          rotate = 0;
          xray = false;
          position = "0, -130";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "eDP-1";
          text = ''cmd[update:1000] echo -e "$(date +"%A, %B %d")"'';
          color = "rgba(216, 222, 233, 0.70)";
          font_size = 25;
          font_family = "SF Pro Display Bold";
          position = "0, 350";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "eDP-1";
          text = ''cmd[update:1000] echo $(date +"%H:%M")'';
          color = "rgba(216, 222, 233, 0.70)";
          font_size = 120;
          font_family = "SF Pro Display Bold";
          position = "0, 250";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "eDP-1";
          text = "  $USER";
          color = "rgba(216, 222, 233, 0.80)";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          font_size = 18;
          font_family = "SF Pro Display Bold";
          position = "0, -130";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "eDP-1";
          text = ''cmd[update:1000] echo "$(${music})"'';
          color = "rgba(255, 255, 255, 1)";
          font_size = 14;
          font_family = "JetBrains Mono Nerd Font Mono";
          position = "0, 100";
          halign = "center";
          valign = "bottom";
          zindex = 5;
        }
      ];

      input-field = [
        {
          monitor = "eDP-1";
          size = "300, 60";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(255, 255, 255, 0.1)";
          font_color = "rgb(200, 200, 200)";
          fade_on_empty = false;
          font_family = "SF Pro Display Bold";
          placeholder_text = "<i><span foreground=\"##ffffff99\">🔒 Enter Pass</span></i>";
          hide_input = false;
          position = "0, -210";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
