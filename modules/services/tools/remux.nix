{ ... }: {
  flake.modules.nixos.remux = { config, lib, pkgs, ... }:
    let
      image = pkgs.callPackage ./remux/_image.nix { };
      state = "/var/lib/remux-provision";
      scripts = pkgs.runCommand "remux-provision-scripts" { } ''
        mkdir -p "$out"
        cp ${./media-provision/remux.py} "$out/remux.py"
        cp ${./media-provision/decypharr.py} "$out/decypharr.py"
      '';
      bootstrap = pkgs.writeShellApplication {
        name = "remux-isolated-bootstrap";
        runtimeInputs = [ pkgs.docker pkgs.python3 pkgs.coreutils ];
        text = ''
          umask 077
          rm -f /run/remux-client/ready
          docker load -i ${image} >/dev/null
          if docker container inspect remux-bootstrap >/dev/null 2>&1; then
            docker rm -f remux-bootstrap >/dev/null
          fi
          trap 'docker rm -f remux-bootstrap >/dev/null 2>&1 || true' EXIT
          docker run -d --name remux-bootstrap --network none \
            --user ${toString config.users.users.media.uid}:${toString config.users.groups.media.gid} \
            --env LOG_FILE_ENABLED=false --env DISABLE_DHT=true \
            --volume /var/lib/remux:/data \
            --tmpfs /tmp:rw,nosuid,nodev,size=512m \
            ghcr.io/lostb1t/remux:latest >/dev/null
          python3 -B ${scripts}/remux.py --container remux-bootstrap --state-dir ${state}
        '';
      };
      source = pkgs.writeShellApplication {
        name = "remux-source-provision";
        runtimeInputs = [ pkgs.docker pkgs.python3 pkgs.coreutils ];
        text = ''
          rm -f /run/remux-client/ready
          python3 -B ${scripts}/remux.py --container remux-main --state-dir ${state} \
            --source-credentials ${config.age.secrets.remux-aiostreams.path}
          touch /run/remux-client/ready
        '';
      };
    in {
      assertions = [{ assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux"; message = "Remux image is pinned for x86_64-linux."; }];
      age.secrets.remux-aiostreams = {
        file = ../../../secrets/remux-aiostreams.age;
        mode = "0400";
      };
      users.groups.jellyfin = { };
      users.users.jellyfin = {
        isSystemUser = true;
        group = "jellyfin";
        home = "/var/lib/jellyfin";
      };
      systemd.tmpfiles.rules = [
        "d /var/lib/remux 0750 media media -"
        "d ${state} 0700 root root -"
        "d /run/remux-client 0755 root root -"
      ];
      virtualisation.oci-containers.containers.remux-main = {
        image = "ghcr.io/lostb1t/remux:latest";
        imageFile = image;
        user = "${toString config.users.users.media.uid}:${toString config.users.groups.media.gid}";
        ports = [ "127.0.0.1:8097:3000" ];
        environment = { LOG_FILE_ENABLED = "false"; DISABLE_DHT = "true"; };
        volumes = [ "/var/lib/remux:/data" "/data/media:/media:ro" ];
        extraOptions = [
          "--tmpfs=/tmp:rw,nosuid,nodev,size=512m"
          "--tmpfs=/data/cache:rw,nosuid,nodev,size=1g,uid=${toString config.users.users.media.uid},gid=${toString config.users.groups.media.gid}"
          "--tmpfs=/data/transcode_sessions:rw,nosuid,nodev,size=2g,uid=${toString config.users.users.media.uid},gid=${toString config.users.groups.media.gid}"
        ];
      };
      systemd.services.docker-remux-main = {
        preStart = lib.mkAfter ''
          ${bootstrap}/bin/remux-isolated-bootstrap
        '';
        serviceConfig.ExecStopPost = lib.mkAfter [ "${pkgs.coreutils}/bin/rm -f /run/remux-client/ready" ];
      };
      systemd.services.remux-source-provision = {
        wantedBy = [ "multi-user.target" ];
        after = [ "docker-remux-main.service" "docker-aiostreams.service" ];
        requires = [ "docker-remux-main.service" ];
        partOf = [ "docker-remux-main.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${source}/bin/remux-source-provision";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -f /run/remux-client/ready";
          UMask = "0077";
          TimeoutStartSec = "5min";
        };
      };
      services.nginx.virtualHosts."jellyfin.inspiravita.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8097";
          proxyWebsockets = true;
          extraConfig = ''
            if (!-f /run/remux-client/ready) { return 503; }
            proxy_buffering off;
          '';
        };
      };
    };
}
