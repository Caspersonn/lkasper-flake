{ ... }: {
flake.modules.nixos.cato-client = { pkgs, config, ... }:
  {
    services.cato-client = {
      enable = true;
    };
  };
}
