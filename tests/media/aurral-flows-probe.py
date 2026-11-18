import hashlib
import json
from pathlib import Path
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request


root = Path("/var/lib/aurral-flows-provision")
seed = json.loads((root / "admin.json").read_text())
credential = json.loads((root / "slskd.json").read_text())
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def call(port, path, body=None, headers=None):
    request = urllib.request.Request(
        f"http://127.0.0.1:{port}{path}",
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Content-Type": "application/json", **(headers or {})},
    )
    with opener.open(request, timeout=30) as response:
        data = response.read()
        return json.loads(data) if data else None


def denied(port, path, status):
    try:
        call(port, path)
    except urllib.error.HTTPError as error:
        assert error.code == status
    else:
        raise AssertionError("unauthenticated administration was accepted")


assert call(3002, "/api/health/bootstrap")["onboardingRequired"] is False
denied(3002, "/api/settings", 401)
denied(5032, "/api/v0/application", 401)
logged = call(3002, "/api/auth/login", seed)
assert logged["user"]["username"] == "casper"
assert logged["user"]["role"] == "admin"
auth = {"Authorization": "Bearer " + logged["token"]}
assert call(3002, "/api/playlists/worker/settings", headers=auth)["concurrency"] == 3
settings = call(3002, "/api/settings", headers=auth)
assert settings["downloadFolderPath"] == "/data/music-aurral"
assert settings["integrations"]["slskd"]["apiKey"] == credential["api_key"]
assert settings["security"]["localNetworkBypass"]["enabled"] is False
for source in ("lidarr", "ytdlp", "prowlarr", "nzbget", "sabnzbd", "tidarr", "deemix"):
    assert settings["integrations"][source]["enabled"] is False
journal = json.loads((root / "flows.json").read_text())["managed"]
assert len(journal) == 2
expected_ids = {entry["id"] for entry in journal.values()}
for attempt in range(30):
    flows = call(3002, "/api/playlists/status", headers=auth)["flows"]
    if expected_ids <= {flow["id"] for flow in flows}:
        break
    time.sleep(1)
else:
    raise AssertionError("managed flows did not become visible after provisioning")
for name, entry in journal.items():
    flow = next(flow for flow in flows if flow["id"] == entry["id"])
    assert flow["name"] == name
    assert flow["ownerUserId"] == logged["user"]["id"]
    assert flow["autoDownload"] is True
    assert flow["enabled"] is True
    assert flow["deepDive"] is False
    assert flow["scheduleDays"]
config = json.loads(Path("/var/lib/slskd-aurral/slskd.yml").read_text())
assert config["shares"]["directories"] == []
assert config["flags"]["no_connect"] is True
assert config["web"]["ip_address"] == "127.0.0.1"
assert config["soulseek"]["listen_port"] == 50310
assert config["retention"]["files"] == {"complete": None, "incomplete": None}
assert config["transfers"]["download"]["slots"] == 6
assert "speed_limit" not in config["transfers"]["download"]
options = call(5032, "/api/v0/options", headers={"X-API-Key": credential["api_key"]})
assert options["transfers"]["download"]["slots"] == 6
assert options["transfers"]["download"]["speedLimit"] == 2147483647
call(5032, "/api/v0/session", headers={"X-API-Key": credential["api_key"]})
salt = "fixture-subsonic-salt"
token = hashlib.md5((seed["password"] + salt).encode()).hexdigest()
query = urllib.parse.urlencode({"u": seed["username"], "t": token, "s": salt, "v": "1.16.1", "c": "nixos-test", "f": "json"})
assert call(3002, "/rest/ping.view?" + query)["subsonic-response"]["status"] == "ok"
for name in ("admin.json", "slskd.json", "flows.json"):
    assert (root / name).stat().st_mode & 0o777 == 0o600
logs = subprocess.check_output(["journalctl", "--no-pager", "-u", "docker-slskd-aurral", "-u", "docker-aurral-flows", "-u", "aurral-flows-provision"], text=True)
for value in (seed["password"], credential["api_key"], credential["soulseek_password"], logged["token"]):
    assert value not in logs
