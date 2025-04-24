{config, lib, pkgs, agenix, username, ... }:
{

  age = {
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      spotify = {
        file = ../secrets/spotify.age;
        path = "/home/${username}/.config/spotify/prefs";
        owner = "casper";
        group = "users";
        mode = "644";
      };
    };
  };
}
