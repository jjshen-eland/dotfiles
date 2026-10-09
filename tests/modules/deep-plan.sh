#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 12b. deep-plan 雙薄入口與共用 workflow"
DPS_CLAUDE="$ROOT/claude/skills/deep-plan"
DPS_CODEX="$ROOT/codex/skills/deep-plan"
if python3 "$ROOT/tests/deep-plan-repair-context.py" "$DPS_CODEX/scripts/launch-reviewers.py" >"$TMP/deep-plan-repair-context.out" 2>&1; then
    ok "deep-plan repair context：discovery與修後證據入口分離"
else
    cat "$TMP/deep-plan-repair-context.out"
    bad "deep-plan repair context regression"
fi
if [ -f "$DPS_CLAUDE/SKILL.md" ] && [ -f "$DPS_CODEX/SKILL.md" ] \
    && [ ! -L "$DPS_CLAUDE" ] && [ ! -L "$DPS_CODEX" ]; then
    ok "deep-plan 兩個 runtime 各有薄入口"
else bad "deep-plan runtime entry 缺漏或仍是 whole-directory symlink"; fi
if [ -L "$DPS_CODEX/references" ] \
    && [ "$DPS_CODEX/references/workflow.md" -ef "$DPS_CLAUDE/references/workflow.md" ] \
    && [ "$DPS_CODEX/references/planner-brief.md" -ef "$DPS_CLAUDE/references/planner-brief.md" ] \
    && [ "$DPS_CODEX/references/reviewer-prompt.txt" -ef "$DPS_CLAUDE/references/reviewer-prompt.txt" ] \
    && [ "$DPS_CODEX/references/criteria-impact-prompt.txt" -ef "$DPS_CLAUDE/references/criteria-impact-prompt.txt" ]; then
    ok "deep-plan workflow、brief 與 reviewer prompts 是單一 portable core"
else bad "deep-plan shared references 分叉或未正確路由"; fi
dps_claude_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$DPS_CLAUDE/SKILL.md")"
dps_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$DPS_CODEX/SKILL.md")"
dps_claude_description="$(grep '^description:' <<< "$dps_claude_frontmatter")"
dps_codex_description="$(grep '^description:' <<< "$dps_codex_frontmatter")"
if [ "$dps_claude_description" = "$dps_codex_description" ] \
    && ! grep -Eq '^(user-invocable|argument-hint|allowed-tools|context|agent):' <<< "$dps_claude_frontmatter$dps_codex_frontmatter"; then
    ok "deep-plan 雙入口 description 一致且 frontmatter portable"
else bad "deep-plan 雙入口 frontmatter 漂移或混入專屬欄位"; fi
dps_claude_lines="$(wc -l < "$DPS_CLAUDE/SKILL.md" | tr -d ' ')"
dps_codex_lines="$(wc -l < "$DPS_CODEX/SKILL.md" | tr -d ' ')"
if [ "$dps_claude_lines" -le 30 ] && [ "$dps_codex_lines" -le 30 ] \
    && grep -q 'references/workflow.md' "$DPS_CLAUDE/SKILL.md" \
    && grep -q 'references/workflow.md' "$DPS_CODEX/SKILL.md"; then
    ok "deep-plan runtime entries 保持薄殼並路由 shared workflow"
else bad "deep-plan runtime entry 過厚或未載入 shared workflow"; fi
# shellcheck disable=SC2016 # literal Markdown backticks／$deep-plan tokens below
if grep -q 'background `Agent`' "$DPS_CLAUDE/SKILL.md" \
    && ! grep -Eq 'launch-reviewers|spawn_agent|wait_agent|fork_turns' "$DPS_CLAUDE/SKILL.md" \
    && grep -q 'scripts/launch-reviewers.py' "$DPS_CODEX/SKILL.md" \
    && grep -q 'stdout manifest says `ok: true`' "$DPS_CODEX/SKILL.md" \
    && ! grep -Eq 'spawn_agent|wait_agent|fork_turns|background `Agent`|SendMessage' "$DPS_CODEX/SKILL.md"; then
    ok "deep-plan runtime tool contracts 保持分離"
else bad "deep-plan runtime adapter 漂移或互相污染"; fi
# shellcheck disable=SC2016 # literal $deep-plan in metadata
if ! grep -Eq 'spawn_agent|wait_agent|fork_turns|SendMessage|Claude Code|Codex' "$DPS_CLAUDE/references/workflow.md" \
    && [ ! -e "$DPS_CODEX/evals.md" ] \
    && grep -q 'Use \$deep-plan' "$DPS_CODEX/agents/openai.yaml"; then
    ok "deep-plan shared core 無 runtime 私有工具，eval 與 UI metadata 各安其位"
