{ inputs, ... }: {
  flake.modules.nixos.invidious = { lib, config, pkgs, ... }: {

    virtualisation.oci-containers.containers.invidious-companion = {
      image = "quay.io/invidious/invidious-companion:latest";
      ports = [ "127.0.0.1:8282:8282" ];
      environment = { SERVER_SECRET_KEY = "ahyie0ooSh1quaiL"; };
      extraOptions = [
        "--cap-drop=ALL"
        "--read-only"
        "--security-opt=no-new-privileges:true"
      ];
      volumes = [ "companioncache:/var/tmp/youtubei.js:rw" ];
    };

    services.invidious = {
      enable = true;
      address = "0.0.0.0";
      port = 3000;
      domain = "invidious.inspiravita.com";

      database = {
        createLocally = true;
        port = 5432;
      };

      settings = {
        db = {
          dbname = "invidious";
          user = "invidious";
        };
        check_tables = true;
        hmac_key = "aed6Oap9ezud2Tho";
        invidious_companion = [{
          private_url = "http://127.0.0.1:8282/companion";
          public_url = "https://invidious.inspiravita.com/companion";
        }];
        invidious_companion_key = "ahyie0ooSh1quaiL";
      };

      nginx.enable = true;
      http3-ytproxy.enable = true;
    };

    services.nginx = {
      additionalModules = [ pkgs.nginxModules.pam ];
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "40M";
      virtualHosts."invidious.inspiravita.com" = {
        forceSSL = true;
        enableACME = true;
        basicAuth = { casper = "test12345"; };
        locations."/companion" = {
          proxyPass = "http://127.0.0.1:8282";
          proxyWebsockets = true;
        };
      };
    };
  };
}
