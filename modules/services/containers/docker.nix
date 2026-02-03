{ inputs, ... }: {
  flake.modules.nixos.docker = { pkgs, unstable, ... }: {
    environment.systemPackages = with pkgs; [ docker ffmpeg ];

    virtualisation.oci-containers.backend = "docker";
    virtualisation.docker.enable = true;
  };
}
