{ inputs, ... }: {
  flake.modules.nixos.decypharr = { config, lib, pkgs, ... }:
    let
      port = 8282;
      mountPoint = "/data/debrid";
      # A crashed FUSE mount leaves "Transport endpoint is not connected"
      # behind; clear it around every start and stop. "-": not mounted is fine.
      unmount = "-${pkgs.util-linux}/bin/umount --lazy ${mountPoint}";
      provision = pkgs.writeShellApplication {
        name = "provision-decypharr";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          umask 077
          ${pkgs.python3}/bin/python3 ${./media-provision/decypharr.py} \
            --settings ${./media-provision/decypharr-settings.json} \
            --credentials "$CREDENTIALS_DIRECTORY/real-debrid" \
            --state-dir /var/lib/decypharr
          chown media:media /var/lib/decypharr/{config.json,auth.json,.provision.lock}
          if ${pkgs.util-linux}/bin/mountpoint --quiet ${mountPoint}; then
            exit 1
          fi
          test -d ${mountPoint}
          test ! -L ${mountPoint}
          chown media:media ${mountPoint}
          chmod 2770 ${mountPoint}
        '';
      };
      mountReady = pkgs.writeShellApplication {
        name = "wait-decypharr-mount";
        runtimeInputs = [ pkgs.coreutils pkgs.util-linux ];
        text = ''
          for _ in {1..60}; do
            if mountpoint --quiet ${mountPoint}; then
              exit 0
            fi
            sleep 1
          done
          exit 1
        '';
      };
    in
    {
      age.secrets.media-real-debrid = {
        file = ../../../secrets/media-real-debrid.age;
        mode = "0400";
      };

      virtualisation.oci-containers.containers.decypharr = {
        image = "decypharr:2.7.2-holyarrs";
        imageFile = (import ../../../tests/media/decypharr-build/package.nix) { inherit pkgs; patch = ./decypharr/sync-maindata.patch; };
        # Host network: the NixOS firewall below decides who reaches the port.
        networks = [ "host" ];
        environment = {
          PUID = toString config.users.users.media.uid;
          PGID = toString config.users.groups.media.gid;
          UMASK = "002";
          TZ = config.time.timeZone;
        };
        volumes = [
          # Decypharr chowns /app on every start; keep it to itself.
          "/var/lib/decypharr:/app"
          # rshared: the mount it creates at /data/debrid shows up on the host.
          "/data:/data:rshared"
        ];
        devices = [ "/dev/fuse:/dev/fuse:rwm" ];
        capabilities.SYS_ADMIN = true;
        extraOptions = [ "--security-opt=apparmor=unconfined" ];
      };

      systemd.services.docker-decypharr = {
        restartTriggers = [ config.age.secrets.media-real-debrid.file ];
        unitConfig = {
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        serviceConfig = {
          LoadCredential = [ "real-debrid:${config.age.secrets.media-real-debrid.path}" ];
          ExecStartPre = lib.mkAfter [ unmount "${provision}/bin/provision-decypharr" ];
          ExecStartPost = [ "${mountReady}/bin/wait-decypharr-mount" ];
          ExecStopPost = lib.mkAfter [ unmount ];
          TimeoutStartSec = lib.mkForce 90;
          RestartSec = 10;
        };
      };

      systemd.tmpfiles.settings."10-decypharr"."/var/lib/decypharr".d = {
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