else bad "deep-plan shared core 污染、eval 重複或 Codex metadata 缺漏"; fi
if grep -q 'receiver_thread_ids=\[\]' "$ROOT/shared/skills/deep-plan/evals.md" \
    && grep -q 'P17 — Codex deterministic launcher' "$ROOT/shared/skills/deep-plan/evals.md" \
    && ! grep -Eq 'fork_turns|spawn_agent|wait_agent' "$ROOT/shared/skills/deep-plan/evals.md" \
    && grep -q '恰好收到 N 份可歸因' "$DPS_CLAUDE/SKILL.md" \
    && [ -x "$DPS_CODEX/scripts/launch-reviewers.py" ] \
    && [ -f "$DPS_CODEX/assets/reviewer-output.schema.json" ]; then
    ok "deep-plan empty-wait RED oracle 與 deterministic launcher 已接線"
else bad "deep-plan 缺少 empty-wait oracle、launcher 或 output schema"; fi
if grep -q 'subprocess.Popen' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q 'stdin=subprocess.PIPE' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q 'stdout=subprocess.PIPE' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q '"read-only"' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q '"--ephemeral"' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q '"--output-schema"' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q 'reviewer-prompt.txt' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && ! grep -q 'Do not invoke any skill' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q 'start_new_session=os.name == "posix"' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q '"SIGHUP", "SIGQUIT"' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && grep -q '"--ignore-rules"' "$DPS_CODEX/scripts/launch-reviewers.py" \
    && ! grep -Eq 'shell *= *True|tempfile|mkdtemp|NamedTemporary' "$DPS_CODEX/scripts/launch-reviewers.py"; then
    ok "deep-plan Codex launcher 使用 argv＋in-memory pipes、process tree cleanup 與 repo policy"
else bad "deep-plan Codex launcher transport 或 child isolation contract 漂移"; fi

dps_fixture="$TMP/deep-plan-launcher"
git init -q -b test/deep-plan "$dps_fixture"
mkdir -p "$dps_fixture/docs/plans"
cat > "$dps_fixture/docs/plans/plan.md" <<'PLAN'
# Plan

Status: unimplemented.
PLAN
(cd "$dps_fixture" && "${GITC[@]}" add docs/plans/plan.md && "${GITC[@]}" commit -qm "docs: add plan")
cat > "$TMP/deep-plan-codex-stub" <<'PY'
#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys
import time

prompt = sys.stdin.read()
if mutate_path := os.environ.get("DEEP_PLAN_STUB_MUTATE_FILE"):
    Path(mutate_path).write_text("after\n", encoding="utf-8")
required_prompt_text = [
    "依語意找相依，不只比對字串。",
    "可唯讀查檔、搜尋、檢查歷史及執行不改變狀態的診斷。",
]
scope_text = "修後驗證資料：" if os.environ.get("DEEP_PLAN_STUB_REPAIR") else "把計畫對現況、歷史、相依與完成判定的宣稱逐一拿回 repo 查證。"
required_prompt_text.append(scope_text)
if not all(text in prompt for text in required_prompt_text):
    sys.exit(8)
if "Do not invoke any skill" in prompt or "spawn or wait" in prompt:
    sys.exit(7)
criteria_text = "這份計畫正在改變一組判準。"
if os.environ.get("DEEP_PLAN_STUB_REQUIRE_CRITERIA") and criteria_text not in prompt:
    sys.exit(9)
if os.environ.get("DEEP_PLAN_STUB_FORBID_CRITERIA") and criteria_text in prompt:
    sys.exit(10)
time.sleep(0.1)
print(json.dumps({"type": "thread.started", "thread_id": f"stub-{os.getpid()}"}))
if os.environ.get("DEEP_PLAN_STUB_INVALID"):
    review = {"invalid": True}
else:
    review = {
        "findings": [{
            "issue": "fixture finding",
            "layer": "verifiable",
            "severity": "blocker",
            "evidence": ["docs/plans/plan.md:1"],
        }],
        "verified_claims": ["plan exists"],
        "unverified_claims": [],
        "recommendation": "do_not_start",
    }
