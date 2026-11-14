{ inputs, ... }: {
  flake.modules.nixos.aiostreams = { config, pkgs, ... }: {

    virtualisation.oci-containers.containers.aiostreams = {
      image = "ghcr.io/viren070/aiostreams:latest";
      ports = [ "127.0.0.1:3099:3000" ];
      environment = {
        BASE_URL = "https://aiostreams.inspiravita.com";
        DATABASE_URI = "sqlite://./data/db.sqlite";
      };
      # Provides SECRET_KEY and AIOSTREAMS_AUTH
      environmentFiles = [ config.age.secrets.aiostreams_env.path ];
      volumes = [ "aiostreams-data:/app/data" ];
    };

    services.nginx = {
      enable = true;
      virtualHosts."aiostreams.inspiravita.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3099";
          proxyWebsockets = true;
        };
      };
    };


    networking.firewall.allowedTCPPorts = [ 3099 ];

  };
}
