"""Exercise PR-wide record selection and failure propagation with real Git."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest

SCRIPT = Path(__file__).resolve().with_name('run-ci.py')


class SelectionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.env = dict(os.environ, DOTFILES_PRECOMMIT_OFF='1', GITHUB_EVENT_NAME='pull_request')
        self.git('init', '-q', '-b', 'fixture-base')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        for name in ('STATUS.md', 'docs/backlog.md', 'docs/archive/milestones-2026-10.md',
                     'docs/plans/2026-10-09-work.md', 'AGENTS.md', 'app.py'):
            p = self.root / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text('# Original\n\nOriginal text.\n')
        self.git('add', 'STATUS.md', 'docs', 'AGENTS.md', 'app.py')
        self.git('commit', '-qm', 'fixture base')
        self.base = self.git('rev-parse', 'HEAD').strip()
        self.git('switch', '-qc', 'fixture-pr')

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.root, env=self.env, text=True)

    def commit(self, *names):
        self.git('add', '--', *names)
        self.git('commit', '-qm', 'fixture change')

    def select(self, execute=False, checkout_sha=None, **event_changes):
        head = self.git('rev-parse', 'HEAD').strip()
        event = {'pull_request': {'base': {'sha': self.base}, 'head': {'sha': head}}}
        event.update(event_changes)
        path = self.root / '.git/event.json'
        path.write_text(json.dumps(event))
        env = dict(self.env, GITHUB_EVENT_PATH=str(path), GITHUB_SHA=checkout_sha or head)
        result = subprocess.run([sys.executable, '-B', str(SCRIPT), '--root', str(self.root),
                                 *([] if execute else ['--select-only'])],
                                env=env, capture_output=True, text=True)
        return result, json.loads(result.stdout.splitlines()[0].removeprefix('CI_SELECTION '))

    def change_record(self, name='STATUS.md'):
        p = self.root / name
        p.write_text(p.read_text() + '\nUpdated observation.\n')
        self.commit(name)

    def test_existing_record_prose_uses_document_checks(self):
        for name in ('STATUS.md', 'docs/backlog.md', 'docs/archive/milestones-2026-10.md',
                     'docs/plans/2026-10-09-work.md'):
            self.change_record(name)
        result, plan = self.select()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(plan['mode'], 'records')
        self.assertEqual(len(plan['changed_paths']), 4)

    def test_earlier_code_commit_cannot_hide_behind_last_docs_commit(self):
        (self.root / 'app.py').write_text('changed\n')
        self.commit('app.py')
        self.change_record()
        self.assertEqual(self.select()[1]['mode'], 'full')

    def test_instructions_are_not_records(self):
        self.change_record('AGENTS.md')
        self.assertEqual(self.select()[1]['mode'], 'full')

    def test_heading_change_falls_back(self):
        (self.root / 'STATUS.md').write_text('# Different\n')
        self.commit('STATUS.md')
        self.assertEqual(self.select()[1]['mode'], 'full')

    def test_indented_or_empty_markdown_heading_falls_back(self):
        for heading in ('   ## Added heading', '##', '  Setext heading\n  ---'):
            with self.subTest(heading=heading):
                self.setUp()
                p = self.root / 'STATUS.md'
                p.write_text(p.read_text() + '\n' + heading + '\n')
                self.commit('STATUS.md')
                self.assertEqual(self.select()[1]['mode'], 'full')

    def test_new_deleted_renamed_and_mode_changed_records_fall_back(self):
        for mutation in ('new', 'delete', 'rename', 'executable', 'symlink'):
            with self.subTest(mutation=mutation):
                self.setUp()
                p = self.root / 'docs/backlog.md'
                if mutation == 'new':
                    p = self.root / 'docs/plans/2026-10-09-new.md'; p.write_text('new\n')
                elif mutation == 'delete':
                    p.unlink()
                elif mutation == 'rename':
                    p.rename(self.root / 'docs/renamed.md')
                elif mutation == 'executable':
                    p.chmod(0o755)
                else:
                    p.unlink(); p.symlink_to('../app.py')
                self.commit('docs', 'STATUS.md')
                self.assertEqual(self.select()[1]['mode'], 'full')

    def test_dirty_or_untracked_checkout_falls_back(self):
        self.change_record()
        for path in ('app.py', 'untracked'):
            (self.root / path).write_text('unvalidated input\n')
            self.assertEqual(self.select()[1]['mode'], 'full')

    def test_missing_or_invalid_event_and_empty_diff_fall_back(self):
        self.assertEqual(self.select()[1]['mode'], 'full')
        self.change_record()
        self.assertEqual(self.select(pull_request={})[1]['mode'], 'full')
        self.assertEqual(self.select(pull_request={'base': {'sha': 'f' * 40},
                                                 'head': {'sha': 'HEAD'}})[1]['mode'], 'full')

    def test_changed_checkout_identity_falls_back(self):
        self.change_record()
        self.assertEqual(self.select(checkout_sha='f' * 40)[1]['mode'], 'full')
        self.env['GITHUB_EVENT_NAME'] = 'push'
        self.assertEqual(self.select()[1]['mode'], 'full')

    def test_alias_to_changed_document_falls_back(self):
        (self.root / 'input-link').symlink_to('docs')
        self.commit('input-link')
        self.base = self.git('rev-parse', 'HEAD').strip()
        self.change_record('docs/backlog.md')
        self.assertEqual(self.select()[1]['mode'], 'full')

    def test_real_merge_checkout_is_supported(self):
        self.change_record()
        pr_head = self.git('rev-parse', 'HEAD').strip()
        self.git('switch', '-qc', 'fixture-merge', self.base)
        self.git('merge', '--no-ff', '-qm', 'synthetic merge', pr_head)
        event = {'base': {'sha': self.base}, 'head': {'sha': pr_head}}
        self.assertEqual(self.select(pull_request=event)[1]['mode'], 'records')
        (self.root / 'app.py').write_text('extra merge-tree change\n')
        self.git('add', 'app.py')
        self.git('commit', '--amend', '--no-edit', '-q')
        self.assertEqual(self.select(pull_request=event)[1]['mode'], 'full')

    def test_selected_check_failures_and_kernel_findings_propagate(self):
        tests = self.root / 'tests'; tests.mkdir()
        for name in ('kernel-gate.py', 'xref-gate.py', 'test_doc_governance.py'):
            (tests / name).write_text('print("" , end="")\n')
        self.commit('tests')
        self.base = self.git('rev-parse', 'HEAD').strip()
        self.change_record()
        result, plan = self.select(execute=True)
        self.assertEqual(plan['mode'], 'records')
        self.assertEqual(result.returncode, 0, result.stderr)
        # Commit a failing gate as accepted base so selection still concerns docs.
        for name, body in [('xref-gate.py', 'raise SystemExit(7)\n'),
                           ('xref-gate.py', 'print("[FINDING] fixture")\n'),
                           ('kernel-gate.py', 'print("[FINDING] fixture")\n')]:
            for p in tests.iterdir(): p.write_text('pass\n')
            (tests / name).write_text(body)
            self.commit('tests'); self.base = self.git('rev-parse', 'HEAD').strip()
            self.change_record()
            result, plan = self.select(execute=True)
            self.assertEqual(plan['mode'], 'records')
            self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_fallback_executes_full_suite_and_preserves_failure(self):
        tests = self.root / 'tests'; tests.mkdir()
        (tests / 'run-parallel.sh').write_text('#!/bin/sh\necho full-suite-executed\nexit 9\n')
        result, plan = self.select(execute=True)
        self.assertEqual(plan['mode'], 'full')
        self.assertIn('full-suite-executed', result.stdout)
        self.assertEqual(result.returncode, 9)

    def test_record_cancellation_cleans_check_descendants(self):
        tests = self.root / 'tests'; tests.mkdir()
        (tests / 'kernel-gate.py').write_text(
            'import os,subprocess,sys,time\n'
            'from pathlib import Path\n'
            'Path(".git/check-pid").write_text(str(os.getpid()))\n'
            'subprocess.Popen([sys.executable, "-c", '
            '"import os,signal,time; from pathlib import Path; "'
            '+ "signal.signal(signal.SIGTERM,signal.SIG_IGN); "'
            '+ "Path(\'.git/child-pid\').write_text(str(os.getpid())); time.sleep(30)"])\n'
            'time.sleep(30)\n')
        for name in ('xref-gate.py', 'test_doc_governance.py'):
            (tests / name).write_text('raise RuntimeError("must not run after cancellation")\n')
        self.commit('tests'); self.base = self.git('rev-parse', 'HEAD').strip()
        self.change_record()
        head = self.git('rev-parse', 'HEAD').strip()
        event = self.root / '.git/event.json'
        event.write_text(json.dumps({'pull_request': {'base': {'sha': self.base}, 'head': {'sha': head}}}))
        process = subprocess.Popen([sys.executable, '-B', str(SCRIPT), '--root', str(self.root)],
            env=dict(self.env, GITHUB_SHA=head, GITHUB_EVENT_PATH=str(event)),
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            pidfile = self.root / '.git/child-pid'
            deadline = time.monotonic() + 6
            while not pidfile.exists() and time.monotonic() < deadline:
                time.sleep(.02)
            self.assertTrue(pidfile.exists())
            process.send_signal(signal.SIGTERM)
            stdout, stderr = process.communicate(timeout=6)
            self.assertNotEqual(process.returncode, 0, stdout + stderr)
            self.assertNotIn('must not run', stderr)
            child = int(pidfile.read_text())
            deadline = time.monotonic() + 2
            while time.monotonic() < deadline:
                state = subprocess.run(['ps', '-o', 'stat=', '-p', str(child)], capture_output=True, text=True).stdout.strip()
                if not state or state.startswith('Z'):
                    break
                time.sleep(.02)
            self.assertTrue(not state or state.startswith('Z'), 'cancelled record check left a descendant')
        finally:
            if process.poll() is None:
                process.kill(); process.wait()
            check_pid = self.root / '.git/check-pid'
            if check_pid.exists():
                pid = int(check_pid.read_text())
                try: os.killpg(pid, signal.SIGKILL)
                except ProcessLookupError:
                    try: os.kill(pid, signal.SIGKILL)
                    except ProcessLookupError: pass
            child_pid = self.root / '.git/child-pid'
            if child_pid.exists():
                try: os.kill(int(child_pid.read_text()), signal.SIGKILL)
                except ProcessLookupError: pass


if __name__ == '__main__':
    unittest.main()
