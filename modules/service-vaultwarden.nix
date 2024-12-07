{config, lib, pkgs, agenix, unstable, ... }:
	
{
  services.vaultwarden = {
    enable = true;
    #environmentFile = xxx; # Needs to be changed
    #config = xxx; # Needs to be changed
  }

security.acme.defaults.email = "";
security.acme.acceptTerms = true;

services.nginx = {
    enable = true;
    
    # Use recommended settings
    recommendedGzipSettings = true;

    virtualHosts."vaultwarden.home.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8000";
      };
    };
};

}
