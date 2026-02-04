{inputs, ... }: {
  flake.modules.homeManager.swaync = { pkgs, config, lib, username, hostname, ... }:
    {
      services.swaync = {
        enable = true;
        settings = {
          notification-2fa-action = false;
        };
      };
    };
}
