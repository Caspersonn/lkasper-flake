{ inputs, ... }: {
  flake.modules.nixos.home-assistant = { pkgs, unstable, config, ... }:
    let
      bilresaAutomations = pkgs.writeText "automations.yaml" ''
    - id: bilresa_bed_controls
      alias: BILRESA Bed controls
      description: Control KAJPLATS Bed Lamp and TRETAKT Fairy Lights from BILRESA Bed
      mode: restart

      triggers:
        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Bed"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "on"
          id: kajplats_on

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Bed"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "off"
          id: kajplats_off

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Bed"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "on_double"
          id: tretakt_toggle

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Bed"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "off_double"
          id: all_off

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Bed"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "brightness_move_up"
          id: kajplats_brightness_up

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Bed"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "brightness_move_down"
          id: kajplats_brightness_down

      actions:
        - choose:
            - conditions:
                - condition: trigger
                  id: kajplats_on
              sequence:
                - action: light.turn_on
                  target:
                    entity_id: light.0x00c09b9eff953a7d

            - conditions:
                - condition: trigger
                  id: kajplats_off
              sequence:
                - action: light.turn_off
                  target:
                    entity_id: light.0x00c09b9eff953a7d

            - conditions:
                - condition: trigger
                  id: tretakt_toggle
              sequence:
                - action: switch.toggle
                  target:
                    entity_id: switch.0x7c31fafffed877c5

            - conditions:
                - condition: trigger
                  id: all_off
              sequence:
                - action: light.turn_off
                  target:
                    entity_id: light.0x00c09b9eff953a7d
                - action: switch.turn_off
                  target:
                    entity_id: switch.0x7c31fafffed877c5
                - action: switch.turn_off
                  metadata: {}
                  target:
                    device_id: 11eb5bdfd3ed3ea64942de741d70cef0
                  data: {}

            - conditions:
                - condition: trigger
                  id: kajplats_brightness_up
              sequence:
                - action: light.turn_on
                  target:
                    entity_id: light.0x00c09b9eff953a7d
                  data:
                    brightness_step_pct: 20

            - conditions:
                - condition: trigger
                  id: kajplats_brightness_down
              sequence:
                - action: light.turn_on
                  target:
                    entity_id: light.0x00c09b9eff953a7d
                  data:
                    brightness_step_pct: -20

    - id: bilresa_burea_controls
      alias: BILRESA Burea controls
      description: Control TRETAKT Burea Lamp from BILRESA Burea
      mode: restart

      triggers:
        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Burea"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "on"
          id: kajplats_on

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Burea"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "off"
          id: kajplats_off

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Burea"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "on_double"
          id: tretakt_toggle

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Burea"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "off_double"
          id: all_off

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Burea"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "brightness_move_up"
          id: kajplats_brightness_up

        - trigger: mqtt
          topic: "zigbee2mqtt/BILRESA Burea"
          value_template: "{{ value_json.get('action', ''\) }}"
          payload: "brightness_move_down"
          id: kajplats_brightness_down

      actions:
        - choose:
            - conditions:
                - condition: trigger
                  id: kajplats_on
              sequence:
                - action: light.turn_on
                  target:
                    entity_id: light.0x00c09b9eff953a7d

            - conditions:
                - condition: trigger
                  id: kajplats_off
              sequence:
                - action: light.turn_off
                  target:
                    entity_id: light.0x00c09b9eff953a7d

            - conditions:
                - condition: trigger
                  id: tretakt_toggle
              sequence:
                - action: switch.toggle
                  target:
                    entity_id: switch.0x983268fffe3c54e0

            - conditions:
                - condition: trigger
                  id: all_off
              sequence:
                - action: light.turn_off
                  target:
                    entity_id: light.0x00c09b9eff953a7d
                - action: switch.turn_off
                  target:
                    entity_id: switch.0x7c31fafffed877c5
                - action: switch.turn_off
                  metadata: {}
                  target:
                    device_id: 11eb5bdfd3ed3ea64942de741d70cef0
                  data: {}

            - conditions:
                - condition: trigger
                  id: kajplats_brightness_up
              sequence:
                - action: light.turn_on
                  target:
                    entity_id: light.0x00c09b9eff953a7d
                  data:
                    brightness_step_pct: 20

            - conditions:
                - condition: trigger
                  id: kajplats_brightness_down
              sequence:
                - action: light.turn_on
                  target:
                    entity_id: light.0x00c09b9eff953a7d
                  data:
                    brightness_step_pct: -20
      '';
    in
      {

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

      system.activationScripts.homeAssistantAutomations = ''
        install -d -m 0755 -o hass -g hass /var/lib/hass
        install -m 0644 -o hass -g hass ${bilresaAutomations} /var/lib/hass/automations.yaml
      '';

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
            # Only for the first time setup
            #network_key = "GENERATE";
            #pan_id = "GENERATE";
            #ext_pan_id = "GENERATE";

            channel = 25;

            # 0xaf0f = 44815
            pan_id = 44815;

            # 5c df 67 fe e2 da 96 c7
            ext_pan_id = [
              92 223 103 254 226 218 150 199
            ];

            # 30 a4 be 53 b2 8b a6 4e c3 6e 25 a7 3e 0c 11 b2
            network_key = [
              48 164 190 83 178 139 166 78
              195 110 37 167 62 12 17 178
            ];
        };
      };
    };

    systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile = config.age.secrets.zigbee2mqtt-env.path; #"/var/lib/secrets/zigbee2mqtt.env";


    # mosquitto integration for mqtt broker
    services.mosquitto = {
      enable = true;

      listeners = [
        {
          address = "127.0.0.1";
          port = 1883;

          users.zigbee2mqtt = {
            passwordFile = config.age.secrets.mqtt-zigbee2mqtt-password.path; #"/var/lib/secrets/mqtt-zigbee2mqtt-password";
            acl = [
              "readwrite zigbee2mqtt/#"
              "readwrite homeassistant/#"
            ];
          };

          users.homeassistant = {
            passwordFile = config.age.secrets.mqtt-homeassistant-password.path; #"/var/lib/secrets/mqtt-homeassistant-password";
            acl = [
              "readwrite #"
            ];
          };
        }
      ];
    };
  };
}
