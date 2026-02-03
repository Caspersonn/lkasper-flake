{ inputs, ... }: {
  flake.modules.nixos.kde = { config, lib, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      kdePackages.kate
      kdePackages.partitionmanager
    ];

    services = {
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;
      xserver.enable = true;
    };
  };
}
