{ ... }:
{
  # Media server for Finamp and other clients; library is set by music-provision.
  flake.modules.nixos.jellyfin = { ... }: {
    services.jellyfin = {
      enable = true;
      openFirewall = false;
    };

    services.nginx = {
      enable = true;
      virtualHosts."jellyfin.inspiravita.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true;
        };
      };
    };
  };
}
