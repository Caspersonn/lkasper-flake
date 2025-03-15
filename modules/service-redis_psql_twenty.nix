{ lib, pkgs, ...}:

{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    ensureUsers = [ { name = "postgres"; } ]; 
    settings = {
        port = 5432;
        ssl = false;
    };
    authentication = ''
    #type database DBuser origin-address auth-method
    # ipv4 from everywhere (including dockers) firewall and SG blocks real outside connections
      host  all      all     0.0.0.0/0      scram-sha-256
    # ipv6 from localhost
      host all       all     ::1/128        scram-sha-256
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      alter user postgres with password 'postgres';
    '';
  };

  services.redis.servers."" = {
    enable = true;
  };
}
