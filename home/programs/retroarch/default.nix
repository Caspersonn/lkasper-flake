{config, pkgs, lib, username, ...}: 
{
  imports = [
    ./retroarch.nix
  ];

  home.file = {
    "/home/${username}/.config/retroarch/config" = {
      source = ./config;
      recursive = true;
    };
  };
}
