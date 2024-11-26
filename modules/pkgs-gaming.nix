{config, lib, pkgs, agenix, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
	flatpak
	gamescope
	protontricks
	rpcs3
	steam
	steam-tui
  stremio
	wine
  discord
  gamemode
  goverlay
  lutris
  mangohud
  mesa
  protonplus
  vulkan-tools
  ];
}
