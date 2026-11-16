import json
from pathlib import Path
import urllib.request


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
