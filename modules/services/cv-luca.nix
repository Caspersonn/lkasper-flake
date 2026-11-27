{ inputs, ... }: {
  flake.modules.nixos.cv-luca = { config, pkgs, lib, ... }: {
    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.secrets."cv-luca-aws".file = ../../../secrets/cv-luca-aws.age;

    # Haal de gebouwde site op uit S3 en zet hem in /var/lib/cv-luca
    systemd.services.cv-luca-sync = {
      description = "CV-site syncronisoreen van S3";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.age.secrets."cv-luca-aws".path;
        ExecStart = "${pkgs.awscli2}/bin/aws s3 sync s3://$CV_S3_BUCKET/ /var/lib/cv-luca/ --delete";
        StateDirectory = "cv-luca";
      };
    };

    # Elke 15 minuten synchroniseren + meteen bij opstarten
    systemd.timers.cv-luca-sync = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "15min";
        Unit = "cv-luca-sync.service";
      };
    };

    security.acme.certs."cv-luca.inspiravita.com" = {
      webroot = "/var/lib/acme/acme-challenge";
      group = "nginx";
    };

    services.nginx = {
      enable = true;
      virtualHosts."cv-luca.inspiravita.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/.well-known/".root = "/var/lib/acme/acme-challenge/";
        locations."/" = {
          root = "/var/lib/cv-luca";
          tryFiles = "$uri $uri/ $uri.html =404";
        };
      };
    };
  };
}
