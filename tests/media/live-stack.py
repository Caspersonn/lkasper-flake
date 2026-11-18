import argparse
import importlib.util
import json
import os
from pathlib import Path
import secrets
import socket
import sqlite3
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
import decypharr
import holyarrs
import connections
import importlib.util

jackett_spec = importlib.util.spec_from_file_location("jackett_provision", SOURCE / "jackett.py")
jackett_provision = importlib.util.module_from_spec(jackett_spec)
jackett_spec.loader.exec_module(jackett_provision)

MOVIE_TMDB = "550"
ARTIST = "Miles Davis"
ALBUM = "Kind of Blue"
USER_AGENT = "soundspan-live-check/1.0 (media acceptance)"
IMAGE_DECY = "decypharr:2.7.2-holyarrs"
IMAGE_HOLY = "holyarrs/holyarrs:1.0.19"


def free_port():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


def docker(*args, timeout=120):
    return subprocess.check_output(["docker", *args], stderr=subprocess.PIPE, text=True, timeout=timeout).strip()


def mbid_of(entity, name, extra=""):
    request = urllib.request.Request(
        f"https://musicbrainz.org/ws/2/{entity}?query={urllib.parse.quote(name + extra)}&fmt=json&limit=1",
        headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
    )
    for attempt in range(5):
        try:
            with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request, timeout=30) as response:
                payload = json.load(response)
            break
        except urllib.error.HTTPError as error:
            if error.code == 503 and attempt < 4:
                time.sleep(5)
                continue
            raise
    found = payload.get(entity + "s") or []
    if not found:
        raise SystemExit(f"MusicBrainz lookup failed for {name}")
    return found[0]["id"]


