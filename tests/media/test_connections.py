import copy
import contextlib
import fcntl
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("media_connections", SOURCE / "connections.py")
connections = importlib.util.module_from_spec(spec)
spec.loader.exec_module(connections)


class FakeClient:
    def __init__(self):
        self.data = {"library-folders": [], "sources": [], "downloaders": []}
        self.calls = []
        self.lost = False
        self.healthy = True
        self.folder_health = "ok"

    def ready(self):
        return {}

    def call(self, method, path, body=None, key=None):
        self.calls.append((method, path, copy.deepcopy(body)))
        parts = path.strip("/").split("/")
        group = parts[0]
        rows = self.data[group]
        if method == "GET":
            return {"library_folders" if group == "library-folders" else group: copy.deepcopy(rows)}
        if len(parts) == 3:
            if parts[2] == "test":
                return {"ok": self.healthy}
            found = next(item for item in rows if item["id"] == int(parts[1]))
            return {**found, "health": self.folder_health}
        if method == "POST":
            found = {"id": max([item["id"] for item in rows] + [0]) + 1, **copy.deepcopy(body)}
            rows.append(found)
        else:
            found = next(item for item in rows if item["id"] == int(parts[1]))
            found.update(copy.deepcopy(body))
        if self.lost and group == "sources":
            self.lost = False
            raise connections.ProvisionError("lost mutation response")
        return copy.deepcopy(found)


class ConnectionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.root.chmod(0o700)
        self.journal = self.root / "connections.json"
        self.settings = json.loads((SOURCE / "connections-settings.json").read_text())
        self.keys = {"holyarrs": {"id": 1, "label": "nixos-media-provision", "scopes": ["all"], "key": "hak_fixture"}, "jackett": {"APIKey": "jackett-fixture"}, "decypharr": {"token_only": True, "api_token": "decypharr-fixture"}}
        self.client = FakeClient()

    def run_reconcile(self):
        return connections.reconcile(self.client, self.settings, self.keys, self.journal)

    def test_fresh_repeat_stable_ids_and_journal_without_mutations(self):
        self.run_reconcile()
        before = copy.deepcopy(self.client.data)
        content = self.journal.read_bytes()
        inode = self.journal.stat().st_ino
        self.client.calls.clear()
        self.run_reconcile()
        self.assertEqual(self.client.data, before)
        self.assertEqual(self.journal.read_bytes(), content)
        self.assertEqual(self.journal.stat().st_ino, inode)
        self.assertFalse(any(method == "PUT" or (method == "POST" and path.count("/") == 1) for method, path, _ in self.client.calls))
        self.assertEqual([len(values) for values in self.client.data.values()], [3, 2, 1])

    def test_credentials_only_at_runtime_and_private_journal(self):
        self.run_reconcile()
        text = self.journal.read_text()
        self.assertNotIn("jackett-fixture", text)
        self.assertNotIn("decypharr-fixture", text)
        self.assertNotIn("hak_fixture", text)
        self.assertEqual(self.journal.stat().st_mode & 0o777, 0o600)
        downloader = self.client.data["downloaders"][0]
        self.assertEqual(downloader["username"], "media")
        self.assertEqual(downloader["category_music"], "holyarrs-music")
        self.assertFalse(downloader["clear_finished"])

    def test_secret_rotation_preserves_identity(self):
        self.run_reconcile()
        ids = [item["id"] for item in self.client.data["sources"]]
        self.keys["jackett"]["APIKey"] = "rotated"
        self.run_reconcile()
        self.assertEqual(ids, [item["id"] for item in self.client.data["sources"]])
        self.assertTrue(all(item["api_key"] == "rotated" for item in self.client.data["sources"]))

    def test_unrelated_state_and_unknown_settings_preserved(self):
        self.run_reconcile()
        self.client.data["sources"].append({"id": 900, "name": "unmanaged", "url": "https://example.com"})
        self.client.data["downloaders"][0]["unknown"] = "keep"
        self.client.data["sources"][0]["priority"] = 20
        self.run_reconcile()
        self.assertEqual(self.client.data["downloaders"][0]["unknown"], "keep")
        self.assertEqual(self.client.data["sources"][-1]["name"], "unmanaged")
        self.assertEqual(self.client.data["sources"][0]["priority"], 1)

    def test_lost_source_response_recovers_without_duplicate(self):
        self.client.lost = True
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()
        self.run_reconcile()
        self.assertEqual(len(self.client.data["sources"]), 2)

    def test_changed_host_refused_without_sending_secret(self):
        self.run_reconcile()
        self.client.data["sources"][0]["url"] = "https://elsewhere.example"
        self.client.calls.clear()
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()
        self.assertFalse(any(path.startswith("/sources") and method in ("POST", "PUT") for method, path, _ in self.client.calls))

    def test_duplicate_managed_source_refused(self):
        self.run_reconcile()
        self.client.data["sources"].append({**self.client.data["sources"][0], "id": 20})
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()

    def test_changed_folder_kind_refused(self):
        self.run_reconcile()
        self.client.data["library-folders"][0]["kind"] = "music"
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()

    def test_bad_library_health_refused(self):
        for health in ("read_only", "missing", "no_hardlink"):
            self.client.folder_health = health
            with self.assertRaises(connections.ProvisionError):
                self.run_reconcile()

    def test_changed_or_missing_saved_identity_refused(self):
        self.run_reconcile()
        self.client.data["sources"][0]["id"] = 100
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()
        self.client.data["sources"].clear()
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()

    def test_native_connection_failure_is_visible_and_retry_preserves_ids(self):
        self.client.healthy = False
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()
        self.client.healthy = True
        self.run_reconcile()
        self.assertEqual(len(self.client.data["sources"]), 2)

    def test_bad_or_unsafe_journal_refused(self):
        self.journal.write_text('{}')
        self.journal.chmod(0o600)
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()
        self.journal.chmod(0o644)
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()

    def test_invalid_credentials_do_not_write(self):
        self.keys["decypharr"]["token_only"] = False
        with self.assertRaises(connections.ProvisionError):
            self.run_reconcile()
        self.assertEqual(self.client.calls, [])
        self.assertFalse(self.journal.exists())

    def test_concurrent_provision_refused_before_api_calls(self):
        lock_path = self.root / ".connections.lock"
        with lock_path.open("w") as lock:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises(BlockingIOError):
                connections.provision(self.client, self.settings, {}, self.root)
        self.assertEqual(self.client.calls, [])

    def test_cli_error_redaction(self):
        output = io.StringIO()
        argv = ["connections", "--endpoint", "http://127.0.0.1:6263", "--settings", str(SOURCE / "connections-settings.json"), "--credentials-dir", str(self.root), "--state-dir", str(self.root)]
        with patch.object(sys, "argv", argv), patch.object(connections, "provision", side_effect=connections.ProvisionError("fixture-secret")), contextlib.redirect_stderr(output):
            self.assertEqual(connections.main(), 1)
        self.assertNotIn("fixture-secret", output.getvalue())
        self.assertNotIn("Traceback", output.getvalue())


if __name__ == "__main__":
    unittest.main()
