"""Exercise the shipped PowerShell script against an installed Codex app-server.

Run with Python 3.11+: python tests/test_integration.py [absolute codex.exe]
All generated files stay in this checkout's ignored .work directory.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "plugins/default-browser/skills/default-browser/scripts/Set-CodexLinkTarget.ps1"
KEYS = ("open-link-in-target-preference", "open-local-url-in-target-preference")
BACKUP = ".default-browser-plugin-backup.json"
if len(sys.argv) > 1:
    CODEX = Path(sys.argv.pop(1)).resolve()
else:
    candidates = list((Path(os.environ["LOCALAPPDATA"]) / "OpenAI/Codex/bin").glob("*/codex.exe"))
    CODEX = max(candidates, key=lambda p: p.stat().st_mtime)


class Integration(unittest.TestCase):
    def setUp(self):
        (ROOT / ".work").mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="link-test-", dir=ROOT / ".work")
        self.home = Path(self.temp.name)
        self.config = self.home / "config.toml"

    def tearDown(self):
        self.temp.cleanup()

    def write(self, text):
        self.config.write_text(text, encoding="utf-8")

    def read(self):
        return tomllib.loads(self.config.read_text(encoding="utf-8"))

    def run_action(self, action, success=True):
        result = subprocess.run(
            ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(SCRIPT),
             "-Action", action, "-CodexHome", str(self.home), "-CodexExecutable", str(CODEX), "-Verbose"],
            # Some embedded Python runtimes expose both PATH and Path. Windows
            # PowerShell's .NET Framework rejects that duplicate environment.
            env={key.upper(): value for key, value in os.environ.items()},
            capture_output=True, timeout=35,
        )
        if success:
            self.assertEqual(result.returncode, 0, (result.stdout + result.stderr).decode("utf-8", errors="replace"))
            return json.loads(result.stdout)
        self.assertNotEqual(result.returncode, 0)
        return result

    def test_round_trip_preserves_unrelated_later_edits(self):
        self.write('# 注释保留\nmodel = "gpt-6.1-sol"\n[desktop]\nsansFontSize = 16\n'
                   'open-link-in-target-preference = "in-app-browser"\n'
                   '[model_providers.example]\nname = "Keep me"\nenv_key = "DO_NOT_LEAK_THIS_VALUE"\n')
        before = self.config.read_bytes()
        status = self.run_action("Status")
        self.assertFalse(status["backupExists"])
        self.assertEqual(self.config.read_bytes(), before)
        enabled = self.run_action("Enable")
        self.assertTrue(enabled["changed"])
        self.assertNotIn("DO_NOT_LEAK_THIS_VALUE", json.dumps(enabled))
        self.assertEqual([self.read()["desktop"][k] for k in KEYS], ["external-browser"] * 2)
        self.write(self.config.read_text(encoding="utf-8").replace("sansFontSize = 16", "sansFontSize = 19"))
        self.run_action("Restore")
        config = self.read()
        self.assertEqual(config["desktop"][KEYS[0]], "in-app-browser")
        self.assertNotIn(KEYS[1], config["desktop"])
        self.assertEqual(config["desktop"]["sansFontSize"], 19)
        self.assertEqual(config["model_providers"]["example"]["env_key"], "DO_NOT_LEAK_THIS_VALUE")
        self.assertIn("# 注释保留", self.config.read_text(encoding="utf-8"))
        self.assertFalse((self.home / BACKUP).exists())

    def test_repeat_enable_preserves_first_backup(self):
        self.write('model = "gpt-6.1-sol"\n')
        self.run_action("Enable")
        backup = (self.home / BACKUP).read_bytes()
        result = self.run_action("Enable")
        self.assertFalse(result["changed"])
        self.assertEqual((self.home / BACKUP).read_bytes(), backup)
        self.run_action("Restore")
        self.assertFalse(self.read().get("desktop", {}))
        self.run_action("Restore", success=False)

    def test_invalid_toml_is_not_modified(self):
        self.write('[desktop\nbroken = "value"\n')
        before = self.config.read_bytes()
        self.run_action("Enable", success=False)
        self.assertEqual(self.config.read_bytes(), before)
        self.assertFalse((self.home / BACKUP).exists())

    def test_restore_preserves_newer_manual_choice(self):
        self.write('model = "gpt-6.1-sol"\n')
        self.run_action("Enable")
        self.write(self.config.read_text(encoding="utf-8").replace('"external-browser"', '"in-app-browser"'))
        before = self.config.read_bytes()
        self.run_action("Restore", success=False)
        self.assertEqual(self.config.read_bytes(), before)
        self.assertTrue((self.home / BACKUP).exists())

    def test_restore_original_two_explicit_values(self):
        original = ('[desktop]\nopen-link-in-target-preference = "external-browser"\n'
                    'open-local-url-in-target-preference = "in-app-browser"\n')
        self.write(original)
        self.run_action("Enable")
        self.run_action("Restore")
        self.assertEqual(self.read(), tomllib.loads(original))


if __name__ == "__main__":
    unittest.main(verbosity=2)
