import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess


parser = argparse.ArgumentParser()
parser.add_argument("phase", choices=("verify", "isolate"))
args = parser.parse_args()
assert os.environ.get("AURRAL_VM_RECOVERY") == "1"
assert Path("/etc/aurral-recovery-vm").is_file()
paths = [
    Path("/var/lib/decypharr"), Path("/var/lib/holyarrs"), Path("/var/lib/jackett"),
    Path("/var/lib/aurral-flows-provision"), Path("/var/lib/aurral-flows"),
    Path("/var/lib/slskd-aurral"), Path("/data/music-aurral"),
]
staging = Path("/var/lib/media-restore/latest")
fixture = json.loads(Path("/var/lib/aurral-flows/retention-fixture.json").read_text())
if args.phase == "verify":
    assert staging.stat().st_mode & 0o077 == 0
    kept = Path(fixture["jobs"][0]["file"])
    rotated = Path(fixture["jobs"][1]["file"])
    restored = staging / str(kept).lstrip("/")
    assert restored.read_bytes().startswith(b"fLaC")
    assert hashlib.sha256(restored.read_bytes()).digest() == hashlib.sha256(kept.read_bytes()).digest()
    assert not (staging / str(rotated).lstrip("/")).exists()
    assert rotated.is_file()
    for name in ("admin", "slskd", "flows"):
        live = Path(f"/var/lib/aurral-flows-provision/{name}.json")
        assert (staging / str(live).lstrip("/")).read_bytes() == live.read_bytes()
    print("Recovery includes credentials and liked audio still in _flows, without unliked audio")
else:
    units = [
        "aurral-capacity.timer", "aurral-capacity.service", "aurral-flows-provision.service",
        "docker-aurral-flows.service", "docker-slskd-aurral.service",
        "docker-holyarrs.service", "jackett.service", "docker-decypharr.service",
    ]
    subprocess.run(["systemctl", "stop", *units], check=True)
    destination = Path("/var/lib/aurral-vm-original")
    destination.mkdir(mode=0o700)
    for index, path in enumerate(paths):
        assert path.is_dir() and not path.is_symlink()
        path.rename(destination / str(index))
    print("Disposable VM roots moved aside for verified restore installation")
