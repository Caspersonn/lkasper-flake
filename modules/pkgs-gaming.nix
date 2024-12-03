{config, lib, pkgs, agenix, unstable, nixpkgs-2411,... }:

{
  environment.systemPackages = with pkgs; [
  nixpkgs-2411.cemu
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
