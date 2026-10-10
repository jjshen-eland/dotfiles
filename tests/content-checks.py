#!/usr/bin/env python3
"""Check the current repository; scanner implementation regressions are separate."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tests'))
from suite import load_manifest, select_paths  # noqa: E402

failed = False
# The shared harness defines every path; selector tests pass paths as data.
NOT_READERS = {'tests/module-shell.sh', 'tests/test_suite.py', 'tests/test_ci_selection.py'}
DYNAMIC_READERS = {'tests/test_doc_governance.py': {'content'}}  # run below as RealRetrievalCorpusTests


def route_drift(manifest, texts, files):
    """A module source naming a routed path must have one of its modules selected for that path."""
    readers = {}
    for name, entry in manifest['modules'].items():
        own = {p for p in entry['command'] if p.startswith('tests/')}
        if entry.get('shell'):
            own.add(f'tests/modules/{name}.sh')
        for source in own - NOT_READERS:
            readers.setdefault(source, set()).add(name)
    for source, extra in DYNAMIC_READERS.items():
        readers.setdefault(source, set()).update(extra)
    allowed = manifest.get('name_only_mentions', {})
    problems = [f'stale name-only mention: {s} {p}' for s, paths in allowed.items() for p in paths
                if p not in files or p not in texts.get(s, '')]
    for path in files:
        if '/' not in path:
            continue
        selected = set(select_paths(manifest, [path])[0])
        if selected == set(manifest['modules']):
            continue
        for source, modules in sorted(readers.items()):
            if path in texts.get(source, '') and not modules & selected and path not in allowed.get(source, ()):
                problems.append(f'route drift: {source} names {path}; select one of {sorted(modules)}')
    return problems


drift_manifest = {'modules': {'m1': {'command': ['x', 'tests/m1.py']}, 'm2': {'command': ['x', 'tests/m2.py']}},
                  'routes': [{'paths': ['a/x.md'], 'modules': ['m1']}]}
drift_texts = {'tests/m1.py': '', 'tests/m2.py': 'open("a/x.md")'}
if (len(route_drift(drift_manifest, drift_texts, ['a/x.md'])) != 1
        or route_drift(dict(drift_manifest, name_only_mentions={'tests/m2.py': ['a/x.md']}), drift_texts, ['a/x.md'])
        or not route_drift(dict(drift_manifest, name_only_mentions={'tests/m1.py': ['a/x.md']}), drift_texts, ['a/x.md'])):
    raise RuntimeError('route drift check failed its controls')
manifest = load_manifest(ROOT)
tracked = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', '-z']).decode().split('\0')
sources = {p for e in manifest['modules'].values() for p in e['command'] if p.startswith('tests/')}
sources |= {f'tests/modules/{n}.sh' for n, e in manifest['modules'].items() if e.get('shell')}
for problem in route_drift(manifest, {s: (ROOT / s).read_text() for s in sources}, set(filter(None, tracked))):
    print(problem)
    failed = True


def cli_preferences(text):
    blocks = re.findall(r'^## CLI preferences\n(.*?)(?=^#{1,2} |\Z)', text, re.M | re.S)
    return blocks[0].strip() if len(blocks) == 1 else ''


# A short replica is necessary in each runtime's always-on entry; reject drift.
sample = '## CLI preferences\n\nexample\n\n## Next\nunrelated\n'
if (cli_preferences(sample) != 'example' or cli_preferences('')
        or cli_preferences('## CLI preferences\n\n') or cli_preferences(sample + sample)):
    raise RuntimeError('CLI preferences section extraction failed its controls')
claude_cli = cli_preferences((ROOT / 'claude/CLAUDE.md').read_text())
codex_cli = cli_preferences((ROOT / 'codex/AGENTS.md').read_text())
if not claude_cli or claude_cli != codex_cli:
    print('CLI preferences missing, duplicated or different across runtime entries')
    failed = True

for scanner in ('kernel', 'xref'):
    result = subprocess.run([sys.executable, '-B', str(ROOT/'tests'/f'{scanner}-gate.py'), '--root', str(ROOT)],
                            capture_output=True, text=True)
    print(result.stdout, end='')
    print(result.stderr, end='', file=sys.stderr)
    failed |= result.returncode != 0 or bool(result.stdout.strip())
result = subprocess.run([sys.executable, '-B', str(ROOT/'tests/test_doc_governance.py'), 'RealRetrievalCorpusTests'])
raise SystemExit(int(failed or result.returncode != 0))
