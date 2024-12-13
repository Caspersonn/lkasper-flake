{config, lib, pkgs,  agenix, ... }:
{

  age = {
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      spotify = {
        file = ../secrets/spotify-lucak.age;
        path = "/home/lucak/.config/spotify/prefs";
        owner = "lucak";
        group = "users";
        mode = "600";
      };
#      toggl = {
#        file = ../secrets/toggl.age;
#        path = "";
#        owner = "lucak";
#        group = "users";
#        mode = "600";
#      };
     };
  };


}
