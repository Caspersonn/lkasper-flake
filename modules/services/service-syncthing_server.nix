{ config, pkgs, username, ... }:

{
  services.syncthing = {
    enable = true;
    user = "${username}";
    dataDir = "/home/${username}/syncthing";
    configDir = "/home/${syncthing}/.config/syncthing";

    devices = {
      gaming-casper.id = "DEVICE-ID-GAMING-PC";
      home-casper.id = "DEVICE-ID-LAPTOP";
    };

    folders = {
      "retroarch-saves" = {
        path = "/home/${username}/syncthing/retroarch/save";
        devices = [ "gaming-casper" "home-casper" ];
      };
      "retroarch-states" = {
        path = "/home/${username}/syncthing/retroarch/state";
        devices = [ "gaming-casper" "home-casper" ];
      };
    };
  };
}
