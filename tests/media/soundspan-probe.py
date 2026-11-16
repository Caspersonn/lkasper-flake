import json
from pathlib import Path
import urllib.error
import urllib.request

seed = json.loads(Path("/var/lib/soundspan/provision/admin.json").read_text())
request = urllib.request.Request(
    "http://127.0.0.1:3006/api/auth/login",
    data=json.dumps({"username": seed["username"], "password": seed["password"]}).encode(),
    headers={"Content-Type": "application/json"},
)
with urllib.request.urlopen(request, timeout=10) as response:
    login = json.load(response)
assert isinstance(login.get("token"), str) and login["token"]
assert login.get("user", {}).get("role") == "admin"
request = urllib.request.Request(
    "http://127.0.0.1:3006/api/system-settings",
    headers={"Authorization": f"Bearer {login['token']}"},
)
with urllib.request.urlopen(request, timeout=10) as response:
    settings = json.load(response)
assert settings.get("downloadSource") == "holyarrs"
assert settings.get("holyarrsEnabled") is True
assert settings.get("holyarrsUrl") == "http://127.0.0.1:6263"
assert settings.get("musicPath") == "/data/media/music"
assert isinstance(settings.get("holyarrsApiKey"), str) and settings["holyarrsApiKey"]
frontend = urllib.request.urlopen("http://127.0.0.1:3030/", timeout=10)
assert frontend.status == 200
print("Soundspan account, HolyArrs settings and frontend verified.")
