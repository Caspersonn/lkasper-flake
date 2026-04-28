# Run before
# sudo mkdir -p /srv/cobblemon
# sudo chown 1000:1000 /srv/cobblemon
{ config, pkgs, ... }:

{
  flake.modules.nixos.minecraft-server = { lib, config, pkgs, ... }: {
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.cobblemon = {
    image = "docker.io/itzg/minecraft-server:java21";
    autoStart = true;

    ports = [ "25565:25565" ];
    volumes = [ "/srv/cobblemon:/data" ];

    environment = {
      EULA = "TRUE";

      # Modrinth modpack installer
      MODPACK_PLATFORM = "MODRINTH";
      MODRINTH_MODPACK = "https://modrinth.com/modpack/cobblemon-fabric/version/1.7.3";
      VERSION = "1.21.1";

      # Tune this for your server
      MEMORY = "4G";
      TZ = "Europe/Amsterdam";

      # Basic server.properties values
      MOTD = "Cobblemon Official Modpack 1.7.3";
      MAX_PLAYERS = "10";
      DIFFICULTY = "normal";
      VIEW_DISTANCE = "16";
      SIMULATION_DISTANCE = "12";
      ONLINE_MODE = "TRUE";
    };
  };

  networking.firewall.allowedTCPPorts = [ 25575 25565];
  };
}
