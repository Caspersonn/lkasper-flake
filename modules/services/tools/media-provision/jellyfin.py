import argparse
import fcntl
import json
import os
from pathlib import Path
import secrets
import stat
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

from decypharr import ProvisionError, atomic_json, read_object


LABEL = "nixos-media-provision"
LIBRARIES = [
    {"name": "Movies", "kind": "movies", "paths": ["/data/media/movies"]},
    {"name": "TV Shows", "kind": "tvshows", "paths": ["/data/media/tv"]},
]


class Client:
    def __init__(self, endpoint, opener=None):
        parsed = urllib.parse.urlsplit(endpoint)
        if parsed.scheme != "http" or parsed.hostname not in ("127.0.0.1", "::1") or parsed.path not in ("", "/") or parsed.query or parsed.fragment or parsed.username or parsed.password:
            raise ProvisionError("Jellyfin provisioning requires a loopback HTTP endpoint")
        self.endpoint = endpoint.rstrip("/")
        self.opener = opener or urllib.request.build_opener(urllib.request.ProxyHandler({}))
        self.token = None

    def call(self, method, path, body=None, headers=None):
        data = None
        merged = {"Accept": "application/json", **(headers or {})}
        if body is not None:
            data = json.dumps(body).encode()
            merged["Content-Type"] = "application/json"
        if self.token:
            merged["Authorization"] = f'MediaBrowser Token="{self.token}"'
        request = urllib.request.Request(self.endpoint + path, data=data, method=method, headers=merged)
        try:
            with self.opener.open(request, timeout=30) as response:
                raw = response.read()
        except urllib.error.HTTPError as error:
            raise ProvisionError(f"Jellyfin request failed with HTTP {error.code} for {method} {path}") from None
        except (urllib.error.URLError, TimeoutError):
            raise ProvisionError("Jellyfin is not reachable") from None
        if not raw:
            return None
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            raise ProvisionError("Jellyfin returned invalid JSON") from None

    def ready(self):
        deadline = time.monotonic() + 300
        while True:
            try:
                return self.call("GET", "/System/Info/Public")
            except ProvisionError:
                if time.monotonic() >= deadline:
                    raise ProvisionError("Jellyfin did not become ready")
                time.sleep(2)

    def startup_ready(self):
        deadline = time.monotonic() + 300
        while True:
            try:
                return self.call("GET", "/Startup/Configuration")
            except ProvisionError:
                if time.monotonic() >= deadline:
                    raise ProvisionError("Jellyfin startup wizard did not become ready")
                time.sleep(2)

    def login(self, name, password):
        answer = self.call("POST", "/Users/AuthenticateByName", {"Username": name, "Pw": password}, {"Authorization": f'MediaBrowser Client="{LABEL}", Device="kaito", DeviceId="{LABEL}", Version="1.0"'})
        token = answer.get("AccessToken") if isinstance(answer, dict) else None
        user = answer.get("User") if isinstance(answer, dict) else None
        if not isinstance(token, str) or not token or not isinstance(user, dict) or user.get("Name") != name:
            raise ProvisionError("Jellyfin login did not return the expected identity")
        self.token = token
        return user


def password_file(path):
    if path.exists():
        stored = read_object(path, protected=True)
        password = stored.get("password") if isinstance(stored, dict) else None
        if not isinstance(password, str) or len(password) < 16:
            raise ProvisionError("invalid Jellyfin administrator state")
        return stored
    password = secrets.token_urlsafe(32)
    atomic_json(path, {"name": "media-admin", "password": password})
    return read_object(path, protected=True)


def ensure_libraries(client):
    existing = client.call("GET", "/Library/VirtualFolders")
    if not isinstance(existing, list):
        raise ProvisionError("invalid Jellyfin library list")
    for wanted in LIBRARIES:
        matches = [item for item in existing if isinstance(item, dict) and item.get("Name") == wanted["name"]]
        if len(matches) > 1:
            raise ProvisionError("duplicate Jellyfin library")
        if matches:
            paths = matches[0].get("Locations")
            if not isinstance(paths, list) or wanted["paths"][0] not in paths:
                raise ProvisionError("Jellyfin library location changed; migration required")
            continue
        query = urllib.parse.urlencode([("name", wanted["name"]), ("collectionType", wanted["kind"]), ("refreshLibrary", "false")] + [("paths", path) for path in wanted["paths"]])
        client.call("POST", "/Library/VirtualFolders?" + query, {"LibraryOptions": {}})
    saved = client.call("GET", "/Library/VirtualFolders")
    names = {item.get("Name") for item in saved if isinstance(item, dict)}
    if not {wanted["name"] for wanted in LIBRARIES} <= names:
        raise ProvisionError("Jellyfin libraries were not saved")


def reconcile(client, state_dir):
    public = client.ready()
    completed = public.get("StartupWizardCompleted") if isinstance(public, dict) else None
    if completed is not True:
        seed = password_file(state_dir / "admin.json")
        client.startup_ready()
        client.call("POST", "/Startup/Configuration", {"UICulture": "en-US", "MetadataCountryCode": "US", "PreferredMetadataLanguage": "en"})
        client.call("GET", "/Startup/User")
        client.call("POST", "/Startup/User", {"Name": seed["name"], "Password": seed["password"]})
        client.call("POST", "/Startup/Complete")
        public = client.call("GET", "/System/Info/Public")
        if not isinstance(public, dict) or public.get("StartupWizardCompleted") is not True:
            raise ProvisionError("Jellyfin startup wizard did not complete")
    elif not (state_dir / "admin.json").exists():
        raise ProvisionError("existing Jellyfin administrator requires explicit migration")
    seed = read_object(state_dir / "admin.json", protected=True)
    user = client.login(seed["name"], seed["password"])
    if user.get("Policy", {}).get("IsAdministrator") is not True:
        raise ProvisionError("Jellyfin administrator lacks the administrator role")
    ensure_libraries(client)
    return public


def provision(client, state_dir):
    info = state_dir.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_mode & 0o077 or state_dir.resolve() != state_dir.absolute():
        raise ProvisionError("Jellyfin state directory must be private without symlinks")
    fd = os.open(state_dir / ".jellyfin.lock", os.O_WRONLY | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(fd, "w") as lock:
        if not stat.S_ISREG(os.fstat(lock.fileno()).st_mode):
            raise ProvisionError("Jellyfin lock must be regular")
        os.fchmod(lock.fileno(), 0o600)
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        return reconcile(client, state_dir)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    args = parser.parse_args()
    try:
        provision(Client(args.endpoint), args.state_dir)
    except (ProvisionError, OSError, ValueError, TypeError, KeyError, AttributeError) as error:
        print(f"Jellyfin provisioning failed: {error}; no user or library was deleted.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
