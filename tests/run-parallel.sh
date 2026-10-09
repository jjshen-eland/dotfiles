#!/usr/bin/env bash
# Compatibility command; scheduling and selection have one implementation.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -B "$ROOT/tests/suite.py" "$@"
