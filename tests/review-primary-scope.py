"""Primary responsibility and aggregate integrity through the real controller CLI."""
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(sys.argv.pop(1)).resolve()
SCRIPTS = ROOT / 'shared/skills/deep-review/scripts'


class PrimaryScope(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='review-primary-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.scripts = SCRIPTS
        self.env = dict(os.environ, DOTFILES_PRECOMMIT_OFF='1',
                        DEEP_REVIEW_STATE_DIR=str(self.root / 'evidence'), TMPDIR=str(self.root))
        for key in ('CODEX_THREAD_ID', 'CODEX_SESSION_ID', 'CLAUDE_SESSION_ID', 'TURBO_RUNTIME'):
            self.env.pop(key, None)
        self.repo = self.make_repo('repo', 39)

    def run_cmd(self, argv, ok=True, cwd=None):
        result = subprocess.run(list(map(str, argv)), cwd=cwd or self.repo,
                                env=self.env, text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def make_repo(self, name, count):
        repo = self.root / name
        repo.mkdir()
        for args in (('init', '-q', '-b', 'feature/test'), ('config', 'user.name', 'Fixture'),
                     ('config', 'user.email', 'fixture@example.invalid')):
            subprocess.run(['git', '-C', str(repo), *args], env=self.env, check=True,
                           capture_output=True)
        names = [f'file-{i:02}.py' for i in range(count)]
        for name in names:
            (repo / name).write_text('value = 1\n')
        subprocess.run(['git', '-C', str(repo), 'add', *names], env=self.env, check=True)
        subprocess.run(['git', '-C', str(repo), '-c', 'core.hooksPath=/dev/null',
                        'commit', '-qm', 'test: seed'], env=self.env, check=True)
        for name in names:
            (repo / name).write_text('value = 2\n')
        return repo

    def data(self, name, value):
        path = self.root / name
        path.write_text(json.dumps(value))
        return path

    def ctl(self, *args, ok=True):
        r = self.run_cmd([sys.executable, '-B', self.scripts / 'review-control.py', *args], ok=ok)
        return json.loads(r.stdout) if ok else r

    def open(self, repos=None, route='full', second=False):
        args = ['open', '--route', route]
        for repo in repos or [self.repo]:
            r = self.run_cmd(['bash', self.scripts / 'review-scope.sh', 'capture', '--repo', repo,
                              '--mode', 'working-tree'])
            manifest = next(x[10:] for x in r.stdout.splitlines() if x.startswith('manifest: '))
            args += ['--manifest', manifest]
        if second:
            args += ['--second-opinion']
        return self.ctl(*args)['state']

    def assignment(self, name, primary):
        return {'id': name, 'repos': list(primary), 'concern': 'changed behavior and contracts',
                'primary': primary}

    def partition(self, counts=(12, 14, 13)):
        names = [f'file-{i:02}.py' for i in range(39)]
        out, offset = [], 0
        for i, count in enumerate(counts):
            out.append(self.assignment('part-' + str(i), {str(self.repo): names[offset:offset + count]}))
            offset += count
        return out

    def admit(self, state, assignments, ok=True, reason='initial'):
        return self.ctl('admit', '--state', state, '--assignments',
                        self.data('assignments.json', assignments), '--reason', reason, ok=ok)

    def finish(self, state, admitted, results=None, ok=True):
        self.ctl('dispatch', '--state', state, '--ticket', admitted['ticket'])
        if results is None:
            results = []
            pending = json.loads(Path(state).read_text())['pending']
            for index, assignment in enumerate(pending['assignments']):
                report = self.root / f'report-{index}.txt'
                report.write_text('Independent synthetic controller fixture; assigned responsibility complete.\n')
                results.append({'assignment': assignment['id'], 'reviewer': 'fixture-' + str(index),
                                'result': 'complete', 'report': str(report), 'findings': []})
        return self.ctl('finish', '--state', state, '--ticket', admitted['ticket'],
                        '--input', self.data('results.json', results), ok=ok)

    def test_shared_repo_free_text_partition_is_rejected_before_spending(self):
        state = self.open()
        assignments = self.partition()
        for assignment in assignments:
            assignment['concern'] += ': ' + ', '.join(assignment.pop('primary')[str(self.repo)])
        result = self.admit(state, assignments, ok=False)
        self.assertNotEqual(result.returncode, 0, 'unbounded free-text partition was admitted')
        self.assertEqual(self.ctl('status', '--state', state)['attempts'], 0)

    def test_39_file_three_way_projection_and_global_receipt(self):
        self.assert_projection((12, 14, 13))

    def test_two_way_projection_and_global_receipt(self):
        self.assert_projection((19, 20))

    def assert_projection(self, counts):
        state = self.open()
        assignments = self.partition(counts)
        admitted = self.admit(state, assignments)
        packets = [json.loads(Path(p).read_text()) for p in admitted['packets']]
        aggregate = packets[0]['scope']
        self.assertEqual(len(aggregate[0]['subject_files']), 39)
        for packet, assignment, count in zip(packets, assignments, counts):
            self.assertEqual(packet['scope'], aggregate, 'aggregate immutable subject was narrowed')
            self.assertEqual(packet['primary_scope'], [
                {'repo': str(self.repo), 'subject_files': assignment['primary'][str(self.repo)]}])
            self.assertEqual(len(packet['primary_scope'][0]['subject_files']), count)
        finished = self.finish(state, admitted)
        self.assertEqual(finished['verdict'], 'PASS')
        journal = json.loads(Path(state).read_text())
        self.assertEqual(journal['receipt']['scope'], journal['sets'][0]['scope'])
        self.assertEqual(journal['attempts'], 1)
        self.assertEqual(journal['valid_sets'], 1)

    def test_cross_repo_interface_partition_keeps_both_endpoints(self):
        other = self.make_repo('consumer', 2)
        state = self.open([self.repo, other])
        assignments = [self.assignment('source', {str(self.repo): [f'file-{i:02}.py' for i in range(1, 39)]}),
                       self.assignment('consumer', {str(other): ['file-01.py']}),
                       self.assignment('interface', {str(self.repo): ['file-00.py'], str(other): ['file-00.py']})]
        admitted = self.admit(state, assignments)
        for path in admitted['packets']:
            packet = json.loads(Path(path).read_text())
            self.assertEqual({s['repo'] for s in packet['scope']}, {str(self.repo), str(other)})
        self.assertEqual(self.finish(state, admitted)['verdict'], 'PASS')

    def test_invalid_primary_boundaries_do_not_spend_attempts(self):
        state = self.open()
        variants = []
        omitted = self.partition(); omitted[0]['primary'][str(self.repo)].pop(); variants.append(omitted)
        overlap = self.partition(); overlap[0]['primary'][str(self.repo)].append('file-12.py'); variants.append(overlap)
        outside = self.partition(); outside[0]['primary'][str(self.repo)][0] = '../outside.py'; variants.append(outside)
        duplicate = self.partition(); duplicate[0]['primary'][str(self.repo)].append('file-00.py'); variants.append(duplicate)
        wrong_repo = self.partition(); wrong_repo[0]['primary'][str(self.root)] = ['file-00.py']; variants.append(wrong_repo)
        wrong_type = self.partition(); wrong_type[0]['primary'][str(self.repo)] = 'file-00.py'; variants.append(wrong_type)
        for assignments in variants:
            with self.subTest(assignments=assignments):
                self.assertNotEqual(self.admit(state, assignments, ok=False).returncode, 0)
                self.assertEqual(self.ctl('status', '--state', state)['attempts'], 0)

    def test_ordinary_cannot_narrow_its_whole_subject(self):
        state = self.open(route='ordinary')
        self.assertNotEqual(self.admit(state, self.partition()[:1], ok=False).returncode, 0)
        assignment = self.assignment('whole', {str(self.repo): [f'file-{i:02}.py' for i in range(39)]})
        self.assertEqual(self.finish(state, self.admit(state, [assignment]))['verdict'], 'PASS')

    def test_packet_primary_drift_blocks_dispatch_and_keeps_attempt(self):
        state = self.open()
        admitted = self.admit(state, self.partition())
        path = Path(admitted['packets'][0]); packet = json.loads(path.read_text())
        packet['primary_scope'][0]['subject_files'].pop(); path.write_text(json.dumps(packet))
        result = self.ctl('dispatch', '--state', state, '--ticket', admitted['ticket'], ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.ctl('status', '--state', state)['attempts'], 1)

    def test_subject_drift_blocks_aggregate(self):
        state = self.open()
        admitted = self.admit(state, self.partition())
        self.ctl('dispatch', '--state', state, '--ticket', admitted['ticket'])
        (self.repo / 'file-38.py').write_text('value = 3\n')
        result = self.ctl('finish', '--state', state, '--ticket', admitted['ticket'],
                          '--input', self.data('results.json', []), ok=False)
        self.assertNotEqual(result.returncode, 0)
        journal = json.loads(Path(state).read_text())
        self.assertNotIn('receipt', journal)
        self.assertEqual(journal['events'][-1]['kind'], 'invalid-result')
        self.assertEqual(journal['attempts'], 1)

    def test_brief_input_drift_blocks_dispatch(self):
        source = self.root / 'source'
        shutil.copytree(SCRIPTS.parent, source)
        self.scripts = source / 'scripts'
        state = self.open()
        admitted = self.admit(state, self.partition())
        brief = source / 'references/portable-reviewer-brief.md'
        brief.write_text(brief.read_text() + '\nChanged review criteria.\n')
        result = self.ctl('dispatch', '--state', state, '--ticket', admitted['ticket'], ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.ctl('status', '--state', state)['attempts'], 1)

    def test_native_incomplete_report_is_retained_with_failed_set(self):
        # Fake transport tests artifact retention only; it is never native acceptance.
        bin_dir = self.root / 'fake-bin'; bin_dir.mkdir()
        executable = bin_dir / 'codex'
        executable.write_text('#!' + sys.executable + '\n' + '''import json, sys, uuid
sys.stdin.read()
print(json.dumps({'type':'thread.started','thread_id':str(uuid.uuid4())}))
review={'result':'incomplete','report':'Required execution fact could not be established.', 'findings':[]}
print(json.dumps({'type':'item.completed','item':{'type':'agent_message','text':json.dumps(review)}}))
''')
        executable.chmod(0o755)
        self.env['PATH'] = str(bin_dir) + os.pathsep + self.env['PATH']
        state = self.open()
        admitted = self.admit(state, self.partition())
        self.ctl('dispatch', '--state', state, '--ticket', admitted['ticket'])
        result = self.ctl('native-review', '--state', state, '--ticket', admitted['ticket'], ok=False)
        self.assertNotEqual(result.returncode, 0)
        reports = list(Path(state).parent.glob('native-*/*-report.json'))
        self.assertEqual(len(reports), 3, 'original incomplete reports were discarded')
        for report in reports:
            self.assertEqual(json.loads(report.read_text())['result'], 'incomplete')
        journal = json.loads(Path(state).read_text())
        self.assertEqual(journal['attempts'], 1)
        self.assertEqual(journal['verdict'], 'BLOCKED')
        self.assertTrue(journal['failed_sets'][-1]['native_required'])
        self.assertEqual(journal['failed_sets'][-1]['ticket'], admitted['ticket'])

    def test_incomplete_partial_duplicate_and_reused_results_block(self):
        for case in ('incomplete', 'partial', 'duplicate', 'reused'):
            with self.subTest(case=case):
                self.env['DEEP_REVIEW_STATE_DIR'] = str(self.root / ('evidence-' + case))
                state = self.open(second=case == 'reused')
                admitted = self.admit(state, self.partition())
                results = []
                for i in range(3):
                    report = self.root / f'{case}-report-{i}.txt'; report.write_text('Original fixture report.\n')
                    results.append({'assignment': 'part-' + str(i), 'reviewer': case + '-' + str(i),
                                    'result': 'complete', 'report': str(report), 'findings': []})
                if case == 'incomplete': results[1]['result'] = 'incomplete'
                if case == 'partial': results.pop()
                if case == 'duplicate': results[1]['reviewer'] = results[0]['reviewer']
                if case == 'reused':
                    self.assertEqual(self.finish(state, admitted, copy.deepcopy(results))['valid_sets'], 1)
                    admitted = self.admit(state, self.partition(), reason='second')
                result = self.finish(state, admitted, results, ok=False)
                self.assertNotEqual(result.returncode, 0)
                journal = json.loads(Path(state).read_text())
                self.assertNotIn('receipt', journal)
                self.assertIsNone(journal['pending'])
                self.assertEqual(journal['events'][-1]['kind'], 'invalid-result')
                self.assertEqual(journal['attempts'], 2 if case == 'reused' else 1)


if __name__ == '__main__':
    unittest.main()
