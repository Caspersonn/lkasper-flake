{ lib, pkgs, ...}:

{
  services.mysql = {
    enable = true;
    package = pkgs.mysql84;
    initialDatabases = [
      { name = "tokenserver_rs"; }
      { name = "syncstorage_rs"; }
      { name = "kimai"; }
    ];
    ensureDatabases = [
      "tokenserver_rs"
      "syncstorage_rs"
      "kimai"
    ];
  };

  environment.systemPackages = with pkgs; [
    mysql84
  ];
}
