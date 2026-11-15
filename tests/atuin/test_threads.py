from contextlib import closing
import base64
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import subprocess
import tempfile
import time
import unittest


class ThreadsTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="atuin-threads-", dir="/tmp/opencode")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.config = self.root / "config"
        self.config.mkdir()
        self.data = self.root / "data"
        self.data.mkdir()
        self.socket = self.root / "daemon.sock"
        (self.data / "key").write_bytes(base64.b64encode(bytes(range(32))))
        (self.config / "config.toml").write_text(
            f'data_dir = "{self.data}"\nkey_path = "{self.data}/key"\n'
            'auto_sync = false\n[ai]\nenabled = false\n'
            '[threads]\ncapture = false\n[daemon]\nenabled = true\n'
            f'autostart = false\nsystemd_socket = false\nsocket_path = "{self.socket}"\n'
        )
        self.environment = dict(os.environ)
        for name in list(self.environment):
            if name.startswith(("ATUIN_", "CLAUDE_", "CODEX_", "XDG_")) or name in ("LISTEN_PID", "LISTEN_FDS"):
                self.environment.pop(name)
        self.environment.update({
            "HOME": str(self.root), "ATUIN_CONFIG_DIR": str(self.config),
            "XDG_DATA_HOME": str(self.root / "share"),
            "XDG_CONFIG_HOME": str(self.config), "XDG_STATE_HOME": str(self.root / "state"),
            "XDG_RUNTIME_DIR": str(self.root), "RUST_LOG": "off",
        })
        self.atuin = shutil.which("atuin")
        self.assertIsNotNone(self.atuin)
        self.daemon = subprocess.Popen(
            [self.atuin, "daemon", "start"], env=self.environment,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        self.addCleanup(self.stop)
        for _ in range(100):
            if self.socket.exists():
                break
            self.assertIsNone(self.daemon.poll(), "isolated daemon exited")
            time.sleep(0.1)
        self.assertTrue(self.socket.exists())

    def stop(self):
        self.daemon.terminate()
        try:
            self.daemon.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.daemon.kill()
            self.daemon.wait()

    def run_atuin(self, *arguments):
        result = subprocess.run(
            [self.atuin, *arguments], env=self.environment,
            capture_output=True, text=True, timeout=60,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_empty_profile(self):
        self.run_atuin("threads", "import", "--style", "json")
        self.assertEqual(self.run_atuin("threads", "list", "--style", "json"), [])

    def fixtures(self):
        transcript = self.root / ".claude/projects/fixture/11111111-1111-4111-8111-111111111111.jsonl"
        transcript.parent.mkdir(parents=True)
        transcript.write_text(json.dumps({
            "type": "user", "uuid": "22222222-2222-4222-8222-222222222222",
            "sessionId": transcript.stem, "cwd": str(self.root),
            "timestamp": "2026-11-15T10:00:00Z",
            "message": {"role": "user", "content": "Claude fixture"},
        }) + "\n")
        database = self.root / "share/opencode/opencode.db"
        database.parent.mkdir(parents=True)
        with closing(sqlite3.connect(database)) as connection, connection:
            connection.executescript("""
                CREATE TABLE event(id TEXT PRIMARY KEY, aggregate_id TEXT, seq INTEGER,
                    type TEXT, data TEXT);
                CREATE TABLE session(id TEXT PRIMARY KEY, title TEXT, parent_id TEXT,
                    directory TEXT, time_created INTEGER, time_updated INTEGER);
                CREATE TABLE message(id TEXT PRIMARY KEY, session_id TEXT,
                    time_created INTEGER, time_updated INTEGER, data TEXT);
                CREATE TABLE part(id TEXT PRIMARY KEY, message_id TEXT, session_id TEXT,
                    time_created INTEGER, time_updated INTEGER, data TEXT);
                INSERT INTO session VALUES('ses_fixture','OpenCode fixture',NULL,'/',1794736800000,1794736800000);
            """)
            connection.execute("INSERT INTO message VALUES(?,?,?,?,?)", (
                "msg_fixture", "ses_fixture", 1794736800000, 1794736800000,
                json.dumps({"id": "msg_fixture", "sessionID": "ses_fixture", "role": "user", "time": {"created": 1794736800000}}),
            ))
            connection.execute("INSERT INTO part VALUES(?,?,?,?,?,?)", (
                "prt_fixture", "msg_fixture", "ses_fixture", 1794736800000, 1794736800000,
                json.dumps({"id": "prt_fixture", "messageID": "msg_fixture", "sessionID": "ses_fixture", "type": "text", "text": "OpenCode fixture"}),
            ))
        return transcript, database

    def test_agents_repeat_and_source_preservation(self):
        transcript, database = self.fixtures()
        original = {path: hashlib.sha256(path.read_bytes()).digest() for path in (transcript, database)}
        self.run_atuin("threads", "import", "--style", "json")
        first = self.run_atuin("threads", "list", "--style", "json")
        self.assertEqual(len(first), 2, first)
        self.run_atuin("threads", "import", "--style", "json")
        self.assertEqual(self.run_atuin("threads", "list", "--style", "json"), first)
        for path, digest in original.items():
            self.assertEqual(hashlib.sha256(path.read_bytes()).digest(), digest)

    @unittest.skipUnless(shutil.which("claude") and shutil.which("opencode"), "native agent executables are required for restore acceptance")
    def test_native_restore_without_agent_execution(self):
        sources = self.fixtures()
        original = {path: hashlib.sha256(path.read_bytes()).digest() for path in sources}
        self.run_atuin("threads", "import", "--style", "json")
        threads = self.run_atuin("threads", "list", "--style", "json")
        destination = self.root / "destination"
        destination.mkdir()
        data = destination / "data"
        data.mkdir()
        for name in ["threads.db", "meta.db"]:
            with closing(sqlite3.connect((self.data / name).as_uri() + "?mode=ro", uri=True)) as source, closing(sqlite3.connect(data / name)) as target:
                source.backup(target)
        (destination / "config.toml").write_text(
            f'data_dir = "{data}"\nkey_path = "{self.data}/key"\nauto_sync = false\n'
            '[ai]\nenabled = false\n[threads]\ncapture = true\n[daemon]\nenabled = false\nautostart = false\n'
        )
        environment = dict(self.environment, HOME=str(destination),
            ATUIN_CONFIG_DIR=str(destination), CLAUDE_CONFIG_DIR=str(destination / ".claude"),
            XDG_DATA_HOME=str(destination / "share"), XDG_CONFIG_HOME=str(destination / "config"),
            XDG_STATE_HOME=str(destination / "state"), PWD=str(self.root))
        for thread in threads:
            result = subprocess.run([self.atuin, "resume", "--print", thread["atuin_id"]],
                env=environment, cwd=self.root, capture_output=True, text=True, timeout=60)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("claude" if thread["harness"] == "claude-code" else "opencode", result.stdout)
        self.assertTrue(list((destination / ".claude").rglob("*.jsonl")))
        restored = False
        for database in (destination / "share/opencode").rglob("*.db"):
            with closing(sqlite3.connect(database)) as connection:
                tables = {row[0] for row in connection.execute("SELECT name FROM sqlite_master WHERE type='table'")}
                for table in ["session", "session_v2"]:
                    if table in tables:
                        restored |= connection.execute(f"SELECT count(*) FROM {table}").fetchone()[0] > 0
        self.assertTrue(restored)
        for path, digest in original.items():
            self.assertEqual(hashlib.sha256(path.read_bytes()).digest(), digest)


if __name__ == "__main__":
    unittest.main()
