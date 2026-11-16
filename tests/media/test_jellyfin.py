import copy
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("media_jellyfin", SOURCE / "jellyfin.py")
jellyfin = importlib.util.module_from_spec(spec)
spec.loader.exec_module(jellyfin)


class FakeClient:
    def __init__(self):
        self.completed = False
        self.users = {}
        self.libraries = []
        self.calls = []
        self.token = None

    def ready(self):
        return {"StartupWizardCompleted": self.completed}

    def startup_ready(self):
        return {"UICulture": "en-US"}

    def call(self, method, path, body=None, headers=None):
        self.calls.append((method, path, copy.deepcopy(body)))
        if path == "/System/Info/Public":
            return {"StartupWizardCompleted": self.completed}
        if path == "/Startup/Configuration":
            return None
        if path == "/Startup/User":
            if method == "GET":
                return {"Name": "default"}
            self.users[body["Name"]] = {"name": body["Name"], "password": body["Password"], "admin": True}
            return None
        if path == "/Startup/Complete":
            self.completed = True
            return None
        if path == "/Library/VirtualFolders" and method == "GET":
            return copy.deepcopy(self.libraries)
        if path.startswith("/Library/VirtualFolders?"):
            from urllib.parse import parse_qs, urlsplit
            query = parse_qs(urlsplit(path).query)
            self.libraries.append({"Name": query["name"][0], "Locations": query["paths"], "CollectionType": query["collectionType"][0]})
            return None
        raise AssertionError("unexpected request " + path)

    def login(self, name, password):
        stored = self.users.get(name)
        if stored is None or stored["password"] != password:
            raise jellyfin.ProvisionError("Jellyfin login did not return the expected identity")
        self.token = "token"
        return {"Name": name, "Policy": {"IsAdministrator": True}}


class ProvisionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name)
        self.state.chmod(0o700)
        self.client = FakeClient()

    def test_fresh_instance_completes_wizard_and_creates_libraries(self):
        jellyfin.reconcile(self.client, self.state)
        seed = json.loads((self.state / "admin.json").read_text())
        self.assertEqual(seed["name"], "media-admin")
        self.assertGreaterEqual(len(seed["password"]), 16)
        self.assertTrue(self.client.completed)
        self.assertEqual({row["Name"] for row in self.client.libraries}, {"Movies", "TV Shows"})
        calls = [(method, path) for method, path, _ in self.client.calls]
        self.assertLess(calls.index(("GET", "/Startup/User")), calls.index(("POST", "/Startup/User")))

    def test_repeat_is_stable(self):
        jellyfin.reconcile(self.client, self.state)
        before = copy.deepcopy(self.client.libraries)
        content = (self.state / "admin.json").read_bytes()
        self.client.calls.clear()
        jellyfin.reconcile(self.client, self.state)
        self.assertEqual(self.client.libraries, before)
        self.assertEqual((self.state / "admin.json").read_bytes(), content)
        self.assertFalse(any(method == "POST" and path.startswith("/Library") for method, path, _ in self.client.calls))

    def test_existing_unmanaged_instance_is_refused(self):
        self.client.completed = True
        with self.assertRaises(jellyfin.ProvisionError):
            jellyfin.reconcile(self.client, self.state)
        self.assertTrue(all(method == "GET" for method, _, _ in self.client.calls))
        self.assertFalse((self.state / "admin.json").exists())

    def test_changed_library_location_is_refused(self):
        jellyfin.reconcile(self.client, self.state)
        self.client.libraries[0]["Locations"] = ["/elsewhere"]
        with self.assertRaises(jellyfin.ProvisionError):
            jellyfin.reconcile(self.client, self.state)

    def test_duplicate_library_is_refused(self):
        jellyfin.reconcile(self.client, self.state)
        self.client.libraries.append(copy.deepcopy(self.client.libraries[0]))
        with self.assertRaises(jellyfin.ProvisionError):
            jellyfin.reconcile(self.client, self.state)

    def test_bad_seed_is_refused(self):
        (self.state / "admin.json").write_text('{"name": "media-admin", "password": "short"}')
        (self.state / "admin.json").chmod(0o600)
        with self.assertRaises(jellyfin.ProvisionError):
            jellyfin.reconcile(self.client, self.state)

    def test_state_directory_must_be_private(self):
        self.state.chmod(0o755)
        with self.assertRaises(jellyfin.ProvisionError):
            jellyfin.provision(self.client, self.state)


if __name__ == "__main__":
    unittest.main()
