{config, lib, pkgs, unstable, ... }:
let 
  cfg = config.roles.kde;
in
{
  environment.systemPackages = with pkgs; [
    kdePackages.kate
    kdePackages.partitionmanager
  ];

  services = {
    displayManager.sddm.enable = true; 
    desktopManager.plasma6 = {
      enable = true;
    };
    xserver = {
      enable = true;
    };
  }; 
 
#  qt = {
#    enable = true;
#    platformTheme = "gnome";
#    style = "adwaita-dark";
#  };
}
