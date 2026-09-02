#!/bin/sh
# Claude Code / Codex Stop hook: mark when the main agent starts waiting for input.
# Hook failures must never turn a completed agent response into an error.

set +e
exec 2>/dev/null

# Both runtimes send one JSON object on stdin. Consume it without echoing any
# conversation content, then emit the shared structured hook response.
cat >/dev/null || true
timestamp=$(TZ=Etc/GMT-8 date '+%Y-%m-%d %H:%M:%S GMT+8') || exit 0
[ -n "$timestamp" ] || exit 0

printf '{"systemMessage":"🕒 等待輸入起點：%s"}\n' "$timestamp" || true
exit 0
