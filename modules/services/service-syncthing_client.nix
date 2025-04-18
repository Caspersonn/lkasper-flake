{ config, pkgs, username, hostname, ... }:

{
  services.syncthing = {
    enable = true;
    user = "${username}";
    dataDir = "/home/${username}/.config/syncthing";
    configDir = "/home/${username}/.config/syncthing";

    settings = {
      devices = {
        server.id = "U72AHTO-3SBUUYX-CIYNDMF-VSSXYAS-YAV6V56-LQ4LSKP-7J3RGLV-DNVCZQ5";
      };

      folders = {
        "retroarch-saves" = {
          path = "/home/${username}/.config/retroarch/saves";
          devices = [ "server" ];
        };
        "retroarch-states" = {
          path = "/home/${username}/.config/retroarch/states";
          devices = [ "server" ];
        };
      };
    };
  };
}