def wait_for(predicate, deadline, step=5):
    while time.time() < deadline:
        try:
            value = predicate()
            if value:
                return value
        except (urllib.error.URLError, TimeoutError, OSError, KeyError, ValueError):
            pass
        time.sleep(step)
    raise SystemExit("timed out waiting for the live pipeline")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", type=Path, required=True)
    parser.add_argument("--jackett-bin", default="Jackett")
    parser.add_argument("--timeout-minutes", type=int, default=25)
    args = parser.parse_args()

    suffix = secrets.token_hex(5)
    root = Path(tempfile.mkdtemp(prefix="live-stack-", dir="/tmp/opencode"))
    data = root / "data"
    app = root / "decypharr"
    holy_state = Path("/tmp/opencode/live/holyarrs-state")
    jackett_home = root / "jackett" / "h"
    for child in ("debrid", "symlinks", "media/movies", "media/tv", "media/music"):
        (data / child).mkdir(mode=0o770, parents=True, exist_ok=True)
    holy_state.mkdir(mode=0o700, exist_ok=True)
    app.mkdir(mode=0o700)
    print("workspace", root)

    recorded = None
    database = holy_state / "holyarrs.db"
    if database.exists():
        with sqlite3.connect(database) as conn:
            sources = dict(conn.execute("SELECT name, url FROM sources"))
            downloaders = dict(conn.execute("SELECT name, url FROM downloaders"))
        source = urllib.parse.urlsplit(sources.get("nixos-knaben", ""))
        downloader = urllib.parse.urlsplit(downloaders.get("nixos-decypharr", ""))
        if source.port and downloader.port:
            recorded = (downloader.port, source.port)
            print("reusing recorded ports", recorded)
    decy_port, jackett_port = recorded if recorded else (free_port(), free_port())
    holy_port = free_port()
    decy = "live-decy-" + suffix
    holy = "live-holy-" + suffix
    names = [decy, holy]
    try:
        decypharr.provision(SOURCE / "decypharr-settings.json", args.credentials, app)
        fixture_settings = root / "decypharr-settings.json"
        configuration = json.loads((SOURCE / "decypharr-settings.json").read_text())
        configuration.update(port=str(decy_port), bind_address="127.0.0.1")
        decypharr.atomic_json(fixture_settings, configuration)
        decypharr.provision(fixture_settings, args.credentials, app)
        token = json.loads((app / "auth.json").read_text())["api_token"]

        jackett_provision.provision(SOURCE / "jackett-settings.json", jackett_home / ".config" / "Jackett", jackett_port)
        subprocess.run(["pkill", "-f", f"--Port {jackett_port}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(2)
        jackett_env = dict(os.environ, HOME=str(jackett_home))
        subprocess.Popen([args.jackett_bin, "--Port", str(jackett_port)], env=jackett_env,
                         stdout=(root / "jackett.log").open("w"), stderr=subprocess.STDOUT)
        jackett_key = json.loads((jackett_home / ".config" / "Jackett" / "provision-auth.json").read_text())["APIKey"]
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        for attempt in range(60):
            try:
                with opener.open(f"http://127.0.0.1:{jackett_port}/api/v2.0/indexers/thepiratebay/results/torznab/api?t=caps&apikey={jackett_key}", timeout=3) as response:
                    if b'error code="100"' not in response.read()[:200]:
                        break
            except Exception:
                pass
            if attempt == 59:
                raise AssertionError("Jackett did not start with its provisioned key")
            time.sleep(1)

        docker("run", "-d", "--name", decy, "--network", "host", "--device", "/dev/fuse",
               "--cap-add", "SYS_ADMIN", "--security-opt", "apparmor=unconfined",
               "-e", f"PUID={os.getuid()}", "-e", f"PGID={os.getgid()}", "-e", "UMASK=002",
               "--mount", f"type=bind,src={app},dst=/app",
               f"--mount", f"type=bind,src={data},dst=/data,bind-propagation=rshared",
               IMAGE_DECY)
        docker("run", "-d", "--name", holy, "--network", "host",
               "-e", f"PUID={os.getuid()}", "-e", f"PGID={os.getgid()}", "-e", "UMASK=002",
               "-e", f"HOLYARRS_HEALTH_URL=http://127.0.0.1:{holy_port}",
               "--mount", f"type=bind,src={holy_state},dst=/config",
               f"--mount", f"type=bind,src={data},dst=/data,bind-propagation=rslave",
               IMAGE_HOLY, "-config", "/config", "-addr", f"127.0.0.1:{holy_port}")

        endpoint = f"http://127.0.0.1:{holy_port}"
        client = holyarrs.Client(endpoint)
        holyarrs.bootstrap(client, holy_state / "provision")
        key = json.loads((holy_state / "provision" / "api-key.json").read_text())["key"]

        connection_settings = json.loads((SOURCE / "connections-settings.json").read_text())
        connection_settings["downloader"]["url"] = f"http://127.0.0.1:{decy_port}"
        for source in connection_settings["sources"]:
            indexer = "knaben" if "knaben" in source["name"] else "thepiratebay"
            source["url"] = f"http://127.0.0.1:{jackett_port}/api/v2.0/indexers/{indexer}/results/torznab/api"
        connection_file = root / "connections-settings.json"
        decypharr.atomic_json(connection_file, connection_settings)
        credentials = {
            name: decypharr.read_object(path)
            for name, path in {
                "holyarrs": holy_state / "provision" / "api-key.json",
                "jackett": jackett_home / ".config" / "Jackett" / "provision-auth.json",
                "decypharr": app / "auth.json",
            }.items()
        }
        attempts = 6
        for attempt in range(attempts):
            try:
                connections.reconcile(client, connection_settings, credentials, holy_state / "provision" / "connections.json")
                break
            except decypharr.ProvisionError as error:
                if attempt == attempts - 1:
                    for group in ("sources", "downloaders"):
                        for item in client.call("GET", "/" + group, key=key).get(group, []):
                            result = client.call("POST", f"/{group}/{item['id']}/test", {}, key=key)
                            print(f"native test {group} {item['name']}: {json.dumps(result)[:300]}", flush=True)
                            print(f"record {group} {item['name']}: url={item.get('url')!r} format={item.get('format')!r} kind={item.get('kind')!r}", flush=True)
                    for wanted in connection_settings["sources"] + [connection_settings["downloader"]]:
                        print(f"wanted {wanted['name']}: url={wanted['url']!r} format={wanted.get('format')!r} kind={wanted.get('kind')!r}", flush=True)
                    raise
                print(f"connection attempt {attempt + 1} failed: {error}; retrying", flush=True)
                time.sleep(10)
        print("connections reconciled")

        downloader = next(item for item in client.call("GET", "/downloaders", key=key)["downloaders"]
                          if item["name"] == "nixos-decypharr")
        for attempt in range(12):
            result = client.call("POST", f"/downloaders/{downloader['id']}/test", {}, key=key)
            print("downloader test", attempt, result.get("ok"), flush=True)
            if result.get("ok"):
                break
            time.sleep(10)
        else:
            raise AssertionError("Decypharr downloader test never passed before asks")

        artist = mbid_of("artist", ARTIST)
        album = None
        for attempt in range(5):
            request = urllib.request.Request(
                f"https://musicbrainz.org/ws/2/release-group/?query=artist:{urllib.parse.quote(ARTIST)}%20AND%20releasegroup:{urllib.parse.quote(ALBUM)}&fmt=json&limit=5",
                headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
            )
            try:
                with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request, timeout=30) as response:
                    payload = json.load(response)
                break
            except urllib.error.HTTPError as error:
                if error.code == 503 and attempt < 4:
                    time.sleep(5)
                    continue
                raise
        groups = payload.get("release-groups") or []
        if not groups:
            raise SystemExit("MusicBrainz release-group lookup failed")
        album = groups[0]["id"]
        print("mbids", artist, album)

        def ask(body):
            for attempt in range(90):
                try:
                    return client.call("POST", "/asks", body, key=key)
                except holyarrs.ApiError as error:
                    print("ask attempt", attempt, "failed with status", error.status)
                    time.sleep(15)
            raise holyarrs.ApiError()

        movie = ask({"id": f"tmdb:{MOVIE_TMDB}"})
        music = ask({"kind": "artist", "id": f"mbid:{artist}", "albums": [album]})
        movie = movie.get("ask") if isinstance(movie, dict) and movie.get("ask") else movie
        music = music.get("ask") if isinstance(music, dict) and music.get("ask") else music
        ids = {"movie": movie.get("id") if isinstance(movie, dict) else movie,
               "music": music.get("id") if isinstance(music, dict) else music}
        print("ask ids", ids)

        deadline = time.time() + args.timeout_minutes * 60
        states = {}
        retried = set()
        poll = 0
        while time.time() < deadline:
            poll += 1
            for row in client.call("GET", "/downloads/view", key=key).get("downloads", []):
                if row.get("phase") == "needs_a_decision" and row.get("id") not in retried:
                    retried.add(row["id"])
                    try:
                        client.call("PUT", f"/downloads/{row['id']}/edition",
                                    {"edition": "Theatrical", "confirm": True, "retry": True}, key=key)
                        print("edition retry queued for download", row["id"], flush=True)
                    except holyarrs.ApiError as error:
                        print("edition retry", row["id"], "failed with status", error.status, flush=True)
            for name, ask_id in ids.items():
                if not ask_id:
                    continue
                view = client.call("GET", f"/asks/{ask_id}", key=key)
                state = view.get("state")
                if states.get(name) != state:
                    states[name] = state
                    print("ask", name, state)
                if state == "asked":
                    try:
                        client.call("POST", f"/asks/{ask_id}/approve", {"note": "live acceptance"}, key=key)
                    except holyarrs.ApiError:
                        pass
                title_id = view.get("title_id")
                if state != "available" and title_id and poll % 8 == 0:
                    try:
                        client.call("POST", f"/titles/{title_id}/search", {}, key=key)
                        print("hand search queued for", name, "title", title_id, flush=True)
                    except holyarrs.ApiError as error:
                        print("hand search", name, "failed with status", error.status, flush=True)
            ready = all(states.get(name) == "available" for name in ids)
            links = {
                "movie": list((data / "symlinks").glob("**/*")) if data.exists() else [],
                "music": [],
            }
            if ready:
                break
            time.sleep(15)
        print("final states", states)

        found = {}
        for name, folder in (("movie", "movies"), ("music", "music")):
            tree = list((data / "media" / folder).glob("**/*"))
            found[name] = tree
            print(name, "library entries:", len(tree), [p.name for p in tree[:5]])
        symlinks = sorted((data / "symlinks").glob("**/*"))
        print("symlink tree:", len(symlinks), [p.name for p in symlinks[:10]])
        resolved = []
        for link in symlinks:
            if link.is_symlink():
                target = os.readlink(link)
                resolved.append(target)
                if not target.startswith("/data/debrid"):
                    raise AssertionError(f"link target outside the debrid mount: {target}")
        if not resolved:
            raise AssertionError("no imported symlinks were produced")
        sample = [t for t in resolved if t.endswith((".mkv", ".mp4", ".flac", ".m4a", ".mp3"))]
        if not sample:
            raise AssertionError("no media file links were produced")
        assert all(states.get(name) == "available" for name in ids), states
        assert found["movie"], "movie library folder stayed empty"
        assert found["music"], "music library folder stayed empty"

        for target in sample[:2]:
            rel = target[len("/data/"):]
            host_path = data / rel
            if not host_path.exists():
                raise AssertionError(f"debrid content not visible on the host: {target}")
            probe = subprocess.run(["docker", "exec", "--user", "2000:2000", decy, "sh", "-c",
                                    f"test -r '{target}' && head -c 200000 '{target}' > /dev/null"],
                                   capture_output=True, text=True, timeout=60)
            if probe.returncode != 0:
                raise AssertionError(f"uid 2000 cannot read {target}: {probe.stderr}")
        doctor = subprocess.run(["docker", "exec", holy, "/holyarrs", "doctor"],
                                capture_output=True, text=True, timeout=120)
        print("holyarrs doctor exit", doctor.returncode)
        for line in doctor.stdout.splitlines():
            if line.strip():
                print("doctor:", line.strip())
        if doctor.returncode != 0:
            raise AssertionError("holyarrs doctor reported failures")
        logs = docker("logs", decy) + docker("logs", holy)
        for secret in (token, key, json.loads(args.credentials.read_text())["real_debrid_api_key"]):
            assert secret not in logs, "a secret value leaked into container logs"
        print("LIVE STACK OK: both asks reached available, links resolve into /data/debrid, uid 2000 can read them, logs are redacted.")
    finally:
        for name in names:
            subprocess.run(["docker", "rm", "-f", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
        subprocess.run(["pkill", "-f", f"--Port {jackett_port}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("workspace kept for inspection:", root)


if __name__ == "__main__":
    main()
