#!/usr/bin/env python3
"""Session controls and single-use delegated review bindings; Python stdlib.

This is operational evidence, not a source of user authority or a semantic grader.
The main agent verifies the original user's intent, ownership and acceptance.
"""
import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shlex
import re
import stat
import subprocess
import sys
import uuid

ACTIONS = {'commit', 'push', 'pr', 'merge'}
PHASES = {'idle', 'running', 'waiting', 'blocked', 'stopped', 'complete'}


def digest(value):
    data = value if isinstance(value, bytes) else json.dumps(value, sort_keys=True).encode()
    return hashlib.sha256(data).hexdigest()


def require(value, reason):
    if not value:
        raise ValueError(reason)


def base():
    raw = Path(os.environ.get('TURBO_STATE_ROOT',
                             str(Path(os.environ.get('TMPDIR', '/tmp')) / f'turbo-{os.getuid()}')))
    require(not raw.is_symlink(), 'session storage must not be a symlink')
    return raw.resolve()


def location(runtime, session):
    require(runtime in {'codex', 'claude'} and isinstance(session, str) and
            0 < len(session) <= 256, 'native runtime and session identity required')
    return base() / digest([runtime, session]) / 'state.json'


def native(runtime, session):
    keys = ['CODEX_THREAD_ID', 'CODEX_SESSION_ID'] if runtime == 'codex' else ['CLAUDE_SESSION_ID']
    actual = next((os.environ[k] for k in keys if os.environ.get(k)), None)
    require(actual is None or actual == session, 'different native session; delegation cannot transfer')


def read(path):
    require(not path.is_symlink(), 'session evidence must not be a symlink')
    info = path.stat()
    require(info.st_uid == os.getuid() and stat.S_ISREG(info.st_mode) and
            not info.st_mode & 0o077, 'private owner-only session evidence required')
    result = json.loads(path.read_text())
    require(result.get('schema') == 1 and location(result['runtime'], result['session']) == path,
            'invalid session identity')
    return result


def write(path, state):
    temp = path.with_name(uuid.uuid4().hex + '.new')
    descriptor = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, 'w') as stream:
        json.dump(state, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temp, path)


