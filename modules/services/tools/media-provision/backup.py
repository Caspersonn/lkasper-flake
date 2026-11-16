import argparse
import fcntl
import grp
import json
import os
from pathlib import Path
import pwd
import shutil
import signal
import stat
import subprocess
import sys
import traceback
import tempfile


class BackupError(Exception):
    pass


def private_directory(path):
    path = Path(path)
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = path.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.geteuid():
        raise BackupError()
    if path.resolve() != path.absolute() or info.st_mode & 0o077:
        raise BackupError()
    return path


def command(args, env=None, check=True):
    result = subprocess.run(args, env=env, capture_output=True, timeout=120 if args[0] == 'systemctl' else 3600)
    if check and result.returncode:
        raise BackupError()
    return result


class Backup:
    def __init__(self, settings, password, runtime):
        self.settings = settings
        self.runtime = private_directory(runtime)
        self.journal = self.runtime / 'active-units.json'
        self.environment = os.environ.copy()
        for name in ['RESTIC_PASSWORD', 'RESTIC_PASSWORD_COMMAND']:
            self.environment.pop(name, None)
        self.environment.update({
            'RESTIC_REPOSITORY': settings['repository'],
            'RESTIC_PASSWORD_FILE': str(password),
            'RESTIC_CACHE_DIR': str(self.runtime / 'cache'),
        })

    def restic(self, *args):
        return command(['restic', *args], env=self.environment).stdout

    def authenticate(self):
        password = Path(self.environment['RESTIC_PASSWORD_FILE'])
        info = password.lstat()
        if not stat.S_ISREG(info.st_mode) or info.st_mode & 0o077:
            raise BackupError()
        repository = private_directory(self.settings['repository'])
        if not (repository / 'config').exists():
            if any(repository.iterdir()):
                raise BackupError()
            self.restic('init')
        self.restic('cat', 'config')

    def write_journal(self, units):
        fd, name = tempfile.mkstemp(dir=self.runtime)
        try:
            with os.fdopen(fd, 'w') as stream:
                json.dump(units, stream)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(name, self.journal)
        finally:
            if os.path.exists(name):
                os.unlink(name)

    def resume(self):
        if not self.journal.exists():
            return
        info = self.journal.lstat()
        if not stat.S_ISREG(info.st_mode) or info.st_mode & 0o077:
            raise BackupError()
        units = json.loads(self.journal.read_text())
        if not isinstance(units, list) or any(u not in self.settings['units'] for u in units):
            raise BackupError()
        failed = False
        for unit in reversed(units):
            try:
                command(['systemctl', 'start', unit])
            except (BackupError, OSError, subprocess.TimeoutExpired):
                failed = True
        if failed:
            raise BackupError()
        self.journal.unlink()

    def backup(self):
        self.resume()
        self.authenticate()
        paths = self.settings['paths']
        if any(not Path(p).is_dir() or Path(p).is_symlink() for p in paths):
            raise BackupError()
        if any(not Path(p).is_file() or Path(p).is_symlink() for p in self.settings['required_files']):
            raise BackupError()
        active = []
        for unit in self.settings['units']:
            loaded = command(['systemctl', 'show', unit, '--property=LoadState', '--value']).stdout.strip()
            if loaded != b'loaded':
                raise BackupError()
            state = command(['systemctl', 'is-active', unit], check=False).stdout.strip()
            if state == b'active':
                active.append(unit)
            elif state not in [b'inactive', b'failed']:
                raise BackupError()
        self.write_journal(active)
        try:
            for unit in active:
                command(['systemctl', 'stop', unit])
            excludes = [arg for path in self.settings['exclude'] for arg in ['--exclude', path]]
            pending_tag = self.settings['tag'] + '-pending'
            output = self.restic('backup', '--json', '--one-file-system', '--tag', pending_tag, *excludes, '--', *paths)
            summaries = [row for line in output.splitlines() if (row := json.loads(line)).get('message_type') == 'summary']
            if len(summaries) != 1 or not summaries[0].get('snapshot_id'):
                raise BackupError()
            self.restic('tag', '--add', self.settings['tag'], '--remove', pending_tag, summaries[0]['snapshot_id'])
        finally:
            self.resume()
        self.restic('forget', '--tag', self.settings['tag'], '--keep-daily', '7', '--keep-weekly', '4', '--prune')

    def restore(self):
        self.authenticate()
        snapshots = json.loads(self.restic('snapshots', '--json', '--tag', self.settings['tag']))
        if not snapshots:
            raise BackupError()
        snapshot = max(snapshots, key=lambda s: s['time'])
        if sorted(snapshot['paths']) != sorted(self.settings['paths']):
            raise BackupError()
        parent = private_directory(self.settings['restore_root'])
        target = parent / 'latest'
        if target.exists() or target.is_symlink():
            raise BackupError()
        temporary = Path(tempfile.mkdtemp(prefix='.restore-', dir=parent))
        try:
            self.restic('restore', snapshot['id'], '--verify', '--target', str(temporary))
            for path in self.settings['required_files']:
                restored = temporary / path.lstrip('/')
                if restored.is_symlink() or not restored.is_file():
                    raise BackupError()
            temporary.chmod(0o700)
            os.rename(temporary, target)
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)


    def owners_lookup(self):
        resolved = {}
        for path, owner in self.settings['owners'].items():
            try:
                uid = pwd.getpwnam(owner[0]).pw_uid
                gid = grp.getgrnam(owner[1]).gr_gid
            except KeyError:
                raise BackupError()
            resolved[path] = (uid, gid)
        return resolved

    def apply_owner(self, root, uid, gid):
        os.lchown(root, uid, gid)
        for parent, directories, files in os.walk(root):
            for name in directories + files:
                os.lchown(os.path.join(parent, name), uid, gid)

    def install(self):
        owners = self.owners_lookup()
        staging = Path(self.settings['restore_root']) / 'latest'
        info = staging.lstat()
        if not stat.S_ISDIR(info.st_mode) or info.st_mode & 0o077 or staging.resolve() != staging.absolute():
            raise BackupError()
        for path in self.settings['paths']:
            if Path(path).exists() or Path(path).is_symlink():
                raise BackupError()
            staged = staging / path.lstrip('/')
            if staged.is_symlink() or not staged.is_dir():
                raise BackupError()
        moves = []
        try:
            for path in self.settings['paths']:
                staged = staging / path.lstrip('/')
                destination = Path(path)
                destination.parent.mkdir(parents=True, exist_ok=True)
                os.rename(staged, destination)
                moves.append((destination, staged))
            for path in self.settings['required_files']:
                if Path(path).is_symlink() or not Path(path).is_file():
                    raise BackupError()
            for path, (uid, gid) in owners.items():
                self.apply_owner(Path(path), uid, gid)
        except BaseException:
            for destination, staged in reversed(moves):
                if destination.exists() or destination.is_symlink():
                    os.rename(destination, staged)
            raise
        shutil.rmtree(staging)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--settings', type=Path, required=True)
    parser.add_argument('--password-file', type=Path, required=True)
    parser.add_argument('--runtime-dir', type=Path, required=True)
    parser.add_argument('operation', choices=['backup', 'resume', 'restore', 'install'])
    args = parser.parse_args()
    os.umask(0o077)
    def interrupted(signum, frame):
        raise BackupError()
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        settings = json.loads(args.settings.read_text())
        backup = Backup(settings, args.password_file, args.runtime_dir)
        fd = os.open(backup.runtime / 'lock', os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, 'w'):
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            getattr(backup, args.operation)()
    except (BackupError, OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        if os.environ.get("MEDIA_STATE_DEBUG") == "1":
            print(f"Media state operation failed: {error!r}", file=sys.stderr)
            traceback.print_exc()
        print('Media state operation failed; retained state was not replaced.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
