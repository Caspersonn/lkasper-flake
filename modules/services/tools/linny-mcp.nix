{ inputs, ... }: {
  flake.modules.nixos.linny-mcp = { config, lib, pkgs, ... }:
    let
      corpusPath = "/home/casper/git/gh.caspersonn/lkasper-linny";
    in
      {
      imports = [ inputs.linny-mcp.nixosModules.linny-mcp ];

      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      age.secrets.linny-mcp-tokens = {
        file = ../../../secrets/linny-mcp-tokens.age;
        owner = "casper";
        group = "users";
      };

      services.linny-mcp = {
        enable = true;
        package = inputs.linny-mcp.packages."${pkgs.system}".default;
        inherit corpusPath;
        listenAddress = "127.0.0.1";
        port = 8765;
        tokensFile = config.age.secrets.linny-mcp-tokens.path;
        # The notebook lives in casper's home and is a casper-owned git repo.
        user = "casper";
        group = "users";
      };

      systemd.services.linny-mcp = {
        # linny-mcp shells out to git for conflict detection and history.
        path = [ pkgs.git ];
        # ProtectHome = true hides /home entirely; read-only lets the
        # ReadWritePaths entry for the corpus take effect.
        serviceConfig.ProtectHome = lib.mkForce "read-only";
      };
    };
}
