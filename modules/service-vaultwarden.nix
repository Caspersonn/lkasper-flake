{config, lib, pkgs, agenix, unstable, ... }:
	
{
  services.vaultwarden = {
    enable = true;
    #environmentFile = xxx; # Needs to be changed
    #config = xxx; # Needs to be changed
  };

#  security.acme.defaults.email = "lucakasper8@gmail.com";
#  security.acme.acceptTerms = true;

  services.nginx = {
    enable = true;
    
    # Use recommended settings
    recommendedGzipSettings = true;

    virtualHosts."vaultwarden.home.dev" = {
      #enableACME = true;
      #forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:8222";
      };
      extraConfig = ''
        allow 192.168.178.1/24;
        allow all;
      '';
    };
  };
}
