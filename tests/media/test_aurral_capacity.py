import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[2] / "modules/services/tools/media-provision"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("aurral_capacity", SOURCE / "aurral_capacity.py")
capacity = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capacity)


class CapacityTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.root.chmod(0o700)
        self.library = self.root / "library"
        self.staging = self.root / "staging"
        self.library.mkdir()
        self.staging.mkdir()
        self.flows = self.library / "_flows"
        self.flows.mkdir()

    def test_temporary_usage_excludes_kept_audio_and_links(self):
        (self.library / "kept.flac").write_bytes(b"k" * 100000)
        (self.flows / "link.flac").symlink_to(self.library / "kept.flac")
        (self.flows / "track.flac").write_bytes(b"t" * 10)
        (self.staging / "partial").write_bytes(b"p" * 20)
        status = capacity.measure(self.library, self.staging, 100000, 0)
        self.assertFalse(status["paused"])
        self.assertLess(status["temporaryBytes"], 100000)
        self.assertGreaterEqual(status["temporaryBytes"], 30)

    def test_budget_and_low_disk_refuse_acquisition(self):
        (self.staging / "partial").write_bytes(b"p" * 100)
        self.assertEqual(capacity.measure(self.library, self.staging, 1, 0)["reason"], "temporary-budget")
        self.assertEqual(capacity.measure(self.library, self.staging, 100000, 10**30)["reason"], "minimum-free-space")

    def test_missing_or_symlinked_roots_fail_closed(self):
        with self.assertRaises(capacity.ProvisionError):
            capacity.measure(self.root / "missing", self.staging, 100, 0)
        link = self.root / "link"
        link.symlink_to(self.library, target_is_directory=True)
        with self.assertRaises(capacity.ProvisionError):
            capacity.measure(link, self.staging, 100, 0)

    def test_pause_resume_controls_only_its_own_suspension(self):
        calls = []
        ready = {"paused": False, "reason": "ready"}
        paused = {"paused": True, "reason": "temporary-budget"}
        capacity.enforce(self.root, ready, calls.append)
        self.assertEqual(calls, [])
        capacity.enforce(self.root, paused, calls.append)
        capacity.enforce(self.root, ready, calls.append)
        capacity.enforce(self.root, ready, calls.append)
        self.assertEqual(calls, ["stop", "start"])
        self.assertEqual((self.root / "capacity.json").stat().st_mode & 0o777, 0o600)

    def test_failed_resume_preserves_suspension(self):
        capacity.enforce(self.root, {"paused": True}, lambda _: None)
        with self.assertRaises(OSError):
            capacity.enforce(self.root, {"paused": False}, lambda _: (_ for _ in ()).throw(OSError()))
        self.assertTrue(capacity.read_object(self.root / "capacity.json", protected=True)["paused"])

    def test_measurement_error_does_not_delete_any_files(self):
        audio = self.flows / "track.flac"
        audio.write_bytes(b"keep")
        with patch.object(capacity.os, "statvfs", side_effect=OSError()):
            with self.assertRaises(OSError):
                capacity.measure(self.library, self.staging, 100000, 0)
        self.assertEqual(audio.read_bytes(), b"keep")


if __name__ == "__main__":
    unittest.main()
