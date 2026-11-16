import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import stat
import sys

from decypharr import ProvisionError, atomic_json, read_object
from holyarrs import Client, validate_key


def records(client, path, field, key):
    values = client.call("GET", path, key=key).get(field)
    if not isinstance(values, list) or any(not isinstance(item, dict) or type(item.get("id")) is not int or item["id"] <= 0 for item in values):
        raise ProvisionError("invalid integration list")
    return values


def unique(values, field, value):
    matching = [item for item in values if item.get(field) == value]
    if len(matching) > 1:
        raise ProvisionError("duplicate managed integration")
    return matching[0] if matching else None


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def reconcile(client, settings, keys, journal_path):
    validate_key(keys["holyarrs"])
    key = keys["holyarrs"]["key"]
    jackett_key = keys["jackett"].get("APIKey")
    downloader_key = keys["decypharr"].get("api_token")
    if not isinstance(jackett_key, str) or not jackett_key or not isinstance(downloader_key, str) or not downloader_key or keys["decypharr"].get("token_only") is not True:
        raise ProvisionError("incomplete integration credentials")
    journal = read_object(journal_path, protected=True, optional=True)
    if journal is None:
        journal = {"sources": {}, "downloaders": {}}
    if set(journal) != {"sources", "downloaders"} or any(not isinstance(value, dict) for value in journal.values()):
        raise ProvisionError("invalid integration journal")
    folders = records(client, "/library-folders", "library_folders", key)
    for wanted in settings["folders"]:
        found = unique(folders, "path", wanted["path"])
        if found and found.get("kind") != wanted["kind"]:
            raise ProvisionError("managed library path has an incompatible kind")
        if found is None:
            found = client.call("POST", "/library-folders", wanted, key=key)
            if type(found.get("id")) is not int or found.get("path") != wanted["path"] or found.get("kind") != wanted["kind"]:
                raise ProvisionError("library creation did not match intent")
        elif found.get("label") != wanted["label"]:
            client.call("PUT", f"/library-folders/{found['id']}", {"label": wanted["label"]}, key=key)
        checked = client.call("POST", f"/library-folders/{found['id']}/check", {}, key=key)
        if checked.get("health") != "ok" or checked.get("path") != wanted["path"] or checked.get("kind") != wanted["kind"]:
            raise ProvisionError("library folder is not ready for safe imports")
    groups = (
        ("sources", [{**settings["source_defaults"], **item} for item in settings["sources"]], "api_key", jackett_key),
        ("downloaders", [settings["downloader"]], "secret", downloader_key),
    )
    for group, wanted_items, secret_field, secret in groups:
        existing = records(client, "/" + group, group, key)
        for wanted in wanted_items:
            found = unique(existing, "name", wanted["name"])
            if found is not None and (found.get("url") != wanted["url"] or (group == "sources" and found.get("format") != wanted["format"]) or (group == "downloaders" and found.get("kind") != wanted["kind"])):
                raise ProvisionError("managed integration target changed; migration required")
            fingerprint = digest({secret_field: secret})
            saved = journal[group].get(wanted["name"])
            if saved is not None and (not isinstance(saved, dict) or type(saved.get("id")) is not int or not isinstance(saved.get("digest"), str)):
                raise ProvisionError("invalid integration journal entry")
            if found is None and saved is not None:
                raise ProvisionError("managed integration disappeared; restore or migrate")
            if found is not None and saved is not None and found["id"] != saved["id"]:
                raise ProvisionError("managed integration identity changed")
            changed = found is None or any(found.get(name) != value for name, value in wanted.items()) or saved is None or saved["digest"] != fingerprint
            if changed:
                body = {**wanted, secret_field: secret}
                found = client.call("POST" if found is None else "PUT", "/" + group + ("" if found is None else f"/{found['id']}"), body, key=key)
                if type(found.get("id")) is not int or found["id"] <= 0 or any(found.get(name) != value for name, value in wanted.items()):
                    raise ProvisionError("saved integration does not match intent")
                journal[group][wanted["name"]] = {"id": found["id"], "digest": fingerprint}
                atomic_json(journal_path, journal)
            if client.call("POST", f"/{group}/{found['id']}/test", {}, key=key).get("ok") is not True:
                raise ProvisionError("managed integration failed its native test")
    return journal


def provision(client, settings, credentials, state_dir):
    info = state_dir.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_mode & 0o077 or state_dir.resolve() != state_dir.absolute():
        raise ProvisionError("integration state directory must be private without symlinks")
    fd = os.open(state_dir / ".connections.lock", os.O_WRONLY | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(fd, "w") as lock:
        if not stat.S_ISREG(os.fstat(lock.fileno()).st_mode):
            raise ProvisionError("integration lock must be regular")
        os.fchmod(lock.fileno(), 0o600)
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        keys = {name: read_object(path, protected=True) for name, path in credentials.items()}
        client.ready()
        return reconcile(client, settings, keys, state_dir / "connections.json")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", required=True)
    parser.add_argument("--settings", type=Path, required=True)
    parser.add_argument("--credentials-dir", type=Path, required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    args = parser.parse_args()
    try:
        provision(Client(args.endpoint), read_object(args.settings), {name: args.credentials_dir / name for name in ("holyarrs", "jackett", "decypharr")}, args.state_dir)
    except (ProvisionError, OSError, ValueError, TypeError, KeyError, AttributeError):
        print("Media integration provisioning failed; no library or integration was deleted.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
