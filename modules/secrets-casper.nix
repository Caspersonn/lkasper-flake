{config, lib, pkgs,  agenix, ... }:
{

  age = {
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      spotify = {
        file = ../secrets/spotify-casper.age;
        path = "/home/casper/.config/spotify/prefs";
        owner = "casper";
        group = "users";
        mode = "600";
      };
#      steam = {
#        file = ../secrets/steam.age;
#        path = "";
#        owner = "casper";
#        group = "users";
#        mode = "600";
#      };
     };
  };
}
