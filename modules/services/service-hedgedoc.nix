{config, lib, pkgs, ...}:
{
  services.hedgedoc = {
    enable = true;
    environmentFile = "/home/casper/hedgedoc.env";
    settings = {
      domain = "localhost";
      dbURL = "postgres://hedgedoc:\${DB_PASSWORD}@localhost:5432/hedgedoc";
      allowOrigin = [
        "*"
      ];
      db = {
        username = "hedgedoc";
        password = "$DB_PASSWORD";
        database = "hedgedoc";
        host     = "localhost:5432";
        dialect  = "postgresql";
      };
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    enableTCPIP = true;
    ensureUsers = [ { name = "postgres"; } ]; 
    settings = {
      port = 5432;
      ssl = false;
    };

    extensions = ps: with ps; [
      pgvector
    ];

    authentication = ''
    #type database DBuser origin-address auth-method
    # ipv4 from everywhere (including dockers) firewall and SG blocks real outside connections
      host  all      all     0.0.0.0/0      scram-sha-256
    # ipv6 from localhost
      host all       all     ::1/128        scram-sha-256
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      create user hedgedoc login superuser;
      alter user hedgedoc with password 'hedgedoc';
      alter user postgres with password 'postgres';
      create database hedgedoc;
    '';
  };
}
