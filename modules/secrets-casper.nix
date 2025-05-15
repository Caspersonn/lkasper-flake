{config, lib, pkgs, agenix, username, ... }:
{
  environment.systemPackages = with pkgs; [
    age
  ];

  age.secrets = let
    keyconf = keyname: {
      file = ../secrets/${keyname}.age;
      path = "/tmp/${keyname}";
      owner = "casper";
      group = "users";
      mode = "600";
    };

    keyconf_root = keyname: {
      file = ../secrets/${keyname}.age;
      path = "/tmp/${keyname}";
      owner = "root";
      group = "root";
      mode = "600";
    };
  in
    {
      avante-bedrock = keyconf "avante-bedrock";
      spotify = keyconf "spotify";
  };
}
