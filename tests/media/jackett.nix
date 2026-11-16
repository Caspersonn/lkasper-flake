{ pkgs, jackett }:
let
  probe = pkgs.writeText "jackett-probe.py" ''
    import http.cookiejar
    import json
    from pathlib import Path
    import subprocess
    import urllib.parse
    import urllib.request
    import xml.etree.ElementTree as ET

    root = Path('/var/lib/jackett/.config/Jackett')
    seed = json.loads((root / 'provision-auth.json').read_text())
    base = 'http://127.0.0.1:9117'
    client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
    client.open(base + '/UI/Dashboard', urllib.parse.urlencode({'password': seed['admin_password']}).encode(), timeout=15).read()
    configured = json.loads(client.open(base + '/api/v2.0/indexers?configured=true', timeout=15).read())
    assert {item['id'] for item in configured} == {'knaben', 'thepiratebay'}
    config = json.loads(client.open(base + '/api/v2.0/indexers/thepiratebay/config', timeout=15).read())
    assert next(item['value'] for item in config if item['id'] == 'top100') == '100'
    for name in ('knaben', 'thepiratebay'):
        endpoint = base + '/api/v2.0/indexers/' + name + '/results/torznab/api?'
        query = urllib.parse.urlencode({'apikey': seed['APIKey'], 't': 'caps'})
        caps = ET.fromstring(urllib.request.urlopen(endpoint + query, timeout=15).read())
        assert caps.find('./searching/music-search').get('available') == 'yes'
        assert caps.find('./categories/category[@id="3000"]') is not None
        refused = ET.fromstring(urllib.request.urlopen(endpoint + 'apikey=invalid&t=caps', timeout=15).read())
        assert refused.tag == 'error' and refused.get('code') == '100'
    for path in root.rglob('*.json'):
        assert path.stat().st_mode & 0o077 == 0
    logs = subprocess.check_output(['journalctl', '-u', 'jackett.service', '--no-pager', '-o', 'cat'], text=True)
    assert seed['APIKey'] not in logs and seed['admin_password'] not in logs
  '';
in
pkgs.testers.runNixOSTest {
  name = "jackett-provision";
  nodes.machine = { ... }: {
    imports = [ jackett ];
    services.tailscale.interfaceName = "tailscale0";
    system.switch.enable = true;
    environment.systemPackages = [ pkgs.python3 ];
    virtualisation.memorySize = 1536;
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("jackett.service")
    machine.wait_for_open_port(9117)
    machine.succeed("python3 ${probe}")
    original = machine.succeed("sha256sum /var/lib/jackett/.config/Jackett/{ServerConfig,provision-auth}.json /var/lib/jackett/.config/Jackett/Indexers/{knaben,thepiratebay}.json")
    for _ in range(2):
        machine.succeed("/run/current-system/bin/switch-to-configuration test >&2")
        machine.succeed("systemctl restart jackett.service")
        machine.wait_for_open_port(9117)
        machine.succeed("python3 ${probe}")
        assert machine.succeed("sha256sum /var/lib/jackett/.config/Jackett/{ServerConfig,provision-auth}.json /var/lib/jackett/.config/Jackett/Indexers/{knaben,thepiratebay}.json") == original
    machine.succeed("systemctl stop jackett.service; cp /var/lib/jackett/.config/Jackett/provision-auth.json /root/auth-copy; echo '{}' > /var/lib/jackett/.config/Jackett/provision-auth.json")
    machine.fail("systemctl start jackett.service")
    machine.succeed("systemctl stop jackett.service; cp /root/auth-copy /var/lib/jackett/.config/Jackett/provision-auth.json; chown jackett:jackett /var/lib/jackett/.config/Jackett/provision-auth.json; systemctl reset-failed; systemctl start jackett.service")
    machine.wait_for_open_port(9117)
    machine.succeed("python3 ${probe}")
  '';
}
