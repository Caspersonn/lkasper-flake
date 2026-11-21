{ ... }: {
  flake.modules.nixos.aurral-flows = { config, lib, pkgs, ... }:
    let
      cfg = config.services.aurralFlows;
      state = "/var/lib/aurral-flows-provision";
      images = import ./aurral-flows/_images.nix { inherit pkgs; };
      favoriteService = import ./aurral-flows/_favorite-service.nix { inherit pkgs; };
      scripts = pkgs.runCommand "aurral-flows-provision" { } ''
        mkdir -p "$out"
        cp ${./media-provision/decypharr.py} "$out/decypharr.py"
        cp ${./media-provision/aurral.py} "$out/aurral.py"
        cp ${./media-provision/slskd_aurral.py} "$out/slskd_aurral.py"
        cp ${./media-provision/aurral_capacity.py} "$out/aurral_capacity.py"
        cp ${./media-provision/aurral_cleanup.py} "$out/aurral_cleanup.py"
      '';
      capacity = pkgs.writeShellScript "aurral-capacity" ''
        exec ${pkgs.python3}/bin/python3 ${scripts}/aurral_capacity.py \
          --budget ${toString cfg.temporaryBudgetBytes} \
          --minimum-free ${toString cfg.minimumFreeBytes} "$@"
      '';
      cleanup = pkgs.writeShellScript "aurral-staging-cleanup" ''
        exec ${pkgs.util-linux}/bin/flock -n /run/aurral-maintenance/lock \
          ${pkgs.python3}/bin/python3 ${scripts}/aurral_cleanup.py "$@"
      '';
      prepare = pkgs.writeShellApplication {
        name = "prepare-aurral-slskd";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          umask 077
          ${pkgs.python3}/bin/python3 ${scripts}/slskd_aurral.py \
            --state-dir /var/lib/slskd-aurral \
            --credentials ${state}/slskd.json ${lib.optionalString cfg.connect "--connect"}
          chown media:media /var/lib/slskd-aurral/slskd.yml
        '';
      };
      provision = pkgs.writeShellScript "provision-aurral-flows" ''
        set -eu
        ${pkgs.coreutils}/bin/rm -f /run/aurral-client/ready
        ${pkgs.python3}/bin/python3 ${scripts}/aurral.py \
          --state-dir ${state} \
          --settings ${./media-provision/aurral-settings.json} \
          --credentials ${state}/slskd.json
        ${pkgs.coreutils}/bin/touch /run/aurral-client/ready
      '';
    in {
      options.services.aurralFlows = {
        enable = lib.mkEnableOption "isolated Aurral Flows and Soulseek acquisition";
        connect = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Connect the isolated slskd instance to Soulseek using its protected generated account.";
        };
        clientDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional HTTPS hostname for the authenticated Aurral UI and its Subsonic endpoint.";
        };
        temporaryBudgetBytes = lib.mkOption {
          type = lib.types.ints.positive;
          default = 20 * 1024 * 1024 * 1024;
          description = "Acquisition suspension threshold for flow and slskd staging bytes.";
        };
        minimumFreeBytes = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 20 * 1024 * 1024 * 1024;
          description = "Minimum available bytes on both music and staging filesystems.";
        };
      };
      config = lib.mkIf cfg.enable {
        assertions = [{
          assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
          message = "The pinned Aurral Flows images are verified for x86_64-linux.";
        }];
        users.groups.media.gid = 2000;
        users.users.media = {
          isSystemUser = true;
          uid = 2000;
          group = "media";
          description = "Owner of the shared media tree in /data";
        };
        users.users.casper.extraGroups = [ "media" ];
        systemd.tmpfiles.settings = {
          "10-data-root"."/data".d = { user = "root"; group = "root"; mode = "0755"; };
        };
        systemd.tmpfiles.rules = [
          "d ${state} 0700 root root -"
          "d /run/aurral-maintenance 0700 root root -"
          "d /run/aurral-client 0755 root root -"
          "d /var/lib/aurral-flows 0750 media media -"
          "d /var/lib/slskd-aurral 0750 media media -"
          "d /data/music-aurral 2770 media media -"
          "d /data/downloads 0755 root root -"
          "d /data/downloads/slskd 2770 media media -"
          "d /data/downloads/slskd/complete 2770 media media -"
          "d /data/downloads/slskd/incomplete 2770 media media -"
        ];
        virtualisation.oci-containers.containers = {
          slskd-aurral = {
            image = "slskd/slskd:latest";
            imageFile = images.slskd;
            networks = [ "host" ];
            user = "${toString config.users.users.media.uid}:${toString config.users.groups.media.gid}";
            environment = {
              SLSKD_HTTP_PORT = "5032";
              SLSKD_SLSK_LISTEN_PORT = "50310";
              SLSKD_UMASK = "0007";
            };
            volumes = [
              "/var/lib/slskd-aurral:/app"
              "/data/downloads/slskd:/data/downloads/slskd"
            ];
          };
          aurral-flows = {
            image = "ghcr.io/lklynet/aurral:latest";
            imageFile = images.aurral;
            networks = [ "host" ];
            environment = {
              PORT = "3002";
              PUID = toString config.users.users.media.uid;
              PGID = toString config.users.groups.media.gid;
              AURRAL_DATA_DIR = "/config";
              LIBRARY_FOLDER = "/data/music-aurral";
              FILE_BROWSE_ROOTS = "/data/music-aurral,/data/downloads/slskd";
              XDG_CACHE_HOME = "/config/cache";
              TZ = config.time.timeZone;
            } // lib.optionalAttrs (cfg.clientDomain != null) {
              TRUST_PROXY = "true";
              AURRAL_PUBLIC_URL = "https://${cfg.clientDomain}";
            };
            volumes = [
              "/var/lib/aurral-flows:/config"
              "${favoriteService}:/app/backend/services/subsonicLibraryService.ts:ro"
              "/data/music-aurral:/data/music-aurral"
              "/data/downloads/slskd:/data/downloads/slskd"
            ];
          };
        };
        systemd.services.docker-slskd-aurral.serviceConfig.ExecStartPre = lib.mkAfter [
          "${prepare}/bin/prepare-aurral-slskd"
        ];
        systemd.services.docker-slskd-aurral.serviceConfig.ExecCondition = "${capacity} --check";
        services.nginx = lib.mkIf (cfg.clientDomain != null) {
          enable = true;
          virtualHosts.${cfg.clientDomain} = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:3002";
              proxyWebsockets = true;
              extraConfig = ''
                if (!-f /run/aurral-client/ready) { return 503; }
                proxy_buffering off;
              '';
            };
          };
        };
        systemd.services.aurral-capacity = {
          after = [ "aurral-flows-provision.service" ];
          path = [ pkgs.systemd ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.util-linux}/bin/flock -n -E 0 /run/aurral-maintenance/lock ${capacity}";
            UMask = "0077";
          };
        };
        systemd.timers.aurral-capacity = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "30s";
            OnUnitActiveSec = "10s";
            AccuracySec = "1s";
          };
        };
        systemd.services.aurral-staging-cleanup = {
          after = [ "aurral-flows-provision.service" ];
          path = [ pkgs.systemd ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = cleanup;
            ExecStopPost = "${cleanup} --resume";
            TimeoutStartSec = "15min";
            TimeoutStopSec = "10min";
            UMask = "0077";
          };
        };
        systemd.timers.aurral-staging-cleanup = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            RandomizedDelaySec = "30min";
            Persistent = true;
          };
        };
        systemd.services.aurral-flows-provision = {
          wantedBy = [ "multi-user.target" ];
          after = [ "docker-aurral-flows.service" "docker-slskd-aurral.service" ];
          requires = [ "docker-aurral-flows.service" "docker-slskd-aurral.service" ];
          partOf = [ "docker-aurral-flows.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = provision;
            ExecStopPost = "${pkgs.coreutils}/bin/rm -f /run/aurral-client/ready";
            TimeoutStartSec = 420;
            UMask = "0077";
          };
        };
      };
    };
}
