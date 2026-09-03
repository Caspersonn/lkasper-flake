{ inputs, ... }: {
  flake.modules.nixos.twobluetooth = { pkgs, ... }: {
    hardware.bluetooth.enable = true;

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    services.pipewire.extraConfig.pipewire."90-bluetooth-combined" = {
      "context.modules" = [
        {
          name = "libpipewire-module-combine-stream";

          args = {
            "combine.mode" = "sink";

            "node.name" = "bluetooth_combined";
            "node.description" = "Both Bluetooth Speakers";

            # Helpful because Bluetooth devices can have different latency.
            "combine.latency-compensate" = true;

            "combine.props" = {
              "audio.position" = [ "FL" "FR" ];
            };

            "stream.rules" = [
              {
                matches = [
                  {
                    "media.class" = "Audio/Sink";
                    "node.name" =
                      "bluez_output.88_92_CC_CE_22_1B.1";
                  }
                ];

                actions."create-stream" = {
                  "audio.position" = [ "FL" "FR" ];
                  "combine.audio.position" = [ "FL" "FR" ];
                };
              }

              {
                matches = [
                  {
                    "media.class" = "Audio/Sink";
                    "node.name" =
                      "bluez_output.74_45_CE_59_A1_C6.1";
                  }
                ];

                actions."create-stream" = {
                  "audio.position" = [ "FL" "FR" ];
                  "combine.audio.position" = [ "FL" "FR" ];
                };
              }
            ];
          };
        }
      ];
    };
  };
}
