{ inputs, ... }: {
  flake.modules.nixos.materialious = { lib, config, pkgs, ... }: {

    virtualisation.oci-containers.containers.materialious = {
      image = "wardpearce/materialious-full:latest";
      ports = [ "127.0.0.1:3001:3000" ];
      environment = {
        COOKIE_SECRET = "ohngeiv4Ahthaexu";
        DATABASE_CONNECTION_URI = "sqlite:///materialious-data/materialious.db";
        PUBLIC_PLAYER_ID = "";
        PUBLIC_INTERNAL_AUTH = "true";
        PUBLIC_REQUIRE_AUTH = "true";
        PUBLIC_REGISTRATION_ALLOWED = "true";
        PUBLIC_CAPTCHA_DISABLED = "true";
        WHITELIST_BASE_DOMAIN = "inspiravita.com";
        PUBLIC_DANGEROUS_ALLOW_ANY_PROXY = "false";
        PUBLIC_DEFAULT_INVIDIOUS_INSTANCE = "https://invidious.inspiravita.com";
        PUBLIC_DEFAULT_RETURNYTDISLIKES_INSTANCE =
          "https://returnyoutubedislikeapi.com";
        PUBLIC_DEFAULT_SPONSERBLOCK_INSTANCE = "https://sponsor.ajay.app";
        PUBLIC_DEFAULT_DEARROW_INSTANCE = "https://sponsor.ajay.app";
        PUBLIC_DEFAULT_DEARROW_THUMBNAIL_INSTANCE =
          "https://dearrow-thumb.ajay.app";
        PUBLIC_DEFAULT_SETTINGS = ''{"themeColor": "#2596be", "region": "US"}'';
        ORIGIN = "https://materialious.inspiravita.com";
      };
      volumes = [ "materialious-data:/materialious-data" ];
    };

    services.nginx = {
      enable = true;
      virtualHosts."materialious.inspiravita.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3001";
          proxyWebsockets = true;
        };
      };
    };

  };
}
