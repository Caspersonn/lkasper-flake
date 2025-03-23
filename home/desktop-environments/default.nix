{hostname, ...}: let
  inherit (import ../../hosts/${hostname}/variables.nix);
in {
  imports = [
    ./gnome
    ./hyprland
  ];
}