print(json.dumps({
    "type": "item.completed",
    "item": {"type": "agent_message", "text": json.dumps(review)},
}))
PY
chmod +x "$TMP/deep-plan-codex-stub"
# Transport-only unit fixtures retain their original process/schema coverage.
# Real CLI admission, exhausted/reused tickets and zero-dispatch failures run below.
dps_transport="$TMP/deep-plan-transport"
printf '#!/bin/bash\nexec python3 "%s/tests/deep-plan-routing.py" --transport "$@"\n' "$ROOT" > "$dps_transport"
chmod +x "$dps_transport"
if python3 -B "$ROOT/tests/deep-plan-routing.py" >"$TMP/deep-plan-routing.out" 2>&1; then
    ok "deep-plan controller：模式／輪次／證據隔離與真實CLI拒絕派遣"
else
    cat "$TMP/deep-plan-routing.out"
    bad "deep-plan controller behavior regression"
fi
dps_launch_out="$(DEEP_PLAN_STUB_FORBID_CRITERIA=1 "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$TMP/deep-plan-codex-stub" \
    --timeout-seconds 5)"
dps_launch_rc=$?
if [ "$dps_launch_rc" -eq 0 ] \
    && grep -q '"ok":true' <<< "$dps_launch_out" \
    && grep -q '"all_running_after_dispatch":true' <<< "$dps_launch_out" \
    && [ "$(grep -o 'stub-[0-9]*' <<< "$dps_launch_out" | sort -u | wc -l | tr -d ' ')" -eq 2 ] \
    && [ -z "$(git -C "$dps_fixture" status --porcelain=v1)" ]; then
    ok "deep-plan launcher 建立兩個 attributed reviewers 並保持 target repo 不變"
else bad "deep-plan launcher normal fixture 未滿足 parallel／fresh／read-only oracle"; fi
printf '%s\n' 'F1: verify the repair against source evidence.' > "$TMP/deep-plan-repair.md"
dps_repair_out="$(DEEP_PLAN_STUB_REPAIR=1 "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --repair-context "$TMP/deep-plan-repair.md" --codex-bin "$TMP/deep-plan-codex-stub" --timeout-seconds 5)"
dps_repair_rc=$?
if [ "$dps_repair_rc" -eq 0 ] && grep -q '"review_mode":"repair-verification"' <<< "$dps_repair_out"; then
    ok "deep-plan repair packet以immutable hash進入有效fresh manifest"
else bad "deep-plan repair packet transport失敗"; fi
dps_repair_drift_out="$(DEEP_PLAN_STUB_REPAIR=1 DEEP_PLAN_STUB_MUTATE_FILE="$TMP/deep-plan-repair.md" \
    "$dps_transport" --plan "$dps_fixture/docs/plans/plan.md" --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --repair-context "$TMP/deep-plan-repair.md" --codex-bin "$TMP/deep-plan-codex-stub" --timeout-seconds 5)"
dps_repair_drift_rc=$?
if [ "$dps_repair_drift_rc" -ne 0 ] && grep -q '"ok":false' <<< "$dps_repair_drift_out"; then
    ok "deep-plan repair packet被改寫時拒絕驗收"
else bad "deep-plan repair packet drift被錯誤放行"; fi
cp "$dps_fixture/docs/plans/plan.md" "$TMP/deep-plan-scratch.md"
dps_criteria_out="$(DEEP_PLAN_STUB_REQUIRE_CRITERIA=1 "$dps_transport" \
    --plan "$TMP/deep-plan-scratch.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$TMP/deep-plan-codex-stub" \
    --criteria-impact-review \
    --timeout-seconds 5)"
dps_criteria_rc=$?
if [ "$dps_criteria_rc" -eq 0 ] \
    && grep -q '"ok":true' <<< "$dps_criteria_out" \
    && grep -q '"criteria_impact_review":true' <<< "$dps_criteria_out"; then
    ok "deep-plan launcher 支援 repo 外 scratch plan 並保留判準類 impact-grid prompt"
else bad "deep-plan launcher 遺失 scratch artifact 或判準類 reviewer contract"; fi
dps_invalid_out="$(DEEP_PLAN_STUB_INVALID=1 "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$TMP/deep-plan-codex-stub" \
    --timeout-seconds 5)"
dps_invalid_rc=$?
if [ "$dps_invalid_rc" -eq 1 ] && grep -q '"ok":false' <<< "$dps_invalid_out"; then
    ok "deep-plan launcher 對 schema-invalid reviewer set fail closed"
