import argparse
from pathlib import Path
import secrets
import sys

from decypharr import ProvisionError, atomic_json, read_object


def render(state_dir, credential_path, connect=False):
    if state_dir.is_symlink() or state_dir.resolve() != state_dir.absolute() or not state_dir.is_dir():
        raise ProvisionError("slskd state must be a directory without symlinks")
    config_path = state_dir / "slskd.yml"
    credential = read_object(credential_path, protected=True, optional=True)
    if credential is None:
        if config_path.exists() or config_path.is_symlink():
            raise ProvisionError("existing slskd configuration requires explicit migration")
        credential = {
            "api_key": secrets.token_urlsafe(48),
            "web_username": "casper",
            "web_password": secrets.token_urlsafe(32),
            "jwt_key": secrets.token_urlsafe(48),
            "soulseek_username": "aurral-" + secrets.token_hex(8),
            "soulseek_password": secrets.token_urlsafe(32),
        }
        atomic_json(credential_path, credential)
    for name in ("api_key", "web_username", "web_password", "jwt_key", "soulseek_username", "soulseek_password"):
        if not isinstance(credential.get(name), str) or not credential[name] or any(char.isspace() for char in credential[name]):
            raise ProvisionError("invalid protected slskd credentials")
    if len(credential["api_key"]) < 32 or len(credential["web_password"]) < 20 or len(credential["jwt_key"]) < 32:
        raise ProvisionError("invalid protected slskd credential length")
    config = {
        "instance_name": "aurral-flows",
        "remote_configuration": False,
        "remote_file_management": False,
        "flags": {"no_connect": not connect, "no_version_check": True},
        "directories": {
            "downloads": "/data/downloads/slskd/complete",
            "incomplete": "/data/downloads/slskd/incomplete",
        },
        "shares": {"directories": []},
        "web": {
            "port": 5032,
            "ip_address": "127.0.0.1",
            "https": {"disabled": True},
            "authentication": {
                "disabled": False,
                "username": credential["web_username"],
                "password": credential["web_password"],
                "jwt": {"key": credential["jwt_key"]},
                "api_keys": {"aurral": {"key": credential["api_key"], "role": "administrator", "cidr": "127.0.0.1/32"}},
            },
        },
        "soulseek": {
            "username": credential["soulseek_username"],
            "password": credential["soulseek_password"],
            "listen_port": 50310,
        },
        "transfers": {
            "download": {
                "slots": 2,
                "speed_limit": 2048,
                "retry": {"partial": "resume", "attempts": 3, "delay": 5000, "max_delay": 60000},
                "destination": {"exists": "rename", "permissions": {"mode": "660"}},
            },
        },
        "retention": {"files": {"complete": None, "incomplete": None}, "logs": 7},
    }
    atomic_json(config_path, config)
    return config


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--credentials", type=Path, required=True)
    parser.add_argument("--connect", action="store_true")
    args = parser.parse_args()
    try:
        render(args.state_dir, args.credentials, args.connect)
    except (ProvisionError, OSError, ValueError, TypeError):
        print("Isolated slskd provisioning failed; existing state was not reset.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
