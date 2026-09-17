# minecraft-skyblock.nix
{ inputs, ... }: {
  flake.modules.nixos.skyblock-minecraft = { config, lib, pkgs, unstable, ... }: 
    let
      dataDir = "/var/lib/minecraft";

      bentobox = pkgs.fetchurl {
        url = "https://github.com/BentoBoxWorld/BentoBox/releases/download/3.22.4/BentoBox-3.22.4.jar";
        hash = "sha256-tgdyMMwB1k8El6CVqdw7TXmTr6GYWr+oC5JqFgtkWWY=";
      };

      bskyblock = pkgs.fetchurl {
        url = "https://github.com/BentoBoxWorld/BSkyBlock/releases/download/1.20.0/BSkyBlock-1.20.0.jar";
        hash = "sha256-AbVNqAIQ0DI0kQh3lINGOLyo28yOqUMtu54oohjlJNo=";
      };

      # Force Paper to run using Java 25.
      paper25 = pkgs.writeShellScriptBin "minecraft-server" ''
    exec ${pkgs.jdk25_headless}/bin/java "$@" \
    -jar ${pkgs.papermc}/share/papermc/papermc.jar \
    nogui
    '';

    in
      {
      services.minecraft-server = {
        enable = true;
        eula = true;
        declarative = true;
        openFirewall = true;

        dataDir = dataDir;

        # IMPORTANT: use our Java 25 launcher, not pkgs.papermc directly.
        package = paper25;

        jvmOpts = lib.concatStringsSep " " [
          "-Xms2G"
          "-Xmx4G"
          "-XX:+UseG1GC"
        ];

        serverProperties = {
          server-port = 25565;
          gamemode = "survival";
          difficulty = "normal";
          max-players = 10;
          online-mode = true;
          spawn-protection = 0;
          view-distance = 8;
          simulation-distance = 6;
          motd = "Private SkyBlock";
        };
      };

      systemd.services.minecraft-server.preStart = lib.mkAfter ''
    mkdir -p plugins/BentoBox/addons

    ln -sfn ${bentobox} \
      plugins/BentoBox.jar

    ln -sfn ${bskyblock} \
      plugins/BentoBox/addons/BSkyBlock.jar
      '';
    networking.firewall.allowedTCPPorts = [ 25575 25565];
    };
}
