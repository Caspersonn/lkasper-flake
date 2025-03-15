{config, lib, pkgs, unstable, ... }:

{
  programs.coolercontrol.enable = true;
  environment.systemPackages = with pkgs; [
    lm_sensors
  ];
}
