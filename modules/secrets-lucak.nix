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
      #aws_config = {
      #  file = ../secrets/aws_config.age;
      #  path = "/home/lucak/.aws/config";
      #  owner = "lucak";
      #  group = "users";
      #  mode = "600";
      #};
      #aws_credentials = {
      #  file = ../secrets/aws_credentials.age;
      #  path = "/home/lucak/.aws/credentials";
      #  owner = "lucak";
      #  group = "users";
      #  mode = "600";
      #};
    };
  };
}
