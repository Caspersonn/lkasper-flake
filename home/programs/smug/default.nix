{ lib, config, pkgs, ... }:
{
  home.file = {
    ".config/smug" = {
      source = ./smug;
      recursive = true;
    }; 
  };
}
