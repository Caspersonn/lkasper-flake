{ inputs, ... }: {
  # Shared /data tree for HolyArrs, its downloader and (later) a media server.
  # Every service mounts /data at the same path, so symlinks resolve everywhere.
  flake.modules.nixos.media-storage = { ... }: {
    # Fixed ids: the containers receive them as PUID/PGID.
    users.groups.media.gid = 2000;
    users.users.media = {
      isSystemUser = true;
      uid = 2000;
      group = "media";
      description = "Owner of the shared media tree in /data";
    };
    users.users.casper.extraGroups = [ "media" ];

    systemd.tmpfiles.settings = {
      # Shared parent must be root-owned, otherwise tmpfiles refuses to create
      # the service-owned folders below it ("unsafe path transition").
      "10-data-root"."/data".d = { user = "root"; group = "root"; mode = "0755"; };
      "10-media" =
        let
          shared = { user = "media"; group = "media"; mode = "2770"; };
        in
        {
          # Mount point for the Real-Debrid mount. No owner or mode on purpose:
          # tmpfiles then leaves the mounted folder alone on every rebuild.
          "/data/debrid".d = { };
          "/data/symlinks".d = shared;
          "/data/media".d = shared;
          "/data/media/movies".d = shared;
          "/data/media/tv".d = shared;
          "/data/media/music".d = shared;
        };
    };
  };
}