@contextmanager
def locked(runtime, session):
    path = location(runtime, session)
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    for directory in [base(), path.parent]:
        require(directory.stat().st_uid == os.getuid() and not directory.is_symlink(),
                'invalid session storage owner')
        directory.chmod(0o700)
    lock_path = path.parent / 'lock'
    require(not lock_path.is_symlink(), 'invalid session lock')
    with os.fdopen(os.open(lock_path, os.O_RDWR | os.O_CREAT, 0o600), 'a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield path


def off_state(runtime, session):
    return {'schema': 1, 'runtime': runtime, 'session': session, 'mode': 'off',
            'generation': uuid.uuid4().hex, 'phase': 'idle', 'goal': None, 'repos': [],
            'allow': [], 'instruction': '', 'checkpoint': '', 'reason': '',
            'requests': {}, 'consumed': [], 'last_stop': None, 'progress': None,
            'review_baselines': {}, 'pending_reviews': {}, 'permission_mode': 'unknown'}


def public(state):
    return {key: state[key] for key in ['mode', 'generation', 'phase', 'goal', 'repos',
                                      'allow', 'checkpoint', 'reason', 'permission_mode']}


def roots(repos):
    result = []
    for raw in repos:
        path = Path(raw).resolve(strict=True)
        run = subprocess.run(['git', '-C', str(path), 'rev-parse', '--show-toplevel'],
                             capture_output=True, text=True, check=False)
        require(run.returncode == 0 and Path(run.stdout.strip()).resolve() == path,
                'canonical Git roots required')
        require(base() != path and path not in base().parents, 'session evidence must be outside targets')
        result.append(str(path))
    return sorted(set(result))


def fingerprint(repos):
    result = {}
    for repo in repos:
        command = ['git', '-C', repo, 'ls-files', '-z', '--cached', '--others', '--exclude-standard']
        listing = subprocess.check_output(command, env=dict(os.environ, GIT_OPTIONAL_LOCKS='0'))
        files = {}
        for raw in sorted(set(listing.split(b'\0')) - {b''}):
            name = os.fsdecode(raw)
            # Review journals are control activity, not evidence of a product repair.
            if any(part.startswith('.') and part.endswith('.review') for part in Path(name).parts):
                continue
            path = Path(repo) / name
            if path.is_symlink():
                files[name] = digest(os.fsencode(os.readlink(path)))
            elif path.is_file():
                files[name] = digest(path.read_bytes())
            else:
                files[name] = 'absent'
        result[repo] = files
    return digest(result)


def evidence_files(evidence, repos):
    result = {}
    for raw in evidence:
        path = Path(raw)
        require(not path.is_symlink(), 'evidence must not be a symlink')
        path = path.resolve(strict=True)
        require(path.is_file() and any(Path(repo) in path.parents for repo in repos),
                'evidence must be a real artifact inside delegated scope')
        require(not any(part.startswith('.') and part.endswith('.review') for part in path.parts),
                'review counters are not repair progress')
        result[str(path)] = digest(path.read_bytes())
    require(result, 'observable evidence required')
    return result


def command(instruction, action):
    tokens = shlex.split(instruction)
    require(len(tokens) >= 2 and tokens[:2] in [['$turbo', action], ['/turbo', action]],
            'original explicit main-user control command required')
    allowed = set()
    tail = tokens[2:]
    goal = None
    while tail:
        token = tail.pop(0)
        if token == '--allow' and tail:
            allowed |= set(tail.pop(0).split(','))
        elif not token.startswith('-') and goal is None:
            goal = token
        else:
            raise ValueError('unsupported turbo control argument')
    require(allowed <= ACTIONS, 'unsupported action; use separate explicit authorization')
    return allowed


def control(runtime, session, action, instruction='', goal=None, repos=(), allow=(), normalized_instruction=None):
    path = location(runtime, session)
    if action == 'status':
        return public(read(path) if path.exists() else off_state(runtime, session))
    native(runtime, session)
    require(action in {'on', 'off'}, 'unknown control action')
    require(not normalized_instruction or instruction.strip(), 'actual user source required for normalization')
    # The main agent verifies semantic equivalence and provenance; this is only shape validation.
    named = command(normalized_instruction or instruction, 'on') if action == 'on' else set()
    require(set(allow) <= named, 'requested actions were not named by the user')
    with locked(runtime, session) as path:
        state = read(path) if path.exists() else off_state(runtime, session)
        if action == 'off':
            state = off_state(runtime, session)
        elif state['mode'] == 'on':
            require(not goal or str(Path(goal).resolve()) == state['goal'],
                    'existing goal; do not reset delegation with repeated on')
            require(set(allow) <= set(state['allow']), 'new actions require a new explicit work delegation')
        else:
            canonical_roots = roots(repos)
            canonical_goal = str(Path(goal).resolve(strict=True)) if goal else None
            require(not canonical_goal or Path(canonical_goal).is_file(), 'goal must be a real file')
            require(not canonical_goal or any(Path(repo) in Path(canonical_goal).parents
                                             for repo in canonical_roots), 'goal must belong to delegated scope')
            state.update(mode='on', phase='running' if canonical_goal else 'idle',
                         goal=canonical_goal, repos=canonical_roots, allow=sorted(named),
                         instruction=instruction, normalization=normalized_instruction,
                         progress=fingerprint(canonical_roots))
        write(path, state)
        return public(state)


def report(runtime, session, phase, evidence, checkpoint, reason):
    native(runtime, session)
    require(phase in PHASES and reason and len(reason) <= 2000, 'phase and concrete reason required')
    require(phase != 'waiting', 'only an actual dispatched review ticket establishes waiting')
    with locked(runtime, session) as path:
        state = read(path)
        require(state['mode'] == 'on' and state['goal'], 'no active goal delegation')
        proof = evidence_files(evidence, state['repos']) if phase in {'complete', 'running'} else {}
        state.update(phase=phase, checkpoint=checkpoint, reason=reason, proof=proof)
        if phase in {'blocked', 'complete', 'stopped'}:
            state['pending_reviews'] = {}
        if phase in {'complete', 'stopped'}:
            state['allow'] = []
            state['requests'] = {}
        write(path, state)
        return public(state)


def bind(runtime, session, goal, repos, instruction):
    native(runtime, session)
    require(instruction and len(instruction) <= 32000, 'current actual user goal instruction required')
    with locked(runtime, session) as path:
        state = read(path)
        require(state['mode'] == 'on', 'enable turbo from an actual user control first')
        goal = Path(goal).resolve(strict=True)
        delegated_roots = roots(repos)
        require(goal.is_file() and any(Path(repo) in goal.parents for repo in delegated_roots),
                'canonical goal inside delegated scope required')
        state.update(generation=uuid.uuid4().hex, goal=str(goal), repos=delegated_roots,
                     phase='running', goal_instruction=instruction, allow=[], requests={},
                     review_baselines={}, pending_reviews={}, last_stop=None, progress=fingerprint(delegated_roots))
        state.pop('ship_summary', None)
        write(path, state)
        return public(state)


def review_checkpoint(runtime, session, target, repos, token=None):
    """A valid review establishes a progress baseline; its reviewed repair is spent."""
    path = location(runtime, session)
    if not path.exists():
        return
    with locked(runtime, session) as path:
        state = read(path)
        if state['mode'] == 'on' and state['repos'] == sorted(str(Path(r).resolve()) for r in repos):
            key = str(Path(target).resolve())
            state['review_baselines'][key] = fingerprint(state['repos'])
            if token and state.get('pending_reviews', {}).get(key) == token:
                del state['pending_reviews'][key]
                if state['phase'] == 'waiting' and not state['pending_reviews']:
                    state.update(phase='running', reason='native review result admitted; continue current goal',
                                 last_stop=None)
            write(path, state)


def review_pending(runtime, session, target, repos, token, failed=False):
    path = location(runtime, session)
    if not path.exists():
        return
    with locked(runtime, session) as path:
        state = read(path)
        if state['mode'] != 'on' or not state['goal'] or state['repos'] != sorted(str(Path(r).resolve()) for r in repos):
            return
        key = str(Path(target).resolve())
        pending = state.setdefault('pending_reviews', {})
        if failed:
            if pending.get(key) == token:
                del pending[key]
                if state['phase'] == 'waiting':
                    state.update(phase='blocked', reason='invalid or incomplete native review; diagnose its retained attempt')
        elif state['phase'] in {'running', 'waiting'}:
            pending[key] = token
            state.update(phase='waiting', reason='native review pending; wait for its completion event')
        write(path, state)


def checkpoint_from_environment(target, repos, token=None, event='complete'):
    runtime = os.environ.get('TURBO_RUNTIME')
    require(runtime in {None, 'codex', 'claude'}, 'invalid checkpoint runtime')
    session = None
    if runtime != 'claude':
        session = os.environ.get('CODEX_THREAD_ID') or os.environ.get('CODEX_SESSION_ID')
        if session:
            runtime = 'codex'
    if not session and runtime != 'codex':
        session = os.environ.get('CLAUDE_SESSION_ID')
        runtime = 'claude'
    if session:
        native(runtime, session)
        if event == 'complete':
            review_checkpoint(runtime, session, target, repos, token)
        else:
            require(token and event in {'started', 'failed'}, 'review lifecycle token required')
            review_pending(runtime, session, target, repos, token, failed=event == 'failed')


def live_context(repos):
    runtime = os.environ.get('TURBO_RUNTIME')
    if runtime == 'claude':
        session = os.environ.get('CLAUDE_SESSION_ID')
    else:
        session = os.environ.get('CODEX_THREAD_ID') or os.environ.get('CODEX_SESSION_ID')
        runtime = 'codex' if session else 'claude'
        session = session or os.environ.get('CLAUDE_SESSION_ID')
    if not session:
        return None
    native(runtime, session)
    path = location(runtime, session)
    if not path.exists():
        return None
    state = read(path)
    if (state['mode'] == 'on' and state['goal'] and state['phase'] in {'running', 'waiting'}
            and state['repos'] == sorted(str(Path(r).resolve()) for r in repos)):
        return state
    return None


def native_report_path(binding, target, ticket, reviewer):
    return location(binding['runtime'], binding['session']).parent / 'native-reports' / \
        digest([binding['generation'], str(Path(target).resolve()), ticket, reviewer])


def collect_claude_report(state, payload):
    """Retain the native final response before the author can paraphrase it."""
    reviewer = payload.get('agent_id')
    original = payload.get('last_assistant_message')
    if not (isinstance(reviewer, str) and reviewer and isinstance(original, str) and original.strip()):
        return
    for target, ticket in state.get('pending_reviews', {}).items():
        path = native_report_path(state, target, ticket, reviewer)
        path.parent.mkdir(mode=0o700, exist_ok=True)
        require(not path.parent.is_symlink() and path.parent.stat().st_uid == os.getuid(),
                'invalid native report storage')
        record = {'runtime': 'claude', 'session': state['session'], 'generation': state['generation'],
                  'target': target, 'ticket': ticket, 'reviewer': reviewer,
                  'agent_type': payload.get('agent_type'), 'raw_report': original,
                  'sha256': digest(original.encode()), 'event': 'SubagentStop'}
        if path.exists():
            require(json.loads(path.read_text()) == record, 'native report identity reused with changed output')
        else:
            write(path, record)


def native_report(binding, target, ticket, reviewer):
    path = native_report_path(binding, target, ticket, reviewer)
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(descriptor) as stream:
        info = os.fstat(stream.fileno())
        require(info.st_uid == os.getuid() and stat.S_ISREG(info.st_mode) and not info.st_mode & 0o077,
                'private native report required')
        record = json.load(stream)
    require(all(record.get(key) == binding[key] for key in ('runtime', 'session', 'generation')) and
            record.get('target') == str(Path(target).resolve()) and record.get('ticket') == ticket and
            record.get('reviewer') == reviewer and record.get('event') == 'SubagentStop' and
            record.get('sha256') == digest(record['raw_report'].encode()), 'native original report binding drift')
    return str(path), record['raw_report']


def persist_claude_identity(session):
    """Use only the native SessionStart environment file, never global configuration."""
    raw = os.environ.get('CLAUDE_ENV_FILE')
    if not raw:
        return
    path = Path(raw)
    require(path.parent.is_dir() and path.parent.stat().st_uid == os.getuid(), 'invalid native environment directory')
    descriptor = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    with os.fdopen(descriptor, 'a') as stream:
        info = os.fstat(stream.fileno())
        require(info.st_uid == os.getuid() and stat.S_ISREG(info.st_mode), 'invalid native environment file')
        stream.write(f'\nexport TURBO_RUNTIME=claude\nexport CLAUDE_SESSION_ID={shlex.quote(session)}\n')


def outward_command(payload):
    if payload.get('tool_name') != 'Bash':
        return False
    command_text = payload.get('tool_input', {}).get('command', '')
    helper = Path(__file__).resolve().parents[4] / 'scripts/outward-action-gate.py'
    spec = importlib.util.spec_from_file_location('turbo_outward_classifier', helper)
    classifier = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = classifier
    spec.loader.exec_module(classifier)
    if classifier.classify(command_text):
        return True
    # PR creation is also outward. Reuse the existing shell tokenizer; this is
    # an evidence gate, not a replacement for the host's command policy.
    try:
        commands = classifier.split_commands(classifier.shell_tokens(command_text))
    except ValueError:
        # classify() already returns unknown for unsupported shell syntax such
        # as quoted heredoc data. Its optional PR extension must keep that
        # contract rather than turn a local report into an outward denial.
        return False
    for argv in commands:
        argv, _ = classifier.unwrap_prefix(argv)
        if argv and Path(argv[0]).name == 'gh' and argv[1:3] == ['pr', 'create']:
            return True
    return False


def summary_denial(reason):
    return {'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny',
            'permissionDecisionReason': 'turbo-ship-summary: ' + reason +
            ' Follow Project log-prepare Step 4 and emit the actual Ship 摘要： to the user before '
            'the outward call. This gate grants no delivery or host-approval authority.'}}


