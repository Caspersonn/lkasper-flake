{ inputs, ... }: {
  flake.modules.nixos.media-connections = { config, pkgs, ... }:
    let
      scripts = pkgs.runCommand "media-connections-provision" { } ''
        mkdir -p "$out"
        cp ${./media-provision/connections.py} "$out/connections.py"
        cp ${./media-provision/holyarrs.py} "$out/holyarrs.py"
        cp ${./media-provision/decypharr.py} "$out/decypharr.py"
      '';
      settings = ./media-provision/connections-settings.json;
      dependencies = [ "docker-holyarrs.service" "docker-decypharr.service" "jackett.service" ];
    in {
      systemd.services.docker-holyarrs.wants = [ "media-connections.service" ];
      systemd.services.media-connections = {
        wantedBy = [ "multi-user.target" ];
        after = dependencies;
        requires = dependencies;
        partOf = dependencies;
        restartTriggers = [ scripts settings ];
        unitConfig = {
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          UMask = "0077";
          TimeoutStartSec = 180;
          Restart = "on-failure";
          RestartSec = 10;
          LoadCredential = [
            "holyarrs:/var/lib/holyarrs/provision/api-key.json"
            "jackett:${config.services.jackett.dataDir}/provision-auth.json"
            "decypharr:/var/lib/decypharr/auth.json"
          ];
          ExecStart = "${pkgs.python3}/bin/python3 -B ${scripts}/connections.py --endpoint http://127.0.0.1:6263 --settings ${settings} --credentials-dir %d --state-dir /var/lib/holyarrs/provision";
        };
      };
    };
}
