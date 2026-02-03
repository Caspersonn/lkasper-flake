{ inputs, ... }: {
  flake.modules.nixos.openssh = { config, pkgs, ... }: {
    services.openssh = {
      enable = true;
      settings.UseDns = true;
    };
  };
}
