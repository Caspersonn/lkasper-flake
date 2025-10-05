{config, lib, pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    acme-sh
    openssl
    invidious
    stremio
  ];
}
