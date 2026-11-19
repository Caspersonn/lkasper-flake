{ inputs, ... }: {
  flake.modules.nixos.media-backup = { config, lib, pkgs, ... }:
    let
      remux = builtins.hasAttr "docker-remux-main" config.systemd.services;
      jellyfin = config.services.jellyfin.enable || remux;
      soundspan = builtins.hasAttr "soundspan-backend" config.systemd.services;
      aurral = config.services.aurralFlows.enable or false;
      paths = [ "/var/lib/decypharr" "/var/lib/holyarrs" "/var/lib/jackett" ]
        ++ lib.optionals remux [ "/var/lib/remux" "/var/lib/remux-provision" ]
        ++ lib.optionals jellyfin [ "/var/lib/jellyfin" ]
        ++ lib.optionals soundspan [ "/var/backups/media/soundspan-dump" ]
        ++ lib.optionals aurral [ "/var/lib/aurral-flows-provision" "/var/lib/aurral-flows" "/var/lib/slskd-aurral" "/data/music-aurral" ];
      units = lib.optionals aurral [ "aurral-capacity.timer" "aurral-capacity.service" "aurral-flows-provision.service" "docker-aurral-flows.service" "docker-slskd-aurral.service" ]
        ++ lib.optionals remux [ "remux-source-provision.service" "docker-remux-main.service" ]
        ++ [ "docker-holyarrs.service" "jackett.service" "docker-decypharr.service" ]
        ++ lib.optionals config.services.jellyfin.enable [ "jellyfin.service" ]
        ++ lib.optionals soundspan [ "soundspan-backend.service" "soundspan-frontend.service" ];
      requiredFiles = [
        "/var/lib/decypharr/config.json"
        "/var/lib/decypharr/auth.json"
        "/var/lib/holyarrs/holyarrs.key"
      ] ++ lib.optionals soundspan [ "/var/backups/media/soundspan-dump/soundspan.dump" ]
        ++ lib.optionals remux [ "/var/lib/remux/db.sqlite" "/var/lib/remux-provision/admin.json" "/var/lib/remux-provision/source.json" ]
        ++ lib.optionals aurral [ "/var/lib/aurral-flows-provision/admin.json" "/var/lib/aurral-flows-provision/slskd.json" "/var/lib/aurral-flows-provision/flows.json" "/var/lib/aurral-flows/aurral.db" "/var/lib/slskd-aurral/slskd.yml" ];
      settings = pkgs.writeText "media-backup-settings.json" (builtins.toJSON {
        repository = "/var/backups/media/restic";
        restore_root = "/var/lib/media-restore";
        inherit paths units;
        aurral = if aurral then { database = "/var/lib/aurral-flows/aurral.db"; library = "/data/music-aurral"; } else null;
        required_files = requiredFiles;
        exclude = [ "/var/lib/decypharr/cache" ] ++ lib.optionals remux [ "/var/lib/remux/cache" "/var/lib/remux/transcode_sessions" ];
        tag = "media-state-v1";
        owners = lib.foldl (a: b: a // b) { } (
          [
            { "/var/lib/decypharr" = [ "media" "media" ]; }
            { "/var/lib/holyarrs" = [ "media" "media" ]; }
            { "/var/lib/jackett" = [ "jackett" "jackett" ]; }
          ]
          ++ lib.optionals jellyfin [
            { "/var/lib/jellyfin" = [ "jellyfin" "jellyfin" ]; }
          ]
          ++ lib.optionals remux [
            { "/var/lib/remux" = [ "media" "media" ]; }
            { "/var/lib/remux-provision" = [ "root" "root" ]; }
          ]
          ++ lib.optionals soundspan [
            { "/var/backups/media/soundspan-dump" = [ "postgres" "postgres" ]; }
          ]
          ++ lib.optionals aurral [
            { "/var/lib/aurral-flows-provision" = [ "root" "root" ]; }
            { "/var/lib/aurral-flows" = [ "media" "media" ]; }
            { "/var/lib/slskd-aurral" = [ "media" "media" ]; }
            { "/data/music-aurral" = [ "media" "media" ]; }
          ]
        );
      });
      dumpDatabase = pkgs.writeShellApplication {
        name = "media-state-dump-soundspan";
        runtimeInputs = [ pkgs.util-linux config.services.postgresql.package ];
        text = ''
          umask 077
          install -d -m 0700 /var/backups/media/soundspan-dump
          chown postgres:postgres /var/backups/media/soundspan-dump
          rm -rf /var/backups/media/soundspan-dump/*
          runuser -u postgres -- pg_dump --dbname=soundspan --format=custom \
            --file=/var/backups/media/soundspan-dump/soundspan.dump
        '';
      };
      run = operation: lib.optionalString aurral "${pkgs.util-linux}/bin/flock -n /run/aurral-maintenance/lock "
        + "${pkgs.python3}/bin/python3 ${./media-provision/backup.py} --settings ${settings} --password-file %d/password --runtime-dir /run/media-state-backup ${operation}";
      common = {
        path = [ pkgs.restic pkgs.systemd ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          UMask = "0077";
          LoadCredential = [ "password:${config.age.secrets.media-backup-password.path}" ];
          RuntimeDirectory = "media-state-backup";
          RuntimeDirectoryMode = "0700";
          RuntimeDirectoryPreserve = "yes";
          TimeoutStartSec = "2h";
          TimeoutStopSec = "5min";
        };
      };
    in {
      age.secrets.media-backup-password = {
        file = ../../../secrets/media-backup-password.age;
        mode = "0400";
      };
      systemd.tmpfiles.settings."10-media-backup" = {
        "/var/backups/media".d = { mode = "0755"; user = "root"; group = "root"; };
        "/var/backups/media/restic".d.mode = "0700";
        "/var/lib/media-restore".d.mode = "0700";
      };
      systemd.services.media-state-backup = common // {
        description = "Encrypted acquisition-state backup";
        serviceConfig = common.serviceConfig // {
          ExecStart = run "backup";
          ExecStartPre = lib.optionals soundspan [ "${dumpDatabase}/bin/media-state-dump-soundspan" ];
          ExecStopPost = run "resume";
        };
      };
      systemd.services.media-state-install = common // {
        description = "Install verified acquisition state from staging";
        environment.MEDIA_STATE_DEBUG = "1";
        serviceConfig = common.serviceConfig // {
          ExecStart = run "install";
        };
      };
      systemd.services.media-state-restore = common // {
        description = "Verify acquisition-state restore into protected staging";
        serviceConfig = common.serviceConfig // {
          ExecStart = run "restore";
        };
      };
      systemd.timers.media-state-backup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "30min";
          Persistent = true;
        };
      };
    };
}
