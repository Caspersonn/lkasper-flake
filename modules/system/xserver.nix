{ inputs, ... }: {
  flake.modules.nixos.xserver = { config, pkgs, ... }: {
    services.xserver.enable = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };
}
