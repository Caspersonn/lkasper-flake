{ inputs, ... }: {
  flake.modules.nixos.tailscale = { config, pkgs, ... }: {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
    };
  };
}
