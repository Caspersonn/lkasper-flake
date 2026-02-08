{...}: {
  flake.modules.nixos.nextcloud = { config, pkgs, ... }: {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud32;
      hostName = "localhost";
      config.adminpassFile = config.age.secrets."nextcloud-admin-passwd".path;
      config.dbtype = "sqlite";
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) news contacts calendar tasks;
      };
      extraAppsEnable = true;
    };

    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.secrets."nextcloud-admin-passwd".file = ../../../secrets/nextcloud-admin-passwd.age;

    security.acme.certs."nextcloud.inspiravita.com" = {
      webroot = "/var/lib/acme/acme-challenge";
      group = "nginx";
    };

    services.nginx = {
      enable = true;
      additionalModules = [ pkgs.nginxModules.pam ];
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "nextcloud.inspiravita.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/.well-known/".root = "/var/lib/acme/acme-challenge/";
          locations."/" = { proxyPass = "http://localhost"; };
        };
      };
    };
  };
}
