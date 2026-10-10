#!/usr/bin/env python3
"""One module catalog and executor for local validation and CI.

Default: complete suite. --base REF: committed + working changes since merge-base.
--module NAME: focused development check (not a complete impact analysis).
"""
import argparse
from collections import deque
import fnmatch
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time


CI_SYSTEMS = ['Linux', 'Darwin']  # platform.system() of the CI matrix runners


def load_manifest(root):
    manifest = json.loads((root / 'tests/suites.json').read_text())
    modules = manifest['modules']
    if not isinstance(modules, dict) or not modules:
        raise ValueError('empty module catalog')
    shell = set()
    for name, entry in modules.items():
        if not re.fullmatch(r'[a-z][a-z0-9-]*', name):
            raise ValueError('invalid module name')
        command = entry.get('command')
        if not isinstance(command, list) or not command or not all(isinstance(x, str) for x in command):
            raise ValueError('invalid command: ' + name)
        if entry.get('shell'):
            if command != ['bash', 'tests/module-shell.sh', name]:
                raise ValueError('invalid shell entry: ' + name)
            shell.add(name)
        platforms = entry.get('ci_platforms', CI_SYSTEMS)
        if (not isinstance(platforms, list) or not platforms or len(platforms) != len(set(platforms))
                or not set(platforms) <= set(CI_SYSTEMS)):
            raise ValueError('invalid ci_platforms: ' + name)
    actual = {p.stem for p in (root / 'tests/modules').glob('*.sh')}
    if shell != actual:
        raise ValueError('shell module registration mismatch: ' + str(shell ^ actual))
    for route in manifest['routes']:
        if not route['paths'] or not route['modules'] or not set(route['modules']) <= modules.keys():
            raise ValueError('invalid impact route')
    return manifest


def select_paths(manifest, paths):
    all_names = list(manifest['modules'])
    selected = set(manifest.get('always', []))
    if not paths:
        return all_names, 'empty or unavailable change set'
    for path in paths:
        matches = [r for r in manifest['routes'] if any(fnmatch.fnmatchcase(path, p) for p in r['paths'])]
        owners = [name for name, entry in manifest['modules'].items()
                  if entry.get('shell') and path == 'tests/modules/' + name + '.sh']
        if not matches and not owners:
            return all_names, 'unmapped input: ' + path
        selected.update(owners)
        for route in matches:
            selected.update(route['modules'])
    if not selected or not selected <= manifest['modules'].keys():
        raise ValueError('invalid selected module set')
    if any(not path.endswith('.md') for path in paths):
        selected.update(('lint', 'shell-contract'))
    return [name for name in all_names if name in selected], 'declared input dependencies'


REGULAR_MODES = ('100644', '100755')


def regular_file_change(fields):
    """Mode of an added, deleted or content-modified regular file in `git diff --raw`; None otherwise."""
    if len(fields) != 5:
        return None
    src, dst, status = fields[0].removeprefix(':'), fields[1], fields[4]
    if status == 'M' and src == dst and src in REGULAR_MODES:
        return dst
    if status == 'A' and src == '000000' and dst in REGULAR_MODES:
        return dst
    if status == 'D' and dst == '000000' and src in REGULAR_MODES:
        return src
    return None


def expand_aliases(root, paths):
    expanded = set(paths)
    # A deleted path no longer exists; a link still aimed at it fails strict resolution below.
    changed = [(root / path).resolve(strict=(root / path).exists()) for path in paths]
    entries = subprocess.check_output(['git', '-C', str(root), 'ls-files', '-s', '-z'])
    for entry in entries.split(b'\0'):
        if entry.startswith(b'120000 '):
            link = root / os.fsdecode(entry.split(b'\t', 1)[1])
            target = link.resolve(strict=True)
            for path in changed:
                if path == target or target in path.parents:
                    alias = link if path == target else link / path.relative_to(target)
                    expanded.add(str(alias.relative_to(root)))
    return sorted(expanded)


def local_paths(root, base):
    def git(*args):
        return subprocess.check_output(['git', '--no-replace-objects', '-C', str(root), *args], stderr=subprocess.PIPE)
    ancestor = git('merge-base', base, 'HEAD').decode().strip()
    if git('ls-files', '-u') or git('ls-files', '--others', '--exclude-standard', '-z'):
        raise ValueError('unmerged or untracked input; run the complete suite')
    # Includes all commits, staged and unstaged changes. Mode/topology changes need full validation.
    raw = git('diff', '--raw', '--no-abbrev', '--no-renames', '-z', ancestor).split(b'\0')
    paths = []
    for meta, path in zip(raw[:-1:2], raw[1:-1:2]):
        if regular_file_change(meta.decode().split()) is None:
            raise ValueError('mode/topology change')
        paths.append(os.fsdecode(path))
    return expand_aliases(root, paths)


