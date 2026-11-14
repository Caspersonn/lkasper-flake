{ inputs, ... }: {
  # HolyArrs: finds, grabs and organises movies, shows and music into /data/media.
  # Owner account, sources and downloader are set in its web UI and kept in
  # /var/lib/holyarrs. Back up holyarrs.key from there by hand: HolyArrs' own
  # backups leave it out.
  flake.modules.nixos.holyarrs = { config, ... }:
    let
      port = 6262;
    in
    {
      virtualisation.oci-containers.containers.holyarrs = {
        # Releases come every few hours; upgrade by changing this tag.
        image = "holyarrs/holyarrs:1.0.19";
        # Host network: the NixOS firewall below decides who reaches the port,
        # and Jackett and Decypharr are reachable on 127.0.0.1.
        networks = [ "host" ];
        environment = {
          PUID = toString config.users.users.media.uid;
          PGID = toString config.users.groups.media.gid;
          UMASK = "002";
          TZ = config.time.timeZone;
          # Downloads are symlinks into the Real-Debrid mount; import them as links.
          HOLYARRS_FOLLOW_LINKS = "1";
          HOLYARRS_SAVE_PATH = "/data/symlinks";
          # IP addresses are always accepted; host names must be listed.
          HOLYARRS_ALLOWED_HOSTS = "${config.networking.hostName}.mesh";
        };
        volumes = [
          "/var/lib/holyarrs:/config"
          # rslave: sees the Real-Debrid mount even when it appears after start.
          "/data:/data:rslave"
        ];
      };

      # Start after the downloader's mount, but keep running if it restarts.
      systemd.services.docker-holyarrs.after = [ "docker-decypharr.service" ];

      systemd.tmpfiles.settings."10-holyarrs"."/var/lib/holyarrs".d = {
        user = "media";
        group = "media";
        mode = "0750";
      };

      networking.firewall.interfaces = {
        "nebula.mesh".allowedTCPPorts = [ port ];
        ${config.services.tailscale.interfaceName}.allowedTCPPorts = [ port ];
      };
    };
}
