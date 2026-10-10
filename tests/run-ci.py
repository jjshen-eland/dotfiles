#!/usr/bin/env python3
"""Select declared test modules for a proven PR scope, otherwise run the full suite.

Uses the pull_request event's immutable endpoints and the actual checkout.
No network calls, persistent cache, path-only workflow filtering, or empty success.
"""
import argparse
import json
import os
import platform
from pathlib import Path
import re
import subprocess
import sys

from suite import load_manifest, select_paths, expand_aliases, regular_file_change, execute as run_modules


RECORD = re.compile(r'(?:STATUS\.md|docs/backlog\.md|'
                    r'docs/archive/(?:decisions|dead-ends|milestones)-\d{4}-\d{2}\.md|'
                    r'docs/plans/\d{4}-\d{2}-\d{2}-[^/]+\.md)\Z')
OID = re.compile(r'(?:[0-9a-f]{40}|[0-9a-f]{64})\Z')


def git(root, *args):
    return subprocess.check_output(['git', '--no-replace-objects', '-C', str(root), *args],
                                   stderr=subprocess.PIPE)


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
            mode = regular_file_change(fields)
            if mode is None:
                return fallback('mode, symlink or other non-regular change: ' + name)
            if RECORD.fullmatch(name) and mode != '100644':
                return fallback('executable record: ' + name)
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
        paths = expand_aliases(root, plan['changed_paths'])
        manifest = load_manifest(root)
        names, reason = select_paths(manifest, sorted(paths))
        if set(names) == set(manifest['modules']):
            return fallback(reason)
        return dict(plan, mode='records' if names == ['content'] else 'modules', reason=reason,
                    checks=names, base=base, head=head)
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, subprocess.CalledProcessError) as error:
        return fallback('scope unavailable; full suite: ' + str(error))


def execute(root, plan):
    manifest = load_manifest(root)
    names = list(manifest['modules']) if plan['mode'] == 'full' else plan['checks']
    # Local runs ignore ci_platforms; the other matrix job still runs what is skipped here.
    system = platform.system()
    skipped = [n for n in names if system not in manifest['modules'][n].get('ci_platforms', [system])]
    print('CI_PLATFORM ' + json.dumps({'system': system, 'skipped': skipped}), flush=True)
    return run_modules(root, manifest, [n for n in names if n not in skipped])


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
    except (OSError, ValueError, KeyError, TypeError) as error:
        print('CI_EXECUTION_ERROR: ' + str(error), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
