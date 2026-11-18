import argparse
import json
import urllib.error
import urllib.request
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--state-dir", type=Path, default=Path("/var/lib/aurral-flows-provision"))
parser.add_argument("--app-state", type=Path, default=Path("/var/lib/aurral-flows"))
args = parser.parse_args()
seed = json.loads((args.state_dir / "admin.json").read_text())
fixture = json.loads((args.app_state / "job-fixture.json").read_text())
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def call(method, route, body=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(
        "http://127.0.0.1:3002/api" + route,
        data=json.dumps(body).encode() if body is not None else None,
        headers=headers,
        method=method,
    )
    try:
        with opener.open(request, timeout=60) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        return error.code, None


status, login = call("POST", "/auth/login", seed)
assert status == 200
token = login["token"]
route = "/playlists/jobs/" + fixture["flowId"]
assert call("GET", route)[0] == 401
status, jobs = call("GET", route, token=token)
assert status == 200
jobs = {job["id"]: job for job in jobs}
assert jobs[fixture["failed"]]["status"] == "failed"
assert jobs[fixture["failed"]]["error"] == "No matching Soulseek file"
assert jobs[fixture["blocked"]]["status"] == "blocked"
assert jobs[fixture["blocked"]]["error"] == "Waiting for Soulseek peer"
assert all(not any(key in job for key in ("finalPath", "stagingPath", "externalPath")) for job in jobs.values())
retry = "/playlists/jobs/" + fixture["failed"] + "/retry"
assert call("POST", retry, {})[0] == 401
status, result = call("POST", retry, {}, token=token)
assert status == 200
assert result["jobId"] == fixture["failed"]
assert result["retried"] and result["status"] == "pending"
status, settings = call("GET", "/settings", token=token)
assert status == 200
for source in ("lidarr", "ytdlp", "prowlarr", "nzbget", "sabnzbd", "tidarr", "deemix"):
    assert not settings["integrations"][source]["enabled"], source
print("Authenticated waiting, failure and retry contracts passed without fallback sources")
