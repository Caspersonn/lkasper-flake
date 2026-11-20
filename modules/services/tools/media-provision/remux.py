import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import secrets
import stat
import subprocess
import sys
import time
from urllib.parse import urlsplit

from decypharr import ProvisionError, atomic_json, read_object


TRANSPORT = '''import json,sys,urllib.request,urllib.error
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs): return None
r=json.load(sys.stdin)
q=urllib.request.Request("http://127.0.0.1:3000"+r["path"],method=r["method"],headers=r["headers"],data=None if r["body"] is None else json.dumps(r["body"]).encode())
try:
 with urllib.request.build_opener(urllib.request.ProxyHandler({}),NoRedirect()).open(q,timeout=30) as s:
  b=s.read(4194305)
  if len(b)>4194304: raise ValueError()
  print(json.dumps({"status":s.status,"body":json.loads(b) if b else None}))
except urllib.error.HTTPError as e: print(json.dumps({"status":e.code}))
'''


class Client:
    def __init__(self, container):
        if not re.fullmatch(r"remux-[a-z0-9-]+", container):
            raise ProvisionError("invalid Remux container name")
        self.container = container
        self.token = None

    def require_isolation(self):
        result = subprocess.run(
            ["docker", "inspect", "--format", "{{.HostConfig.NetworkMode}}", self.container],
            capture_output=True, text=True, timeout=20,
        )
        if result.returncode != 0 or result.stdout.strip() != "none":
            raise ProvisionError("Remux bootstrap requires an isolated network")

    def call(self, method, path, body=None):
        if not path.startswith("/") or "\n" in path or "\r" in path:
            raise ProvisionError("invalid Remux API path")
        headers = {
            "Content-Type": "application/json",
            "Authorization": 'MediaBrowser Client="nixos-remux", Device="kaito", DeviceId="nixos-remux", Version="1"',
        }
        if self.token:
            headers["X-Emby-Token"] = self.token
            headers["Authorization"] += ', Token="' + self.token + '"'
        result = subprocess.run(
            ["docker", "exec", "-i", self.container, "python3", "-c", TRANSPORT],
            input=json.dumps({"method": method, "path": path, "body": body, "headers": headers}),
            capture_output=True, text=True, timeout=40,
        )
        try:
            response = json.loads(result.stdout) if result.returncode == 0 else {}
        except ValueError:
            response = {}
        if not isinstance(response, dict) or response.get("status") not in range(200, 300):
            raise ProvisionError("Remux API request failed")
        return response.get("body")


def reconcile(client, state_dir):
    public = client.call("GET", "/system/info/public")
    if not isinstance(public, dict) or not isinstance(public.get("StartupWizardCompleted"), bool):
        raise ProvisionError("Remux startup status is invalid")
    seed_path = state_dir / "admin.json"
    seed = read_object(seed_path, protected=True, optional=True)
    if seed is None:
        if public["StartupWizardCompleted"]:
            raise ProvisionError("existing Remux administrator requires explicit migration")
        seed = {"name": "casper", "password": "Aa1!" + secrets.token_urlsafe(32)}
        atomic_json(seed_path, seed)
    if not all(isinstance(seed.get(key), str) and seed[key] for key in ("name", "password")):
        raise ProvisionError("Remux administrator seed is invalid")
    if not public["StartupWizardCompleted"]:
        client.call("POST", "/startup/user", {"Name": seed["name"], "Password": seed["password"]})
    auth = client.call("POST", "/users/authenticatebyname", {"Username": seed["name"], "Pw": seed["password"]})
    if not isinstance(auth, dict) or not isinstance(auth.get("AccessToken"), str) or not auth["AccessToken"]:
        raise ProvisionError("Remux administrator authentication failed")
    user = auth.get("User", {})
    if user.get("Name") != seed["name"] or user.get("Policy", {}).get("IsAdministrator") is not True:
        raise ProvisionError("Remux administrator identity is invalid")
    client.token = auth["AccessToken"]
    config = client.call("GET", "/system/configuration")
    if not isinstance(config, dict) or "P2pEnabled" not in config:
        raise ProvisionError("Remux P2P configuration contract is unavailable")
    wanted = {"P2pEnabled": False, "ServerName": "kaito", "DefaultWebClient": "remux"}
    if any(config.get(key) != value for key, value in wanted.items()):
        client.call("POST", "/system/configuration", dict(config, **wanted))
    verified = client.call("GET", "/system/configuration")
    if any(verified.get(key) != value for key, value in wanted.items()):
        raise ProvisionError("Remux safety settings did not converge")
    if not public["StartupWizardCompleted"]:
        client.call("POST", "/startup/complete")
    if client.call("GET", "/system/info/public").get("StartupWizardCompleted") is not True:
        raise ProvisionError("Remux startup did not complete")


