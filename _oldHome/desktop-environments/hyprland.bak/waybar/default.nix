{ hostname, ... }: let
  inherit (import ../../hosts/${hostname}/variables.nix) waybarChoice;
in
{
  imports = [
    ./waybar.nix
  ];
}