else bad "deep-plan launcher 接受 schema-invalid reviewer output"; fi
dps_guard_out="$(DEEP_PLAN_REVIEWER_PROCESS=1 "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$TMP/deep-plan-codex-stub")"
dps_guard_rc=$?
if [ "$dps_guard_rc" -eq 2 ] && grep -q 'nested deep-plan reviewer launch is forbidden' <<< "$dps_guard_out"; then
    ok "deep-plan launcher 阻止 reviewer process 遞迴啟動"
else bad "deep-plan launcher recursion guard 失效"; fi
bad_plan_target="$TMP/deep-plan"$'\n'"injected.md"
cp "$dps_fixture/docs/plans/plan.md" "$bad_plan_target"
ln -s "$bad_plan_target" "$TMP/deep-plan-safe-link.md"
dps_control_out="$("$dps_transport" \
    --plan "$TMP/deep-plan-safe-link.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$TMP/deep-plan-codex-stub")"
dps_control_rc=$?
if [ "$dps_control_rc" -eq 2 ] \
    && grep -q 'resolved plan path contains a forbidden control character' <<< "$dps_control_out"; then
    ok "deep-plan launcher 對 symlink 解析後的 control-character path fail closed"
else bad "deep-plan launcher 接受 canonical path prompt injection"; fi
dps_relative_out="$("$dps_transport" \
    --plan docs/plans/plan.md \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$TMP/deep-plan-codex-stub")"
dps_relative_rc=$?
if [ "$dps_relative_rc" -eq 2 ] && grep -q 'plan path must be absolute' <<< "$dps_relative_out"; then
    ok "deep-plan launcher 拒絕 cwd-relative artifact，避免靜默審錯 scope"
else bad "deep-plan launcher 接受 relative artifact path"; fi
echo "stable" > "$dps_fixture/evidence.txt"
(cd "$dps_fixture" && "${GITC[@]}" add evidence.txt && "${GITC[@]}" commit -qm "test: add evidence")
echo "before" > "$dps_fixture/evidence.txt"
dps_mutation_out="$(DEEP_PLAN_STUB_MUTATE_FILE="$dps_fixture/evidence.txt" \
    "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$TMP/deep-plan-codex-stub" \
    --timeout-seconds 5)"
dps_mutation_rc=$?
if [ "$dps_mutation_rc" -eq 1 ] \
    && grep -q '"ok":false' <<< "$dps_mutation_out" \
    && grep -q '"content_sha256"' <<< "$dps_mutation_out"; then
    ok "deep-plan launcher 以 content fingerprint 抓到 status 字串不變的 dirty-file mutation"
else bad "deep-plan launcher 只比 HEAD/status，漏掉 dirty evidence drift"; fi
mkdir -p "$TMP/deep-plan-descendant-pids"
dps_hanging_stub="$ROOT/tests/fixtures/deep-plan-hanging-stub.py"
# `kill -0` only proves that a PID still has a process-table entry. On macOS an
# exited orphan can remain as `Z` until launchd reaps it, even though it no
# longer executes or holds the inherited pipe. Keep unknown/non-zombie states
# fail-closed, but do not report an exited zombie as a launcher leak.
pid_is_live_non_zombie() {
    local pid="$1"
    local state
    kill -0 "$pid" 2>/dev/null || return 1
    if ! state="$(ps -o stat= -p "$pid" 2>/dev/null)"; then
        # The PID can be reaped between kill -0 and ps. Only keep the
        # fail-closed verdict when a second liveness check still sees it.
        kill -0 "$pid" 2>/dev/null || return 1
        return 0
    fi
    state="${state//[[:space:]]/}"
    [[ "$state" != Z* ]]
}
dps_mock_kill_calls=0
kill() {
    dps_mock_kill_calls=$((dps_mock_kill_calls + 1))
    [ "$dps_mock_kill_calls" -eq 1 ]
}
ps() {
    return 1
}
if ! pid_is_live_non_zombie 999999; then
    ok "deep-plan cleanup gate 不把 kill／ps 間消失的 PID 誤判為 live"
else bad "deep-plan cleanup gate 對 PID 回收 race 產生 false live"; fi
unset -f kill ps
dps_timeout_out="$(DEEP_PLAN_DESCENDANT_PID_DIR="$TMP/deep-plan-descendant-pids" \
    "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$dps_hanging_stub" \
    --timeout-seconds 1)"
