{ ... }:
{
  # Media server for movies and TV; library and administrator are set by
  # the provisioning unit, which uses only the loopback API.
  flake.modules.nixos.jellyfin = { config, lib, pkgs, ... }:
    let
      stateDir = "${config.services.jellyfin.dataDir}/provision";
      scripts = pkgs.runCommand "jellyfin-provision" { } ''
        mkdir -p "$out"
        cp ${./media-provision/jellyfin.py} "$out/jellyfin.py"
        cp ${./media-provision/decypharr.py} "$out/decypharr.py"
      '';
      provision = pkgs.writeShellApplication {
        name = "provision-jellyfin";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          umask 077
          install -d -m 0700 ${stateDir}
          ${pkgs.python3}/bin/python3 -B ${scripts}/jellyfin.py \
            --endpoint http://127.0.0.1:8096 \
            --state-dir ${stateDir}
        '';
      };
    in
    {
      services.jellyfin = {
        enable = true;
        openFirewall = false;
      };

      users.users.jellyfin.extraGroups = [ "media" ];

      systemd.services.jellyfin-media-provision = {
        wantedBy = [ "multi-user.target" ];
        after = [ "jellyfin.service" ];
        requires = [ "jellyfin.service" ];
        partOf = [ "jellyfin.service" ];
        restartTriggers = [ provision ];
        unitConfig = {
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 10;
          TimeoutStartSec = 420;
          UMask = "0077";
          ExecStart = lib.getExe provision;
        };
      };

      services.nginx = {
        enable = true;
        virtualHosts."jellyfin.inspiravita.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8096";
            proxyWebsockets = true;
          };
        };
      };
    };
}
