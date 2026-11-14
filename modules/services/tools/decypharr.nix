{ inputs, ... }: {
  # Download client for HolyArrs: it poses as qBittorrent, hands torrents to
  # Real-Debrid and drops symlinks into its own Real-Debrid mount, so nothing
  # is downloaded or seeded locally. The Real-Debrid key, login, mount and
  # folders are set in its first-run wizard and kept in /var/lib/decypharr.
  flake.modules.nixos.decypharr = { config, lib, pkgs, ... }:
    let
      port = 8282;
      mountPoint = "/data/debrid";
      # A crashed FUSE mount leaves "Transport endpoint is not connected"
      # behind; clear it around every start and stop. "-": not mounted is fine.
      unmount = "-${pkgs.util-linux}/bin/umount --lazy ${mountPoint}";
    in
    {
      virtualisation.oci-containers.containers.decypharr = {
        image = "cy01/blackhole:v2.7.2";
        # Host network: the NixOS firewall below decides who reaches the port.
        networks = [ "host" ];
        environment = {
          PUID = toString config.users.users.media.uid;
          PGID = toString config.users.groups.media.gid;
          UMASK = "002";
          TZ = config.time.timeZone;
        };
        volumes = [
          # Decypharr chowns /app on every start; keep it to itself.
          "/var/lib/decypharr:/app"
          # rshared: the mount it creates at /data/debrid shows up on the host.
          "/data:/data:rshared"
        ];
        devices = [ "/dev/fuse:/dev/fuse:rwm" ];
        capabilities.SYS_ADMIN = true;
        extraOptions = [ "--security-opt=apparmor=unconfined" ];
      };

      systemd.services.docker-decypharr.serviceConfig = {
        ExecStartPre = lib.mkAfter [ unmount ];
        ExecStopPost = lib.mkAfter [ unmount ];
      };

      systemd.tmpfiles.settings."10-decypharr"."/var/lib/decypharr".d = {
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
