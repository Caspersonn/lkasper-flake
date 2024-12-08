{config, lib, pkgs, agenix, unstable, ... }:
{
  environment.systemPackages = with pkgs; [
    docker
    ffmpeg
  ];
  virtualisation.oci-containers.backend = "docker";
}
