{ pkgs, agenix, media-storage, decypharr, media-backup }:
let
  fixture = pkgs.runCommand "decypharr-test-credentials" {
    nativeBuildInputs = [ pkgs.age ];
  } ''
    mkdir -p "$out"
    age-keygen -o "$out/identity" 2>/dev/null
    echo '{"real_debrid_api_key":"not-a-real-debrid-key"}' |
      age --encrypt --recipient "$(age-keygen -y "$out/identity")" --output "$out/credential.age"
    echo 'not-a-real-backup-password' |
      age --encrypt --recipient "$(age-keygen -y "$out/identity")" --output "$out/backup-password.age"
  '';
  restic = pkgs.writeShellScriptBin "restic" ''
    if [[ "$1" == backup ]]; then
      test "$(systemctl is-active docker-decypharr)" = inactive || exit 1
      test "$(systemctl is-active docker-holyarrs)" = inactive || exit 1
      test "$(systemctl is-active jackett)" = inactive || exit 1
      if [[ -e /run/fail-media-backup ]]; then
        exit 1
      fi
      if [[ -e /run/partial-media-backup ]]; then
        ${pkgs.restic}/bin/restic "$@"
        exit 3
      fi
      if [[ -e /run/interrupt-media-backup ]]; then
        touch /run/media-backup-quiesced
        sleep infinity
      fi
    fi
    exec ${pkgs.restic}/bin/restic "$@"
  '';
  container = pkgs.writeText "decypharr-container-fixture.py" ''
    import json
    import time
    from pathlib import Path

    state = Path('/var/lib/decypharr')
    config = json.loads((state / 'config.json').read_text())
    auth = json.loads((state / 'auth.json').read_text())
    assert config['debrids'][0]['api_key'] == 'not-a-real-debrid-key'
    assert config['categories'] == ['holyarrs-movies', 'holyarrs-tv', 'holyarrs-music']
    assert config['mount']['type'] == 'dfs'
    assert config['default_download_action'] == 'symlink'
    assert config['hearsay'] == {'disabled': True, 'participate': False, 'publish': False}
    assert auth['token_only'] is True
    assert auth['api_token']
    for name in ['config.json', 'auth.json']:
        info = (state / name).stat()
        assert info.st_mode & 0o777 == 0o600
        assert info.st_uid == 2000
    assert not Path('/data/debrid/__all__').exists()
    Path('/run/decypharr-fixture-started').touch()
    while True:
        time.sleep(60)
  '';
