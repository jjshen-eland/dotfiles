#!/usr/bin/env python3
"""Check the current repository; scanner implementation regressions are separate."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
failed = False
for scanner in ('kernel', 'xref'):
    result = subprocess.run([sys.executable, '-B', str(ROOT/'tests'/f'{scanner}-gate.py'), '--root', str(ROOT)],
                            capture_output=True, text=True)
    print(result.stdout, end='')
    print(result.stderr, end='', file=sys.stderr)
    failed |= result.returncode != 0 or bool(result.stdout.strip())
result = subprocess.run([sys.executable, '-B', str(ROOT/'tests/test_doc_governance.py'), 'RealRetrievalCorpusTests'])
raise SystemExit(int(failed or result.returncode != 0))
