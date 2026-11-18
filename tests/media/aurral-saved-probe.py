import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import time
import urllib.parse
import urllib.request


parser = argparse.ArgumentParser()
parser.add_argument("phase", choices=("retain", "check"))
parser.add_argument("--state-dir", default="/var/lib/aurral-flows-provision")
parser.add_argument("--app-state", default="/var/lib/aurral-flows")
args = parser.parse_args()
seed = json.loads((Path(args.state_dir) / "admin.json").read_text())
fixture_path = Path(args.app_state) / "saved-fixture.json"
fixture = json.loads(fixture_path.read_text())
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
salt = "saved-playlist-test"
params = {
    "u": seed["username"], "s": salt,
    "t": hashlib.md5((seed["password"] + salt).encode()).hexdigest(),
    "v": "1.16.1", "c": "saved-playlist-test", "f": "json",
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
    with opener.open(request, timeout=90) as response:
        raw = response.read()
        return json.loads(raw) if raw else None


token = api("auth/login", seed)["token"]
if args.phase == "retain":
    tracks = subsonic("getPlaylist", id="flow:" + fixture["flowId"])["playlist"]["entry"]
    assert len(tracks) == 2
    for track in tracks:
        subsonic("stream", id=track["id"], format="raw")
    result = api("library/downloads/track", {
        "artistName": "Fixture Artist", "albumName": "Fixture Album", "trackName": "Explicit Keep Song",
        "durationMs": 2000,
    }, token=token)
    assert result.get("success") or result.get("alreadyOwned") or result.get("queued"), result
    saved = api("playlists/flows/" + fixture["flowId"] + "/static-playlist", {"name": "Saved Retention Fixture"}, token=token)
    assert saved["trackCount"] == 2
    playlist_id = saved["playlist"]["id"]
    fixture["playlistId"] = playlist_id
    fixture_path.write_text(json.dumps(fixture))
    entries = subsonic("getPlaylist", id="shared:" + playlist_id)["playlist"]["entry"]
    favorite = next(track for track in entries if track["title"] == "Playlist Favorite Song")
    with ThreadPoolExecutor(max_workers=2) as executor:
        liked = executor.submit(subsonic, "star", id=favorite["id"])
        rotated = executor.submit(api, "playlists/flows/" + fixture["flowId"], method="DELETE", token=token)
        liked.result()
        rotated.result()
    for _ in range(120):
        if not any(flow["id"] == fixture["flowId"] for flow in api("playlists/status", token=token)["flows"]):
            break
        time.sleep(1)
    else:
        raise AssertionError("Native flow cleanup did not complete")
    entries = subsonic("getPlaylist", id="shared:" + playlist_id)["playlist"]["entry"]
    assert len(entries) == 2
    for track in entries:
        subsonic("stream", id=track["id"], format="raw")
    api("playlists/shared-playlists/" + playlist_id, method="DELETE", token=token)
    for _ in range(120):
        if not any(playlist["id"] == playlist_id for playlist in api("playlists/status", token=token)["sharedPlaylists"]):
            break
        time.sleep(1)
    else:
        raise AssertionError("Native saved-playlist cleanup did not complete")

for title in ("Explicit Keep Song", "Playlist Favorite Song"):
    for _ in range(90):
        songs = subsonic("search3", query=title)["searchResult3"].get("song", [])
        matches = [song for song in songs if song["title"] == title]
        if len(matches) == 1:
            break
        time.sleep(1)
    assert len(matches) == 1, "Retained track must exist exactly once"
    subsonic("stream", id=matches[0]["id"], format="raw")
    if title == "Playlist Favorite Song":
        starred = subsonic("getStarred2")["starred2"].get("song", [])
        assert len([song for song in starred if song["title"] == title]) == 1
        subsonic("unstar", id=matches[0]["id"])
        subsonic("stream", id=matches[0]["id"], format="raw")
        subsonic("star", id=matches[0]["id"])
print("Explicit keep, saved-playlist retention and concurrent favorite/cleanup passed")
