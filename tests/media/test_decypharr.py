import contextlib
import copy
import fcntl
import importlib.util
import io
import json
import os
from pathlib import Path
import stat
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "modules/services/tools/media-provision"
SPEC = importlib.util.spec_from_file_location("decypharr", SOURCE / "decypharr.py")
decypharr = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(decypharr)
SETTINGS = json.loads((SOURCE / "decypharr-settings.json").read_text())


class RendererTests(unittest.TestCase):
    def setUp(self):
        self.credential = {"real_debrid_api_key": "test-only-provider-key"}

    def fresh(self):
        return decypharr.render(SETTINGS, self.credential)

    def test_fresh_configuration_uses_debrid_symlinks_and_music(self):
        config, auth = self.fresh()
        self.assertEqual(config["debrids"][0]["api_key"], self.credential["real_debrid_api_key"])
        self.assertEqual(config["default_download_action"], "symlink")
        self.assertEqual(config["download_folder"], "/data/symlinks")
        self.assertIn("holyarrs-music", config["categories"])
        self.assertTrue({"mp3", "flac", "opus", "m4a", "mkv"} <= set(config["allowed_file_types"]))
        self.assertEqual(config["min_file_size"], "0")
        self.assertEqual(config["mount"]["type"], "dfs")
        self.assertEqual(config["mount"]["mount_path"], "/data/debrid")
        self.assertEqual(config["mount"]["dfs"]["disk_cache_size"], "500MB")
        self.assertEqual(config["mount"]["dfs"]["buffer_memory"], "256MB")
        self.assertTrue(config["use_auth"])
        self.assertTrue(config["disable_webdav"])
        self.assertEqual(config["hearsay"], {"disabled": True, "participate": False, "publish": False})
        self.assertFalse(config["nfs"]["enabled"])
        self.assertFalse(config["smb"]["enabled"])
        self.assertEqual(config["usenet"]["providers"], [])
        self.assertTrue(auth["token_only"])
        self.assertEqual(len(auth["api_token"]), 64)
        self.assertNotIn("password", auth)

    def test_fresh_instances_have_distinct_generated_secrets(self):
        first, first_auth = self.fresh()
        second, second_auth = self.fresh()
        self.assertNotEqual(first["session_secret"], second["session_secret"])
        self.assertNotEqual(first["strm"]["secret"], second["strm"]["secret"])
        self.assertNotEqual(first_auth["api_token"], second_auth["api_token"])

    def test_repeat_activation_is_identical(self):
        config, auth = self.fresh()
        self.assertEqual(decypharr.render(SETTINGS, self.credential, config, auth), (config, auth))

    def test_rotation_preserves_auth_signing_keys_and_unmanaged_settings(self):
        config, auth = self.fresh()
        config["log_level"] = "warn"
        config["debrids"][0]["rate_limit"] = "50/minute"
        config["debrids"][0]["download_api_keys"] = ["old-provider-key"]
        updated, updated_auth = decypharr.render(SETTINGS, {"real_debrid_api_key": "rotated-test-key"}, config, auth)
        self.assertEqual(updated["debrids"][0]["api_key"], "rotated-test-key")
        self.assertNotIn("download_api_keys", updated["debrids"][0])
        self.assertEqual(updated["debrids"][0]["rate_limit"], "50/minute")
        self.assertEqual(updated["session_secret"], config["session_secret"])
        self.assertEqual(updated["strm"]["secret"], config["strm"]["secret"])
        self.assertEqual(updated["log_level"], "warn")
        self.assertEqual(updated_auth, auth)

    def test_renderer_does_not_mutate_inputs(self):
        config, auth = self.fresh()
        original = copy.deepcopy((SETTINGS, self.credential, config, auth))
        decypharr.render(SETTINGS, self.credential, config, auth)
        self.assertEqual((SETTINGS, self.credential, config, auth), original)

    def test_invalid_provider_key_is_rejected(self):
        for value in (None, "", "a b", "secret\n", 42):
            with self.subTest(value=value), self.assertRaises(decypharr.ProvisionError):
                decypharr.render(SETTINGS, {"real_debrid_api_key": value})

    def test_missing_auth_is_not_regenerated(self):
        config, _ = self.fresh()
        with self.assertRaises(decypharr.ProvisionError):
            decypharr.render(SETTINGS, self.credential, config)

    def test_missing_auth_material_requires_restore(self):
        config, auth = self.fresh()
        for key in ("api_token", "session_version"):
            damaged = dict(auth)
            del damaged[key]
            with self.subTest(key=key), self.assertRaises(decypharr.ProvisionError):
                decypharr.render(SETTINGS, self.credential, config, damaged)

    def test_password_auth_is_not_silently_replaced(self):
        with self.assertRaises(decypharr.ProvisionError):
            decypharr.render(SETTINGS, self.credential, {}, {"username": "existing", "password": "existing-hash"})

    def test_existing_other_providers_require_explicit_migration(self):
        for value in ([{"provider": "torbox"}], [{}, {}], "invalid"):
            with self.subTest(value=value), self.assertRaises(decypharr.ProvisionError):
                decypharr.render(SETTINGS, self.credential, {"debrids": value})
        with self.assertRaises(decypharr.ProvisionError):
            decypharr.render(SETTINGS, self.credential, {"usenet": {"providers": [{}]}})

    def test_empty_signing_keys_are_not_silently_rotated(self):
        config, auth = self.fresh()
        config["session_secret"] = ""
        with self.assertRaises(decypharr.ProvisionError):
            decypharr.render(SETTINGS, self.credential, config, auth)

    def test_invalid_nested_state_is_not_discarded(self):
        for current in ({"strm": "invalid"}, {"mount": {"dfs": []}}, {"usenet": []}):
            with self.subTest(current=current), self.assertRaises(decypharr.ProvisionError):
                decypharr.render(SETTINGS, self.credential, current)


class FileTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.credentials = self.root / "credentials.json"
        self.credentials.write_text(json.dumps({"real_debrid_api_key": "test-only-provider-key"}))
        self.credentials.chmod(0o600)
        self.state = self.root / "state"

    def provision(self):
        decypharr.provision(SOURCE / "decypharr-settings.json", self.credentials, self.state)

    def test_two_activations_preserve_bytes_and_timestamps(self):
        self.provision()
        paths = (self.state / "config.json", self.state / "auth.json")
        before = {p.name: (p.read_bytes(), p.stat().st_mtime_ns, p.stat().st_ino) for p in paths}
        self.provision()
        after = {p.name: (p.read_bytes(), p.stat().st_mtime_ns, p.stat().st_ino) for p in paths}
        self.assertEqual(before, after)
        self.assertEqual(stat.S_IMODE(self.state.stat().st_mode), 0o700)
        for path in self.state.iterdir():
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)

    def test_unsafe_credentials_permissions_are_rejected(self):
        self.credentials.chmod(0o644)
        with self.assertRaises(decypharr.ProvisionError):
            self.provision()
        self.assertFalse(self.state.exists())

    def test_missing_credentials_do_not_create_state(self):
        self.credentials.unlink()
        with self.assertRaises(decypharr.ProvisionError):
            self.provision()
        self.assertFalse(self.state.exists())

    def test_corrupt_state_is_not_overwritten(self):
        self.provision()
        path = self.state / "config.json"
        path.write_text('{"broken": "test-only-sensitive-value"')
        with self.assertRaises(decypharr.ProvisionError) as error:
            self.provision()
        self.assertEqual(path.read_text(), '{"broken": "test-only-sensitive-value"')
        self.assertNotIn("test-only-sensitive-value", str(error.exception))

    def test_invalid_auth_leaves_config_unchanged(self):
        self.provision()
        config = self.state / "config.json"
        before = config.read_bytes()
        (self.state / "auth.json").write_text("{}")
        with self.assertRaises(decypharr.ProvisionError):
            self.provision()
        self.assertEqual(config.read_bytes(), before)

    def test_replace_failure_preserves_previous_file_and_cleans_temporary(self):
        self.provision()
        target = self.state / "config.json"
        before = target.read_bytes()
        with patch.object(decypharr.os, "replace", side_effect=OSError("test-only-failure")):
            with self.assertRaises(OSError):
                decypharr.atomic_json(target, {"changed": True})
        self.assertEqual(target.read_bytes(), before)
        self.assertEqual(sorted(p.name for p in self.state.iterdir()), [".provision.lock", "auth.json", "config.json"])

    def test_file_permissions_are_repaired_without_changing_content(self):
        self.provision()
        target = self.state / "auth.json"
        before = target.read_bytes()
        target.chmod(0o644)
        self.provision()
        self.assertEqual(target.read_bytes(), before)
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)

    def test_symlinked_credentials_are_rejected(self):
        target = self.root / "credential-target.json"
        self.credentials.rename(target)
        self.credentials.symlink_to(target)
        with self.assertRaises(OSError):
            self.provision()

    def test_symlinked_state_is_rejected(self):
        target = self.root / "target"
        target.mkdir()
        self.state.symlink_to(target)
        with self.assertRaises(decypharr.ProvisionError):
            self.provision()
        self.assertEqual(list(target.iterdir()), [])

    def test_group_writable_state_is_rejected(self):
        self.state.mkdir(mode=0o770)
        self.state.chmod(0o770)
        with self.assertRaises(decypharr.ProvisionError):
            self.provision()

    def test_concurrent_provisioning_is_refused_without_mutation(self):
        self.provision()
        target = self.state / "config.json"
        before = target.read_bytes()
        with (self.state / ".provision.lock").open("w") as lock:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises(BlockingIOError):
                self.provision()
        self.assertEqual(target.read_bytes(), before)

    def test_symlinked_configuration_is_not_followed(self):
        self.provision()
        target = self.state / "config.json"
        outside = self.root / "outside.json"
        target.rename(outside)
        before = outside.read_bytes()
        target.symlink_to(outside)
        with self.assertRaises(OSError):
            self.provision()
        self.assertEqual(outside.read_bytes(), before)

    def test_fifo_input_is_rejected_without_waiting(self):
        self.credentials.unlink()
        os.mkfifo(self.credentials, 0o600)
        with self.assertRaises(decypharr.ProvisionError):
            self.provision()

    def test_cli_does_not_log_sensitive_values(self):
        self.credentials.write_text('{"test-only-sensitive-value":')
        output = io.StringIO()
        args = ["decypharr", "--settings", str(SOURCE / "decypharr-settings.json"),
                "--credentials", str(self.credentials), "--state-dir", str(self.state)]
        with patch.object(decypharr.sys, "argv", args), contextlib.redirect_stderr(output):
            self.assertEqual(decypharr.main(), 1)
        self.assertNotIn("test-only-sensitive-value", output.getvalue())


if __name__ == "__main__":
    unittest.main()
