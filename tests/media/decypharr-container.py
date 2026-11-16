import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
import decypharr
import holyarrs


def docker(*args):
    return subprocess.check_output(["docker", *args], stderr=subprocess.PIPE, text=True, timeout=90).strip()


def port():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main():
    suffix = secrets.token_hex(6)
    network = "opencode-decypharr-" + suffix
    decy = network
    holy = "opencode-decypharr-holyarrs-" + suffix
    names = [decy, holy]
    with tempfile.TemporaryDirectory(prefix="decypharr-container-", dir="/tmp/opencode") as directory:
        root = Path(directory)
        app = root / "decypharr"
        state = root / "holyarrs"
        state.mkdir(mode=0o700)
        data = root / "data"
        for child in ("debrid", "symlinks", "media/movies", "media/tv", "media/music"):
            (data / child).mkdir(mode=0o770, parents=True, exist_ok=True)
        credentials = root / "credential.json"
        decypharr.atomic_json(credentials, {"real_debrid_api_key": "fixture-not-a-real-debrid-key"})
        decy_port, holy_port = port(), port()
        fixture_settings = root / "settings.json"
        configuration = json.loads((SOURCE / "decypharr-settings.json").read_text())
        configuration.update(port=str(decy_port), bind_address="127.0.0.1")
        decypharr.atomic_json(fixture_settings, configuration)
        decypharr.provision(fixture_settings, credentials, app)
        token = json.loads((app / "auth.json").read_text())["api_token"]
        before = {name: json.loads((app / name).read_text()) for name in ("config.json", "auth.json")}
        endpoint = f"http://127.0.0.1:{holy_port}"
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
        try:
            docker("run", "-d", "--name", decy, "--network", "host", "--device", "/dev/fuse", "--cap-add", "SYS_ADMIN", "--security-opt", "apparmor=unconfined", "-e", f"PUID={os.getuid()}", "-e", f"PGID={os.getgid()}", "-e", "UMASK=002", "--mount", f"type=bind,src={app},dst=/app", "--mount", f"type=bind,src={data},dst=/data", "cy01/blackhole:v2.7.2")
            base = f"http://127.0.0.1:{decy_port}"
            for attempt in range(60):
                try:
                    request = urllib.request.Request(base + "/api/v2/auth/login", data=urllib.parse.urlencode({"username": "media", "password": token}).encode())
                    with opener.open(request, timeout=2) as response:
                        assert response.read() == b"Ok."
                    break
                except (urllib.error.URLError, TimeoutError):
                    if attempt == 59:
                        raise
                    time.sleep(1)
            try:
                opener.open(base + "/setup", timeout=5)
            except urllib.error.HTTPError as error:
                assert error.code == 303 and error.headers.get("Location") == "/"
            else:
                raise AssertionError("Decypharr still presents its setup wizard")
            docker("run", "-d", "--name", holy, "--network", "host", "-e", f"PUID={os.getuid()}", "-e", f"PGID={os.getgid()}", "-e", f"HOLYARRS_HEALTH_URL={endpoint}", "--mount", f"type=bind,src={state},dst=/config", "--mount", f"type=bind,src={data},dst=/data", "holyarrs/holyarrs:1.0.19", "-config", "/config", "-addr", f"127.0.0.1:{holy_port}")
            client = holyarrs.Client(endpoint)
            holyarrs.bootstrap(client, state / "provision")
            key = json.loads((state / "provision/api-key.json").read_text())["key"]
            settings = json.loads((SOURCE / "connections-settings.json").read_text())["downloader"]
            settings.update(url=base, secret=token)
            saved = client.call("POST", "/downloaders", settings, key=key)
            result = client.call("POST", f"/downloaders/{saved['id']}/test", {}, key=key)
            assert result["ok"] is True
            assert saved["category_music"] == "holyarrs-music" and saved["username"] == "media"
            docker("restart", decy)
            for attempt in range(30):
                try:
                    result = client.call("POST", f"/downloaders/{saved['id']}/test", {}, key=key)
                    if result.get("ok"):
                        break
                except holyarrs.ApiError:
                    pass
                if attempt == 29:
                    raise AssertionError("Downloader did not recover after restart")
                time.sleep(1)
            after = {name: json.loads((app / name).read_text()) for name in ("config.json", "auth.json")}
            assert after["auth.json"] == before["auth.json"]
            for field in ("session_secret", "strm"):
                assert after["config.json"][field] == before["config.json"][field]
            logs = docker("logs", decy) + docker("logs", holy)
            assert token not in logs and key not in logs and "fixture-not-a-real-debrid-key" not in logs
            assert "Participating in hearsay network" not in logs
            assert after["config.json"]["hearsay"]["disabled"] is True
            print("Actual Decypharr wizard bypass, HolyArrs token-password authentication, music category and restart passed.")
            print("Dummy credential only; Real-Debrid authentication, populated mount and acquired media were not tested.")
            print("Decypharr image: " + docker("inspect", "--format", "{{.Image}}", decy))
        except Exception:
            logs = docker("logs", decy)
            for value in (token, "fixture-not-a-real-debrid-key", before["config.json"]["session_secret"], before["config.json"]["strm"]["secret"]):
                logs = logs.replace(value, "[redacted]")
            print(logs, file=sys.stderr)
            raise
        finally:
            for name in names:
                subprocess.run(["docker", "rm", "-f", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)


if __name__ == "__main__":
    main()
