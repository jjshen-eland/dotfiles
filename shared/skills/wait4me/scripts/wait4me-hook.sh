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
stop_diagnostic="$state_dir/last-stop"

ensure_state_dir() {
    mkdir -p "$state_dir" 2>/dev/null || return 1
    chmod 700 "$state_root" "$state_dir" 2>/dev/null || true
}

enable_session() {
    ensure_state_dir || return 1
    : > "$enabled_file" 2>/dev/null
}

cleanup_session() {
    rm -f "$enabled_file" "$stop_diagnostic" 2>/dev/null
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

# Only fixed stages and allowlisted error tokens go to this owner-only session file.
# It survives a stopped async sender, so "sending" without a terminal stage is evidence.
record_stop() {  # <stage> <sender-rc> <safe-kind>
    [ -d "$state_dir" ] || return 0
    printf 'stage=%s rc=%s kind=%s\n' "$1" "$2" "$3" > "$stop_diagnostic" 2>/dev/null || true
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
    local message body sender_output sender_rc
    sender_kind=none
    message="$(jq -nr --arg value "$1" '$value | gsub("[\\r\\n\\t]+"; " ") | gsub("  +"; " ") | .[0:200]' 2>/dev/null)"
    if [ -z "$message" ]; then sender_kind=message_unavailable; return 75; fi
    if [ ! -x "$sender" ]; then sender_kind=sender_unavailable; return 75; fi
    body="$(jq -n --arg message "$message" \
        '{message:$message,level:"info",task:"agent-response-needed"}' 2>/dev/null)"
    if [ -z "$body" ]; then sender_kind=payload_unavailable; return 75; fi
    sender_output="$(printf '%s\n' "$body" | "$sender" 2>&1)"
    sender_rc=$?
    if [ "$sender_rc" -ne 0 ]; then
        case "$sender_output" in
            'wait4me: notification skipped ('*')')
                sender_kind="${sender_output#wait4me: notification skipped (}"
                sender_kind="${sender_kind%)}"
                ;;
            *) sender_kind=unknown ;;
        esac
        case "$sender_kind" in
            ''|*[!a-zA-Z0-9_-]*) sender_kind=unknown ;;
        esac
        printf 'wait4me: notification skipped (%s)\n' "$sender_kind" >&2
    fi
    return "$sender_rc"
}

notify_once() {
    notification_stage=claim-unavailable
    notification_rc=0
    sender_kind=none
    begin_notification "$1" || return 0
    if send_notification "$2"; then
        finish_notification success
        notification_stage=delivered
    else
        notification_rc=$?
        finish_notification failure
        notification_stage=send-failed
    fi
}

probe_control_notification() {
    probe_result=failed
    probe_kind=none
    if send_notification 'wait4me 通知測試：目前已啟用。收到這則表示通知通道可用。'; then
        probe_result=accepted
    else
        probe_kind="$sender_kind"
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
                    probe_control_notification
                    emit_context "wait4me-control: enabled for this session; probe=$probe_result; kind=$probe_kind. Report switch and probe separately; accepted means Gateway acknowledgement, and the user still confirms device receipt. $marker_contract"
                else
                    emit_context 'wait4me-control: enable failed because ephemeral session state was unavailable. Do not claim it is enabled.'
                fi
                ;;
            '$wait4me off')
                cleanup_session
                emit_context 'wait4me-control: disabled for this session; probe=not-sent. Confirm briefly.'
                ;;
            '$wait4me status')
                if is_enabled; then
                    probe_control_notification
                    emit_context "wait4me-control: status=enabled for this session; probe=$probe_result; kind=$probe_kind. Report switch and probe separately; accepted means Gateway acknowledgement, and the user still confirms device receipt. $marker_contract"
                else
                    emit_context 'wait4me-control: status=disabled for this session; probe=not-sent. Report without changing it.'
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
        record_stop entered 0 none
        reason="$(jq -r 'try ((.last_assistant_message // "") | capture("<!-- wait4me: (?<reason>[^<>\\r\\n]{1,120}) -->").reason) catch ""' <<< "$payload" 2>/dev/null)"
        if [ -z "$reason" ]; then record_stop marker-absent 0 none; exit 0; fi
        reason="$(clean_text "$reason")"
        if [ -z "$reason" ]; then record_stop marker-invalid 0 none; exit 0; fi
        cwd="$(jq -r '.cwd // empty' <<< "$payload" 2>/dev/null)"
        repo="$(basename "${cwd:-session}")"
        turn_id="$(jq -r '.turn_id // empty' <<< "$payload" 2>/dev/null)"
        [ -n "$turn_id" ] || turn_id="$(printf '%s' "$reason" | hash_text)"
        record_stop sending 0 none
        notify_once "stop|$turn_id|$reason" \
            "等待回應: $repo — ${reason}。請回 terminal。"
        record_stop "$notification_stage" "$notification_rc" "$sender_kind"
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
