from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "modules/services/tools/media-provision"))
from decypharr import ProvisionError
from slskd_aurral import render


class SlskdAurralTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.state = self.root / "state"
        self.state.mkdir()
        self.credentials = self.root / "credentials.json"

    def test_private_credentials_isolated_paths_and_no_network(self):
        config = render(self.state, self.credentials)
        self.assertTrue(config["flags"]["no_connect"])
        self.assertEqual(config["shares"]["directories"], [])
        self.assertEqual(config["web"]["port"], 5032)
        self.assertEqual(config["web"]["ip_address"], "127.0.0.1")
        self.assertEqual(config["soulseek"]["listen_port"], 50310)
        self.assertEqual(config["retention"]["files"], {"complete": None, "incomplete": None})
        self.assertEqual(config["web"]["authentication"]["api_keys"]["aurral"]["role"], "administrator")
        self.assertTrue(config["directories"]["downloads"].startswith("/data/downloads/slskd/"))
        for path in [self.credentials, self.state / "slskd.yml"]:
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_repeat_preserves_credentials_and_converges(self):
        first = render(self.state, self.credentials)
        seed = self.credentials.read_bytes()
        (self.state / "slskd.yml").write_text("{}")
        self.assertEqual(render(self.state, self.credentials), first)
        self.assertEqual(self.credentials.read_bytes(), seed)
        connected = render(self.state, self.credentials, connect=True)
        self.assertFalse(connected["flags"]["no_connect"])
        self.assertEqual(connected["soulseek"], first["soulseek"])

    def test_unmanaged_config_is_not_adopted(self):
        path = self.state / "slskd.yml"
        path.write_text("existing")
        with self.assertRaises(ProvisionError):
            render(self.state, self.credentials)
        self.assertEqual(path.read_text(), "existing")
        self.assertFalse(self.credentials.exists())

    def test_public_seed_and_symlinks_are_rejected(self):
        render(self.state, self.credentials)
        self.credentials.chmod(0o644)
        with self.assertRaises(ProvisionError):
            render(self.state, self.credentials)
        self.credentials.chmod(0o600)
        link = self.root / "link"
        link.symlink_to(self.state, target_is_directory=True)
        with self.assertRaises(ProvisionError):
            render(link, self.credentials)


if __name__ == "__main__":
    unittest.main()
