import importlib.util
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import tempfile


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("holyarrs_provision", SOURCE / "holyarrs.py")
holyarrs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(holyarrs)
IMAGE = "holyarrs/holyarrs:1.0.19"


def docker(*args):
    return subprocess.check_output(["docker", *args], stderr=subprocess.PIPE, text=True, timeout=90).strip()


def main():
    name = "opencode-holyarrs-bootstrap-" + secrets.token_hex(6)
    with tempfile.TemporaryDirectory(prefix="holyarrs-bootstrap-", dir="/tmp/opencode") as directory:
        config = Path(directory)
        state = config / "provision"
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        endpoint = f"http://127.0.0.1:{port}"
        try:
            docker("run", "-d", "--name", name, "--network", "host", "--env", f"PUID={os.getuid()}", "--env", f"PGID={os.getgid()}", "--env", f"HOLYARRS_HEALTH_URL={endpoint}", "--mount", f"type=bind,src={config},dst=/config", IMAGE, "-config", "/config", "-addr", f"127.0.0.1:{port}")
            client = holyarrs.Client(endpoint)
            original = client.call
            lost_ids = []
            lost_keys = []
            def lose_response(method, path, body=None, key=None):
                result = original(method, path, body, key)
                if (method, path) == ("POST", "/auth/keys"):
                    lost_ids.append(result["id"])
                    lost_keys.append(result["key"])
                    raise holyarrs.ApiError()
                return result
            client.call = lose_response
            try:
                holyarrs.bootstrap(client, state)
            except holyarrs.ApiError:
                pass
            else:
                raise AssertionError("Injected lost response was not observed")
            assert len(lost_ids) == 1
            assert (state / "api-intent.json").exists()
            assert not (state / "api-key.json").exists()
            holyarrs.bootstrap(holyarrs.Client(endpoint), state)
            stored = json.loads((state / "api-key.json").read_text())
            assert stored["key"] != lost_keys[0]
            try:
                holyarrs.Client(endpoint).call("GET", "/auth/me", key=lost_keys[0])
            except holyarrs.ApiError as error:
                assert error.status == 401
            else:
                raise AssertionError("Orphan key was not revoked")
            keys = holyarrs.Client(endpoint).call("GET", "/auth/keys", key=stored["key"])["keys"]
            assert len(keys) == 1 and keys[0]["id"] == stored["id"]
            settings = holyarrs.Client(endpoint).call("GET", "/auth/settings", key=stored["key"])
            assert settings["skip_login_local_network"] is False
            try:
                holyarrs.Client(endpoint).call("GET", "/auth/me")
            except holyarrs.ApiError as error:
                assert error.status == 401
            else:
                raise AssertionError("Unauthenticated loopback client accepted")
            docker("exec", name, "/holyarrs", "-healthcheck")
            assert not (state / "api-intent.json").exists()
            before = {p.name: p.read_bytes() for p in state.glob("*.json")}
            holyarrs.bootstrap(holyarrs.Client(endpoint), state)
            docker("restart", name)
            holyarrs.bootstrap(holyarrs.Client(endpoint), state)
            assert before == {p.name: p.read_bytes() for p in state.glob("*.json")}
            who = holyarrs.Client(endpoint).call("GET", "/auth/me", key=stored["key"])
            assert who["name"] == "media-admin" and who["role"] == "owner" and who["via"] == "api_key" and who["setup_open"] is False
            keys = holyarrs.Client(endpoint).call("GET", "/auth/keys", key=stored["key"])["keys"]
            assert len(keys) == 1 and keys[0]["id"] == stored["id"]
            logs = docker("logs", name)
            owner = json.loads((state / "owner.json").read_text())
            assert owner["password"] not in logs and stored["key"] not in logs
            for path in state.iterdir():
                assert path.stat().st_mode & 0o077 == 0
            print("Pinned-container bootstrap, orphan recovery, repeat provisioning, restart, API identity and log redaction passed.")
            print("Image: " + docker("inspect", "--format", "{{.Image}}", name))
        finally:
            subprocess.run(["docker", "rm", "-f", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)


if __name__ == "__main__":
    main()