dps_timeout_rc=$?
dps_descendant_count="$(find "$TMP/deep-plan-descendant-pids" -name '*.pid' -type f | wc -l | tr -d ' ')"
dps_descendants_alive=0
dps_timeout_process_states=""
for pid_file in "$TMP/deep-plan-descendant-pids"/*.pid; do
    descendant_pid="$(< "$pid_file")"
    descendant_state="$(ps -o stat= -p "$descendant_pid" 2>/dev/null)"
    descendant_state="${descendant_state//[[:space:]]/}"
    [ -n "$descendant_state" ] || descendant_state="missing"
    dps_timeout_process_states="${dps_timeout_process_states}${dps_timeout_process_states:+,}${descendant_pid}:${descendant_state}"
    if pid_is_live_non_zombie "$descendant_pid"; then
        dps_descendants_alive=$((dps_descendants_alive + 1))
    fi
done
dps_timeout_has_failure_manifest=0
grep -q '"ok":false' <<< "$dps_timeout_out" && dps_timeout_has_failure_manifest=1
if [ "$dps_timeout_rc" -eq 1 ] \
    && [ "$dps_timeout_has_failure_manifest" -eq 1 ] \
    && [ "$dps_descendant_count" -eq 2 ] \
    && [ "$dps_descendants_alive" -eq 0 ]; then
    ok "deep-plan launcher timeout 會收掉 reviewer process tree，不留持 pipe descendant"
else
    echo "  timeout diagnostics: rc=$dps_timeout_rc manifest=$dps_timeout_has_failure_manifest pid_count=$dps_descendant_count live=$dps_descendants_alive states=${dps_timeout_process_states:-none} output=$dps_timeout_out" >&2
    bad "deep-plan launcher timeout 未完整 fail closed 或留下 descendant"
fi
mkdir -p "$TMP/deep-plan-cleanup-fault-pids"
dps_cleanup_fault_out="$(PYTHONPATH="$ROOT/tests/fixtures/deep-plan-cleanup-fault" \
DEEP_PLAN_DESCENDANT_PID_DIR="$TMP/deep-plan-cleanup-fault-pids" \
    "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$dps_hanging_stub" \
    --timeout-seconds 1)"
dps_cleanup_fault_rc=$?
dps_cleanup_fault_pid_count="$(find "$TMP/deep-plan-cleanup-fault-pids" -name '*.pid' -type f | wc -l | tr -d ' ')"
dps_cleanup_fault_alive=0
for pid_file in "$TMP/deep-plan-cleanup-fault-pids"/*.pid; do
    descendant_pid="$(< "$pid_file")"
    if pid_is_live_non_zombie "$descendant_pid"; then
        dps_cleanup_fault_alive=$((dps_cleanup_fault_alive + 1))
    fi
done
dps_cleanup_fault_manifest=0
python3 - "$dps_cleanup_fault_out" <<'PY' && dps_cleanup_fault_manifest=1
import json
import sys

payload = json.loads(sys.argv[1])
errors = payload.get("cleanup_errors", [])
raise SystemExit(not (
    payload.get("ok") is False
    and any(error.get("phase") == "force-signal" for error in errors)
))
PY
if [ "$dps_cleanup_fault_rc" -eq 1 ] \
    && [ "$dps_cleanup_fault_manifest" -eq 1 ] \
    && [ "$dps_cleanup_fault_pid_count" -eq 2 ] \
    && [ "$dps_cleanup_fault_alive" -eq 0 ]; then
    ok "deep-plan launcher cleanup 次級錯誤保留 canonical fail-closed manifest"
else
    echo "  cleanup fault diagnostics: rc=$dps_cleanup_fault_rc manifest=$dps_cleanup_fault_manifest pid_count=$dps_cleanup_fault_pid_count live=$dps_cleanup_fault_alive output=$dps_cleanup_fault_out" >&2
    bad "deep-plan launcher cleanup 次級錯誤逃出 canonical handler（RED）"
fi
mkdir -p "$TMP/deep-plan-signal-pids"
DEEP_PLAN_DESCENDANT_PID_DIR="$TMP/deep-plan-signal-pids" \
    "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$dps_hanging_stub" \
    --timeout-seconds 30 > "$TMP/deep-plan-signal.out" &
dps_signal_launcher_pid=$!
for _ in {1..50}; do
    dps_signal_pid_count="$(find "$TMP/deep-plan-signal-pids" -name '*.pid' -type f | wc -l | tr -d ' ')"
    [ "$dps_signal_pid_count" -eq 2 ] && break
    sleep 0.1
done
kill -HUP "$dps_signal_launcher_pid"
wait "$dps_signal_launcher_pid"
dps_signal_rc=$?
dps_signal_descendants_alive=0
dps_signal_process_states=""
for pid_file in "$TMP/deep-plan-signal-pids"/*.pid; do
    descendant_pid="$(< "$pid_file")"
    descendant_state="$(ps -o stat= -p "$descendant_pid" 2>/dev/null)"
    descendant_state="${descendant_state//[[:space:]]/}"
    [ -n "$descendant_state" ] || descendant_state="missing"
    dps_signal_process_states="${dps_signal_process_states}${dps_signal_process_states:+,}${descendant_pid}:${descendant_state}"
    if pid_is_live_non_zombie "$descendant_pid"; then
        dps_signal_descendants_alive=$((dps_signal_descendants_alive + 1))
    fi
done
dps_signal_has_failure_manifest=0
grep -q '"ok":false' "$TMP/deep-plan-signal.out" && dps_signal_has_failure_manifest=1
if [ "$dps_signal_rc" -eq 1 ] \
    && [ "$dps_signal_has_failure_manifest" -eq 1 ] \
    && [ "$dps_signal_pid_count" -eq 2 ] \
    && [ "$dps_signal_descendants_alive" -eq 0 ]; then
    ok "deep-plan launcher 收到 SIGHUP 會收掉 reviewer process tree"
else
    echo "  signal diagnostics: rc=$dps_signal_rc manifest=$dps_signal_has_failure_manifest pid_count=$dps_signal_pid_count live=$dps_signal_descendants_alive states=${dps_signal_process_states:-none} output=$(< "$TMP/deep-plan-signal.out")" >&2
    bad "deep-plan launcher signal cleanup 未 fail closed 或留下 descendant"
fi
mkdir -p "$TMP/deep-plan-single-cleanup-pids"
PYTHONPATH="$ROOT/tests/fixtures/deep-plan-wait-guard" \
DEEP_PLAN_DESCENDANT_PID_DIR="$TMP/deep-plan-single-cleanup-pids" \
    "$dps_transport" \
    --plan "$dps_fixture/docs/plans/plan.md" \
    --repo "$dps_fixture" \
    --brief "$DPS_CODEX/references/planner-brief.md" \
    --schema "$DPS_CODEX/assets/reviewer-output.schema.json" \
    --codex-bin "$dps_hanging_stub" \
    --timeout-seconds 30 > "$TMP/deep-plan-single-cleanup.out" 2>&1 &
dps_single_cleanup_launcher_pid=$!
for _ in {1..50}; do
    dps_single_cleanup_pid_count="$(find "$TMP/deep-plan-single-cleanup-pids" -name '*.pid' -type f | wc -l | tr -d ' ')"
    [ "$dps_single_cleanup_pid_count" -eq 2 ] && break
    sleep 0.1
done
kill -HUP "$dps_single_cleanup_launcher_pid"
wait "$dps_single_cleanup_launcher_pid"
dps_single_cleanup_rc=$?
dps_single_cleanup_alive=0
for pid_file in "$TMP/deep-plan-single-cleanup-pids"/*.pid; do
    descendant_pid="$(< "$pid_file")"
    if pid_is_live_non_zombie "$descendant_pid"; then
        dps_single_cleanup_alive=$((dps_single_cleanup_alive + 1))
    fi
done
dps_single_cleanup_manifest=0
python3 - "$TMP/deep-plan-single-cleanup.out" <<'PY' && dps_single_cleanup_manifest=1
import json
from pathlib import Path
import sys

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
raise SystemExit(payload.get("ok") is not False)
PY
if [ "$dps_single_cleanup_rc" -eq 1 ] \
    && [ "$dps_single_cleanup_manifest" -eq 1 ] \
    && [ "$dps_single_cleanup_pid_count" -eq 2 ] \
    && [ "$dps_single_cleanup_alive" -eq 0 ]; then
    ok "deep-plan launcher signal path 只執行一次 cleanup"
else
    echo "  single cleanup diagnostics: rc=$dps_single_cleanup_rc manifest=$dps_single_cleanup_manifest pid_count=$dps_single_cleanup_pid_count live=$dps_single_cleanup_alive output=$(< "$TMP/deep-plan-single-cleanup.out")" >&2
    bad "deep-plan launcher signal handler 重複 cleanup（RED）"
fi
