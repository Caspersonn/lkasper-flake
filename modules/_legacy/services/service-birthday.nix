{ config, pkgs, ... }:

{
  systemd.services.nextjs = {
    description = "Next.js app";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "casper";
      WorkingDirectory = "/home/casper/git/personal/antonia-birthday";

      ExecStart = "${pkgs.nodejs_24}/bin/npm run start";

      Environment = [
        "NODE_ENV=production"
        "PORT=3000"
        "PATH=${pkgs.nodejs_24}/bin:${pkgs.bash}/bin"
      ];

      Restart = "always";
    };
  };

  services.nginx = {
    enable = true;
    additionalModules = [ pkgs.nginxModules.pam ];
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "40M";
    virtualHosts = {
      "birthday.inspiravita.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
        };
      };
    };
  };
}
