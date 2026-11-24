{ config, lib, ... }:
let
  backup = config.casper.backup;
  tun = "nebula.${config.casper.nebula.network}";
  clients = builtins.attrNames backup.clients;
in
{
  flake.modules.nixos.backup-restic-server = { config, lib, ... }:
    let
      host = config.networking.hostName;
      secret = name: ../../../secrets + "/${name}";
      resticSecret = name: {
        file = secret "${name}.age";
        owner = "restic";
        group = "restic";
        mode = "0400";
      };

      # Pruning and checks run here only: clients cannot delete (append-only
      # REST server, S3 keys without delete rights). Concurrent client
      # backups are handled by restic's repository locks.
      retryLock = "--retry-lock 1h";
      maintTimer = {
        OnCalendar = "Sun 04:00";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };

      maintLocal = client: lib.nameValuePair "maint-local-${client}" {
        user = "restic";
        repository = "${backup.server.dataDir}/${client}";
        passwordFile = config.age.secrets."restic-${client}-password".path;
        paths = [ ];
        pruneOpts = backup.retention.kaito ++ [ retryLock ];
        runCheck = true;
        checkOpts = [ retryLock "--read-data-subset=10%" ];
        timerConfig = maintTimer;
      };

      maintS3 = client: lib.nameValuePair "maint-s3-${client}" {
        user = "restic";
        repository = backup.repository.s3 client;
        extraOptions = [ "s3.region=${backup.s3.region}" ];
        passwordFile = config.age.secrets."restic-${client}-password".path;
        # kaito-backup IAM key, the only key allowed to delete in the bucket.
        environmentFile = config.age.secrets.restic-kaito-env.path;
        paths = [ ];
        pruneOpts = backup.retention.s3 ++ [ retryLock ];
        runCheck = true;
        checkOpts = [ retryLock ];
        timerConfig = maintTimer;
      };
    in
    {
      assertions = [{
        assertion = host == backup.server.host;
        message = "backup-restic-server is imported on ${host}, but casper.backup.server.host is ${backup.server.host}.";
      }];

      age.secrets = {
        restic-htpasswd = resticSecret "restic-htpasswd";
        restic-kaito-env = resticSecret "restic-kaito-env";
      } // lib.genAttrs (map (c: "restic-${c}-password") clients) resticSecret;

      services.restic.server = {
        enable = true;
        # Socket activation takes a bare port; the firewall limits it to the mesh.
        listenAddress = toString backup.server.port;
        inherit (backup.server) dataDir;
        appendOnly = true;
        privateRepos = true;
        htpasswd-file = config.age.secrets.restic-htpasswd.path;
      };

      systemd.tmpfiles.rules = [ "d ${backup.server.dataDir} 0700 restic restic -" ];

      networking.firewall.interfaces.${tun}.allowedTCPPorts = [ backup.server.port ];

      services.restic.backups = lib.listToAttrs (map maintLocal clients ++ map maintS3 clients);
    };
}
