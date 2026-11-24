{ config, lib, ... }:
let
  backup = config.casper.backup;
in
{
  flake.modules.nixos.backup-restic-home = { config, lib, pkgs, ... }:
    let
      host = config.networking.hostName;
      registered = backup.clients ? ${host};
      client = backup.clients.${host} or { extraExcludes = [ ]; extraIncludes = [ ]; };
      secret = name: ../../../secrets + "/${name}";

      # Ordered restic patterns: absolute patterns also match everything below
      # them and the last matching pattern wins. An excluded directory is never
      # entered, so every re-included path needs its parents re-included first
      # (the ".local" -> ".local/share" -> ".local/share/<x>" ladder).
      browserJunk = [
        "cache2"
        "startupCache"
        "crashes"
        "minidumps"
        "datareporting"
        "saved-telemetry-pings"
      ];

      configDenylist = [
        "open-webui-desktop"
        "teams-for-linux"
        "Jan"
        "discord"
        "Electron"
        "Slack"
        "chromium"
        "google-chrome"
        "BraveSoftware"
        "Cypress"
        "clipse" # clipboard history, may contain passwords
        "elephant"
        "feishin"
        "coc"
        "whatsapp-electron"
        "vesktop"
      ];

      electronCaches = [
        "Cache"
        "Code Cache"
        "GPUCache"
        "DawnCache"
        "DawnGraphiteCache"
        "DawnWebGPUCache"
        "GrShaderCache"
        "ShaderCache"
        "Service Worker"
        "Crashpad"
        "CachedData"
        "blob_storage"
      ];

      localShareKeep = [
        "keyrings"
        "fish"
        "FreeCAD"
        "bambu-studio"
        "orca-slicer"
      ];

      dotfilesKeep = [
        ".*rc"
        ".*_history"
        ".gitconfig"
        ".git-credentials"
        ".netrc"
        ".profile"
      ];

      buildJunk = [
        "node_modules"
        ".venv"
        "__pycache__"
        ".terraform"
        ".terragrunt-cache"
        ".next"
        ".direnv"
        ".tox"
        ".gradle"
        ".serverless"
        ".aws-sam"
        "cdk.out"
      ];

      # Names that are only build output inside repositories.
      gitBuildOutput = [ "target" "dist" "build" "result" "vendor" "venv" ];

      excludes = lib.concatLists [
        # Visible entries are personal data, except these.
        [
          "/home/*/Downloads"
          "/home/*/go/pkg"
        ]

        # Hidden entries are application state, except this allowlist.
        [ "/home/*/.*" ]
        (map (d: "!/home/*/${d}") [ ".ssh" ".gnupg" ".docker" ".aws" ])
        [
          "/home/*/.aws/sso/cache"
          "/home/*/.aws/cli/cache"
        ]

        [
          "!/home/*/.mozilla"
          "!/home/*/.thunderbird"
          "/home/*/.mozilla/firefox/*/storage"
          "/home/*/.thunderbird/*/storage"
        ]
        (lib.concatMap (j: [ "/home/*/.mozilla/**/${j}" "/home/*/.thunderbird/**/${j}" ]) browserJunk)

        [ "!/home/*/.config" ]
        (map (d: "/home/*/.config/${d}") configDenylist)
        (map (d: "/home/*/.config/**/${d}") electronCaches)

        [
          "!/home/*/.local"
          "/home/*/.local/*"
          "!/home/*/.local/share"
          "/home/*/.local/share/*"
        ]
        (map (d: "!/home/*/.local/share/${d}") localShareKeep)

        (map (f: "!/home/*/${f}") dotfilesKeep)
        (map (p: "!${p}") client.extraIncludes)

        # Rebuildable output anywhere, also inside re-included directories.
        buildJunk
        (map (d: "/home/*/git/**/${d}") gitBuildOutput)

        client.extraExcludes
      ];

      excludeFile = pkgs.writeText "restic-home-excludes" (lib.concatLines excludes);

      job = { repository, timerConfig, extraOptions ? [ ] }: {
        inherit repository timerConfig extraOptions;
        passwordFile = config.age.secrets.restic-home-password.path;
        environmentFile = config.age.secrets.restic-home-env.path;
        # Fixed paths and tag keep one stable snapshot series per host.
        paths = [ "/home" ];
        initialize = true;
        inhibitsSleep = true;
        extraBackupArgs = [
          "--exclude-file=${excludeFile}"
          "--exclude-caches"
          "--one-file-system"
          "--tag home"
          "--retry-lock 30m"
        ];
        # No pruneOpts: clients cannot delete, kaito prunes.
      };

      lowPriority = {
        serviceConfig = {
          Nice = 19;
          IOSchedulingClass = "idle";
        };
        unitConfig.ConditionACPower = true;
      };
    in
    lib.mkMerge [
      {
        assertions = [{
          assertion = registered;
          message = "backup-restic-home is imported on ${host}, but the host is not registered: add `casper.backup.clients.${host} = { };` next to its Nebula node.";
        }];
      }

      (lib.mkIf registered {
        age.secrets = {
          restic-home-password.file = secret "restic-${host}-password.age";
          restic-home-env.file = secret "restic-${host}-env.age";
        };

        # Stable path for dry-run audits, see docs/backup-restore.md.
        environment.etc."restic/home-excludes".source = excludeFile;

        services.restic.backups = {
          home-kaito = job {
            repository = backup.repository.rest host;
            timerConfig = {
              OnCalendar = "hourly";
              Persistent = true;
              RandomizedDelaySec = "10m";
            };
          };

          home-s3 = job {
            repository = backup.repository.s3 host;
            extraOptions = [ "s3.region=${backup.s3.region}" ];
            timerConfig = {
              OnCalendar = "daily";
              Persistent = true;
              RandomizedDelaySec = "1h";
            };
          };
        };

        systemd.services.restic-backups-home-kaito = lowPriority;
        systemd.services.restic-backups-home-s3 = lowPriority;
      })
    ];
}
