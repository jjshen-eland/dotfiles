#!/usr/bin/env python3
"""Code-review admission and evidence journal (stdlib, macOS/Linux).

The journal is operational evidence, not mutation authority or a semantic grader.
It lives outside targets and is shared by both runtime entries. All transitions
are serialized; spending a dispatch/repair slot is persisted before work starts.
"""
import argparse
import base64
import contextlib
import difflib
import fcntl
import hashlib
import json
import importlib.util
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import time
import uuid

SCRIPTS = Path(__file__).resolve().parent
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS='0', PYTHONDONTWRITEBYTECODE='1')
SEVERITIES = {'critical', 'high', 'medium', 'low'}
RELATIONS = {'independent', 'unresolved-original', 'repair-introduced', 'repair-exposed', 'unknown'}


def turbo_module(optional=False):
    helper = SCRIPTS.parents[1] / 'turbo/scripts/turbo-state.py'
    if optional and not helper.exists():
        return None
    spec = importlib.util.spec_from_file_location('turbo_state', helper)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class Blocked(Exception):
    pass


def require(condition, message):
    if not condition:
        raise Blocked(message)


def read(path):
    return json.loads(Path(path).read_text())


def write(path, data):
    path = Path(path)
    tmp = path.with_name(path.name + '.' + uuid.uuid4().hex)
    with tmp.open('x') as stream:
        json.dump(data, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(tmp, path)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def run(argv, cwd=None):
    return subprocess.run(argv, cwd=cwd, env=ENV, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=False)


def git(repo, *args):
    r = run(['git', '-c', 'diff.autoRefreshIndex=false', '-C', repo, *args])
    require(r.returncode == 0, r.stderr.decode(errors='replace'))
    return r.stdout


def scope_check(manifest, action='verify'):
    r = run(['bash', str(SCRIPTS / 'review-scope.sh'), action, '--manifest', str(manifest)])
    require(r.returncode == 0, r.stdout.decode(errors='replace') + r.stderr.decode(errors='replace'))


def load_scope(manifest):
    manifest = Path(manifest).resolve()
    scope_check(manifest)
    result = {key: (manifest / key).read_text().strip() for key in
              ('repo', 'mode', 'base', 'head', 'fingerprint', 'guidance-source')}
    result['paths'] = [os.fsdecode(x) for x in (manifest / 'paths.nul').read_bytes().split(b'\0') if x]
    result['guidance'] = [os.fsdecode(x) for x in (manifest / 'guidance.nul').read_bytes().split(b'\0') if x]
    result['subject_files'] = list(dict.fromkeys(os.fsdecode(x) for x in
                                  (manifest / 'subjects.nul').read_bytes().split(b'\0') if x))
    result['working_tree_included'] = result['mode'] != 'range'
    result['manifest'] = str(manifest)
    return result


def scope_identity(scopes):
    return [{k: s[k] for k in ('repo', 'mode', 'base', 'head', 'paths', 'fingerprint', 'guidance')}
            for s in scopes]


def capture_after(scope):
    mode = 'audit' if scope['mode'] == 'audit' else 'branch'
    cmd = ['bash', str(SCRIPTS / 'review-scope.sh'), 'capture', '--repo', scope['repo'], '--mode', mode]
    if mode == 'branch':
        cmd += ['--base', scope['base']]
    for path in scope['paths']:
        cmd += ['--path', path]
    r = run(cmd)
    require(r.returncode == 0, r.stderr.decode(errors='replace'))
    manifest = next(x[10:] for x in r.stdout.decode().splitlines() if x.startswith('manifest: '))
    after = load_scope(manifest)
    require(after['base'] == scope['base'], 'repair changed original baseline')
    return after


def snapshot(scopes):
    """Worktree bytes/modes for repair mutation checks; never follow file symlinks."""
    result = {}
    for s in scopes:
        repo = s['repo']
        files = {}
        paths = git(repo, 'ls-files', '-z', '--cached', '--others', '--exclude-standard')
        for raw in sorted(set(paths.split(b'\0')) - {b''}):
            name = os.fsdecode(raw)
            p = Path(repo) / name
            try:
                mode = p.lstat().st_mode
                if stat.S_ISLNK(mode):
                    data = os.fsencode(os.readlink(p))
                elif stat.S_ISREG(mode):
                    data = p.read_bytes()
                elif stat.S_ISDIR(mode):
                    # Submodule state is also covered by the immutable scope helper.
                    data = git(repo, 'ls-files', '--stage', '--', name)
                else:
                    raise Blocked('unsupported selected file type: ' + str(p))
                files[name] = [mode, base64.b64encode(data).decode()]
            except FileNotFoundError:
                files[name] = None
        result[repo] = {'head': git(repo, 'rev-parse', 'HEAD').decode().strip(), 'files': files}
    return result


def actual_delta(before, after):
    out = []
    for repo in before:
        a, b = before[repo]['files'], after[repo]['files']
        for name in sorted(a.keys() | b.keys()):
            if a.get(name) == b.get(name):
                continue
            old, new = a.get(name), b.get(name)
            x = base64.b64decode(old[1]) if old else b''
            y = base64.b64decode(new[1]) if new else b''
            item = {'repo': repo, 'path': name, 'content_hash': 'sha256',
                    'before': hashlib.sha256(x).hexdigest() if old else None,
                    'after': hashlib.sha256(y).hexdigest() if new else None,
                    'before_mode': old[0] if old else None, 'after_mode': new[0] if new else None}
            if b'\0' not in x + y:
                item['diff'] = ''.join(difflib.unified_diff(
                    x.decode(errors='replace').splitlines(True), y.decode(errors='replace').splitlines(True),
                    fromfile='before/' + name, tofile='after/' + name))
            out.append(item)
    return out


def storage():
    # Fixed system-temp location, independent of runtime and per-session TMPDIR.
    # An override is for isolated fixtures; relocating a live journal is not resume.
    return Path(os.environ.get('DEEP_REVIEW_STATE_DIR', '/tmp/deep-review-' + str(os.getuid()))).resolve()


@contextlib.contextmanager
def locked(root):
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    require(root.stat().st_uid == os.getuid(), 'evidence directory has another owner')
    with (root / 'lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def outside(root, scopes):
    for s in scopes:
        repo = Path(s['repo']).resolve()
        gitdir = Path(git(s['repo'], 'rev-parse', '--absolute-git-dir').decode().strip()).resolve()
        require(not any(root == p or p in root.parents for p in (repo, gitdir)),
                'review evidence must remain outside every target and its Git metadata')


def save(state):
    write(state['state'], state)


def event(state, kind, **data):
    state['events'].append({'kind': kind, 'at': time.time(), **data})
    save(state)


def fresh(state):
    for s in state['scopes']:
        require(load_scope(s['manifest']) == s, 'manifest identity changed')


def current(state):
    fresh(state)
    return digest(scope_identity(state['scopes']))


def persist_scopes(scopes, directory):
    result = []
    for s in scopes:
        target = directory / ('subject-' + uuid.uuid4().hex)
        shutil.copytree(s['manifest'], target)
        result.append({**s, 'manifest': str(target)})
    return result


def open_batch(args, root):
    require(args.manifest, 'at least one manifest is required')
    scopes = sorted([load_scope(p) for p in args.manifest], key=lambda s: s['repo'])
    repos = [s['repo'] for s in scopes]
    require(len(set(repos)) == len(repos), 'duplicate repository')
    outside(root, scopes)
    index_path = root / 'index.json'
    index = read(index_path) if index_path.exists() else {}
    existing = {index[r] for r in repos if r in index}
    policy = {'route': args.route, 'autofix': args.autofix, 'followup': args.followup,
              'repair_limit': args.repair_limit if args.autofix else 0,
              'second_opinion': args.second_opinion}
    if existing:
        require(len(existing) == 1, 'repositories belong to different active review batches')
        state = read(existing.pop())
        require(repos == [s['repo'] for s in state['scopes']], 'repository set changed; retain the original batch')
        require(scope_identity(scopes) == scope_identity(state['scopes']),
                'scope/content changed; use the existing repair transition or explicit new-batch')
        require(policy == state['policy'], 'policy is frozen; reopening cannot reset budget or change mode')
        return summary(state)
    require(1 <= args.repair_limit <= 5, 'repair limit must be 1..5')
    directory = root / uuid.uuid4().hex
    directory.mkdir(mode=0o700)
    state = {'schema': 1, 'state': str(directory / 'state.json'), 'batch': uuid.uuid4().hex,
             'scopes': persist_scopes(scopes, directory), 'origin': scope_identity(scopes),
             'policy': policy, 'attempts': 0, 'second_attempts': 0, 'valid_sets': 0, 'repairs': 0, 'reviewer_count': 0,
             'reviewers': [], 'findings': [], 'events': [], 'sets': [], 'checks': [],
             'pending': None, 'repair': None, 'repair_ready': False, 'primary_valid': False,
                                 'second_done': False, 'edited': [], 'verdict': 'BLOCKED', 'history': []}
    event(state, 'opened')
    for repo in repos:
        index[repo] = state['state']
    write(index_path, index)
    return summary(state)


def summary(state):
    result = {k: state[k] for k in ('state', 'batch', 'policy', 'attempts', 'valid_sets', 'repairs',
                                  'reviewer_count', 'verdict', 'pending', 'findings', 'edited')}
    result['repair'] = ({k: state['repair'][k] for k in ('id', 'findings', 'checks', 'failed')}
                        if state['repair'] else None)
    return result


def result_verdict(state):
    if any(f['disposition'] is None or f['disposition']['status'] == 'unresolved' for f in state['findings']):
        return 'BLOCKED'
    if any(f['open'] for f in state['findings']):
        return 'FAIL'
    if not state['primary_valid'] or (state['policy']['second_opinion'] and not state['second_done']):
        return 'BLOCKED'
    return 'PASS'


def primary_assignments(scopes, assignments):
    """Validate finite path ownership without grading concern prose or dependencies."""
    subjects = {s['repo']: s['subject_files'] for s in scopes}
    ids, repo_counts = set(), {}
    normalized = []
    for assignment in assignments:
        require(isinstance(assignment, dict) and set(assignment) in (
            {'id', 'repos', 'concern'}, {'id', 'repos', 'concern', 'primary'}),
            'assignment fields: id, repos, concern, optional primary')
        require(isinstance(assignment['id'], str) and assignment['id'] and assignment['id'] not in ids,
                'assignment IDs must be distinct nonempty strings')
        require(isinstance(assignment['concern'], str) and assignment['concern'].strip(), 'missing concern')
        require(isinstance(assignment['repos'], list) and assignment['repos'] and
                all(isinstance(p, str) and p and Path(p).is_absolute() for p in assignment['repos']),
                'assignment repos must be nonempty absolute paths')
        repos = [str(Path(p).resolve()) for p in assignment['repos']]
        require(len(set(repos)) == len(repos) and set(repos) <= set(subjects),
                'assignment has unknown or duplicate repos')
        ids.add(assignment['id'])
        for repo in repos:
            repo_counts[repo] = repo_counts.get(repo, 0) + 1
        normalized.append({**assignment, 'repos': repos})
    require(set(repo_counts) == set(subjects), 'partition omits a confirmed repository')
    owned = set()
    for assignment in normalized:
        primary = assignment.get('primary')
        if primary is None:
            require('primary' not in assignment and all(repo_counts[r] == 1 for r in assignment['repos']),
                    'shared-repo assignments require structured primary paths; concern is not coverage')
            primary = {r: list(subjects[r]) for r in assignment['repos']}
        require(isinstance(primary, dict) and all(isinstance(r, str) and r and Path(r).is_absolute()
                                                for r in primary), 'primary must map absolute repos to path lists')
        canonical = {str(Path(r).resolve()): paths for r, paths in primary.items()}
        require(len(canonical) == len(primary) and set(canonical) == set(assignment['repos']),
                'primary repos must exactly match assignment repos')
        for repo, paths in canonical.items():
            require(isinstance(paths, list) and all(isinstance(p, str) for p in paths),
                    'primary paths must be lists of exact subject file names')
            require(len(set(paths)) == len(paths) and set(paths) <= set(subjects[repo]),
                    'primary has duplicate or out-of-subject paths')
            units = {(repo, p) for p in paths}
            require(not owned & units, 'primary ownership overlaps another assignment')
            owned.update(units)
        assignment['primary'] = canonical
    require(owned == {(repo, p) for repo, paths in subjects.items() for p in paths},
            'primary partition omits subject files')
    return normalized


def packets_fresh(pending):
    for entry in pending['packets']:
        packet = read(entry['path'])
        require(digest(packet) == entry['sha256'], 'review packet drift')
        # Old in-flight packets retain their original protocol, never rewritten.
        if 'brief_sha256' in packet:
            require(hashlib.sha256(Path(packet['brief']).read_bytes()).hexdigest() == packet['brief_sha256'],
                    'reviewer brief input drift')


def admit(state, args):
    require(args.reason in ('initial', 'repair', 'second'), 'invalid dispatch reason')
    fresh(state)
    require(state['pending'] is None and state['repair'] is None, 'unfinished dispatch or repair')
    require(not any(f['disposition'] is None for f in state['findings'])
            or (not state['primary_valid'] and state['attempts'] == 0 and state['history']),
            'verify raw findings before another dispatch')
    policy = state['policy']
    primary_limit = 1 + (policy['repair_limit'] if policy['route'] == 'full' else 0)
    if args.reason == 'second':
        require(state['second_attempts'] < int(policy['second_opinion']), 'second-opinion limit reached')
    else:
        require(state['attempts'] - state['second_attempts'] < primary_limit,
                'review limit reached; no dispatch; explicit new batch required')
    if args.reason == 'repair':
        require(policy['route'] == 'full' and state['primary_valid'] and state['repair_ready'],
                'repair follow-up requires full route, valid baseline and successful repair preflight')
    elif args.reason == 'second':
        require(policy['second_opinion'] and state['primary_valid'] and not state['second_done'],
                'no pending requested second opinion')
    else:
        require(not state['primary_valid'] or (state['history'] and state['attempts'] == 0),
                'initial discovery already completed')
    assignments = read(args.assignments)
    require(isinstance(assignments, list) and assignments, 'assignments must be a nonempty list')
    require(policy['route'] != 'ordinary' or len(assignments) == 1, 'ordinary uses exactly one reviewer')
    assignments = primary_assignments(state['scopes'], assignments)
    ticket = uuid.uuid4().hex
    mode = (policy['followup'] if args.reason == 'repair' else
            state.get('next_initial_mode', 'blind') if args.reason == 'initial' else 'blind')
    state['attempts'] += 1
    if args.reason == 'second':
        state['second_attempts'] += 1
    state['pending'] = {'ticket': ticket, 'assignments': assignments, 'scope': current(state),
                        'mode': mode, 'reason': args.reason, 'phase': 'reserved', 'packets': []}
    # Persist consumption before rendering or launching; renderer failure cannot refund.
    event(state, 'reserved', ticket=ticket, mode=mode)
    for assignment in assignments:
        brief = SCRIPTS.parent / 'references/portable-reviewer-brief.md'
        packet = {'brief': str(brief), 'brief_sha256': hashlib.sha256(brief.read_bytes()).hexdigest(),
                  'instruction': ('First read only the complete brief and this packet in a separate tool call; '
                                  'do not batch those initial reads with target inspection. Then independently '
                                  'review primary_scope and necessary '
                                  'semantic dependents; scope is the aggregate immutable context. Stay read-only. '
                                  'When working_tree_included is true, inspect staged, unstaged and untracked content '
                                  'against base, even when base equals head. Otherwise compare only the committed endpoints.'),
                  'scope': [{k: s[k] for k in ('repo', 'mode', 'base', 'head', 'paths', 'guidance',
                                              'subject_files', 'working_tree_included', 'fingerprint')} for s in state['scopes']],
                  'primary_scope': [{'repo': r, 'subject_files': paths} for r, paths in assignment['primary'].items()],
                  'concern': assignment['concern'], 'language': args.language}
        if mode == 'focused':
            packet['repair'] = state.get('repair_packet', {'original_findings': [f['raw'] for f in state['findings']]})
        path = Path(state['state']).parent / ('input-' + uuid.uuid4().hex + '.json')
        write(path, packet)
        state['pending']['packets'].append({'path': str(path), 'sha256': digest(packet), 'assignment': assignment['id']})
    save(state)
    return {'ticket': ticket, 'mode': mode, 'packets': [p['path'] for p in state['pending']['packets']]}


def dispatch(state, args):
    p = state['pending']
    require(p and p['ticket'] == args.ticket and p['phase'] == 'reserved', 'ticket is absent, spent or not reserved')
    require(current(state) == p['scope'], 'ticket scope drift')
    packets_fresh(p)
    p['phase'] = 'dispatched'
    state['reviewer_count'] += len(p['assignments'])
    event(state, 'dispatched', ticket=p['ticket'])
    turbo = turbo_module(optional=True)
    if turbo:
        context = turbo.live_context([s['repo'] for s in state['scopes']])
        if context and context['runtime'] == 'codex':
            p['native_required'] = True
            save(state)
        elif context and context['runtime'] == 'claude':
            p['native_claude'] = {key: context[key] for key in ('runtime', 'session', 'generation')}
            save(state)
        turbo.checkpoint_from_environment(state['state'], [s['repo'] for s in state['scopes']],
                                          p['ticket'], event='started')
    return {'ticket': p['ticket'], 'packets': [x['path'] for x in p['packets']]}


def finish(state, args):
    p = state['pending']
    require(p and p['ticket'] == args.ticket and p['phase'] == 'dispatched', 'no matching dispatched ticket')
    # Invalid/partial results close the attempt as BLOCKED and retain original evidence.
    try:
        require(current(state) == p['scope'], 'result scope drift')
        packets_fresh(p)
        reports = read(args.input)
        require(isinstance(reports, list), 'results must be a list')
        if p.get('native_required'):
            proof = p.get('native_proof', {})
            require(proof.get('input') == str(Path(args.input).resolve()) and
                    proof.get('input_sha256') == hashlib.sha256(Path(args.input).read_bytes()).hexdigest()
                    and proof.get('scope') == p['scope'],
                    'Turbo Codex requires native-review process evidence; author reports are not independent reviews')
            require(len(proof.get('processes', [])) == len(reports), 'native process set incomplete')
            for process, report in zip(proof['processes'], reports):
                require(process['exit'] == 0 and process['thread_id'] == report['reviewer'] and
                        process['assignment'] == report['assignment'] and process['report'] == report['report'] and
                        all(hashlib.sha256(Path(process[k]).read_bytes()).hexdigest() == process[k + '_sha256']
                            for k in ('trace', 'report')), 'native process/report evidence drift')
        expected = {a['id']: a for a in p['assignments']}
        require(len(reports) == len(expected) and {r['assignment'] for r in reports} == set(expected),
                'partial or duplicate result set')
        identities = [r['reviewer'] for r in reports]
        require(all(isinstance(x, str) and x.strip() for x in identities) and len(set(identities)) == len(identities),
                'missing or duplicated reviewer identity')
        require(not set(identities) & set(state['reviewers']), 'reviewer identity was already used')
        findings = []
        for r in reports:
            require(r['result'] == 'complete', 'review incomplete')
            raw = Path(r['report']).read_text()
            require(raw.strip(), 'empty original report')
            if p.get('native_claude'):
                turbo = turbo_module()
                native_path, original = turbo.native_report(p['native_claude'], state['state'],
                                                           p['ticket'], r['reviewer'])
                # Keep the submitted text explicitly separate; never call it the original.
                r['submitted_report'] = r['report']
                if raw != original:
                    r['author_summary'] = raw
                r['report'], raw = native_path, original
            require(isinstance(r['findings'], list), 'findings must be a list')
            ids = set()
            for f in r['findings']:
                require(f['severity'] in SEVERITIES and f['id'] not in ids, 'invalid severity or duplicate finding')
                require(all(isinstance(f.get(k), str) and f[k].strip() for k in
                            ('id', 'location', 'trigger', 'impact', 'evidence')), 'incomplete finding')
                ids.add(f['id'])
                affected = ([str(Path(f['repo']).resolve())] if f.get('repo') else expected[r['assignment']]['repos'])
                require(set(affected) <= set(expected[r['assignment']]['repos']), 'finding repository outside assignment')
                findings.append({'id': uuid.uuid4().hex, 'raw': f, 'reviewer': r['reviewer'],
                                 'assignment': r['assignment'], 'ticket': p['ticket'],
                                 'disposition': None, 'open': True, 'repairs': [], 'repos': affected})
            r['raw_report'] = raw
        state['sets'].append({**p, 'reports': reports})
        state['reviewers'].extend(identities)
        state['findings'].extend(findings)
        state['valid_sets'] += 1
        if p['reason'] == 'second':
            state['second_done'] = True
        else:
            state['primary_valid'] = True
            state.pop('next_initial_mode', None)
        state['pending'] = None
        state['repair_ready'] = False
        state['verdict'] = result_verdict(state)
        state['receipt'] = {'scope': p['scope'], 'ticket': p['ticket']}
        event(state, 'result', ticket=p['ticket'])
    except (Blocked, OSError, ValueError, KeyError, TypeError) as error:
        state.setdefault('failed_sets', []).append({**p, 'error': str(error)})
        state['pending'] = None
        state['verdict'] = 'BLOCKED'
        state.pop('receipt', None)
        event(state, 'invalid-result', ticket=p['ticket'], reason=str(error))
        turbo = turbo_module(optional=True)
        if turbo:
            turbo.checkpoint_from_environment(state['state'], [s['repo'] for s in state['scopes']],
                                              p['ticket'], event='failed')
        raise Blocked(str(error))
    turbo = turbo_module(optional=True)
    if turbo:
        turbo.checkpoint_from_environment(state['state'], [s['repo'] for s in state['scopes']], p['ticket'])
    return summary(state)


def assess(state, args):
    fresh(state)
    require(state['pending'] is None and state['repair'] is None, 'unfinished work')
    claims = read(args.input)
    pending = {f['id']: f for f in state['findings'] if f['disposition'] is None}
    require(isinstance(claims, list) and len(claims) == len(pending)
            and {d['id'] for d in claims} == set(pending), 'verify every new finding exactly once')
    prior = {f['id']: f for f in state['findings'] if f['disposition'] is not None}
    for d in claims:
        require(d['status'] in ('true-positive', 'false-positive', 'unresolved', 'resolved'), 'invalid disposition')
        require(d['status'] != 'resolved' or pending[d['id']].get('recheck'),
                'resolved requires a prior finding rechecked against an explicitly changed subject')
        require(isinstance(d.get('evidence'), str) and d['evidence'].strip(), 'missing independent verification evidence')
        require(d.get('relation') in RELATIONS, 'missing repair relation')
        if d['relation'] in ('unresolved-original', 'repair-introduced', 'repair-exposed'):
            require(d.get('parent') in prior, 'repair relation requires an earlier finding')
            require(isinstance(d.get('diagnosis'), str) and d['diagnosis'].strip(),
                    'recurrence requires diagnosis of repair method, invariant and dependents')
        f = pending[d['id']]
        f['disposition'] = d
        f['open'] = d['status'] == 'unresolved' or (d['status'] == 'true-positive' and f['raw']['severity'] != 'low')
    state['verdict'] = result_verdict(state)
    event(state, 'assessed', finding_ids=list(pending))
    return summary(state)


def repair_start(state, args):
    require(state['policy']['autofix'], 'autofix not selected; current ownership still requires independent verification')
    require(state['pending'] is None, 'review still pending')
    require(state['repairs'] < state['policy']['repair_limit'], 'repair limit reached')
    if state['policy']['route'] == 'full':
        require(state['attempts'] - state['second_attempts'] < 1 + state['policy']['repair_limit'],
                'no primary follow-up capacity; preserve the reserved second-opinion slot')
    editable = sorted({str(Path(p).resolve()) for p in args.editable_repo} if args.editable_repo
                      else {s['repo'] for s in state['scopes']})
    require(set(editable) <= {s['repo'] for s in state['scopes']}, 'editable repository outside confirmed scope')
    blockers = [f for f in state['findings'] if f['open'] and set(f['repos']) <= set(editable)]
    require(blockers and all(f['disposition'] and f['disposition']['status'] == 'true-positive' for f in blockers),
            'repair requires independently verified blocking findings')
    if state['repair'] is not None:
        # A failed preflight remains an attempt; a new attempt starts from its actual content.
        require(state['repair']['failed'], 'repair already active')
        state['scopes'] = persist_scopes([capture_after(s) if s['repo'] in state['repair']['editable'] else s
                                         for s in state['scopes']], Path(state['state']).parent)
    for s in state['scopes']:
        scope_check(s['manifest'], 'autofix-check' if s['repo'] in editable else 'verify')
    before = snapshot(state['scopes'])
    state['repairs'] += 1
    state['repair'] = {'id': uuid.uuid4().hex, 'before': before, 'findings': [f['id'] for f in blockers],
                       'checks': [], 'failed': False, 'editable': editable}
    state['repair_ready'] = False
    state['verdict'] = 'BLOCKED'
    state.pop('receipt', None)
    event(state, 'repair-started', repair=state['repair']['id'])
    return {'repair': state['repair']['id']}


def check(state, args):
    require(state['repair'] is not None, 'no active repair')
    require(not state['repair']['failed'], 'failed preflight consumes this repair attempt; start the next bounded repair before retrying')
    repo = str(Path(args.repo).resolve())
    require(repo in [s['repo'] for s in state['scopes']], 'check repository not in scope')
    command = read(args.input)
    require(isinstance(command, list) and command and all(isinstance(x, str) and x for x in command),
            'check input must be an argv array; no implicit shell')
    before = snapshot(state['scopes'])
    check_id = uuid.uuid4().hex
    # Retain an interrupted command as incomplete evidence rather than a passing check.
    entry = {'id': check_id, 'repo': repo, 'command': command, 'snapshot': digest(before), 'exit': None}
    state['checks'].append(entry)
    state['repair']['checks'].append(check_id)
    event(state, 'check-started', check=check_id)
    r = run(command, cwd=repo)
    entry.update(exit=r.returncode, stdout=r.stdout.decode(errors='replace'), stderr=r.stderr.decode(errors='replace'))
    entry['stable'] = snapshot(state['scopes']) == before
    if r.returncode or not entry['stable']:
        state['repair']['failed'] = True
    event(state, 'checked', check=check_id)
    return {'check': check_id, 'exit': r.returncode, 'stable': entry['stable'],
            'stdout': entry['stdout'], 'stderr': entry['stderr']}


def repair_finish(state, args):
    repair = state['repair']
    require(repair is not None, 'no active repair')
    require(not repair['failed'], 'this repair failed preflight; no review dispatch')
    proof = read(args.input)
    after = snapshot(state['scopes'])
    require(set(after) == set(repair['before']), 'repair repository set changed')
    claims = proof['findings']
    require(len(claims) == len(repair['findings']) and {x['id'] for x in claims} == set(repair['findings']),
            'original finding verification is incomplete')
    for claim in claims:
        require(claim['outcome'] in ('addressed', 'unresolved'), 'invalid repair outcome')
        require(all(isinstance(claim.get(k), str) and claim[k].strip() for k in
                    ('trigger', 'same_class', 'invariant', 'dependents')), 'missing repair completeness evidence')
    checks = [x for x in state['checks'] if x['id'] in repair['checks']]
    selected = proof.get('checks', [])
    require(set(selected) <= {x['id'] for x in checks}, 'check belongs to another repair')
    latest = {}
    for c in checks:
        latest[(c['repo'], tuple(c['command']))] = c
    require(all(c['exit'] == 0 and c.get('stable') and c['snapshot'] == digest(after) for c in latest.values()),
            'known check failed, incomplete or stale; do not dispatch another reviewer')
    require(set(selected) == {c['id'] for c in latest.values()}, 'include every latest relevant check')
    require(selected or (isinstance(proof.get('static_evidence'), str) and proof['static_evidence'].strip()),
            'no executed check or explicit static verification boundary')
    delta = actual_delta(repair['before'], after)
    require(delta, 'repair has no actual content delta')
    for d in delta:
        require(d['repo'] in repair['editable'], 'repair changed a read-only peer')
        scope = next(s for s in state['scopes'] if s['repo'] == d['repo'])
        paths = scope['paths']
        require(not paths or any(p == '.' or d['path'] == p or d['path'].startswith(p.rstrip('/') + '/') for p in paths),
                'repair changed a path outside the confirmed scope')
    require(all(x['outcome'] == 'addressed' for x in claims), 'original finding remains unresolved')
    scopes = [capture_after(s) if s['repo'] in repair['editable'] else s for s in state['scopes']]
    # Changed head/branch is not a normal code repair transition.
    require(all(repair['before'][r]['head'] == after[r]['head'] for r in after), 'HEAD changed during repair')
    state['scopes'] = persist_scopes(scopes, Path(state['state']).parent)
    state['edited'] = sorted(set(state['edited']) | {x['repo'] for x in delta})
    repaired = [f for f in state['findings'] if f['id'] in repair['findings']]
    for f in repaired:
        f['open'] = False
        f['repairs'].append({'repair': repair['id'], 'proof': next(c for c in claims if c['id'] == f['id'])})
    # Allowlist only: no counters, policy, desired result or author disposition.
    finding_fields = ('id', 'severity', 'repo', 'location', 'trigger', 'impact', 'evidence',
                      'verification_basis', 'same_class', 'repair_direction')
    state['repair_packet'] = {'original_findings': [{k: f['raw'][k] for k in finding_fields if k in f['raw']}
                                                  for f in repaired], 'actual_delta': delta,
                              'verification': [{k: c[k] for k in ('trigger', 'same_class', 'invariant', 'dependents')}
                                               for c in claims], 'checks': [
                                  {k: c[k] for k in ('repo', 'command', 'exit', 'stdout', 'stderr')}
                                  for c in latest.values()]}
    state['repair'] = None
    state['repair_ready'] = True
    state['second_done'] = False  # An opinion about pre-repair bytes is not a repaired-subject receipt.
    state['verdict'] = result_verdict(state) if state['policy']['route'] == 'ordinary' else 'BLOCKED'
    if state['policy']['route'] == 'ordinary':
        state['receipt'] = {'scope': current(state), 'author_verification': repair['id']}
    event(state, 'repair-verified', repair=repair['id'], proof=proof, delta=delta)
    return summary(state)


def terminal(state, args):
    repo = str(Path(args.repo).resolve())
    if args.action == 'terminal-record' and state['repair'] is not None:
        require(repo in state['repair']['editable'], 'terminal target is a read-only peer')
        delta = actual_delta(state['repair']['before'], snapshot(state['scopes']))
        state['edited'] = sorted(set(state['edited']) | {d['repo'] for d in delta if d['repo'] in state['repair']['editable']})
    require(state['policy']['autofix'] and repo in state['edited'], 'terminal mutation requires an actually edited owned autofix target')
    s = next(s for s in state['scopes'] if s['repo'] == repo)
    anchor = Path(git(repo, 'rev-parse', '--absolute-git-dir').decode().strip()) / 'deep-review/anchor'
    original = anchor.read_text() if anchor.exists() else ''
    fields = dict(x.split('=', 1) for x in original.splitlines() if x.startswith('terminal_') and '=' in x)
    retained = [x for x in original.splitlines() if not x.startswith('terminal_')]
    if args.action == 'terminal-record':
        require(args.reason in ('blocking-findings', 'blocked-review'), 'invalid terminal reason')
        origin = next(o for o in state['origin'] if o['repo'] == repo)
        coverage = {'base': origin['base'], 'paths': origin['paths'], 'repo': repo,
                    'state': state['state'], 'batch': state['batch']}
        retained += ['terminal_reason=' + args.reason, 'terminal_head=' + git(repo, 'rev-parse', 'HEAD').decode().strip(),
                     'terminal_at=' + str(int(time.time())), 'terminal_scope=' + json.dumps(coverage, sort_keys=True)]
        anchor.parent.mkdir(parents=True, exist_ok=True)
    else:
        require(state['verdict'] == 'PASS' and state.get('receipt', {}).get('scope') == current(state),
                'no valid PASS receipt for current content')
        if not fields:
            return {'terminal': 'NONE'}
        require('terminal_scope' in fields, 'legacy signal lacks scope evidence; preserve it for explicit disposition')
        old = json.loads(fields['terminal_scope'])
        require(old['repo'] == repo and (s['paths'] == old['paths'] or not s['paths']), 'PASS omits terminal paths')
        require(s['mode'] != 'range', 'terminal clear requires current working content verification')
        for base, head in [(s['base'], old['base']), (old['base'], fields['terminal_head']),
                           (fields['terminal_head'], s['head'])]:
            require(run(['git', '-C', repo, 'merge-base', '--is-ancestor', base, head]).returncode == 0,
                    'PASS endpoints do not cover terminal scope')
    tmp = anchor.with_name('anchor.' + uuid.uuid4().hex)
    if retained:
        tmp.write_text('\n'.join(retained) + '\n')
        os.replace(tmp, anchor)
    elif anchor.exists():
        anchor.unlink()
    event(state, args.action, repo=repo)
    return {'terminal': 'RECORDED' if args.action == 'terminal-record' else 'CLEARED'}


def terminal_evidence(repo):
    repo = str(Path(repo).resolve())
    anchor = Path(git(repo, 'rev-parse', '--absolute-git-dir').decode().strip()) / 'deep-review/anchor'
    original = anchor.read_text() if anchor.exists() else ''
    lines = [x for x in original.splitlines() if x.startswith('terminal_') and '=' in x]
    fields = dict(x.split('=', 1) for x in lines)
    require(len(lines) == len(fields), 'duplicate terminal fields; preserve signal')
    signal = digest([x for x in lines if not x.startswith('terminal_disposition=')])
    return repo, anchor, original, fields, signal


def disposition_receipt(repo, anchor, fields, signal):
    identity = fields['terminal_disposition']
    require(len(identity) == 32 and all(c in '0123456789abcdef' for c in identity),
            'invalid disposition identity; preserve signal')
    receipt = read(anchor.parent / 'dispositions' / (identity + '.json'))
    authorization = receipt['authorization']
    require(receipt['schema'] == 1 and receipt['id'] == identity and receipt['repo'] == repo
            and receipt['signal'] == signal and receipt['shipping_authorized'] is False,
            'disposition does not match this original signal')
    old_lines = [x for x in receipt['original'].splitlines()
                 if x.startswith('terminal_') and '=' in x and not x.startswith('terminal_disposition=')]
    require(digest(old_lines) == signal and 'terminal_scope' not in fields,
            'disposition is not for this legacy signal')
    require(authorization['action'] == 'close-legacy-review-terminal'
            and authorization['repo'] == repo and authorization['signal'] == signal
            and authorization['head'] == receipt['head']
            and authorization['scope'] == receipt['review']['receipt']['scope']
            and authorization['endpoint'] == receipt['endpoint']
            and receipt['endpoint'] in ('branch', 'pr', 'merge', 'disposition-only')
            and isinstance(authorization['user_instruction'], str) and authorization['user_instruction'].strip(),
            'missing exact legacy disposition provenance')
    scopes = receipt['review']['scopes']
    require(digest(scopes) == authorization['scope'], 'disposition review identity mismatch')
    subject = next(s for s in scopes if s['repo'] == repo)
    require(not subject['paths'] and subject['mode'] != 'range' and subject['head'] == receipt['head'],
            'disposition requires the complete current subject')
    for base, head in [(fields['terminal_head'], receipt['head']), (receipt['head'], 'HEAD')]:
        require(run(['git', '-C', repo, 'merge-base', '--is-ancestor', base, head]).returncode == 0,
                'disposition endpoints do not cover this signal and lineage')
    return receipt


def terminal_status(repo):
    repo, anchor, original, fields, signal = terminal_evidence(repo)
    result = {'terminal': 'ACTIVE' if fields.get('terminal_reason') else 'NONE',
              'repo': repo, 'signal': signal, 'head': git(repo, 'rev-parse', 'HEAD').decode().strip(),
              'kind': 'scoped' if 'terminal_scope' in fields else 'legacy',
              'shipping_authorized': False}
    if 'terminal_disposition' in fields:
        receipt = disposition_receipt(repo, anchor, fields, signal)
        result.update(terminal='DISPOSED', receipt=str(anchor.parent / 'dispositions' / (receipt['id'] + '.json')))
    return result


def terminal_dispose(state, args):
    repo, anchor, original, fields, signal = terminal_evidence(args.repo)
    require(fields.get('terminal_reason') and fields.get('terminal_head') and fields.get('terminal_at'),
            'legacy signal lacks its original identity; preserve it')
    require('terminal_scope' not in fields, 'scoped signals require compatible terminal-clear, not legacy disposition')
    require('terminal_disposition' not in fields, 'signal already has a disposition; do not replay approval')
    require(state['pending'] is None and state['repair'] is None and state['verdict'] == 'PASS',
            'legacy disposition requires completed PASS verification')
    scope = current(state)
    require(state.get('receipt', {}).get('scope') == scope, 'no valid PASS receipt for current content')
    subject = next(s for s in state['scopes'] if s['repo'] == repo)
    require(not subject['paths'] and subject['mode'] != 'range',
            'unknown legacy coverage requires a complete current subject, not partial or historical review')
    head = git(repo, 'rev-parse', 'HEAD').decode().strip()
    require(run(['git', '-C', repo, 'merge-base', '--is-ancestor', fields['terminal_head'], head]).returncode == 0,
            'legacy signal is not in the current endpoint lineage')
    instruction = read(args.input)
    require(instruction['action'] == 'close-legacy-review-terminal'
            and instruction['repo'] == repo and instruction['signal'] == signal
            and instruction['head'] == head and instruction['scope'] == scope,
            'current instruction must name the exact repo, legacy signal, HEAD and review scope')
    require(instruction['endpoint'] in ('branch', 'pr', 'merge', 'disposition-only')
            and isinstance(instruction['user_instruction'], str) and instruction['user_instruction'].strip(),
            'explicit current legacy disposition instruction and bounded endpoint required')
    identity = uuid.uuid4().hex
    receipt = {'schema': 1, 'id': identity, 'repo': repo, 'signal': signal, 'original': original,
               'head': head, 'endpoint': instruction['endpoint'], 'authorization': instruction,
               'shipping_authorized': False, 'at': time.time(),
               'review': {'state': state['state'], 'batch': state['batch'], 'receipt': state['receipt'],
                          'scopes': scope_identity(state['scopes']),
                          'attempts': state['attempts'], 'repairs': state['repairs']}}
    directory = anchor.parent / 'dispositions'
    directory.mkdir(exist_ok=True)
    path = directory / (identity + '.json')
    require(not path.exists(), 'disposition history cannot be overwritten')
    write(path, receipt)  # Archive before publishing; interrupted archival cannot silence a signal.
    require(anchor.read_text() == original and current(state) == scope, 'signal or reviewed content changed during disposition')
    tmp = anchor.with_name('anchor.' + uuid.uuid4().hex)
    tmp.write_text(original + ('' if original.endswith('\n') else '\n') + 'terminal_disposition=' + identity + '\n')
    os.replace(tmp, anchor)
    event(state, 'terminal-dispose', repo=repo, signal=signal, receipt=str(path), endpoint=instruction['endpoint'])
    return {'terminal': 'DISPOSED', 'receipt': str(path), 'shipping_authorized': False}


def new_batch(state, args, delegated=False):
    before_subject = scope_identity(state['scopes'])
    authorization = Path(args.authorization).read_text().strip() if args.authorization else ''
    if not delegated:
        require(authorization, 'explicit current user instruction required; a helper flag is not authorization')
    require(state['pending'] is None, 'cannot abandon an active dispatch')
    failed_repair = state['repair']
    if failed_repair is not None:
        require(failed_repair['failed'] and state['repairs'] >= state['policy']['repair_limit'],
                'finish the active repair or its bounded failure first')
        state['scopes'] = persist_scopes([capture_after(s) if s['repo'] in failed_repair['editable'] else s
                                         for s in state['scopes']], Path(state['state']).parent)
        state['repair'] = None
    if args.manifest:
        scopes = sorted([load_scope(p) for p in args.manifest], key=lambda s: s['repo'])
        require([s['repo'] for s in scopes] == [s['repo'] for s in state['scopes']],
                'new scope must retain every confirmed repository')
        outside(storage(), scopes)
        if scope_identity(scopes) != scope_identity(state['scopes']):
            state['scopes'] = persist_scopes(scopes, Path(state['state']).parent)
            for f in state['findings']:
                if f['open']:
                    f.setdefault('disposition_history', []).append(f['disposition'])
                    f['disposition'] = None
                    f['recheck'] = True
            state['primary_valid'] = False
            state['second_done'] = False
            state['repair_ready'] = False
            state.pop('receipt', None)
    fresh(state)
    authority = None
    if delegated:
        require(args.input and args.expected_state_sha, 'delegated request and state binding required')
        require(hashlib.sha256(Path(state['state']).read_bytes()).hexdigest() == args.expected_state_sha,
                'stale delegated review state')
        primary_limit = 1 + (state['policy']['repair_limit'] if state['policy']['route'] == 'full' else 0)
        require((state['policy']['autofix'] and state['policy']['repair_limit'] > 0 and
                 state['repairs'] >= state['policy']['repair_limit']) or
                state['attempts'] - state['second_attempts'] >= primary_limit,
                'original review budget remains; use its existing transitions')
        authority = turbo_module().consume_request(args.input, state['state'], 'deep-review',
                                                  [s['repo'] for s in state['scopes']], args.expected_state_sha)
        authorization = authority['instruction']
        if scope_identity(state['scopes']) != before_subject:
            invalidate_open_dispositions(state)
            state['primary_valid'] = state['second_done'] = state['repair_ready'] = False
            state.pop('receipt', None)
    state['history'].append({'batch': state['batch'], 'attempts': state['attempts'], 'repairs': state['repairs'],
                             'verdict': state['verdict'], 'authorization': authorization,
                             'delegation': authority, 'policy': dict(state['policy']), 'failed_repair': failed_repair})
    if authority:
        state['policy']['followup'] = authority['mode']
        state['next_initial_mode'] = authority['mode']
    state['batch'] = uuid.uuid4().hex
    state['attempts'] = state['repairs'] = state['second_attempts'] = 0
    state['verdict'] = 'BLOCKED'
    event(state, 'new-batch')
    return summary(state)


def invalidate_open_dispositions(state):
    for finding in state['findings']:
        if finding['open']:
            if finding['disposition'] is not None:
                finding.setdefault('disposition_history', []).append(finding['disposition'])
            finding['disposition'] = None
            finding['recheck'] = True


def refresh_subject(state, args):
    require(state['pending'] is None and state['repair'] is None, 'finish pending dispatch/repair first')
    require(args.input and args.expected_state_sha and
            hashlib.sha256(Path(state['state']).read_bytes()).hexdigest() == args.expected_state_sha,
            'current single-use subject refresh binding required')
    require(all(s['mode'] != 'range' for s in state['scopes']), 'immutable range cannot be refreshed')
    primary_limit = 1 + (state['policy']['repair_limit'] if state['policy']['route'] == 'full' else 0)
    require(state['attempts'] - state['second_attempts'] < primary_limit,
            'review capacity exhausted; use legal delegated-reentry with current manifests instead')
    before = state['scopes']
    after = [capture_after(s) for s in before]
    require(scope_identity(after) != scope_identity(before), 'current subject has no changed content')
    authority = turbo_module().consume_request(args.input, state['state'], 'deep-review',
                                               [s['repo'] for s in before], args.expected_state_sha,
                                               transition='refresh-subject')
    state['scopes'] = persist_scopes(after, Path(state['state']).parent)
    state['primary_valid'] = state['second_done'] = state['repair_ready'] = False
    state['verdict'] = 'BLOCKED'
    state.pop('receipt', None)
    state['next_initial_mode'] = authority['mode']
    invalidate_open_dispositions(state)
    event(state, 'subject-refreshed', before=scope_identity(before), after=scope_identity(after), delegation=authority)
    return summary(state)


def native_review(state, args):
    spec = importlib.util.spec_from_file_location('native_review_transport', SCRIPTS / 'native-review.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.launch(sys.modules[__name__], state, args)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['open', 'status', 'admit', 'dispatch', 'finish', 'assess',
                                         'repair-start', 'check', 'repair-finish', 'new-batch',
                                         'terminal-record', 'terminal-clear', 'terminal-status', 'terminal-dispose',
                                         'delegated-reentry', 'refresh-subject', 'native-review'])
    parser.add_argument('--state')
    parser.add_argument('--manifest', action='append')
    parser.add_argument('--route', choices=['ordinary', 'full'], default='ordinary')
    parser.add_argument('--autofix', action='store_true')
    parser.add_argument('--followup', choices=['blind', 'focused'], default='blind')
    parser.add_argument('--repair-limit', type=int, default=3)
    parser.add_argument('--second-opinion', action='store_true')
    parser.add_argument('--assignments')
    parser.add_argument('--ticket')
    parser.add_argument('--input')
    parser.add_argument('--repo')
    parser.add_argument('--editable-repo', action='append')
    parser.add_argument('--reason', default='initial')
    parser.add_argument('--language', default='user requested language')
    parser.add_argument('--authorization')
    parser.add_argument('--expected-state-sha')
    parser.add_argument('--review-model')
    args = parser.parse_args()
    try:
        if args.action == 'terminal-status':
            require(args.repo, '--repo required')
            print(json.dumps(terminal_status(args.repo), ensure_ascii=False))
            return 0  # Read-only inspection never creates a journal, lock or target metadata.
        root = storage()
        if args.action == 'open':
            # Refuse a fixture/cache override inside the target before creating even a lock.
            require(args.manifest, 'missing manifests')
            outside(root, [load_scope(p) for p in args.manifest])
        with locked(root):
            if args.action == 'open':
                result = open_batch(args, root)
            else:
                require(args.state, '--state required')
                path = Path(args.state).resolve()
                require(root in path.parents, 'state belongs to another evidence directory; do not relocate a live batch')
                state = read(path)
                require(state['schema'] == 1 and state['state'] == str(path), 'invalid journal identity')
                outside(root, state['scopes'])
                if args.action == 'status':
                    result = summary(state)
                elif args.action == 'repair-start':
                    result = repair_start(state, args)
                elif args.action == 'terminal-dispose':
                    require(args.repo and args.input, '--repo and --input required')
                    result = terminal_dispose(state, args)
                elif args.action == 'delegated-reentry':
                    result = new_batch(state, args, delegated=True)
                elif args.action == 'refresh-subject':
                    result = refresh_subject(state, args)
                elif args.action == 'native-review':
                    result = native_review(state, args)
                elif args.action.startswith('terminal-'):
                    result = terminal(state, args)
                else:
                    result = {'admit': admit, 'dispatch': dispatch, 'finish': finish, 'assess': assess,
                              'check': check, 'repair-finish': repair_finish, 'new-batch': new_batch}[args.action](state, args)
            print(json.dumps(result, ensure_ascii=False))
            return 1 if args.action == 'check' and (result['exit'] or not result['stable']) else 0
    except (Blocked, OSError, ValueError, KeyError, TypeError, StopIteration) as error:
        print(json.dumps({'verdict': 'BLOCKED', 'reason': str(error)}, ensure_ascii=False))
        return 1


if __name__ == '__main__':
    sys.exit(main())
