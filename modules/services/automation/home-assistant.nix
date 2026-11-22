{ inputs, ... }: {
  flake.modules.nixos.home-assistant =
    {
      pkgs,
      unstable,
      config,
      ...
    }:
    let
      mapDashboardYaml = (pkgs.formats.yaml { }).generate "map.yaml" { type = "map"; };
    in
    {
      networking.firewall.allowedTCPPorts = [
        8123 # Home Assistant
        8080 # Zigbee2MQTT frontend; remove if you do not want LAN access
        10200 # Wyoming Piper TTS (for voice satellite devices)
        10300 # Wyoming Faster Whisper STT (for voice satellite devices)
      ];
      networking.firewall.allowedUDPPorts = [ 5353 ];

      services.home-assistant = {
        enable = true;
        package = unstable.home-assistant;
        openFirewall = true;
        extraComponents = [
          # Components required to complete the onboarding
          "analytics"
          "google_translate"
          "met"
          "radio_browser"
          "shopping_list"
          "ibeacon"
          "switchbot"
          "zha"
          "mqtt"
          # Recommended for fast zlib compression
          # https://www.home-assistant.io/integrations/isal
          "isal"

          "adguard"
          "ollama"
          "wyoming"
          "matter"
        ];
        config = {
          # Includes dependencies for a basic setup
          # https://www.home-assistant.io/integrations/default_config/
          default_config = { };
          scene = [ ];
          script = { };
        };
      };

      systemd.tmpfiles.rules = [
        "L+ /var/lib/hass/dashboards/map.yaml - - - - ${mapDashboardYaml}"
      ];

      services.zigbee2mqtt = {
        enable = true;
        package = unstable.zigbee2mqtt;

        settings = {
          homeassistant = {
            enabled = true;
          };

          serial = {
            port = "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_5256aab514a1ef118a5fa1a361ce3355-if00-port0";
            #adapter = "zstack";
            #baudrate = 115200;
            #rtscts = false;
          };

          permit_join = false;

          mqtt = {
            base_topic = "zigbee2mqtt";
            server = "mqtt://127.0.0.1:1883";
            user = "zigbee2mqtt";
          };

          frontend = {
            enabled = true;
            host = "0.0.0.0";
            port = 8080;
          };

          advanced = {
            # Only for the first time setup
            #network_key = "GENERATE";
            #pan_id = "GENERATE";
            #ext_pan_id = "GENERATE";

            #channel = 25;

            # 0xaf0f = 44815
            #pan_id = 44815;

            # 5c df 67 fe e2 da 96 c7
            #Ext_pan_id = [
            #  92
            #  223
            #  103
            #  254
            #  226
            #  218
            #  150
            #  199
            #];

            # 30 a4 be 53 b2 8b a6 4e c3 6e 25 a7 3e 0c 11 b2
            #network_key = [
            #  48
            #  164
            #  190
            #  83
            #  178
            #  139
            #  166
            #  78
            #  195
            #  110
            #  37
            #  167
            #  62
            #  12
            #  17
            #  178
            #];
          };
        };
      };

      systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile =
        config.age.secrets.zigbee2mqtt-env.path;

      services.ollama = {
        enable = true;
        package = unstable.ollama;
        loadModels = [ "llama3.2:3b" ];
      };

      services.wyoming.faster-whisper.servers."main" = {
        enable = true;
        model = "base-int8";
        language = "nl";
        uri = "tcp://0.0.0.0:10300";
        device = "cpu";
      };

      services.wyoming.piper.servers."main" = {
        enable = true;
        voice = "nl_BE-nathalie-medium";
        uri = "tcp://0.0.0.0:10200";
      };

      # mosquitto integration for mqtt broker
      services.mosquitto = {
        enable = true;

        listeners = [
          {
            address = "127.0.0.1";
            port = 1883;

            users.zigbee2mqtt = {
              passwordFile = config.age.secrets.mqtt-zigbee2mqtt-password.path;
              acl = [
                "readwrite zigbee2mqtt/#"
                "readwrite homeassistant/#"
              ];
            };

            users.homeassistant = {
              passwordFile = config.age.secrets.mqtt-homeassistant-password.path;
              acl = [
                "readwrite #"
              ];
            };
          }
        ];
      };
    };
}
