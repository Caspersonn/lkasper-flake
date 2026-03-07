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
        https_only = true;
        external_port = lib.mkForce 443;
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
      appendHttpConfig = ''
        proxy_buffer_size 16k;
        proxy_buffers 4 16k;
        proxy_busy_buffers_size 16k;
        large_client_header_buffers 4 16k;
      '';
      virtualHosts."invidious.inspiravita.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/companion" = {
          proxyPass = "http://127.0.0.1:8282";
          proxyWebsockets = true;
          extraConfig = ''
            auth_basic off;

            proxy_buffering off;
            proxy_request_buffering off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_connect_timeout 60s;

            proxy_hide_header 'Access-Control-Allow-Origin';
            proxy_hide_header 'Access-Control-Allow-Methods';
            proxy_hide_header 'Access-Control-Allow-Headers';
            proxy_hide_header 'Access-Control-Expose-Headers';

            add_header 'Access-Control-Allow-Origin' 'https://materialious.inspiravita.com' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;

            if ($request_method = 'OPTIONS') {
              add_header 'Access-Control-Allow-Origin' 'https://materialious.inspiravita.com';
              add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
              add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
              add_header 'Access-Control-Max-Age' 1728000;
              add_header 'Content-Type' 'text/plain; charset=utf-8';
              add_header 'Content-Length' 0;
              return 204;
            }
          '';
        };
      };
    };
  };
}
