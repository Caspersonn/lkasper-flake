{ inputs, ... }: {
  flake.modules.nixos.pokemon-tracker = { config, lib, pkgs, unstable, ... }: {
    imports = [
        inputs.pokemon-tracker.nixosModules.default
    ];

    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.secrets."pokemon_tracker_nextauth".file = ../../../secrets/pokemon_tracker_nextauth.age;

    services.pokemon-tracker = {
      enable = true;
      port = 2864;
      host = "0.0.0.0";

      database = {
        name = "pokemon_tracker";
        user = "pokemon_tracker";
      };

      environmentFiles = [ config.age.secrets."pokemon_tracker_nextauth".path ];

      allowedEmails = [
        "lucakasper8@gmail.com"
      ];
    };

    networking.firewall.allowedTCPPorts = [ 80 443 2864 ];

    security.acme.certs."pokemon-tracker.inspiravita.com" = {
      webroot = "/var/lib/acme/acme-challenge";
      group = "nginx";
    };
    security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";

    services.nginx = {
      enable = true;
      additionalModules = [ pkgs.nginxModules.pam ];
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "pokemon-tracker.inspiravita.com" = {
          forceSSL = false;
          enableACME = true;
          locations."/.well-known/".root = "/var/lib/acme/acme-challenge/";
          locations."/" = { proxyPass = "http://127.0.0.1:2864"; };
        };
      };
    };
  };
}