in
pkgs.testers.runNixOSTest {
  name = "decypharr-provision";
  nodes.machine = { lib, ... }: {
    imports = [ agenix.nixosModules.default media-storage decypharr media-backup ];
    time.timeZone = "UTC";
    system.switch.enable = true;
    users.users.casper = {
      isNormalUser = true;
      group = "users";
    };
    users.groups.jackett = { };
    users.users.jackett = {
      isSystemUser = true;
      group = "jackett";
    };
    age.identityPaths = [ "${fixture}/identity" ];
    age.secrets.media-real-debrid.file = lib.mkForce "${fixture}/credential.age";
    age.secrets.media-backup-password.file = lib.mkForce "${fixture}/backup-password.age";
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.decypharr.autoStart = false;
    systemd.services.docker-decypharr.serviceConfig.ExecStart =
      lib.mkForce "${pkgs.python3}/bin/python3 ${container}";
    systemd.services.docker-decypharr.serviceConfig.ExecStartPost = lib.mkForce [];
    systemd.services.docker-holyarrs.serviceConfig = {
      ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
    };
    systemd.services.jackett.serviceConfig = {
      ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
    };
    systemd.services.media-state-backup.path = lib.mkBefore [ restic ];
    systemd.timers.media-state-backup.wantedBy = lib.mkForce [];
    environment.systemPackages = [ pkgs.restic ];
    virtualisation.memorySize = 1024;
    networking.firewall.enable = false;
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("test -s /run/agenix/media-real-debrid")
    machine.succeed('test "$(stat -Lc %a /run/agenix/media-real-debrid)" = 400')
    machine.succeed("systemctl start docker-decypharr")
    machine.wait_for_file("/run/decypharr-fixture-started")
    first = machine.succeed("sha256sum /var/lib/decypharr/config.json /var/lib/decypharr/auth.json")
    machine.succeed("/run/current-system/bin/switch-to-configuration test")
    machine.succeed("systemctl restart docker-decypharr")
    machine.wait_for_unit("docker-decypharr.service")
    assert first == machine.succeed("sha256sum /var/lib/decypharr/config.json /var/lib/decypharr/auth.json")
    machine.succeed("/run/current-system/bin/switch-to-configuration test")
    machine.succeed("systemctl restart docker-decypharr")
    machine.wait_for_unit("docker-decypharr.service")
    assert first == machine.succeed("sha256sum /var/lib/decypharr/config.json /var/lib/decypharr/auth.json")
    machine.succeed("install -d -m 700 /var/lib/holyarrs /var/lib/jackett")
    machine.succeed("umask 077; echo test-holyarrs-master-key > /var/lib/holyarrs/holyarrs.key; echo test-library-database > /var/lib/holyarrs/library.db")
    machine.succeed("systemctl start docker-holyarrs jackett")
    machine.succeed("systemctl start media-state-backup")
    for unit in ["docker-decypharr", "docker-holyarrs", "jackett"]:
        machine.wait_for_unit(unit + ".service")
    assert first == machine.succeed("sha256sum /var/lib/decypharr/config.json /var/lib/decypharr/auth.json")
    machine.succeed('test "$(stat -c %a /var/backups/media/restic)" = 700')
    machine.succeed("test ! -e /run/media-state-backup/active-units.json")
    machine.succeed("systemctl start media-state-restore")
    restored = machine.succeed("sha256sum /var/lib/media-restore/latest/var/lib/decypharr/config.json /var/lib/media-restore/latest/var/lib/decypharr/auth.json")
    assert first == restored.replace("/var/lib/media-restore/latest", "")
    machine.succeed("cmp /var/lib/holyarrs/holyarrs.key /var/lib/media-restore/latest/var/lib/holyarrs/holyarrs.key")
    machine.succeed('test "$(stat -c %a /var/lib/media-restore)" = 700')
    machine.succeed('test "$(stat -c %a /var/lib/media-restore/latest/var/lib/decypharr/auth.json)" = 600')
    machine.fail("systemctl start media-state-restore")
    machine.succeed("systemctl stop jackett; systemctl start media-state-backup")
    machine.fail("systemctl is-active jackett")
    machine.succeed("systemctl start jackett")
    machine.succeed("touch /run/fail-media-backup")
    machine.fail("systemctl start media-state-backup")
    for unit in ["docker-decypharr", "docker-holyarrs", "jackett"]:
        machine.wait_for_unit(unit + ".service")
    machine.succeed("rm /run/fail-media-backup")
    snapshots = "RESTIC_PASSWORD_FILE=/run/agenix/media-backup-password RESTIC_REPOSITORY=/var/backups/media/restic restic snapshots --json --tag media-state-v1"
    accepted_before = machine.succeed(snapshots)
    machine.succeed("touch /run/partial-media-backup")
    machine.fail("systemctl start media-state-backup")
    assert accepted_before == machine.succeed(snapshots)
    for unit in ["docker-decypharr", "docker-holyarrs", "jackett"]:
        machine.wait_for_unit(unit + ".service")
    machine.succeed("rm /run/partial-media-backup; touch /run/interrupt-media-backup")
    machine.succeed("systemctl start --no-block media-state-backup")
    machine.wait_for_file("/run/media-backup-quiesced")
    machine.succeed("systemctl stop media-state-backup")
    for unit in ["docker-decypharr", "docker-holyarrs", "jackett"]:
        machine.wait_for_unit(unit + ".service")
    machine.succeed("rm /run/interrupt-media-backup")
    machine.succeed("mv /run/agenix/media-backup-password /run/agenix/media-backup-password.saved; umask 077; echo wrong-backup-password > /run/agenix/media-backup-password")
    before = machine.succeed("systemctl show docker-decypharr -p InvocationID --value")
    machine.fail("systemctl start media-state-backup")
    assert before == machine.succeed("systemctl show docker-decypharr -p InvocationID --value")
    machine.succeed("mv /run/agenix/media-backup-password.saved /run/agenix/media-backup-password")
    machine.fail("grep -r -a -l -E 'not-a-real-debrid-key|test-holyarrs-master-key|not-a-real-backup-password' /var/backups/media/restic")
    backup_logs = machine.succeed("journalctl -u media-state-backup -u media-state-restore --no-pager")
    for value in ["not-a-real-debrid-key", "test-holyarrs-master-key", "not-a-real-backup-password", "wrong-backup-password"]:
        assert value not in backup_logs
    machine.succeed("systemctl stop docker-decypharr; rm /run/decypharr-fixture-started")
    machine.succeed("mv /run/agenix/media-real-debrid /run/agenix/media-real-debrid.saved")
    machine.succeed("systemctl reset-failed")
    machine.fail("systemctl start docker-decypharr")
    machine.wait_until_succeeds("test $(systemctl show docker-decypharr -p Result --value) = start-limit-hit", timeout=80)
    machine.fail("test -e /run/decypharr-fixture-started")
    machine.succeed("mv /run/agenix/media-real-debrid.saved /run/agenix/media-real-debrid")
    machine.succeed("systemctl reset-failed docker-decypharr; systemctl start docker-decypharr")
    machine.wait_for_file("/run/decypharr-fixture-started")
    machine.succeed("systemctl stop docker-decypharr; rm /run/decypharr-fixture-started")
    machine.succeed("echo invalid > /var/lib/decypharr/auth.json")
    machine.fail("systemctl start docker-decypharr")
    machine.fail("test -e /run/decypharr-fixture-started")
    machine.succeed("systemctl stop docker-decypharr")
    assert first.splitlines()[0] == machine.succeed("sha256sum /var/lib/decypharr/config.json").strip()
    logs = machine.succeed("journalctl -u docker-decypharr --no-pager")
    assert "not-a-real-debrid-key" not in logs
    machine.succeed("systemctl stop docker-decypharr docker-holyarrs jackett")
    machine.succeed("rm -rf /var/lib/decypharr /var/lib/holyarrs /var/lib/jackett")
    machine.succeed("systemctl start media-state-install")
    machine.succeed("test -f /var/lib/decypharr/config.json")
    machine.succeed('test "$(stat -c %U:%G /var/lib/holyarrs)" = media:media')
    machine.succeed('test "$(stat -c %U:%G /var/lib/jackett)" = jackett:jackett')
    machine.succeed("test ! -e /var/lib/media-restore/latest")
    machine.fail("systemctl start media-state-install")
  '';
}
