{config, lib, pkgs, agenix, ... }:
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
      aws_config = {
        file = ../secrets/aws_config.age;
        path = "/home/casper/.aws/config";
        owner = "casper";
        group = "users";
        mode = "600";
      };
      aws_credentials = {
        file = ../secrets/aws_credentials.age;
        path = "/home/casper/.aws/credentials";
        owner = "casper";
        group = "users";
        mode = "600";
      };
    };
  };
}
