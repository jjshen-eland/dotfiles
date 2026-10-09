#!/usr/bin/env bash
# Complete suite, or --base REF / --module NAME for impact/focused validation.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -B "$ROOT/tests/suite.py" "$@"
