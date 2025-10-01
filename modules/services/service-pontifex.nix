{config, lib, pkgs, agenix, unstable, ... }:

{
  services.pontifex = {
    enable = true;
    envFile = config.age.secrets.pontifex.path;
  };

  age.secrets.pontifex.file = ../../secrets/pontifex.age;

  services.nginx.enable = true;

  security.acme.defaults.email = "lucakasper8@gmail.com";
  security.acme.acceptTerms = true;

  services.nginx.virtualHosts."pontifex.inspiravita.com" = {
    enableACME = true;
    forceSSL = false;
    locations."/" = {
      proxyPass = "http://127.0.0.1:4000";
    };
  };
}
