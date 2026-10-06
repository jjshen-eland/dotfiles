"""Behavior oracle for session control and delegated review; no model calls."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'shared/skills/turbo/scripts/turbo-state.py'
PLAN = ROOT / 'shared/skills/deep-plan/scripts/review-state.py'


def module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        subprocess.run(['git', 'init', '-q', '-b', 'test/turbo', str(self.repo)], check=True)
        self.plan = self.repo / 'plan.md'
        self.plan.write_text('# Goal\nCreate a passing result.\n')
        self.evidence = self.repo / 'result.txt'
        self.evidence.write_text('initial result\n')
        subprocess.run(['git', '-C', str(self.repo), 'add', 'plan.md', 'result.txt'], check=True)
        subprocess.run(['git', '-C', str(self.repo), '-c', 'user.name=Test',
                        '-c', 'user.email=test@example.org', 'commit', '-qm', 'test: seed'], check=True)
        self.before = dict(os.environ)
        os.environ['TURBO_STATE_ROOT'] = str(self.root / 'sessions')
        os.environ['CODEX_THREAD_ID'] = 'main'
        self.m = module(SCRIPT, 'turbo')

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.before)
        self.tmp.cleanup()

    def on(self, session='main', allow=()):
        text = '$turbo on' + (' --allow ' + ','.join(allow) if allow else '')
        return self.m.control('codex', session, 'on', text, self.plan, [self.repo], allow)

    def event(self, session='main', **fields):
        return dict(session_id=session, cwd=str(self.repo), **fields)


class Session(Fixture):

    def test_local_heredoc_uses_classifier_unknown_without_summary_denial(self):
        self.on()
        command = "cat <<'REPORT'\na reviewer's local notes\nREPORT\n"
        checked = subprocess.run(['bash', '-n'], input=command, text=True, capture_output=True)
        self.assertEqual(checked.returncode, 0)
        self.assertEqual(self.m.hook('codex', 'PreToolUse', self.event(
            tool_name='Bash', tool_input={'command': command})), {})
        self.assertEqual(self.m.hook('codex', 'PreToolUse', self.event(
            tool_name='Bash', tool_input={'command': 'gh pr create --title result --body local'}))[
                'hookSpecificOutput']['permissionDecision'], 'deny')

    def test_notice_distinguishes_enabled_idle_and_actual_host_wait(self):
        self.m.control('codex', 'main', 'on', '$turbo on')
        self.assertEqual(self.m.notice('codex', self.event()), '等待輸入起點')
        self.m.control('codex', 'main', 'off')
        self.on()
        self.assertEqual(self.m.notice('codex', self.event(last_assistant_message='<!-- wait4me: real choice -->')),
                         '等待輸入起點')
        self.m.hook('codex', 'PermissionRequest', self.event())
        self.assertEqual(self.m.notice('codex', self.event()), '等待輸入起點')

    def test_outward_requires_an_actual_current_native_summary(self):
        self.on(allow=['push', 'pr', 'merge'])
        trace = self.root / 'native-transcript.jsonl'
        payload = self.event(tool_name='Bash', tool_input={'command': 'git push -u origin test/turbo'},
                             transcript_path=str(trace), turn_id='current')
        def emit(role, text, turn='current'):
            trace.write_text(json.dumps({'type': 'session_meta', 'payload': {'id': 'main'}})+'\n'+json.dumps(
                {'type': 'response_item', 'payload': {'type': 'message', 'role': role, 'phase': 'commentary',
                 'content': [{'type': 'output_text', 'text': text}],
                 'internal_chat_message_metadata_passthrough': {'turn_id': turn}}})+'\n')
        self.assertEqual(self.m.hook('codex', 'PreToolUse', payload)['hookSpecificOutput']['permissionDecision'], 'deny')
        summary = f'Ship 摘要：\n repo root: {self.repo}\n feature branch: test/turbo\n commit: result only'
        for role, text, turn in [('user', summary, 'current'), ('tool', summary, 'current'),
                                 ('assistant', summary, 'other'), ('assistant', 'reading references', 'current'),
                                 ('assistant', 'Quoted request: ' + summary, 'current')]:
            emit(role, text, turn)
            self.assertEqual(self.m.hook('codex', 'PreToolUse', payload)['hookSpecificOutput']['permissionDecision'], 'deny')
        emit('assistant', summary)
        self.assertEqual(self.m.hook('codex', 'PreToolUse', payload), {})
        self.evidence.write_text('a new committed result\n')
        subprocess.run(['git', '-C', str(self.repo), 'add', 'result.txt'], check=True)
        subprocess.run(['git', '-C', str(self.repo), '-c', 'user.name=Test', '-c', 'user.email=test@example.org',
                        'commit', '-qm', 'test: changed result'], check=True)
        emit('assistant', 'status update')
        self.assertEqual(self.m.hook('codex', 'PreToolUse', payload)['hookSpecificOutput']['permissionDecision'], 'deny')
        self.m.control('codex', 'main', 'off')
        self.assertEqual(self.m.hook('codex', 'PreToolUse', payload), {})

    def test_claude_summary_binds_native_prompt_and_actual_tool(self):
        self.m.control('claude', 'claude-main', 'on', '/turbo on --allow push', self.plan, [self.repo])
        trace = self.root / 'claude-transcript.jsonl'
        payload = self.event(session='claude-main', tool_name='Bash', tool_use_id='actual-tool', prompt_id='current',
                             tool_input={'command': 'git push origin test/turbo'}, transcript_path=str(trace))
        summary = f'Ship 摘要：\nrepo root: {self.repo.resolve()}\nfeature branch: test/turbo'
        records = [{'type': 'user', 'sessionId': 'claude-main', 'promptId': 'current'},
                   {'type': 'assistant', 'sessionId': 'claude-main', 'isSidechain': False, 'message':
                    {'role': 'assistant', 'content': [{'type': 'text', 'text': summary}]}},
                   {'type': 'assistant', 'sessionId': 'claude-main', 'message':
                    {'role': 'assistant', 'content': [{'type': 'tool_use', 'id': 'actual-tool', 'name': 'Bash',
                                                     'input': payload['tool_input']}]}}]
        def emit():
            trace.write_text(''.join(json.dumps(r)+'\n' for r in records))
        records[1]['isSidechain'] = True
        emit()
        self.assertEqual(self.m.hook('claude', 'PreToolUse', payload)['hookSpecificOutput']['permissionDecision'], 'deny')
        records[1]['isSidechain'] = False
        records[0]['promptId'] = 'other'
        emit()
        self.assertEqual(self.m.hook('claude', 'PreToolUse', payload)['hookSpecificOutput']['permissionDecision'], 'deny')
        records[0]['promptId'] = 'current'
        records[2]['message']['content'][0]['id'] = 'invented'
        emit()
        self.assertEqual(self.m.hook('claude', 'PreToolUse', payload)['hookSpecificOutput']['permissionDecision'], 'deny')
        records[2]['message']['content'][0]['id'] = 'actual-tool'
        emit()
        self.assertEqual(self.m.hook('claude', 'PreToolUse', payload), {})

    def test_background_review_waits_without_stalling_then_resumes(self):
        self.on()
        p = module(PLAN, 'plan_waiting')
        p.open_review(self.plan, [self.repo])
        ticket = p.prepare(self.plan, 'initial')
        p.claim(Path(ticket['ticket']))
        for _ in range(2):
            self.assertEqual(self.m.hook('codex', 'Stop', self.event())['decision'], 'block')
            self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'waiting')
        result = {'findings': [], 'verified_claims': [], 'unverified_claims': [],
                  'recommendation': 'start'}
        p.finish(Path(ticket['ticket']), [{'id': f'waiting-{i}', 'review': result} for i in range(2)])
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'running')
        self.assertEqual(self.m.hook('codex', 'Stop', self.event())['decision'], 'block')

    def test_claude_background_completion_does_not_need_stop_polling(self):
        self.m.control('claude', 'claude-main', 'on', '/turbo on', self.plan, [self.repo])
        self.m.review_pending('claude', 'claude-main', self.plan, [self.repo], 'ticket')
        for _ in range(2):
            self.assertNotIn('decision', self.m.hook('claude', 'Stop', self.event(session='claude-main')))
            self.assertEqual(self.m.control('claude', 'claude-main', 'status')['phase'], 'waiting')
        self.m.review_checkpoint('claude', 'claude-main', self.plan, [self.repo], 'ticket')
        self.assertEqual(self.m.control('claude', 'claude-main', 'status')['phase'], 'running')

    def test_invalid_review_does_not_leave_a_waiting_goal(self):
        self.on()
        p = module(PLAN, 'plan_invalid_wait')
        p.open_review(self.plan, [self.repo])
        ticket = p.prepare(self.plan, 'initial')
        p.claim(Path(ticket['ticket']))
        with self.assertRaises(ValueError):
            p.finish(Path(ticket['ticket']), [])
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'blocked')
        self.assertNotIn('decision', self.m.hook('codex', 'Stop', self.event()))

    def test_session_start_persists_claude_identity_for_controller_bash(self):
        envfile = self.root / 'native-env'
        os.environ['CLAUDE_ENV_FILE'] = str(envfile)
        self.m.hook('claude', 'SessionStart', self.event(session='claude-main', source='startup'))
        r = subprocess.run(['sh', '-c', '. "$1"; printf "%s:%s" "$TURBO_RUNTIME" "$CLAUDE_SESSION_ID"',
                            'test', str(envfile)], check=True, text=True, capture_output=True)
        self.assertEqual(r.stdout, 'claude:claude-main')

    def test_review_completion_cannot_reactivate_off_or_pending_permission(self):
        self.on()
        self.m.review_pending('codex', 'main', self.plan, [self.repo], 'ticket')
        self.m.hook('codex', 'PermissionRequest', self.event())
        self.m.review_checkpoint('codex', 'main', self.plan, [self.repo], 'ticket')
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'blocked')
        self.m.control('codex', 'main', 'off')
        self.m.review_checkpoint('codex', 'main', self.plan, [self.repo], 'ticket')
        self.assertEqual(self.m.control('codex', 'main', 'status')['mode'], 'off')

    def test_checkpoint_uses_selected_runtime_in_nested_runtime_environment(self):
        os.environ['CLAUDE_SESSION_ID'] = 'claude-main'
        os.environ['TURBO_RUNTIME'] = 'claude'
        self.m.control('claude', 'claude-main', 'on', '/turbo on', self.plan, [self.repo])
        self.evidence.write_text('repair now reviewed by Claude\n')
        self.m.checkpoint_from_environment(self.plan, [self.repo])
        sha = hashlib.sha256(self.plan.read_bytes()).hexdigest()
        with self.assertRaises(ValueError):
            self.m.request('claude', 'claude-main', 'deep-plan', self.plan, sha,
                           'focused', [self.evidence], 'reuse the reviewed repair')

    def test_plan_finished_review_spends_its_reviewed_repair(self):
        self.on()
        p = module(PLAN, 'plan_checkpoint')
        p.open_review(self.plan, [self.repo])
        self.plan.write_text('# Goal\nCreate a passing result with verified caller compatibility.\n')
        result = {'findings': [], 'verified_claims': [], 'unverified_claims': [],
                  'recommendation': 'start'}
        for number in range(2):
            ticket = p.prepare(self.plan, 'initial' if number == 0 else 'independent')
            p.claim(Path(ticket['ticket']))
            p.finish(Path(ticket['ticket']), [{'id': f'fresh-{number}-{i}', 'review': result}
                                               for i in range(2)])
        target = p.control_path(self.plan)
        sha = hashlib.sha256(target.read_bytes()).hexdigest()
        with self.assertRaises(ValueError):
            self.m.request('codex', 'main', 'deep-plan', target, sha,
                           'focused', [self.plan], 'repeat the same reviewed repair')

    def test_timestamp_does_not_call_autonomous_continuation_waiting(self):
        self.on()
        r = subprocess.run(['sh', str(ROOT / 'scripts/agent-turn-end-timestamp.sh'), 'codex'],
                           input=json.dumps(self.event()), capture_output=True, text=True, check=True)
        message = json.loads(r.stdout)['systemMessage']
        self.assertIn('Turbo 回合結束', message)
        self.assertIn('GMT+8', message)
        self.assertNotIn('等待輸入', message)

    def test_prompt_updates_effective_permission_mode(self):
        self.on()
        self.m.hook('codex', 'UserPromptSubmit', self.event(prompt='continue', permission_mode='dontAsk'))
        self.assertEqual(self.m.control('codex', 'main', 'status')['permission_mode'], 'dontAsk')

    def test_goal_must_be_a_real_file(self):
        folder = self.repo / 'directory'
        folder.mkdir()
        with self.assertRaises(ValueError):
            self.m.control('codex', 'main', 'on', '$turbo on', folder, [self.repo])

    def test_idle_mode_accepts_a_new_user_goal_without_carrying_delivery_actions(self):
        self.m.control('codex', 'main', 'on', '$turbo on')
        result = self.m.bind('codex', 'main', self.plan, [self.repo], 'Implement this goal')
        self.assertEqual(result['phase'], 'running')
        self.assertEqual(result['allow'], [])

    def test_reviewed_changes_do_not_count_as_new_reentry_progress(self):
        self.on()
        self.evidence.write_text('a repair already reviewed\n')
        self.m.review_checkpoint('codex', 'main', self.plan, [self.repo])
        sha = hashlib.sha256(self.plan.read_bytes()).hexdigest()
        with self.assertRaises(ValueError):
            self.m.request('codex', 'main', 'deep-plan', self.plan, sha,
                           'focused', [self.evidence], 'repeat the same reviewed repair')

    def test_status_is_read_only_and_isolated(self):
        self.assertEqual(self.m.control('codex', 'main', 'status')['mode'], 'off')
        self.assertFalse((self.root / 'sessions').exists())
        self.on()
        self.assertEqual(self.m.control('claude', 'main', 'status')['mode'], 'off')
        self.assertEqual(self.m.control('codex', 'other', 'status')['mode'], 'off')

    def test_on_does_not_grant_shipping_or_reset_generation(self):
        first = self.on()
        self.assertEqual(first['allow'], [])
        self.assertEqual(first['generation'], self.on()['generation'])

    def test_actions_must_be_named_by_current_user_instruction(self):
        with self.assertRaises(ValueError):
            self.m.control('codex', 'main', 'on', '$turbo on', self.plan, [self.repo], ['merge'])
        self.assertEqual(self.on(allow=['commit', 'push', 'pr', 'merge'])['allow'],
                         ['commit', 'merge', 'pr', 'push'])

    def test_original_named_actions_are_recorded_without_duplicate_cli_flags(self):
        result = self.m.control('codex', 'main', 'on', '$turbo on --allow commit,push,pr,merge',
                                self.plan, [self.repo])
        self.assertEqual(result['allow'], ['commit', 'merge', 'pr', 'push'])
        self.assertEqual(result['generation'], self.m.control('codex', 'main', 'on',
                         '$turbo on --allow commit,push,pr,merge', self.plan, [self.repo])['generation'])

    def test_natural_language_normalization_retains_actual_user_source(self):
        source = '開啟 turbo mode，依 plan.md 完成；允許 commit、push、開 PR 與 merge。'
        self.m.control('codex', 'main', 'on', source, self.plan, [self.repo], ['commit', 'push', 'pr', 'merge'],
                       normalized_instruction='$turbo on plan.md --allow commit,push,pr,merge')
        state = self.m.read(self.m.location('codex', 'main'))
        self.assertEqual(state['instruction'], source)
        self.assertEqual(state['normalization'], '$turbo on plan.md --allow commit,push,pr,merge')
        with self.assertRaises(ValueError):
            self.m.control('codex', 'main', 'on', '', self.plan, [self.repo],
                           normalized_instruction='$turbo on plan.md')

    def test_quote_or_generated_message_does_not_activate(self):
        for text in ['Research "$turbo on"', '```\n$turbo on\n```',
                     'turbo-continuation: $turbo on', '$turbo on --allow force-push']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                self.m.control('codex', 'main', 'on', text, self.plan, [self.repo])

    def test_off_and_interrupt_stop_continuation(self):
        self.on()
        self.m.hook('codex', 'Interrupt', self.event())
        self.assertNotIn('decision', self.m.hook('codex', 'Stop', self.event()))
        self.assertEqual(self.m.control('codex', 'main', 'status')['mode'], 'off')

    def test_compact_retains_mode_and_resume_revokes_it(self):
        first = self.on()
        result = self.m.hook('codex', 'SessionStart', self.event(source='compact'))
        self.assertIn('session_id=main', result['hookSpecificOutput']['additionalContext'])
        self.assertEqual(first['generation'], self.m.control('codex', 'main', 'status')['generation'])
        self.m.hook('codex', 'SessionStart', self.event(source='resume'))
        self.assertEqual(self.m.control('codex', 'main', 'status')['mode'], 'off')

    def test_native_stop_continues_only_with_progress(self):
        self.on()
        self.assertEqual(self.m.hook('codex', 'Stop', self.event(turn_id='one'))['decision'], 'block')
        self.evidence.write_text('new result\n')
        self.assertEqual(self.m.hook('codex', 'Stop', self.event(turn_id='two'))['decision'], 'block')
        self.assertNotIn('decision', self.m.hook('codex', 'Stop', self.event(turn_id='three')))
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'blocked')

    def test_stopped_and_complete_require_evidence_and_do_not_continue(self):
        self.on()
        with self.assertRaises(ValueError):
            self.m.report('codex', 'main', 'complete', [], 'deliver', '')
        self.m.report('codex', 'main', 'complete', [self.evidence], 'deliver', 'criteria verified')
        self.assertNotIn('decision', self.m.hook('codex', 'Stop', self.event()))

    def test_pending_permission_and_human_marker_never_autoretry(self):
        self.on()
        self.m.hook('codex', 'PermissionRequest', self.event())
        self.assertNotIn('decision', self.m.hook('codex', 'Stop', self.event()))
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'blocked')


class Reentry(Fixture):
    def setUp(self):
        super().setUp()
        self.p = module(PLAN, 'plan')
        self.p.open_review(self.plan, [self.repo])
        for number in range(2):
            ticket = self.p.prepare(self.plan, 'initial' if number == 0 else 'independent')
            self.p.claim(Path(ticket['ticket']))
            result = {'findings': [], 'verified_claims': [], 'unverified_claims': [],
                      'recommendation': 'start'}
            self.p.finish(Path(ticket['ticket']),
                          [{'id': f'native-{number}-{i}', 'review': result} for i in range(2)])
        self.state = self.p.control_path(self.plan)

    def request(self, mode='focused'):
        self.on()
        self.plan.write_text('# Goal\nCreate a passing result; preserve caller compatibility.\n')
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        packet = self.m.request('codex', 'main', 'deep-plan', self.state, sha,
                                mode, [self.plan], 'verified correction within the same goal')
        path = self.root / 'request.json'
        path.write_text(json.dumps(packet))
        return path, sha

    def test_delegated_reentry_preserves_history_and_changes_only_new_batch_policy(self):
        packet, sha = self.request()
        result = self.p.delegated_reentry(self.plan, packet, sha)
        self.assertEqual(result['batch'], 2)
        self.assertEqual(len(result['previous_batches'][0]['rounds']), 2)
        self.assertEqual(result['previous_batches'][0]['policy'], 'blind')
        self.assertEqual(result['policy'], 'focused')
        self.assertEqual(result['max_rounds'], 2)

    def test_reentry_refuses_off(self):
        packet, sha = self.request()
        self.m.control('codex', 'main', 'off')
        before = self.state.read_bytes()
        with self.assertRaises(ValueError):
            self.p.delegated_reentry(self.plan, packet, sha)
        self.assertEqual(before, self.state.read_bytes())

    def test_reentry_refuses_forgery_and_changed_artifacts(self):
        packet, sha = self.request()
        raw = json.loads(packet.read_text())
        raw['mode'] = 'blind'
        packet.write_text(json.dumps(raw))
        before = self.state.read_bytes()
        with self.assertRaises(ValueError):
            self.p.delegated_reentry(self.plan, packet, sha)
        self.assertEqual(before, self.state.read_bytes())
        packet, sha = self.request()
        self.plan.write_text('changed after request\n')
        with self.assertRaises(ValueError):
            self.p.delegated_reentry(self.plan, packet, sha)

    def test_reentry_refuses_replay_and_stale_state(self):
        packet, sha = self.request()
        self.p.delegated_reentry(self.plan, packet, sha)
        before = self.state.read_bytes()
        with self.assertRaises(ValueError):
            self.p.delegated_reentry(self.plan, packet, sha)
        self.assertEqual(before, self.state.read_bytes())

    def test_reentry_refuses_partial_batch(self):
        packet, sha = self.request()
        self.p.delegated_reentry(self.plan, packet, sha)
        self.plan.write_text('another repair\n')
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        raw = self.m.request('codex', 'main', 'deep-plan', self.state, sha,
                             'blind', [self.plan], 'more facts')
        packet.write_text(json.dumps(raw))
        with self.assertRaises(ValueError):
            self.p.delegated_reentry(self.plan, packet, sha)

    def test_reentry_requires_actual_progress(self):
        self.on()
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        with self.assertRaises(ValueError):
            self.m.request('codex', 'main', 'deep-plan', self.state, sha,
                           'focused', [self.plan], 'try the same review again')


class CodeReentry(unittest.TestCase):
    def setUp(self):
        before = sys.argv
        sys.argv = ['fixture', str(ROOT)]
        try:
            fixture = module(ROOT / 'tests/review-repair-controller.py', 'code_fixture')
        finally:
            sys.argv = before
        self.f = fixture.Controller(methodName='runTest')
        self.f.setUp()
        self.addCleanup(self.f.doCleanups)
        self.m = module(SCRIPT, 'turbo_code')
        self.before = dict(os.environ)
        self.addCleanup(self.restore)
        os.environ['TURBO_STATE_ROOT'] = str(self.f.root / 'sessions')
        os.environ['CODEX_THREAD_ID'] = 'main'
        self.f.env.update(TURBO_STATE_ROOT=os.environ['TURBO_STATE_ROOT'], CODEX_THREAD_ID='main')
        self.plan = self.f.repo / 'plan.md'
        self.plan.write_text('# Goal\nRepair code while retaining compatibility.\n')
        self.m.control('codex', 'main', 'on', '$turbo on', self.plan, [self.f.repo])
        self.state = Path(self.f.ctl('open', '--manifest', self.f.capture('--path', 'a.py'))['state'])
        # Explicit fake transport for mechanical process/proof contracts only.
        # Native forward evals always resolve the real installed Codex binary.
        bin_dir = self.f.root / 'fake-transport'
        bin_dir.mkdir()
        executable = bin_dir / 'codex'
        executable.write_text('#!' + sys.executable + '\n' + '''import json, os, sys, uuid
sys.stdin.read()
print(json.dumps({'type':'thread.started','thread_id':str(uuid.uuid4())}))
value={'result':'complete','report':'Mechanical fake transport; no real code review claim.',
       'findings':json.loads(os.environ.get('TURBO_TEST_FINDINGS','[]'))}
print(json.dumps({'type':'item.completed','item':{'type':'agent_message','text':json.dumps(value)}}))
''')
        executable.chmod(0o755)
        self.f.env['PATH'] = str(bin_dir) + os.pathsep + self.f.env['PATH']
        self.f.review = self.review

    def review(self, state, findings=None, reason='initial', reviewer=None):
        a = self.f.ctl('admit', '--state', state, '--assignments', self.f.assignments(), '--reason', reason)
        self.f.ctl('dispatch', '--state', state, '--ticket', a['ticket'])
        self.f.env['TURBO_TEST_FINDINGS'] = json.dumps(findings or [])
        return self.f.ctl('native-review', '--state', state, '--ticket', a['ticket'])

    def claude_dispatch(self):
        self.f.env.pop('CODEX_THREAD_ID', None)
        self.f.env.update(TURBO_RUNTIME='claude', CLAUDE_SESSION_ID='claude-main')
        self.m.control('claude', 'claude-main', 'on', '/turbo on', self.plan, [self.f.repo])
        a = self.f.ctl('admit', '--state', self.state, '--assignments', self.f.assignments(), '--reason', 'initial')
        self.f.ctl('dispatch', '--state', self.state, '--ticket', a['ticket'])
        return a

    def test_claude_native_report_preserves_original_and_labels_author_summary(self):
        a = self.claude_dispatch()
        original = '## Scope\nActual native report.\n\nCommands: none.\nObservation: retained verbatim.\n'
        self.m.hook('claude', 'SubagentStop', {'session_id': 'claude-main',
                    'agent_id': 'native-agent-1', 'agent_type': 'general-purpose',
                    'last_assistant_message': original})
        summary = self.f.data('author-summary.txt', 'Author paraphrase.')
        # data() writes JSON; the exact summary bytes are deliberately distinct.
        results = self.f.data('native-set.json', [{'assignment': 'source', 'reviewer': 'native-agent-1',
                           'result': 'complete', 'report': str(summary), 'findings': []}])
        self.f.ctl('finish', '--state', self.state, '--ticket', a['ticket'], '--input', results)
        report = json.loads(self.state.read_text())['sets'][-1]['reports'][0]
        self.assertEqual(report['raw_report'], original)
        self.assertEqual(report['author_summary'], summary.read_text())
        self.assertEqual(json.loads(Path(report['report']).read_text())['raw_report'], original)

    def test_claude_missing_native_report_blocks_without_refund(self):
        a = self.claude_dispatch()
        summary = self.f.data('author-only.txt', 'Author report cannot stand in for native original.')
        results = self.f.data('author-set.json', [{'assignment': 'source', 'reviewer': 'invented-agent',
                           'result': 'complete', 'report': str(summary), 'findings': []}])
        self.f.ctl('finish', '--state', self.state, '--ticket', a['ticket'], '--input', results, ok=False)
        value = json.loads(self.state.read_text())
        self.assertEqual(value['attempts'], 1)
        self.assertEqual(value['valid_sets'], 0)
        self.assertIsNone(value['pending'])

    def restore(self):
        os.environ.clear()
        os.environ.update(self.before)

    def packet(self):
        (self.f.repo / 'plan.md').write_text('# Goal\nRepair code; new compatibility evidence.\n')
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        packet = self.m.request('codex', 'main', 'deep-review', self.state, sha,
                               'focused', [self.plan], 'new evidence within the reviewed scope')
        return self.f.data('delegated.json', packet), sha

    def renew(self, packet, sha, ok=True):
        return self.f.ctl('delegated-reentry', '--state', self.state, '--input', packet,
                          '--expected-state-sha', sha, ok=ok)

    def test_cannot_renew_before_original_review(self):
        packet, sha = self.packet()
        before = self.state.read_bytes()
        self.assertNotEqual(self.renew(packet, sha, False).returncode, 0)
        self.assertEqual(before, self.state.read_bytes())

    def test_code_review_waits_for_complete_native_set(self):
        a = self.f.ctl('admit', '--state', self.state, '--assignments', self.f.assignments(), '--reason', 'initial')
        self.f.ctl('dispatch', '--state', self.state, '--ticket', a['ticket'])
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'waiting')
        self.assertEqual(self.m.hook('codex', 'Stop', {'session_id': 'main'})['decision'], 'block')
        self.f.ctl('native-review', '--state', self.state, '--ticket', a['ticket'])
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'running')

    def test_invalid_code_review_blocks_without_refunding_attempt(self):
        a = self.f.ctl('admit', '--state', self.state, '--assignments', self.f.assignments(), '--reason', 'initial')
        self.f.ctl('dispatch', '--state', self.state, '--ticket', a['ticket'])
        self.f.ctl('finish', '--state', self.state, '--ticket', a['ticket'],
                   '--input', self.f.data('invalid-set.json', []), ok=False)
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'blocked')
        self.assertEqual(json.loads(self.state.read_text())['attempts'], 1)

    def test_author_report_cannot_be_admitted_as_native_codex_review(self):
        a = self.f.ctl('admit', '--state', self.state, '--assignments', self.f.assignments())
        self.f.ctl('dispatch', '--state', self.state, '--ticket', a['ticket'])
        report = self.f.root / 'author-report.txt'
        report.write_text('NO BLOCKING FINDINGS; purported /root/reviewer\n')
        result = self.f.data('counterfeit.json', [{'assignment': 'source', 'reviewer': '/root/reviewer',
                            'result': 'complete', 'report': str(report), 'findings': []}])
        r = self.f.ctl('finish', '--state', self.state, '--ticket', a['ticket'], '--input', result, ok=False)
        self.assertNotEqual(r.returncode, 0)
        state = json.loads(self.state.read_text())
        self.assertEqual(state['verdict'], 'BLOCKED')
        self.assertEqual(state['attempts'], 1)
        self.assertEqual(state['sets'], [])

    def test_author_subject_refresh_preserves_budget_and_revokes_receipt(self):
        # The original batch has capacity left; a repaired acceptance counterexample
        # changes its current subject without allocating another batch.
        state = json.loads(self.state.read_text())
        state['policy'].update(route='full', autofix=True, repair_limit=2)
        self.state.write_text(json.dumps(state))
        self.f.review(self.state)
        old = json.loads(self.state.read_text())
        (self.f.repo / 'a.py').write_text('value = 2\n')
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        packet = self.m.request('codex', 'main', 'deep-review', self.state, sha, 'blind',
                               [self.f.repo / 'a.py'], 'verified acceptance counterexample repaired',
                               transition='refresh-subject')
        self.f.ctl('refresh-subject', '--state', self.state, '--input', self.f.data('refresh.json', packet),
                   '--expected-state-sha', sha)
        now = json.loads(self.state.read_text())
        for key in ('attempts', 'repairs', 'batch', 'history', 'sets', 'policy'):
            self.assertEqual(now[key], old[key])
        self.assertNotIn('receipt', now)
        self.assertFalse(now['primary_valid'])
        self.f.review(self.state, reviewer='after-refresh')
        self.assertEqual(json.loads(self.state.read_text())['attempts'], 2)

    def test_review_completion_spends_its_existing_progress(self):
        self.plan.write_text('# Goal\nNew compatibility evidence, now reviewed.\n')
        self.f.review(self.state)
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        with self.assertRaises(ValueError):
            self.m.request('codex', 'main', 'deep-review', self.state, sha,
                           'focused', [self.plan], 'reuse a repair already reviewed')

    def test_valid_renewal_preserves_results_and_requires_fresh_baseline(self):
        self.f.review(self.state)
        packet, sha = self.packet()
        self.renew(packet, sha)
        state = json.loads(self.state.read_text())
        self.assertEqual(len(state['history']), 1)
        self.assertEqual(len(state['sets']), 1)
        self.assertEqual(state['attempts'], 0)
        self.assertEqual(state['policy']['followup'], 'focused')
        self.assertNotEqual(self.renew(packet, sha, False).returncode, 0)
        admitted = self.f.ctl('admit', '--state', self.state, '--assignments', self.f.assignments())
        self.assertEqual(admitted['mode'], 'focused')

    def test_native_failure_retains_process_log_and_spent_attempt(self):
        executable = Path(self.f.env['PATH'].split(os.pathsep)[0]) / 'codex'
        executable.write_text('#!' + sys.executable + '\nimport sys\nsys.stdin.read()\nprint("transport failed")\nsys.exit(3)\n')
        admitted = self.f.ctl('admit', '--state', self.state, '--assignments', self.f.assignments())
        self.f.ctl('dispatch', '--state', self.state, '--ticket', admitted['ticket'])
        r = self.f.ctl('native-review', '--state', self.state, '--ticket', admitted['ticket'], ok=False)
        self.assertNotEqual(r.returncode, 0)
        state = json.loads(self.state.read_text())
        self.assertEqual(state['attempts'], 1)
        self.assertEqual(state['verdict'], 'BLOCKED')
        self.assertIsNone(state['pending'])
        self.assertEqual(self.m.control('codex', 'main', 'status')['phase'], 'blocked')
        traces = list(self.state.parent.glob('native-*/*-events.jsonl'))
        self.assertEqual(len(traces), 1)
        self.assertIn('transport failed', traces[0].read_text())

    def test_refreshed_original_must_be_reverified_before_another_repair(self):
        state = json.loads(self.state.read_text())
        state['policy'].update(route='full', autofix=True, repair_limit=2)
        self.state.write_text(json.dumps(state))
        self.f.review(self.state, [self.f.finding()])
        self.f.assess(self.state)
        (self.f.repo / 'a.py').write_text('value = 2\n')
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        packet = self.m.request('codex', 'main', 'deep-review', self.state, sha, 'focused',
                               [self.f.repo / 'a.py'], 'original trigger repaired before capture',
                               transition='refresh-subject')
        self.f.ctl('refresh-subject', '--state', self.state, '--input', self.f.data('recheck.json', packet),
                   '--expected-state-sha', sha)
        state = json.loads(self.state.read_text())
        self.assertIsNone(state['findings'][0]['disposition'])
        self.assertTrue(state['findings'][0]['recheck'])
        self.assertEqual(state['findings'][0]['disposition_history'][0]['status'], 'true-positive')
        r = self.f.ctl('repair-start', '--state', self.state, ok=False)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(json.loads(self.state.read_text())['repairs'], 0)
        claims = [{'id': state['findings'][0]['id'], 'status': 'resolved', 'relation': 'independent',
                   'evidence': 'original trigger independently checked against changed a.py'}]
        self.f.ctl('assess', '--state', self.state, '--input', self.f.data('resolved.json', claims))
        self.f.review(self.state)
        self.assertEqual(json.loads(self.state.read_text())['verdict'], 'PASS')

    def test_refresh_cannot_refill_a_spent_budget_or_use_a_reentry_packet(self):
        self.f.review(self.state)
        (self.f.repo / 'a.py').write_text('value = 2\n')
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        packet = self.m.request('codex', 'main', 'deep-review', self.state, sha, 'blind',
                               [self.f.repo / 'a.py'], 'new acceptance repair', transition='refresh-subject')
        before = self.state.read_bytes()
        r = self.f.ctl('refresh-subject', '--state', self.state, '--input', self.f.data('cap-refresh.json', packet),
                       '--expected-state-sha', sha, ok=False)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(self.state.read_bytes(), before)
        with self.assertRaises(ValueError):
            self.m.consume_request(self.f.root / 'cap-refresh.json', self.state, 'deep-review',
                                   [self.f.repo], sha)

    def test_renewed_failed_repair_rechecks_original_against_captured_bytes(self):
        state = json.loads(self.state.read_text())
        state['policy'].update(route='full', autofix=True, repair_limit=1)
        self.state.write_text(json.dumps(state))
        self.f.review(self.state, [self.f.finding()])
        self.f.assess(self.state)
        self.f.ctl('repair-start', '--state', self.state)
        self.f.ctl('check', '--state', self.state, '--repo', self.f.repo,
                   '--input', self.f.data('failed-preflight.json', [sys.executable, '-c', 'raise SystemExit(1)']), ok=False)
        (self.f.repo / 'a.py').write_text('value = 2\n')
        sha = hashlib.sha256(self.state.read_bytes()).hexdigest()
        packet = self.m.request('codex', 'main', 'deep-review', self.state, sha, 'focused',
                               [self.f.repo / 'a.py'], 'root cause fixed after the failed bounded attempt')
        self.renew(self.f.data('captured-reentry.json', packet), sha)
        state = json.loads(self.state.read_text())
        self.assertIsNone(state['findings'][0]['disposition'])
        self.assertTrue(state['findings'][0]['recheck'])
        self.assertEqual(state['history'][0]['repairs'], 1)
        self.assertTrue(state['history'][0]['failed_repair']['failed'])
        self.assertEqual(state['repairs'], 0)
        self.assertIsNone(state['repair'])


class Wiring(unittest.TestCase):
    def test_native_fixture_has_no_foreign_working_tree_changes(self):
        runner = module(ROOT / 'tests/turbo-native-eval.py', 'native_fixture')
        with tempfile.TemporaryDirectory() as root:
            info = runner.prepare('codex', 'complete', root)
            r = subprocess.run(['git', '-C', info['repo'], 'status', '--porcelain'],
                               check=True, text=True, capture_output=True)
            self.assertEqual(r.stdout, '')

    def test_native_lifecycle_hooks_are_synchronous_and_keep_other_hooks(self):
        codex = tomllib.loads((ROOT / 'codex/config.toml').read_text())
        claude = json.loads((ROOT / 'claude/settings.json').read_text())
        for runtime, config in [('codex', codex), ('claude', claude)]:
            events = ['SessionStart', 'UserPromptSubmit', 'PreToolUse', 'PermissionRequest', 'Stop', 'SessionEnd']
            if runtime == 'codex':
                events.append('Interrupt')
            else:
                self.assertNotIn('Interrupt', config['hooks'])
                events.append('SubagentStop')
            for event in events:
                hooks = [h for group in config['hooks'][event] for h in group['hooks']]
                expected = f'python3 "$HOME"/.dotfiles/shared/skills/turbo/scripts/turbo-state.py hook {event} --runtime {runtime}'
                target = [h for h in hooks if h['command'] == expected]
                timeout = 3 if runtime == 'codex' and event in {'SessionEnd', 'Interrupt'} else 5
                self.assertEqual(target, [{'type': 'command', 'command': expected, 'timeout': timeout}])
            if runtime == 'codex':
                self.assertNotIn('SubagentStop', config['hooks'])
            start = [g for g in config['hooks']['SessionStart'] if any('turbo-state.py' in h['command'] for h in g['hooks'])]
            self.assertIn('fork', start[0]['matcher'].split('|'))
            hooks = [h for group in config['hooks']['Stop'] for h in group['hooks']]
            self.assertTrue(any('wait4me-hook.sh stop' in h['command'] for h in hooks))
            self.assertTrue(any(h['command'].endswith('agent-turn-end-timestamp.sh '+runtime) for h in hooks))


if __name__ == '__main__':
    unittest.main(verbosity=2)
