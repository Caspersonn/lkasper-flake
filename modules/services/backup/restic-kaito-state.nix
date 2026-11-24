{ config, lib, ... }:
let
  backup = config.casper.backup;
in
{
  flake.modules.nixos.backup-restic-kaito-state = { config, lib, pkgs, ... }:
    let
      host = config.networking.hostName;
      secret = name: ../../../secrets + "/${name}";
      resticSecret = name: {
        file = secret "${name}.age";
        owner = "restic";
        group = "restic";
        mode = "0400";
      };

      dumpDir = "/var/backup";
      hasPostgres = config.services.postgresql.enable;
      hasVaultwarden = config.services.vaultwarden.enable;
      hasSolidtime = config.virtualisation.oci-containers.containers ? solidtime-db;

      systemctl = "${config.systemd.package}/bin/systemctl";
      docker = "${config.virtualisation.docker.package}/bin/docker";

      # Consistent dumps of live databases. Any failure fails the unit before
      # restic runs, so a broken dump never silently ends up as "backed up".
      prepare = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
      ''
      + lib.optionalString hasPostgres ''
        ${systemctl} start postgresqlBackup.service
      ''
      + lib.optionalString hasVaultwarden ''
        ${systemctl} start backup-vaultwarden.service
      ''
      + lib.optionalString hasSolidtime ''
        install -d -m 0700 ${dumpDir}/solidtime
        ${docker} exec solidtime-db pg_dump -U solidtime -Fc solidtime \
          > ${dumpDir}/solidtime/solidtime.dump.tmp
        mv ${dumpDir}/solidtime/solidtime.dump.tmp ${dumpDir}/solidtime/solidtime.dump
      '';

      retryLock = "--retry-lock 1h";
    in
    {
      assertions = [{
        assertion = config.services.restic.server.enable;
        message = "backup-restic-kaito-state needs backup-restic-server on ${host} (restic user, prune key).";
      }];

      age.secrets = {
        restic-kaito-password = resticSecret "restic-kaito-password";
        restic-kaito-env = resticSecret "restic-kaito-env";
      };

      services.postgresqlBackup = lib.mkIf hasPostgres {
        enable = true;
        backupAll = true;
        location = "${dumpDir}/postgresql";
        compression = "zstd";
        # Triggered by the backup job instead of its own timer.
        startAt = [ ];
      };

      services.vaultwarden.backupDir = lib.mkIf hasVaultwarden "${dumpDir}/vaultwarden";

      services.restic.backups = {
        state-s3 = {
          repository = backup.repository.s3 host;
          extraOptions = [ "s3.region=${backup.s3.region}" ];
          passwordFile = config.age.secrets.restic-kaito-password.path;
          environmentFile = config.age.secrets.restic-kaito-env.path;
          paths = [ "/var/lib" dumpDir ];
          initialize = true;
          backupPrepareCommand = prepare;
          exclude = [
            # Client repositories never go to S3 a second time.
            backup.server.dataDir
            "/var/lib/restic"

            # Docker storage is rebuildable, except the Solidtime file volume.
            "/var/lib/docker/*"
            "!/var/lib/docker/volumes"
            "/var/lib/docker/volumes/*"
            "!/var/lib/docker/volumes/solidtime-storage"

            # Live databases, dumped to ${dumpDir} instead.
            "/var/lib/postgresql"
            "/var/lib/vaultwarden/db.sqlite3*"

            # History, models and caches.
            "/var/lib/hass/home-assistant_v2.db*"
            "/var/lib/private/ollama"
            "/var/lib/redis-*"
            "/var/lib/systemd/coredump"
            "/var/lib/containers"
            "/var/lib/machines"
          ];
          extraBackupArgs = [
            "--exclude-caches"
            "--one-file-system"
            "--tag state"
            "--retry-lock 30m"
          ];
          timerConfig = {
            OnCalendar = "03:30";
            Persistent = true;
            RandomizedDelaySec = "15m";
          };
        };

        # Lives here rather than in backup-restic-server: it must exist exactly
        # when state-s3 exists, and testing `backups ? state-s3` there recurses.
        maint-s3-kaito = {
          user = "restic";
          repository = backup.repository.s3 host;
          extraOptions = [ "s3.region=${backup.s3.region}" ];
          passwordFile = config.age.secrets.restic-kaito-password.path;
          environmentFile = config.age.secrets.restic-kaito-env.path;
          paths = [ ];
          pruneOpts = backup.retention.s3 ++ [ retryLock ];
          runCheck = true;
          checkOpts = [ retryLock ];
          timerConfig = {
            OnCalendar = "Sun 04:00";
            Persistent = true;
            RandomizedDelaySec = "3h";
          };
        };
      };
    };
}
