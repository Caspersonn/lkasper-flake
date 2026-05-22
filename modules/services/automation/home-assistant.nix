{ inputs, ... }: {
  flake.modules.nixos.home-assistant = { pkgs, unstable, config, ... }: {

    networking.firewall.allowedTCPPorts = [
      8123 # Home Assistant
      8080 # Zigbee2MQTT frontend; remove if you do not want LAN access
    ];

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
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = {};
        automation = "!include automations.yaml";
      };
    };

    services.zigbee2mqtt = {
      enable = true;
      package = unstable.zigbee2mqtt;

      settings = {
        homeassistant = {
          enabled = true;
        };

        serial = {
          port = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0edbe6e0009eef11a7f6cba661ce3355-if00-port0";
          adapter = "zstack";
          baudrate = 115200;
          rtscts = false;
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
          network_key = "GENERATE";
          pan_id = "GENERATE";
          ext_pan_id = "GENERATE";
          channel = 11;
        };
      };
    };

    systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile = "/var/lib/secrets/zigbee2mqtt.env";


    # mosquitto integration for mqtt broker
    services.mosquitto = {
      enable = true;

      listeners = [
        {
          address = "127.0.0.1";
          port = 1883;

          users.zigbee2mqtt = {
            passwordFile = "/var/lib/secrets/mqtt-zigbee2mqtt-password";
            acl = [
              "readwrite zigbee2mqtt/#"
              "readwrite homeassistant/#"
            ];
          };

          users.homeassistant = {
            passwordFile = "/var/lib/secrets/mqtt-homeassistant-password";
            acl = [
              "readwrite #"
            ];
          };
        }
      ];
    };
  };
}