def kill_group(process, sig):
    try:
        os.killpg(process.pid, sig)
    except ProcessLookupError:
        pass


def execute(root, manifest, names, jobs=4, verbose=False):
    if not names or len(names) != len(set(names)) or not set(names) <= manifest['modules'].keys():
        raise ValueError('empty, duplicate or unknown module selection')
    interrupted = 0
    def interrupt(signum, _frame):
        nonlocal interrupted
        interrupted = 128 + signum
    previous = {s: signal.signal(s, interrupt) for s in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP)}
    running = {}
    owned = []
    completed = []
    pending = deque(names)
    failed = False
    started = time.monotonic()
    try:
        with tempfile.TemporaryDirectory(prefix='dotfiles-tests-') as tmp:
            while (pending or running) and not interrupted:
                while pending and len(running) < jobs and not interrupted:
                    name = pending.popleft()
                    log = open(Path(tmp) / (name + '.log'), 'w+b')
                    entry = manifest['modules'][name]
                    command = [sys.executable if part == '{python}' else part for part in entry['command']]
                    begin = time.monotonic()
                    try:
                        process = subprocess.Popen(command, cwd=root, stdout=log, stderr=subprocess.STDOUT,
                            stdin=subprocess.DEVNULL, start_new_session=True,
                            env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1', 'DOTFILES_PRECOMMIT_OFF': '1'})
                    except BaseException:
                        log.close()
                        raise
                    # A signal received inside Popen only sets a flag; ownership is registered first.
                    owned.append((process, log))
                    running[name] = (process, log, begin)
                for name, (process, log, begin) in list(running.items()):
                    code = process.poll()
                    if code is None:
                        continue
                    kill_group(process, signal.SIGKILL)
                    process.wait()
                    log.seek(0)
                    output = log.read().decode('utf-8', errors='replace')
                    log.close()
                    owned.remove((process, log))
                    passed = code == 0
                    if manifest['modules'][name].get('shell'):
                        rows = re.findall(r'^MODULE_RESULT name=(\S+) pass=(\d+) fail=(\d+)$', output, re.M)
                        passed = passed and len(rows) == 1 and rows[0][0] == name and int(rows[0][1]) > 0 and rows[0][2] == '0'
                    if verbose or not passed:
                        print(output, end='')
                    print('TEST_MODULE ' + json.dumps({'name': name, 'exit': code, 'passed': passed,
                        'seconds': round(time.monotonic() - begin, 3)}), flush=True)
                    failed |= not passed
                    completed.append(name)
                    del running[name]
                if running and not interrupted:
                    time.sleep(.02)
            if interrupted:
                for process, _ in owned:
                    kill_group(process, signal.SIGTERM)
                time.sleep(.2)
    finally:
        for sig in previous:
            signal.signal(sig, signal.SIG_IGN)
        for process, log in owned:
            kill_group(process, signal.SIGKILL)
            process.wait()
            log.close()
        for sig, handler in previous.items():
            signal.signal(sig, handler)
    passed = not interrupted and not failed and set(completed) == set(names)
    print('TEST_RESULT ' + json.dumps({'passed': passed, 'selected': names, 'completed': completed,
          'seconds': round(time.monotonic() - started, 3)}), flush=True)
    return interrupted or (0 if passed else 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--module', action='append')
    group.add_argument('--base')
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--verbose', action='store_true')
    args = parser.parse_args()
    try:
        if args.jobs < 1:
            raise ValueError('--jobs must be positive')
        if os.environ.get('DOTFILES_TEST_SHARD'):
            raise ValueError('DOTFILES_TEST_SHARD retired; use --module or --base')
        root = args.root.resolve()
        manifest = load_manifest(root)
        names, reason = list(manifest['modules']), 'complete suite'
        if args.module:
            names, reason = args.module, 'explicit focused check'
        elif args.base:
            try:
                names, reason = select_paths(manifest, local_paths(root, args.base))
            except (OSError, ValueError, subprocess.CalledProcessError) as error:
                reason = 'full fallback: ' + str(error)
        if not names or len(names) != len(set(names)) or not set(names) <= manifest['modules'].keys():
            raise ValueError('empty, duplicate or unknown module selection')
        print('TEST_SELECTION ' + json.dumps({'modules': names, 'reason': reason}), flush=True)
        return 0 if args.list else execute(root, manifest, names, args.jobs, args.verbose)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print('TEST_ERROR: ' + str(error), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
