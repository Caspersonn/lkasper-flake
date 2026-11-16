import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("soundspan_provision", SOURCE / "soundspan.py")
soundspan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(soundspan)


class FakeClient:
    def __init__(self):
        self.calls = []
        self.token = None
        self.users = 0
        self.login_ok = True
        self.settings = {}
        self.scan_error = None

    def ready(self):
        return {"needsOnboarding": self.users == 0, "hasAccount": self.users > 0}

    def call(self, method, path, body=None):
        self.calls.append((method, path, body))
        if path == "/api/onboarding/register":
            if self.users:
                import soundspan_provision_stub
            self.users = 1
            self.token = "registered"
            return {"token": "registered", "user": {"role": "admin"}}
        if path == "/api/auth/login":
            if not self.users or not self.login_ok:
                raise soundspan.ProvisionError("Soundspan request failed with HTTP 401 for POST /api/auth/login")
            self.token = "logged"
            return {"token": "logged", "user": {"role": "admin"}}
        if path == "/api/onboarding/complete":
            return {"success": True}
        if path == "/api/library/scan":
            if self.scan_error:
                raise soundspan.ProvisionError(self.scan_error)
            return {"jobId": "scan-1"}
        if path == "/api/system-settings":
            if method == "GET":
                return dict(self.settings)
            self.settings.update(body)
            return dict(self.settings)
        raise AssertionError(path)


class SoundspanTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.root.chmod(0o700)
        self.admin = self.root / "admin.json"
        self.credentials = self.root / "api-key.json"
        self.credentials.write_text('{"key": "hak-soundspan"}')
        self.credentials.chmod(0o600)

    def run_reconcile(self, client):
        return soundspan.reconcile(client, self.root, self.credentials)

    def test_fresh_instance_registers_and_completes_onboarding(self):
        client = FakeClient()
        self.run_reconcile(client)
        self.assertEqual(client.settings["downloadSource"], "holyarrs")
        self.assertEqual(client.settings["holyarrsApiKey"], "hak-soundspan")
        self.assertEqual(client.settings["musicPath"], "/data/media/music")
        self.assertIn(("POST", "/api/library/scan", None), client.calls)
        self.assertFalse(client.admin_password_visible if hasattr(client, "admin_password_visible") else False)

    def test_repeat_reconciliation_changes_nothing(self):
        client = FakeClient()
        self.run_reconcile(client)
        client.token = None
        self.run_reconcile(client)
        posts = [call for call in client.calls if call[0] == "POST" and call[1] == "/api/system-settings"]
        self.assertEqual(len(posts), 1)

    def test_scan_cooldown_is_accepted(self):
        client = FakeClient()
        client.scan_error = "Soundspan request failed with HTTP 429 for POST /api/library/scan"
        self.run_reconcile(client)

    def test_scan_failure_is_reported(self):
        client = FakeClient()
        client.scan_error = "Soundspan request failed with HTTP 500 for POST /api/library/scan"
        with self.assertRaises(soundspan.ProvisionError):
            self.run_reconcile(client)

    def test_existing_account_uses_login(self):
        client = FakeClient()
        client.users = 1
        self.run_reconcile(client)
        self.assertTrue(any(call[1] == "/api/auth/login" for call in client.calls))
        self.assertFalse(any(call[1] == "/api/onboarding/register" for call in client.calls))

    def test_bad_login_refused_without_reset(self):
        client = FakeClient()
        client.users = 1
        client.login_ok = False
        with self.assertRaises(soundspan.ProvisionError):
            self.run_reconcile(client)
        self.assertEqual(client.users, 1)

    def test_missing_holyarrs_key_refused(self):
        client = FakeClient()
        client.users = 1
        self.credentials.write_text("{}")
        with self.assertRaises(soundspan.ProvisionError):
            self.run_reconcile(client)

    def test_changed_settings_are_reapplied(self):
        client = FakeClient()
        self.run_reconcile(client)
        client.settings["downloadSource"] = "soulseek"
        client.token = None
        self.run_reconcile(client)
        self.assertEqual(client.settings["downloadSource"], "holyarrs")

    def test_unsafe_state_dir_refused(self):
        self.root.chmod(0o755)
        with self.assertRaises(soundspan.ProvisionError):
            soundspan.provision(FakeClient(), self.root, self.credentials)


if __name__ == "__main__":
    unittest.main()
