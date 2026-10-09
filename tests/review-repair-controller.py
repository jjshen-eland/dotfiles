"""Behavioral contracts for bounded review and repair; no prose matching."""
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(sys.argv.pop(1)).resolve()
SCRIPTS = ROOT / 'shared/skills/deep-review/scripts'


class Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='review-controller-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.env = dict(os.environ, DOTFILES_PRECOMMIT_OFF='1',
                        DEEP_REVIEW_STATE_DIR=str(self.root / 'evidence'), TMPDIR=str(self.root))
        for args in [('init', '-q', '-b', 'feature/test'), ('config', 'user.name', 'Fixture'),
                     ('config', 'user.email', 'fixture@example.invalid')]:
            self.git(*args)
        for name in ('a.py', 'b.py'):
            (self.repo / name).write_text('value = 1\n')
        self.git('add', 'a.py', 'b.py')
        self.git('commit', '-qm', 'test: seed')
        self.head = self.git('rev-parse', 'HEAD').strip()

    def run_cmd(self, args, ok=True):
        r = subprocess.run(args, cwd=self.repo, env=self.env, text=True, capture_output=True)
        if ok:
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        return r

    def git(self, *args):
        return self.run_cmd(['git', *args]).stdout

    def capture(self, *args):
        r = self.run_cmd(['bash', str(SCRIPTS / 'review-scope.sh'), 'capture', '--repo',
                          str(self.repo), '--mode', 'working-tree', *args])
        return next(x[10:] for x in r.stdout.splitlines() if x.startswith('manifest: '))

    def ctl(self, *args, ok=True):
        r = self.run_cmd([sys.executable, str(SCRIPTS / 'review-control.py'), *map(str, args)], ok)
        return json.loads(r.stdout) if ok else r

    def data(self, name, value):
        path = self.root / name
        path.write_text(json.dumps(value))
        return path

    def open(self, *args):
        return self.ctl('open', '--manifest', self.capture(), *args)['state']

    def assignments(self):
        return self.data('assignments.json', [{'id': 'source', 'repos': [str(self.repo)],
                                             'concern': 'changed behavior and dependencies'}])

    def review(self, state, findings=None, reason='initial', reviewer='native-source'):
        a = self.ctl('admit', '--state', state, '--assignments', self.assignments(), '--reason', reason)
        self.ctl('dispatch', '--state', state, '--ticket', a['ticket'])
        report = self.root / ('report-' + reviewer + '.txt')
        report.write_text(json.dumps(findings or []))
        results = self.data('results.json', [{'assignment': 'source', 'reviewer': reviewer,
                            'result': 'complete', 'report': str(report), 'findings': findings or []}])
        return self.ctl('finish', '--state', state, '--ticket', a['ticket'], '--input', results)

    def finding(self):
        return {'id': 'F1', 'severity': 'medium', 'location': 'a.py:1',
                'trigger': 'value is zero', 'impact': 'division fails', 'evidence': 'a.py constant'}

    def assess(self, state):
        findings = self.ctl('status', '--state', state)['findings']
        data = [{'id': f['id'], 'status': 'true-positive', 'evidence': 'source and reproducer',
                 'relation': 'independent'} for f in findings if f['disposition'] is None]
        return self.ctl('assess', '--state', state, '--input', self.data('dispositions.json', data))

    def repair(self, state, value=2):
        self.ctl('repair-start', '--state', state)
        (self.repo / 'a.py').write_text('value = ' + str(value) + '\n')
        check = self.ctl('check', '--state', state, '--repo', self.repo,
                         '--input', self.data('command.json', [sys.executable, '-B', '-c',
                                             'import a; assert a.value == 2']))
        findings = self.ctl('status', '--state', state)['findings']
        proof = {'checks': [check['check']], 'findings': [
            {'id': f['id'], 'outcome': 'addressed', 'trigger': 'reproducer passes',
             'same_class': 'a.py and b.py inspected', 'invariant': 'nonzero value',
             'dependents': 'division callers inspected'} for f in findings if f['open']]}
        return self.ctl('repair-finish', '--state', state, '--input', self.data('proof.json', proof))

    def legacy_signal(self):
        self.run_cmd(['git', 'init', '--bare', '-q', str(self.root / 'origin.git')])
        self.git('remote', 'add', 'origin', str(self.root / 'origin.git'))
        self.git('update-ref', 'refs/remotes/origin/main', self.head)
        self.git('symbolic-ref', 'refs/remotes/origin/HEAD', 'refs/remotes/origin/main')
        gh_stub = self.root / 'gh-stub'
        gh_stub.write_text('#!/bin/sh\nexit 1\n')
        gh_stub.chmod(0o755)
        self.env['SHIP_STATE_GH'] = str(gh_stub)
        self.run_cmd(['bash', str(SCRIPTS / 'review-terminal.sh'), 'record', '--repo',
                      str(self.repo), '--reason', 'blocked-review', '--head', self.head])
        anchor = self.repo / '.git/deep-review/anchor'
        anchor.write_text('cycle=5\nbase=' + self.head + '\n' + anchor.read_text())
        return anchor

    def ship(self):
        return self.run_cmd(['bash', str(ROOT / 'shared/skills/project/scripts/ship-state.sh'),
                             str(self.repo)]).stdout

    def disposition(self, state, **overrides):
        info = self.ctl('terminal-status', '--repo', self.repo)
        request = {'action': 'close-legacy-review-terminal', 'repo': info['repo'],
                   'signal': info['signal'], 'head': self.git('rev-parse', 'HEAD').strip(),
                   'scope': json.loads(Path(state).read_text()).get('receipt', {}).get('scope', ''),
                   'endpoint': 'merge',
                   'user_instruction': 'Close this original legacy signal despite unknown coverage; '
                                       'no shipping authorization is granted.'}
        request.update(overrides)
        return self.data('disposition.json', request)



