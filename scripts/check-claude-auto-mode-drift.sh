#!/usr/bin/env bash

# Warn when Claude adds/removes built-in auto-mode environment slots. The local
# settings must spell out this list because environment does not support $defaults.
set -uo pipefail

command -v claude >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

defaults_json="$(claude auto-mode defaults 2>/dev/null)" || exit 0
config_json="$(claude auto-mode config 2>/dev/null)" || exit 0

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-auto-mode.XXXXXX")" || exit 0
trap 'rm -rf "$tmp_dir"' EXIT

# Section headings (`### Org-wide`) carry no `label: value` and are not slots.
# sort and comm must share one collation, or comm silently reports every line in
# both columns.
extract_slots() {
    jq -r '.environment[]? | select(index(":")) | split(":")[0]' | LC_ALL=C sort -u
}

if ! extract_slots <<< "$defaults_json" > "$tmp_dir/defaults" \
    || ! extract_slots <<< "$config_json" > "$tmp_dir/config"; then
    exit 0
fi

missing="$(LC_ALL=C comm -23 "$tmp_dir/defaults" "$tmp_dir/config")"
extra="$(LC_ALL=C comm -13 "$tmp_dir/defaults" "$tmp_dir/config")"
[ -z "$missing" ] && [ -z "$extra" ] && exit 0

echo '⚠️  Claude autoMode.environment slots have drifted; review claude/settings.json:'
if [ -n "$missing" ]; then
    while IFS= read -r slot; do printf '     missing locally: %s\n' "$slot"; done <<< "$missing"
fi
if [ -n "$extra" ]; then
    while IFS= read -r slot; do printf '     local-only slot: %s\n' "$slot"; done <<< "$extra"
fi

exit 0
