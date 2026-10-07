#!/usr/bin/env python3
"""Validate the executable workflow structure, using the declared yq dependency."""
import json
import shlex
import subprocess
import sys


def validate(doc):
    errors = []
    if not isinstance(doc, dict):
        return ['workflow must be a mapping']
    if not isinstance(doc.get('on'), dict) or set(doc['on']) != {'pull_request'}:
        errors.append('workflow must trigger only on pull_request')
    if doc.get('permissions') != {'contents': 'read'}:
        errors.append('workflow must have only contents: read permission')
    job = doc.get('jobs', {}).get('suite', {})
    if not isinstance(job, dict):
        return errors + ['suite job is missing']
    if 'if' in job or job.get('permissions', {'contents': 'read'}) != {'contents': 'read'}:
        errors.append('suite job must be unconditional and read-only')
    strategy = job.get('strategy', {})
    matrix = strategy.get('matrix') if isinstance(strategy, dict) else None
    platforms = matrix.get('os') if isinstance(matrix, dict) else None
    if (not isinstance(matrix, dict) or set(matrix) != {'os'}
            or not isinstance(platforms, list) or len(platforms) != 2
            or not all(isinstance(platform, str) for platform in platforms)
            or set(platforms) != {'macos-15', 'ubuntu-24.04'}):
        errors.append('suite matrix must execute both supported OSes without exclusions')
    if job.get('runs-on') != '${{ matrix.os }}':
        errors.append('suite runner must use matrix.os')
    workflow_shell = doc.get('defaults', {}).get('run', {}).get('shell', 'bash')
    defaults = job.get('defaults', {}).get('run', {})
    shell = defaults.get('shell', workflow_shell)
    dependencies = None
    complete = None
    for i, step in enumerate(job.get('steps', [])):
        if (not isinstance(step, dict) or 'if' in step
                or step.get('shell', shell) not in ('bash', 'sh')):
            continue
        run = step.get('run')
        if not isinstance(run, str):
            continue
        # Accept actual simple commands, not comments, echo strings or conditional blocks.
        lines = [shlex.split(line, comments=True) for line in run.splitlines()]
        commands = [line for line in lines if line]
        if len(commands) != 1:
            continue
        argv = commands[0]
        if (argv[:2] == ['brew', 'install'] and set(argv[2:]) == {'shellcheck', 'ripgrep', 'yq', 'zsh'}
                and step.get('continue-on-error', False) is False):
            dependencies = i
        if argv == ['./tests/run-parallel.sh'] and step.get('continue-on-error', False) is False:
            complete = i
    if dependencies is None or complete is None or dependencies >= complete:
        errors.append('unconditional dependency install must precede the complete suite step')
    if job.get('continue-on-error', False) is not False:
        errors.append('suite failure must propagate')
    return errors


def main():
    try:
        result = subprocess.run(['yq', '-o=json', '.', sys.argv[1]], capture_output=True, text=True, check=True)
        errors = validate(json.loads(result.stdout))
    except (OSError, subprocess.CalledProcessError, ValueError, TypeError, AttributeError, IndexError) as error:
        print(f'CI_CONTRACT_ERROR: {error}', file=sys.stderr)
        return 2
    for error in errors:
        print('CI_CONTRACT_FINDING: ' + error)
    return 1 if errors else 0


if __name__ == '__main__':
    raise SystemExit(main())
