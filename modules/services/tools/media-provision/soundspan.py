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
import urllib.request

from decypharr import ProvisionError, atomic_json, read_object


class Client:
    def __init__(self, endpoint):
        parsed = urllib.parse.urlsplit(endpoint)
        if parsed.scheme != "http" or parsed.hostname not in ("127.0.0.1", "::1") or parsed.path not in ("", "/") or parsed.query or parsed.fragment or parsed.username or parsed.password:
            raise ProvisionError("provisioning requires a loopback HTTP endpoint")
        if parsed.port is None:
            raise ProvisionError("provisioning requires an explicit port")
        self.base = f"http://{parsed.hostname}:{parsed.port}"
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        self.token = None

    def call(self, method, path, body=None):
        headers = {"Accept": "application/json"}
        data = None
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        if self.token is not None:
            headers["Authorization"] = f"Bearer {self.token}"
        request = urllib.request.Request(self.base + path, data=data, headers=headers, method=method)
        try:
            with self.opener.open(request, timeout=30) as response:
                payload = response.read()
        except urllib.error.HTTPError as error:
            raise ProvisionError(f"Soundspan request failed with HTTP {error.code} for {method} {path}")
        except (urllib.error.URLError, TimeoutError):
            raise ProvisionError("Soundspan is not reachable")
        if not payload:
            return {}
        try:
            return json.loads(payload)
        except ValueError:
            raise ProvisionError(f"Soundspan returned invalid JSON for {method} {path}")

    def ready(self):
        for attempt in range(150):
            try:
                return self.call("GET", "/api/onboarding/status")
            except ProvisionError:
                if attempt == 149:
                    raise
            time.sleep(2)
        raise ProvisionError("Soundspan did not become ready")


def admin_file(path):
    if path.exists():
        seed = read_object(path, protected=True)
        if not isinstance(seed, dict) or not isinstance(seed.get("username"), str) or not isinstance(seed.get("password"), str) or len(seed["password"]) < 16:
            raise ProvisionError("invalid Soundspan administrator state")
        return seed
    seed = {"username": "casper", "password": secrets.token_urlsafe(32)}
    atomic_json(path, seed)
    return read_object(path, protected=True)


def authenticate(client, status, seed):
    if status.get("hasAccount") is not True:
        try:
            registered = client.call("POST", "/api/onboarding/register", {"username": seed["username"], "password": seed["password"]})
        except ProvisionError as error:
            if "403" not in str(error):
                raise
        else:
            client.token = registered.get("token")
            if not isinstance(client.token, str) or not client.token:
                raise ProvisionError("Soundspan registration did not return a token")
            return
    logged = client.call("POST", "/api/auth/login", {"username": seed["username"], "password": seed["password"]})
    client.token = logged.get("token")
    if not isinstance(client.token, str) or not client.token:
        raise ProvisionError("Soundspan login did not return a token")


def reconcile(client, state_dir, credentials):
    public = client.ready()
    seed = admin_file(state_dir / "admin.json")
    authenticate(client, public, seed)
    client.call("POST", "/api/onboarding/complete")
    key = read_object(credentials, protected=True).get("key")
    if not isinstance(key, str) or not key:
        raise ProvisionError("the HolyArrs credential does not contain an API key")
    wanted = {
        "downloadSource": "holyarrs",
        "holyarrsEnabled": True,
        "holyarrsUrl": "http://127.0.0.1:6263",
        "holyarrsApiKey": key,
        "musicPath": "/data/media/music",
    }
    current = client.call("GET", "/api/system-settings")
    if not isinstance(current, dict):
        raise ProvisionError("Soundspan returned invalid system settings")
    if any(current.get(name) != value for name, value in wanted.items()):
        client.call("POST", "/api/system-settings", wanted)
        current = client.call("GET", "/api/system-settings")
        if not isinstance(current, dict) or any(current.get(name) != value for name, value in wanted.items()):
            raise ProvisionError("Soundspan settings did not match intent after saving")
    return current


def provision(client, state_dir, credentials):
    info = state_dir.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_mode & 0o077 or state_dir.resolve() != state_dir.absolute():
        raise ProvisionError("Soundspan state directory must be private without symlinks")
    fd = os.open(state_dir / ".soundspan.lock", os.O_WRONLY | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(fd, "w") as lock:
        if not stat.S_ISREG(os.fstat(lock.fileno()).st_mode):
            raise ProvisionError("Soundspan lock must be regular")
        os.fchmod(lock.fileno(), 0o600)
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        return reconcile(client, state_dir, credentials)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--credentials", type=Path, required=True)
    args = parser.parse_args()
    try:
        provision(Client(args.endpoint), args.state_dir, args.credentials)
    except (ProvisionError, OSError, ValueError, TypeError, KeyError, AttributeError) as error:
        print(f"Soundspan provisioning failed: {error}; no account or setting was deleted.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
