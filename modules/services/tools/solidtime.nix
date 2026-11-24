{ inputs, ... }: {
  flake.modules.nixos.solidtime =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      networkName = "solidtime-net";
      image = "solidtime/solidtime:0.23.0";
      docker = "${config.virtualisation.docker.package}/bin/docker";
      appEnvironment = {
        APP_NAME = "solidtime";
        APP_ENV = "production";
        APP_DEBUG = "false";
        APP_URL = "https://solidtime.inspiravita.com";
        APP_FORCE_HTTPS = "true";
        APP_ENABLE_REGISTRATION = "off";
        TRUSTED_PROXIES = "0.0.0.0/0,2000:0:0:0:0:0:0:0/3";
        SUPER_ADMINS = "luca.kasper@technative.eu";
        LOG_CHANNEL = "stderr_daily";
        LOG_LEVEL = "warning";
        DB_CONNECTION = "pgsql";
        DB_HOST = "solidtime-db";
        DB_PORT = "5432";
        DB_DATABASE = "solidtime";
        DB_USERNAME = "solidtime";
        DB_SSL_MODE = "prefer";
        MAIL_MAILER = "log";
        MAIL_FROM_ADDRESS = "solidtime@inspiravita.com";
        MAIL_FROM_NAME = "solidtime";
        QUEUE_CONNECTION = "database";
        FILESYSTEM_DISK = "local";
        PUBLIC_FILESYSTEM_DISK = "public";
        GOTENBERG_URL = "http://solidtime-gotenberg:3000";
      };
      appContainer = {
        inherit image;
        user = "1000:1000";
        environmentFiles = [ config.age.secrets.solidtime-env.path ];
        volumes = [
          "solidtime-storage:/var/www/html/storage"
          "/var/lib/solidtime/logs:/var/www/html/storage/logs"
          "/var/lib/solidtime/app:/var/www/html/storage/app"
        ];
        extraOptions = [
          "--network=${networkName}"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=3"
          "--health-start-period=60s"
        ];
      };
    in
    {
      virtualisation.oci-containers.backend = "docker";

      age.secrets = {
        solidtime-env = {
          file = ../../../secrets/solidtime-env.age;
          mode = "0400";
        };
        solidtime-db-env = {
          file = ../../../secrets/solidtime-db-env.age;
          mode = "0400";
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/solidtime 0750 1000 1000 -"
        "d /var/lib/solidtime/logs 0750 1000 1000 -"
        "d /var/lib/solidtime/app 0750 1000 1000 -"
      ];

      virtualisation.oci-containers.containers = {
        solidtime-app = appContainer // {
          environment = appEnvironment // {
            CONTAINER_MODE = "http";
            AUTO_DB_MIGRATE = "true";
          };
          ports = [ "127.0.0.1:8000:8000" ];
          dependsOn = [
            "solidtime-db"
            "solidtime-gotenberg"
          ];
          extraOptions = appContainer.extraOptions ++ [
            "--health-cmd=curl --fail http://localhost:8000/health-check/up"
          ];
        };
        solidtime-scheduler = appContainer // {
          environment = appEnvironment // {
            CONTAINER_MODE = "scheduler";
          };
          dependsOn = [ "solidtime-app" ];
          extraOptions = appContainer.extraOptions ++ [ "--health-cmd=healthcheck" ];
        };
        solidtime-queue = appContainer // {
          environment = appEnvironment // {
            CONTAINER_MODE = "worker";
            WORKER_COMMAND = "php /var/www/html/artisan queue:work";
          };
          dependsOn = [ "solidtime-app" ];
          extraOptions = appContainer.extraOptions ++ [ "--health-cmd=healthcheck" ];
        };
        solidtime-db = {
          image = "postgres:17";
          environment = {
            POSTGRES_DB = "solidtime";
            POSTGRES_USER = "solidtime";
          };
          environmentFiles = [ config.age.secrets.solidtime-db-env.path ];
          volumes = [ "solidtime-database:/var/lib/postgresql/data" ];
          extraOptions = [
            "--network=${networkName}"
            "--health-cmd=pg_isready -h 127.0.0.1 -U solidtime -d solidtime"
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-retries=5"
          ];
        };
        solidtime-gotenberg = {
          image = "gotenberg/gotenberg:8";
          extraOptions = [
            "--network=${networkName}"
            "--health-cmd=curl --silent --fail http://localhost:3000/health"
            "--health-interval=30s"
            "--health-timeout=5s"
            "--health-retries=3"
          ];
        };
      };

      systemd.services = lib.mkMerge [
        (lib.genAttrs
          (map (name: "docker-solidtime-${name}") [
            "app"
            "scheduler"
            "queue"
            "db"
            "gotenberg"
          ])
          (_: {
            requires = [ "solidtime-network.service" ];
            after = [
              "solidtime-network.service"
              "systemd-tmpfiles-setup.service"
            ];
          })
        )
        {
          docker-solidtime-app.restartTriggers = [ config.age.secrets.solidtime-env.file ];
          docker-solidtime-scheduler.restartTriggers = [ config.age.secrets.solidtime-env.file ];
          docker-solidtime-queue.restartTriggers = [ config.age.secrets.solidtime-env.file ];
          docker-solidtime-db.restartTriggers = [ config.age.secrets.solidtime-db-env.file ];
          solidtime-network = {
            requires = [ "docker.service" ];
            after = [ "docker.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              ${docker} network inspect ${networkName} >/dev/null 2>&1 || \
                ${docker} network create --driver bridge ${networkName}
            '';
          };
          docker-solidtime-db.postStart = ''
            for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
              if ${docker} exec solidtime-db pg_isready -h 127.0.0.1 -U solidtime -d solidtime; then
                exit 0
              fi
              sleep 2
            done
            exit 1
          '';
          docker-solidtime-app.postStart = ''
            for attempt in $(${pkgs.coreutils}/bin/seq 1 90); do
              if ${docker} exec solidtime-app curl --silent --fail http://localhost:8000/health-check/up; then
                exit 0
              fi
              sleep 2
            done
            exit 1
          '';
        }
      ];

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts."solidtime.inspiravita.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8000";
            proxyWebsockets = true;
          };
          extraConfig = "client_max_body_size 50M;";
        };
      };
    };
}
