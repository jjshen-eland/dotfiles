"""Standalone brewup coverage uses the same isolated oracle as the full suite."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENTRY = ROOT / "tests/brewup-tests.sh"


class BrewupEntryTests(unittest.TestCase):
    def run_entry(self, script=None):
        env = dict(os.environ)
        env.pop("BREWUP_TEST_SCRIPT", None)
        if script is not None:
            env["BREWUP_TEST_SCRIPT"] = str(script)
        result = subprocess.run(["bash", str(ENTRY)], cwd="/", env=env,
                                text=True, capture_output=True)
        return result, result.stdout + result.stderr

    def test_current_source_passes_in_standalone_mode(self):
        result, output = self.run_entry()
        self.assertEqual(result.returncode, 0, output)
        self.assertIn("BREWUP_RESULT pass=34 fail=0", output)

    def test_missing_update_reproduces_original_five_failures(self):
        source = (ROOT / "scripts/brewup.sh").read_text()
        old = next(line for line in source.splitlines() if "bun update -g || echo" in line)
        self.assertEqual(source.count(old), 1, "mutation prerequisite changed")
        source = source.replace(old, "    bun outdated -g >/dev/null 2>&1", 1)
        with tempfile.TemporaryDirectory(prefix="brewup-entry-mutant-") as directory:
            script = Path(directory) / "brewup.sh"
            script.write_text(source)
            script.chmod(0o755)
            result, output = self.run_entry(script)
        self.assertEqual(result.returncode, 1, output)
        self.assertIn("BREWUP_RESULT pass=29 fail=5", output)


if __name__ == "__main__":
    unittest.main()
