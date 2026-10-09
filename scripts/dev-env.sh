#!/usr/bin/env bash
# Explicit environment for agent commands launched without shell startup files.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../shell/environment.sh
source "$ROOT/shell/environment.sh"
[ "$#" -gt 0 ] || { echo "Usage: $0 command [args...]" >&2; exit 2; }
exec "$@"
