from contextlib import closing
import importlib.util
import os
from pathlib import Path
import sqlite3
import sys
import tempfile
import time
import unittest


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("aurral_cleanup", SOURCE / "aurral_cleanup.py")
cleanup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cleanup)


class CleanupTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.root.chmod(0o700)
        self.state = self.root / "state"
        self.state.mkdir(mode=0o700)
        self.staging = self.root / "staging"
        self.staging.mkdir()
        self.database = self.root / "aurral.db"
        self.calls = []
        with closing(sqlite3.connect(self.database)) as db, db:
            db.execute("CREATE TABLE playlist_download_jobs (status TEXT, staging_path TEXT, final_path TEXT)")
            db.execute("CREATE TABLE weekly_flow_download_provider_work (id TEXT)")
            db.execute("CREATE TABLE _honker_live (id TEXT)")

    def control(self, action, unit, *args):
        self.calls.append((action, unit))
        if action == "show":
            return "loaded" if args[0] == "--property=LoadState" else "active"
        return ""

    def run_cleanup(self, **kwargs):
        return cleanup.cleanup(self.state, self.database, self.staging, control=self.control, provider=lambda _: False, **kwargs)

    def test_prune_preserves_references_links_and_permanent_audio(self):
        orphan = self.staging / "orphan"
        orphan.write_bytes(b"orphan")
        kept = self.staging / "kept"
        kept.write_bytes(b"kept")
        directory = self.staging / "referenced"
        directory.mkdir()
        (directory / "partial").write_bytes(b"partial")
        permanent = self.root / "permanent.flac"
        permanent.write_bytes(b"permanent")
        (self.staging / "link").symlink_to(permanent)
        (self.staging / "directory-link").symlink_to(self.root, target_is_directory=True)
        hard = self.staging / "hard"
        os.link(permanent, hard)
        result = cleanup.prune(self.staging, {kept, directory}, time.time() + 49 * 3600)
        self.assertEqual(result["removedFiles"], 1)
        self.assertFalse(orphan.exists())
        self.assertEqual(kept.read_bytes(), b"kept")
        self.assertTrue((directory / "partial").exists())
        self.assertEqual(permanent.read_bytes(), b"permanent")
        self.assertTrue(hard.exists())
        self.assertTrue((self.staging / "link").is_symlink())

    def test_age_uses_change_time_and_bounds_file_byte_and_scan_counts(self):
        for index in range(3):
            (self.staging / str(index)).write_bytes(b"x" * 4096)
        os.utime(self.staging / "0", (0, 0))
        self.assertEqual(cleanup.prune(self.staging, set(), time.time())["removedFiles"], 0)
        future = time.time() + 49 * 3600
        self.assertEqual(cleanup.prune(self.staging, set(), future, max_bytes=1)["removedFiles"], 0)
        self.assertEqual(cleanup.prune(self.staging, set(), future, max_entries=0)["reason"], "scan-limit")
        self.assertEqual(cleanup.prune(self.staging, set(), future, max_files=1)["removedFiles"], 1)

    def test_symlinked_staging_is_refused(self):
        link = self.root / "link"
        link.symlink_to(self.staging, target_is_directory=True)
        with self.assertRaises(cleanup.ProvisionError):
            cleanup.prune(link, set(), time.time() + 49 * 3600)

    def test_snapshot_protects_all_job_paths_and_detects_work(self):
        target = self.staging / "partial"
        with closing(sqlite3.connect(self.database)) as db, db:
            db.execute("INSERT INTO playlist_download_jobs VALUES ('failed', ?, ?)", (str(target), str(self.root / "kept.flac")))
        busy, paths = cleanup.references(self.database)
        self.assertEqual(busy, 0)
        self.assertIn(target, paths)
        for statement in [
            "INSERT INTO playlist_download_jobs VALUES ('downloading', NULL, NULL)",
            "INSERT INTO weekly_flow_download_provider_work VALUES ('work')",
            "INSERT INTO _honker_live VALUES ('work')",
        ]:
            with closing(sqlite3.connect(self.database)) as db, db:
                db.execute(statement)
            self.assertGreater(cleanup.references(self.database)[0], 0)

    def test_nightly_schema_protects_paths_and_checks_all_active_work(self):
        target = self.staging / "partial"
        with closing(sqlite3.connect(self.database)) as db, db:
            db.execute("ALTER TABLE playlist_download_jobs RENAME TO download_jobs")
            db.execute("ALTER TABLE weekly_flow_download_provider_work RENAME TO download_provider_work")
            db.execute("DROP TABLE _honker_live")
            db.execute("CREATE TABLE jobs (state TEXT)")
            db.execute("INSERT INTO download_jobs VALUES ('done', ?, NULL)", (str(target),))
            db.execute("INSERT INTO jobs VALUES ('done')")
        before = self.database.read_bytes()
        self.assertEqual(cleanup.references(self.database), (0, {target}))
        self.assertEqual(self.database.read_bytes(), before)
        for statement in [
            "INSERT INTO download_jobs VALUES ('downloading', NULL, NULL)",
            "INSERT INTO download_provider_work VALUES ('work')",
            "INSERT INTO jobs VALUES ('pending')",
        ]:
            with closing(sqlite3.connect(self.database)) as db, db:
                db.execute(statement)
            self.assertGreater(cleanup.references(self.database)[0], 0)

    def test_missing_or_malformed_database_fails_without_creating_it(self):
        missing = self.root / "missing.db"
        with self.assertRaises(cleanup.ProvisionError):
            cleanup.references(missing)
        self.assertFalse(missing.exists())
        with closing(sqlite3.connect(self.database)) as db, db:
            db.execute("INSERT INTO playlist_download_jobs VALUES ('done', '../escape', NULL)")
        with self.assertRaises(cleanup.ProvisionError):
            cleanup.references(self.database)

    def test_quiesces_only_isolated_services_and_resumes_reverse_order(self):
        result = self.run_cleanup()
        self.assertEqual(result["reason"], "complete")
        stopped = [unit for action, unit in self.calls if action == "stop"]
        started = [unit for action, unit in self.calls if action == "start"]
        self.assertEqual(stopped, cleanup.UNITS)
        self.assertEqual(started, list(reversed(cleanup.UNITS)))
        self.assertFalse((self.state / "cleanup-active.json").exists())

    def test_provider_or_application_references_skip_deletion(self):
        file = self.staging / "orphan"
        file.write_bytes(b"keep")
        result = cleanup.cleanup(self.state, self.database, self.staging, control=self.control, provider=lambda _: True)
        self.assertEqual(result["reason"], "provider-references")
        self.assertNotIn(("stop", "docker-slskd-aurral.service"), self.calls)
        result = self.run_cleanup(snapshot=lambda _: (1, set()))
        self.assertEqual(result["reason"], "application-references")
        self.assertEqual(file.read_bytes(), b"keep")

    def test_snapshot_failure_resumes_services(self):
        with self.assertRaises(cleanup.ProvisionError):
            self.run_cleanup(snapshot=lambda _: (_ for _ in ()).throw(cleanup.ProvisionError("unavailable")))
        self.assertEqual([unit for action, unit in self.calls if action == "start"], list(reversed(cleanup.UNITS)))

    def test_failed_resume_retains_private_journal_for_recovery(self):
        cleanup.atomic_json(self.state / "cleanup-active.json", {"units": cleanup.UNITS})
        with self.assertRaises(OSError):
            cleanup.resume(self.state, lambda *_: (_ for _ in ()).throw(OSError()))
        journal = self.state / "cleanup-active.json"
        self.assertEqual(journal.stat().st_mode & 0o777, 0o600)
        cleanup.resume(self.state, self.control)
        self.assertFalse(journal.exists())

    def test_malformed_recovery_journal_never_controls_other_units(self):
        for units in [[{}], ["navidrome.service"], [cleanup.UNITS[0]] * 2, "invalid"]:
            with self.subTest(units=units):
                cleanup.atomic_json(self.state / "cleanup-active.json", {"units": units})
                with self.assertRaises(cleanup.ProvisionError):
                    cleanup.resume(self.state, self.control)
        self.assertEqual(self.calls, [])

    def test_inactive_downloader_does_not_restart_manually_stopped_services(self):
        def control(action, unit, *args):
            value = self.control(action, unit, *args)
            return "inactive" if action == "show" and args[0] == "--property=ActiveState" else value
        result = cleanup.cleanup(self.state, self.database, self.staging, control=control)
        self.assertEqual(result["reason"], "downloader-inactive")
        self.assertFalse(any(action in ("start", "stop") for action, _ in self.calls))

    def test_provider_redirect_is_rejected_before_forwarding(self):
        with self.assertRaises(cleanup.ProvisionError):
            cleanup.NoRedirect().redirect_request(None, None, 302, "redirect", {}, "http://example.com")


if __name__ == "__main__":
    unittest.main()
