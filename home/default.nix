{hostname, ...}: let
  inherit (import ../../../hosts/${hostname}/variables.nix);
in {
  imports = [
    ./desktop-environments
  ]
  ++
    map (n: "${./programs}/${n}") (builtins.attrNames (builtins.readDir ./programs));

}

