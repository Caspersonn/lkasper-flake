{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
  android-tools
  beekeeper-studio
  unstable.cemu
	flatpak
	gamescope
	protontricks
	rpcs3
	steam-tui
  steam
  stremio
  wine64Packages.unstableFull
  wineWow64Packages.unstableFull
  discord
  ddcutil
  ddcui
  gamemode
  goverlay
  lutris
  mangohud
  mesa
  ns-usbloader
  protonplus
  ps3iso-utils
  heroic
  radeontop
  unstable.multiviewer-for-f1
  libGL
  vulkan-tools
  appimage-run
  ];
}
