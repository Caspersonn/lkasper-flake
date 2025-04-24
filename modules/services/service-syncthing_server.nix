{ config, pkgs, username, ... }:

{
  services.syncthing = {
    enable = true;
    user = "${username}";
    dataDir = "/home/${username}/syncthing";
    configDir = "/home/${username}/.config/syncthing";
    guiAddress = "0.0.0.0:8384";

    settings = {
      devices = {
        gaming-casper.id = "47RNTJS-TRJDF6O-PQMZU2O-G6YCGAR-OF5AIPY-EV65O64-F7MN764-JVSTLQZ";
        home-casper.id = "7D2F46L-KZMRC63-IDF3OL2-T7VGOCD-KRAKNB3-RUM5RUS-YZNVSRT-64BYJQA";
        macbook-pro.id = "UYCT2YS-TFFBICM-3EVXWRZ-6P5B3ZP-7PKBIPD-RERAHVB-YBS3ISU-NWBSRAV";
      };

      folders = {
        "retroarch-saves" = {
          path = "/home/${username}/syncthing/retroarch/saves";
          devices = [ "gaming-casper" "home-casper" ];
        };
        "retroarch-states" = {
          path = "/home/${username}/syncthing/retroarch/states";
          devices = [ "gaming-casper" "home-casper" ];
        };
        "macbook-desktop" = {
          path = "/home/${username}/syncthing/macbook/desktop";
          devices = [ "macbook-pro" ];
          type = "receiveonly";
        };
      };
    };
  };
}
