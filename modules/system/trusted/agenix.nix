{ inputs, ... }: {
  flake.modules.nixos.secrets = { config, lib, pkgs, ... }: {
    environment.systemPackages = with pkgs; [ age ];

    age.secrets = let
      keyconf = keyname: {
        file = ../../../secrets/${keyname}.age;
        path = "/tmp/${keyname}";
        owner = "casper";
        group = "users";
        mode = "600";
      };

      keyconf_root = keyname: {
        file = ../../../secrets/${keyname}.age;
        path = "/tmp/${keyname}";
        owner = "root";
        group = "root";
        mode = "600";
      };
    in {
      avante-bedrock = keyconf "avante-bedrock";
      avante-openai = keyconf "avante-openai";
      google-bedrock = keyconf "google-bedrock";
      google-engine-bedrock = keyconf "google-engine-bedrock";
      mqtt-zigbee2mqtt-password =  keyconf "mqtt-zigbee2mqtt-password";
      mqtt-homeassistant-password = keyconf "mqtt-homeassistant-password";
      zigbee2mqtt-env = keyconf "zigbee2mqtt-env";
      aiostreams_secret_key = keyconf "aiostreams-secret-key";
      aiostreams_auth = keyconf "aiostreams-auth";
      #spotify = keyconf "spotify";
    };
  };
}
