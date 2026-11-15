import base64
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest
import uuid


class LifecycleTests(unittest.TestCase):
    def test_socket_secret_ordering_and_restart_import(self):
        runtime = Path(os.environ["XDG_RUNTIME_DIR"])
        directory = runtime / "systemd/user"
        directory.mkdir(parents=True, exist_ok=True)
        name = "atuin-acceptance-" + uuid.uuid4().hex
        units = [name + suffix for suffix in [".service", ".socket", "-secrets.service", "-import.service"]]
        atuin = shutil.which("atuin")
        python = shutil.which("python3")
        initializer = Path(__file__).resolve().parents[2] / "modules/users/shared/atuin/credentials.py"
        with tempfile.TemporaryDirectory(prefix=name, dir=runtime) as temporary:
            root = Path(temporary)
            socket = runtime / (name + ".sock")
            for kind, content in [("session", b"fixture-session"), ("key", base64.b64encode(bytes(range(32))))]:
                path = root / kind
                path.write_bytes(content)
                path.chmod(0o400)
            (root / "config.toml").write_text(
                f'data_dir = "{root}/data"\nkey_path = "{root}/key"\nauto_sync = false\n'
                '[ai]\nenabled = false\n[threads]\ncapture = true\n'
                '[daemon]\nenabled = true\nautostart = false\nsystemd_socket = true\n'
                f'socket_path = "{socket}"\nsync_frequency = 300\n'
            )
            before = root / "before.py"
            before.write_text(f'import runpy,sys\nfrom pathlib import Path\nassert Path("{root}/ready").exists()\nsys.argv=["credentials","{root}/session","{root}/key","{root}/config.toml","{atuin}"]\nrunpy.run_path("{initializer}",run_name="__main__")\n')
            importer = root / "import.py"
            importer.write_text(f'import subprocess\nfrom pathlib import Path\nsubprocess.run(["{atuin}","threads","import"],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)\nwith Path("{root}/imports").open("a") as f: f.write("done\\n")\n')
            env = f'Environment=HOME={root} ATUIN_CONFIG_DIR={root} XDG_DATA_HOME={root}/share XDG_CONFIG_HOME={root} XDG_STATE_HOME={root}/state RUST_LOG=off\n'
            definitions = {
                units[0]: f'[Unit]\nRequires={units[1]} {units[2]}\nAfter={units[2]}\nWants={units[3]}\n[Service]\nExecStartPre={python} {before}\nExecStart={atuin} daemon start\nUMask=0077\nRestart=on-failure\n' + env,
                units[1]: f'[Socket]\nListenStream={socket}\nSocketMode=0600\nRemoveOnStop=true\n',
                units[2]: f'[Service]\nType=oneshot\nExecStart={shutil.which("touch")} {root}/ready\nRemainAfterExit=true\n',
                units[3]: f'[Unit]\nRequires={units[0]}\nAfter={units[0]}\nPartOf={units[0]}\n[Service]\nType=oneshot\nExecStart={python} {importer}\nRemainAfterExit=true\nRestart=on-failure\nRestartSec=1\nUMask=0077\n' + env,
            }
            try:
                for unit, content in definitions.items():
                    (directory / unit).write_text(content)
                self.control("daemon-reload")
                self.control("start", units[1])
                self.assertFalse((root / "ready").exists())
                result = subprocess.run([atuin, "threads", "list", "--style", "json"],
                    env=dict(os.environ, HOME=str(root), ATUIN_CONFIG_DIR=str(root)),
                    capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.wait_imports(root, 1)
                first = self.control("show", units[0], "--property=MainPID", "--value").stdout.strip()
                self.control("restart", units[0])
                self.wait_imports(root, 2)
                second = self.control("show", units[0], "--property=MainPID", "--value").stdout.strip()
                self.assertNotEqual(first, second)
                self.assertEqual(socket.stat().st_mode & 0o777, 0o600)
            finally:
                self.control("stop", *units, check=False)
                for unit in units:
                    (directory / unit).unlink(missing_ok=True)
                self.control("daemon-reload")
                self.control("reset-failed", *units, check=False)

    def control(self, *args, check=True):
        return subprocess.run(["systemctl", "--user", *args], capture_output=True, text=True, check=check, timeout=30)

    def wait_imports(self, root, count):
        for _ in range(100):
            path = root / "imports"
            if path.exists() and len(path.read_text().splitlines()) == count:
                return
            time.sleep(0.1)
        self.fail("Import did not complete after daemon start/restart")


if __name__ == "__main__":
    unittest.main()
