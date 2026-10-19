{ ... }:
{
  # Library manager; root folder and login are set by music-provision.
  flake.modules.nixos.lidarr = { config, lib, ... }:
    let
      players = lib.filter (u: config.services.${u}.enable) [ "navidrome" "jellyfin" ];
    in
    {
      # LIDARR__AUTH__APIKEY (Lidarr) + LIDARR_API_KEY (Aurral), same key.
      age.secrets.music-lidarr-api.file = ../../../secrets/music-lidarr-api.age;

      services.lidarr = {
        enable = true;
        openFirewall = false;
        environmentFiles = [ config.age.secrets.music-lidarr-api.path ];
        settings = {
          server.bindaddress = "127.0.0.1";
          auth = {
            method = "Forms";
            required = "Enabled";
          };
        };
      };

      users.users = lib.genAttrs players (_: { extraGroups = [ "lidarr" ]; });

      systemd.tmpfiles.rules = [
        "d /mnt/audio/music/lidarr 0755 lidarr lidarr -"
      ];

      services.nginx = {
        enable = true;
        virtualHosts."lidarr.inspiravita.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8686";
            proxyWebsockets = true;
          };
        };
      };
    };
}
