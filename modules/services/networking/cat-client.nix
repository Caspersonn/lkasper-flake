{ ... }: {
flake.modules.nixos.cato-client = { pkgs, config, ... }:
  {
    services.cato-client = {
      enable = true;
    };

    networking.firewall.allowedTCPPorts = [ 443 ];

    services.resolved.settings.Resolve = {
      DNS = [ "145.78.2.16" "145.78.59.6" ];
      Domains = [ "~cldsvc.net" ];   # add other internal zones if needed
      FallbackDNS = [ "1.1.1.1" ];
    };
  };
}
