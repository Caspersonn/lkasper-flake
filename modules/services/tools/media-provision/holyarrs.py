import argparse
import fcntl
import http.cookiejar
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


class ApiError(ProvisionError):
    def __init__(self, status=None):
        super().__init__("HolyArrs request failed")
        self.status = status


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ApiError(code)


class Client:
    def __init__(self, endpoint):
        parsed = urllib.parse.urlsplit(endpoint)
        if parsed.scheme != "http" or parsed.hostname not in ("127.0.0.1", "::1") or parsed.path not in ("", "/") or parsed.query or parsed.fragment or parsed.username or parsed.password:
            raise ProvisionError("bootstrap requires a loopback HTTP endpoint")
        if parsed.port is None:
            raise ProvisionError("bootstrap requires an explicit port")
        self.endpoint = endpoint.rstrip("/")
        self.csrf = None
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect(), urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def call(self, method, path, body=None, key=None):
        headers = {"Accept": "application/json", "Origin": self.endpoint}
        if self.csrf:
            headers["X-CSRF-Token"] = self.csrf
        if key:
            headers["X-Api-Key"] = key
        data = None
        if body is not None:
            headers["Content-Type"] = "application/json"
            data = json.dumps(body).encode()
        request = urllib.request.Request(self.endpoint + "/api/v1" + path, data=data, headers=headers, method=method)
        try:
            with self.opener.open(request, timeout=5) as response:
                raw = response.read(1024 * 1024 + 1)
                if len(raw) > 1024 * 1024:
                    raise ApiError()
                value = json.loads(raw) if raw else {}
                if not isinstance(value, dict):
                    raise ApiError()
                return value
        except urllib.error.HTTPError as error:
            status = error.code
            error.close()
            raise ApiError(status) from None
        except (urllib.error.URLError, OSError, ValueError):
            raise ApiError() from None

    def ready(self):
        deadline = time.monotonic() + 60
        for attempt in range(30):
            try:
                return self.call("GET", "/auth/state")
            except ApiError as error:
                if error.status not in (None, 502, 503, 504) or attempt == 29 or time.monotonic() >= deadline:
                    raise
                time.sleep(1)


def require_identity(who, owner, expected_id=None, via="session"):
    if who.get("name") != owner["name"] or who.get("role") != "owner" or type(who.get("id")) is not int or who["id"] <= 0:
        raise ProvisionError("authenticated identity is not the managed owner")
    if expected_id is not None and who["id"] != expected_id:
        raise ProvisionError("API key belongs to a different owner")
    if who.get("via") != via:
        raise ProvisionError("unexpected authentication method")


def bootstrap(client, state_dir):
    state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = state_dir.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.geteuid() or info.st_mode & 0o077 or state_dir.resolve() != state_dir.absolute():
        raise ProvisionError("bootstrap state must be private, service-owned and without symlinks")
    fd = os.open(state_dir / ".provision.lock", os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(fd, "w") as lock:
        if not stat.S_ISREG(os.fstat(lock.fileno()).st_mode):
            raise ProvisionError("bootstrap lock must be a regular file")
        os.fchmod(lock.fileno(), 0o600)
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        reconcile(client, state_dir)


def reconcile(client, state_dir):
    owner_path = state_dir / "owner.json"
    key_path = state_dir / "api-key.json"
    intent_path = state_dir / "api-intent.json"
    owner = read_object(owner_path, protected=True, optional=True)
    stored = read_object(key_path, protected=True, optional=True)
    intent = read_object(intent_path, protected=True, optional=True)
    if intent is not None and intent != {"label": LABEL}:
        raise ProvisionError("unexpected API key creation intent")
    state = client.ready()
    if type(state.get("needs_setup")) is not bool or state.get("host_refused") or state.get("config_unmapped"):
        raise ProvisionError("HolyArrs is not ready for supported bootstrap")
    if owner is None:
        if not state["needs_setup"] or stored is not None or intent is not None:
            raise ProvisionError("existing HolyArrs state requires migration or restore")
        owner = {"name": "media-admin", "password": secrets.token_urlsafe(36)}
        atomic_json(owner_path, owner)
    if owner.get("name") != "media-admin" or not isinstance(owner.get("password"), str) or len(owner["password"]) < 20:
        raise ProvisionError("owner seed is incomplete; restore it before provisioning")
    if state["needs_setup"]:
        if stored is not None:
            raise ProvisionError("database and API state must be restored together")
        result = client.call("POST", "/auth/setup", owner)
    else:
        result = client.call("POST", "/auth/login", owner)
    if not isinstance(result.get("csrf"), str) or not result["csrf"]:
        raise ProvisionError("login did not establish a CSRF-protected session")
    client.csrf = result["csrf"]
    try:
        who = client.call("GET", "/auth/me")
        require_identity(who, owner)
        keys = client.call("GET", "/auth/keys").get("keys")
        if not isinstance(keys, list) or any(not isinstance(item, dict) for item in keys):
            raise ProvisionError("unexpected API key list")
        if stored is None:
            matching = [item for item in keys if item.get("label") == LABEL]
            if matching and intent is None:
                raise ProvisionError("missing established API credential; restore it")
            for item in matching:
                if type(item.get("id")) is not int or item["id"] <= 0:
                    raise ProvisionError("unexpected managed key identifier")
            atomic_json(intent_path, {"label": LABEL})
            for item in matching:
                client.call("DELETE", f"/auth/keys/{item['id']}")
            created = client.call("POST", "/auth/keys", {"label": LABEL, "scopes": ["all"]})
            stored = {name: created.get(name) for name in ("id", "label", "scopes", "key")}
            validate_key(stored)
            atomic_json(key_path, stored)
        else:
            validate_key(stored)
            matching = [item for item in keys if item.get("label") == LABEL]
            if len(matching) != 1 or matching[0].get("id") != stored["id"] or matching[0].get("scopes") != ["all"]:
                raise ProvisionError("saved API key does not match the server; restore or migrate")
        require_identity(client.call("GET", "/auth/me", key=stored["key"]), owner, who["id"], via="api_key")
        settings = client.call("GET", "/auth/settings", key=stored["key"])
        if settings.get("skip_login_local_network") is not False:
            client.call("PUT", "/auth/settings", {"skip_login_local_network": False}, key=stored["key"])
        if client.call("GET", "/auth/settings", key=stored["key"]).get("skip_login_local_network") is not False:
            raise ProvisionError("local-network authentication bypass is still enabled")
        if intent is not None or intent_path.exists():
            intent_path.unlink()
        if who.get("setup_open") is True:
            client.call("POST", "/auth/setup/done", {})
        if client.call("GET", "/auth/me").get("setup_open") is not False:
            raise ProvisionError("owner setup is incomplete")
    finally:
        client.call("POST", "/auth/logout", {})
        client.csrf = None


def validate_key(stored):
    if type(stored.get("id")) is not int or stored["id"] <= 0 or stored.get("label") != LABEL or stored.get("scopes") != ["all"] or not isinstance(stored.get("key"), str) or not stored["key"].startswith("hak_"):
        raise ProvisionError("invalid managed API key response or state")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    args = parser.parse_args()
    try:
        bootstrap(Client(args.endpoint), args.state_dir)
    except (ProvisionError, OSError, ValueError, TypeError, KeyError, AttributeError):
        print("HolyArrs bootstrap failed; existing accounts and credentials were not reset.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
