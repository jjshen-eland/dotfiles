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

    def test_materialize_rebuilds_subject_outside_target(self):
        with tempfile.TemporaryDirectory(prefix="review-materialize-") as tmp:
            tmp = Path(tmp).resolve()
            repo = tmp / "repo"
            repo.mkdir()
            env = dict(os.environ, DOTFILES_PRECOMMIT_OFF="1", TMPDIR=str(tmp), GIT_OPTIONAL_LOCKS="0",
                       GIT_TRACE=str(tmp / "git.trace"))
            scope = str(ROOT / "shared/skills/deep-review/scripts/review-scope.sh")

            def run(*args, ok=True):
                result = subprocess.run(args, cwd=repo, env=env, text=True, capture_output=True)
                if ok:
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                return result

            run("git", "init", "-q", "-b", "fix/example")
            run("git", "config", "user.name", "fixture")
            run("git", "config", "user.email", "fixture@example.invalid")
            run("git", "config", "maintenance.auto", "false")
            run("git", "config", "gc.auto", "0")
            files = {".gitignore": "logs/\n", "app/main.py": "VALUE = 1\n", "app/gone.py": "OLD = 1\n",
                     "docs/note.md": "base\n"}
            for name, content in files.items():
                (repo / name).parent.mkdir(parents=True, exist_ok=True)
                (repo / name).write_text(content)
            run("git", "add", *files)
            run("git", "commit", "-qm", "test: seed")
            self.assertNotIn("maintenance run --auto", (tmp / "git.trace").read_text())
            (repo / "app/main.py").write_text("VALUE = 2\n")
            (repo / "app/gone.py").unlink()
            (repo / "app/new.py").write_text("NEW = 1\n")
            (repo / "docs/note.md").write_text("outside selected path\n")
            (repo / "logs").mkdir()
            (repo / "logs/app.log").write_text("ignored\n")

            def entries(path):
                # Full metadata: an empty directory or an mtime-only change is a target write.
                return {str(p.relative_to(path)): (p.lstat().st_mode, p.lstat().st_size, p.lstat().st_mtime_ns,
                                                   p.read_bytes() if p.is_file() else None)
                        for p in path.rglob("*")}

            def files_of(path):
                return {str(p.relative_to(path)): p.read_text() for p in path.rglob("*") if p.is_file()}

            def capture(*args):
                out = run("bash", scope, "capture", "--repo", str(repo), *args).stdout
                return next(x.removeprefix("manifest: ") for x in out.splitlines() if x.startswith("manifest: "))

            before = entries(repo)
            manifest = capture("--mode", "working-tree", "--path", "app")
            out = run("bash", scope, "materialize", "--manifest", manifest, "--dest", str(tmp / "snap")).stdout
            self.assertIn("verdict: MATERIALIZED", out)
            self.assertEqual(files_of(tmp / "snap"), {".gitignore": "logs/\n", "app/main.py": "VALUE = 2\n",
                                                      "app/new.py": "NEW = 1\n", "docs/note.md": "base\n"})
            self.assertEqual(entries(repo), before)

            for dest in (repo / "inside", repo / ".git/inside", tmp / "snap"):
                with self.subTest(dest=str(dest)):
                    self.assertEqual(run("bash", scope, "materialize", "--manifest", manifest,
                                         "--dest", str(dest), ok=False).returncode, 2)
                    self.assertFalse((repo / "inside").exists() or (repo / ".git/inside").exists())

            head = run("git", "rev-parse", "HEAD").stdout.strip()
            # A linked worktree's Git directory lives in the main checkout, outside the worktree root.
            run("git", "worktree", "add", "-q", "--detach", str(tmp / "linked"), head)
            out = run("bash", scope, "capture", "--repo", str(tmp / "linked"), "--mode", "working-tree").stdout
            linked = next(x.removeprefix("manifest: ") for x in out.splitlines() if x.startswith("manifest: "))
            self.assertEqual(run("bash", scope, "materialize", "--manifest", linked,
                                 "--dest", str(repo / ".git/linked-snap"), ok=False).returncode, 2)
            self.assertFalse((repo / ".git/linked-snap").exists())
            before = entries(repo)

            ranged = capture("--mode", "range", "--range", f"{EMPTY_TREE}..{head}")
            run("bash", scope, "materialize", "--manifest", ranged, "--dest", str(tmp / "range"))
            self.assertEqual(files_of(tmp / "range"), files)
            self.assertEqual(entries(repo), before)

            (repo / "app/main.py").write_text("VALUE = 3\n")
            stale = run("bash", scope, "materialize", "--manifest", manifest, "--dest", str(tmp / "stale"), ok=False)
            self.assertEqual(stale.returncode, 5)
            self.assertIn("verdict: BLOCKED", stale.stdout)
            self.assertFalse((tmp / "stale").exists())


EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
unittest.main()
