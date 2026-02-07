{ inputs, ... }: {
  flake.modules.nixos.vaultwarden = { config, lib, pkgs, unstable, ... }: 
    let
      port = 8222;
    in
      {
      services.nginx.enable = true;

      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      age.secrets.vaultwarden.file = ../../../secrets/vaultwarden.age;

      services.vaultwarden = {
        enable = true;
        environmentFile = config.age.secrets.vaultwarden.path;
        config = {
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = port;
        };
      };

      security.acme.certs."vaultwarden.inspiravita.com" = {
        webroot = "/var/lib/acme/acme-challenge";
        group = "nginx";
      };

      services.nginx.virtualHosts."vaultwarden.inspiravita.com" = {
        enableACME = true;
        forceSSL = false;
        locations."/.well-known/".root = "/var/lib/acme/acme-challenge/";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
        };
      };
    };
}
