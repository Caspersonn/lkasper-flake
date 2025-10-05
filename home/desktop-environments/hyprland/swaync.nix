{ pkgs, ... }: {
  services.swaync = {
    enable = true;
    settings = {
      notification-2fa-action = false;
    };
  };
}
