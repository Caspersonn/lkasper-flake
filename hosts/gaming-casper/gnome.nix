{config, lib, pkgs,  agenix, ... }:

{
  environment.systemPackages = with pkgs; [
    gnomeExtensions.dock-from-dash
    gnomeExtensions.dash-to-dock
    gnomeExtensions.date-menu-formatter
    gnomeExtensions.gsconnect
    gnomeExtensions.night-light-slider-updated
    gnomeExtensions.unite
    gnomeExtensions.arcmenu
  ];
} 
