"""Execute the documented local finish recipe against isolated Git repos."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
REFERENCE = ROOT / 'shared/skills/project/references/merge-workflow.md'


class LocalFinish(unittest.TestCase):
    def run_cmd(self, *args, **kw):
        return subprocess.run(args, cwd=self.repo, text=True, capture_output=True, **kw)

    def git(self, *args):
        return self.run_cmd(self.real_git, *args, check=True).stdout.strip()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.real_git = shutil.which('git')
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.repo / 'file').write_text('base\n')
        self.git('add', 'file')
        self.git('commit', '-qm', 'base')
        self.git('switch', '-qc', 'feat/item')
        (self.repo / 'file').write_text('item\n')
        self.git('add', 'file')
        self.git('commit', '-qm', 'item')
        self.head = self.git('rev-parse', 'HEAD')
        self.git('switch', '-q', 'main')
        self.git('merge', '--squash', 'feat/item')
        self.git('commit', '-qm', 'squashed item')
        self.merge = self.git('rev-parse', 'HEAD')
        self.origin = self.root / 'origin.git'
        self.git('init', '--bare', '-q', str(self.origin))
        self.git('remote', 'add', 'origin', str(self.origin))
        self.git('push', '-q', 'origin', 'main')
        self.git('switch', '-q', 'feat/item')
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'],
                        REAL_GIT=self.real_git, CALL_LOG=str(self.root / 'calls'),
                        repo=str(self.repo), default='main', feature='feat/item',
                        feature_head=self.head, repo_slug='fixture/repo', pr='1',
                        project_scripts=str(ROOT / 'shared/skills/project/scripts'),
                        PR_STATE='MERGED', PR_HEAD=self.head, MERGE_OID=self.merge)
        self.stub('git', '''#!/bin/bash
printf '%s\\n' "$*" >> "$CALL_LOG"
if [[ "${FAULT:-}" == ref_query && ( "$*" == *"show-ref"* || "$*" == *"for-each-ref"* ) ]]; then exit 128; fi
if [[ "$*" == *" pull "* || "$1" == pull ]]; then
  if [[ "${FAULT:-}" == pull ]]; then exit 42; fi
  "$REAL_GIT" "$@" || exit $?
  if [[ "${FAULT:-}" == dirty_after ]]; then touch "$repo/unexpected"; fi
  exit 0
fi
exec "$REAL_GIT" "$@"
''')
        self.stub('gh', '''#!/bin/bash
if [[ "${FAULT:-}" == query ]]; then exit 43; fi
if [[ "$1 $2" == 'pr view' ]]; then
  printf '%s\\t%s\\t%s\\n' "$PR_STATE" "$PR_HEAD" "$MERGE_OID"
fi
''')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text(body)
        path.chmod(0o755)

    def finish(self, conditional=False):
        blocks = re.findall(r'```bash\n(.*?)```', REFERENCE.read_text(), re.S)
        recipe = next(b for b in blocks if 'git -C' in b and 'switch' in b)
        # Also execute the historical recipe for the before arm.
        for old, new in [('<repo>', '"$repo"'), ('<default>', '"$default"'),
                         ('<feature>', '"$feature"'), ('<PR-number|URL>', '"$pr"'),
                         ('<merge-flag>', '--rebase')]:
            recipe = recipe.replace(old, new)
        if conditional:
            recipe = 'rc=0\n' + recipe.rstrip() + ' || rc=$?\nexit "$rc"'
        return self.run_cmd('bash', '-c', recipe, env=self.env)

    def branch_exists(self):
        return self.run_cmd(self.real_git, 'show-ref', '--verify', '--quiet',
                            'refs/heads/feat/item').returncode == 0

    def assert_stop(self):
        result = self.finish()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.branch_exists(), 'failure deleted feature ref')

    def test_success(self):
        self.assertEqual(self.finish().returncode, 0)
        self.assertFalse(self.branch_exists())
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.git('rev-parse', 'origin/main'))

    def test_already_cleaned_by_gh(self):
        self.git('switch', '-q', 'main')
        self.git('branch', '-D', 'feat/item')
        self.assertEqual(self.finish().returncode, 0)
        self.assertFalse(self.branch_exists())

    def test_pull_fast_forwards_local_default(self):
        self.git('update-ref', 'refs/heads/main', self.git('rev-parse', self.merge + '^'))
        self.assertEqual(self.finish().returncode, 0)
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.merge)
        self.assertFalse(self.branch_exists())

    def test_unrelated_current_branch(self):
        self.git('switch', '-qc', 'feat/other')
        self.assert_stop()
        self.assertEqual(self.git('branch', '--show-current'), 'feat/other')

    def test_pull_failure(self):
        self.env['FAULT'] = 'pull'
        self.assert_stop()

    def test_conditional_shell_context(self):
        self.env['FAULT'] = 'pull'
        result = self.finish(conditional=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.branch_exists())

    def test_dirty_before(self):
        (self.repo / 'unexpected').touch()
        self.assert_stop()
        self.assertEqual(self.git('branch', '--show-current'), 'feat/item')

    def test_dirty_after_pull(self):
        self.env['FAULT'] = 'dirty_after'
        self.assert_stop()

    def test_pr_head_mismatch(self):
        self.env['PR_HEAD'] = '0' * 40
        self.assert_stop()

    def test_not_merged(self):
        self.env['PR_STATE'] = 'OPEN'
        self.assert_stop()

    def test_query_failure(self):
        self.env['FAULT'] = 'query'
        self.assert_stop()

    def test_local_ref_query_failure(self):
        self.env['FAULT'] = 'ref_query'
        self.assert_stop()

    def test_merge_commit_not_in_default(self):
        self.env['MERGE_OID'] = self.head
        self.assert_stop()

    def test_feature_advanced(self):
        (self.repo / 'new').touch()
        self.git('add', 'new')
        self.git('commit', '-qm', 'new work')
        self.assert_stop()


if __name__ == '__main__':
    unittest.main()
