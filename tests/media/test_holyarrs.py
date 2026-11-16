import fcntl
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("holyarrs_provision", SOURCE / "holyarrs.py")
holyarrs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(holyarrs)


class FakeClient:
    def __init__(self):
        self.owner = None
        self.csrf = None
        self.keys = {}
        self.next_id = 1
        self.setup_open = True
        self.skip_local = True
        self.calls = []
        self.fail = None

    def ready(self):
        return {"needs_setup": self.owner is None}

    def call(self, method, path, body=None, key=None):
        self.calls.append((method, path))
        if (method, path) == self.fail:
            raise holyarrs.ApiError(503)
        if method == "POST" and path in ("/auth/setup", "/auth/login"):
            if path == "/auth/setup":
                if self.owner is not None:
                    raise holyarrs.ApiError(409)
                self.owner = dict(body)
            if body != self.owner:
                raise holyarrs.ApiError(401)
            return {"csrf": "test-csrf"}
        if self.csrf != "test-csrf":
            raise holyarrs.ApiError(403)
        if path == "/auth/me":
            if key is not None and key not in [item["key"] for item in self.keys.values()]:
                raise holyarrs.ApiError(401)
            return {"id": 1, "name": self.owner["name"], "role": "owner", "via": "api_key" if key else "session", "setup_open": self.setup_open}
        if path == "/auth/keys" and method == "GET":
            return {"keys": [{k: v for k, v in item.items() if k != "key"} for item in self.keys.values()]}
        if path == "/auth/keys" and method == "POST":
            item = dict(body, id=self.next_id, key="hak_fixture_" + str(self.next_id))
            self.keys[self.next_id] = item
            self.next_id += 1
            return dict(item)
        if method == "DELETE" and path.startswith("/auth/keys/"):
            del self.keys[int(path.rsplit("/", 1)[1])]
            return {}
        if path == "/auth/setup/done":
            self.setup_open = False
            return {"done": True}
        if path == "/auth/settings":
            if method == "PUT":
                self.skip_local = body["skip_login_local_network"]
            return {"skip_login_local_network": self.skip_local}
        if path == "/auth/logout":
            return {}
        raise AssertionError((method, path))


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.state = self.root / "provision"
        self.client = FakeClient()

    def run_bootstrap(self):
        holyarrs.bootstrap(self.client, self.state)

    def test_fresh_and_repeated_identity(self):
        self.run_bootstrap()
        paths = list(self.state.glob("*.json"))
        before = {p: (p.read_bytes(), p.stat().st_ino) for p in paths}
        self.run_bootstrap()
        self.assertEqual(before, {p: (p.read_bytes(), p.stat().st_ino) for p in paths})
        self.assertEqual(len(self.client.keys), 1)
        self.assertFalse(self.client.setup_open)
        self.assertFalse(self.client.skip_local)
        self.assertEqual(self.client.calls.count(("POST", "/auth/setup")), 1)
        self.assertEqual(self.client.calls.count(("POST", "/auth/keys")), 1)
        self.assertIsNone(self.client.csrf)
        self.assertFalse((self.state / "api-intent.json").exists())
        for path in self.state.iterdir():
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.state.stat().st_mode & 0o777, 0o700)

    def test_unmanaged_owner_refused(self):
        self.client.owner = {"name": "existing", "password": "do-not-replace"}
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()
        self.assertEqual(self.client.calls, [])
        self.assertFalse((self.state / "owner.json").exists())

    def test_unmapped_configuration_refused_without_owner_creation(self):
        with patch.object(self.client, "ready", return_value={"needs_setup": True, "config_unmapped": True}):
            with self.assertRaises(holyarrs.ProvisionError):
                self.run_bootstrap()
        self.assertFalse((self.state / "owner.json").exists())
        self.assertEqual(self.client.calls, [])

    def test_uncertain_owner_creation_recovers_without_reset(self):
        original = self.client.call
        def lost_response(method, path, body=None, key=None):
            result = original(method, path, body, key)
            if path == "/auth/setup":
                raise holyarrs.ApiError()
            return result
        with patch.object(self.client, "call", side_effect=lost_response):
            with self.assertRaises(holyarrs.ApiError):
                self.run_bootstrap()
        owner = (self.state / "owner.json").read_bytes()
        self.run_bootstrap()
        self.assertEqual(owner, (self.state / "owner.json").read_bytes())
        self.assertEqual(self.client.calls.count(("POST", "/auth/setup")), 1)

    def test_lost_key_response_recovers_only_managed_orphan(self):
        original = self.client.call
        def lost_response(method, path, body=None, key=None):
            result = original(method, path, body, key)
            if (method, path) == ("POST", "/auth/keys"):
                raise holyarrs.ApiError()
            return result
        with patch.object(self.client, "call", side_effect=lost_response):
            with self.assertRaises(holyarrs.ApiError):
                self.run_bootstrap()
        self.client.keys[99] = {"id": 99, "label": "someone-else", "scopes": ["read"], "key": "hak_other"}
        self.run_bootstrap()
        self.assertEqual(set(self.client.keys), {2, 99})
        self.assertIn(("DELETE", "/auth/keys/1"), self.client.calls)
        self.assertNotIn(("DELETE", "/auth/keys/99"), self.client.calls)

    def test_saved_key_with_pending_intent_is_not_recreated(self):
        self.run_bootstrap()
        holyarrs.atomic_json(self.state / "api-intent.json", {"label": holyarrs.LABEL})
        self.run_bootstrap()
        self.assertEqual(len(self.client.keys), 1)
        self.assertFalse((self.state / "api-intent.json").exists())

    def test_missing_established_key_requires_restore(self):
        self.run_bootstrap()
        (self.state / "api-key.json").unlink()
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()
        self.assertEqual(len(self.client.keys), 1)
        self.assertNotIn(("DELETE", "/auth/keys/1"), self.client.calls)

    def test_invalid_saved_key_is_not_rotated(self):
        self.run_bootstrap()
        self.client.keys[1]["key"] = "hak_changed"
        with self.assertRaises(holyarrs.ApiError):
            self.run_bootstrap()
        self.assertEqual(len(self.client.keys), 1)

    def test_wrong_key_scope_refused(self):
        self.run_bootstrap()
        self.client.keys[1]["scopes"] = ["read"]
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()

    def test_duplicate_managed_label_refused(self):
        self.run_bootstrap()
        self.client.keys[2] = dict(self.client.keys[1], id=2, key="hak_other")
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()
        self.assertEqual(len(self.client.keys), 2)

    def test_malformed_intent_refused_before_api_calls(self):
        self.run_bootstrap()
        self.client.calls.clear()
        holyarrs.atomic_json(self.state / "api-intent.json", {"label": "another"})
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()
        self.assertEqual(self.client.calls, [])

    def test_authentication_bypass_reconciles_on_repeat(self):
        self.run_bootstrap()
        self.client.skip_local = True
        self.run_bootstrap()
        self.assertFalse(self.client.skip_local)
        self.assertEqual(len(self.client.keys), 1)

    def test_database_loss_does_not_recreate_owner(self):
        self.run_bootstrap()
        self.client.owner = None
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()
        self.assertEqual(self.client.calls.count(("POST", "/auth/setup")), 1)

    def test_mutation_is_not_blindly_retried(self):
        self.client.fail = ("POST", "/auth/keys")
        with self.assertRaises(holyarrs.ApiError):
            self.run_bootstrap()
        self.assertEqual(self.client.calls.count(self.client.fail), 1)
        self.assertEqual(self.client.calls[-1], ("POST", "/auth/logout"))

    def test_identity_and_auth_method_checks(self):
        for changes in ({"role": "manager"}, {"name": "another"}, {"id": 2}, {"via": "local_network"}):
            with self.subTest(changes=changes):
                who = dict(id=1, role="owner", name="media-admin", via="api_key")
                who.update(changes)
                with self.assertRaises(holyarrs.ProvisionError):
                    holyarrs.require_identity(who, {"name": "media-admin"}, 1, via="api_key")

    def test_unsafe_state_and_symlink_refused(self):
        self.state.mkdir(mode=0o755)
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()
        self.state.rmdir()
        self.state.symlink_to(self.root)
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()

    def test_unsafe_or_symlinked_owner_seed_refused(self):
        self.run_bootstrap()
        owner = self.state / "owner.json"
        owner.chmod(0o644)
        with self.assertRaises(holyarrs.ProvisionError):
            self.run_bootstrap()
        owner.unlink()
        owner.symlink_to(self.state / "api-key.json")
        with self.assertRaises(OSError):
            self.run_bootstrap()

    def test_concurrent_run_refused(self):
        self.run_bootstrap()
        with (self.state / ".provision.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises(BlockingIOError):
                self.run_bootstrap()

    def test_cli_redacts_invalid_state(self):
        self.state.mkdir(mode=0o700)
        marker = "private-owner-seed-do-not-print"
        (self.state / "owner.json").write_text(marker)
        (self.state / "owner.json").chmod(0o600)
        result = subprocess.run([sys.executable, "-B", str(SOURCE / "holyarrs.py"), "--endpoint", "http://127.0.0.1:12345", "--state-dir", str(self.state)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertNotIn(marker, result.stderr + result.stdout)
        self.assertNotIn("Traceback", result.stderr)


class HttpTests(unittest.TestCase):
    def server(self, handler):
        server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
        thread = threading.Thread(target=lambda: server.serve_forever(poll_interval=0.01), daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        return f"http://127.0.0.1:{server.server_port}"

    def test_non_loopback_and_ambiguous_endpoints_refused(self):
        for value in ("https://127.0.0.1:6262", "http://localhost:6262", "http://example.com:6262", "http://127.0.0.1", "http://127.0.0.1:6262/path", "http://user@127.0.0.1:6262", "http://127.0.0.1:6262?x=1"):
            with self.subTest(value=value), self.assertRaises(holyarrs.ProvisionError):
                holyarrs.Client(value)

    def test_redirects_refused(self):
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass
            def do_GET(self):
                self.send_response(302)
                self.send_header("Location", "http://example.com/")
                self.end_headers()
        client = holyarrs.Client(self.server(Handler))
        with self.assertRaises(holyarrs.ApiError):
            client.call("GET", "/auth/state")

    def test_headers_cookie_and_proxy_environment(self):
        received = []
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass
            def do_GET(self):
                received.append(dict(self.headers))
                self.send_response(200)
                self.send_header("Set-Cookie", "holyarrs_session=fixture; Path=/; HttpOnly")
                self.end_headers()
                self.wfile.write(b'{}')
        endpoint = self.server(Handler)
        with patch.dict(os.environ, {"http_proxy": "http://127.0.0.1:1", "no_proxy": ""}):
            client = holyarrs.Client(endpoint)
            client.call("GET", "/auth/state")
            client.csrf = "fixture-csrf"
            client.call("GET", "/auth/me", key="hak_fixture")
        self.assertEqual(received[1]["Cookie"], "holyarrs_session=fixture")
        self.assertEqual(received[1]["X-Csrf-Token"], "fixture-csrf")
        self.assertEqual(received[1]["X-Api-Key"], "hak_fixture")
        self.assertEqual(received[1]["Origin"], endpoint)

    def test_readiness_retries_are_bounded(self):
        client = holyarrs.Client("http://127.0.0.1:6262")
        with patch.object(client, "call", side_effect=holyarrs.ApiError(503)) as call, patch.object(holyarrs.time, "sleep"):
            with self.assertRaises(holyarrs.ApiError):
                client.ready()
        self.assertEqual(call.call_count, 30)
        with patch.object(client, "call", side_effect=holyarrs.ApiError(403)) as call:
            with self.assertRaises(holyarrs.ApiError):
                client.ready()
        self.assertEqual(call.call_count, 1)


if __name__ == "__main__":
    unittest.main()
