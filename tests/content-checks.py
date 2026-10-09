#!/usr/bin/env python3
"""Check the current repository; scanner implementation regressions are separate."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
failed = False


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
