#!/bin/sh
# Claude Code / Codex Stop hook: mark when the main agent starts waiting for input.
# Hook failures must never turn a completed agent response into an error.

set +e
exec 2>/dev/null

# Both runtimes send one JSON object on stdin. Consume it without echoing any
# conversation content, then emit the shared structured hook response.
label='等待輸入起點'
case "${1:-}" in
    codex|claude)
        script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) || exit 0
        label=$(python3 "$script_dir/../shared/skills/turbo/scripts/turbo-state.py" notice --runtime "$1") || label='回合結束'
        ;;
    *) cat >/dev/null || true ;;
esac
timestamp=$(TZ=Etc/GMT-8 date '+%Y-%m-%d %H:%M:%S GMT+8') || exit 0
[ -n "$timestamp" ] || exit 0

printf '{"systemMessage":"🕒 %s：%s"}\n' "$label" "$timestamp" || true
exit 0
