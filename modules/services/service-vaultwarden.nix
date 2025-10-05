{config, lib, pkgs, agenix, unstable, ... }:
	
{
  services.nginx.enable = true;

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.vaultwarden.file = ../../secrets/vaultwarden.age;

  services.vaultwarden = {
    enable = true;
    environmentFile = config.age.secrets.vaultwarden.path;
  };

  security.acme.defaults.email = "security@inspiravita.com";
  security.acme.acceptTerms = true;

  services.nginx.virtualHosts."vaultwarden.inspiravita.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://192.168.178.95:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
  };
}
