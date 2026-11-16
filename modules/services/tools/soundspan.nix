{ inputs, ... }: {
  flake.modules.nixos.soundspan = { config, lib, pkgs, ... }:
    let
      upstream = inputs.soundspan;
      patched = pkgs.runCommand "soundspan-holyarrs-source.tar.gz" { } ''
    cp -r ${upstream} tree
    chmod -R u+w tree
    patch -p1 -d tree < ${./soundspan/holyarrs-provider.patch} >/dev/null
    tar -czf "$out" -C tree .
  '';
  backendPkg = pkgs.buildNpmPackage {
    pname = "soundspan-backend";
    version = "2.7.2";
    src = patched;
    sourceRoot = "backend";
    npmDepsHash = "sha256-mBk6hQB+D5Jq67mL8OY2EfoE3mKbfUhu6uoBmiexlGM=";
    nodejs = pkgs.nodejs;
    preBuild = ''
      export PRISMA_SCHEMA_ENGINE_BINARY=${pkgs.prisma-engines}/bin/schema-engine
      export PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
      npx prisma generate
    '';
    postInstall = ''
      mkdir -p "$out/lib/node_modules/packages"
      cp -r ../packages/media-metadata-contract "$out/lib/node_modules/packages/"
      cp -r dist "$out/lib/node_modules/soundspan-backend/dist"
    '';
  };
  frontendPkg = pkgs.buildNpmPackage {
    pname = "soundspan-frontend";
    version = "2.7.2";
    src = patched;
    sourceRoot = "frontend";
    npmDepsFetcherVersion = 2;
    npmDepsHash = "sha256-4kWWeAz3m0tHtmzgfnuEfnhEeIs1JmFNwrsJdnSSfQk=";
    nodejs = pkgs.nodejs;
    env.NEXT_TELEMETRY_DISABLED = "1";
    postInstall = ''
      mkdir -p "$out/lib/node_modules/packages"
      cp -r ../packages/media-metadata-contract "$out/lib/node_modules/packages/"
      cp -r .next "$out/lib/node_modules/soundspan-frontend/.next"
    '';
  };
  backendDir = "${backendPkg}/lib/node_modules/soundspan-backend";
  frontendDir = "${frontendPkg}/lib/node_modules/soundspan-frontend";
  stateDir = "/var/lib/soundspan/provision";
  runtimeEnv = pkgs.writeText "soundspan-runtime.env" ''
    ALLOWED_ORIGINS=https://soundspan.inspiravita.com,http://127.0.0.1:3030
    TRANSCODE_CACHE_PATH=/var/cache/soundspan/transcodes
  '';
  scripts = pkgs.runCommand "soundspan-provision" { } ''
    mkdir -p "$out"
    cp ${./media-provision/soundspan.py} "$out/soundspan.py"
    cp ${./media-provision/decypharr.py} "$out/decypharr.py"
  '';
  generateEnv = pkgs.writeShellApplication {
    name = "soundspan-generate-env";
    runtimeInputs = [ pkgs.coreutils pkgs.openssl ];
    text = ''
      umask 077
      install -d -m 0700 ${stateDir}
      envFile=${stateDir}/env
      if test ! -s "$envFile"; then
        {
          printf 'SESSION_SECRET=%s\n' "$(openssl rand -hex 32)"
          printf 'SETTINGS_ENCRYPTION_KEY=%s\n' "$(openssl rand -hex 32)"
          printf 'INTERNAL_API_SECRET=%s\n' "$(openssl rand -hex 32)"
        printf 'DATABASE_URL=postgres://postgres:postgres@127.0.0.1:5432/soundspan\n'
        printf 'REDIS_URL=redis://127.0.0.1:6379\n'
        printf 'PORT=3006\nNODE_ENV=production\n'
        printf 'MUSIC_PATH=/data/media/music\n'
        printf 'LOCAL_LOGIN_ENABLED=true\nBACKEND_PROCESS_ROLE=all\n'
        printf 'ALLOWED_ORIGINS=http://127.0.0.1:3030\n'
      } > "$envFile"
      fi
      chmod 0600 "$envFile"
    '';
  };
  migrate = pkgs.writeShellApplication {
    name = "soundspan-migrate";
    runtimeInputs = [ pkgs.coreutils pkgs.nodejs ];
    excludeShellChecks = [ "SC1091" ];
    text = ''
      cd ${backendDir}
      export PRISMA_SCHEMA_ENGINE_BINARY=${pkgs.prisma-engines}/bin/schema-engine
      export PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
      set -a
      . ${stateDir}/env
      set +a
      ${pkgs.coreutils}/bin/env DATABASE_URL="$DATABASE_URL" ./node_modules/.bin/prisma migrate deploy
    '';
  };
  provision = pkgs.writeShellApplication {
    name = "provision-soundspan";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      umask 077
      install -d -m 0700 ${stateDir}
      ${pkgs.python3}/bin/python3 -B ${scripts}/soundspan.py \
        --endpoint http://127.0.0.1:3006 \
        --state-dir ${stateDir} \
        --credentials /var/lib/holyarrs/provision/api-key.json
    '';
  };
in
{
  services.redis.servers.soundspan = {
    enable = true;
    port = 6379;
  };
  services.postgresql.ensureDatabases = [ "soundspan" ];

  users.users.soundspan = {
    isSystemUser = true;
    group = "soundspan";
    extraGroups = [ "media" ];
  };
  users.groups.soundspan = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/soundspan 0750 soundspan soundspan -"
    "d ${stateDir} 0700 soundspan soundspan -"
  ];

  systemd.services.soundspan-backend = {
    wantedBy = [ "multi-user.target" ];
    after = [ "postgresql.service" "redis-soundspan.service" ];
    wants = [ "postgresql.service" "redis-soundspan.service" ];
    restartTriggers = [ backendPkg generateEnv migrate ];
    path = [ pkgs.nodejs ];
    preStart = ''
      ${generateEnv}/bin/soundspan-generate-env
      ${migrate}/bin/soundspan-migrate
    '';
    serviceConfig = {
      Type = "exec";
      User = "soundspan";
      Group = "soundspan";
      EnvironmentFile = [ "-${stateDir}/env" runtimeEnv ]
        ++ lib.optionals (builtins.hasAttr "music-lastfm" (config.age.secrets or { })) [
          config.age.secrets.music-lastfm.path
        ];
      WorkingDirectory = backendDir;
      CacheDirectory = "soundspan";
      ExecStart = "${pkgs.nodejs}/bin/node dist/index.js";
      ExecStartPost = "${pkgs.writeShellScript "soundspan-wait" ''
        for _ in {1..90}; do
          if ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:3006/api/onboarding/status >/dev/null 2>&1; then
            exit 0
          fi
          sleep 1
        done
        exit 1
      ''}";
      Restart = "on-failure";
      RestartSec = 10;
      UMask = "0077";
    };
  };

  systemd.services.soundspan-frontend = {
    wantedBy = [ "multi-user.target" ];
    after = [ "soundspan-backend.service" ];
    requires = [ "soundspan-backend.service" ];
    partOf = [ "soundspan-backend.service" ];
    restartTriggers = [ frontendPkg ];
    environment = {
      BACKEND_URL = "http://127.0.0.1:3006";
      STREAMING_ENGINE_MODE = "native";
      PORT = "3030";
      NODE_ENV = "production";
    };
    serviceConfig = {
      Type = "exec";
      User = "soundspan";
      Group = "soundspan";
      WorkingDirectory = frontendDir;
      ExecStart = "${pkgs.nodejs}/bin/node server.js";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  systemd.services.soundspan-provision = {
    wantedBy = [ "multi-user.target" ];
    after = [ "soundspan-backend.service" "docker-holyarrs.service" ];
    requires = [ "soundspan-backend.service" ];
    restartTriggers = [ provision ];
    unitConfig = {
      StartLimitIntervalSec = 300;
      StartLimitBurst = 3;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 10;
      TimeoutStartSec = 420;
      UMask = "0077";
      EnvironmentFile = "-${stateDir}/env";
      ExecStart = lib.getExe provision;
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."soundspan.inspiravita.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3030";
        proxyWebsockets = true;
      };
    };
  };
  };
}
