import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"))

from decypharr import ProvisionError, atomic_json
import remux


class FakeClient:
    def __init__(self):
        self.completed = False
        self.isolated = True
        self.admin = True
        self.ignore_config = False
        self.config = {"P2pEnabled": True, "ServerName": "Remux", "DefaultWebClient": "jellyfin", "Unmanaged": "preserved"}
        self.calls = []
        self.token = None
        self.addons = []
        self.ignore_source = False

    def require_isolation(self):
        if not self.isolated:
            raise ProvisionError("not isolated")

    def call(self, method, path, body=None):
        self.calls.append((method, path, copy.deepcopy(body)))
        if path == "/system/info/public":
            return {"StartupWizardCompleted": self.completed}
        if path == "/startup/user":
            self.name = body["Name"]
            self.password = body["Password"]
            return None
        if path == "/users/authenticatebyname":
            if body != {"Username": self.name, "Pw": self.password}:
                raise ProvisionError("invalid authentication")
            return {"AccessToken": "fixture-token", "User": {"Name": self.name, "Policy": {"IsAdministrator": self.admin}}}
        if path == "/system/configuration":
            if method == "POST" and not self.ignore_config:
                self.config = copy.deepcopy(body)
            return copy.deepcopy(self.config)
        if path == "/startup/complete":
            if self.config["P2pEnabled"]:
                raise AssertionError("completed before P2P was disabled")
            self.completed = True
            return None
        if path == "/addons":
            if method == "POST":
                self.addons.append({"id": "fixture-source", "kind": body["preset"]["kind"], "config": body["preset"]["config"], "name": body["name"], "enabled": True, "isDefault": True, "httpRedirectStream": False})
            return copy.deepcopy(self.addons)
        if path == "/addons/fixture-source":
            if not self.ignore_source:
                self.addons[0].update(copy.deepcopy(body))
            return None
        raise AssertionError((method, path))


class RemuxTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name) / "provision"
        self.client = FakeClient()

    def provision(self):
        remux.provision(self.client, self.state)

    def test_fresh_bootstrap_and_repeat_preserve_seed_and_unmanaged_settings(self):
        self.provision()
        seed = (self.state / "admin.json").read_bytes()
        self.assertEqual((self.state / "admin.json").stat().st_mode & 0o777, 0o600)
        self.assertFalse(self.client.config["P2pEnabled"])
        self.assertEqual(self.client.config["DefaultWebClient"], "remux")
        self.assertEqual(self.client.config["Unmanaged"], "preserved")
        self.client.calls.clear()
        self.provision()
        self.assertEqual((self.state / "admin.json").read_bytes(), seed)
        self.assertFalse(any(method == "POST" and path != "/users/authenticatebyname" for method, path, _ in self.client.calls))

    def test_refuses_network_before_creating_credentials(self):
        self.client.isolated = False
        with self.assertRaises(ProvisionError):
            self.provision()
        self.assertFalse(self.state.exists())
        self.assertEqual(self.client.calls, [])

    def test_refuses_completed_unmanaged_instance(self):
        self.client.completed = True
        with self.assertRaises(ProvisionError):
            self.provision()
        self.assertFalse((self.state / "admin.json").exists())

    def test_configuration_failure_does_not_complete_setup(self):
        self.client.ignore_config = True
        with self.assertRaises(ProvisionError):
            self.provision()
        self.assertFalse(self.client.completed)

    def test_interrupted_setup_reuses_protected_seed(self):
        self.client.ignore_config = True
        with self.assertRaises(ProvisionError):
            self.provision()
        seed = (self.state / "admin.json").read_bytes()
        self.client.ignore_config = False
        self.provision()
        self.assertEqual((self.state / "admin.json").read_bytes(), seed)
        self.assertTrue(self.client.completed)

    def test_repairs_p2p_drift_without_recreating_admin(self):
        self.provision()
        self.client.config["P2pEnabled"] = True
        self.client.calls.clear()
        self.provision()
        self.assertFalse(self.client.config["P2pEnabled"])
        self.assertFalse(any(path == "/startup/user" for _, path, _ in self.client.calls))

    def test_refuses_non_admin(self):
        self.client.admin = False
        with self.assertRaises(ProvisionError):
            self.provision()
        self.assertFalse(any(path == "/system/configuration" for _, path, _ in self.client.calls))

    def test_refuses_public_credentials(self):
        self.state.mkdir(mode=0o700)
        atomic_json(self.state / "admin.json", {"name": "casper", "password": "fixture-password"})
        (self.state / "admin.json").chmod(0o644)
        with self.assertRaises(ProvisionError):
            self.provision()

    def test_container_validation_and_isolation_inspection(self):
        for name in ("other", "remux-../x", "remux-fixture\n", "remux-X"):
            with self.subTest(name=name), self.assertRaises(ProvisionError):
                remux.Client(name)
        client = remux.Client("remux-fixture")
        with patch.object(remux.subprocess, "run") as run:
            run.return_value.returncode = 0
            run.return_value.stdout = "bridge\n"
            with self.assertRaises(ProvisionError):
                client.require_isolation()
            run.return_value.stdout = "none\n"
            client.require_isolation()

    def test_transport_holds_credentials_in_stdin_not_arguments(self):
        client = remux.Client("remux-fixture")
        client.token = "fixture-private-token"
        with patch.object(remux.subprocess, "run") as run:
            run.return_value.returncode = 0
            run.return_value.stdout = '{"status":200,"body":{}}'
            client.call("POST", "/users/authenticatebyname", {"Pw": "fixture-private-password"})
            arguments = run.call_args
            self.assertNotIn("fixture-private", repr(arguments.args))
            body = json.loads(arguments.kwargs["input"])
            self.assertIn('Token="fixture-private-token"', body["headers"]["Authorization"])

    def source(self, manifest="https://aiostreams.example/private/manifest.json"):
        credential = Path(self.temp.name) / "source.json"
        atomic_json(credential, {"manifest_url": manifest})
        remux.provision(self.client, self.state, credential)

    def test_source_converges_and_preserves_journal_on_repeat(self):
        self.provision()
        self.source()
        journal = (self.state / "source.json").read_bytes()
        self.client.calls.clear()
        self.source()
        self.assertEqual((self.state / "source.json").read_bytes(), journal)
        self.assertFalse(any(method == "POST" and path != "/users/authenticatebyname" for method, path, _ in self.client.calls))

    def test_source_refuses_p2p_before_fetching_manifest(self):
        self.provision()
        self.client.config["P2pEnabled"] = True
        self.client.calls.clear()
        with self.assertRaises(ProvisionError):
            self.source()
        self.assertFalse(any(path.startswith("/addons") for _, path, _ in self.client.calls))

    def test_source_refuses_unmanaged_reserved_name(self):
        self.provision()
        self.client.addons = [{"name": "Managed AIOStreams"}]
        with self.assertRaises(ProvisionError):
            self.source()
        self.assertFalse((self.state / "source.json").exists())

    def test_source_recovers_creation_intent_without_duplicate(self):
        self.provision()
        self.source()
        atomic_json(self.state / "source.json", {"creating": True})
        self.source()
        self.assertEqual(len(self.client.addons), 1)

    def test_source_rotation_and_failed_readback(self):
        self.provision()
        self.source()
        self.source("https://aiostreams.example/rotated/manifest.json")
        self.client.ignore_source = True
        with self.assertRaises(ProvisionError):
            self.source("https://aiostreams.example/third/manifest.json")

    def test_source_rejects_unsafe_manifests(self):
        self.provision()
        for manifest in ("http://aiostreams.example/manifest.json", "https://user:password@example.com/manifest.json", "https://example.com/not-manifest", "https://example.com/manifest.json#fragment"):
            with self.subTest(manifest=manifest), self.assertRaises(ProvisionError):
                self.source(manifest)


if __name__ == "__main__":
    unittest.main()
