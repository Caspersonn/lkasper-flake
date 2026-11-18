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

from decypharr import ProvisionError, atomic_json, merge, read_object


class Client:
    def __init__(self, endpoint):
        parsed = urllib.parse.urlsplit(endpoint)
        if parsed.scheme != "http" or parsed.hostname != "127.0.0.1" or parsed.port != 3002 or parsed.path not in ("", "/") or parsed.query or parsed.fragment or parsed.username or parsed.password:
            raise ProvisionError("Aurral provisioning requires http://127.0.0.1:3002")
        self.base = "http://127.0.0.1:3002"
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
        self.token = None

    def call(self, method, path, body=None):
        if not path.startswith("/api/") or "?" in path or "#" in path:
            raise ProvisionError("invalid Aurral API path")
        headers = {"Accept": "application/json"}
        data = None
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        request = urllib.request.Request(self.base + path, data=data, headers=headers, method=method)
        try:
            with self.opener.open(request, timeout=30) as response:
                payload = response.read(4 * 1024 * 1024 + 1)
        except urllib.error.HTTPError as error:
            raise ProvisionError(f"Aurral request failed with HTTP {error.code} for {method} {path}") from None
        except (urllib.error.URLError, TimeoutError):
            raise ProvisionError("Aurral is not reachable") from None
        if len(payload) > 4 * 1024 * 1024:
            raise ProvisionError("Aurral response exceeded the size limit")
        try:
            return json.loads(payload) if payload else {}
        except (ValueError, UnicodeError):
            raise ProvisionError("Aurral returned invalid JSON") from None

    def ready(self):
        for attempt in range(90):
            try:
                status = self.call("GET", "/api/health/bootstrap")
                if isinstance(status, dict) and isinstance(status.get("onboardingRequired"), bool):
                    return status
            except ProvisionError:
                pass
            if attempt < 89:
                time.sleep(2)
        raise ProvisionError("Aurral bootstrap endpoint did not become ready")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, url):
        return None


def contains(current, wanted):
    if isinstance(wanted, dict):
        return isinstance(current, dict) and all(key in current and contains(current[key], value) for key, value in wanted.items())
    return current == wanted


def administrator(state_dir, status):
    path = state_dir / "admin.json"
    seed = read_object(path, protected=True, optional=True)
    if seed is None:
        if status["onboardingRequired"] is not True:
            raise ProvisionError("existing Aurral administrator requires explicit migration")
        seed = {"username": "casper", "password": "Aa1!" + secrets.token_urlsafe(32)}
        atomic_json(path, seed)
    if seed.get("username") != "casper" or not isinstance(seed.get("password"), str) or len(seed["password"]) < 20:
        raise ProvisionError("invalid protected Aurral administrator seed")
    return seed


def flow_list(client):
    status = client.call("GET", "/api/playlists/status")
    flows = status.get("flows") if isinstance(status, dict) else None
    if not isinstance(flows, list) or any(not isinstance(flow, dict) for flow in flows):
        raise ProvisionError("Aurral returned an invalid flow list")
    return flows


def valid_flow_id(value):
    return isinstance(value, str) and 0 < len(value) <= 128 and all(char.isascii() and (char.isalnum() or char in "-_") for char in value)


