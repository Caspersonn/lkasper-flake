{ lib, config, pkgs, tfvars, ... }:

let
  cfg = config.elastinix.services.twenty;
  networkName = "twenty-net";
  environment_domain = tfvars.environment_domain;
in
  {
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.twenty_server_environment.file = ../../secrets/twenty_server_environment.age;
  age.secrets.twenty_worker_environment.file = ../../secrets/twenty_worker_environment.age;

    system.activationScripts.TwentyNetwork =
      let
        backend = config.virtualisation.oci-containers.backend;
        backendBin = "${pkgs.${backend}}/bin/${backend}";
      in
        ''
        ${backendBin} network inspect ${networkName} >/dev/null 2>&1 || \
        ${backendBin} network create --driver bridge ${networkName}
      '';

    ## TODO DATABASE NEED TO ALREADY EXIST
    virtualisation.oci-containers.containers."twenty" =
      {
        image = "twentycrm/twenty:v1.6.7";
        ports = [ "8080:3000" ];
        environmentFiles = [ config.age.secrets.twenty_server_environment.path ];
        dependsOn = [ ];
        volumes = [
          "server-local-data:/app/packages/twenty-server/.local-storage"
          "docker-data:/app/docker-data"
        ];
        extraOptions = [
          "--network=${networkName}"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };

    virtualisation.oci-containers.containers."twenty-worker" =
      {
        image = "twentycrm/twenty:v1.6.7";
        environmentFiles = [ config.age.secrets.twenty_worker_environment.path ];
        dependsOn = [ ];
        volumes = [
          "server-local-data:/app/packages/twenty-server/.local-storage"
          "docker-data:/app/docker-data"
        ];
        cmd = [
          "yarn"
          "worker:prod"
        ];
        extraOptions = [
          "--network=${networkName}"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };

  #    services.nginx.virtualHosts."twenty.${environment_domain}" = {
  #      enableACME = true;
  #      forceSSL = true;
  #      locations = {
  #        "/" = {
  #          proxyPass = "http://127.0.0.1:${cfg.forward_port}";
  #        };
  #      };
  #    };
  #};
}
