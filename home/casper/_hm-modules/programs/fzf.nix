{config, pkgs, lib, ...}: 

{
programs.fzf = {
    enable = true;
    enableZshIntegration = true;
 };
}
