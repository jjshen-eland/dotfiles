#!/usr/bin/env bash

set -uo pipefail

settings=${CLAUDE_SETTINGS:-${1:-}}

if [ -z "$settings" ] || [ ! -r "$settings" ]; then
    printf 'Claude settings file is not readable: %s\n' "${settings:-<unset>}" >&2
    exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required to read Claude plugin settings.\n' >&2
    exit 1
fi
if ! jq -e '(.enabledPlugins // {}) | type == "object"' "$settings" >/dev/null 2>&1; then
    printf 'enabledPlugins must be a JSON object in %s\n' "$settings" >&2
    exit 1
fi

jq -r '(.enabledPlugins // {}) | to_entries | map(select(.value == true) | .key) | sort[]' "$settings" |
    while IFS= read -r plugin; do
        printf 'claude plugins install %s\n' "$plugin"
    done
