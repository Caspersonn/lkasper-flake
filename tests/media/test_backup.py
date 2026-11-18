import importlib.util
from contextlib import closing
import fcntl
import grp
import json
import os
from pathlib import Path
import pwd
import sqlite3
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('media_backup', ROOT / 'modules/services/tools/media-provision/backup.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class BackupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.state = self.root / 'state'
        self.state.mkdir(mode=0o700)
        self.key = self.state / 'key'
        self.key.write_text('test-master-key')
        self.password = self.root / 'password'
        self.password.write_text('test-backup-password')
        self.password.chmod(0o600)
        self.settings = {
            'repository': str(self.root / 'repository'),
            'restore_root': str(self.root / 'restore'),
            'paths': [str(self.state)],
            'required_files': [str(self.key)],
            'units': ['owner.service', 'downloader.service'],
            'exclude': [],
            'tag': 'test-state',
        }
        self.backup = module.Backup(self.settings, self.password, self.root / 'runtime')
        self.calls = []
        self.inactive = set()
        self.fail_backup = False
        self.fail_start = False
        self.snapshots = [{'id': '1234', 'time': '2026-11-15T00:00:00Z', 'paths': self.settings['paths']}]

    def command(self, args, env=None, check=True):
        self.calls.append(args)
        output = b''
        if args[:2] == ['systemctl', 'show']:
            output = b'loaded\n'
        if args[:2] == ['systemctl', 'is-active']:
            output = b'inactive\n' if args[2] in self.inactive else b'active\n'
        if args[:2] == ['systemctl', 'start'] and self.fail_start:
            raise module.BackupError()
        if args[:2] == ['restic', 'backup'] and self.fail_backup:
            raise module.BackupError()
        if args[:2] == ['restic', 'backup']:
            output = b'{"message_type":"summary","snapshot_id":"1234"}\n'
        if args[:2] == ['restic', 'snapshots']:
            output = json.dumps(self.snapshots).encode()
        if args[:2] == ['restic', 'restore']:
            target = Path(args[args.index('--target') + 1])
            restored = target / str(self.key).lstrip('/')
            restored.parent.mkdir(parents=True)
            restored.write_text(self.key.read_text())
        return subprocess.CompletedProcess(args, 0, output, b'')

    def run_mocked(self, operation):
        with patch.object(module, 'command', side_effect=self.command):
            getattr(self.backup, operation)()

    def test_backup_stops_writers_and_resumes_in_reverse_order(self):
        self.run_mocked('backup')
        stops = [c for c in self.calls if c[:2] == ['systemctl', 'stop']]
        starts = [c for c in self.calls if c[:2] == ['systemctl', 'start']]
        self.assertEqual([c[2] for c in stops], self.settings['units'])
        self.assertEqual([c[2] for c in starts], list(reversed(self.settings['units'])))
        self.assertLess(self.calls.index(stops[-1]), next(i for i, c in enumerate(self.calls) if c[:2] == ['restic', 'backup']))
        self.assertFalse(self.backup.journal.exists())

    def aurral_scope(self):
        library = self.root / 'music'
        flow = library / '_flows' / 'fixture'
        flow.mkdir(parents=True)
        self.kept = flow / 'Keep [live]*?.flac'
        self.unkept = flow / 'Temporary [live]*?.flac'
        self.kept.write_bytes(b'kept audio')
        self.unkept.write_bytes(b'temporary audio')
        database = self.state / 'aurral.db'
        with closing(sqlite3.connect(database)) as connection, connection:
            connection.execute('CREATE TABLE playlist_download_jobs (playlist_type TEXT, final_path TEXT)')
            connection.execute('INSERT INTO playlist_download_jobs VALUES (?, ?)', ('library', str(self.kept)))
        return {'database': str(database), 'library': str(library)}

    def test_aurral_selection_preserves_kept_audio_inside_flow_directory(self):
        scope = self.aurral_scope()
        before = Path(scope['database']).read_bytes()
        patterns = module.aurral_excludes(scope)
        self.assertEqual(patterns, [str(self.unkept).replace('[', '\\[').replace(']', '\\]').replace('*', '\\*').replace('?', '\\?')])
        self.assertEqual(Path(scope['database']).read_bytes(), before)
        self.assertTrue(self.kept.is_file())
        self.assertTrue(self.unkept.is_file())

    def test_aurral_selection_fails_closed_for_missing_or_external_kept_file(self):
        scope = self.aurral_scope()
        self.kept.unlink()
        with self.assertRaises(module.BackupError):
            module.aurral_excludes(scope)
        with closing(sqlite3.connect(scope['database'])) as connection, connection:
            connection.execute('UPDATE playlist_download_jobs SET final_path = ?', (str(self.key),))
        with self.assertRaises(module.BackupError):
            module.aurral_excludes(scope)

    def test_aurral_selection_refuses_missing_database_without_creating_it(self):
        scope = self.aurral_scope()
        Path(scope['database']).unlink()
        with self.assertRaises(module.BackupError):
            module.aurral_excludes(scope)
        self.assertFalse(Path(scope['database']).exists())

    def test_aurral_selection_never_follows_flow_or_kept_symlinks(self):
        scope = self.aurral_scope()
        self.kept.unlink()
        self.kept.symlink_to(self.key)
        with self.assertRaises(module.BackupError):
            module.aurral_excludes(scope)

    def test_aurral_reference_failure_resumes_writers_without_backup(self):
        self.settings['aurral'] = self.aurral_scope()
        self.kept.unlink()
        with self.assertRaises(module.BackupError):
            self.run_mocked('backup')
        self.assertEqual(len([call for call in self.calls if call[:2] == ['systemctl', 'start']]), 2)
        self.assertFalse(any(call[:2] == ['restic', 'backup'] for call in self.calls))

    def test_aurral_selection_is_computed_after_writers_stop(self):
        self.settings['aurral'] = self.aurral_scope()
        self.run_mocked('backup')
        create = next(call for call in self.calls if call[:2] == ['restic', 'backup'])
        self.assertIn('--exclude', create)
        self.assertNotIn(str(self.kept), create)

    def test_failed_backup_resumes_without_pruning(self):
        self.fail_backup = True
        with self.assertRaises(module.BackupError):
            self.run_mocked('backup')
        self.assertEqual(len([c for c in self.calls if c[:2] == ['systemctl', 'start']]), 2)
        self.assertFalse(any(c[:2] == ['restic', 'forget'] for c in self.calls))
        self.assertFalse(any(c[:2] == ['restic', 'tag'] for c in self.calls))

    def test_only_successful_snapshots_are_promoted_for_restore(self):
        self.run_mocked('backup')
        create = next(c for c in self.calls if c[:2] == ['restic', 'backup'])
        promote = next(c for c in self.calls if c[:2] == ['restic', 'tag'])
        self.assertIn('test-state-pending', create)
        self.assertEqual(promote, ['restic', 'tag', '--add', 'test-state', '--remove', 'test-state-pending', '1234'])

    def test_inactive_services_remain_inactive(self):
        self.inactive.add('owner.service')
        self.run_mocked('backup')
        self.assertFalse(any(c[:2] in [['systemctl', 'stop'], ['systemctl', 'start']] and c[2] == 'owner.service' for c in self.calls))

    def test_authentication_failure_precedes_service_stops(self):
        with patch.object(self.backup, 'authenticate', side_effect=module.BackupError):
            with self.assertRaises(module.BackupError):
                self.run_mocked('backup')
        self.assertFalse(self.calls)

    def test_recovery_journal_is_private(self):
        self.backup.write_journal(['owner.service'])
        self.assertEqual(stat.S_IMODE(self.backup.journal.stat().st_mode), 0o600)
        self.run_mocked('resume')
        self.assertEqual(self.calls, [['systemctl', 'start', 'owner.service']])

    def test_failed_resume_preserves_journal_and_attempts_all_units(self):
        self.backup.write_journal(self.settings['units'])
        self.fail_start = True
        with self.assertRaises(module.BackupError):
            self.run_mocked('resume')
        self.assertTrue(self.backup.journal.exists())
        self.assertEqual(len(self.calls), 2)

    def test_journal_cannot_start_unmanaged_units(self):
        self.backup.write_journal(['other.service'])
        with self.assertRaises(module.BackupError):
            self.run_mocked('resume')
        self.assertFalse(self.calls)

    def test_journal_symlink_is_refused(self):
        self.backup.journal.symlink_to(self.password)
        with self.assertRaises(module.BackupError):
            self.run_mocked('resume')

    def test_missing_master_key_refuses_backup_before_stopping_services(self):
        self.key.unlink()
        with self.assertRaises(module.BackupError):
            self.run_mocked('backup')
        self.assertFalse(any(c[0] == 'systemctl' for c in self.calls))

    def test_symlink_master_key_is_refused(self):
        self.key.unlink()
        self.key.symlink_to(self.password)
        with self.assertRaises(module.BackupError):
            self.run_mocked('backup')

    def test_private_password_is_required(self):
        self.password.chmod(0o644)
        with self.assertRaises(module.BackupError):
            self.run_mocked('backup')

    def test_password_symlink_is_refused(self):
        self.password.unlink()
        self.password.symlink_to(self.key)
        with self.assertRaises(module.BackupError):
            self.run_mocked('backup')

    def test_non_repository_data_is_not_initialized_over(self):
        repository = module.private_directory(self.settings['repository'])
        (repository / 'existing').touch()
        with self.assertRaises(module.BackupError):
            self.run_mocked('backup')
        self.assertFalse(self.calls)

    def test_repository_permissions_are_enforced(self):
        repository = Path(self.settings['repository'])
        repository.mkdir(mode=0o755)
        with self.assertRaises(module.BackupError):
            self.run_mocked('backup')

    def test_restore_verifies_state_without_touching_live_files(self):
        self.run_mocked('restore')
        restored = Path(self.settings['restore_root']) / 'latest' / str(self.key).lstrip('/')
        self.assertEqual(restored.read_text(), 'test-master-key')
        self.assertEqual(self.key.read_text(), 'test-master-key')
        self.assertTrue(any(c[:2] == ['restic', 'restore'] and '--verify' in c for c in self.calls))
        self.assertFalse(any(c[0] == 'systemctl' for c in self.calls))

    def test_restore_refuses_existing_target(self):
        parent = module.private_directory(self.settings['restore_root'])
        target = parent / 'latest'
        target.mkdir()
        (target / 'existing').write_text('keep')
        with self.assertRaises(module.BackupError):
            self.run_mocked('restore')
        self.assertEqual((target / 'existing').read_text(), 'keep')

    def test_restore_refuses_unexpected_snapshot_paths(self):
        self.snapshots[0]['paths'] = ['/etc']
        with self.assertRaises(module.BackupError):
            self.run_mocked('restore')
        self.assertFalse(any(c[:2] == ['restic', 'restore'] for c in self.calls))

    def test_restore_refuses_missing_snapshots(self):
        self.snapshots.clear()
        with self.assertRaises(module.BackupError):
            self.run_mocked('restore')

    def test_restore_failure_removes_only_its_temporary_directory(self):
        original = self.command
        def fail_restore(args, **kwargs):
            result = original(args, **kwargs)
            if args[:2] == ['restic', 'restore']:
                raise module.BackupError()
            return result
        with patch.object(module, 'command', side_effect=fail_restore):
            with self.assertRaises(module.BackupError):
                self.backup.restore()
        self.assertEqual(list(Path(self.settings['restore_root']).iterdir()), [])
        self.assertTrue(self.key.exists())

    def seed_staging(self):
        restore = Path(self.settings['restore_root'])
        restore.mkdir(mode=0o700)
        latest = restore / 'latest'
        staged = latest / str(self.state).lstrip('/')
        staged.mkdir(parents=True, mode=0o700)
        os.rename(self.key, staged / 'key')
        self.state.rmdir()
        latest.chmod(0o700)
        return latest, staged

    def test_install_moves_staged_state_with_ownership_and_removes_staging(self):
        latest, staged = self.seed_staging()
        user = pwd.getpwuid(os.geteuid()).pw_name
        group = grp.getgrgid(os.getegid()).gr_name
        self.settings['owners'] = {str(self.state): [user, group]}
        original = module.Backup.apply_owner
        with patch.object(module.Backup, 'apply_owner', autospec=True, side_effect=original) as owner:
            self.backup.install()
        self.assertEqual((self.state / 'key').read_text(), 'test-master-key')
        self.assertEqual([call.args[1] for call in owner.call_args_list], [self.state])
        self.assertEqual(owner.call_args_list[0].args[2:], (os.geteuid(), os.getegid()))
        self.assertFalse(latest.exists())

    def test_install_refuses_existing_destination(self):
        latest, staged = self.seed_staging()
        self.state.mkdir(mode=0o700)
        self.settings['owners'] = {str(self.state): [pwd.getpwuid(os.geteuid()).pw_name, grp.getgrgid(os.getegid()).gr_name]}
        with self.assertRaises(module.BackupError):
            self.backup.install()
        self.assertTrue(self.state.is_dir())
        self.assertTrue(staged.is_dir())

    def test_install_refuses_missing_required_file_and_rolls_back(self):
        latest, staged = self.seed_staging()
        (staged / 'key').unlink()
        self.settings['owners'] = {str(self.state): [pwd.getpwuid(os.geteuid()).pw_name, grp.getgrgid(os.getegid()).gr_name]}
        with self.assertRaises(module.BackupError):
            self.backup.install()
        self.assertFalse(self.state.exists())
        self.assertTrue((staged).is_dir())

    def test_install_refuses_unknown_owner_before_moving(self):
        latest, staged = self.seed_staging()
        self.settings['owners'] = {str(self.state): ['no-such-media-user', grp.getgrgid(os.getegid()).gr_name]}
        with self.assertRaises(module.BackupError):
            self.backup.install()
        self.assertFalse(self.state.exists())
        self.assertTrue(staged.is_dir())

    def test_install_refuses_loose_staging(self):
        latest, staged = self.seed_staging()
        latest.chmod(0o755)
        self.settings['owners'] = {str(self.state): [pwd.getpwuid(os.geteuid()).pw_name, grp.getgrgid(os.getegid()).gr_name]}
        with self.assertRaises(module.BackupError):
            self.backup.install()
        self.assertFalse(self.state.exists())
        self.assertTrue(staged.is_dir())

    def test_other_password_sources_are_removed(self):
        with patch.dict(os.environ, {'RESTIC_PASSWORD': 'wrong', 'RESTIC_PASSWORD_COMMAND': 'unsafe'}):
            backup = module.Backup(self.settings, self.password, self.root / 'other-runtime')
        self.assertNotIn('RESTIC_PASSWORD', backup.environment)
        self.assertNotIn('RESTIC_PASSWORD_COMMAND', backup.environment)

    def cli(self):
        settings = self.root / 'settings.json'
        settings.write_text(json.dumps(self.settings))
        return subprocess.run([
            sys.executable, '-B', str(spec.origin), '--settings', str(settings),
            '--password-file', str(self.password), '--runtime-dir', str(self.backup.runtime),
            'backup',
        ], capture_output=True, text=True, timeout=10)

    def test_concurrent_operation_is_refused_before_repository_access(self):
        with (self.backup.runtime / 'lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = self.cli()
        self.assertEqual(result.returncode, 1)
        self.assertFalse(Path(self.settings['repository']).exists())
        self.assertNotIn('Traceback', result.stderr)

    def test_cli_redacts_secret_values_and_underlying_errors(self):
        self.password.chmod(0o644)
        result = self.cli()
        self.assertEqual(result.returncode, 1)
        self.assertNotIn(self.password.read_text(), result.stdout + result.stderr)
        self.assertNotIn('Traceback', result.stderr)


if __name__ == '__main__':
    unittest.main()
