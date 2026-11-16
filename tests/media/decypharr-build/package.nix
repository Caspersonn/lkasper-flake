{ pkgs, patch }:
let
  upstream = pkgs.fetchFromGitHub {
    owner = "sirrobot01";
    repo = "decypharr";
    rev = "d6f8df094dfe58eff16932f64c5e13bc24ae1d3a";
    hash = "sha256-SXEGn5pWBxRPVvGHt2pHCMFnikj+eGKfi9guXcEZDvI=";
  };
  patched = pkgs.runCommand "decypharr-patched" {} ''
    cp -r ${upstream} tree
    chmod -R u+w tree
    patch -p1 -d tree < ${patch} >/dev/null
    mv tree "$out"
  '';
  vendorHash = "sha256-Bmxe/vl1HfXSOm5qypDfAH35DIiS+1vnnZxCoQj+zNE=";
  version = "2.7.2";
  binary = pkgs.buildGoModule {
    pname = "decypharr";
    inherit version;
    src = patched;
    inherit vendorHash;
    env.CGO_ENABLED = "1";
    env.NIX_CFLAGS_COMPILE = "-I${pkgs.fuse3.dev}/include/fuse3 -DFUSE_USE_VERSION=31";
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.fuse3 ];
    ldflags = [ "-s" "-w" "-X github.com/sirrobot01/decypharr/pkg/version.Version=${version}" ];
  };
  healthcheck = binary;
  entrypoint = pkgs.writeScript "decypharr-entrypoint" ''
    #!${pkgs.runtimeShell}
    set -e
    umask "$UMASK"
    mkdir -p /app/logs /app/cache
    touch /app/logs/decypharr.log
    chown "$PUID":"$PGID" /app/logs /app/cache /app/logs/decypharr.log
    chmod u+s /bin/fusermount3 2>/dev/null || true
    if [ "$(id -u)" != "0" ]; then
      exec "$@"
    fi
    exec ${pkgs.util-linux}/bin/setpriv --reuid="$PUID" --regid="$PGID" --clear-groups -- env HOME=/app "$@"
  '';
  setuidFuse = pkgs.runCommand "fusermount3-suid" { } ''
    install -d -m 0755 "$out/bin" "$out/sbin"
    cp ${pkgs.fuse3}/bin/fusermount3 "$out/bin/fusermount3"
    ln -s /bin/fusermount3 "$out/sbin/fusermount3"
  '';
in pkgs.dockerTools.buildImage {
  name = "decypharr";
  tag = "2.7.2-holyarrs";
  copyToRoot = pkgs.buildEnv {
    name = "decypharr-root";
    ignoreCollisions = true;
    paths = [
      setuidFuse
      binary healthcheck pkgs.rclone pkgs.cacert pkgs.tzdata
      pkgs.libgcc pkgs.stdenv.cc.cc.lib pkgs.fuse3 pkgs.util-linux pkgs.coreutils pkgs.runtimeShellPackage
      (pkgs.writeTextFile {
        name = "fuse-conf";
        destination = "/etc/fuse.conf";
        text = "user_allow_other\n";
      })
      (pkgs.writeTextFile {
        name = "passwd";
        destination = "/etc/passwd";
        text = "root:x:0:0:root:/root:/bin/sh\nappuser:x:1000:1000::/app:/bin/sh\nmedia:x:2000:2000::/data:/bin/sh\n";
      })
      (pkgs.writeTextFile {
        name = "group";
        destination = "/etc/group";
        text = "root:x:0:\nappuser:x:1000:\nmedia:x:2000:\n";
      })
    ];
  };
  extraCommands = ''
    mkdir -p usr/bin
    ln -s /bin/decypharr usr/bin/decypharr
    ln -s /bin/healthcheck usr/bin/healthcheck
  '';
  config = {
    Env = [ "PUID=1000" "PGID=1000" "UMASK=002" "LOG_PATH=/app/logs" "GO_LOG=client-unlock-handlers.go=err" ];
    Cmd = [ "/usr/bin/decypharr" "--config" "/app" ];
    Entrypoint = [ entrypoint ];
    Healthcheck = {
      Test = [ "CMD" "/usr/bin/healthcheck" "--config" "/app" ];
      Interval = 10000000000;
      Timeout = 3000000000;
      Retries = 10;
      StartPeriod = 30000000000;
    };
  };
}
