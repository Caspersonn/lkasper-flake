# Run before
# sudo mkdir -p /srv/cobblemon
# sudo chown 1000:1000 /srv/cobblemon
{ config, pkgs, ... }:

{
  flake.modules.nixos.minecraft-server = { lib, config, pkgs, ... }:
  let
    # rctmod (CurseForge-only) — pinned via fetchurl
    rctmod = pkgs.fetchurl {
      url = "https://edge.forgecdn.net/files/7913/182/rctmod-fabric-1.21.1-0.18.1-beta.jar";
      hash = "sha256-kpUdO+R1oEM/jvUIQ5cwcj4ukB3R47JQnCkgUDHU61E=";
    };

    extraMods = pkgs.linkFarm "cobblemon-extra-mods" [
      { name = "rctmod-fabric-1.21.1-0.18.1-beta.jar"; path = rctmod; }
    ];
  in {
  virtualisation.oci-containers.containers.cobblemon = {
    image = "docker.io/itzg/minecraft-server:java21";
    autoStart = true;

    ports = [ "25565:25565" ];
    volumes = [
      "/srv/cobblemon:/data"
          #"${extraMods}:/extra-mods:ro"
    ];

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
      MODRINTH_PROJECTS = "architectury-api,rctapi,forge-config-api-port:N5qzq0XV,radical-gyms-cobblemon";
      MODRINTH_ALLOWED_VERSION_TYPE = "beta";

      # rctmod (CurseForge) — copied from Nix store into /data/mods/ on startup
          #COPY_MODS_SRC = "/extra-mods";
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
