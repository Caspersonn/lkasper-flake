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

      # Sonoff ZBDongle-P (TI CC2652P, Z-Stack firmware) -> Zigbee2MQTT
      zigbeeDongle = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0edbe6e0009eef11a7f6cba661ce3355-if00-port0";
      # Sonoff Dongle Plus MG24 (EFR32MG24, OpenThread RCP firmware) -> Thread border router
      threadDongle = "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_5256aab514a1ef118a5fa1a361ce3355-if00-port0";

      # Zigbee2MQTT friendly name of the BILRESA scroll wheel (MQTT topic zigbee2mqtt/<name>)
      bilresaWheel = "0x6cd8fb000020b0b4";
      # Home Assistant entity of the DUBBELKISEL LED driver (Matter)
      dubbelkiselLight = "light.dubbelkisel";
    in
    {
      networking.firewall.allowedTCPPorts = [
        8123 # Home Assistant
        8080 # Zigbee2MQTT frontend; remove if you do not want LAN access
        5580 # Matter server dashboard + websocket (no auth!); remove if you do not want LAN access
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

          # Matter over Thread
          "matter"
          "otbr"
          "thread"
        ];
        config = {
          # Includes dependencies for a basic setup
          # https://www.home-assistant.io/integrations/default_config/
          default_config = { };
          scene = [ ];
          script = { };

          automation = [
            {
              id = "bilresa_wheel_dubbelkisel";
              alias = "BILRESA wiel -> DUBBELKISEL";
              mode = "restart";
              triggers = [
                {
                  trigger = "mqtt";
                  topic = "zigbee2mqtt/${bilresaWheel}";
                }
              ];
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.payload_json.action is defined }}";
                }
              ];
              actions = [
                {
                  choose = [
                    {
                      conditions = "{{ trigger.payload_json.action == 'brightness_move_to_level' }}";
                      sequence = [
                        {
                          action = "light.turn_on";
                          target.entity_id = dubbelkiselLight;
                          data = {
                            brightness = "{{ trigger.payload_json.action_level | int }}";
                            transition = 0.3;
                          };
                        }
                      ];
                    }
                    {
                      # toggle instead of on/off: the remote tracks its own state,
                      # which drifts when the light is switched elsewhere
                      conditions = "{{ trigger.payload_json.action in ['on', 'off'] }}";
                      sequence = [
                        {
                          action = "light.toggle";
                          target.entity_id = dubbelkiselLight;
                        }
                      ];
                    }
                  ];
                }
              ];
            }
          ];
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
            port = zigbeeDongle;
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
            # Only for the first time setup
            #network_key = "GENERATE";
            #pan_id = "GENERATE";
            #ext_pan_id = "GENERATE";

            # Network identity of the original Z-Stack network on the ZBDongle-P.
            # Zigbee stays on channel 25; Thread should use a different channel (e.g. 15).
            channel = 25;

            # 0xaf0f = 44815
            pan_id = 44815;

            # 5c df 67 fe e2 da 96 c7
            ext_pan_id = [ 92 223 103 254 226 218 150 199 ];

            # 30 a4 be 53 b2 8b a6 4e c3 6e 25 a7 3e 0c 11 b2
            network_key = [ 48 164 190 83 178 139 166 78 195 110 37 167 62 12 17 178 ];
          };
        };
      };

      systemd.services.zigbee2mqtt = {
        # Zigbee2MQTT crashes at boot if the MQTT broker is not up yet
        after = [ "mosquitto.service" ];
        wants = [ "mosquitto.service" ];
        serviceConfig.EnvironmentFile = config.age.secrets.zigbee2mqtt-env.path;
      };

      # Thread border router on the Sonoff MG24 (needs OpenThread RCP firmware).
      # Home Assistant's OTBR integration talks to the REST API on http://127.0.0.1:8081
      # and forms the Thread network if none exists yet.
      services.openthread-border-router = {
        enable = true;
        backboneInterfaces = [ "enp86s0" ];
        radio = {
          device = threadDongle;
          # Must match the baud rate of the flashed RCP firmware (usually in the file name)
          baudRate = 460800;
          flowControl = false;
        };
      };

      # Matter controller for Home Assistant (ws://127.0.0.1:5580/ws)
      services.matter-server = {
        enable = true;
        # Keep in sync with the Home Assistant version (both from unstable)
        # Patched: one malformed PAA root certificate on the DCL makes
        # x509.load_pem_x509_certificate raise ValueError, which kills the startup
        # task before the websocket/dashboard on :5580 is opened. Skip such certs.
        package = unstable.python-matter-server.overridePythonAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            f=matter_server/server/helpers/paa_certificates.py
            sed -i 's/^\( *\)cert = x509.load_pem_x509_certificate(pem_certificate.encode())$/\1try:\n\1    cert = x509.load_pem_x509_certificate(pem_certificate.encode())\n\1except ValueError as err:\n\1    LOGGER.warning("Skipping invalid PAA certificate %s: %s", subject, err)\n\1    return False/' $f
            grep -q "Skipping invalid PAA certificate" $f
          '';
        });
        # Use kaito's own Bluetooth (hci0) so the Matter server can commission
        # Thread devices directly (HA: Matter -> "Commission device with code"),
        # bypassing the Android/Google Play Services border router discovery.
        extraArgs = {
          bluetooth-adapter = 0;
        };
      };

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
