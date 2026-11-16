import argparse
import copy
import fcntl
import hashlib
import json
import os
from pathlib import Path
import secrets
import stat
import sys

from decypharr import ProvisionError, atomic_json, read_object


def private_directory(path):
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = path.lstat()
    if not stat.S_ISDIR(info.st_mode) or path.resolve() != path.absolute():
        raise ProvisionError("state directory must not contain symlinks")
    if info.st_uid != os.geteuid() or info.st_mode & 0o077:
        raise ProvisionError("state directory must be private and service-owned")


def read_items(path):
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    except FileNotFoundError:
        return []
    with os.fdopen(fd, "r") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_size > 1024 * 1024 or info.st_mode & 0o077:
            raise ProvisionError("indexer state must be a protected regular file")
        try:
            value = json.load(stream)
        except (ValueError, UnicodeError):
            raise ProvisionError("indexer state contains invalid JSON") from None
    validate_items(value)
    return value


def validate_items(items):
    if not isinstance(items, list):
        raise ProvisionError("indexer state must contain an array")
    ids = set()
    for item in items:
        if not isinstance(item, dict) or not isinstance(item.get("id"), str) or item["id"] in ids:
            raise ProvisionError("indexer state contains invalid or duplicate items")
        ids.add(item["id"])


def reconcile_items(current, managed):
    validate_items(current)
    validate_items(managed)
    result = copy.deepcopy(current)
    by_id = {item["id"]: item for item in result}
    for item in managed:
        if item["id"] in by_id:
            by_id[item["id"]].update(item)
        else:
            result.append(copy.deepcopy(item))
    return result


def password_hash(password, api_key):
    return hashlib.sha512((password + api_key).encode("utf-16le")).hexdigest()


def credentials(current, seed):
    if seed is None:
        if current is not None:
            raise ProvisionError("existing unmanaged Jackett state requires explicit migration")
        seed = {
            "APIKey": secrets.token_hex(16),
            "InstanceId": secrets.token_hex(32),
            "admin_password": secrets.token_urlsafe(32),
        }
    for key in ("APIKey", "InstanceId", "admin_password"):
        if not isinstance(seed.get(key), str) or not seed[key] or any(c.isspace() for c in seed[key]):
            raise ProvisionError("credential state is incomplete; restore it before provisioning")
    expected = {key: seed[key] for key in ("APIKey", "InstanceId")}
    expected["AdminPassword"] = password_hash(seed["admin_password"], seed["APIKey"])
    if current is not None and any(current.get(key) != value for key, value in expected.items()):
        raise ProvisionError("server credentials differ from protected state; restore or migrate first")
    return seed, expected


def provision(settings_path, state_dir, port):
    settings = read_object(settings_path)
    if not isinstance(settings.get("server"), dict) or set(settings.get("indexers", {})) != {"knaben", "thepiratebay"}:
        raise ProvisionError("unexpected managed Jackett settings")
    if set(settings["server"]) & {"APIKey", "InstanceId", "AdminPassword"}:
        raise ProvisionError("credentials must not be declared in settings")
    private_directory(state_dir)
    lock = os.open(state_dir / ".provision.lock", os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(lock, "w") as stream:
        if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
            raise ProvisionError("lock must be a regular file")
        os.fchmod(stream.fileno(), 0o600)
        fcntl.flock(stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        server_path = state_dir / "ServerConfig.json"
        seed_path = state_dir / "provision-auth.json"
        current = read_object(server_path, protected=True, optional=True)
        seed = read_object(seed_path, protected=True, optional=True)
        seed, expected = credentials(current, seed)
        server = copy.deepcopy(current) if current is not None else {}
        server.update(settings["server"])
        server.update(expected)
        server["Port"] = port
        indexer_dir = state_dir / "Indexers"
        private_directory(indexer_dir)
        indexers = {
            name: reconcile_items(read_items(indexer_dir / f"{name}.json"), items)
            for name, items in settings["indexers"].items()
        }
        atomic_json(seed_path, seed)
        for name, items in indexers.items():
            atomic_json(indexer_dir / f"{name}.json", items)
        atomic_json(server_path, server)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--settings", type=Path, required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--port", type=int, required=True)
    args = parser.parse_args()
    try:
        if not 0 < args.port < 65536:
            raise ProvisionError("invalid port")
        provision(args.settings, args.state_dir, args.port)
    except (ProvisionError, OSError, ValueError, KeyError, TypeError, AttributeError):
        print("Jackett provisioning failed; existing state was not reset.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
