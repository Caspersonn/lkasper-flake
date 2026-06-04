{ ... }: {
  flake.modules.nixos.adguardhome = { ... }: {
    services.adguardhome = {
      enable = true;
      host = "0.0.0.0";
      port = 3001;
      settings = {
        dhcp = {
          enabled = true;
        };
      };
    };
  };
}
