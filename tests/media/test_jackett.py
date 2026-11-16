import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("jackett_provision", SOURCE / "jackett.py")
jackett = importlib.util.module_from_spec(spec)
spec.loader.exec_module(jackett)


class JackettTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.state = self.root / "state"

    def provision(self):
        jackett.provision(SOURCE / "jackett-settings.json", self.state, 9117)

    def read(self, name):
        return json.loads((self.state / name).read_text())

    def write(self, name, value):
        path = self.state / name
        path.write_text(json.dumps(value))
        path.chmod(0o600)

    def test_fresh_settings_and_credentials(self):
        self.provision()
        server = self.read("ServerConfig.json")
        seed = self.read("provision-auth.json")
        self.assertEqual(server["APIKey"], seed["APIKey"])
        expected = hashlib.sha512((seed["admin_password"] + seed["APIKey"]).encode("utf-16le")).hexdigest()
        self.assertEqual(server["AdminPassword"], expected)
        self.assertTrue(server["AllowExternal"])
        self.assertTrue(server["UpdateDisabled"])
        self.assertEqual(server["Port"], 9117)
        self.assertEqual({p.stem for p in (self.state / "Indexers").glob("*.json")}, {"knaben", "thepiratebay"})
        self.assertIn({"id": "top100", "value": "100"}, self.read("Indexers/thepiratebay.json"))
        for path in self.state.rglob("*"):
            self.assertEqual(path.stat().st_mode & 0o777, 0o700 if path.is_dir() else 0o600)

    def test_repeat_is_byte_and_inode_identical(self):
        self.provision()
        before = {p: (p.read_bytes(), p.stat().st_ino, p.stat().st_mtime_ns) for p in self.state.rglob("*.json")}
        self.provision()
        self.assertEqual(before, {p: (p.read_bytes(), p.stat().st_ino, p.stat().st_mtime_ns) for p in before})

    def test_preserve_unmanaged_settings_and_sources(self):
        self.provision()
        server = self.read("ServerConfig.json")
        server.update(CacheTtl=1234, AllowCORS=True)
        self.write("ServerConfig.json", server)
        self.write("Indexers/knaben.json", [{"id": "tags", "value": "kept"}, {"id": "sitelink", "value": "wrong", "type": "inputstring"}])
        self.write("Indexers/other.json", [{"id": "unmanaged", "value": 42}])
        self.provision()
        self.assertEqual(self.read("ServerConfig.json")["CacheTtl"], 1234)
        self.assertFalse(self.read("ServerConfig.json")["AllowCORS"])
        self.assertEqual(self.read("Indexers/other.json"), [{"id": "unmanaged", "value": 42}])
        self.assertIn({"id": "sitelink", "value": "https://knaben.org/", "type": "inputstring"}, self.read("Indexers/knaben.json"))
        self.assertIn({"id": "tags", "value": "kept"}, self.read("Indexers/knaben.json"))

    def test_refuse_unmanaged_server(self):
        self.state.mkdir(mode=0o700)
        self.write("ServerConfig.json", {"APIKey": "existing"})
        with self.assertRaises(jackett.ProvisionError):
            self.provision()
        self.assertFalse((self.state / "provision-auth.json").exists())

    def test_refuse_changed_credentials_without_writes(self):
        self.provision()
        for field in ("APIKey", "InstanceId", "AdminPassword"):
            with self.subTest(field=field):
                original = self.read("ServerConfig.json")
                self.write("ServerConfig.json", dict(original, **{field: "changed"}))
                before = (self.state / "ServerConfig.json").read_bytes()
                with self.assertRaises(jackett.ProvisionError):
                    self.provision()
                self.assertEqual(before, (self.state / "ServerConfig.json").read_bytes())
                self.write("ServerConfig.json", original)

    def test_missing_or_invalid_seed_refused(self):
        self.provision()
        seed = self.read("provision-auth.json")
        for field in seed:
            with self.subTest(field=field):
                self.write("provision-auth.json", dict(seed, **{field: ""}))
                with self.assertRaises(jackett.ProvisionError):
                    self.provision()
        (self.state / "provision-auth.json").unlink()
        with self.assertRaises(jackett.ProvisionError):
            self.provision()

    def test_interrupted_first_run_recovers_seed(self):
        atomic = jackett.atomic_json
        def fail_server(path, value):
            if path.name == "ServerConfig.json":
                raise OSError("interrupted")
            return atomic(path, value)
        with patch.object(jackett, "atomic_json", side_effect=fail_server):
            with self.assertRaises(OSError):
                self.provision()
        seed = self.read("provision-auth.json")
        self.provision()
        self.assertEqual(self.read("provision-auth.json"), seed)
        self.assertEqual(self.read("ServerConfig.json")["APIKey"], seed["APIKey"])

    def test_bad_indexer_state_refused_before_writes(self):
        self.provision()
        before = (self.state / "ServerConfig.json").read_bytes()
        for value in ({}, [1], [{"id": "x"}, {"id": "x"}], [{"value": 1}]):
            with self.subTest(value=value):
                self.write("Indexers/knaben.json", value)
                with self.assertRaises(jackett.ProvisionError):
                    self.provision()
                self.assertEqual((self.state / "ServerConfig.json").read_bytes(), before)

    def test_directory_symlinks_refused(self):
        target = self.root / "target"
        target.mkdir(mode=0o700)
        self.state.symlink_to(target)
        with self.assertRaises(jackett.ProvisionError):
            self.provision()
        self.assertEqual(list(target.iterdir()), [])

    def test_indexer_file_symlink_refused(self):
        self.provision()
        path = self.state / "Indexers/knaben.json"
        path.unlink()
        path.symlink_to(self.state / "provision-auth.json")
        with self.assertRaises(OSError):
            self.provision()

    def test_unsafe_seed_permissions_refused(self):
        self.provision()
        (self.state / "provision-auth.json").chmod(0o644)
        with self.assertRaises(jackett.ProvisionError):
            self.provision()

    def test_nonblocking_lock(self):
        self.provision()
        with (self.state / ".provision.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises(BlockingIOError):
                self.provision()

    def test_cli_redacts_invalid_input(self):
        self.provision()
        marker = "private-value-must-not-appear"
        (self.state / "ServerConfig.json").write_text(marker)
        result = subprocess.run([sys.executable, "-B", str(SOURCE / "jackett.py"), "--settings", str(SOURCE / "jackett-settings.json"), "--state-dir", str(self.state), "--port", "9117"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertNotIn(marker, result.stdout + result.stderr)
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
