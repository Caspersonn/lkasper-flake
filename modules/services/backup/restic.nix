{ config, lib, ... }:
let
  cfg = config.casper.backup;
  inherit (lib) mkOption types;
in
{
  options.casper.backup = {
    server = {
      host = mkOption {
        type = types.str;
        default = "kaito";
        description = "Host that runs the REST server and all pruning and checks.";
      };

      address = mkOption {
        type = types.str;
        default = "kaito.mesh";
        description = "Mesh name clients use to reach the REST server.";
      };

      port = mkOption {
        type = types.port;
        default = 8100;
        description = "REST server port, opened on the Nebula interface only.";
      };

      dataDir = mkOption {
        type = types.str;
        default = "/srv/restic";
        description = ''
          REST repository storage. Kept outside /var/lib so the kaito state
          backup never re-uploads the client repositories.
        '';
      };
    };

    s3 = {
      bucket = mkOption {
        type = types.str;
        description = "S3 bucket holding one repository prefix per host.";
      };

      region = mkOption {
        type = types.str;
        description = "AWS region of the bucket.";
      };
    };

    retention = {
      kaito = mkOption {
        type = types.listOf types.str;
        default = [ "--keep-hourly 24" "--keep-daily 7" "--keep-weekly 4" ];
        description = "forget flags for the repositories on kaito.";
      };

      s3 = mkOption {
        type = types.listOf types.str;
        default = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
        description = "forget flags for the S3 repositories.";
      };
    };

    clients = mkOption {
      default = { };
      description = ''
        Hosts whose /home is backed up, declared by each host in modules/hosts
        next to its Nebula node. The server derives htpasswd users, password
        secrets and maintenance jobs from this set.
      '';
      type = types.attrsOf (types.submodule {
        options = {
          extraExcludes = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Extra restic exclude patterns, applied after the policy.";
          };

          extraIncludes = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              Extra hidden paths to keep, as absolute patterns without the
              leading "!" (for example "/home/*/.librewolf").
            '';
          };
        };
      });
    };

    repository = {
      rest = mkOption {
        type = types.functionTo types.str;
        internal = true;
        readOnly = true;
        default = host: "rest:http://${cfg.server.address}:${toString cfg.server.port}/${host}/";
        description = "REST repository URL of a host.";
      };

      s3 = mkOption {
        type = types.functionTo types.str;
        internal = true;
        readOnly = true;
        default = host: "s3:s3.${cfg.s3.region}.amazonaws.com/${cfg.s3.bucket}/${host}";
        description = "S3 repository URL of a host.";
      };
    };
  };

  config = {
    casper.backup.s3 = {
      bucket = "restic-backup-kaito";
      region = "eu-central-1";
    };

    flake.backup = { inherit (cfg) server s3 retention clients; };
  };
}
