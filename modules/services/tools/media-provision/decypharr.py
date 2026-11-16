import argparse
import copy
import fcntl
import json
import os
from pathlib import Path
import secrets
import stat
import sys
import tempfile


class ProvisionError(Exception):
    pass


def read_object(path, *, protected=False, optional=False):
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    except FileNotFoundError:
        if optional:
            return None
        raise ProvisionError("required input is missing") from None
    with os.fdopen(fd, "r") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode):
            raise ProvisionError("input must be a regular file")
        if protected and stat.S_IMODE(info.st_mode) & 0o077:
            raise ProvisionError("secret input permissions must exclude group and others")
        if info.st_size > 1024 * 1024:
            raise ProvisionError("input is too large")
        try:
            value = json.load(stream)
        except (ValueError, UnicodeError):
            raise ProvisionError("input contains invalid JSON") from None
    if not isinstance(value, dict):
        raise ProvisionError("input must contain a JSON object")
    return value


def merge(current, managed):
    result = copy.deepcopy(current)
    for key, value in managed.items():
        if isinstance(value, dict):
            if key in result and not isinstance(result[key], dict):
                raise ProvisionError("existing configuration contains an invalid settings object")
            result[key] = merge(result.get(key, {}), value)
        else:
            result[key] = copy.deepcopy(value)
    return result


def preserved_secret(value, key):
    if key not in value:
        value[key] = secrets.token_hex(32)
    if not isinstance(value[key], str) or not value[key]:
        raise ProvisionError("existing signing or authentication material is incomplete")


def render(settings, credential, current=None, auth=None):
    api_key = credential.get("real_debrid_api_key")
    if not isinstance(api_key, str) or not api_key or any(c.isspace() for c in api_key):
        raise ProvisionError("a nonempty Real-Debrid API key without whitespace is required")
    if current is not None and current.get("use_auth") and auth is None:
        raise ProvisionError("existing authentication state is missing; restore it before provisioning")
    config = copy.deepcopy(current) if current is not None else {}
    providers = config.get("debrids", [])
    if not isinstance(providers, list) or len(providers) > 1:
        raise ProvisionError("existing provider configuration requires explicit migration")
    provider = providers[0] if providers else {}
    if not isinstance(provider, dict) or provider.get("provider", provider.get("name", "realdebrid")) != "realdebrid":
        raise ProvisionError("existing provider configuration requires explicit migration")
    usenet = config.get("usenet", {})
    if not isinstance(usenet, dict):
        raise ProvisionError("existing Usenet configuration is invalid")
    if usenet.get("providers"):
        raise ProvisionError("existing Usenet configuration requires explicit migration")
    configured = merge(provider, settings["debrids"][0])
    configured["api_key"] = api_key
    configured.pop("download_api_keys", None)
    config = merge(config, settings)
    config["debrids"] = [configured]
    preserved_secret(config, "session_secret")
    if not isinstance(config.get("strm"), dict):
        raise ProvisionError("existing stream signing configuration is invalid")
    preserved_secret(config["strm"], "secret")
    if auth is None:
        auth = {
            "token_only": True,
            "api_token": secrets.token_hex(32),
            "session_version": secrets.token_hex(16),
        }
    else:
        auth = copy.deepcopy(auth)
        if auth.get("token_only") is not True:
            raise ProvisionError("existing password authentication requires explicit migration")
        for key in ("api_token", "session_version"):
            if not isinstance(auth.get(key), str) or not auth[key]:
                raise ProvisionError("existing authentication material is incomplete; restore it first")
    return config, auth


def atomic_json(path, value):
    data = (json.dumps(value, indent=2, sort_keys=True) + "\n").encode()
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    except FileNotFoundError:
        pass
    else:
        with os.fdopen(fd, "rb") as stream:
            info = os.fstat(stream.fileno())
            if not stat.S_ISREG(info.st_mode):
                raise ProvisionError("state must be a regular file")
            if stream.read() == data:
                os.fchmod(stream.fileno(), 0o600)
                return False
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            os.fchmod(stream.fileno(), 0o600)
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    return True


def provision(settings_path, credential_path, state_dir):
    settings = read_object(settings_path)
    credential = read_object(credential_path, protected=True)
    state_dir = Path(state_dir)
    state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    if state_dir.is_symlink() or not state_dir.is_dir():
        raise ProvisionError("state directory must be a real directory")
    if state_dir.stat().st_mode & 0o022:
        raise ProvisionError("state directory must not be writable by group or others")
    lock = os.open(state_dir / ".provision.lock", os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(lock, "w") as stream:
        if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
            raise ProvisionError("provisioning lock must be a regular file")
        os.fchmod(stream.fileno(), 0o600)
        fcntl.flock(stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        config_path = state_dir / "config.json"
        auth_path = state_dir / "auth.json"
        current = read_object(config_path, optional=True)
        auth = read_object(auth_path, optional=True)
        config, auth = render(settings, credential, current, auth)
        atomic_json(auth_path, auth)
        atomic_json(config_path, config)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--settings", type=Path, required=True)
    parser.add_argument("--credentials", type=Path, required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    args = parser.parse_args()
    try:
        provision(args.settings, args.credentials, args.state_dir)
    except (ProvisionError, OSError, KeyError, TypeError, AttributeError) as error:
        message = str(error) if isinstance(error, ProvisionError) else "input or state operation failed"
        print(f"decypharr provisioning failed: {message}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
