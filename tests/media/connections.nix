{ pkgs, agenix, media-storage, holyarrs, jackett, media-connections, decypharr ? null }:
let
  actual = decypharr != null;
  credential = pkgs.runCommand "acquisition-test-credential" { nativeBuildInputs = [ pkgs.age ]; } ''
    mkdir -p "$out"
    age-keygen -o "$out/identity" 2>/dev/null
    echo '{"real_debrid_api_key":"not-a-real-debrid-key"}' |
      age --encrypt --recipient "$(age-keygen -y "$out/identity")" --output "$out/credential.age"
  '';
  fixture = pkgs.writeText "qbit-connection-fixture.py" ''
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    import json
    from pathlib import Path
    import urllib.parse

    root = Path('/var/lib/decypharr')
    root.mkdir(mode=0o700, exist_ok=True)
    auth = root / 'auth.json'
    auth.write_text(json.dumps({'token_only': True, 'api_token': 'fixture-token'}))
    auth.chmod(0o600)

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass
        def reply(self, status, body, cookie=False):
            self.send_response(status)
            if cookie:
                self.send_header('Set-Cookie', 'SID=fixture; Path=/')
            self.end_headers()
            self.wfile.write(body.encode())
        def do_POST(self):
            body = urllib.parse.parse_qs(self.rfile.read(int(self.headers.get('Content-Length', '0'))).decode())
            if self.path == '/api/v2/auth/login' and body == {'username': ['media'], 'password': ['fixture-token']}:
                self.reply(200, 'Ok.', True)
            else:
                self.reply(403, 'Forbidden')
        def do_GET(self):
            if 'SID=fixture' not in self.headers.get('Cookie', ""):
                self.reply(403, 'Forbidden')
            elif Path('/run/qbit-fixture-failed').exists():
                self.reply(503, 'Unavailable')
            elif self.path.startswith('/api/v2/app/version'):
                self.reply(200, 'v4.3.9')
            elif self.path.startswith('/api/v2/torrents/categories'):
                self.reply(200, json.dumps({name: {'name': name, 'savePath': '/data/symlinks'} for name in ['holyarrs-movies', 'holyarrs-tv', 'holyarrs-music']}))
            else:
                self.reply(200, '[]')

    ThreadingHTTPServer(('127.0.0.1', 8282), Handler).serve_forever()
  '';
  probe = pkgs.writeText "media-connections-probe.py" ''
    import json
    from pathlib import Path
    import subprocess
    import urllib.request

    root = Path('/var/lib/holyarrs/provision')
    key = json.loads((root / 'api-key.json').read_text())['key']
    def get(path):
        request = urllib.request.Request('http://127.0.0.1:6263/api/v1/' + path, headers={'X-Api-Key': key})
        return json.load(urllib.request.urlopen(request, timeout=5))
    folders = get('library-folders')['library_folders']
    assert len(folders) == 3 and {row['kind'] for row in folders} == {'movie', 'show', 'music'}
    assert all(row['health'] == 'ok' and not row['copies_expected'] for row in folders)
    sources = get('sources')['sources']
    assert len(sources) == 2 and {row['name'] for row in sources} == {'nixos-knaben', 'nixos-thepiratebay'}
    assert all(row['categories']['music'] == [3000] and row['allow_local_network'] for row in sources)
    downloaders = get('downloaders')['downloaders']
    assert len(downloaders) == 1 and downloaders[0]['category_music'] == 'holyarrs-music'
    assert downloaders[0]['username'] == 'media'
    assert not downloaders[0]['clear_finished']
    assert (root / 'connections.json').stat().st_mode & 0o777 == 0o600
    logs = subprocess.check_output(['journalctl', '-u', 'media-connections', '-u', 'docker-holyarrs', '-u', 'jackett', '--no-pager', '-o', 'cat'], text=True)
    secret_values = [key, json.loads((root / 'owner.json').read_text())['password']]
    jackett = json.loads(Path('/var/lib/jackett/.config/Jackett/provision-auth.json').read_text())
    secret_values.extend([jackett['APIKey'], jackett['admin_password']])
    assert all(value not in logs for value in secret_values)
    identities = {name: [row['id'] for row in rows] for name, rows in [('folders', folders), ('sources', sources), ('downloaders', downloaders)]}
    snapshot = root / 'test-identities.json'
    if snapshot.exists():
        assert json.loads(snapshot.read_text()) == identities
    else:
        snapshot.write_text(json.dumps(identities))
        snapshot.chmod(0o600)
  '';
