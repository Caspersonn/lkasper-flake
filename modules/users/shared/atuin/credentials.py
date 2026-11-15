import base64
from contextlib import closing
import hmac
import os
from pathlib import Path
import sqlite3
import stat
import subprocess
import sys
import tomllib

import msgpack


class ProvisioningError(Exception):
    pass


def private_secret(path):
    info = path.stat()
    if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o400:
        raise ProvisioningError("Managed credentials must be owned by this user with mode 0400; check agenix provisioning.")
    return path.read_bytes()


def decode_key(value):
    raw = base64.b64decode(value.rstrip(), validate=True)
    if len(raw) == 32:
        return raw
    unpacked = msgpack.unpackb(raw)
    if isinstance(unpacked, bytes) and len(unpacked) == 32:
        return unpacked
    if isinstance(unpacked, list) and len(unpacked) == 32 and all(type(x) is int and 0 <= x <= 255 for x in unpacked):
        return bytes(unpacked)
    raise ProvisioningError("Invalid managed encryption key; restore the enrolled user's encrypted secret.")


def data_directory(settings):
    if "data_dir" in settings:
        return Path(settings["data_dir"]).expanduser()
    if os.environ.get("ATUIN_HOME"):
        return Path(os.environ["ATUIN_HOME"]) / "data"
    home = Path.home()
    current = home / ".atuin/data"
    legacy = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "atuin"
    if not current.exists() and (legacy.exists() or (home / ".local/share/atuin").exists()):
        return legacy
    return current


def unanchored_profile_is_empty(data_dir, database, session):
    legacy_session = data_dir / "session"
    if legacy_session.exists() and legacy_session.read_bytes() != session:
        return False
    for name in ["history.db", "records.db"]:
        path = data_dir / name
        if not path.exists():
            continue
        with closing(sqlite3.connect(f"{path.as_uri()}?mode=ro", uri=True)) as connection:
            tables = {row[0] for row in connection.execute("SELECT name FROM sqlite_master WHERE type='table'")}
            for table in ["history", "records", "store"]:
                if table in tables and connection.execute(f'SELECT EXISTS(SELECT 1 FROM "{table}")').fetchone()[0]:
                    return False
    if database.exists():
        with closing(sqlite3.connect(f"{database.as_uri()}?mode=ro", uri=True)) as connection:
            rows = dict(connection.execute("SELECT key,value FROM meta"))
        if rows.get("session", session.decode("ascii")) != session.decode("ascii"):
            return False
        if set(rows) - {"host_id", "files_migrated", "session"}:
            return False
    return True


def provision(session_path, key_path, config_path, atuin):
    os.umask(0o077)
    session = private_secret(session_path)
    key_bytes = private_secret(key_path)
    managed_key = decode_key(key_bytes)
    if not session or any(byte < 33 or byte > 126 for byte in session):
        raise ProvisioningError("Invalid managed session token; restore the exact enrolled token without whitespace.")
    settings = tomllib.loads(config_path.read_text())
    data_dir = data_directory(settings)
    existing_key = data_dir / "key"
    if existing_key.exists() and not hmac.compare_digest(decode_key(existing_key.read_bytes()), managed_key):
        raise ProvisioningError("Existing Atuin key differs from the managed account. Keep local data and arrange an explicit account migration.")
    if Path(settings.get("key_path", "")) != key_path:
        raise ProvisioningError("Atuin key_path does not reference the managed key; rebuild the shared configuration.")
    database = Path(settings.get("meta", {}).get("db_path", data_dir / "meta.db"))
    if not existing_key.exists() and not unanchored_profile_is_empty(data_dir, database, session):
        raise ProvisioningError("Existing Atuin data has no local account key anchor; verify its original key before provisioning.")
    environment = os.environ.copy()
    environment["ATUIN_CONFIG_DIR"] = str(config_path.parent)
    environment["RUST_LOG"] = "off"
    result = subprocess.run([atuin, "info"], env=environment, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode or not database.is_file():
        raise ProvisioningError("Atuin metadata initialization failed; verify the configured data directory and package version.")
    if not existing_key.exists():
        with existing_key.open("xb") as anchor:
            anchor.write(key_bytes)
    database.chmod(0o600)
    with closing(sqlite3.connect(database, timeout=60)) as connection, connection:
        columns = {row[1] for row in connection.execute("PRAGMA table_info(meta)")}
        if not {"key", "value", "updated_at"} <= columns:
            raise ProvisioningError("Unsupported Atuin metadata schema; retain local data and update the managed initializer.")
        connection.execute(
            "INSERT INTO meta(key,value,updated_at) VALUES (?, ?, strftime('%s','now')) "
            "ON CONFLICT(key) DO UPDATE SET value=excluded.value,updated_at=excluded.updated_at "
            "WHERE meta.value != excluded.value",
            ("session", session.decode("ascii")),
        )


def main():
    try:
        provision(*(Path(value) for value in sys.argv[1:4]), sys.argv[4])
    except ProvisioningError as error:
        print(f"Atuin credential provisioning failed: {error}", file=sys.stderr)
        return 1
    except (OSError, ValueError, sqlite3.Error, msgpack.exceptions.UnpackException, ProvisioningError):
        print("Atuin credential provisioning failed: verify agenix files, permissions, key/account consistency, and the metadata schema. No device login is required; retain local data.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
