{ ... }:

{
  imports = []
  ++
    map (n: "${./gnome}/${n}") (builtins.attrNames (builtins.readDir ./gnome))
  ++
    map (n: "${./programs}/${n}") (builtins.attrNames (builtins.readDir ./programs));
}
