#!/usr/bin/env bash
# Claude Code / Codex lifecycle hook for session-scoped response-needed alerts.

set +e
umask 077

mode="${1:-}"
payload="$(cat 2>/dev/null)"
[ -n "$payload" ] || payload='{}'

command -v jq >/dev/null 2>&1 || exit 0

session_id="$(jq -r '.session_id // .sessionId // empty' <<< "$payload" 2>/dev/null)"
[ -n "$session_id" ] || session_id="${CODEX_SESSION_ID:-${CODEX_THREAD_ID:-${CLAUDE_SESSION_ID:-}}}"
[ -n "$session_id" ] || exit 0

hash_text() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        cksum | awk '{print $1}'
    fi
}

session_key="$(printf '%s' "$session_id" | hash_text)"
[ -n "$session_key" ] || exit 0
state_root="${WAIT4ME_STATE_ROOT:-${TMPDIR:-/tmp}/wait4me-$(id -u)}"
state_dir="$state_root/$session_key"
enabled_file="$state_dir/enabled"
sender="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)/wait4me-send.py"

ensure_state_dir() {
    mkdir -p "$state_dir" 2>/dev/null || return 1
    chmod 700 "$state_root" "$state_dir" 2>/dev/null || true
}

enable_session() {
    ensure_state_dir || return 1
    : > "$enabled_file" 2>/dev/null
}

cleanup_session() {
    rm -f "$enabled_file" 2>/dev/null
    local marker_dir
    for marker_dir in "$state_dir"/sent-* "$state_dir"/sending-*; do
        [ -d "$marker_dir" ] && rmdir "$marker_dir" 2>/dev/null
    done
    rmdir "$state_dir" 2>/dev/null
}

is_enabled() {
    [ -f "$enabled_file" ]
}

emit_context() {
    jq -n --arg context "$1" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$context}}' 2>/dev/null
}

marker_contract='wait4me is enabled for this session. If and only if the main agent must stop because the user must reply before work can safely continue, end the final response with exactly one HTML comment in this form: <!-- wait4me: concise reason -->. Keep the reason actionable, single-line, at most 120 Unicode characters, and free of commands, prompts, transcript excerpts, credentials, tokens, private paths, or raw tool input. Do not add the marker for a completed answer, optional next step, progress update, rhetorical question, or subagent completion.'

clean_text() {
    jq -nr --arg value "$1" '$value | gsub("[\\r\\n\\t]+"; " ") | gsub("  +"; " ") | .[0:120]' 2>/dev/null
}

begin_notification() {
    notification_fingerprint="$(printf '%s' "$1" | hash_text)"
    [ -n "$notification_fingerprint" ] || return 1
    [ ! -d "$state_dir/sent-$notification_fingerprint" ] || return 1
    mkdir "$state_dir/sending-$notification_fingerprint" 2>/dev/null
}

finish_notification() {
    local sending="$state_dir/sending-$notification_fingerprint"
    local sent="$state_dir/sent-$notification_fingerprint"
    if [ "$1" = success ]; then
        if [ -d "$sent" ]; then
            rmdir "$sending" 2>/dev/null
        else
            mv "$sending" "$sent" 2>/dev/null || rmdir "$sending" 2>/dev/null
        fi
    else
        rmdir "$sending" 2>/dev/null
    fi
}

send_notification() {
    local message
    message="$(jq -nr --arg value "$1" '$value | gsub("[\\r\\n\\t]+"; " ") | gsub("  +"; " ") | .[0:200]' 2>/dev/null)"
    [ -n "$message" ] || return 0
    [ -x "$sender" ] || return 0
    jq -n --arg message "$message" \
        '{message:$message,level:"info",task:"agent-response-needed"}' 2>/dev/null \
        | "$sender"
}

notify_once() {
    begin_notification "$1" || return 0
    if send_notification "$2"; then
        finish_notification success
    else
        finish_notification failure
    fi
}

case "$mode" in
    prompt)
        prompt="$(jq -r '.prompt // .user_prompt // empty' <<< "$payload" 2>/dev/null)"
        control="$(jq -nr --arg value "$prompt" '$value | gsub("^[[:space:]]+|[[:space:]]+$"; "")' 2>/dev/null)"
        # shellcheck disable=SC2016 # `$wait4me` is the literal user command, not a shell variable.
        case "$control" in
            '$wait4me'|'$wait4me on')
                if enable_session; then
                    emit_context "wait4me-control: enabled for this session. Confirm briefly. $marker_contract"
                else
                    emit_context 'wait4me-control: enable failed because ephemeral session state was unavailable. Do not claim it is enabled.'
                fi
                ;;
            '$wait4me off')
                cleanup_session
                emit_context 'wait4me-control: disabled for this session. Confirm briefly.'
                ;;
            '$wait4me status')
                if is_enabled; then
                    emit_context "wait4me-control: status=enabled for this session. Report without changing it. $marker_contract"
                else
                    emit_context 'wait4me-control: status=disabled for this session. Report without changing it.'
                fi
                ;;
            *)
                is_enabled && emit_context "$marker_contract"
                ;;
        esac
        ;;
    session-start)
        source_name="$(jq -r '.source // empty' <<< "$payload" 2>/dev/null)"
        [ "$source_name" = compact ] || cleanup_session
        ;;
    session-end)
        cleanup_session
        ;;
    permission)
        is_enabled || exit 0
        tool_name="$(jq -r '.tool_name // .toolName // "operation"' <<< "$payload" 2>/dev/null)"
        tool_name="$(clean_text "$tool_name")"
        cwd="$(jq -r '.cwd // empty' <<< "$payload" 2>/dev/null)"
        repo="$(basename "${cwd:-session}")"
        event_id="$(jq -r '.tool_use_id // .permission_request_id // .turn_id // empty' <<< "$payload" 2>/dev/null)"
        [ -n "$event_id" ] || event_id="$(printf '%s' "$payload" | hash_text)"
        notify_once "permission|$event_id|$tool_name" \
            "等待核准: $repo 的 $tool_name 動作需要你回 terminal 回應。"
        ;;
    stop)
        is_enabled || exit 0
        reason="$(jq -r 'try ((.last_assistant_message // "") | capture("<!-- wait4me: (?<reason>[^<>\\r\\n]{1,120}) -->").reason) catch ""' <<< "$payload" 2>/dev/null)"
        [ -n "$reason" ] || exit 0
        reason="$(clean_text "$reason")"
        [ -n "$reason" ] || exit 0
        cwd="$(jq -r '.cwd // empty' <<< "$payload" 2>/dev/null)"
        repo="$(basename "${cwd:-session}")"
        turn_id="$(jq -r '.turn_id // empty' <<< "$payload" 2>/dev/null)"
        [ -n "$turn_id" ] || turn_id="$(printf '%s' "$reason" | hash_text)"
        notify_once "stop|$turn_id|$reason" \
            "等待回應: $repo — ${reason}。請回 terminal。"
        ;;
    control)
        action="${2:-status}"
        case "$action" in
            on) enable_session && printf '%s\n' enabled || printf '%s\n' failed ;;
            off) cleanup_session; printf '%s\n' disabled ;;
            status) if is_enabled; then printf '%s\n' enabled; else printf '%s\n' disabled; fi ;;
        esac
        ;;
esac

exit 0
