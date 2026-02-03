{ config, pkgs, tfvarsfile, ... }:
{
  services.atuin = {
    enable = true;
    database.createLocally = true;
    openRegistration = true;
    host = "0.0.0.0";
    port = 8888;

  };

  services.nginx.virtualHosts."atuin.inspiravita.com" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:8888";
      };
    };
  };
}
