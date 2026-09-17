{ inputs, ... }: {
  flake.modules.nixos.twobluetooth = { pkgs, ... }: {
    services.xrdp.enable = true;
    services.xrdp.defaultWindowManager = "hyprland-wayland";
    services.xrdp.openFirewall = true;
  };
}
