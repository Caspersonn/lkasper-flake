import base64
from contextlib import closing
import importlib.util
import os
from pathlib import Path
import shutil
import sqlite3
import stat
import tempfile
import unittest
from unittest.mock import patch


source = Path(__file__).resolve().parents[2] / "modules/users/shared/atuin/credentials.py"
spec = importlib.util.spec_from_file_location("credentials", source)
credentials = importlib.util.module_from_spec(spec)
spec.loader.exec_module(credentials)


class CredentialsTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.config = self.root / "config/config.toml"
        self.config.parent.mkdir()
        self.session = self.root / "session"
        self.key = self.root / "key"
        self.session.write_bytes(b"fixture-session")
        self.key.write_bytes(base64.b64encode(bytes(range(32))))
        self.session.chmod(0o400)
        self.key.chmod(0o400)
        self.data = self.root / ".atuin/data"
        self.config.write_text(f'key_path = "{self.key}"\n[ai]\nenabled = false\n')
        self.environment = patch.dict(os.environ, {
            "HOME": str(self.root),
            "XDG_DATA_HOME": str(self.root / ".local/share"),
            "XDG_CONFIG_HOME": str(self.root / "config"),
            "ATUIN_CONFIG_DIR": str(self.config.parent),
            "ATUIN_HOME": "",
        })
        self.environment.start()
        self.addCleanup(self.environment.stop)
        self.atuin = shutil.which("atuin")
        self.assertIsNotNone(self.atuin)

    def provision(self):
        credentials.provision(self.session, self.key, self.config, self.atuin)

    def metadata(self):
        with closing(sqlite3.connect(self.data / "meta.db")) as connection:
            return dict(connection.execute("SELECT key,value FROM meta"))

    def test_fresh_repeat_rotation_and_private_database(self):
        self.provision()
        self.assertEqual(self.metadata()["session"], "fixture-session")
        self.assertEqual(stat.S_IMODE((self.data / "meta.db").stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE((self.data / "key").stat().st_mode), 0o600)
        with closing(sqlite3.connect(self.data / "meta.db")) as connection, connection:
            connection.execute("INSERT INTO meta(key,value) VALUES ('unrelated','preserved')")
        self.provision()
        self.session.chmod(0o600)
        self.session.write_bytes(b"rotated-fixture-session")
        self.session.chmod(0o400)
        self.provision()
        self.assertEqual(self.metadata()["session"], "rotated-fixture-session")
        self.assertEqual(self.metadata()["unrelated"], "preserved")

    def test_key_rotation_retains_database(self):
        self.provision()
        original = (self.data / "meta.db").read_bytes()
        self.key.chmod(0o600)
        self.key.write_bytes(base64.b64encode(bytes(reversed(range(32)))))
        self.key.chmod(0o400)
        with self.assertRaisesRegex(credentials.ProvisioningError, "Existing Atuin key differs"):
            self.provision()
        self.assertEqual((self.data / "meta.db").read_bytes(), original)

    def test_missing_secret_does_not_create_data(self):
        self.session.unlink()
        with self.assertRaises(FileNotFoundError):
            self.provision()
        self.assertFalse(self.data.exists())

    def test_missing_secret_preserves_existing_profile(self):
        self.provision()
        original = (self.data / "meta.db").read_bytes()
        self.session.unlink()
        with self.assertRaises(FileNotFoundError):
            self.provision()
        self.assertEqual((self.data / "meta.db").read_bytes(), original)

    def test_invalid_session_does_not_create_data(self):
        self.session.chmod(0o600)
        self.session.write_bytes(b"invalid\n")
        self.session.chmod(0o400)
        with self.assertRaisesRegex(credentials.ProvisioningError, "Invalid managed session"):
            self.provision()
        self.assertFalse(self.data.exists())

    def test_permissions_fail_before_mutation(self):
        self.session.chmod(0o644)
        with self.assertRaisesRegex(credentials.ProvisioningError, "mode 0400"):
            self.provision()
        self.assertFalse(self.data.exists())

    def test_legacy_profile_and_metadata_preserved(self):
        self.data = self.root / ".local/share/atuin"
        self.data.mkdir(parents=True)
        (self.data / "key").write_bytes(self.key.read_bytes())
        (self.data / "session").write_bytes(b"legacy-fixture-session")
        self.provision()
        self.assertEqual(self.metadata()["session"], "fixture-session")
        self.assertEqual((self.data / "session").read_bytes(), b"legacy-fixture-session")
        self.assertFalse((self.root / ".atuin/data").exists())

    def test_key_encodings(self):
        raw = bytes(range(32))
        for encoded in [raw, credentials.msgpack.packb(raw), credentials.msgpack.packb(list(raw))]:
            self.assertEqual(credentials.decode_key(base64.b64encode(encoded)), raw)

    def test_unanchored_history_is_preserved(self):
        self.data.mkdir(parents=True)
        database = self.data / "history.db"
        with closing(sqlite3.connect(database)) as connection, connection:
            connection.execute("CREATE TABLE history (id TEXT)")
            connection.execute("INSERT INTO history VALUES ('preserved')")
        original = database.read_bytes()
        with self.assertRaisesRegex(credentials.ProvisioningError, "no local account key anchor"):
            self.provision()
        self.assertEqual(database.read_bytes(), original)
        self.assertFalse((self.data / "key").exists())

    def test_unanchored_other_session_is_preserved(self):
        self.provision()
        (self.data / "key").unlink()
        database = self.data / "meta.db"
        with closing(sqlite3.connect(database)) as connection, connection:
            connection.execute("UPDATE meta SET value='other-account' WHERE key='session'")
        original = database.read_bytes()
        with self.assertRaisesRegex(credentials.ProvisioningError, "no local account key anchor"):
            self.provision()
        self.assertEqual(database.read_bytes(), original)

    def test_unanchored_records_are_preserved(self):
        self.data.mkdir(parents=True)
        database = self.data / "records.db"
        with closing(sqlite3.connect(database)) as connection, connection:
            connection.execute("CREATE TABLE store (id TEXT)")
            connection.execute("INSERT INTO store VALUES ('encrypted-preserved')")
        original = database.read_bytes()
        with self.assertRaisesRegex(credentials.ProvisioningError, "no local account key anchor"):
            self.provision()
        self.assertEqual(database.read_bytes(), original)

    def test_metadata_journal_is_private(self):
        self.provision()
        database = self.data / "meta.db"
        observations = []
        test = self

        class Connection(sqlite3.Connection):
            def execute(self, statement, parameters=()):
                result = super().execute(statement, parameters)
                if statement.startswith("INSERT INTO meta"):
                    observations.append(super().execute("PRAGMA journal_mode").fetchone()[0])
                    journal = Path(str(database) + "-journal")
                    test.assertTrue(journal.exists())
                    test.assertEqual(stat.S_IMODE(journal.stat().st_mode), 0o600)
                return result

        connect = sqlite3.connect
        self.session.chmod(0o600)
        self.session.write_bytes(b"journal-rotation-fixture")
        self.session.chmod(0o400)
        with patch.object(credentials.sqlite3, "connect", side_effect=lambda *args, **kwargs: connect(*args, factory=Connection, **kwargs)):
            self.provision()
        self.assertEqual(observations, ["delete"])
        self.assertFalse(Path(str(database) + "-journal").exists())


if __name__ == "__main__":
    unittest.main()
