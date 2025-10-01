{ config, lib, pkgs, unstable, ... }:{

  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];

  environment.systemPackages = with pkgs; [
    bambu-studio
  ];
}
