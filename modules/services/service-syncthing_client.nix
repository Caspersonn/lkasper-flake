{ config, pkgs, username, hostname, ... }:

{
  services.syncthing = {
    enable = true;
    user = "${username}";
    dataDir = "/home/${username}/.config/syncthing";
    configDir = "/home/${username}/.config/syncthing";

    devices = {
      server.id = "DEVICE-ID-SERVER";
    };

    folders = {
      "retroarch-saves" = {
        path = "/home/${username}/.config/retroarch/save";
        devices = [ "server" ];
      };
      "retroarch-states" = {
        path = "/home/${username}/.config/retroarch/state";
        devices = [ "server" ];
      };
    };
  };
}
