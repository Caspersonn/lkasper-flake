{ config, lib, pkgs, ... }: {

   system.activationScripts.invidiousnet =
    let
    backend = config.virtualisation.oci-containers.backend;
    backendBin = "${pkgs.${backend}}/bin/${backend}";
  in
    ''
    ${backendBin} network inspect invidiousnet >/dev/null 2>&1 || \
    ${backendBin} network create --driver bridge invidiousnet
  '';

  virtualisation.oci-containers.containers = {
    invidious = {
      image = "quay.io/invidious/invidious:master-arm64";
      ports = [ "127.0.0.1:3000:3000" ];
      environment = {
        INVIDIOUS_CONFIG = ''
          db:
            dbname: invidious
            user: kemal
            password: kemal
            host: invidious-db
            port: 5432
          check_tables: true
          invidious_companion:
          - private_url: "http://companion:8282"
            public_url: "http://localhost:8282"
          invidious_companion_key: "ahyie0ooSh1quaiL"
          hmac_key: "aed6Oap9ezud2Tho"
        '';
      };
      extraOptions = [ "--network=invidiousnet" ];
    };

    companion = {
      image = "quay.io/invidious/invidious-companion:latest";
      ports = [ "127.0.0.1:8282:8282" ];
      environment = {
        SERVER_SECRET_KEY = "ahyie0ooSh1quaiL";
      };
      extraOptions = [
        "--cap-drop=ALL"
        "--read-only"
        "--security-opt=no-new-privileges:true"
        "--network=invidiousnet"
      ];
      volumes = [
        "companioncache:/var/tmp/youtubei.js:rw"
      ];
    };

    invidious-db = {
      image = "postgres:14";
      environment = {
        POSTGRES_DB = "invidious";
        POSTGRES_USER = "kemal";
        POSTGRES_PASSWORD = "kemal";
      };
      extraOptions = [ "--network=invidiousnet" ];
      volumes = [
        "postgresdata:/var/lib/postgresql/data"
        "./config/sql:/config/sql"
        "./docker/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh"
      ];
    };
  };

  services.nginx = {
    enable = true;
    additionalModules = [ pkgs.nginxModules.pam ];
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "40M";
    virtualHosts = {
      "invidious.inspiravita.com" = {
        forceSSL = true;
        enableACME = true;
        basicAuth = { casper = "test12345"; };
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
        };
      };
    };
  };
}
