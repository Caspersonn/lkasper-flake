{ inputs, ... }: {
  flake.modules.nixos.home-assistant = { pkgs, unstable, config, ... }: {
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
        # Recommended for fast zlib compression
        # https://www.home-assistant.io/integrations/isal
        "isal"
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = {};
      };
    };
    services.zigbee2mqtt = {
      enable = true;
      settings = {
        homeassistant.enabled = config.services.home-assistant.enable;
        permit_join = true;
        serial = {
          port = "/dev/ttyACM1";
        };
      };
    };
  };
}
