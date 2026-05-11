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
      MODRINTH_PROJECTS = "architectury-api,rctapi,forge-config-api-port=v21.1.6-1.21.1-Fabric";

      # CurseForge mod: rctmod — download manually and place in /srv/cobblemon/mods/
      # https://www.curseforge.com/minecraft/mc-mods/rctmod (latest for 1.21.1 Fabric)
      REMOVE_OLD_MODS_EXCLUDE = "rctmod*.jar";

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
