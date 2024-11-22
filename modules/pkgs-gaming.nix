{config, lib, pkgs, agenix, unstable, ... }:
	
{
  environment.systemPackages = with pkgs; [
	flatpak
	gamescope
	protontricks
	rpcs3
	steam
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
