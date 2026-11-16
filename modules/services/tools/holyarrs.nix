{ inputs, ... }: {
  flake.modules.nixos.holyarrs = { config, lib, pkgs, ... }:
    let
      port = 6262;
      backendPort = 6263;
      endpoint = "http://127.0.0.1:${toString backendPort}";
      scripts = pkgs.runCommand "holyarrs-provision" { } ''
        mkdir -p "$out"
        cp ${./media-provision/holyarrs.py} "$out/holyarrs.py"
        cp ${./media-provision/decypharr.py} "$out/decypharr.py"
      '';
      provision = "${pkgs.util-linux}/bin/setpriv --reuid=${toString config.users.users.media.uid} --regid=${toString config.users.groups.media.gid} --init-groups ${pkgs.python3}/bin/python3 -B ${scripts}/holyarrs.py --endpoint ${endpoint} --state-dir /var/lib/holyarrs/provision";
    in
    {
      virtualisation.oci-containers.containers.holyarrs = {
        image = "holyarrs/holyarrs:1.0.19";
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "holyarrs/holyarrs";
          imageDigest = "sha256:0d82787b6bd274bd19b31adee9689f90e55d4c46a8194594deecfe02882d963d";
          sha256 = "sha256-UNwGIDgx+xrO9Apou8EaxPUA4IZPP1m/2KJlREMaqeY=";
          finalImageTag = "1.0.19";
          os = "linux";
          arch = "amd64";
        };
        cmd = [ "-config" "/config" "-addr" "127.0.0.1:${toString backendPort}" ];
        networks = [ "host" ];
        environment = {
          PUID = toString config.users.users.media.uid;
          PGID = toString config.users.groups.media.gid;
          UMASK = "002";
          TZ = config.time.timeZone;
          HOLYARRS_FOLLOW_LINKS = "1";
          HOLYARRS_SAVE_PATH = "/data/symlinks";
          HOLYARRS_ALLOWED_HOSTS = "${config.networking.hostName}.mesh";
          HOLYARRS_HEALTH_URL = endpoint;
        };
        volumes = [
          "/var/lib/holyarrs:/config"
          "/data:/data:rslave"
        ];
      };

      systemd.services.docker-holyarrs = {
        after = [ "docker-decypharr.service" ];
        wants = [ "holyarrs-access.socket" ];
        restartTriggers = [ scripts ];
        unitConfig = {
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        serviceConfig = {
          ExecStartPost = [ provision ];
          TimeoutStartSec = lib.mkForce 120;
          RestartSec = 10;
        };
      };

      systemd.sockets.holyarrs-access = {
        unitConfig.DefaultDependencies = false;
        before = [ "shutdown.target" ];
        conflicts = [ "shutdown.target" ];
        after = [ "docker-holyarrs.service" ];
        bindsTo = [ "docker-holyarrs.service" ];
        partOf = [ "docker-holyarrs.service" ];
        socketConfig = {
          ListenStream = toString port;
          NoDelay = true;
        };
      };

      systemd.services.holyarrs-access = {
        after = [ "docker-holyarrs.service" ];
        bindsTo = [ "docker-holyarrs.service" ];
        partOf = [ "docker-holyarrs.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString backendPort}";
          DynamicUser = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        };
      };

      systemd.tmpfiles.settings."10-holyarrs"."/var/lib/holyarrs".d = {
        user = "media";
        group = "media";
        mode = "0750";
      };

      networking.firewall.interfaces = {
        "nebula.mesh".allowedTCPPorts = [ port ];
        ${config.services.tailscale.interfaceName}.allowedTCPPorts = [ port ];
      };
    };
}
