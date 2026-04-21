{ inputs, ... }: {
  flake.modules.nixos.twenty = { config, lib, pkgs, unstable, tfvars, ... }:
    let
      networkName = "twenty-net";
      version = "v1.22.5";
      forward_port = "3000";
    in {

      system.activationScripts.TwentyNetwork = let
        backend = config.virtualisation.oci-containers.backend;
        backendBin = "${pkgs.${backend}}/bin/${backend}";
      in ''
        ${backendBin} network inspect ${networkName} >/dev/null 2>&1 || \
        ${backendBin} network create --driver bridge ${networkName}
      '';

      age = {
        secrets = {
          twenty_server_environment = {
            file = ../../../secrets/twenty_server_environment.age;
            mode = "600";
          };
          twenty_worker_environment = {
            file = ../../../secrets/twenty_worker_environment.age;
            mode = "600";
          };
        };
      };

      virtualisation.oci-containers.containers."twenty" = {
        image = "twentycrm/twenty:${version}";
        ports = [ "${forward_port}:3000" ];
        environmentFiles =
          [ config.age.secrets.twenty_server_environment.path ];
        dependsOn = [ ];
        volumes = [
          "server-local-data:/app/packages/twenty-server/.local-storage"
          "docker-data:/app/docker-data"
        ];
        extraOptions = [
          "--network=${networkName}"
          "--add-host=host.docker.internal:host-gateway"
          "--health-cmd=curl --fail http://localhost:3000/healthz || exit 1"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=5"
          "--health-start-period=60s"
        ];
      };

      virtualisation.oci-containers.containers."twenty-worker" = {
        image = "twentycrm/twenty:${version}";
        environmentFiles =
          [ config.age.secrets.twenty_worker_environment.path ];
        environment = {
          DISABLE_DB_MIGRATIONS = "true";
          DISABLE_CRON_JOBS_REGISTRATION = "true";
        };
        dependsOn = [ "twenty" ];
        volumes = [
          "server-local-data:/app/packages/twenty-server/.local-storage"
          "docker-data:/app/docker-data"
        ];
        cmd = [ "yarn" "worker:prod" ];
        extraOptions = [
          "--network=${networkName}"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };

      virtualisation.oci-containers.containers."redis" = {
        image = "redis:latest";
        ports = [ "6379:6379" ];
        environment = { REDIS_HOST = "redis"; };
        dependsOn = [ ];
        volumes = [ "redis:/var/lib/redis/data" ];
        extraOptions = [ "--network=${networkName}" ];
        cmd = [ "--maxmemory-policy" "noeviction" "--appendonly" "yes" ];
      };

      #services.nginx.virtualHosts."twenty.${environment_domain}" = {
      #  enableACME = true;
      #  forceSSL = true;
      #  extraConfig = ''
      #    client_max_body_size 50M;
      #  '';
      #  locations = {
      #    "/" = {
      #      proxyPass = "http://127.0.0.1:${forward_port}";
      #      proxyWebsockets = true;
      #      extraConfig = ''
      #        proxy_set_header X-Real-IP $remote_addr;
      #        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      #      proxy_set_header X-Forwarded-Proto $scheme;
      #      proxy_buffering off;
      #      proxy_read_timeout 86400;
      #      '';
      #    };
      #  };
      #};
    };
}
