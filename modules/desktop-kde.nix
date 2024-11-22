{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
	kdePackages.kate
  kdePackages.partitionmanager
  ];

  services = {
    xserver = {
      enable = true;
      displayManager.sddm.enable = true; 
      desktopManager.plasma6 = {
        enable = true;
      };
    };
  }; 
}