class Controller(Fixture):
    def test_fresh_validates_each_scope_once_and_rejects_drift(self):
        spec = importlib.util.spec_from_file_location('fresh_controller', SCRIPTS / 'review-control.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        scope = module.load_scope(self.capture())
        state = {'scopes': [scope]}
        with mock.patch.object(module, 'scope_check', wraps=module.scope_check) as verify:
            module.fresh(state)
            self.assertEqual(verify.call_count, 1, 'same scope repeatedly crosses the external verifier')
        (self.repo / 'a.py').write_text('value = 0\n')
        with self.assertRaises(module.Blocked):
            module.fresh(state)
        scope = module.load_scope(self.capture())
        with self.assertRaisesRegex(module.Blocked, 'manifest identity changed'):
            module.fresh({'scopes': [{**scope, 'fingerprint': 'forged'}]})

    def test_legacy_ancestry_does_not_prove_coverage(self):
        self.run_cmd(['bash', str(SCRIPTS / 'review-terminal.sh'), 'record', '--repo',
                      str(self.repo), '--reason', 'blocking-findings', '--head', self.head])
        (self.repo / 'a.py').write_text('value = 0\n')
        self.capture('--path', 'b.py')
        r = self.run_cmd(['bash', str(SCRIPTS / 'review-terminal.sh'), 'clear', '--repo',
                          str(self.repo), '--base', self.head, '--head', self.head], ok=False)
        self.assertNotEqual(r.returncode, 0, 'ancestry alone cleared an unreviewed dirty finding')
        self.assertIn('terminal_reason=', (self.repo / '.git/deep-review/anchor').read_text())

    def test_disposed_legacy_ancestor_stops_reblocking_later_batches(self):
        anchor = self.legacy_signal()
        original = anchor.read_text()
        self.git('branch', 'main')
        (self.repo / 'a.py').write_text('value = 2\n')
        self.git('add', 'a.py')
        self.git('commit', '-qm', 'test: first batch explicitly shipped')
        self.git('switch', '-q', 'main')
        self.git('merge', '--ff-only', 'feature/test')
        self.git('switch', '-qc', 'feature/next')
        (self.repo / 'b.py').write_text('value = 2\n')
        self.git('add', 'b.py')
        self.git('commit', '-qm', 'test: independently reviewed next batch')
        state = self.open()
        self.review(state)
        before = Path(state).read_bytes()
        self.assertIn('review-terminal: blocked-review', self.ship())
        self.assertNotEqual(self.ctl('terminal-clear', '--state', state, '--repo', self.repo,
                                     ok=False).returncode, 0)
        self.assertEqual(anchor.read_text(), original, 'read-only PASS mutated legacy metadata')
        request = self.disposition(state)
        result = self.ctl('terminal-dispose', '--state', state, '--repo', self.repo, '--input', request)
        self.assertEqual(result['terminal'], 'DISPOSED')
        self.assertFalse(result['shipping_authorized'])
        receipt = json.loads(Path(result['receipt']).read_text())
        self.assertEqual(receipt['original'], original)
        self.assertEqual(receipt['endpoint'], 'merge')
        self.assertIn('cycle=5\nbase=' + self.head, anchor.read_text())
        self.assertIn('terminal_reason=blocked-review', anchor.read_text())
        after = json.loads(Path(state).read_text())
        prior = json.loads(before)
        for key in ('attempts', 'repairs', 'reviewer_count', 'findings', 'history', 'receipt', 'verdict'):
            self.assertEqual(after[key], prior[key], 'disposition changed review authority or budget')
        self.assertNotIn('\nreview-terminal:', '\n' + self.ship())
        self.git('switch', '-qc', 'feature/unrelated')
        (self.repo / 'a.py').write_text('value = 3\n')
        self.git('add', 'a.py')
        self.git('commit', '-qm', 'test: later unrelated change')
        self.assertNotIn('\nreview-terminal:', '\n' + self.ship())
        self.assertFalse(self.ctl('terminal-status', '--repo', self.repo)['shipping_authorized'])
        self.assertNotEqual(self.ctl('terminal-dispose', '--state', state, '--repo', self.repo,
                                     '--input', request, ok=False).returncode, 0, 'old approval was reusable')
        self.run_cmd(['bash', str(SCRIPTS / 'review-terminal.sh'), 'record', '--repo', self.repo,
                      '--reason', 'blocking-findings', '--head', 'HEAD'])
        self.assertIn('review-terminal: blocking-findings', self.ship())
        self.assertTrue(Path(result['receipt']).exists(), 'new signal deleted original history')

    def test_legacy_disposition_requires_exact_current_instruction(self):
        anchor = self.legacy_signal()
        state = self.open()
        self.review(state)
        original = anchor.read_bytes()
        for overrides in ({'action': 'merge'}, {'signal': '0' * 64}, {'repo': str(self.root)},
                          {'head': '0' * 40}, {'scope': '0' * 64}, {'endpoint': 'production'},
                          {'user_instruction': ''}):
            request = self.disposition(state, **overrides)
            self.assertNotEqual(self.ctl('terminal-dispose', '--state', state, '--repo', self.repo,
                                         '--input', request, ok=False).returncode, 0)
            self.assertEqual(anchor.read_bytes(), original)
            self.assertIn('review-terminal: blocked-review', self.ship())

    def test_legacy_disposition_rejects_incomplete_partial_and_stale_pass(self):
        anchor = self.legacy_signal()
        state = self.open()
        request = self.disposition(state)
        self.assertNotEqual(self.ctl('terminal-dispose', '--state', state, '--repo', self.repo,
                                     '--input', request, ok=False).returncode, 0)
        self.review(state)
        request = self.disposition(state)
        original = anchor.read_bytes()
        (self.repo / 'a.py').write_text('value = 0\n')
        self.assertNotEqual(self.ctl('terminal-dispose', '--state', state, '--repo', self.repo,
                                     '--input', request, ok=False).returncode, 0)
        self.assertEqual(anchor.read_bytes(), original)
        (self.repo / 'a.py').write_text('value = 1\n')
        # A different evidence root is an isolated control, never a live-budget reset.
        self.env['DEEP_REVIEW_STATE_DIR'] = str(self.root / 'partial-evidence')
        partial = self.ctl('open', '--manifest', self.capture('--path', 'b.py'))['state']
        self.review(partial)
        self.assertNotEqual(self.ctl('terminal-dispose', '--state', partial, '--repo', self.repo,
                                     '--input', self.disposition(partial), ok=False).returncode, 0)
        self.assertEqual(anchor.read_bytes(), original)

        self.env['DEEP_REVIEW_STATE_DIR'] = str(self.root / 'range-evidence')
        captured = self.run_cmd(['bash', str(SCRIPTS / 'review-scope.sh'), 'capture', '--repo',
                                 self.repo, '--mode', 'range', '--range', self.head + '..' + self.head])
        manifest = next(x[10:] for x in captured.stdout.splitlines() if x.startswith('manifest: '))
        historical = self.ctl('open', '--manifest', manifest)['state']
        self.review(historical)
        self.assertNotEqual(self.ctl('terminal-dispose', '--state', historical, '--repo', self.repo,
                                     '--input', self.disposition(historical), ok=False).returncode, 0)
        self.assertEqual(anchor.read_bytes(), original)

    def test_legacy_disposition_cannot_clear_scoped_or_changed_signal(self):
        anchor = self.legacy_signal()
        state = self.open()
        self.review(state)
        request = self.disposition(state)
        anchor.write_text(anchor.read_text().replace('terminal_at=', 'terminal_at=9'))
        original = anchor.read_bytes()
        self.assertNotEqual(self.ctl('terminal-dispose', '--state', state, '--repo', self.repo,
                                     '--input', request, ok=False).returncode, 0)
        self.assertEqual(anchor.read_bytes(), original)
        anchor.write_text(anchor.read_text() + 'terminal_scope={"repo":' + json.dumps(str(self.repo)) + '}\n')
        original = anchor.read_bytes()
        request = self.disposition(state)
        self.assertNotEqual(self.ctl('terminal-dispose', '--state', state, '--repo', self.repo,
                                     '--input', request, ok=False).returncode, 0)
        self.assertEqual(anchor.read_bytes(), original)

    def test_bad_disposition_receipt_fails_closed_and_status_is_readonly(self):
        anchor = self.legacy_signal()
        before = {str(p): p.read_bytes() for p in self.repo.rglob('*') if p.is_file()}
        self.assertEqual(self.ctl('terminal-status', '--repo', self.repo)['terminal'], 'ACTIVE')
        self.assertEqual(before, {str(p): p.read_bytes() for p in self.repo.rglob('*') if p.is_file()})
        anchor.write_text(anchor.read_text() + 'terminal_disposition=missing.json\n')
        self.assertIn('review-terminal: blocked-review', self.ship())
        self.assertNotEqual(self.ctl('terminal-status', '--repo', self.repo, ok=False).returncode, 0)
        anchor.write_bytes(before[str(anchor)])
        state = self.open()
        self.review(state)
        closed = self.ctl('terminal-dispose', '--state', state, '--repo', self.repo,
                           '--input', self.disposition(state))
        Path(closed['receipt']).unlink()  # Deliberately corrupt only this test's isolated archive.
        self.assertIn('review-terminal: blocked-review', self.ship())
        self.assertNotEqual(self.ctl('terminal-status', '--repo', self.repo, ok=False).returncode, 0)

    def test_recapture_and_cross_runtime_keep_consumed_ticket(self):
        state = self.open('--route', 'ordinary')
        admit = self.ctl('admit', '--state', state, '--assignments', self.assignments())
        self.ctl('dispatch', '--state', state, '--ticket', admit['ticket'])
        self.assertNotEqual(self.ctl('dispatch', '--state', state, '--ticket', admit['ticket'], ok=False).returncode, 0)
        again = self.open('--route', 'ordinary')
        self.assertEqual(again, state)
        self.assertNotEqual(self.ctl('admit', '--state', state, '--assignments', self.assignments(), ok=False).returncode, 0)
        self.assertEqual(self.ctl('status', '--state', state)['attempts'], 1)

    def test_scope_shrink_and_drift_do_not_reopen(self):
        state = self.open()
        self.assertNotEqual(self.ctl('open', '--manifest', self.capture('--path', 'a.py'), ok=False).returncode, 0)
        (self.repo / 'a.py').write_text('value = 0\n')
        self.assertNotEqual(self.ctl('admit', '--state', state, '--assignments', self.assignments(), ok=False).returncode, 0)
        self.assertEqual(self.ctl('status', '--state', state)['attempts'], 0)

    def test_focused_preflight_and_terminal_receipt(self):
        state = self.open('--route', 'full', '--autofix', '--followup', 'focused', '--repair-limit', '2')
        self.review(state, [self.finding()])
        self.assess(state)
        self.repair(state)
        self.ctl('terminal-record', '--state', state, '--repo', self.repo, '--reason', 'blocked-review')
        a = self.ctl('admit', '--state', state, '--assignments', self.assignments(), '--reason', 'repair')
        packet = Path(a['packets'][0]).read_text()
        self.assertIn('division fails', packet)
        self.assertIn('value = 2', packet)
        delta = json.loads(packet)['repair']['actual_delta'][0]
        self.assertEqual(delta['after'], hashlib.sha256((self.repo / 'a.py').read_bytes()).hexdigest())
        self.assertEqual(delta['before'], hashlib.sha256(b'value = 1\n').hexdigest())
        for term in ('attempts', 'repair_limit', 'last chance', 'verdict', 'remaining'):
            self.assertNotIn(term, packet)
        self.ctl('dispatch', '--state', state, '--ticket', a['ticket'])
        report = self.root / 'clean.txt'
        report.write_text('NO BLOCKING FINDINGS')
        results = self.data('clean.json', [{'assignment': 'source', 'reviewer': 'native-fresh',
                                           'result': 'complete', 'report': str(report), 'findings': []}])
        self.ctl('finish', '--state', state, '--ticket', a['ticket'], '--input', results)
        self.assertEqual(self.ctl('status', '--state', state)['verdict'], 'PASS')
        (self.repo / 'a.py').write_text('value = 0\n')
        self.assertNotEqual(self.ctl('terminal-clear', '--state', state, '--repo', self.repo, ok=False).returncode, 0)
        (self.repo / 'a.py').write_text('value = 2\n')
        self.ctl('terminal-clear', '--state', state, '--repo', self.repo)
        self.assertFalse((self.repo / '.git/deep-review/anchor').exists())

    def test_failed_edited_repair_can_persist_terminal(self):
        state = self.open('--autofix', '--repair-limit', '1')
        self.review(state, [self.finding()])
        self.assess(state)
        self.ctl('repair-start', '--state', state)
        (self.repo / 'a.py').write_text('value = 0\n')
        self.ctl('check', '--state', state, '--repo', self.repo,
                 '--input', self.data('bad.json', [sys.executable, '-c', 'raise SystemExit(1)']), ok=False)
        self.ctl('terminal-record', '--state', state, '--repo', self.repo, '--reason', 'blocked-review')
        self.assertIn('terminal_scope=', (self.repo / '.git/deep-review/anchor').read_text())
        auth = self.root / 'user.txt'
        auth.write_text('Start another bounded repair batch for the remaining finding.')
        next_batch = self.ctl('new-batch', '--state', state, '--authorization', auth)
        self.assertEqual(next_batch['repairs'], 0)
        self.assertTrue(next_batch['findings'][0]['open'])
        self.assertTrue(json.loads(Path(state).read_text())['history'])

    def test_explicit_new_scope_retains_prior_finding_for_revalidation(self):
        state = self.open()
        self.review(state, [self.finding()])
        self.assess(state)
        (self.repo / 'a.py').write_text('value = 2\n')
        auth = self.root / 'user.txt'
        auth.write_text('Review the changed subject as a new bounded batch, preserving earlier evidence.')
        self.ctl('new-batch', '--state', state, '--authorization', auth, '--manifest', self.capture())
        self.review(state, reviewer='new-scope-native')
        status = self.ctl('status', '--state', state)
        self.assertEqual(status['verdict'], 'BLOCKED')
        claim = {'id': status['findings'][0]['id'], 'status': 'resolved', 'evidence': 'new source now has nonzero value', 'relation': 'independent'}
        self.ctl('assess', '--state', state, '--input', self.data('new-source-assessment.json', [claim]))
        self.assertEqual(self.ctl('status', '--state', state)['verdict'], 'PASS')

    def test_readonly_all_git_metadata_unchanged(self):
        before = {str(p): p.read_bytes() for p in self.repo.rglob('*') if p.is_file()}
        state = self.open()
        self.review(state)
        self.assertNotEqual(self.ctl('terminal-record', '--state', state, '--repo', self.repo,
                                     '--reason', 'blocked-review', ok=False).returncode, 0)
        self.assertEqual(before, {str(p): p.read_bytes() for p in self.repo.rglob('*') if p.is_file()})

    def test_packet_preserves_dirty_subject_when_endpoints_equal(self):
        (self.repo / 'a.py').write_text('value = 0\n')
        (self.repo / 'extra.py').write_text('value = 0\n')
        state = self.open()
        a = self.ctl('admit', '--state', state, '--assignments', self.assignments())
        scope = json.loads(Path(a['packets'][0]).read_text())['scope'][0]
        self.assertEqual(scope['base'], scope['head'])
        self.assertTrue(scope['working_tree_included'])
        self.assertEqual(set(scope['subject_files']), {'a.py', 'extra.py'})

    def test_repair_cannot_hide_out_of_scope_edit(self):
        state = self.ctl('open', '--manifest', self.capture('--path', 'a.py'), '--autofix')['state']
        self.review(state, [self.finding()])
        self.assess(state)
        self.ctl('repair-start', '--state', state)
        (self.repo / 'a.py').write_text('value = 2\n')
        (self.repo / 'b.py').write_text('value = 0\n')
        finding = self.ctl('status', '--state', state)['findings'][0]
        proof = {'checks': [], 'static_evidence': 'constants inspected', 'findings': [
            {'id': finding['id'], 'outcome': 'addressed', 'trigger': 'a.py nonzero',
             'same_class': 'a.py', 'invariant': 'nonzero', 'dependents': 'no callers'}]}
        r = self.ctl('repair-finish', '--state', state, '--input', self.data('proof.json', proof), ok=False)
        self.assertNotEqual(r.returncode, 0, 'partial scope hid a repair-introduced change')

    def test_independent_owned_repo_can_repair_without_mutating_readonly_peer(self):
        other = self.root / 'other'
        self.run_cmd(['git', 'clone', '--no-local', '-q', str(self.repo), str(other)])
        capture = self.run_cmd(['bash', str(SCRIPTS / 'review-scope.sh'), 'capture', '--repo',
                               str(other), '--mode', 'range', '--range', self.head + '..' + self.head]).stdout
        other_manifest = next(x[10:] for x in capture.splitlines() if x.startswith('manifest: '))
        state = self.ctl('open', '--manifest', self.capture(), '--manifest', other_manifest, '--autofix')['state']
        assignments = self.data('both.json', [{'id': 'source', 'repos': [str(self.repo), str(other)], 'concern': 'both repos'}])
        a = self.ctl('admit', '--state', state, '--assignments', assignments)
        self.ctl('dispatch', '--state', state, '--ticket', a['ticket'])
        report = self.root / 'both.txt'
        report.write_text('Independent local constant defect in repo/a.py. Peer unchanged.')
        finding = {**self.finding(), 'repo': str(self.repo)}
        results = self.data('both-results.json', [{'assignment': 'source', 'reviewer': 'both-native',
                           'result': 'complete', 'report': str(report), 'findings': [finding]}])
        self.ctl('finish', '--state', state, '--ticket', a['ticket'], '--input', results)
        self.assess(state)
        before = {str(p): p.read_bytes() for p in other.rglob('*') if p.is_file()}
        self.ctl('repair-start', '--state', state, '--editable-repo', self.repo)
        self.assertEqual(before, {str(p): p.read_bytes() for p in other.rglob('*') if p.is_file()})
        (other / 'a.py').write_text('external_writer = True\n')
        before = {str(p): p.read_bytes() for p in other.rglob('*') if p.is_file()}
        self.assertNotEqual(self.ctl('terminal-record', '--state', state, '--repo', other,
                                    '--reason', 'blocked-review', ok=False).returncode, 0)
        self.assertEqual(before, {str(p): p.read_bytes() for p in other.rglob('*') if p.is_file()})



class Policy(Fixture):
    """State/slot policy with an already validated scope adapter.

    Real scope freshness, Git metadata, terminal receipts and runtime subprocess
    persistence remain in Controller. Policy still uses production parsing,
    transitions, locks, on-disk journals, Git snapshots and check subprocesses.
    """

    def setUp(self):
        super().setUp()
        spec = importlib.util.spec_from_file_location('policy_controller', SCRIPTS / 'review-control.py')
        self.controller = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.controller)

    def ctl(self, *args, ok=True):
        argv = [str(SCRIPTS / 'review-control.py'), *map(str, args)]
        out, err = io.StringIO(), io.StringIO()
        with mock.patch.dict(os.environ, self.env, clear=True), \
                mock.patch.object(sys, 'argv', argv), \
                mock.patch.object(self.controller, 'ENV', dict(self.env, GIT_OPTIONAL_LOCKS='0', PYTHONDONTWRITEBYTECODE='1')), \
                mock.patch.object(self.controller, 'scope_check'), \
                contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = self.controller.main()
        result = subprocess.CompletedProcess(argv, code, out.getvalue(), err.getvalue())
        if ok:
            self.assertEqual(code, 0, result.stdout + result.stderr)
            return json.loads(result.stdout)
        return result

    def test_partial_result_spends_slot_and_cannot_pass(self):
        state = self.open('--route', 'ordinary')
        a = self.ctl('admit', '--state', state, '--assignments', self.assignments())
        self.ctl('dispatch', '--state', state, '--ticket', a['ticket'])
        r = self.ctl('finish', '--state', state, '--ticket', a['ticket'],
                     '--input', self.data('partial.json', []), ok=False)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(self.ctl('status', '--state', state)['verdict'], 'BLOCKED')
        self.assertNotEqual(self.ctl('admit', '--state', state, '--assignments', self.assignments(), ok=False).returncode, 0)

    def test_failed_check_blocks_review_and_repair_has_limit(self):
        state = self.open('--route', 'full', '--autofix', '--repair-limit', '1')
        self.review(state, [self.finding()])
        self.assess(state)
        self.ctl('repair-start', '--state', state)
        bad = self.ctl('check', '--state', state, '--repo', self.repo,
                      '--input', self.data('bad.json', [sys.executable, '-c', 'raise SystemExit(1)']), ok=False)
        self.assertNotEqual(bad.returncode, 0)
        self.assertNotEqual(self.ctl('admit', '--state', state, '--assignments', self.assignments(), '--reason', 'repair', ok=False).returncode, 0)
        self.assertNotEqual(self.ctl('repair-start', '--state', state, ok=False).returncode, 0)
        self.assertEqual(self.ctl('status', '--state', state)['repairs'], 1)
        self.assertNotEqual(self.ctl('check', '--state', state, '--repo', self.repo,
                                    '--input', self.data('pass.json', [sys.executable, '-c', 'pass']), ok=False).returncode, 0)

    def test_recurrence_requires_diagnosis_and_never_lowers_raw_severity(self):
        state = self.open('--route', 'full', '--autofix', '--repair-limit', '1')
        self.review(state, [self.finding()])
        self.assess(state)
        self.repair(state)
        self.review(state, [self.finding()], reason='repair', reviewer='fresh')
        findings = self.ctl('status', '--state', state)['findings']
        claim = {'id': findings[-1]['id'], 'status': 'true-positive', 'evidence': 'b.py still zero',
                 'relation': 'unresolved-original', 'parent': findings[0]['id']}
        self.assertNotEqual(self.ctl('assess', '--state', state, '--input', self.data('recurrence.json', [claim]), ok=False).returncode, 0)
        claim['diagnosis'] = 'The previous local patch omitted b.py and its division consumer; fix the shared invariant.'
        self.ctl('assess', '--state', state, '--input', self.data('recurrence.json', [claim]))
        self.assertNotEqual(self.ctl('repair-start', '--state', state, ok=False).returncode, 0)
        status = self.ctl('status', '--state', state)
        self.assertEqual(status['verdict'], 'FAIL')
        self.assertEqual([f['raw']['severity'] for f in status['findings']], ['medium', 'medium'])

    def test_focused_renderer_does_not_copy_arbitrary_report_metadata(self):
        state = self.open('--route', 'full', '--autofix', '--followup', 'focused')
        self.review(state, [{**self.finding(), 'remaining_budget': 'last chance'}])
        self.assess(state)
        self.repair(state)
        a = self.ctl('admit', '--state', state, '--assignments', self.assignments(), '--reason', 'repair')
        packet = Path(a['packets'][0]).read_text()
        self.assertNotIn('remaining_budget', packet)
        self.assertNotIn('last chance', packet)
        self.assertEqual(self.ctl('status', '--state', state)['findings'][0]['raw']['remaining_budget'], 'last chance')

    def test_reused_identity_invalidates_result(self):
        state = self.open('--second-opinion')
        self.review(state)
        self.assertEqual(self.ctl('status', '--state', state)['verdict'], 'BLOCKED')
        a = self.ctl('admit', '--state', state, '--assignments', self.assignments(), '--reason', 'second')
        self.ctl('dispatch', '--state', state, '--ticket', a['ticket'])
        r = self.ctl('finish', '--state', state, '--ticket', a['ticket'],
                     '--input', self.root / 'results.json', ok=False)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(self.ctl('status', '--state', state)['attempts'], 2)

    def test_primary_cannot_spend_the_reserved_second_opinion(self):
        state = self.open('--route', 'full', '--autofix', '--repair-limit', '1', '--second-opinion')
        a = self.ctl('admit', '--state', state, '--assignments', self.assignments())
        self.ctl('dispatch', '--state', state, '--ticket', a['ticket'])
        self.ctl('finish', '--state', state, '--ticket', a['ticket'], '--input', self.data('partial.json', []), ok=False)
        self.review(state, [self.finding()])
        self.assess(state)
        self.assertNotEqual(self.ctl('repair-start', '--state', state, ok=False).returncode, 0,
                            'repair would require stealing the second-opinion slot')
        self.review(state, reason='second', reviewer='second-native')
        self.assertEqual(self.ctl('status', '--state', state)['attempts'], 3)

    def test_second_opinion_of_old_content_does_not_cover_repair(self):
        state = self.open('--route', 'full', '--autofix', '--repair-limit', '1', '--second-opinion')
        self.review(state, [self.finding()])
        self.assess(state)
        self.review(state, reason='second', reviewer='old-second')
        self.repair(state)
        self.review(state, reason='repair', reviewer='repaired-primary')
        self.assertEqual(self.ctl('status', '--state', state)['verdict'], 'BLOCKED')

    def test_ordinary_author_verification_and_fresh_ids(self):
        state = self.open('--autofix')
        self.review(state, [self.finding()])
        self.assess(state)
        self.repair(state)
        self.assertEqual(self.ctl('status', '--state', state)['verdict'], 'PASS')
        self.assertNotEqual(self.ctl('admit', '--state', state, '--assignments', self.assignments(), '--reason', 'repair', ok=False).returncode, 0)
        self.assertEqual(self.ctl('status', '--state', state)['attempts'], 1)




if __name__ == '__main__':
    unittest.main()
