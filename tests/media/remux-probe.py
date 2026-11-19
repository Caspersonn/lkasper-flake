import json
from pathlib import Path
import subprocess
import sys

sys.path.insert(0, sys.argv[1])
from decypharr import ProvisionError, read_object
from remux import Client

seed = read_object(Path('/var/lib/remux-provision/admin.json'), protected=True)
client = Client('remux-main')
assert client.call('GET', '/system/info/public')['StartupWizardCompleted'] is True
try:
    client.call('GET', '/system/configuration')
except ProvisionError:
    pass
else:
    raise AssertionError('anonymous configuration access was accepted')
auth = client.call('POST', '/users/authenticatebyname', {'Username': seed['name'], 'Pw': seed['password']})
assert auth['User']['Policy']['IsAdministrator'] is True
client.token = auth['AccessToken']
config = client.call('GET', '/system/configuration')
assert config['P2pEnabled'] is False
assert config['DefaultWebClient'] == 'remux'
assert config['ServerName'] == 'kaito'
container = json.loads(subprocess.check_output(['docker', 'inspect', 'remux-main']))[0]
assert container['HostConfig']['NetworkMode'] != 'none'
assert '/data/cache' in container['HostConfig']['Tmpfs']
assert '/data/transcode_sessions' in container['HostConfig']['Tmpfs']
assert subprocess.run(['docker', 'inspect', 'remux-bootstrap'], capture_output=True).returncode != 0
assert not Path('/run/remux-client/ready').exists()
assert Path('/var/lib/remux-provision/admin.json').stat().st_mode & 0o777 == 0o600
