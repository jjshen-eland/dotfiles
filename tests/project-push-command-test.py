"""Exercise Project's published push commands against the actual outward gate.

No network or model calls. Native model traces are captured separately by
project-push-model-eval.py; these tests do not claim behavior acceptance.
"""

import importlib.util
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("outward_gate", ROOT / "scripts/outward-action-gate.py")
gate = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = gate
spec.loader.exec_module(gate)
REFERENCES = ROOT / "shared/skills/project/references"


def published_pushes():
    for name in ["log-prepare.md", "ship-paths.md", "ship-exceptions.md"]:
        text = (REFERENCES / name).read_text()
        snippets = re.findall(r"`([^`\n]*\bgit\b[^`\n]*\bpush\b[^`\n]*)`", text)
        snippets += [line.split("#", 1)[0].strip() for line in text.splitlines()
                     if re.match(r"^git\s.*\bpush\b", line)]
        for command in snippets:
            if command.startswith("git ") and not any(x in command for x in ["--dry-run", "git push`"]):
                # Bare command names in explanations are not runnable examples.
                if "<" in command or "-u origin" in command:
                    yield name, command


def run(work, *args):
    return subprocess.run(args, cwd=work, capture_output=True, text=True, check=True)


class PushContract(unittest.TestCase):
    def test_lease_oracle_requires_the_exact_branch_and_expected_sha(self):
        eval_spec = importlib.util.spec_from_file_location("push_eval", ROOT / "tests/project-push-model-eval.py")
        eval_module = importlib.util.module_from_spec(eval_spec)
        eval_spec.loader.exec_module(eval_module)
        expected = "a" * 40
        for ref in ["feat/change", "refs/heads/feat/change"]:
            argv = ["git", "push", f"--force-with-lease={ref}:{expected}", "publish", "feat/change"]
            self.assertTrue(eval_module.has_anchored_lease(argv, "feat/change", expected))
        for lease in ["--force-with-lease", "--force-with-lease=feat/change:" + "b" * 40,
                      "--force-with-lease=refs/heads/main:" + expected]:
            self.assertFalse(eval_module.has_anchored_lease(["git", "push", lease], "feat/change", expected))

    def test_bootstrap_helper_emits_executable_command_and_separate_workdir(self):
        with tempfile.TemporaryDirectory(prefix="project-bootstrap-") as temporary:
            base = Path(temporary)
            work, remote = base / "repo with space", base / "remote.git"
            work.mkdir()
            run(base, "git", "init", "--bare", "-q", "-b", "main", str(remote))
            run(work, "git", "init", "-q", "-b", "main")
            run(work, "git", "config", "core.hooksPath", "/dev/null")
            run(work, "git", "config", "user.name", "Eval")
            run(work, "git", "config", "user.email", "eval@example.invalid")
            (work / "file").write_text("baseline\n")
            run(work, "git", "add", "file"); run(work, "git", "commit", "-qm", "baseline")
            baseline = run(work, "git", "rev-parse", "HEAD").stdout.strip()
            run(work, "git", "switch", "-qc", "feat/extra")
            (work / "file").write_text("feature\n")
            run(work, "git", "add", "file"); run(work, "git", "commit", "-qm", "feature")
            run(work, "git", "remote", "add", "publish", str(remote))
            provider = base / "provider.py"
            provider.write_text("#!/usr/bin/env python3\nimport sys\na=sys.argv[1:]\n"
                                "if a[:2]==['repo','view']: print('fixture/bootstrap')\n"
                                "elif a[:1]==['api']: print('[]' if 'rules/branches/' in a[1] else 'main')\n"
                                "else: sys.exit(1)\n")
            provider.chmod(0o755)
            helper = ROOT / "shared/skills/project/scripts/ship-state.sh"
            def detect():
                return subprocess.run([str(helper), str(work)], cwd=base, text=True, capture_output=True,
                                      env=dict(os.environ, SHIP_STATE_GH=str(provider)), check=True).stdout
            output = detect()
            self.assertIn("verdict: BOOTSTRAP", output)
            fields = dict(line.split(": ", 1) for line in output.splitlines() if line.startswith("bootstrap-"))
            self.assertEqual(fields.get("bootstrap-workdir"), str(work.resolve()))
            self.assertEqual(gate.classify(fields["bootstrap-cmd"]).render(), "push canonical")
            run(Path(fields["bootstrap-workdir"]), *shlex.split(fields["bootstrap-cmd"]))
            self.assertEqual(run(base, "git", "--git-dir", str(remote), "rev-parse", "refs/heads/main").stdout.strip(), baseline)
            self.assertNotIn("refs/heads/feat/extra", run(work, "git", "ls-remote", "--heads", "publish").stdout)
            self.assertNotIn("bootstrap-cmd:", detect())

    def test_published_commands_reach_policy_without_opaque_deny(self):
        commands = list(published_pushes())
        self.assertGreaterEqual(len(commands), 4)
        for source, command in commands:
            with self.subTest(source=source, command=command):
                finding = gate.classify(command)
                self.assertIsNotNone(finding)
                self.assertEqual(finding.render(), "push canonical")
                self.assertIsNone(gate.hook_response(finding))

    def test_opaque_controls_still_denied(self):
        for command in ["git -C /tmp/repo push origin feat/x",
                        "cd /tmp/repo && git push origin feat/x",
                        "bash -lc 'git push origin feat/x'"]:
            with self.subTest(command=command):
                response = gate.hook_response(gate.classify(command))
                self.assertEqual(response["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_command_and_workdir_keep_space_path_remote_and_lease(self):
        with tempfile.TemporaryDirectory(prefix="project-push-") as temporary:
            base = Path(temporary)
            work, remote, decoy = [base / name for name in ["repo with space", "remote.git", "decoy"]]
            work.mkdir(); decoy.mkdir()
            run(base, "git", "init", "--bare", "-q", "-b", "main", str(remote))
            run(work, "git", "init", "-q", "-b", "feat/change")
            run(work, "git", "config", "core.hooksPath", "/dev/null")
            run(work, "git", "config", "user.name", "Eval")
            run(work, "git", "config", "user.email", "eval@example.invalid")
            (work / "file").write_text("base\n")
            run(work, "git", "add", "file")
            run(work, "git", "commit", "-qm", "fixture")
            run(work, "git", "remote", "add", "publish", str(remote))
            template = next(command for name, command in published_pushes()
                            if name == "ship-paths.md" and "<feature-branch>" in command)
            command = template.replace("<repo>", shlex.quote(str(work))).replace("origin", "publish").replace("<feature-branch>", "feat/change")
            self.assertEqual(gate.classify(command).render(), "push canonical")
            run(work, *shlex.split(command))
            old = run(work, "git", "rev-parse", "HEAD").stdout.strip()
            (work / "file").write_text("rewritten\n")
            run(work, "git", "add", "file")
            run(work, "git", "commit", "--amend", "-qm", "rewritten fixture")
            push = f"git push --force-with-lease=refs/heads/feat/change:{old} publish feat/change"
            self.assertEqual(gate.classify(push).render(), "push canonical")
            run(work, *shlex.split(push))
            expected = run(work, "git", "rev-parse", "HEAD").stdout.strip()
            self.assertEqual(run(base, "git", "--git-dir", str(remote), "rev-parse", "refs/heads/feat/change").stdout.strip(), expected)
            self.assertEqual(list(decoy.iterdir()), [])
            # A stale lease must fail when a different rewrite is actually requested.
            (work / "file").write_text("another rewrite\n")
            run(work, "git", "add", "file")
            run(work, "git", "commit", "--amend", "-qm", "second rewrite")
            rejected = subprocess.run(shlex.split(push), cwd=work, capture_output=True, text=True)
            self.assertNotEqual(rejected.returncode, 0)
            self.assertEqual(run(base, "git", "--git-dir", str(remote), "rev-parse", "refs/heads/feat/change").stdout.strip(), expected)


if __name__ == "__main__":
    unittest.main()
