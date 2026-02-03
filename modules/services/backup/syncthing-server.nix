{ inputs, ... }: {
  flake.modules.nixos.syncthing-server = { config, pkgs, ... }: {
    services.syncthing = {
      enable = true;
      user = "casper";
      dataDir = "${config.users.users.casper.home}/syncthing";
      configDir = "${config.users.users.casper.home}/.config/syncthing";
      guiAddress = "0.0.0.0:8384";

      settings = {
        devices = {
          gaming-casper.id =
            "47RNTJS-TRJDF6O-PQMZU2O-G6YCGAR-OF5AIPY-EV65O64-F7MN764-JVSTLQZ";
          home-casper.id =
            "7D2F46L-KZMRC63-IDF3OL2-T7VGOCD-KRAKNB3-RUM5RUS-YZNVSRT-64BYJQA";
          macbook-pro.id =
            "UYCT2YS-TFFBICM-3EVXWRZ-6P5B3ZP-7PKBIPD-RERAHVB-YBS3ISU-NWBSRAV";
        };

        folders = {
          "retroarch-saves" = {
            path = "${config.users.users.casper.home}/syncthing/retroarch/saves";
            devices = [ "gaming-casper" "home-casper" ];
          };
          "retroarch-roms" = {
            path = "${config.users.users.casper.home}/syncthing/retroarch/roms";
            devices = [ "gaming-casper" "home-casper" ];
          };
          "retroarch-thumbnails" = {
            path = "${config.users.users.casper.home}/syncthing/retroarch/thumbnails";
            devices = [ "gaming-casper" "home-casper" ];
          };
          "retroarch-system" = {
            path = "${config.users.users.casper.home}/syncthing/retroarch/system";
            devices = [ "gaming-casper" "home-casper" ];
          };
          "macbook-desktop" = {
            path = "${config.users.users.casper.home}/syncthing/macbook/desktop";
            devices = [ "macbook-pro" ];
            type = "receiveonly";
          };
        };
      };
    };
  };
}
