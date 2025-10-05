{hostname, ...}:
let
  inherit (import ../../../../hosts/${hostname}/variables.nix) waybarChoice;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
    settings.mainBar = import ./${waybarChoice}/main_bar.nix;
    style = ./${waybarChoice}/style.css;
  };
}
