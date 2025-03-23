{config, lib, pkgs, agenix, unstable, ... }:
	
{
  services.nginx.enable = true;
  
  services.vaultwarden = {
    enable = true;
    #environmentFile = xxx; # Needs to be changed
    config = {
      DOMAIN = "https://vaultwarden.inspiravita.com";
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "192.168.178.95";
      ROCKET_PORT = 8222;
    };
  };

  security.acme.defaults.email = "lucakasper8@gmail.com";
  security.acme.acceptTerms = true;

  services.nginx.virtualHosts."vaultwarden.inspiravita.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://192.168.178.95:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
  };
}
