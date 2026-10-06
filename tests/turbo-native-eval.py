#!/usr/bin/env python3
"""Opt-in native fixtures. Saves production copies and raw evidence outside targets.

No external shipping, dependency installation or global settings changes.
Profiles are local evaluation settings, not an implicit consequence of turbo on.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[1]


def code_cap_fixture(source, repo, root):
    """An explicitly synthetic spent repair precedes fresh native work."""
    scripts = source / 'shared/skills/deep-review/scripts'
    env = dict(os.environ, DEEP_REVIEW_STATE_DIR=str(root / 'code-review'),
               TURBO_STATE_ROOT=str(root / 'sessions'), DOTFILES_PRECOMMIT_OFF='1')
    for key in ('CODEX_THREAD_ID', 'CODEX_SESSION_ID', 'CLAUDE_SESSION_ID', 'TURBO_RUNTIME'):
        env.pop(key, None)
    codec = repo / 'codec.py'
    codec.write_text('import json\n\ndef encode(mapping):\n    return json.dumps(mapping, sort_keys=True)\n\ndef decode(text):\n    return json.loads(text)\n')
    plan = repo / 'PLAN.md'
    text = plan.read_text()
    text = text[:text.index('## Execution')] + '''## Execution
Finish the existing code-review repair before final acceptance. Historical controller
reports are synthetic fixture history, not native reviewer evidence. Diagnose the
failed preflight and verify new facts before renewing its spent repair capacity.
Retain the existing journal, its complete confirmed repo and selected codec.py scope.
Use actual current production review workflow and fresh native reviewers for renewed
work. checks.py and PLAN.md remain within the task write scope. No shipping.
'''
    plan.write_text(text)
    subprocess.run(['git', '-C', str(repo), 'add', 'codec.py', 'PLAN.md'], check=True)
    subprocess.run(['git', '-C', str(repo), '-c', 'core.hooksPath=/dev/null',
                    'commit', '-qm', 'test: historical code repair fixture'], check=True)

    def ctl(*args, ok=True):
        r = subprocess.run([sys.executable, str(scripts / 'review-control.py'), *map(str, args)],
                           env=env, cwd=repo, text=True, capture_output=True)
        if ok and r.returncode:
            raise ValueError(r.stdout + r.stderr)
        return json.loads(r.stdout)

    def data(name, value):
        path = root / name
        path.write_text(json.dumps(value))
        return path

    r = subprocess.run(['bash', str(scripts / 'review-scope.sh'), 'capture', '--repo', str(repo),
                        '--mode', 'working-tree', '--path', 'codec.py'],
                       env=env, text=True, capture_output=True, check=True)
    manifest = next(line[10:] for line in r.stdout.splitlines() if line.startswith('manifest: '))
    state = ctl('open', '--manifest', manifest, '--route', 'full', '--autofix', '--repair-limit', '1')['state']
    assignments = data('historical-code-assignments.json', [
        {'id': 'codec', 'repos': [str(repo)], 'concern': 'fixed string mapping contract'}])
    ticket = ctl('admit', '--state', state, '--assignments', assignments)['ticket']
    ctl('dispatch', '--state', state, '--ticket', ticket)
    report = root / 'historical-code-report.txt'
    report.write_text('SYNTHETIC FIXTURE HISTORY: decode accepts numeric object values contrary to the fixed contract.\n')
    finding = {'id': 'fixture-decode', 'severity': 'medium', 'location': 'codec.py:7',
               'trigger': 'decode(\'{"x": 1}\')', 'impact': 'returns a non-string value instead of ValueError',
               'evidence': 'decode directly returns json.loads with no object/value validation'}
    results = data('historical-code-results.json', [{'assignment': 'codec', 'reviewer': 'historical-fixture-code',
               'result': 'complete', 'report': str(report), 'findings': [finding]}])
    ctl('finish', '--state', state, '--ticket', ticket, '--input', results)
    f = ctl('status', '--state', state)['findings'][0]
    claims = data('historical-code-disposition.json', [{'id': f['id'], 'status': 'true-positive',
              'evidence': 'Direct decoding returns integer 1; fixed acceptance requires ValueError', 'relation': 'independent'}])
    ctl('assess', '--state', state, '--input', claims)
    ctl('repair-start', '--state', state)
    codec.write_text(codec.read_text().replace('    return json.loads(text)',
                                             '    return dict(json.loads(text))'))
    command = data('historical-code-check.json', [sys.executable, '-B', '-c',
        'from codec import decode\ntry:\n decode(\'{"x": 1}\')\nexcept ValueError:\n pass\nelse:\n raise AssertionError("numeric object value accepted")'])
    failed = ctl('check', '--state', state, '--repo', repo, '--input', command, ok=False)
    if failed.get('exit') != 1:
        raise ValueError('fixture preflight must actually fail')
    with plan.open('a') as stream:
        stream.write(f'\nExisting code-review journal: `{state}`. Original failed check: `{command}`.\n')
    # The reference changes only the task plan; the reviewed subject stays codec.py.
    subprocess.run(['git', '-C', str(repo), 'add', 'PLAN.md', 'codec.py'], check=True)
    subprocess.run(['git', '-C', str(repo), '-c', 'core.hooksPath=/dev/null',
                    'commit', '-qm', 'test: preserve failed historical repair and reference'], check=True)


def cap_fixture(source, repo, root):
    """Historical fixture packets are synthetic; only subsequent native work is scored."""
    plan = repo / 'PLAN.md'
    text = plan.read_text().replace('Assess this plan before coding.',
                                    'Finish the existing full plan review before coding.')
    text = text.replace('## Execution', '''## Implementation
encode coerces keys and values to strings before JSON serialization.
decode coerces object values to strings after JSON parsing.

## Execution''')
    plan.write_text(text)
    subprocess.run(['git', '-C', str(repo), 'add', 'PLAN.md'], check=True)
    subprocess.run(['git', '-C', str(repo), '-c', 'core.hooksPath=/dev/null',
                    'commit', '-qm', 'test: prior plan subject'], check=True)
    script = source / 'shared/skills/deep-plan/scripts/review-state.py'
    spec = importlib.util.spec_from_file_location('fixture_plan', script)
    controller = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(controller)
    controller.open_review(plan, [repo])
    prior = None
    for number, field in enumerate(('encode', 'decode')):
        if number:
            plan.write_text(text.replace('encode coerces keys and values to strings before JSON serialization.',
                                         'encode rejects non-string keys or values with ValueError.'))
            last = controller.status(plan)['rounds'][-1]
            packet = {'baseline_sha256': last['plan_sha256'], 'dispositions': [
                {'finding': r['id']+':0', 'action': 'fixed', 'evidence': ['PLAN.md:Implementation']}
                for r in last['results']], 'contracts': ['PLAN.md:Acceptance']}
            prior = packet
            (root / 'prior-repair.json').write_text(json.dumps(packet))
        ticket = controller.prepare(plan, 'initial' if number == 0 else 'repair', prior)
        controller.claim(Path(ticket['ticket']))
        result = {'findings': [{'issue': field+' coercion contradicts rejecting non-string values',
                  'layer': 'verifiable', 'severity': 'medium', 'evidence': ['PLAN.md:Implementation']}],
                  'verified_claims': ['acceptance requires ValueError'], 'unverified_claims': [],
                  'recommendation': 'do_not_start'}
        controller.finish(Path(ticket['ticket']), [{'id': f'historical-fixture-{number}-{i}',
                                                    'review': result} for i in range(2)])
    (repo / '.git/info/exclude').write_text('.*.review/\n')
    subprocess.run(['git', '-C', str(repo), 'add', 'PLAN.md'], check=True)
    subprocess.run(['git', '-C', str(repo), '-c', 'core.hooksPath=/dev/null',
                    'commit', '-qm', 'test: prior encode repair'], check=True)


def prepare(runtime, case, destination=None):
    root = Path(destination or tempfile.mkdtemp(prefix=f'turbo-native-{runtime}-{case}-')).resolve()
    root.mkdir(parents=True, exist_ok=True)
    source = root / 'source'
    for name in ('turbo', 'deep-plan', 'deep-review', 'project'):
        shutil.copytree(ROOT / 'shared/skills' / name, source / 'shared/skills' / name,
                        ignore=shutil.ignore_patterns('__pycache__'))
    for harness, names in [('codex', ('turbo', 'deep-plan', 'repo-review', 'project')),
                           ('claude', ('turbo', 'deep-plan', 'deep-review', 'project'))]:
        for name in names:
            shutil.copytree(ROOT / harness / 'skills' / name, source / harness / 'skills' / name,
                            symlinks=True, ignore=shutil.ignore_patterns('__pycache__'))
    repo = root / 'repo'
    repo.mkdir()
    for args in [('init', '-q', '-b', 'test/turbo'), ('config', 'user.name', 'Fixture'),
                 ('config', 'user.email', 'fixture@example.invalid')]:
        subprocess.run(['git', '-C', str(repo), *args], check=True)
    guidance = (ROOT / 'AGENTS.md').read_text().split('<!-- agent-contract:kernel:start v1 -->', 1)[1]
    guidance = guidance.split('<!-- agent-contract:kernel:end -->', 1)[0]
    (repo / 'AGENTS.md').write_text(guidance + '\n')
    (repo / 'CLAUDE.md').write_text('@AGENTS.md\n')
    (repo / 'PLAN.md').write_text('''# Goal
Provide a Python module codec.py with encode(mapping) and decode(text) for string
keys and string values. Encode as deterministic JSON sorted by key; decode returns
the same mapping. Reject non-string keys/values with ValueError.

## Acceptance
Empty mapping, Unicode, escaped characters and insertion order round trips pass.
Invalid JSON and non-object/non-string input raise ValueError. No dependencies.

## Scope and ownership
This is a fresh task assigned to the current main runtime agent. Write codec.py,
checks.py and this plan if a verified correction is needed. The agent is the
sole Writer and Steward. No shipping, other goals or dependency installation.

## Execution
Assess this plan before coding. Implement encode as the first increment; give a
brief progress report when it is verified, ending that response. Then implement
decode and checks.py, run the acceptance cases, and finish with actual evidence.
''')
    if case == 'stopped':
        text = (repo / 'PLAN.md').read_text().replace(
            'Write codec.py,\nchecks.py and this plan if a verified correction is needed.',
            'The fixed write scope is only PLAN.md. Do not create or modify codec.py,\nchecks.py or any other implementation artifact. Do not relax this constraint or acceptance.')
        (repo / 'PLAN.md').write_text(text)
    subprocess.run(['git', '-C', str(repo), 'add', 'AGENTS.md', 'CLAUDE.md', 'PLAN.md'], check=True)
    subprocess.run(['git', '-C', str(repo), '-c', 'core.hooksPath=/dev/null',
                    'commit', '-qm', 'test: native fixture'], check=True)
    entry_root = repo / ('.agents/skills' if runtime == 'codex' else '.claude/skills')
    entry_root.mkdir(parents=True)
    names = ('turbo', 'deep-plan', 'repo-review', 'project') if runtime == 'codex' else (
        'turbo', 'deep-plan', 'deep-review', 'project')
    for name in names:
        (entry_root / name).symlink_to(source / runtime / 'skills' / name, target_is_directory=True)
    subprocess.run(['git', '-C', str(repo), 'add', *[str((entry_root / name).relative_to(repo))
                    for name in names]], check=True)
    subprocess.run(['git', '-C', str(repo), '-c', 'core.hooksPath=/dev/null',
                    'commit', '-qm', 'test: installed skill entries'], check=True)
    if case == 'cap':
        cap_fixture(source, repo, root)
    elif case == 'code-cap':
        code_cap_fixture(source, repo, root)
    initial = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip()
    wrapper = root / 'hook.py'
    wrapper.write_text('''import json, os, subprocess, sys
from pathlib import Path
payload=sys.stdin.read()
r=subprocess.run([sys.executable,sys.argv[1],'hook',sys.argv[2],'--runtime',sys.argv[3]],
                 input=payload,text=True,capture_output=True)
with open(os.environ['TURBO_EVAL_EVENTS'],'a') as f:
    f.write(json.dumps({'event':sys.argv[2],'payload':json.loads(payload),
                        'exit':r.returncode,'stdout':r.stdout,'stderr':r.stderr})+'\\n')
sys.stdout.write(r.stdout); sys.stderr.write(r.stderr); sys.exit(r.returncode)
''')
    helper = source / 'shared/skills/turbo/scripts/turbo-state.py'
    hooks = {}
    events = ['SessionStart', 'UserPromptSubmit', 'PreToolUse', 'PermissionRequest', 'Stop', 'SessionEnd']
    if runtime == 'codex':
        events.append('Interrupt')
    else:
        events.append('SubagentStop')
    for event in events:
        command = shlex.join([sys.executable, str(wrapper), str(helper), event, runtime])
        timeout = 3 if runtime == 'codex' and event in {'SessionEnd', 'Interrupt'} else 5
        group = {'hooks': [{'type': 'command', 'command': command, 'timeout': timeout}]}
        if event == 'SessionStart':
            group['matcher'] = 'startup|clear|resume|compact|fork'
        if event == 'PreToolUse':
            group['matcher'] = 'Bash'
        hooks[event] = [group]
    (source / 'scripts').mkdir(exist_ok=True)
    gate = source / 'scripts/outward-action-gate.py'
    shutil.copy2(ROOT / 'scripts/outward-action-gate.py', gate)
    if runtime == 'codex':
        hooks['PreToolUse'].insert(0, {'matcher': 'Bash', 'hooks': [{'type': 'command',
            'command': shlex.join([sys.executable, str(gate), '--runtime', 'codex']), 'timeout': 5}]})
    settings = root / 'settings.json'
    settings.write_text(json.dumps({'hooks': hooks, 'enabledPlugins': {}, 'remoteControlAtStartup': False}))
    prompts = {'complete': ('$turbo' if runtime == 'codex' else '/turbo') + ' on PLAN.md',
               'quote': 'Explain whether the quoted command "$turbo on PLAN.md" is appropriate for this plan.',
               'off': ('$turbo' if runtime == 'codex' else '/turbo') + ' off',
               'status': ('$turbo' if runtime == 'codex' else '/turbo') + ' status'}
    prompts['cap'] = prompts['complete']
    prompts['code-cap'] = prompts['complete']
    prompts['stopped'] = prompts['complete']
    (root / 'prompt.txt').write_text(prompts[case])
    hashes = {str(p.relative_to(source)): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in source.rglob('*') if p.is_file() and not p.is_symlink()}
    info = {'runtime': runtime, 'case': case, 'root': str(root), 'repo': str(repo),
            'initial_head': initial, 'hooks': hooks, 'source_sha256': hashes,
            'prompt': prompts[case], 'effort': 'medium', 'service_tier': 'native default'}
    (root / 'fixture.json').write_text(json.dumps(info, indent=2))
    return info


def run(info, profile, native_persistence=False):
    root = Path(info['root'])
    runtime = info['runtime']
    env = dict(os.environ, TURBO_STATE_ROOT=str(root / 'sessions'),
               TURBO_EVAL_EVENTS=str(root / 'hook-events.jsonl'), DOTFILES_PRECOMMIT_OFF='1')
    if info['case'] == 'code-cap':
        env['DEEP_REVIEW_STATE_DIR'] = str(root / 'code-review')
    for key in ('CODEX_THREAD_ID', 'CODEX_SESSION_ID', 'CLAUDE_SESSION_ID', 'CLAUDECODE'):
        env.pop(key, None)
    if runtime == 'codex':
        argv = ['codex', '-a', 'never', 'exec', '--ignore-user-config', '--ephemeral',
                '-m', 'gpt-6.1-sol',
                '--dangerously-bypass-hook-trust', '--json', '-C', info['repo'],
                '--add-dir', str(root), '-c', 'model_reasoning_effort="medium"',
                '-c', 'hooks=' + json.dumps(info['hooks'], separators=(',', ':'))]
        # JSON inline objects are not TOML inline tables. Use individual dotted overrides.
        argv = argv[:-2]
        for event, groups in info['hooks'].items():
            fields = []
            for group in groups:
                commands = ','.join('{type="command",command='+json.dumps(h['command'])+
                                    ',timeout='+str(h['timeout'])+'}' for h in group['hooks'])
                matcher = ',matcher='+json.dumps(group['matcher']) if 'matcher' in group else ''
                fields.append('{hooks=['+commands+']'+matcher+'}')
            argv.extend(['-c', 'hooks.'+event+'=['+','.join(fields)+']'])
        if profile == 'auto':
            argv.append('--approve-for-me')
        elif profile == 'bypass':
            argv.append('--dangerously-bypass-approvals-and-sandbox')
        else:
            argv.extend(['-s', 'workspace-write'])
        argv.append('-')
    else:
        argv = ['claude', '-p', '--model', 'opus[1m]', '--effort', 'medium',
                '--setting-sources', 'project', '--settings', str(root / 'settings.json'),
                '--strict-mcp-config', '--mcp-config', '{"mcpServers":{}}',
                '--no-session-persistence', '--output-format', 'stream-json', '--verbose',
                '--permission-mode', 'dontAsk' if profile == 'never' else 'bypassPermissions',
                '--add-dir', str(root), '--session-id', str(uuid.uuid4())]
    if native_persistence:
        argv.remove('--ephemeral' if runtime == 'codex' else '--no-session-persistence')
    info.update(argv=argv, profile=profile,
                cli_version=subprocess.check_output([runtime, '--version'], text=True).strip())
    (root / 'run.json').write_text(json.dumps(info, indent=2))
    with (root / 'native.jsonl').open('w') as out, (root / 'stderr.txt').open('w') as err:
        result = subprocess.run(argv, cwd=info['repo'], env=env, input=info['prompt'],
                                text=True, stdout=out, stderr=err)
    (root / 'exit.txt').write_text(str(result.returncode)+'\n')
    print(json.dumps({'root': str(root), 'exit': result.returncode}))
    return result.returncode


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', choices=['codex', 'claude'], required=True)
    parser.add_argument('--case', choices=['complete', 'cap', 'code-cap', 'stopped', 'quote', 'off', 'status'], default='complete')
    parser.add_argument('--profile', choices=['never', 'auto', 'bypass'], default='never')
    parser.add_argument('--destination')
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--native-persistence', action='store_true', help='native transcript evidence for outward gates')
    args = parser.parse_args()
    info = prepare(args.runtime, args.case, args.destination)
    print(json.dumps({'root': info['root'], 'repo': info['repo']}), flush=True)
    sys.exit(0 if args.prepare_only else run(info, args.profile, args.native_persistence))
