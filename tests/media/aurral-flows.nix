{ pkgs, agenix, media-storage, aurral-flows, media-backup }:
let
  credential = pkgs.runCommand "aurral-recovery-credential" { nativeBuildInputs = [ pkgs.age ]; } ''
    mkdir -p "$out"
    age-keygen -o "$out/identity" 2>/dev/null
    echo 'aurral-vm-backup-fixture-password' |
      age --encrypt --recipient "$(age-keygen -y "$out/identity")" --output "$out/password.age"
  '';
  certificate = pkgs.runCommand "aurral-client-certificate" { nativeBuildInputs = [ pkgs.openssl ]; } ''
    mkdir -p "$out"
    openssl req -x509 -newkey rsa:2048 -nodes -days 2 -subj /CN=music.test \
      -addext subjectAltName=DNS:music.test -keyout "$out/key.pem" -out "$out/cert.pem" 2>/dev/null
  '';
in
pkgs.testers.runNixOSTest {
  name = "aurral-flows-provision";
  nodes.machine = { lib, ... }: {
    imports = [ agenix.nixosModules.default media-storage aurral-flows media-backup ];
    age.identityPaths = [ "${credential}/identity" ];
    age.secrets.media-backup-password.file = lib.mkForce "${credential}/password.age";
    systemd.timers.media-state-backup.wantedBy = lib.mkForce [ ];
    systemd.timers.aurral-staging-cleanup.wantedBy = lib.mkForce [ ];
    environment.etc.aurral-recovery-vm.text = "disposable recovery fixture";
    systemd.services = lib.genAttrs [ "docker-holyarrs" "docker-decypharr" "jackett" ] (name: {
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = "true";
    });
    users.users.jackett = { isSystemUser = true; group = "jackett"; };
    users.groups.jackett = { };
    services.aurralFlows.enable = true;
    services.aurralFlows.clientDomain = "music.test";
    services.nginx.virtualHosts."music.test" = {
      enableACME = lib.mkForce false;
      sslCertificate = "${certificate}/cert.pem";
      sslCertificateKey = "${certificate}/key.pem";
    };
    services.aurralFlows.minimumFreeBytes = 64 * 1024 * 1024;
    services.aurralFlows.temporaryBudgetBytes = 8 * 1024 * 1024;
    users.users.casper.isNormalUser = true;
    time.timeZone = "UTC";
    system.switch.enable = true;
    virtualisation.oci-containers.backend = "docker";
    virtualisation.memorySize = 4096;
    virtualisation.diskSize = 16384;
    environment.systemPackages = [ pkgs.python3 ];
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("aurral-flows-provision.service", timeout=600)
    machine.succeed("python3 ${./aurral-flows-probe.py}")
    machine.wait_for_unit("nginx.service")
    machine.succeed("curl --fail --silent --insecure --resolve music.test:443:127.0.0.1 https://music.test/api/health/bootstrap | python3 -c 'import json,sys; assert not json.load(sys.stdin)[\"onboardingRequired\"]'")
    machine.succeed("test $(curl --silent --insecure --resolve music.test:443:127.0.0.1 --output /dev/null --write-out '%{http_code}' https://music.test/api/settings) = 401")
    machine.succeed("systemctl stop aurral-flows-provision")
    machine.succeed("test $(curl --silent --insecure --resolve music.test:443:127.0.0.1 --output /dev/null --write-out '%{http_code}' https://music.test/api/health/bootstrap) = 503")
    machine.succeed("systemctl start aurral-flows-provision")
    machine.succeed("docker cp ${./aurral-quality-fixture.mjs} aurral-flows:/app/quality-fixture.mjs")
    machine.succeed("docker exec -e AURRAL_FIXTURE=1 aurral-flows node /app/quality-fixture.mjs", timeout=120)
    original = machine.succeed("sha256sum /var/lib/aurral-flows-provision/{admin,slskd,flows}.json")
    machine.succeed("/run/current-system/bin/switch-to-configuration test >&2")
    machine.succeed("systemctl restart aurral-flows-provision.service")
    machine.wait_for_unit("aurral-flows-provision.service")
    machine.succeed("python3 ${./aurral-flows-probe.py}")
    assert machine.succeed("sha256sum /var/lib/aurral-flows-provision/{admin,slskd,flows}.json") == original
    machine.succeed("docker cp ${./aurral-flow-fixture.mjs} aurral-flows:/app/retention-fixture.mjs")
    machine.succeed("docker exec -e AURRAL_FIXTURE=1 aurral-flows node /app/retention-fixture.mjs")
    machine.succeed("systemctl restart docker-aurral-flows aurral-flows-provision")
    machine.succeed("python3 ${./aurral-flows-probe.py}")
    machine.succeed("python3 ${./aurral-retention-probe.py} prepare", timeout=180)
    machine.succeed("mkdir -p /var/lib/decypharr /var/lib/holyarrs /var/lib/jackett; touch /var/lib/decypharr/config.json /var/lib/decypharr/auth.json /var/lib/holyarrs/holyarrs.key")
    machine.succeed("systemctl start docker-holyarrs jackett docker-decypharr")
    machine.succeed("systemctl start media-state-backup.service", timeout=300)
    machine.succeed("systemctl start media-state-restore.service", timeout=300)
    machine.succeed("AURRAL_VM_RECOVERY=1 python3 ${./aurral-backup-probe.py} verify")
    machine.fail("systemctl start media-state-install.service")
    machine.succeed("python3 ${./aurral-retention-probe.py} retain", timeout=180)
    machine.succeed("systemctl restart docker-slskd-aurral docker-aurral-flows")
    machine.succeed("systemctl restart aurral-flows-provision.service")
    machine.succeed("python3 ${./aurral-flows-probe.py}")
    machine.succeed("python3 ${./aurral-retention-probe.py} check", timeout=180)
    machine.succeed("systemctl stop aurral-capacity.timer")
    machine.succeed("dd if=/dev/zero of=/data/downloads/slskd/capacity-fixture bs=1M count=9 status=none")
    machine.succeed("systemctl start aurral-capacity.service")
    machine.fail("systemctl is-active --quiet docker-slskd-aurral.service")
    machine.succeed("systemctl is-active --quiet docker-aurral-flows.service")
    machine.succeed("python3 -c 'import json; s=json.load(open(\"/var/lib/aurral-flows-provision/capacity.json\")); assert s[\"paused\"] and s[\"reason\"] == \"temporary-budget\"'")
    machine.succeed("python3 ${./aurral-retention-probe.py} check", timeout=180)
    machine.succeed("rm /data/downloads/slskd/capacity-fixture")
    machine.succeed("systemctl start aurral-capacity.service")
    machine.wait_for_unit("docker-slskd-aurral.service")
    machine.succeed("python3 -c 'import json; assert not json.load(open(\"/var/lib/aurral-flows-provision/capacity.json\"))[\"paused\"]'")
    assert machine.succeed("sha256sum /var/lib/aurral-flows-provision/{admin,slskd,flows}.json") == original
    machine.succeed("AURRAL_VM_RECOVERY=1 python3 ${./aurral-backup-probe.py} isolate")
    machine.succeed("systemctl reset-failed media-state-install.service; systemctl start media-state-install.service")
    machine.succeed("test $(stat -c %U:%G /var/lib/aurral-flows-provision) = root:root; test $(stat -c %U:%G /data/music-aurral) = media:media")
    machine.succeed("systemctl start docker-slskd-aurral docker-aurral-flows aurral-flows-provision", timeout=300)
    machine.succeed("python3 ${./aurral-flows-probe.py}")
    machine.succeed("python3 ${./aurral-retention-probe.py} check", timeout=180)
    assert machine.succeed("sha256sum /var/lib/aurral-flows-provision/{admin,slskd,flows}.json") == original
    machine.succeed("docker cp ${./aurral-flow-fixture.mjs} aurral-flows:/app/saved-fixture.mjs")
    machine.succeed("docker exec -e AURRAL_FIXTURE=1 -e AURRAL_FIXTURE_KIND=saved aurral-flows node /app/saved-fixture.mjs")
    machine.succeed("systemctl restart docker-aurral-flows aurral-flows-provision")
    machine.succeed("python3 ${./aurral-saved-probe.py} retain", timeout=300)
    machine.succeed("systemctl restart docker-aurral-flows aurral-flows-provision")
    machine.succeed("python3 ${./aurral-saved-probe.py} check", timeout=180)
    machine.succeed("printf 'unreferenced but recent' > /data/downloads/slskd/cleanup-recent-fixture")
    machine.succeed("systemctl start aurral-staging-cleanup.service", timeout=600)
    machine.succeed("systemctl is-active --quiet docker-slskd-aurral docker-aurral-flows aurral-flows-provision")
    machine.succeed("python3 -c 'import json; s=json.load(open(\"/var/lib/aurral-flows-provision/cleanup.json\")); assert s[\"reason\"] in (\"complete\", \"application-references\", \"provider-references\"); assert not s.get(\"removedFiles\", 0)'")
    machine.succeed("test -f /data/downloads/slskd/cleanup-recent-fixture; test ! -e /var/lib/aurral-flows-provision/cleanup-active.json")
    machine.succeed("python3 ${./aurral-retention-probe.py} check", timeout=180)
    machine.succeed("python3 ${./aurral-saved-probe.py} check", timeout=180)
    machine.succeed("systemd-run --unit=aurral-test-lock --property=Type=exec ${pkgs.util-linux}/bin/flock /run/aurral-maintenance/lock ${pkgs.coreutils}/bin/sleep 120")
    machine.wait_until_fails("${pkgs.util-linux}/bin/flock -n /run/aurral-maintenance/lock ${pkgs.coreutils}/bin/true", timeout=30)
    machine.succeed("systemctl start aurral-capacity.service")
    machine.fail("systemctl start aurral-staging-cleanup.service")
    machine.fail("systemctl start media-state-backup.service")
    machine.succeed("systemctl is-active --quiet docker-slskd-aurral docker-aurral-flows aurral-flows-provision")
    machine.succeed("systemctl stop aurral-test-lock.service; systemctl reset-failed aurral-staging-cleanup media-state-backup")
    machine.succeed("test -f /data/downloads/slskd/cleanup-recent-fixture")
    assert machine.succeed("sha256sum /var/lib/aurral-flows-provision/{admin,slskd,flows}.json") == original
    machine.succeed("docker cp ${./aurral-job-fixture.mjs} aurral-flows:/app/job-fixture.mjs")
    machine.succeed("docker exec -e AURRAL_FIXTURE=1 aurral-flows node /app/job-fixture.mjs")
    machine.succeed("systemctl restart docker-aurral-flows aurral-flows-provision")
    machine.succeed("python3 ${./aurral-jobs-probe.py}", timeout=180)
  '';
}
