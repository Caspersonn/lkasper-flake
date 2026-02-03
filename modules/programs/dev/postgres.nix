{ inputs, ... }: {
  flake.modules.nixos.dev-postgres = { pkgs, ... }: {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16_jit;
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
        host    all             all             127.0.0.1/32            md5
        # IPv6 local connections:
        host    all             all             ::1/128                 md5

        host    all     all     172.17.0.0/16     md5
        host    all     all     172.18.0.0/16     md5
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        alter user postgres with password 'postgres';
      '';
    };
  };
}
