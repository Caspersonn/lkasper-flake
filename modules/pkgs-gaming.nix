{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
  beekeeper-studio
  cemu
	flatpak
	gamescope
	protontricks
	rpcs3
	steam
	steam-tui
	wine
  discord
  gamemode
  goverlay
  lutris
  mangohud
  mesa
  ns-usbloader
  protonplus
  ps3iso-utils
  stremio
  unstable.multiviewer-for-f1
  vulkan-tools
  ];
}
