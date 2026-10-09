#!/usr/bin/env python3
"""Run record checks for a proven narrow PR; otherwise run the complete suite.

Uses the pull_request event's immutable endpoints and the actual checkout.
No network calls, persistent cache, path-only workflow filtering, or empty success.
"""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys


RECORD = re.compile(r'(?:STATUS\.md|docs/backlog\.md|'
                    r'docs/archive/(?:decisions|dead-ends|milestones)-\d{4}-\d{2}\.md|'
                    r'docs/plans/\d{4}-\d{2}-\d{2}-[^/]+\.md)\Z')
OID = re.compile(r'(?:[0-9a-f]{40}|[0-9a-f]{64})\Z')
CHECKS = ('kernel', 'xref', 'document-corpus')


def git(root, *args):
    return subprocess.check_output(['git', '--no-replace-objects', '-C', str(root), *args],
                                   stderr=subprocess.PIPE)


def headings(blob):
    lines = blob.decode('utf-8').splitlines()
    result = []
    for i, line in enumerate(lines):
        if re.match(r'^ {0,3}#{1,6}(?:\s|$)', line):
            result.append(line)
        elif i and re.fullmatch(r' {0,3}(?:=+|-+)\s*', line):
            result.append((lines[i - 1], line))
    return result


def select(root, environment):
    plan = {'mode': 'full', 'reason': 'unproven PR scope', 'changed_paths': [],
            'checks': ['complete-suite']}

    def fallback(reason):
        return dict(plan, reason=reason)

    try:
        if environment.get('GITHUB_EVENT_NAME') != 'pull_request':
            return fallback('no pull_request event; full suite')
        event = json.loads(Path(environment['GITHUB_EVENT_PATH']).read_text())['pull_request']
        base, head = event['base']['sha'], event['head']['sha']
        if not all(isinstance(s, str) and OID.fullmatch(s) for s in (base, head)):
            return fallback('event endpoints are not immutable commit IDs')
        checkout = git(root, 'rev-parse', 'HEAD').decode().strip()
        if checkout != environment.get('GITHUB_SHA'):
            return fallback('checkout does not match event GITHUB_SHA')
        parents = git(root, 'show', '-s', '--format=%P', 'HEAD').decode().split()
        if checkout != head and parents != [base, head]:
            return fallback('checkout is neither PR head nor its exact synthetic merge')
        if git(root, 'status', '--porcelain=v1', '--untracked-files=all'):
            return fallback('checkout has local changes')
        ancestor = git(root, 'merge-base', base, head).decode().strip()
        raw = git(root, 'diff', '--raw', '--no-abbrev', '--no-renames', '-z', ancestor, head)
        entries = raw.split(b'\0')
        if not raw or entries[-1] or len(entries[:-1]) % 2:
            return fallback('empty or malformed PR diff')
        entries = entries[:-1]
        for meta, path in zip(entries[::2], entries[1::2]):
            fields = meta.decode().split()
            name = path.decode('utf-8')
            plan['changed_paths'].append(name)
            if (len(fields) != 5 or fields[0] != ':100644' or fields[1] != '100644'
                    or fields[4] != 'M' or not RECORD.fullmatch(name)):
                return fallback('non-record, new/deleted/renamed file, or mode change: ' + name)
            if headings(git(root, 'show', ancestor + ':' + name)) != headings(git(root, 'show', head + ':' + name)):
                return fallback('document headings changed: ' + name)
        if checkout != head:
            # The tested merge tree must not contain additional changes or a
            # conflict resolution outside the proven record patch.
            merged = git(root, 'diff', '--name-only', '--no-renames', '-z', base, checkout)
            names = {os.fsdecode(p) for p in merged.split(b'\0') if p}
            if names != set(plan['changed_paths']):
                return fallback('synthetic merge changes differ from PR record scope')
            for name in names:
                if git(root, 'ls-tree', checkout, '--', name).split(b'\t')[0] != git(root, 'ls-tree', head, '--', name).split(b'\t')[0]:
                    return fallback('synthetic merge record differs from PR head: ' + name)
        # A record used through another tracked path may be an executable input.
        changed = [(root / name).resolve(strict=True) for name in plan['changed_paths']]
        for entry in git(root, 'ls-files', '-s', '-z').split(b'\0'):
            if entry.startswith(b'120000 '):
                link = root / os.fsdecode(entry.split(b'\t', 1)[1])
                target = link.resolve(strict=True)
                if any(p == target or target in p.parents for p in changed):
                    return fallback('tracked symlink aliases a changed record: ' + str(link.relative_to(root)))
        return dict(plan, mode='records', reason='only existing regular records; headings unchanged',
                    checks=list(CHECKS), omitted=['complete-suite'], base=base, head=head)
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, subprocess.CalledProcessError) as error:
        return fallback('scope unavailable; full suite: ' + str(error))


def run_check(command, root):
    """Capture one check and own its descendants, including on cancellation."""
    interrupted = 0

    def interrupt(signum, _frame):
        nonlocal interrupted
        interrupted = 128 + signum

    previous = {s: signal.signal(s, interrupt) for s in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)}
    process = None
    try:
        process = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, stdin=subprocess.DEVNULL, start_new_session=True)
        while not interrupted:
            try:
                stdout, stderr = process.communicate(timeout=.1)
                return interrupted or process.returncode, stdout, stderr
            except subprocess.TimeoutExpired:
                pass
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            stdout, stderr = process.communicate(timeout=.2)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            stdout, stderr = process.communicate()
        return interrupted, stdout, stderr
    finally:
        if process is not None:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
        for signum, handler in previous.items():
            signal.signal(signum, handler)


def execute(root, plan):
    if plan['mode'] == 'full':
        # Preserve the complete runner's existing signal/process-group ownership.
        os.chdir(root)
        os.execvp('bash', ['bash', str(root / 'tests/run-parallel.sh')])
    commands = [
        ('kernel', [sys.executable, '-B', str(root / 'tests/kernel-gate.py'), '--root', str(root)]),
        ('xref', [sys.executable, '-B', str(root / 'tests/xref-gate.py'), '--root', str(root)]),
        ('document-corpus', [sys.executable, '-B', str(root / 'tests/test_doc_governance.py'),
                             'RealRetrievalCorpusTests']),
    ]
    failed = False
    for name, command in commands:
        code, stdout, stderr = run_check(command, root)
        print(stdout, end='')
        print(stderr, end='', file=sys.stderr)
        # Both scanners report findings on stdout with exit 0.
        passed = code == 0 and (name not in ('kernel', 'xref') or not stdout.strip())
        print('CI_CHECK ' + json.dumps({'name': name, 'exit': code, 'passed': passed}), flush=True)
        failed |= not passed
        if code >= 128 or code < 0:
            return code if code > 0 else 128 - code
    return int(failed)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--select-only', action='store_true')
    args = parser.parse_args()
    root = args.root.resolve()
    plan = select(root, os.environ)
    print('CI_SELECTION ' + json.dumps(plan, ensure_ascii=False, sort_keys=True), flush=True)
    if args.select_only:
        return 0
    try:
        return execute(root, plan)
    except OSError as error:
        print('CI_EXECUTION_ERROR: ' + str(error), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
