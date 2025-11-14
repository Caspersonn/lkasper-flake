{...}:
{
  services.neo4j = {
    enable = true;
    http.enable = true;
    https.enable = false;
    bolt.enable = true;
    bolt.tlsLevel = "DISABLED";
  };
}
