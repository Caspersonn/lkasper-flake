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
        createLocally = false;
      };

      nextauth.secretFile = config.age.secrets."pokemon_tracker_nextauth".path;

      allowedEmails = [
        "lucakasper8@gmail.com"
      ];
    };

    networking.firewall.allowedTCPPorts = [ 2864 ];

    services.nginx = {
      enable = true;
      additionalModules = [ pkgs.nginxModules.pam ];
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "pokemon-tracker.inspiravita.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:2864"; };
        };
      };
    };
  };
}
