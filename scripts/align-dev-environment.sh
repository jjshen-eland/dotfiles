#!/usr/bin/env bash
# Ownership-scoped environment alignment; package removal is limited to explicit ledger ownership.
# This command neither pulls Git nor updates independently installed packages.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:-plan}"
[ "$#" -eq 0 ] || shift
case "$mode" in plan|apply|check) ;; *) echo 'Usage: align-dev-environment.sh {plan|apply|check} [tool options]' >&2; exit 2 ;; esac
# Validate shell migration before package changes.
python3 "$ROOT/scripts/ensure-shell-env.py" plan
# Tool failure stops before shell mutation, and retains the per-tool diagnostic.
bash "$ROOT/scripts/dev-tools.sh" "$mode" "$@"
python3 "$ROOT/scripts/ensure-shell-env.py" "$mode"
