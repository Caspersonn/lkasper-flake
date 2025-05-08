{hostname, ...}: let
  inherit (import ../../../hosts/${hostname}/variables.nix);
in {
  imports = [
    ./desktop-environments
    ./themes
  ]
  ++
    map (n: "${./programs}/${n}") (builtins.attrNames (builtins.readDir ./programs));

}

