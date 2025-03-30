{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
	flatpak
	gamescope
	protontricks
	rpcs3
	steam-tui
  android-tools
  appimage-run
  beekeeper-studio
  ddcui
  ddcutil
  discord
  gamemode
  goverlay
  heroic
  libGL
  lutris
  mangohud
  mesa
  ns-usbloader
  protonplus
  ps3iso-utils
  prismlauncher
  radeontop
  steam
  stremio
  unstable.cemu
  unstable.multiviewer-for-f1
  vulkan-tools
  wine64Packages.unstableFull
  wineWow64Packages.unstableFull
  ];
}
