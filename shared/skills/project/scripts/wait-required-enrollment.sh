#!/usr/bin/env bash
# Wait only for the first required-check object after PR creation.
# Exit 0: ENROLLED; 1: bounded UNOBSERVED; 2: query/transport error;
# 3: PR head changed; 4: exact-head run ended unsuccessfully before enrollment.

set -u

MAX_ATTEMPTS=13
INTERVAL_SECONDS=5
GH_BIN="${PROJECT_ENROLLMENT_GH:-gh}"

usage() {
    echo "usage: $0 <owner/repo> <pr-number-or-url> <expected-head-sha>" >&2
    exit 64
}

[ "$#" -eq 3 ] || usage
repo_slug="$1"
pr_ref="$2"
expected_head="$3"

[[ "$repo_slug" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || usage
[[ "$pr_ref" =~ ^[^[:space:]]+$ ]] && [[ "$pr_ref" != -* ]] || usage
if ! [[ "$expected_head" =~ ^[0-9A-Fa-f]{40}([0-9A-Fa-f]{24})?$ ]]; then
    usage
fi

query_error() {
    local stage="$1" detail="$2"
    echo "verdict: QUERY_ERROR"
    echo "stage: $stage"
    [ -z "$detail" ] || printf 'detail: %s\n' "$detail"
    exit 2
}

run_observed=no
active_run_observed=no
command -v jq >/dev/null 2>&1 || query_error dependency "jq not found"
attempt=1
while :; do
    current_head="$("$GH_BIN" pr view "$pr_ref" -R "$repo_slug" --json headRefOid -q .headRefOid 2>&1)"
    head_rc=$?
    [ "$head_rc" -eq 0 ] || query_error pr-head "$current_head"
    [ -n "$current_head" ] || query_error pr-head "empty headRefOid"
    if [ "$current_head" != "$expected_head" ]; then
        echo "verdict: HEAD_CHANGED"
        echo "expected-head: $expected_head"
        echo "actual-head: $current_head"
        exit 3
    fi

    checks_output="$("$GH_BIN" pr checks "$pr_ref" -R "$repo_slug" --required \
        --json name,bucket,state 2>&1)"
    checks_rc=$?
    checks_count="$(printf '%s\n' "$checks_output" | jq -er \
        'if type == "array" then length else error("not an array") end' 2>/dev/null)"
    checks_json_rc=$?

    if [ "$checks_json_rc" -eq 0 ]; then
        if [ "$checks_count" -gt 0 ]; then
            echo "verdict: ENROLLED"
            echo "attempts: ${attempt}/${MAX_ATTEMPTS}"
            echo "run-observed: $run_observed"
            echo "active-run-observed: $active_run_observed"
            echo "checks-exit: $checks_rc"
            printf 'checks-json: %s\n' "$checks_output"
            exit 0
        fi
        if [ "$checks_rc" -ne 0 ] && [ "$checks_rc" -ne 1 ]; then
            query_error required-checks "$checks_output"
        fi
    elif [ "$checks_rc" -eq 1 ] \
        && [[ "$checks_output" =~ ^no\ checks\ reported\ on\ the\ \'[^\']+\'\ branch$ ]]; then
        :
    else
        query_error required-checks "$checks_output"
    fi

    runs_output="$("$GH_BIN" run list -R "$repo_slug" --commit "$expected_head" \
        --event pull_request --limit 20 \
        --json databaseId,headSha,event,status,conclusion,url 2>&1)"
    runs_rc=$?
    [ "$runs_rc" -eq 0 ] || query_error run-list "$runs_output"
    matching_runs_json="$(printf '%s\n' "$runs_output" | jq -cer --arg head "$expected_head" \
        'if type == "array" then map(select(.headSha == $head and .event == "pull_request")) else error("not an array") end' \
        2>/dev/null)"
    runs_json_rc=$?
    [ "$runs_json_rc" -eq 0 ] || query_error run-list "$runs_output"
    invalid_runs="$(printf '%s\n' "$matching_runs_json" | jq -er '
        [ .[]
          | .status as $status
          | select(
              (.databaseId | type) != "number"
              or (.status | type) != "string"
              or (.conclusion | type) != "string"
              or (["queued", "in_progress", "waiting", "requested", "pending", "completed"] | index($status)) == null
              or ($status == "completed" and .conclusion == "")
              or ($status != "completed" and .conclusion != "")
            )
        ] | length' 2>/dev/null)"
    invalid_runs_rc=$?
    [ "$invalid_runs_rc" -eq 0 ] && [ "$invalid_runs" -eq 0 ] \
        || query_error run-list "$runs_output"
    run_summary="$(printf '%s\n' "$matching_runs_json" | jq -cer '
        {
          count: length,
          active: ([.[] | select(.status != "completed")] | length),
          terminal_conclusions: (
            [.[] | select(.status == "completed" and .conclusion != "success") | .conclusion]
            | unique | sort | join(",")
          )
        }' 2>/dev/null)"
    run_summary_rc=$?
    [ "$run_summary_rc" -eq 0 ] || query_error run-list "$runs_output"
    matching_runs="$(printf '%s\n' "$run_summary" | jq -r '.count')"
    active_runs="$(printf '%s\n' "$run_summary" | jq -r '.active')"
    terminal_conclusions="$(printf '%s\n' "$run_summary" | jq -r '.terminal_conclusions')"
    if [ "$matching_runs" -gt 0 ]; then
        run_observed=yes
    fi
    if [ "$active_runs" -gt 0 ]; then
        active_run_observed=yes
    fi

    if [ -n "$terminal_conclusions" ]; then
        echo "verdict: RUN_TERMINAL"
        echo "attempts: ${attempt}/${MAX_ATTEMPTS}"
        echo "run-observed: $run_observed"
        echo "active-run-observed: $active_run_observed"
        echo "run-conclusions: $terminal_conclusions"
        exit 4
    fi

    if [ "$attempt" -ge "$MAX_ATTEMPTS" ] && [ "$active_runs" -eq 0 ]; then
        echo "verdict: UNOBSERVED"
        echo "attempts: ${attempt}/${MAX_ATTEMPTS}"
        echo "run-observed: $run_observed"
        echo "active-run-observed: $active_run_observed"
        exit 1
    fi

    sleep "$INTERVAL_SECONDS" || query_error sleep "sleep failed"
    attempt=$((attempt + 1))
done

query_error internal "startup enrollment loop escaped its fixed bound"
