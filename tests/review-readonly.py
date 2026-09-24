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
            tracked = repo / "data.txt"
            tracked.write_text("unchanged content\n")
            run("git", "add", "data.txt")
            run("git", "commit", "-qm", "test: seed")
            stat = tracked.stat()
            os.utime(tracked, ns=(stat.st_atime_ns, stat.st_mtime_ns + 2_000_000_000))

            def snapshot():
                return {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in repo.rglob("*") if p.is_file()}

            before = snapshot()
            scope = str(ROOT / "shared/skills/deep-review/scripts/review-scope.sh")
            output = run("bash", scope, "capture", "--repo", str(repo), "--mode", "working-tree")
            self.assertEqual(before, snapshot(), "capture altered target metadata")
            manifest = next(line.removeprefix("manifest: ") for line in output.splitlines()
                            if line.startswith("manifest: "))
            for action in ("show", "verify", "autofix-check"):
                run("bash", scope, action, "--manifest", manifest)
                self.assertEqual(before, snapshot(), action + " altered target metadata")
            run("bash", str(ROOT / "shared/skills/deep-review/scripts/review-terminal.sh"),
                "show", "--repo", str(repo))
            self.assertEqual(before, snapshot(), "read-only review altered repository metadata")


unittest.main()
