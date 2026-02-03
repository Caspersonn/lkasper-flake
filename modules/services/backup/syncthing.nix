{ inputs, ... }: {
  flake.modules.nixos.syncthing = { config, pkgs, ... }: {
    services.syncthing = {
      enable = true;
      user = "casper";
      dataDir = "${config.users.users.casper.home}/.config/syncthing";
      configDir = "${config.users.users.casper.home}/.config/syncthing";

      settings = {
        devices = {
          server.id =
            "U72AHTO-3SBUUYX-CIYNDMF-VSSXYAS-YAV6V56-LQ4LSKP-7J3RGLV-DNVCZQ5";
        };

        folders = {
          "retroarch-saves" = {
            path = "${config.users.users.casper.home}/.config/retroarch/saves";
            devices = [ "server" ];
          };
          "retroarch-roms" = {
            path = "${config.users.users.casper.home}/.config/retroarch/roms";
            devices = [ "server" ];
          };
          "retroarch-thumbnails" = {
            path = "${config.users.users.casper.home}/.config/retroarch/thumbnails";
            devices = [ "server" ];
          };
          "retroarch-system" = {
            path = "${config.users.users.casper.home}/.config/retroarch/system";
            devices = [ "server" ];
          };
        };
      };
    };
  };
}
