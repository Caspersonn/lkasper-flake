import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("aurral_provision", SOURCE / "aurral.py")
aurral = importlib.util.module_from_spec(spec)
spec.loader.exec_module(aurral)


class FakeClient:
    def __init__(self):
        self.onboarding = True
        self.calls = []
        self.settings = {"unmanaged": "keep"}
        self.flows = []
        self.token = None
        self.login_user = {"id": 1, "username": "casper", "role": "admin"}
        self.ignore_settings = False
        self.fail_after_create = False

    def ready(self):
        return {"onboardingRequired": self.onboarding}

    def call(self, method, path, body=None):
        self.calls.append((method, path, copy.deepcopy(body)))
        if path == "/api/onboarding/complete":
            self.onboarding = False
            return {"success": True}
        if path == "/api/auth/login":
            return {"token": "fixture-token", "user": self.login_user}
        if path == "/api/settings":
            if method == "POST" and not self.ignore_settings:
                self.settings = aurral.merge(self.settings, body)
            return copy.deepcopy(self.settings)
        if path == "/api/playlists/status":
            return {"flows": copy.deepcopy(self.flows)}
        if path == "/api/playlists/flows":
            flow = dict(body, id=f"flow-{len(self.flows) + 1}", ownerUserId=1)
            self.flows.append(flow)
            if self.fail_after_create:
                self.fail_after_create = False
                raise aurral.ProvisionError("interrupted after create")
            return {"flow": copy.deepcopy(flow)}
        if path.startswith("/api/playlists/flows/") and method == "PUT":
            flow = next(flow for flow in self.flows if flow["id"] == path.rsplit("/", 1)[1])
            flow.update(copy.deepcopy(body))
            return {"flow": copy.deepcopy(flow)}
        raise AssertionError((method, path))


class AurralTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.root.chmod(0o700)
        self.credentials = self.root / "slskd.json"
        self.credentials.write_text(json.dumps({"api_key": "fixture-key-" * 4}))
        self.credentials.chmod(0o600)
        self.settings = json.loads((SOURCE / "aurral-settings.json").read_text())
        self.client = FakeClient()

    def reconcile(self):
        return aurral.provision(self.client, self.root, self.settings, self.credentials)

    def test_bootstrap_disables_fallbacks_before_creating_flows(self):
        self.reconcile()
        self.assertFalse(self.client.onboarding)
        self.assertEqual(len(self.client.flows), 2)
        self.assertTrue(all(flow["autoDownload"] for flow in self.client.flows))
        self.assertTrue(self.client.settings["subsonic"]["favoriteAutoKeep"])
        for source in ("lidarr", "prowlarr", "nzbget", "sabnzbd", "tidarr", "ytdlp", "deemix"):
            self.assertFalse(self.client.settings["integrations"][source]["enabled"])
        routes = [(method, path) for method, path, _ in self.client.calls]
        self.assertLess(routes.index(("POST", "/api/settings")), routes.index(("POST", "/api/playlists/flows")))
        onboarding = next(body for _, path, body in self.client.calls if path == "/api/onboarding/complete")
        self.assertNotIn("existingMusic", onboarding)
        self.assertEqual(self.client.settings["unmanaged"], "keep")
        self.assertEqual((self.root / "admin.json").stat().st_mode & 0o777, 0o600)

    def test_repeat_activation_preserves_credentials_and_unmanaged_flows(self):
        self.reconcile()
        seed = (self.root / "admin.json").read_bytes()
        self.client.flows.append({"id": "personal", "name": "Personal playlist", "ownerUserId": 1})
        self.client.calls.clear()
        self.reconcile()
        self.assertEqual((self.root / "admin.json").read_bytes(), seed)
        self.assertFalse(any(method in ("POST", "PUT") and path != "/api/auth/login" for method, path, _ in self.client.calls))
        self.assertEqual(self.client.flows[-1]["id"], "personal")

    def test_settings_and_recipe_drift_are_repaired(self):
        self.reconcile()
        self.client.settings["integrations"]["ytdlp"]["enabled"] = True
        self.client.flows[0]["size"] = 2
        self.reconcile()
        self.assertFalse(self.client.settings["integrations"]["ytdlp"]["enabled"])
        self.assertEqual(self.client.flows[0]["size"], 30)

    def test_slskd_key_rotation_preserves_accounts_flows_and_unmanaged_settings(self):
        self.reconcile()
        seed = (self.root / "admin.json").read_bytes()
        journal = (self.root / "flows.json").read_bytes()
        flow_ids = [flow["id"] for flow in self.client.flows]
        key = "rotated-fixture-key-" * 3
        self.credentials.write_text(json.dumps({"api_key": key}))
        self.client.calls.clear()
        self.reconcile()
        self.assertEqual(self.client.settings["integrations"]["slskd"]["apiKey"], key)
        self.assertEqual(self.client.settings["unmanaged"], "keep")
        self.assertEqual((self.root / "admin.json").read_bytes(), seed)
        self.assertEqual((self.root / "flows.json").read_bytes(), journal)
        self.assertEqual([flow["id"] for flow in self.client.flows], flow_ids)
        self.assertFalse(any(path == "/api/playlists/flows" for _, path, _ in self.client.calls))

    def test_corrupt_flow_journal_is_rejected_before_flow_mutation(self):
        for entry in (None, [], "flow-1", {"id": "../settings"}, {"id": "flow/1"}, {"id": "é"}, {"id": "x" * 129}, {"creating": False}, {"creating": True, "id": "flow-1"}):
            with self.subTest(entry=entry):
                aurral.atomic_json(self.root / "flows.json", {"managed": {"Managed Discover Weekly": entry}})
                self.client.calls.clear()
                with self.assertRaises(aurral.ProvisionError):
                    self.reconcile()
                self.assertFalse(any(path.startswith("/api/playlists/") for _, path, _ in self.client.calls))

    def test_existing_unmanaged_administrator_is_not_adopted(self):
        self.client.onboarding = False
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()
        self.assertFalse((self.root / "admin.json").exists())
        self.assertEqual(self.client.calls, [])

    def test_reserved_unmanaged_flow_is_not_overwritten(self):
        self.client.flows.append({"id": "personal", "name": "Managed Discover Weekly", "ownerUserId": 1})
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()
        self.assertEqual(len(self.client.flows), 1)
        self.assertFalse((self.root / "flows.json").exists())

    def test_interrupted_creation_recovers_without_duplicate(self):
        self.client.fail_after_create = True
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()
        self.reconcile()
        self.assertEqual(len(self.client.flows), 2)

    def test_changed_owner_is_not_overwritten(self):
        self.reconcile()
        self.client.flows[0]["ownerUserId"] = 2
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()

    def test_missing_managed_flow_requires_explicit_migration(self):
        self.reconcile()
        self.client.flows.pop(0)
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()

    def test_settings_must_converge_before_flow_creation(self):
        self.client.ignore_settings = True
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()
        self.assertEqual(self.client.flows, [])

    def test_synthetic_api_key_user_cannot_own_flows(self):
        self.client.login_user["id"] = 0
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()
        self.assertEqual(self.client.flows, [])

    def test_public_credentials_are_rejected(self):
        self.credentials.chmod(0o644)
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()

    def test_symlinked_seed_is_rejected(self):
        (self.root / "admin.json").symlink_to(self.credentials)
        with self.assertRaises(OSError):
            self.reconcile()

    def test_nonprivate_state_is_rejected(self):
        self.root.chmod(0o750)
        with self.assertRaises(aurral.ProvisionError):
            self.reconcile()

    def test_only_fixed_loopback_endpoint_is_allowed(self):
        for endpoint in ("https://127.0.0.1:3002", "http://localhost:3002", "http://127.0.0.1:3001", "http://user:password@127.0.0.1:3002", "http://127.0.0.1:3002/path"):
            with self.subTest(endpoint=endpoint), self.assertRaises(aurral.ProvisionError):
                aurral.Client(endpoint)


if __name__ == "__main__":
    unittest.main()
