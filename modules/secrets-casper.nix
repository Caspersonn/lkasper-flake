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
      google-bedrock = keyconf "google-bedrock";
      google-engine-bedrock = keyconf "google-engine-bedrock";
      spotify = keyconf "spotify";
  };
}
