{ pkgs, agenix, media-storage, holyarrs, jackett, decypharr, jellyfin, soundspan, postgres, media-connections, media-backup }:
let
  credential = pkgs.runCommand "backup-coverage-credential" { nativeBuildInputs = [ pkgs.age ]; } ''
    mkdir -p "$out"
    age-keygen -o "$out/identity" 2>/dev/null
    echo '{"real_debrid_api_key":"not-a-real-debrid-key"}' |
      age --encrypt --recipient "$(age-keygen -y "$out/identity")" --output "$out/credential.age"
    echo 'not-a-real-backup-password' |
      age --encrypt --recipient "$(age-keygen -y "$out/identity")" --output "$out/backup-password.age"
  '';
in
pkgs.testers.runNixOSTest {
  name = "backup-coverage";
  nodes.machine = { lib, ... }: {
    imports = [ agenix.nixosModules.default media-storage holyarrs jackett decypharr jellyfin soundspan postgres media-connections media-backup ];
    virtualisation.oci-containers.containers.decypharr.extraOptions = [ "--add-host=api.real-debrid.com:127.0.0.2" ];
    age.identityPaths = [ "${credential}/identity" ];
    age.secrets.media-real-debrid.file = lib.mkForce "${credential}/credential.age";
    age.secrets.media-backup-password.file = lib.mkForce "${credential}/backup-password.age";
    security.acme.acceptTerms = true;
    users.users.casper = {
      isNormalUser = true;
      group = "users";
    };
    time.timeZone = "UTC";
    system.switch.enable = true;
    virtualisation.oci-containers.backend = "docker";
    virtualisation.memorySize = 4096;
    virtualisation.diskSize = 12288;
    systemd.services.nginx.wantedBy = lib.mkForce [ ];
    systemd.services.media-state-backup.wantedBy = lib.mkForce [ ];
    systemd.timers.media-state-backup.wantedBy = lib.mkForce [ ];
    environment.systemPackages = [ pkgs.python3 ];
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("media-connections.service")
    machine.wait_until_succeeds("systemctl is-active jellyfin-media-provision.service")
    machine.wait_until_succeeds("systemctl is-active soundspan-provision.service")
    machine.succeed("python3 ${./jellyfin-probe.py}")
    machine.succeed("python3 ${./soundspan-probe.py}")
    original = machine.succeed("sha256sum /var/lib/jellyfin/provision/admin.json")

    machine.succeed("systemctl start media-state-backup.service")
    machine.wait_for_unit("media-connections.service")
    machine.succeed("systemctl start jellyfin-media-provision.service soundspan-provision.service")
    machine.wait_until_succeeds("systemctl is-active jellyfin-media-provision.service")
    machine.wait_until_succeeds("systemctl is-active soundspan-provision.service")
    machine.succeed("test -s /var/backups/media/soundspan-dump/soundspan.dump")

    machine.succeed("systemctl stop docker-decypharr.service docker-holyarrs.service jackett.service jellyfin.service soundspan-backend.service")
    machine.succeed("rm -rf /var/lib/decypharr /var/lib/holyarrs /var/lib/jackett /var/lib/jellyfin /var/backups/media/soundspan-dump")
    machine.succeed("systemctl start media-state-restore.service")
    machine.succeed("systemctl start media-state-install.service")
    machine.succeed("test -f /var/lib/decypharr/config.json")
    machine.succeed("test -f /var/lib/decypharr/auth.json")
    machine.succeed("test -f /var/lib/holyarrs/holyarrs.key")
    machine.succeed("test -f /var/lib/jellyfin/provision/admin.json")
    machine.succeed("test -s /var/backups/media/soundspan-dump/soundspan.dump")
    machine.succeed("test \"$(stat -c %U:%G /var/lib/holyarrs)\" = media:media")
    machine.succeed("test \"$(stat -c %U:%G /var/lib/jellyfin)\" = jellyfin:jellyfin")
    machine.succeed("test \"$(stat -c %U:%G /var/lib/jackett)\" = jackett:jackett")
    machine.succeed("test \"$(stat -c %U:%G /var/backups/media/soundspan-dump)\" = postgres:postgres")
    machine.fail("test -e /var/lib/media-restore/latest")
    machine.fail("systemctl start media-state-install.service")

    machine.succeed("systemctl start docker-decypharr.service docker-holyarrs.service jackett.service jellyfin.service")
    machine.succeed("systemctl start jellyfin-media-provision.service")
    machine.succeed("systemctl reset-failed media-connections.service || true; systemctl start media-connections.service")
    machine.wait_for_unit("media-connections.service")
    machine.wait_until_succeeds("systemctl is-active jellyfin-media-provision.service")
    machine.succeed("python3 ${./jellyfin-probe.py}")
    assert machine.succeed("sha256sum /var/lib/jellyfin/provision/admin.json") == original
  '';
}
