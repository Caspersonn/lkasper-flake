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
  heroic
  unstable.multiviewer-for-f1
  vulkan-tools
  ];
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };
}