def native_summary(runtime, payload):
    raw = payload.get('transcript_path')
    require(raw, 'native transcript unavailable; this delivery profile requires native session persistence')
    descriptor = os.open(raw, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(descriptor) as stream:
        info = os.fstat(stream.fileno())
        require(info.st_uid == os.getuid() and stat.S_ISREG(info.st_mode), 'invalid native transcript owner/type')
        records = []
        for line in stream:
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                pass  # A trailing, currently appended native record is not evidence.
    session = payload['session_id']
    texts = []
    if runtime == 'codex':
        require(any(r.get('type') == 'session_meta' and r.get('payload', {}).get('id') == session
                    for r in records), 'native transcript belongs to another session')
        turn = payload.get('turn_id')
        require(turn, 'native turn identity missing')
        for record in records:
            item = record.get('payload', {})
            if (record.get('type') == 'response_item' and item.get('type') == 'message'
                    and item.get('role') == 'assistant' and item.get('phase') == 'commentary'
                    and item.get('internal_chat_message_metadata_passthrough', {}).get('turn_id') == turn):
                texts.extend(x['text'] for x in item.get('content', [])
                             if x.get('type') == 'output_text' and isinstance(x.get('text'), str))
    else:
        prompt = payload.get('prompt_id')
        require(prompt and payload.get('tool_use_id'), 'native prompt/tool identity missing')
        active_prompt = None
        bound_tool = False
        for record in records:
            if record.get('sessionId') != session or record.get('isSidechain'):
                continue
            if record.get('type') == 'user' and record.get('promptId'):
                active_prompt = record['promptId']
            if record.get('type') != 'assistant' or active_prompt != prompt:
                continue
            for item in record.get('message', {}).get('content', []):
                if item.get('type') == 'text' and isinstance(item.get('text'), str):
                    texts.append(item['text'])
                if item.get('type') == 'tool_use' and item.get('id') == payload['tool_use_id']:
                    bound_tool = item.get('name') == 'Bash' and item.get('input') == payload.get('tool_input')
        require(bound_tool, 'native transcript has no matching current tool call')
    require(texts and texts[-1].lstrip().startswith('Ship 摘要：'),
            'immediately preceding user-visible assistant content must begin with Ship 摘要：')
    return texts[-1]


def summary_guard(state, runtime, payload):
    if not outward_command(payload):
        return {}
    try:
        heads = {}
        for repo in state['repos']:
            head = subprocess.check_output(['git', '-C', repo, 'rev-parse', 'HEAD'], text=True).strip()
            branch = subprocess.check_output(['git', '-C', repo, 'symbolic-ref', '--short', 'HEAD'], text=True).strip()
            require(branch not in {'main', 'master'}, 'delivery must use a feature branch')
            heads[repo] = {'head': head, 'branch': branch}
        prior = state.get('ship_summary')
        if prior and prior['heads'] == heads:
            return {}
        text = native_summary(runtime, payload)
        mentioned = {str(Path(token.strip('`.,:()<>')).resolve())
                     for token in re.findall(r'/[^\s]+', text)}
        require(all(repo in mentioned and data['branch'] in text for repo, data in heads.items()),
                'Ship 摘要： must identify every current repository and feature branch')
        identity = digest([payload.get('transcript_path'), payload.get('turn_id') or payload.get('prompt_id'), text])
        require(not prior or prior['identity'] != identity, 'commit set changed; emit a new current Ship 摘要：')
        state['ship_summary'] = {'identity': identity, 'heads': heads}
        return {}
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as error:
        return summary_denial(str(error))


def hook(runtime, event, payload):
    session = payload.get('session_id')
    if not session:
        return {}
    if runtime == 'claude' and event == 'SessionStart':
        persist_claude_identity(session)
    path = location(runtime, session)
    if event in {'SessionEnd', 'Interrupt'} or (event == 'SessionStart' and payload.get('source') != 'compact'):
        if path.exists():
            with locked(runtime, session) as path:
                write(path, off_state(runtime, session))
        if event == 'SessionStart':
            return {'hookSpecificOutput': {'hookEventName': event, 'additionalContext':
                    f'Turbo foreground identity: runtime={runtime}; session_id={session}. '
                    'New/resumed sessions start off. This lifecycle context grants no delegation.'}}
        return {}
    if not path.exists():
        return {}
    with locked(runtime, session) as path:
        state = read(path)
        if state['mode'] != 'on':
            return {}
        if payload.get('permission_mode'):
            state['permission_mode'] = payload['permission_mode']
        if runtime == 'claude' and event == 'SubagentStop':
            collect_claude_report(state, payload)
            return {}  # Evidence collection neither continues nor blocks a reviewer.
        if event == 'PreToolUse' and state['goal']:
            result = summary_guard(state, runtime, payload)
            write(path, state)
            return result
        if event == 'SessionStart':
            write(path, state)
            return {'hookSpecificOutput': {'hookEventName': event, 'additionalContext':
                    f'Turbo foreground identity: runtime={runtime}; session_id={session}. '
                    'Mode is enabled after compact. Read the turbo workflow and revalidate '
                    'current goal, ownership and actual user authority; cache grants no authority.'}}
        if event == 'PermissionRequest':
            state.update(phase='blocked', reason='host approval pending; await its terminal result')
        elif event == 'UserPromptSubmit':
            text = payload.get('prompt', '').strip()
            if text in {'$turbo off', '/turbo off'}:
                write(path, off_state(runtime, session))
                return {}
            # Never auto-enable from a hook prompt: continuation is also a user prompt.
            write(path, state)
            return {'hookSpecificOutput': {'hookEventName': event, 'additionalContext':
                    'Turbo is enabled. Read the turbo workflow; honor current user steering. '
                    'This hook context is not user authorization.'}}
        elif event == 'Stop' and state['phase'] in {'running', 'waiting'} and state['goal']:
            if '<!-- wait4me:' in (payload.get('last_assistant_message') or ''):
                state.update(phase='blocked', reason='main agent reported that a real user response is required')
            elif payload.get('permission_mode') == 'plan':
                state.update(phase='blocked', reason='host Plan mode requires a legal execution transition')
            elif state['phase'] == 'waiting':
                if runtime == 'codex' and state.get('pending_reviews'):
                    write(path, state)
                    return {'decision': 'block', 'reason':
                            'turbo-review-wait: Verify actual native reviewer launch evidence. For code review, '
                            'invoke review-control.py native-review with the already-dispatched state/ticket '
                            'and await its actual command; never another admit/dispatch. For plan review, '
                            'await the admitted native launch and its complete results in this foreground. '
                            'If launch/liveness failed, diagnose and report blocked; never fabricate results. '
                            'Do not end this foreground while reviewers are pending: exec may close the session. '
                            'This feedback grants no authorization or reviewer capacity.'}
            else:
                current = fingerprint(state['repos'])
                if current == state['last_stop']:
                    state.update(phase='blocked', reason='no observable progress; diagnose and report next step')
                else:
                    state['last_stop'] = current
                    write(path, state)
                    return {'decision': 'block', 'reason':
                            'turbo-continuation: Continue the delegated goal using its current contract. '
                            'Verify scope, ownership, off/cancel and actual progress. Diagnose blockers; '
                            'use the delegated review transition only with verified new evidence. '
                            'Finish only with acceptance and delivery evidence, or record why work must stop. '
                            'This generated prompt grants no action authorization.'}
        write(path, state)
        return {}


def notice(runtime, payload):
    if '<!-- wait4me:' in (payload.get('last_assistant_message') or ''):
        return '等待輸入起點'
    session = payload.get('session_id')
    if session:
        path = location(runtime, session)
        if path.exists():
            state = read(path)
            if (state['mode'] == 'on' and state['goal'] and
                    state['reason'] != 'host approval pending; await its terminal result'):
                return 'Turbo 回合結束'
    return '等待輸入起點'


def request(runtime, session, family, target, state_sha, mode, evidence, reason, transition='delegated-reentry'):
    native(runtime, session)
    require(family in {'deep-plan', 'deep-review'} and mode in {'blind', 'focused'}, 'invalid review route')
    require(transition in {'delegated-reentry', 'refresh-subject'} and
            (transition != 'refresh-subject' or family == 'deep-review'), 'invalid review transition')
    target = Path(target).resolve(strict=True)
    require(digest(target.read_bytes()) == state_sha and reason, 'stale review state or missing diagnosis')
    with locked(runtime, session) as path:
        state = read(path)
        require(state['mode'] == 'on' and state['phase'] == 'running' and state['goal'],
                'live running goal delegation required')
        proof = evidence_files(evidence, state['repos'])
        progress = fingerprint(state['repos'])
        reviewed = state['review_baselines'].get(str(target), state['progress'])
        require(progress != reviewed and progress != state['progress'],
                'new facts or verified repair required after the latest review')
        packet = {'schema': 1, 'session_state': str(path), 'generation': state['generation'],
                  'goal': state['goal'], 'repos': state['repos'], 'family': family,
                  'transition': transition,
                  'target': str(target), 'state_sha256': state_sha, 'mode': mode,
                  'evidence': proof, 'progress': progress, 'reason': reason, 'nonce': uuid.uuid4().hex}
        state['requests'][packet['nonce']] = digest(packet)
        write(path, state)
        return packet


def consume_request(packet_path, target, family, repos, expected_sha, goal=None, transition='delegated-reentry'):
    packet = json.loads(Path(packet_path).read_text())
    path = Path(packet['session_state'])
    state = read(path)
    native(state['runtime'], state['session'])
    with locked(state['runtime'], state['session']) as path:
        state = read(path)
        require(state['mode'] == 'on' and state['phase'] == 'running' and
                state['generation'] == packet['generation'], 'delegation expired, off or blocked')
        require(packet['family'] == family and packet['target'] == str(Path(target).resolve()) and
                packet.get('transition', 'delegated-reentry') == transition and
                packet['state_sha256'] == expected_sha and digest(Path(target).read_bytes()) == expected_sha,
                'wrong or stale controller binding')
        require(packet['repos'] == state['repos'] == sorted(str(Path(r).resolve()) for r in repos) and
                packet['goal'] == state['goal'] and (goal is None or state['goal'] == str(Path(goal).resolve())),
                'goal or scope mismatch')
        nonce = packet['nonce']
        require(nonce not in state['consumed'] and state['requests'].get(nonce) == digest(packet),
                'forged or already consumed review request')
        require(evidence_files(packet['evidence'], state['repos']) == packet['evidence'] and
                fingerprint(state['repos']) == packet['progress'], 'repair evidence changed')
        require(packet['progress'] != state['progress'], 'no new progress')
        del state['requests'][nonce]
        state['consumed'].append(nonce)
        state['progress'] = packet['progress']
        write(path, state)
        return {'mode': packet['mode'], 'goal': state['goal'], 'generation': state['generation'],
                'instruction': state['instruction'], 'request_sha256': digest(packet), 'reason': packet['reason']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['control', 'hook', 'report', 'request', 'bind', 'notice'])
    parser.add_argument('value', nargs='?')
    parser.add_argument('--runtime', required=True, choices=['claude', 'codex'])
    parser.add_argument('--session-id')
    parser.add_argument('--goal')
    parser.add_argument('--repo', action='append', default=[])
    parser.add_argument('--user-message')
    parser.add_argument('--normalized-message')
    parser.add_argument('--allow', default='')
    parser.add_argument('--evidence', action='append', default=[])
    parser.add_argument('--checkpoint', default='')
    parser.add_argument('--reason', default='')
    parser.add_argument('--family', choices=['deep-plan', 'deep-review'])
    parser.add_argument('--target')
    parser.add_argument('--state-sha')
    parser.add_argument('--mode', choices=['blind', 'focused'])
    parser.add_argument('--transition', choices=['delegated-reentry', 'refresh-subject'], default='delegated-reentry')
    args = parser.parse_args()
    try:
        if args.action == 'notice':
            print(notice(args.runtime, json.load(sys.stdin)))
            return 0
        if args.action == 'hook':
            result = hook(args.runtime, args.value, json.load(sys.stdin))
        else:
            require(args.session_id, 'native session identity required')
            if args.action == 'control':
                text = Path(args.user_message).read_text().strip() if args.user_message else ''
                normalized = Path(args.normalized_message).read_text().strip() if args.normalized_message else None
                result = control(args.runtime, args.session_id, args.value or 'status', text, args.goal,
                                 args.repo, args.allow.split(',') if args.allow else [], normalized)
            elif args.action == 'report':
                result = report(args.runtime, args.session_id, args.value, args.evidence, args.checkpoint, args.reason)
            elif args.action == 'bind':
                text = Path(args.user_message).read_text().strip() if args.user_message else ''
                result = bind(args.runtime, args.session_id, args.goal, args.repo, text)
            else:
                result = request(args.runtime, args.session_id, args.family, args.target, args.state_sha,
                                 args.mode, args.evidence, args.reason, args.transition)
        print(json.dumps(result, ensure_ascii=False))
        return 0
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as error:
        if args.action == 'hook':
            if args.value == 'PreToolUse':
                print(json.dumps(summary_denial('native evidence gate unavailable; diagnose its error')))
                return 0
            print('turbo: hook state unavailable; no continuation', file=sys.stderr)
            return 0
        print(json.dumps({'ok': False, 'reason': str(error)}, ensure_ascii=False))
        return 1


if __name__ == '__main__':
    sys.exit(main())
