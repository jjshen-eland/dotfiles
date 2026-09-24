"""Read-only preflight for an explicit current-user sequential reassignment."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HELPER = Path(sys.argv.pop(1)).resolve()


class AssignmentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="229-assignment-")
        self.repo = Path(self.tmp.name).resolve()
        self.env = dict(os.environ, DOTFILES_PRECOMMIT_OFF="1")
        self.git("init", "-q", "-b", "fix/orders")
        self.git("config", "user.name", "fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.items = [dict(heading="Orders", writer="claude:orders", workspace="branch=fix/orders", steward="claude:orders", scope="src/, STATUS.md")]
        (self.repo / ".doc-governance.json").write_text(json.dumps({"status_schema": {"active_item_contract": {}}}))
        self.status()
        self.git("add", "STATUS.md", ".doc-governance.json")
        self.git("commit", "-qm", "test: seed")
        self.head = self.git("rev-parse", "HEAD")
        self.bound = self.fingerprint()

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repo), *args], env=self.env, stderr=subprocess.PIPE, text=True).strip()

    def status(self):
        content = "# Status\n\n## 進行中\n"
        for item in self.items:
            content += f"\n### {item['heading']}\n"
            for label, key in [("Writer", "writer"), ("Workspace", "workspace"), ("Write Scope", "scope"), ("Dossier Steward", "steward")]:
                content += f"- **{label}**: {item[key]}\n"
        (self.repo / "STATUS.md").write_text(content + "\n## 暫停中\n")

    def fingerprint(self):
        payload = {"version": 1, "root": str(self.repo), "items": self.items}
        return hashlib.sha256(json.dumps(payload, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()

    def call(self, *extra, stopped=True, items=("Orders",), bound=None):
        args = [sys.executable, str(HELPER), "--root", str(self.repo), "--runtime", "codex", "--reassign-from", "claude:orders", "--expected-head", self.head, "--expected-assignment", bound or self.bound]
        if stopped:
            args.append("--prior-writer-stopped")
        for item in items:
            args += ["--assigned-item", item]
        return subprocess.run(args + list(extra), capture_output=True, text=True)

    def test_explicit_assignment_preflight_does_not_mutate(self):
        before = (self.repo / "STATUS.md").read_bytes()
        out = self.call()
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertIn("reassignment-target: codex:orders", out.stdout)
        self.assertIn("verdict: READY_FOR_REASSIGNMENT", out.stdout)
        self.assertNotIn("verdict: PASS", out.stdout)
        self.assertEqual(before, (self.repo / "STATUS.md").read_bytes())

    def test_not_stopped_is_not_assignment(self):
        self.assertNotEqual(self.call(stopped=False).returncode, 0)

    def completion_gate(self):
        return subprocess.run([sys.executable, str(HELPER), "--root", str(self.repo),
                               "--runtime", "codex", "--commit", self.git("rev-parse", "HEAD")],
                              capture_output=True, text=True)

    def test_combined_reassignment_and_retirement_has_no_new_parent_authority(self):
        # Reproduces the native failure: removing the item loses the uncommitted takeover.
        self.items = []
        self.status()
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: complete without recording takeover")
        result = self.completion_gate()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("durable-steward: claude:orders", result.stdout)

    def test_recorded_assignment_allows_completion_without_rewriting_history(self):
        self.items[0].update(writer="codex:orders", steward="codex:orders")
        self.status()
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: record assigned workline")
        self.items = []
        self.status()
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: complete assigned work")
        result = self.completion_gate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("durable-steward-source: commit-parent-active-state", result.stdout)
        self.assertIn("durable-steward: codex:orders", result.stdout)

    def test_conflict_preflight_preserves_index(self):
        tracked = self.repo / "STATUS.md"
        stat = tracked.stat()
        os.utime(tracked, ns=(stat.st_atime_ns, stat.st_mtime_ns + 2_000_000_000))
        index = self.repo / ".git/index"
        before = index.read_bytes()
        self.assertNotEqual(self.call(stopped=False).returncode, 0)
        self.assertEqual(before, index.read_bytes())

    def test_unknown_dirty_file_blocks_but_named_handoff_is_allowed(self):
        (self.repo / "src").mkdir()
        (self.repo / "src" / "owned.py").write_text("value = 1\n")
        self.assertEqual(self.call().returncode, 1)
        self.assertEqual(self.call("--owned-path", "src/owned.py").returncode, 0)
        (self.repo / "unknown.txt").write_text("not handed off\n")
        self.assertEqual(self.call("--owned-path", "src/owned.py").returncode, 1)

    def test_stale_assignment_blocks(self):
        self.items[0]["scope"] = "credentials/"
        self.status()
        self.assertEqual(self.call("--owned-path", "STATUS.md").returncode, 1)

    def test_stale_head_blocks(self):
        self.git("commit", "--allow-empty", "-qm", "test: advance")
        self.assertEqual(self.call().returncode, 1)

    def test_other_work_item_cannot_be_silently_transferred(self):
        self.items.append(dict(self.items[0], heading="Unrelated"))
        self.status()
        self.assertEqual(self.call("--owned-path", "STATUS.md", bound=self.fingerprint()).returncode, 1)

    def test_multiple_explicit_items_in_same_workline(self):
        self.items.append(dict(self.items[0], heading="Consumer"))
        self.status()
        out = self.call("--owned-path", "STATUS.md", items=("Orders", "Consumer"), bound=self.fingerprint())
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)

    def test_different_writer_blocks(self):
        self.items[0]["writer"] = "codex:competing"
        self.status()
        self.assertEqual(self.call("--owned-path", "STATUS.md", bound=self.fingerprint()).returncode, 1)

    def test_prepared_transfer_blocks(self):
        (self.repo / "docs").mkdir()
        (self.repo / "docs" / "transfer.md").write_text("PREPARED\n")
        self.assertEqual(self.call("--owned-path", "docs/transfer.md").returncode, 1)

    def test_wrong_workspace_blocks(self):
        self.items[0]["workspace"] = "branch=fix/other"
        self.status()
        self.assertEqual(self.call("--owned-path", "STATUS.md", bound=self.fingerprint()).returncode, 1)

    def test_invalid_owned_path_rejected(self):
        self.assertEqual(self.call("--owned-path", "../outside").returncode, 2)


unittest.main()
