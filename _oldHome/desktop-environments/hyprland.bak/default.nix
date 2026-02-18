{hostname, ...}: let
  inherit (import ../../../hosts/${hostname}/variables.nix) animChoice;
in 
  {
  imports = [
    animChoice
    ./binds.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./windowrules.nix

    ./rofi
    ./waybar
  ];
}

