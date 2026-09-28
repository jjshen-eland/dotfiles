"""Behavioral boundary tests for the isolated #229 authority candidate."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HELPER = Path(sys.argv.pop(1)).resolve()


class BindingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="229-binding-test-")
        self.repo = Path(self.tmp.name).resolve()
        self.env = dict(os.environ, DOTFILES_PRECOMMIT_OFF="1")
        self.git("init", "-q", "-b", "feat/increment-two")
        self.git("config", "user.name", "fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        (self.repo / ".doc-governance.json").write_text(json.dumps({"status_schema": {"path": "STATUS.md", "active_item_contract": {}}}))
        self.fields = dict(heading="Orders migration", writer="codex:orders", workspace="branch=feat/increment-one", steward="codex:orders", scope="src/, tests/, STATUS.md")
        self.status()
        self.git("add", "STATUS.md", ".doc-governance.json")
        self.git("commit", "-qm", "chore: seed fixture")
        self.bound = self.fingerprint()

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repo), *args], env=self.env, stderr=subprocess.PIPE, text=True).strip()

    def status(self, progress="working"):
        f = self.fields
        (self.repo / "STATUS.md").write_text(f"# Status\n\n## 進行中\n\n### {f['heading']}\n\n- **Writer**：{f['writer']}\n- **Workspace**：{f['workspace']}\n- **Write Scope**：{f['scope']}\n- **Dossier Steward**：{f['steward']}\n- **進度**：{progress}\n\n## 暫停中\n")

    def fingerprint(self):
        payload = {"version": 1, "root": str(self.repo), "items": [self.fields]}
        return hashlib.sha256(json.dumps(payload, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()

    def call(self, *args):
        return subprocess.run([sys.executable, str(HELPER), "--root", str(self.repo), "--runtime", "codex", *args], capture_output=True, text=True)

    def bound_call(self, **kwargs):
        return self.call("--session-resume-actor", kwargs.get("actor", "codex:orders"), "--expected-assignment", kwargs.get("fingerprint", self.bound), "--expected-head", kwargs.get("head", self.git("rev-parse", "HEAD")))

    def test_initial_still_requires_direction(self):
        out = self.call()
        self.assertEqual(out.returncode, 1, out.stdout + out.stderr)

    def test_bound_workline_continues(self):
        out = self.bound_call()
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertIn("authority-source: current-session-workline-binding", out.stdout)

    def test_progress_and_new_commit_do_not_revoke_assignment(self):
        self.status("increment one verified; increment two ready")
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: update progress")
        self.assertEqual(self.bound_call().returncode, 0)

    def test_assignment_changes_block_at_unchanged_head(self):
        original = dict(self.fields)
        for field, value in [("writer", "codex:worker"), ("scope", "src/, credentials/"), ("workspace", "branch=feat/other"), ("steward", "codex:new-owner"), ("heading", "Different work item")]:
            with self.subTest(field=field):
                self.fields = {**original, field: value}
                self.status()
                out = self.bound_call()
                self.assertEqual(out.returncode, 1, out.stdout + out.stderr)
                self.assertIn("stale-workline-assignment", out.stdout)

    def test_wrong_repo_fingerprint_blocks(self):
        out = self.bound_call(fingerprint="0" * 64)
        self.assertEqual(out.returncode, 1)

    def test_snapshot_required(self):
        self.assertEqual(self.call("--session-resume-actor", "codex:orders").returncode, 2)

    def test_stale_head_blocks(self):
        old = self.git("rev-parse", "HEAD")
        self.status("later")
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: later")
        self.assertEqual(self.bound_call(head=old).returncode, 1)

    def test_human_and_cross_runtime_binding_rejected(self):
        for actor in ["owner:maintainer", "claude:orders"]:
            self.assertEqual(self.bound_call(actor=actor).returncode, 2)

    def test_completed_item_does_not_revive_from_parent(self):
        (self.repo / "STATUS.md").write_text("# Status\n\n## 進行中\n\n## 暫停中\n")
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: complete task")
        head = self.git("rev-parse", "HEAD")
        out = self.call("--session-resume-actor", "codex:orders", "--expected-assignment", self.bound, "--expected-head", head, "--commit", head)
        self.assertEqual(out.returncode, 1, out.stdout + out.stderr)

    def test_completion_candidate_uses_exact_parent_assignment(self):
        parent = self.git("rev-parse", "HEAD")
        (self.repo / "STATUS.md").write_text("# Status\n\n## 進行中\n\n## 暫停中\n")
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: complete task")
        candidate = self.git("rev-parse", "HEAD")
        out = self.call(
            "--session-resume-actor", "codex:orders",
            "--expected-assignment", self.bound,
            "--expected-head", candidate,
            "--commit", candidate,
            "--completion-parent", parent,
        )
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertIn("durable-steward-source: completion-candidate-parent-active-state", out.stdout)
        self.assertIn("authority-source: current-session-workline-binding", out.stdout)
        self.assertIn("completion-candidate: READY", out.stdout)

    def test_completion_candidate_rejects_wrong_parent(self):
        parent = self.git("rev-parse", "HEAD")
        (self.repo / "STATUS.md").write_text("# Status\n\n## 進行中\n\n## 暫停中\n")
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: complete task")
        candidate = self.git("rev-parse", "HEAD")
        out = self.call(
            "--session-resume-actor", "codex:orders",
            "--expected-assignment", self.bound,
            "--expected-head", candidate,
            "--commit", candidate,
            "--completion-parent", candidate,
        )
        self.assertEqual(out.returncode, 1, out.stdout + out.stderr)
        self.assertIn("completion-candidate-blocker: parent-mismatch", out.stdout)

    def candidate_rebuild_call(self, parent, candidate=None):
        candidate = candidate or self.git("rev-parse", "HEAD")
        return self.call(
            "--session-resume-actor", "codex:orders",
            "--expected-assignment", self.bound,
            "--expected-head", candidate,
            "--commit", candidate,
            "--candidate-parent", parent,
        )

    def make_shared_candidate(self):
        parent = self.git("rev-parse", "HEAD")
        self.status("candidate updates shared active state")
        self.git("add", "STATUS.md")
        self.git("commit", "-qm", "docs: candidate active-state update")
        return parent, self.git("rev-parse", "HEAD")

    def test_current_session_direct_child_candidate_is_rebuildable(self):
        parent, candidate = self.make_shared_candidate()
        out = self.candidate_rebuild_call(parent, candidate)
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertIn("candidate-provenance: current-session-direct-child", out.stdout)
        self.assertIn("candidate-rebuild: READY", out.stdout)

    def test_candidate_rebuild_requires_exact_parent_and_clean_tree(self):
        parent, candidate = self.make_shared_candidate()
        wrong_parent = self.git("rev-parse", f"{parent}^") if self.git("rev-list", "--count", parent) != "1" else candidate
        out = self.candidate_rebuild_call(wrong_parent, candidate)
        self.assertEqual(out.returncode, 1, out.stdout + out.stderr)
        self.assertIn("candidate-rebuild-blocker: parent-mismatch", out.stdout)

        (self.repo / "unowned.tmp").write_text("dirty\n")
        out = self.candidate_rebuild_call(parent, candidate)
        self.assertEqual(out.returncode, 1, out.stdout + out.stderr)
        self.assertIn("candidate-rebuild-blocker: working-tree-not-clean", out.stdout)

    def test_remote_visible_candidate_is_not_rebuildable(self):
        parent, candidate = self.make_shared_candidate()
        self.git("update-ref", "refs/remotes/origin/already-pushed", candidate)
        out = self.candidate_rebuild_call(parent, candidate)
        self.assertEqual(out.returncode, 1, out.stdout + out.stderr)
        self.assertIn("candidate-rebuild-blocker: remote-tracking-ref-contains-candidate", out.stdout)

    def test_candidate_parent_requires_session_binding_snapshot(self):
        parent, candidate = self.make_shared_candidate()
        out = self.call("--commit", candidate, "--candidate-parent", parent)
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)

        out = self.call(
            "--session-resume-actor", "codex:orders",
            "--expected-assignment", self.bound,
            "--expected-head", candidate,
            "--commit", "HEAD",
            "--candidate-parent", parent,
        )
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)


unittest.main()
