{ pkgs, media-storage, holyarrs }:
let
  gate = pkgs.writeShellScript "holyarrs-test-gate" ''
    touch /run/holyarrs-test-waiting
    while ! test -e /run/holyarrs-test-continue; do
      sleep 0.1
    done
  '';
  probe = pkgs.writeText "holyarrs-test-probe.py" ''
    import json
    from pathlib import Path
    import subprocess
    import urllib.error
    import urllib.request

    root = Path('/var/lib/holyarrs/provision')
    stored = json.loads((root / 'api-key.json').read_text())
    owner = json.loads((root / 'owner.json').read_text())
    request = urllib.request.Request('http://127.0.0.1:6262/api/v1/auth/me', headers={'X-Api-Key': stored['key']})
    who = json.loads(urllib.request.urlopen(request, timeout=5).read())
    assert who['via'] == 'api_key' and who['name'] == owner['name'] and who['role'] == 'owner' and who['setup_open'] is False
    request = urllib.request.Request('http://127.0.0.1:6262/api/v1/auth/keys', headers={'X-Api-Key': stored['key']})
    keys = json.loads(urllib.request.urlopen(request, timeout=5).read())['keys']
    assert len(keys) == 1 and keys[0]['id'] == stored['id']
    try:
        urllib.request.urlopen('http://127.0.0.1:6262/api/v1/auth/me', timeout=5)
    except urllib.error.HTTPError as error:
        assert error.code == 401
    else:
        raise AssertionError('Unauthenticated proxy request accepted')
    for path in root.iterdir():
        assert path.stat().st_mode & 0o077 == 0
    logs = subprocess.check_output(['journalctl', '-u', 'docker-holyarrs.service', '--no-pager', '-o', 'cat'], text=True)
    assert owner['password'] not in logs and stored['key'] not in logs
  '';
in
pkgs.testers.runNixOSTest {
  name = "holyarrs-provision";
  nodes.machine = { lib, ... }: {
    imports = [ media-storage holyarrs ];
    users.users.casper.isNormalUser = true;
    time.timeZone = "UTC";
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.holyarrs.autoStart = false;
    virtualisation.memorySize = 2048;
    virtualisation.diskSize = 4096;
    virtualisation.vlans = [ 1 2 ];
    services.tailscale.interfaceName = "eth1";
    system.switch.enable = true;
    environment.systemPackages = [ pkgs.python3 pkgs.curl ];
    systemd.services.docker-holyarrs.serviceConfig.ExecStartPost = lib.mkBefore [ "${gate}" ];
  };
  nodes.client = { ... }: {
    virtualisation.vlans = [ 1 2 ];
    environment.systemPackages = [ pkgs.curl ];
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl start --no-block docker-holyarrs.service")
    machine.wait_until_succeeds("test -e /run/holyarrs-test-waiting")
    machine.wait_for_open_port(6263)
    machine.fail("ss -ltnH 'sport = :6262' | grep .")
    client.fail("curl --fail --max-time 2 http://machine:6262/api/v1/auth/state")
    client.fail("curl --fail --max-time 2 http://machine:6263/api/v1/auth/state")
    machine.succeed("touch /run/holyarrs-test-continue")
    machine.wait_for_unit("docker-holyarrs.service")
    machine.wait_for_open_port(6262)
    machine.succeed("python3 ${probe}")
    client.succeed("curl --fail --max-time 5 http://machine:6262/api/v1/auth/state | grep -q '\"needs_setup\":false'")
    untrusted = machine.succeed("ip -4 -o addr show dev eth2 | awk '{print $4}' | cut -d/ -f1").strip()
    client.fail(f"curl --fail --max-time 2 http://{untrusted}:6262/api/v1/auth/state")
    machine.succeed("systemctl reload firewall.service")
    client.succeed("curl --fail --max-time 5 http://machine:6262/api/v1/auth/state > /dev/null")
    client.fail(f"curl --fail --max-time 2 http://{untrusted}:6262/api/v1/auth/state")
    original = machine.succeed("sha256sum /var/lib/holyarrs/provision/{owner,api-key}.json")
    for _ in range(2):
        machine.succeed("/run/current-system/bin/switch-to-configuration test >&2")
        machine.succeed("systemctl restart docker-holyarrs.service")
        machine.wait_for_open_port(6262)
        machine.succeed("python3 ${probe}")
        assert machine.succeed("sha256sum /var/lib/holyarrs/provision/{owner,api-key}.json") == original
    machine.succeed("systemctl stop docker-holyarrs.service")
    machine.fail("ss -ltnH 'sport = :6262' | grep .")
    machine.succeed("cp /var/lib/holyarrs/provision/owner.json /root/owner-copy; echo '{}' > /var/lib/holyarrs/provision/owner.json")
    machine.fail("systemctl start docker-holyarrs.service")
    machine.fail("ss -ltnH 'sport = :6262' | grep .")
    client.fail("curl --fail --max-time 2 http://machine:6262/api/v1/auth/state")
    machine.succeed("systemctl stop docker-holyarrs.service; cp /root/owner-copy /var/lib/holyarrs/provision/owner.json; systemctl reset-failed; systemctl start docker-holyarrs.service")
    machine.wait_for_open_port(6262)
    machine.succeed("python3 ${probe}")
    machine.succeed("docker exec holyarrs /holyarrs -healthcheck")
    client.fail("curl --fail --max-time 2 http://machine:6263/api/v1/auth/state")
  '';
}
