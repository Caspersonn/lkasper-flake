{ inputs, ... }: {
  flake.modules.nixos.cv-luca = { config, pkgs, lib, ... }:
    let
      repoDir  = "/var/lib/cv-luca/repo";
      buildDir = "/var/lib/cv-luca/public";
      domain   = "cv-luca.inspiravita.com";

      buildScript = pkgs.writeShellScript "cv-luca-build" ''
        set -euo pipefail
        export GIT_SSL_CAINFO="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

        # Repo ophalen of bijwerken
        if [ -d ${repoDir}/.git ]; then
          ${pkgs.git}/bin/git -C ${repoDir} pull --ff-only
        else
          ${pkgs.git}/bin/git clone https://github.com/Caspersonn/cv-hugo.git ${repoDir}
        fi

        # Hugo site bouwen
        ${pkgs.hugo}/bin/hugo \
          --source ${repoDir} \
          --destination ${buildDir} \
          --baseURL "https://${domain}/" \
          --gc --minify --cleanDestinationDir
      '';
    in
    {
      systemd.services.cv-luca-build = {
        description = "CV-site bouwen vanuit GitHub";
        after  = [ "network-online.target" ];
        wants  = [ "network-online.target" ];
        serviceConfig = {
          Type            = "oneshot";
          ExecStart       = buildScript;
          StateDirectory  = "cv-luca";
        };
      };

      # Dagelijks herbouwen + meteen bij opstarten
      systemd.timers.cv-luca-build = {
        wantedBy  = [ "timers.target" ];
        timerConfig = {
          OnBootSec      = "2min";
          OnUnitActiveSec = "24h";
          Unit           = "cv-luca-build.service";
        };
      };

      security.acme.certs.${domain} = {
        webroot = "/var/lib/acme/acme-challenge";
        group   = "nginx";
      };

      services.nginx = {
        enable = true;
        virtualHosts.${domain} = {
          enableACME = true;
          forceSSL   = true;
          locations."/.well-known/".root = "/var/lib/acme/acme-challenge/";
          locations."/" = {
            root     = buildDir;
            tryFiles = "$uri $uri/ $uri.html =404";
          };
        };
      };
    };
}
