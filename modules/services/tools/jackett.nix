{ inputs, ... }: {
  flake.modules.nixos.jackett = { config, lib, pkgs, ... }:
    let
      port = config.services.jackett.port;
      provision = pkgs.runCommand "jackett-provision" { } ''
        mkdir -p "$out"
        cp ${./media-provision/jackett.py} "$out/jackett.py"
        cp ${./media-provision/decypharr.py} "$out/decypharr.py"
      '';
    in
    {
      services.jackett = {
        enable = true;
        openFirewall = false;
      };

      systemd.services.jackett = {
        restartTriggers = [ ./media-provision/jackett-settings.json provision ];
        unitConfig = {
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        serviceConfig = {
          ExecStartPre = [
            "${pkgs.python3}/bin/python3 -B ${provision}/jackett.py --settings ${./media-provision/jackett-settings.json} --state-dir ${lib.escapeShellArg config.services.jackett.dataDir} --port ${toString port}"
          ];
          TimeoutStartSec = 90;
          RestartSec = 10;
        };
      };

      networking.firewall.interfaces = {
        "nebula.mesh".allowedTCPPorts = [ port ];
        ${config.services.tailscale.interfaceName}.allowedTCPPorts = [ port ];
      };
    };
}
