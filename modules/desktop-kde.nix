{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
	kdePackages.kate
  kdePackages.partitionmanager
  ];

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
}
