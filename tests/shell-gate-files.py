#!/usr/bin/env python3
"""List the existing shell gate scope once per physical script."""
from pathlib import Path
import sys

PATTERNS = (
    'scripts/*.sh', 'scripts/lib/inventory.sh', 'claude/scripts/*.sh',
    'shared/skills/*/scripts/*.sh', 'shared/skills/*/scripts/lib/*.sh',
    'claude/skills/*/scripts/*.sh', 'claude/skills/*/scripts/lib/*.sh',
    'codex/skills/*/scripts/*.sh', '.githooks/dispatcher', 'shell/functions.sh',
    'setup-mac-env.sh', 'setup-linux-env.sh', 'write-mac-defaults.sh',
    'claude/evals/*.sh', 'tests/*.sh', 'tests/modules/*.sh',
)


def main():
    root = Path(sys.argv[1])
    files = set()
    try:
        for pattern in PATTERNS:
            matches = sorted(root.glob(pattern))
            if '*' not in pattern and not matches:
                raise FileNotFoundError(root / pattern)
            for path in matches:
                resolved = path.resolve(strict=True)
                if not resolved.is_file() or '\n' in str(resolved):
                    raise ValueError(f'invalid shell gate file: {path}')
                files.add(str(resolved))
        if len(files) < 15:
            raise ValueError('shell gate scope unexpectedly small')
    except (OSError, ValueError) as error:
        print(f'shell gate inventory failed: {error}', file=sys.stderr)
        return 1
    print('\n'.join(sorted(files)))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
