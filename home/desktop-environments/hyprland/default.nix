{
pkgs,
config,
lib,
username,
  ...
}@args:
let
  cfg = config.roles.hyprland;
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
    ]
  );
}


