{ inputs, ... }: {
  flake.modules.nixos.neo4j = { config, pkgs, ... }: {
    services.neo4j = {
      enable = true;
      http.enable = true;
      https.enable = false;
      bolt.enable = true;
      bolt.tlsLevel = "DISABLED";
    };
  };
}
