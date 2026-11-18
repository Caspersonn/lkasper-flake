import argparse
from contextlib import closing
import json
import os
from pathlib import Path
import sqlite3
import stat
import subprocess
import sys
import time
import urllib.request

from decypharr import ProvisionError, atomic_json, read_object


UNITS = [
    "aurral-capacity.timer", "aurral-capacity.service",
    "aurral-flows-provision.service", "docker-aurral-flows.service",
    "docker-slskd-aurral.service",
]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ProvisionError("cleanup provider redirected")


def directory(path):
    if not path.is_absolute() or path.resolve() != path or not path.is_dir():
        raise ProvisionError("cleanup directories must exist without symlinks")


def references(database):
    if database.resolve() != database or not database.is_file():
        raise ProvisionError("cleanup database must exist without symlinks")
    try:
        with closing(sqlite3.connect(database.as_uri() + "?mode=ro", uri=True)) as db:
            busy = db.execute("SELECT count(*) FROM playlist_download_jobs WHERE status NOT IN ('done','failed','saved','cancelled') OR status IS NULL").fetchone()[0]
            busy += db.execute("SELECT count(*) FROM weekly_flow_download_provider_work").fetchone()[0]
            busy += db.execute("SELECT count(*) FROM _honker_live").fetchone()[0]
            rows = db.execute("SELECT staging_path, final_path FROM playlist_download_jobs").fetchall()
    except sqlite3.Error as error:
        raise ProvisionError("cleanup reference snapshot unavailable") from error
    paths = set()
    for row in rows:
        for value in row:
            if value:
                if not isinstance(value, str) or not Path(value).is_absolute() or ".." in Path(value).parts:
                    raise ProvisionError("invalid cleanup reference")
                paths.add(Path(value))
    return busy, paths


def prune(staging, protected, now, age=48 * 3600, max_files=100, max_bytes=512 * 1024 * 1024, max_entries=50000):
    directory(staging)
    removed = used = scanned = 0
    root_device = staging.stat().st_dev
    for parent, dirs, files, fd in os.fwalk(staging, follow_symlinks=False):
        if os.fstat(fd).st_dev != root_device:
            dirs[:] = []
            continue
        for name in list(dirs) + files:
            scanned += 1
            if scanned > max_entries:
                return {"removedFiles": removed, "removedBytes": used, "reason": "scan-limit"}
            info = os.stat(name, dir_fd=fd, follow_symlinks=False)
            path = Path(parent) / name
            if stat.S_ISDIR(info.st_mode):
                continue
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_dev != root_device:
                continue
            if any(path == ref or ref in path.parents for ref in protected):
                continue
            if now - max(info.st_mtime, info.st_ctime) < age:
                continue
            size = max(info.st_size, info.st_blocks * 512)
            if removed >= max_files or used + size > max_bytes:
                return {"removedFiles": removed, "removedBytes": used, "reason": "removal-limit"}
            current = os.stat(name, dir_fd=fd, follow_symlinks=False)
            if (current.st_dev, current.st_ino, current.st_size, current.st_mtime_ns, current.st_ctime_ns) != (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns):
                raise ProvisionError("cleanup candidate changed")
            os.unlink(name, dir_fd=fd)
            removed += 1
            used += size
    return {"removedFiles": removed, "removedBytes": used, "reason": "complete"}


def command(*args):
    result = subprocess.run(["systemctl", *args], capture_output=True, text=True, timeout=90)
    if result.returncode:
        raise ProvisionError("isolated cleanup service operation failed")
    return result.stdout.strip()


def provider_busy(state):
    key = read_object(state / "slskd.json", protected=True)["api_key"]
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    request = urllib.request.Request("http://127.0.0.1:5032/api/v0/transfers/downloads?includeRemoved=true", headers={"X-API-Key": key})
    with opener.open(request, timeout=20) as response:
        if response.geturl() != request.full_url:
            raise ProvisionError("cleanup provider redirected")
        raw = response.read(4 * 1024 * 1024 + 1)
    if len(raw) > 4 * 1024 * 1024:
        raise ProvisionError("cleanup provider response too large")
    users = json.loads(raw)
    if not isinstance(users, list):
        raise ProvisionError("invalid cleanup provider response")
    for user in users:
        if not isinstance(user, dict) or not isinstance(user.get("directories"), list):
            raise ProvisionError("invalid cleanup provider records")
        for item in user["directories"]:
            if not isinstance(item, dict) or not isinstance(item.get("files"), list):
                raise ProvisionError("invalid cleanup provider files")
            if item["files"]:
                return True
    return False


def resume(state, control=command):
    journal = state / "cleanup-active.json"
    saved = read_object(journal, protected=True, optional=True)
    if saved is None:
        return
    active = saved.get("units")
    if not isinstance(active, list) or any(not isinstance(unit, str) or unit not in UNITS for unit in active) or len(active) != len(set(active)):
        raise ProvisionError("invalid cleanup recovery journal")
    for unit in reversed(active):
        control("start", unit)
    journal.unlink()


def cleanup(state, database, staging, control=command, provider=provider_busy, snapshot=references):
    directory(state)
    if state.stat().st_mode & 0o077:
        raise ProvisionError("cleanup state must be private")
    resume(state, control)
    active = []
    for unit in UNITS:
        if control("show", unit, "--property=LoadState", "--value") != "loaded":
            raise ProvisionError("cleanup unit unavailable")
        status = control("show", unit, "--property=ActiveState", "--value")
        if status == "active":
            active.append(unit)
        elif status not in ("inactive", "failed"):
            raise ProvisionError("cleanup service is transitioning")
    if "docker-slskd-aurral.service" not in active:
        return {"reason": "downloader-inactive"}
    atomic_json(state / "cleanup-active.json", {"units": active})
    try:
        for unit in active:
            if unit != "docker-slskd-aurral.service":
                control("stop", unit)
        if provider(state):
            return {"reason": "provider-references"}
        control("stop", "docker-slskd-aurral.service")
        busy, protected = snapshot(database)
        if busy:
            return {"reason": "application-references"}
        return prune(staging, protected, time.time())
    finally:
        resume(state, control)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    state = Path("/var/lib/aurral-flows-provision")
    try:
        if args.resume:
            resume(state)
        else:
            result = cleanup(state, Path("/var/lib/aurral-flows/aurral.db"), Path("/data/downloads/slskd"))
            atomic_json(state / "cleanup.json", result)
            print("Aurral staging cleanup: " + result["reason"])
    except (OSError, ProvisionError, ValueError, TypeError, KeyError, subprocess.SubprocessError):
        print("Aurral cleanup failed; recovery journal retained when needed.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