def reconcile_flows(client, state_dir, recipes, user_id):
    path = state_dir / "flows.json"
    journal = read_object(path, protected=True, optional=True)
    if journal is None:
        journal = {"managed": {}}
    if not isinstance(journal.get("managed"), dict):
        raise ProvisionError("invalid Aurral flow journal")
    for name, entry in journal["managed"].items():
        if not isinstance(name, str) or not isinstance(entry, dict) or not (entry == {"creating": True} or set(entry) == {"id"} and valid_flow_id(entry["id"])):
            raise ProvisionError("invalid Aurral flow journal entry")
    flows = flow_list(client)
    for name, recipe in recipes.items():
        wanted = dict(recipe, name=name)
        entry = journal["managed"].get(name)
        matches = [flow for flow in flows if flow.get("name") == name]
        if entry is None:
            if matches:
                raise ProvisionError("an unmanaged flow uses a reserved recipe name")
            entry = {"creating": True}
            journal["managed"][name] = entry
            atomic_json(path, journal)
        if entry.get("creating") is True:
            if len(matches) > 1 or any(flow.get("ownerUserId") != user_id for flow in matches):
                raise ProvisionError("interrupted flow creation cannot be reconciled safely")
            if matches:
                flow = matches[0]
            else:
                flow = client.call("POST", "/api/playlists/flows", dict(wanted, autoDownload=False)).get("flow")
                if not isinstance(flow, dict):
                    raise ProvisionError("Aurral did not return the created flow")
                flows.append(flow)
            flow_id = flow.get("id")
            if not valid_flow_id(flow_id):
                raise ProvisionError("Aurral returned an invalid flow identifier")
            entry = {"id": flow_id}
            journal["managed"][name] = entry
            atomic_json(path, journal)
        flow_id = entry.get("id")
        flow = next((flow for flow in flows if flow.get("id") == flow_id), None)
        if flow is None or flow.get("ownerUserId") != user_id:
            raise ProvisionError("managed Aurral flow is missing or changed owner; explicit migration is required")
        if not contains(flow, wanted):
            client.call("PUT", f"/api/playlists/flows/{flow_id}", wanted)
        current = next((flow for flow in flow_list(client) if flow.get("id") == flow_id), None)
        if not contains(current, wanted):
            raise ProvisionError("Aurral recipe did not converge after saving")


def reconcile(client, state_dir, settings, credentials):
    credential = read_object(credentials, protected=True)
    key = credential.get("api_key")
    if not isinstance(key, str) or len(key) < 32 or any(char.isspace() for char in key):
        raise ProvisionError("a protected slskd API key of at least 32 characters is required")
    wanted = merge(settings["settings"], {"integrations": {"slskd": {"apiKey": key}}})
    status = client.ready()
    seed = administrator(state_dir, status)
    if status["onboardingRequired"]:
        client.call("POST", "/api/onboarding/complete", {
            "authUser": seed["username"],
            "authPassword": seed["password"],
            "downloadFolderPath": wanted["downloadFolderPath"],
            "security": {"localNetworkBypass": {"enabled": False}},
        })
    logged = client.call("POST", "/api/auth/login", seed)
    user = logged.get("user", {})
    token = logged.get("token")
    if not isinstance(token, str) or not token or user.get("role") != "admin" or user.get("username") != seed["username"] or type(user.get("id")) is not int or user["id"] <= 0:
        raise ProvisionError("Aurral login did not authenticate the managed administrator")
    client.token = token
    current = client.call("GET", "/api/settings")
    if not contains(current, wanted):
        client.call("POST", "/api/settings", wanted)
        current = client.call("GET", "/api/settings")
        if not contains(current, wanted):
            raise ProvisionError("Aurral settings did not converge after saving")
    reconcile_flows(client, state_dir, settings["flows"], user["id"])


def provision(client, state_dir, settings, credentials):
    info = state_dir.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_mode & 0o077 or state_dir.resolve() != state_dir.absolute():
        raise ProvisionError("Aurral provisioning state must be private without symlinks")
    fd = os.open(state_dir / ".aurral.lock", os.O_WRONLY | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(fd, "w") as lock:
        if not stat.S_ISREG(os.fstat(lock.fileno()).st_mode):
            raise ProvisionError("Aurral provisioning lock must be regular")
        os.fchmod(lock.fileno(), 0o600)
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        reconcile(client, state_dir, settings, credentials)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", default="http://127.0.0.1:3002")
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--settings", type=Path, required=True)
    parser.add_argument("--credentials", type=Path, required=True)
    args = parser.parse_args()
    try:
        provision(Client(args.endpoint), args.state_dir, read_object(args.settings), args.credentials)
    except (ProvisionError, OSError, ValueError, TypeError, KeyError, AttributeError):
        print("Aurral provisioning failed; no account, unmanaged flow or library was reset.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
