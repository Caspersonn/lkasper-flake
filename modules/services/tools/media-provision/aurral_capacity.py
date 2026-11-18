import argparse
import fcntl
import os
from pathlib import Path
import stat
import subprocess
import sys

from decypharr import ProvisionError, atomic_json, read_object


def tree_bytes(root):
    if root.is_symlink() or root.resolve() != root.absolute():
        raise ProvisionError("capacity root must not contain symlinks")
    if not root.exists():
        return 0
    pending = [root]
    total = 0
    while pending:
        directory = pending.pop()
        with os.scandir(directory) as entries:
            for entry in entries:
                info = entry.stat(follow_symlinks=False)
                if stat.S_ISDIR(info.st_mode):
                    pending.append(Path(entry.path))
                elif stat.S_ISREG(info.st_mode):
                    total += max(info.st_size, info.st_blocks * 512)
    return total


def measure(library, staging, budget, minimum_free):
    if budget <= 0 or minimum_free < 0:
        raise ProvisionError("invalid capacity limits")
    for root in (library, staging):
        if not root.is_dir() or root.resolve() != root.absolute():
            raise ProvisionError("capacity directories must exist without symlinks")
    used = tree_bytes(library / "_flows") + tree_bytes(staging)
    free = min(os.statvfs(root).f_bavail * os.statvfs(root).f_frsize for root in (library, staging))
    reason = "temporary-budget" if used >= budget else "minimum-free-space" if free < minimum_free else "ready"
    return {"paused": reason != "ready", "reason": reason, "temporaryBytes": used, "availableBytes": free}


def enforce(state_dir, status, control):
    info = state_dir.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_mode & 0o077 or state_dir.resolve() != state_dir.absolute():
        raise ProvisionError("capacity state must be private without symlinks")
    fd = os.open(state_dir / ".capacity.lock", os.O_WRONLY | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(fd, "w") as lock:
        if not stat.S_ISREG(os.fstat(lock.fileno()).st_mode):
            raise ProvisionError("capacity lock must be regular")
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        path = state_dir / "capacity.json"
        previous = read_object(path, protected=True, optional=True) or {}
        if status["paused"]:
            atomic_json(path, status)
            control("stop")
        elif previous.get("paused"):
            control("start")
            atomic_json(path, status)
        else:
            atomic_json(path, status)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", type=Path, default=Path("/data/music-aurral"))
    parser.add_argument("--staging", type=Path, default=Path("/data/downloads/slskd"))
    parser.add_argument("--state-dir", type=Path, default=Path("/var/lib/aurral-flows-provision"))
    parser.add_argument("--budget", type=int, required=True)
    parser.add_argument("--minimum-free", type=int, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        try:
            status = measure(args.library, args.staging, args.budget, args.minimum_free)
        except (OSError, ProvisionError):
            status = {"paused": True, "reason": "measurement-unavailable"}
        if args.check:
            return int(status["paused"])
        def control(action):
            subprocess.run(["systemctl", action, "docker-slskd-aurral.service"], check=True, timeout=90)
        enforce(args.state_dir, status, control)
        print("Aurral acquisition capacity: " + status["reason"])
    except (OSError, ProvisionError, ValueError, subprocess.SubprocessError):
        print("Aurral capacity enforcement failed; inspect the isolated downloader.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
