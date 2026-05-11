# Run before
# sudo mkdir -p /srv/cobblemon
# sudo chown 1000:1000 /srv/cobblemon
{ config, pkgs, ... }:

{
  flake.modules.nixos.minecraft-server = { lib, config, pkgs, ... }: {
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

      # Additional mods (Modrinth)
      MODRINTH_PROJECTS = "architectury-api,rctapi,forge-config-api-port:N5qzq0XV";
      MODRINTH_ALLOWED_VERSION_TYPE = "beta";

      # CurseForge mods (downloaded via itzg MODS env)
      # rctmod 0.18.1-beta (Fabric 1.21.1): https://www.curseforge.com/minecraft/mc-mods/rctmod/download/7913182
      # Radical Gyms & Structures 0.6 (Fabric 1.21.1): https://www.curseforge.com/minecraft/mc-mods/radical-gyms-structures-cobblemon/download/7330950
      MODS = "https://edge.forgecdn.net/files/7913/182/rctmod-fabric-1.21.1-0.18.1-beta.jar,https://edge.forgecdn.net/files/7330/950/RadicalGymsandStructures-Cobblemon-Fabric-1.21.1-0.6.jar";

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
