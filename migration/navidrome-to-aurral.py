#!/usr/bin/env python3
"""Migrate a Navidrome library and its listening history into Aurral.

The script talks to the Aurral JSON API under /api and to the Navidrome
Subsonic API. It moves the music files into the Aurral Library folder through
the Aurral ingest endpoint, connects Navidrome as a history server so the play
counts and listening history arrive, and imports the Navidrome favorites.

The source path is resolved inside the Aurral container, so it has to be a path
that the container can read. On kaito the Navidrome music folder is mounted
read-only into the Aurral container under the same path.
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


class MigrationError(Exception):
    pass


class AurralClient:
    def __init__(self, base_url, token):
        self.base_url = base_url.rstrip("/")
        self.token = token

    def request(self, method, path, payload=None, expect=(200,)):
        url = self.base_url + path
        data = None
        headers = {"Accept": "application/json"}
        if self.token:
            headers["Authorization"] = "Bearer " + self.token
        if payload is not None:
            data = json.dumps(payload).encode("utf-8")
            headers["Content-Type"] = "application/json"
        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                status = response.status
                body = response.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as error:
            status = error.code
            body = error.read().decode("utf-8", "replace")
        except urllib.error.URLError as error:
            raise MigrationError("cannot reach {}: {}".format(url, error.reason))
        if status not in expect:
            raise MigrationError("{} {} returned {}: {}".format(method, path, status, body.strip()))
        if not body.strip():
            return None
        try:
            return json.loads(body)
        except ValueError:
            return body

    def get(self, path, expect=(200,)):
        return self.request("GET", path, expect=expect)

    def post(self, path, payload=None, expect=(200,)):
        return self.request("POST", path, payload, expect=expect)

    def put(self, path, payload=None, expect=(200,)):
        return self.request("PUT", path, payload, expect=expect)


def login(base_url, username, password):
    client = AurralClient(base_url, None)
    result = client.post("/api/auth/login", {"username": username, "password": password})
    if not isinstance(result, dict) or not result.get("token"):
        raise MigrationError("the Aurral login response carries no token")
    return AurralClient(base_url, result["token"])


def bootstrap(base_url):
    client = AurralClient(base_url, None)
    result = client.get("/api/health/bootstrap")
    if isinstance(result, dict) and result.get("onboardingRequired"):
        raise MigrationError("Aurral still needs its first-run setup to finish")
    return result


def ingest_check(client, source_path):
    try:
        result = client.post("/api/library/files/ingest/check", {"sourcePath": source_path})
    except MigrationError as error:
        message = str(error)
        if "does not exist" in message or "cannot read it" in message:
            raise MigrationError(
                "{} Aurral reads the source path inside its own container, so the folder "
                "has to be mounted into it.".format(message)
            )
        raise
    if not isinstance(result, dict):
        raise MigrationError("the ingest check returned no result")
    return result


def ingest(client, source_path, mode, monitor="none", fill_tags=True):
    result = client.post(
        "/api/library/files/ingest",
        {"sourcePath": source_path, "mode": mode, "monitor": monitor, "fillTags": fill_tags},
        expect=(200, 202),
    )
    if not isinstance(result, dict):
        raise MigrationError("the ingest request returned no operation")
    operation = result.get("operation") if isinstance(result.get("operation"), dict) else result
    operation_id = operation.get("id")
    if operation_id is None:
        raise MigrationError("the ingest request returned no operation identifier")
    return str(operation_id)


def operation_state(client, operation_id):
    result = client.get("/api/library/files/operations/" + urllib.parse.quote(operation_id))
    if not isinstance(result, dict):
        raise MigrationError("the operation status returned no result")
    operation = result.get("operation") if isinstance(result.get("operation"), dict) else result
    return str(operation.get("status") or "").lower(), operation


def wait_for_operation(client, operation_id, timeout, poll_interval):
    deadline = time.monotonic() + timeout
    while True:
        status, operation = operation_state(client, operation_id)
        if status == "complete":
            return operation
        if status in ("failed", "cancelled"):
            detail = operation.get("error") or status
            raise MigrationError("ingest operation {} ended as {}".format(operation_id, detail))
        if time.monotonic() >= deadline:
            raise MigrationError(
                "ingest operation {} timed out in state {}".format(operation_id, status or "unknown")
            )
        time.sleep(poll_interval)


def connect_history(client, url, username, secret):
    client.put("/api/history-servers/navidrome", {"url": url, "username": username, "secret": secret})
    return client.get("/api/history-servers")


def sync_history(client):
    client.post("/api/history-servers/navidrome/sync", expect=(200, 202, 204))


def import_favorites(client):
    return client.post("/api/history-servers/navidrome/favorites")


def history_servers(client):
    result = client.get("/api/history-servers")
    if isinstance(result, dict):
        servers = result.get("servers")
        if isinstance(servers, list):
            return servers
    return []


def choose_mode(check, requested):
    if requested != "auto":
        return requested
    hardlink = check.get("hardlink")
    if isinstance(hardlink, dict) and hardlink.get("available"):
        return "hardlink"
    return "copy"


def report(label, payload):
    print("{}\n{}".format(label, json.dumps(payload, indent=2, sort_keys=True)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--aurral-url", default="http://127.0.0.1:3002")
    parser.add_argument("--aurral-username", required=True)
    parser.add_argument("--aurral-password", default=os.environ.get("AURRAL_PASSWORD"))
    parser.add_argument("--navidrome-url", default="http://127.0.0.1:4533")
    parser.add_argument("--navidrome-username", required=True)
    parser.add_argument("--navidrome-password", default=os.environ.get("NAVIDROME_PASSWORD"))
    parser.add_argument("--source", default="/mnt/audio/music")
    parser.add_argument("--mode", choices=("auto", "copy", "hardlink", "move"), default="auto")
    parser.add_argument("--monitor", choices=("none", "tracks", "albums"), default="none")
    parser.add_argument("--skip-files", action="store_true")
    parser.add_argument("--skip-history", action="store_true")
    parser.add_argument("--skip-favorites", action="store_true")
    parser.add_argument("--timeout", type=int, default=7200)
    parser.add_argument("--poll-interval", type=int, default=15)
    args = parser.parse_args()

    if not args.aurral_password:
        print("the Aurral password is missing; set AURRAL_PASSWORD", file=sys.stderr)
        return 2
    if not args.skip_history and not args.navidrome_password:
        print("the Navidrome password is missing; set NAVIDROME_PASSWORD", file=sys.stderr)
        return 2

    try:
        bootstrap(args.aurral_url)
        client = login(args.aurral_url, args.aurral_username, args.aurral_password)

        if not args.skip_files:
            check = ingest_check(client, args.source)
            report("Ingest check for {}".format(args.source), check)
            mode = choose_mode(check, args.mode)
            operation_id = ingest(client, args.source, mode, args.monitor)
            print("Ingest operation {} started in {} mode".format(operation_id, mode))
            result = wait_for_operation(client, operation_id, args.timeout, args.poll_interval)
            report("Ingest operation finished", result)

        if not args.skip_history:
            servers = connect_history(
                client,
                args.navidrome_url,
                args.navidrome_username,
                args.navidrome_password,
            )
            report("History servers", servers)
            sync_history(client)
            print("A history sync is queued")

        if not args.skip_favorites:
            favorites = import_favorites(client)
            report("Favorites import", favorites)

        report("History servers after the migration", history_servers(client))
    except MigrationError as error:
        print("Migration failed: {}".format(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
