import json
from pathlib import Path
import urllib.request
import urllib.error
import time


def call(method, path, body=None, token=None):
    data = json.dumps(body).encode() if body is not None else None
    headers = {"Authorization": 'MediaBrowser Client="jellyfin-probe", Device="kaito", DeviceId="jellyfin-probe", Version="1.0"' + (f', Token="{token}"' if token else "")}
    if data:
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request("http://127.0.0.1:8096" + path, data=data, method=method, headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read() or b"null")


seed = json.loads(Path("/var/lib/jellyfin/provision/admin.json").read_text())
public = call("GET", "/System/Info/Public")
assert public["StartupWizardCompleted"] is True
login = call("POST", "/Users/AuthenticateByName", {"Username": seed["name"], "Pw": seed["password"]})
assert login["User"]["Name"] == seed["name"] and login["User"]["Policy"]["IsAdministrator"] is True
token = login["AccessToken"]
folders = call("GET", "/Library/VirtualFolders", token=token)
assert {row["Name"] for row in folders} == {"Movies", "TV Shows"}
assert {row["CollectionType"] for row in folders} == {"movies", "tvshows"}
assert all(row["Locations"] == [f"/data/media/{'movies' if row['Name'] == 'Movies' else 'tv'}"] for row in folders)
ping = call("GET", "/Moonfin/Ping", token=token)
assert ping["seerrEnabled"] is True
status = call("GET", "/Moonfin/Seerr/Status", token=token)
assert status["authenticated"] is True
assert ping["defaultSettings"]["seerrEnabled"] is True
discovery = call("GET", "/Moonfin/Seerr/Api/discover/movies", token=token)
assert discovery["results"][0]["id"] == 550
detail = call("GET", "/Moonfin/Seerr/Api/movie/550", token=token)
assert detail["mediaInfo"]["status"] != 5
assert not detail["mediaInfo"].get("ratingKey")
requested = call("POST", "/Moonfin/Seerr/Api/request", {"mediaId": 550, "mediaType": "movie"}, token=token)
assert requested["id"] == 1
assert json.loads(Path("/run/moonfin-request.json").read_text())["id"] == "tmdb:550"
users = call("GET", "/Users", token=token)
restricted = next((user for user in users if user["Name"] == "restricted"), None)
if restricted is None:
    restricted = call("POST", "/Users/New", {"Name": "restricted", "Password": "fixture-password"}, token=token)
policy = restricted["Policy"]
policy["EnableAllFolders"] = False
call("POST", f"/Users/{restricted['Id']}/Policy", policy, token=token)
restricted_login = call("POST", "/Users/AuthenticateByName", {"Username": "restricted", "Pw": "fixture-password"})
for path, supplied_token, expected in [
    ("/Moonfin/Seerr/Status", None, 401),
    ("/Moonfin/Seerr/Status", "invalid", 401),
    ("/Moonfin/Seerr/Status", restricted_login["AccessToken"], 403),
    ("/Moonfin/Seerr/Api/settings/main", token, 501),
]:
    try:
        call("GET", path, token=supplied_token)
        raise AssertionError(path)
    except urllib.error.HTTPError as error:
        assert error.code == expected, (path, error.code)
assert "moonfin-fixture-secret" not in json.dumps([ping, status, discovery, detail, requested])
call("POST", "/Library/Refresh", token=token)
for _ in range(120):
    indexed = call("GET", "/Moonfin/Seerr/Api/movie/551", token=token)
    if indexed["mediaInfo"].get("ratingKey"):
        break
    time.sleep(1)
else:
    raise AssertionError("Linked fixture was not indexed as playable")
assert indexed["mediaInfo"]["status"] == 5
item_id = indexed["mediaInfo"]["ratingKey"]
request = urllib.request.Request(
    f"http://127.0.0.1:8096/Videos/{item_id}/stream?static=true",
    headers={"X-Emby-Token": token, "Range": "bytes=0-63"},
)
with urllib.request.urlopen(request, timeout=30) as response:
    assert response.read(4) == bytes.fromhex("1a45dfa3")
