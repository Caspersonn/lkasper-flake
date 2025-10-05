{
pkgs,
config,
lib,
username,
hostname,
  ...
}@args:
let
  cfg = config.roles.hyprland;
  inherit (import ../../../hosts/${hostname}/variables.nix) waybarChoice;
in
{
  options.roles.hyprland = {
    enable = lib.mkEnableOption "hyprland compositor";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (import ./hyprland.nix args)
      (import ./walker.nix args)
      (import ./hypridle.nix args)
      (import ./waybar args)
      (import ./hyprlock args)
      (import ./script.nix args)
      (import ./swaync.nix args)
      (import ./eww args)
    ]
  );
}


