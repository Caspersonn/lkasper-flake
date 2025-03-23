{ config, lib, pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerdfonts
    fira-code-nerdfont
  ];
}
