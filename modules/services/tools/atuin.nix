{ inputs, ... }: {
  flake.modules.nixos.atuin = { config, pkgs, ... }: {
    services.atuin = {
      enable = true;
      database.createLocally = true;
      openRegistration = true;
      host = "0.0.0.0";
      port = 8888;
    };

    security.acme.certs."atuin.inspiravita.com" = {
      webroot = "/var/lib/acme/acme-challenge";
      group = "nginx";
    };

    services.nginx.virtualHosts."atuin.inspiravita.com" = {
      enableACME = true;
      forceSSL = false;
      locations."/.well-known/".root = "/var/lib/acme/acme-challenge/";
      locations = { "/" = { proxyPass = "http://127.0.0.1:8888"; }; };
    };
  };
}
