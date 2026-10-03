"""Read-only reuse decisions against real Git and filesystem changes."""
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "shared/skills/project/scripts/test-evidence.py"


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = pathlib.Path(self.tmp.name)
        self.git("init", "-q")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        (self.root / "src").mkdir()
        (self.root / "src/app").write_text("original\n")
        (self.root / "run").write_text("runner\n")
        self.git("add", "src/app", "run")
        self.git("commit", "-qm", "fixture")
        self.record = dict(command="./run", exit=0, stdout="passed", stderr="",
                           inputs=["src/", "run"], tested_commit=self.git("rev-parse", "HEAD").strip())

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.root, text=True)

    def invoke(self, action="check", record=None, *args):
        cmd = [sys.executable, str(SCRIPT), action, "--root", str(self.root), *args]
        if action == "check":
            cmd += ["--evidence", "-"]
        proc = subprocess.run(cmd, input=json.dumps(self.record if record is None else record),
                              text=True, capture_output=True)
        self.assertIn(proc.returncode, [0, 1, 2], proc.stderr)
        result = json.loads(proc.stdout)
        return proc.returncode, result

    def verdict(self, expected, record=None, *args):
        before = self.git("status", "--porcelain=v1", "--untracked-files=all")
        rc, result = self.invoke("check", record, *args)
        self.assertEqual(result["verdict"], expected, result)
        self.assertEqual(rc, {"REUSE": 0, "NEED_TEST": 1, "ERROR": 2}[expected])
        self.assertEqual(before, self.git("status", "--porcelain=v1", "--untracked-files=all"))
        return result

    def test_summary_is_not_result(self):
        self.verdict("NEED_TEST", {"author_summary": "All tests passed; implementation complete."})

    def test_docs_commit_does_not_invalidate(self):
        (self.root / "README.md").write_text("documentation")
        self.git("add", "README.md")
        self.git("commit", "-qm", "docs")
        self.verdict("REUSE")

    def test_combined_tool_output_needs_no_fabricated_stderr(self):
        del self.record["stdout"]
        del self.record["stderr"]
        self.record["output"] = "passed\n"
        self.verdict("REUSE")

    def test_failed_missing_and_boolean_exit(self):
        for value in [1, None, False, "0"]:
            with self.subTest(value=value):
                self.verdict("NEED_TEST", dict(self.record, exit=value))
        del self.record["stdout"]
        self.verdict("NEED_TEST")

    def test_source_runner_and_mode_changes(self):
        for name in ["src/app", "run"]:
            with self.subTest(name=name):
                (self.root / name).write_text("changed")
                self.assertIn(name, self.verdict("NEED_TEST")["changed_inputs"])
                self.git("restore", name)
        (self.root / "run").chmod(0o755)
        self.verdict("NEED_TEST")

    def test_index_and_committed_change(self):
        (self.root / "src/app").write_text("different")
        self.git("add", "src/app")
        self.verdict("NEED_TEST")
        self.git("commit", "-qm", "change")
        self.verdict("NEED_TEST")

    def test_untracked_and_ignored_inputs(self):
        (self.root / ".gitignore").write_text("src/extra\n")
        (self.root / "src/extra").write_text("new input")
        self.assertIn("src/extra", self.verdict("NEED_TEST")["changed_inputs"])

    def test_snapshot_covers_dirty_and_untracked(self):
        (self.root / "src/app").write_text("tested dirty")
        (self.root / "src/new").write_text("tested untracked")
        rc, snap = self.invoke("snapshot", None, "--input", "src/", "--input", "run")
        self.assertEqual(rc, 0)
        self.record.update(snap)
        self.verdict("REUSE")
        (self.root / "src/new").unlink()
        self.assertIn("src/new", self.verdict("NEED_TEST")["changed_inputs"])

    def test_snapshot_follows_local_symlink_and_detects_target_change(self):
        (self.root / "target").write_text("target")
        (self.root / "src/link").symlink_to("../target")
        rc, snap = self.invoke("snapshot", None, "--input", "src/", "--input", "run")
        self.assertEqual(rc, 0)
        self.record.update(snap)
        self.verdict("REUSE")
        (self.root / "target").write_text("changed target")
        self.verdict("NEED_TEST")

    def test_environment_comparison(self):
        self.record["environment"] = {"python": "3.14"}
        self.verdict("NEED_TEST")
        self.verdict("REUSE", None, "--environment", '{"python":"3.14"}')
        self.verdict("NEED_TEST", None, "--environment", '{"python":"3.9"}')

    def test_nonimmutable_or_missing_anchor(self):
        for anchor in ["HEAD", "f" * 40, None]:
            with self.subTest(anchor=anchor):
                self.verdict("NEED_TEST", dict(self.record, tested_commit=anchor))

    def test_literal_paths_and_no_traversal(self):
        for path in ["../escape", "/tmp", ":(exclude)src", "src/../run", ""]:
            with self.subTest(path=path):
                self.verdict("NEED_TEST", dict(self.record, inputs=[path]))
        (self.root / "src/[test]").write_text("literal")
        self.git("add", "src/[test]")
        self.git("commit", "-qm", "literal path")
        self.record.update(inputs=["src/[test]"], tested_commit=self.git("rev-parse", "HEAD").strip())
        self.verdict("REUSE")

    def test_invalid_json_is_error(self):
        p = subprocess.run([sys.executable, str(SCRIPT), "check", "--root", str(self.root),
                            "--evidence", "-"], input="{", text=True, capture_output=True)
        self.assertEqual(p.returncode, 2)
        self.assertEqual(json.loads(p.stdout)["verdict"], "ERROR")


if __name__ == "__main__":
    unittest.main()