def reconcile_source(client, state_dir, credential_path):
    seed = read_object(state_dir / "admin.json", protected=True)
    credentials = read_object(credential_path, protected=True)
    manifest = credentials.get("manifest_url")
    if not isinstance(manifest, str) or any(character.isspace() for character in manifest):
        raise ProvisionError("Remux source credential is invalid")
    parsed = urlsplit(manifest)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or parsed.fragment or not parsed.path.endswith("/manifest.json"):
        raise ProvisionError("Remux source requires a protected HTTPS manifest")
    auth = client.call("POST", "/users/authenticatebyname", {"Username": seed.get("name"), "Pw": seed.get("password")})
    if not isinstance(auth, dict) or not isinstance(auth.get("AccessToken"), str) or not auth["AccessToken"]:
        raise ProvisionError("Remux administrator authentication failed")
    user = auth.get("User", {})
    if user.get("Name") != seed.get("name") or user.get("Policy", {}).get("IsAdministrator") is not True:
        raise ProvisionError("Remux administrator identity is invalid")
    client.token = auth["AccessToken"]
    config = client.call("GET", "/system/configuration")
    if not isinstance(config, dict) or config.get("P2pEnabled") is not False:
        raise ProvisionError("Remux source provisioning requires disabled P2P")
    addons = client.call("GET", "/addons")
    if not isinstance(addons, list):
        raise ProvisionError("Remux addon listing is invalid")
    journal_path = state_dir / "source.json"
    journal = read_object(journal_path, protected=True, optional=True)
    if journal is None:
        if any(addon.get("name") == "Managed AIOStreams" for addon in addons):
            raise ProvisionError("existing Remux source requires explicit migration")
        atomic_json(journal_path, {"creating": True})
        journal = {"creating": True}
    if journal == {"creating": True}:
        matches = [addon for addon in addons if addon.get("name") == "Managed AIOStreams" and addon.get("kind") == "stremio" and addon.get("config", {}).get("manifest_url") == manifest]
        if len(matches) > 1:
            raise ProvisionError("Remux source creation is ambiguous")
        if matches:
            addon = matches[0]
        else:
            client.call("POST", "/addons", {"preset": {"kind": "stremio", "config": {"manifest_url": manifest}}, "name": "Managed AIOStreams", "isDefault": True, "priority": 0})
            matches = [addon for addon in client.call("GET", "/addons") if addon.get("name") == "Managed AIOStreams" and addon.get("kind") == "stremio" and addon.get("config", {}).get("manifest_url") == manifest]
            if len(matches) != 1:
                raise ProvisionError("Remux source creation did not converge")
            addon = matches[0]
        journal = {"id": addon.get("id")}
        atomic_json(journal_path, journal)
    if set(journal) != {"id"} or not isinstance(journal["id"], str) or not re.fullmatch(r"[a-zA-Z0-9-]{1,128}", journal["id"]):
        raise ProvisionError("Remux source journal is invalid")
    matches = [addon for addon in client.call("GET", "/addons") if addon.get("id") == journal["id"]]
    if len(matches) != 1 or matches[0].get("kind") != "stremio":
        raise ProvisionError("managed Remux source is missing or changed")
    wanted = {"name": "Managed AIOStreams", "config": {"manifest_url": manifest}, "enabled": True, "isDefault": True, "httpRedirectStream": False}
    addon = matches[0]
    if any(addon.get(key) != value for key, value in wanted.items()):
        client.call("POST", "/addons/" + journal["id"], wanted)
    verified = next((addon for addon in client.call("GET", "/addons") if addon.get("id") == journal["id"]), {})
    if any(verified.get(key) != value for key, value in wanted.items()):
        raise ProvisionError("Remux source settings did not converge")


def provision(client, state_dir, source_credentials=None):
    if source_credentials is None:
        client.require_isolation()
    state_dir = Path(state_dir).absolute()
    for parent in (*reversed(state_dir.parents), state_dir):
        if parent.is_symlink():
            raise ProvisionError("Remux state must not traverse symlinks")
    if source_credentials is not None and not state_dir.is_dir():
        raise ProvisionError("Remux must be bootstrapped before configuring sources")
    state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    if not state_dir.is_dir() or stat.S_IMODE(state_dir.stat().st_mode) & 0o077:
        raise ProvisionError("Remux provisioning state must be private")
    fd = os.open(state_dir / ".remux.lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, "w") as lock:
        if not stat.S_ISREG(os.fstat(lock.fileno()).st_mode):
            raise ProvisionError("Remux lock must be a regular file")
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        for attempt in range(60):
            try:
                client.call("GET", "/system/info/public")
                break
            except ProvisionError:
                if attempt == 59:
                    raise
                time.sleep(1)
        if source_credentials is None:
            reconcile(client, state_dir)
        else:
            reconcile_source(client, state_dir, source_credentials)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--container", required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--source-credentials", type=Path)
    args = parser.parse_args()
    try:
        provision(Client(args.container), args.state_dir, args.source_credentials)
    except (ProvisionError, OSError, ValueError, subprocess.SubprocessError):
        print("Remux provisioning failed; existing data was not reset.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
