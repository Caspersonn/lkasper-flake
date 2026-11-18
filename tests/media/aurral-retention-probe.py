import argparse
import hashlib
import json
from pathlib import Path
import time
import urllib.parse
import urllib.request


parser = argparse.ArgumentParser()
parser.add_argument("phase", choices=("prepare", "retain", "check"))
parser.add_argument("--state-dir", default="/var/lib/aurral-flows-provision")
parser.add_argument("--app-state", default="/var/lib/aurral-flows")
parser.add_argument("--library-root", default="/data/music-aurral")
args = parser.parse_args()
seed = json.loads((Path(args.state_dir) / "admin.json").read_text())
fixture = json.loads((Path(args.app_state) / "retention-fixture.json").read_text())
rotating_file = Path(args.library_root) / Path(fixture["jobs"][1]["file"]).relative_to("/data/music-aurral")
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
salt = "retention-test"
params = {
    "u": seed["username"], "s": salt,
    "t": hashlib.md5((seed["password"] + salt).encode()).hexdigest(),
    "v": "1.16.1", "c": "retention-test", "f": "json",
}


def subsonic(method, **extra):
    query = urllib.parse.urlencode({**params, **extra})
    with opener.open(f"http://127.0.0.1:3002/rest/{method}.view?{query}", timeout=30) as response:
        if method == "stream":
            assert response.status == 200
            assert response.geturl().startswith("http://127.0.0.1:3002/rest/")
            raw = response.read()
            assert raw.startswith(b"fLaC") and len(raw) > 10000
            return
        result = json.load(response)["subsonic-response"]
        assert result["status"] == "ok", result
        return result


def api(path, body=None, method=None, token=None):
    request = urllib.request.Request(
        "http://127.0.0.1:3002/api/" + path,
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
        headers={"Content-Type": "application/json", **({"Authorization": "Bearer " + token} if token else {})},
    )
    with opener.open(request, timeout=30) as response:
        raw = response.read()
        return json.loads(raw) if raw else None


if args.phase in ("prepare", "retain"):
    assert rotating_file.is_file(), "Temporary audio fixture is absent"
    entries = subsonic("getPlaylist", id="flow:" + fixture["flowId"])["playlist"]["entry"]
    assert len(entries) == 2
    for entry in entries:
        subsonic("stream", id=entry["id"], format="raw")
    keep = next(entry for entry in entries if entry["title"] == "Keep Song")
    subsonic("star", id=keep["id"])
    subsonic("star", id=keep["id"])
if args.phase == "retain":
    token = api("auth/login", seed)["token"]
    api("playlists/flows/" + fixture["flowId"], method="DELETE", token=token)
    for _ in range(120):
        if not rotating_file.exists():
            break
        time.sleep(1)
    assert not rotating_file.exists(), "Unliked temporary file survived cleanup"
for _ in range(90):
    starred = subsonic("getStarred2")["starred2"].get("song", [])
    kept = [song for song in starred if song["title"] == "Keep Song"]
    if len(kept) == 1:
        break
    time.sleep(1)
assert len(kept) == 1, "Favorite must be retained exactly once"
subsonic("stream", id=kept[0]["id"], format="raw")
subsonic("unstar", id=kept[0]["id"])
subsonic("stream", id=kept[0]["id"], format="raw")
subsonic("star", id=kept[0]["id"])
print("Full-track streaming, favorite retention and non-destructive unstar passed")