in pkgs.testers.runNixOSTest {
  name = if actual then "media-acquisition" else "media-connections";
  nodes.machine = { lib, ... }: {
    imports = [ agenix.nixosModules.default media-storage holyarrs jackett media-connections ] ++ lib.optional actual decypharr;
    age.identityPaths = [ "${credential}/identity" ];
    age.secrets = lib.mkIf actual {
      media-real-debrid.file = lib.mkForce "${credential}/credential.age";
    };
    users.users.casper.isNormalUser = true;
    time.timeZone = "UTC";
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers = lib.mkIf actual {
      decypharr.extraOptions = [ "--add-host=api.real-debrid.com:127.0.0.2" ];
    };
    virtualisation.memorySize = 2048;
    virtualisation.diskSize = 8192;
    services.tailscale.interfaceName = "tailscale0";
    system.switch.enable = true;
    environment.systemPackages = [ pkgs.python3 ];
    systemd.services.docker-decypharr = lib.mkIf (!actual) {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.python3}/bin/python3 ${fixture}";
    };
  };
  testScript = ''
    machine.start(allow_reboot=True)
    machine.wait_until_succeeds("systemctl reset-failed media-connections.service; systemctl start media-connections.service; systemctl is-active media-connections.service", timeout=300)
    machine.succeed("python3 ${probe}")
    original = machine.succeed("sha256sum /var/lib/holyarrs/provision/connections.json")
    for _ in range(2):
        machine.succeed("/run/current-system/bin/switch-to-configuration test >&2")
        machine.succeed("systemctl restart docker-holyarrs.service")
        machine.wait_for_unit("media-connections.service")
        machine.succeed("python3 ${probe}")
        assert machine.succeed("sha256sum /var/lib/holyarrs/provision/connections.json") == original
  '' + pkgs.lib.optionalString (!actual) ''
    machine.succeed("touch /run/qbit-fixture-failed")
    machine.fail("systemctl restart media-connections.service")
    machine.succeed("rm /run/qbit-fixture-failed; systemctl reset-failed media-connections; systemctl start media-connections")
    machine.succeed("python3 ${probe}")
    assert machine.succeed("sha256sum /var/lib/holyarrs/provision/connections.json") == original
  '' + pkgs.lib.optionalString actual ''
    machine.succeed("mountpoint -q /data/debrid")
    machine.succeed("runuser -u media -- test -r /data/debrid")
    machine.succeed("docker exec --user 2000:2000 decypharr test -r /data/debrid")
    machine.succeed("docker exec holyarrs /holyarrs doctor > /run/doctor.txt || true")
    machine.succeed("grep -E 'OK +(movie|show|music) library /data/media' /run/doctor.txt")
    machine.succeed("grep -E 'OK +downloads /data/symlinks' /run/doctor.txt")
    machine.succeed("! grep -E 'FAIL +(movie|show|music) library|FAIL +downloads ' /run/doctor.txt")
    machine.succeed("systemctl restart docker-decypharr")
    machine.wait_for_unit("media-connections.service")
    machine.succeed("mountpoint -q /data/debrid")
    machine.succeed("runuser -u media -- test -r /data/debrid")
    machine.succeed("python3 ${probe}")
    assert machine.succeed("sha256sum /var/lib/holyarrs/provision/connections.json") == original
    machine.succeed("! journalctl -u docker-decypharr --no-pager | grep -F 'Participating in hearsay network'")
    machine.reboot()
    machine.wait_for_unit("media-connections.service")
    machine.succeed("mountpoint -q /data/debrid")
    machine.succeed("runuser -u media -- test -r /data/debrid")
    machine.succeed("docker exec --user 2000:2000 decypharr test -r /data/debrid")
    machine.succeed("python3 ${probe}")
    assert machine.succeed("sha256sum /var/lib/holyarrs/provision/connections.json") == original
    machine.succeed("docker exec holyarrs /holyarrs doctor > /run/doctor.txt || true")
    machine.succeed("grep -E 'OK +(movie|show|music) library /data/media' /run/doctor.txt")
    machine.succeed("! grep -E 'FAIL +(movie|show|music) library|FAIL +downloads ' /run/doctor.txt")
  '';
}
