from contextlib import closing
import importlib.util
import os
from pathlib import Path
import shutil
import sqlite3
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('real_media_backup', ROOT / 'modules/services/tools/media-provision/backup.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


@unittest.skipUnless(shutil.which('restic'), 'restic is required for the real repository test')
class ResticTests(unittest.TestCase):
    def test_reference_selection_and_verified_restore_use_literal_paths(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = root / 'state'
            state.mkdir(mode=0o700)
            library = root / 'music [live]'
            flow = library / '_flows' / 'fixture [x]*?\\line\nnext'
            flow.mkdir(parents=True)
            kept = flow / 'Keep [song]*?.flac'
            discarded = flow / 'Temporary [song]*?\\.flac'
            collision = flow / 'Temporary xsongOTHERx\\.flac'
            permanent = library / 'Permanent.flac'
            for path in [kept, discarded, collision, permanent]:
                path.write_bytes(b'fLaC' + path.name.encode() * 20)
            database = state / 'aurral.db'
            with closing(sqlite3.connect(database)) as connection, connection:
                connection.execute('CREATE TABLE playlist_download_jobs (playlist_type TEXT, final_path TEXT)')
                connection.executemany('INSERT INTO playlist_download_jobs VALUES (?, ?)', [
                    ('library', str(kept)), ('library', str(collision)), ('library', str(permanent)),
                ])
            password = root / 'password'
            password.write_text('disposable-test-password')
            password.chmod(0o600)
            settings = {
                'repository': str(root / 'repository'), 'restore_root': str(root / 'restore'),
                'paths': [str(state), str(library)], 'required_files': [str(database)],
                'units': [], 'exclude': [], 'tag': 'test-aurral',
                'aurral': {'library': str(library), 'database': str(database)},
            }
            backup = module.Backup(settings, password, root / 'runtime')
            backup.backup()
            backup.restore()
            restored = root / 'restore' / 'latest'
            for path in [database, kept, collision, permanent]:
                self.assertEqual((restored / path.relative_to('/')).read_bytes(), path.read_bytes())
            self.assertFalse((restored / discarded.relative_to('/')).exists())
            self.assertTrue(discarded.exists())
            self.assertEqual(os.stat(restored).st_mode & 0o777, 0o700)


if __name__ == '__main__':
    unittest.main()
