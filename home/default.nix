{...}:
{
  imports = [
    ./desktop-environments
    ./themes
  ]
  ++
    map (n: "${./programs}/${n}") (builtins.attrNames (builtins.readDir ./programs));

}

