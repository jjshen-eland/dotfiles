"""Review inspection must not mutate the target, including Git's index cache."""
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(sys.argv.pop(1)).resolve()


class ReadonlyReview(unittest.TestCase):
    def test_inspection_preserves_git_metadata(self):
        with tempfile.TemporaryDirectory(prefix="review-readonly-") as tmp:
            repo = Path(tmp) / "repo"
            repo.mkdir()
            env = dict(os.environ, DOTFILES_PRECOMMIT_OFF="1", TMPDIR=tmp)
            env.pop("GIT_OPTIONAL_LOCKS", None)

            def run(*args):
                return subprocess.run(args, cwd=repo, env=env, text=True,
                                      capture_output=True, check=True).stdout

            run("git", "init", "-q", "-b", "fix/example")
            run("git", "config", "user.name", "fixture")
            run("git", "config", "user.email", "fixture@example.invalid")
            run("git", "config", "maintenance.auto", "false")
            run("git", "config", "gc.auto", "0")
            tracked = repo / "data.txt"
            tracked.write_text("unchanged content\n")
            run("git", "add", "data.txt")
            run("git", "commit", "-qm", "test: seed")
            stat = tracked.stat()
            os.utime(tracked, ns=(stat.st_atime_ns, stat.st_mtime_ns + 2_000_000_000))

            def snapshot():
                return {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in repo.rglob("*") if p.is_file()}

            def assert_snapshot(expected, action):
                actual = snapshot()
                if expected == actual:
                    return
                expected_paths = set(expected)
                actual_paths = set(actual)
                added = sorted(actual_paths - expected_paths)
                removed = sorted(expected_paths - actual_paths)
                changed = sorted(path for path in expected_paths & actual_paths
                                 if expected[path] != actual[path])
                self.fail(f"{action} altered target metadata: added={added}; "
                          f"removed={removed}; changed={changed}")

            before = snapshot()
            scope = str(ROOT / "shared/skills/deep-review/scripts/review-scope.sh")
            output = run("bash", scope, "capture", "--repo", str(repo), "--mode", "working-tree")
            assert_snapshot(before, "capture")
            manifest = next(line.removeprefix("manifest: ") for line in output.splitlines()
                            if line.startswith("manifest: "))
            for action in ("show", "verify", "autofix-check"):
                run("bash", scope, action, "--manifest", manifest)
                assert_snapshot(before, action)
            run("bash", str(ROOT / "shared/skills/deep-review/scripts/review-terminal.sh"),
                "show", "--repo", str(repo))
            assert_snapshot(before, "read-only review")


unittest.main()
