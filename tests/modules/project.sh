#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 12c. project skill 跨 Claude Code／Codex 共用核心"
python3 "$ROOT/tests/project-reference-metrics-test.py" >"$TMP/project-reference-metrics-test.out" 2>&1
project_metrics_rc=$?
assert_rc "project native trace normalizer：完整末行／partial／重讀／截斷有效性／cache 計費" 0 "$project_metrics_rc"
python3 "$ROOT/tests/session-skills-host-mcp-test.py" >"$TMP/session-skills-host-mcp-test.out" 2>&1
session_skills_transport_rc=$?
assert_rc "session skill eval transport：私人路徑 probe 不執行／fixture output 不截斷／exit 保真" 0 "$session_skills_transport_rc"
python3 -B "$ROOT/tests/project-handover-grade-test.py" >"$TMP/project-handover-grade-test.out" 2>&1
handover_grade_rc=$?
assert_rc "project handover grader：全過／缺字串或 ID／路徑須引用且存在／指令失敗／格式錯誤 BROKEN" 0 "$handover_grade_rc"
PJS_CLAUDE="$ROOT/claude/skills/project"
PJS_CODEX="$ROOT/codex/skills/project"
project_scripts_shared=1
for script_name in bootstrap-baseline.sh branch-first.sh cleanup-stale-branch.sh doc-governance.py read-reference.py ship-state.sh grade-handover.py wait-required-enrollment.sh; do
    [ "$PJS_CLAUDE/scripts/$script_name" -ef "$ROOT/shared/skills/project/scripts/$script_name" ] \
        && [ "$PJS_CODEX/scripts/$script_name" -ef "$ROOT/shared/skills/project/scripts/$script_name" ] \
        || project_scripts_shared=0
done
if [ -f "$PJS_CLAUDE/SKILL.md" ] && [ -f "$PJS_CODEX/SKILL.md" ] \
    && [ "$PJS_CLAUDE/references" -ef "$ROOT/shared/skills/project/references" ] \
    && [ "$PJS_CODEX/references" -ef "$ROOT/shared/skills/project/references" ] \
    && [ "$project_scripts_shared" -eq 1 ] \
    && [ "$PJS_CLAUDE/templates" -ef "$ROOT/shared/skills/project/templates" ] \
    && [ "$PJS_CODEX/templates" -ef "$ROOT/shared/skills/project/templates" ] \
    && [ "$PJS_CODEX/scripts/doc-governance.py" -ef "$ROOT/scripts/doc-governance.py" ]; then
    ok "project 兩個薄入口共用 canonical references/scripts/templates"
else bad "project 跨 runtime 封裝未共用同一核心"; fi
if grep -q 'references/workflow.md' "$PJS_CLAUDE/SKILL.md" \
    && grep -q 'references/workflow.md' "$PJS_CODEX/SKILL.md" \
    && [ -f "$PJS_CODEX/references/workflow.md" ]; then
    ok "project 兩個入口都載入 shared workflow"
else bad "project 入口未共同指向 shared workflow"; fi
project_step0="$(sed -n '/^### 多 Repo 偵測（無 repo 引數時）/,/^## Step 1：/p' "$PJS_CLAUDE/references/log-workflow.md")"
if grep -q 'Scenario 25 — 多 repo 確認可直接選全部偵測結果' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q '全部偵測到的 repos（建議）' <<< "$project_step0" \
    && grep -q '同一次 Project invocation' <<< "$project_step0" \
    && grep -q '不得要求重新輸入' <<< "$project_step0"; then
    ok "project 多 repo Step 0 明列全選路徑且不重建 invocation"
else bad "project 多 repo Step 0 未把『全部偵測到』做成可直接續行的確認選項"; fi
if grep -q 'Scenario 36 — Spec 後的 multi-repo' \
        "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q 'closed repo-set evidence' <<< "$project_step0" \
    && grep -q '完全相同.*不顯示.*確認路徑' <<< "$project_step0" \
    && grep -q '只詢問 repo-set delta' <<< "$project_step0" \
    && grep -q '不得授予 shipping authorization' <<< "$project_step0"; then
    ok "project Step 0 沿用已重驗且未變的 closed repo set"
else bad "project Step 0 未沿用已重驗且未變的 closed repo set"; fi
pjs_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$PJS_CODEX/SKILL.md")"
if ! grep -Eq '^(user-invocable|disable-model-invocation|argument-hint|allowed-tools|context|agent):' <<< "$pjs_codex_frontmatter"; then
    ok "Codex project frontmatter 無 Claude Code 專屬欄位"
else bad "Codex project frontmatter 混入 Claude Code 專屬欄位"; fi
project_sig="\$project"
if grep -q '^disable-model-invocation: true$' "$PJS_CLAUDE/SKILL.md" \
    && grep -q '^  allow_implicit_invocation: false$' "$PJS_CODEX/agents/openai.yaml" \
    && grep -qF "$project_sig" "$PJS_CODEX/agents/openai.yaml"; then
    ok "project 在兩個 runtime 都是 explicit-only"
else bad "project 的 explicit-only policy 未跨 runtime 對齊"; fi
runtime_tilde='~'
if ! rg -q "${runtime_tilde}/\\.dotfiles|${runtime_tilde}/.+(claude|codex)/skills/project|Generated with \\[Claude Code\\]" \
    "$PJS_CLAUDE/SKILL.md" "$PJS_CLAUDE/references/workflow.md" \
    "$PJS_CLAUDE/references/dossier.md" "$PJS_CLAUDE/references/log-workflow.md" \
    "$PJS_CLAUDE/references/ship-paths.md" \
    "$PJS_CLAUDE/scripts"; then
    ok "project runtime core 無私人安裝路徑或產品 attribution 偶合"
else bad "project runtime core 仍含私人／harness-specific path 或 attribution"; fi
if grep -q 'repo contract.*優先' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q '沒有.*Conventional Commits.*fallback' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q 'repo contract.*PR title' "$PJS_CLAUDE/references/ship-paths.md" \
    && ! rg -q 'Step 3 只會產生 `docs:`|<type>/<slug>|type 取自.*feat/fix|commit -m "<type>:|^<type>: <精簡描述>' \
        "$PJS_CLAUDE/references/log-prepare.md" "$PJS_CLAUDE/references/ship-paths.md" \
        "$PJS_CLAUDE/scripts/branch-first.sh" "$PJS_CLAUDE/scripts/ship-state.sh"; then
    ok "project commit／PR title 以 target repo convention 優先"
else bad "project commit／PR title 未明定 repo convention 優先與 fallback"; fi
project_continuity="$(sed -n '/^## 接續（內容契約）/,/^## /p' "$PJS_CLAUDE/references/dossier.md")"
if grep -q '不靠 actor 身分' <<< "$project_continuity" \
    && grep -q 'Goal.、.進度.、.下一步' <<< "$project_continuity" \
    && grep -q 'branch 不存在或已合併' <<< "$project_continuity" \
    && grep -q '邀請，不是佔用' <<< "$project_continuity"; then
    ok "project 接續以 active state 內容契約承擔，不依 actor 身分"
else bad "project 接續缺內容契約（Goal／進度／下一步、branch 核對、下一步不是佔用）"; fi

project_step2_and_3="$(sed -n '/^## Step 2：/,/^## Step 4：/p' \
    "$PJS_CLAUDE/references/log-prepare.md")"
if grep -q 'endpoint 尚未達成時不得.*shipped' <<< "$project_step2_and_3"; then
    ok "project milestone 不在 endpoint 達成前宣稱 shipped"
else bad "project milestone 可在 endpoint 達成前宣稱 shipped"; fi
project_step4="$(sed -n '/^## Step 4：/,/^## Step 5：/p' \
    "$PJS_CLAUDE/references/log-prepare.md")"
if grep -q 'summary-emitted: yes' <<< "$project_step4" \
    && grep -q '當前 invocation.*user-visible' <<< "$project_step4" \
    && grep -q 'post-push.*不算' <<< "$project_step4" \
    && grep -q 'explicit.*merge.*不能省略摘要' <<< "$project_step4"; then
    ok "project Step 4 摘要必須在當前 invocation 的第一個 outward action 前可見"
else bad "project Step 4 摘要仍可能延後到 push 之後"; fi
project_step5="$(sed -n '/^## Step 5：/,$p' \
    "$PJS_CLAUDE/references/log-prepare.md")"
if grep -q '進入條件' <<< "$project_step5" \
    && grep -q 'immediately preceding assistant content' <<< "$project_step5" \
    && grep -q '必須以.*Ship 摘要：.*開頭' <<< "$project_step5" \
    && grep -q 'canonical repo root' <<< "$project_step5" \
    && grep -q 'repo root:' <<< "$project_step4" \
    && grep -q '狀態更新' <<< "$project_step5" \
    && grep -q '不算 Ship 摘要' <<< "$project_step5" \
    && grep -q '不滿足.*不得進入.*outward' <<< "$project_step5"; then
    ok "project Step 5 以緊鄰 literal Ship 摘要作為 outward entry condition"
else bad "project Step 5 可把一般 gate 狀態更新誤當成送出前摘要"; fi

project_runtime_adapter="$(sed -n '/^## Runtime adapter/,/^## /p' "$PJS_CLAUDE/references/workflow.md")"
if grep -q 'Scenario 35 — 文字 fallback 保留完整編號選項' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q '2–3 個.*編號選項' <<< "$project_runtime_adapter" \
    && grep -q '完整動作與後果' <<< "$project_runtime_adapter" \
    && grep -q '建議項.*第一' <<< "$project_runtime_adapter" \
    && grep -q '不得只要求.*確認.*停止' <<< "$project_runtime_adapter" \
    && grep -q '不新增.*預檢\|不改變.*詢問時機' <<< "$project_runtime_adapter"; then
    ok "project 文字 fallback 保留完整編號選項且不增加正常路徑成本"
else bad "project 文字 fallback 仍可退化成確認／停止關鍵字或擴張預檢"; fi

project_spec_completion="$(sed -n '/^### Spec 成功後的 Log invocation 提示/,/^## /p' "$PJS_CLAUDE/references/spec-workflow.md")"
if grep -qF "\$project --merge" <<< "$project_spec_completion" \
    && grep -qF "Claude Code adapter 將 \`\$project\` 換成 \`/project\`" <<< "$project_spec_completion" \
    && grep -q 'endpoint authorization' <<< "$project_spec_completion" \
    && grep -q '不 carry' <<< "$project_spec_completion" \
    && grep -q '未選定就不得自行預填' <<< "$project_spec_completion"; then
    ok "project Spec 收尾只提示命令，不 carry 已結束 invocation 的 endpoint 授權"
else bad "project Spec 收尾未區分命令提示與新 endpoint 授權"; fi
project_check_routing="$(sed -n '/^### merge 受阻時的分流/,/^## PR title/p' "$PJS_CLAUDE/references/merge-workflow.md")"
project_no_checks_scenario="$(sed -n '/^## Scenario 29 /,/^## Scenario 30 /p' "$PJS_CLAUDE/references/pressure-tests.md")"
project_eval_root="$TMP/project-no-checks-eval"
"$ROOT/claude/evals/setup-sandboxes.sh" "$project_eval_root" gate u4 >/dev/null
assert_rc "project eval builder 可只建立 u4 fixture" 0 $?
project_u4="$project_eval_root/u4-gate"
project_checks_out="$("$project_u4/gh-stub-blocked" pr checks 7 --required 2>&1)"
assert_rc "u4 全綠 control → checks exit 0" 0 $?
if grep -q $'unit-tests\tpass' <<< "$project_checks_out"; then
    ok "u4 全綠 control 輸出 pass row"
else bad "u4 全綠 control 缺 pass row（${project_checks_out}）"; fi
project_checks_out="$("$project_u4/gh-stub-blocked-pending" pr checks 7 --required 2>&1)"
assert_rc "u4 pending control → checks exit 8" 8 $?
if grep -q $'unit-tests\tpending' <<< "$project_checks_out"; then
    ok "u4 pending control 輸出 pending row"
else bad "u4 pending control 缺 pending row（${project_checks_out}）"; fi
project_checks_out="$("$project_u4/gh-stub-blocked-no-checks" pr checks 7 --required 2>&1)"
assert_rc "u4 no-checks control → checks exit 1" 1 $?
assert_eq "u4 no-checks control 輸出 exact gh 訊息" \
    "no checks reported on the 'feat/rate-limit' branch" "$project_checks_out"
project_state_out="$("$project_u4/gh-stub-blocked-no-checks" pr view 7 --json mergeStateStatus -q .mergeStateStatus)"
assert_eq "u4 no-checks control 與 Scenario 15 同為 BLOCKED" "BLOCKED" "$project_state_out"
project_policy_out="$(SHIP_STATE_GH="$project_u4/gh-stub-blocked-no-checks" \
    "$PJS_CLAUDE/scripts/ship-state.sh" "$project_u4/work")"
if grep -q 'required-policy: none' <<< "$project_policy_out"; then
    ok "u4 no-checks control 同時提供 required-policy none"
else bad "u4 no-checks control 未形成 no-checks + required-policy none（${project_policy_out}）"; fi

project_enrollment_wait="$PJS_CLAUDE/scripts/wait-required-enrollment.sh"
project_enrollment_scenario="$(sed -n '/^## Scenario 32 /,/^## Scenario 30 /p' "$PJS_CLAUDE/references/pressure-tests.md")"
mkdir -p "$project_eval_root/no-sleep"
cat > "$project_eval_root/no-sleep/sleep" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$project_eval_root/no-sleep/sleep"
project_head_sha="$(git -C "$project_u4/work" rev-parse HEAD)"
rm -f "$project_u4/gh-stub-enrollment.checks-count"
project_enrollment_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_u4/gh-stub-enrollment" \
    "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
project_enrollment_rc=$?
assert_rc "project startup enrollment: no-checks 後同 head check 出現" 0 "$project_enrollment_rc"
if grep -q '^verdict: ENROLLED$' <<< "$project_enrollment_out" \
    && grep -q '^attempts: 3/13$' <<< "$project_enrollment_out" \
    && grep -q '^run-observed: yes$' <<< "$project_enrollment_out" \
    && grep -q '^checks-exit: 8$' <<< "$project_enrollment_out"; then
    ok "project enrollment helper 只在對應 run/check 出現後交回既有 watch 路徑"
else bad "project enrollment helper 沒有保留有界、identity-bound 證據（${project_enrollment_out}）"; fi
project_watch_out="$("$project_u4/gh-stub-enrollment" pr checks 7 -R sandbox/order-service \
    --required --watch --interval 15 --fail-fast 2>&1)"
project_watch_rc=$?
assert_rc "project enrollment 後沿用 checks watch" 0 "$project_watch_rc"
project_final_out="$("$project_u4/gh-stub-enrollment" pr checks 7 -R sandbox/order-service --required 2>&1)"
project_final_rc=$?
assert_rc "project watch 後 authoritative non-watch 全綠" 0 "$project_final_rc"
if grep -q $'unit-tests\tpass' <<< "$project_watch_out" \
    && grep -q $'unit-tests\tpass' <<< "$project_final_out"; then
    ok "project enrollment 組合路徑保留 watch + final non-watch verification"
else bad "project enrollment 組合路徑缺 watch 或 final verdict"; fi

project_required_empty_stub="$project_u4/gh-stub-enrollment-required-empty"
rm -f "$project_required_empty_stub.checks-count"
project_required_empty_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_required_empty_stub" \
    "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
project_required_empty_rc=$?
assert_rc "project enrollment: gh 2.101 required-only empty state 進入 lifecycle" \
    0 "$project_required_empty_rc"
if grep -q '^verdict: ENROLLED$' <<< "$project_required_empty_out" \
    && grep -q '^attempts: 3/13$' <<< "$project_required_empty_out" \
    && grep -q '^run-observed: yes$' <<< "$project_required_empty_out" \
    && grep -q '^checks-exit: 8$' <<< "$project_required_empty_out"; then
    ok "project enrollment 精確接受 no required checks 與含單引號 branch"
else bad "project enrollment 把新版 gh empty state 誤判為 query error（${project_required_empty_out}）"; fi

project_unknown_empty_stub="$project_u4/gh-stub-enrollment-unknown-empty"
rm -f "$project_unknown_empty_stub.checks-count"
project_unknown_empty_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_unknown_empty_stub" \
    "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
project_unknown_empty_rc=$?
assert_rc "project enrollment: unknown exit-1 output 仍 fail closed" \
    2 "$project_unknown_empty_rc"
if grep -q '^verdict: QUERY_ERROR$' <<< "$project_unknown_empty_out" \
    && grep -q '^stage: required-checks$' <<< "$project_unknown_empty_out" \
    && grep -q '^detail: unexpected required checks response$' <<< "$project_unknown_empty_out"; then
    ok "project enrollment 不把任意 exit 1 當 pending"
else bad "project enrollment unknown exit-1 未保留 QUERY_ERROR 證據（${project_unknown_empty_out}）"; fi

rm -f "$project_u4/gh-stub-delayed-enrollment.checks-count"
project_delayed_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_u4/gh-stub-delayed-enrollment" \
    "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
project_delayed_rc=$?
assert_rc "project dependency-gated aggregation: active run 超過 startup grace 後仍等到 check" \
    0 "$project_delayed_rc"
if grep -q '^verdict: ENROLLED$' <<< "$project_delayed_out" \
    && grep -q '^attempts: 16/13$' <<< "$project_delayed_out" \
    && grep -q '^run-observed: yes$' <<< "$project_delayed_out" \
    && grep -q '^active-run-observed: yes$' <<< "$project_delayed_out" \
    && grep -q '^checks-exit: 8$' <<< "$project_delayed_out"; then
    ok "project enrollment 以 exact-head active run 延續觀察，不任意加長 startup grace"
else bad "project enrollment 未辨識 dependency-gated active run（${project_delayed_out}）"; fi
project_delayed_watch_out="$("$project_u4/gh-stub-delayed-enrollment" pr checks 7 \
    -R sandbox/order-service --required --watch --interval 15 --fail-fast 2>&1)"
project_delayed_watch_rc=$?
assert_rc "project delayed enrollment 後沿用 checks watch" 0 "$project_delayed_watch_rc"
project_delayed_final_out="$("$project_u4/gh-stub-delayed-enrollment" pr checks 7 \
    -R sandbox/order-service --required 2>&1)"
project_delayed_final_rc=$?
assert_rc "project delayed watch 後 authoritative non-watch 全綠" 0 "$project_delayed_final_rc"
project_delayed_state_out="$("$project_u4/gh-stub-delayed-enrollment" pr view 7 \
    -R sandbox/order-service --json mergeStateStatus -q .mergeStateStatus)"
if grep -q $'unit-tests\tpass' <<< "$project_delayed_watch_out" \
    && grep -q $'unit-tests\tpass' <<< "$project_delayed_final_out" \
    && [ "$project_delayed_state_out" = CLEAN ]; then
    ok "project delayed enrollment 保留 watch + final non-watch + fresh merge-state gate"
else bad "project delayed enrollment 缺完整 post-enrollment gate"; fi

for project_run_terminal in failure cancelled; do
    project_run_stub="$project_u4/gh-stub-run-$project_run_terminal"
    rm -f "$project_run_stub.checks-count"
    project_run_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
        PROJECT_ENROLLMENT_GH="$project_run_stub" \
        "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
    project_run_rc=$?
    assert_rc "project active run $project_run_terminal 且 check 缺席 → fail closed" \
        4 "$project_run_rc"
    if grep -q '^verdict: RUN_TERMINAL$' <<< "$project_run_out" \
        && grep -q "^run-conclusions: $project_run_terminal$" <<< "$project_run_out"; then
        ok "project enrollment 揭露 exact-head run ${project_run_terminal}，不誤報 QUERY_ERROR"
    else bad "project enrollment 未正確分類 run ${project_run_terminal}（${project_run_out}）"; fi
done

project_run_success_stub="$project_u4/gh-stub-run-success"
rm -f "$project_run_success_stub.checks-count"
project_run_success_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_run_success_stub" \
    "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
project_run_success_rc=$?
assert_rc "project successful run without required check remains UNOBSERVED" \
    1 "$project_run_success_rc"
if grep -q '^verdict: UNOBSERVED$' <<< "$project_run_success_out" \
    && grep -q '^run-observed: yes$' <<< "$project_run_success_out" \
    && grep -q '^active-run-observed: yes$' <<< "$project_run_success_out"; then
    ok "project run success is waiting evidence, never the required-check verdict"
else bad "project successful run incorrectly substituted for required check（${project_run_success_out}）"; fi

project_run_malformed_stub="$project_u4/gh-stub-run-malformed"
rm -f "$project_run_malformed_stub.checks-count"
project_run_malformed_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_run_malformed_stub" \
    "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
project_run_malformed_rc=$?
assert_rc "project malformed exact-head run evidence → QUERY_ERROR" \
    2 "$project_run_malformed_rc"
if grep -q '^verdict: QUERY_ERROR$' <<< "$project_run_malformed_out" \
    && grep -q '^stage: run-list$' <<< "$project_run_malformed_out" \
    && grep -q '^detail:' <<< "$project_run_malformed_out"; then
    ok "project malformed run evidence fails closed with stage and detail"
else bad "project malformed run evidence was not classified as query error（${project_run_malformed_out}）"; fi

rm -f "$project_u4/gh-stub-never-enrollment.checks-count"
project_never_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_u4/gh-stub-never-enrollment" \
    "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
project_never_rc=$?
assert_rc "project startup enrollment: grace 內真正未觸發 → UNOBSERVED" 1 "$project_never_rc"
if grep -q '^verdict: UNOBSERVED$' <<< "$project_never_out" \
    && grep -q '^attempts: 13/13$' <<< "$project_never_out" \
    && grep -q '^run-observed: no$' <<< "$project_never_out"; then
    ok "project enrollment grace 有界且逾期 fail closed"
else bad "project enrollment grace 逾期未來到 UNOBSERVED（${project_never_out}）"; fi

rm -f "$project_u4/gh-stub-enrollment-transport.checks-count"
project_transport_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_u4/gh-stub-enrollment-transport" \
    "$project_enrollment_wait" sandbox/order-service 7 "$project_head_sha" 2>&1)"
project_transport_rc=$?
assert_rc "project startup enrollment: run-list transport error 立即 STOP" 2 "$project_transport_rc"
if grep -q '^verdict: QUERY_ERROR$' <<< "$project_transport_out" \
    && grep -q '^stage: run-list$' <<< "$project_transport_out" \
    && grep -q '^detail:' <<< "$project_transport_out"; then
    ok "project enrollment 不重試 transport failure"
else bad "project enrollment transport failure 未 fail closed（${project_transport_out}）"; fi

project_head_out="$(PATH="$project_eval_root/no-sleep:$PATH" \
    PROJECT_ENROLLMENT_GH="$project_u4/gh-stub-enrollment" \
    "$project_enrollment_wait" sandbox/order-service 7 0000000000000000000000000000000000000000 2>&1)"
project_head_rc=$?
assert_rc "project startup enrollment: PR head 不符 expected SHA → STOP" 3 "$project_head_rc"
if grep -q '^verdict: HEAD_CHANGED$' <<< "$project_head_out"; then
    ok "project enrollment 不把其他 head 的 run/check 當成命中"
else bad "project enrollment 缺 head identity fail-closed 證據（${project_head_out}）"; fi

if grep -q 'shared deterministic enrollment helper' <<< "$project_enrollment_scenario" \
    && grep -q 'fixed 13-observation startup grace' <<< "$project_enrollment_scenario" \
    && grep -q 'lifecycle-bound route' <<< "$project_enrollment_scenario" \
    && grep -q 'RUN_TERMINAL' <<< "$project_enrollment_scenario" \
    && grep -q 'approval UI call count is 0' <<< "$project_enrollment_scenario" \
    && grep -q 'wait-required-enrollment.sh' <<< "$project_check_routing" \
    && grep -q 'startup enrollment' <<< "$project_check_routing" \
    && grep -q '13.*observation.*5' <<< "$project_check_routing" \
    && grep -q 'RUN_TERMINAL' <<< "$project_check_routing" \
    && grep -q 'stage.*detail' <<< "$project_check_routing" \
    && grep -q 'final non-watch' <<< "$project_check_routing"; then
    ok "project shipping contract 區分 startup、active-run、terminal 與 query error"
else bad "project shipping contract 尚未接上 lifecycle-aware enrollment 與原有終態 gate"; fi

"$ROOT/claude/evals/setup-sandboxes.sh" "$project_eval_root" b19 project-pressure >/dev/null
assert_rc "project eval builder 可獨立建立 S8/S9/S10/S12 fixtures" 0 $?
project_s8="$project_eval_root/s8-b19"
project_s9="$project_eval_root/s9-b19"
project_s10="$project_eval_root/s10-b19"
project_s12="$project_eval_root/s12-b19"

assert_eq "S8 重用 u4 形狀：feature branch 已 push" \
    $'0\t0' "$(git -C "$project_s8/work" rev-list --left-right --count '@{upstream}...HEAD')"
assert_eq "S8 重用 u4 形狀：相對 main 有三顆語意/review commits" \
    "3" "$(git -C "$project_s8/work" rev-list --count origin/main..HEAD)"
assert_eq "S8 gh stub 提供已開 PR" \
    "https://github.com/sandbox/order-service/pull/7" \
    "$("$project_s8/gh-stub" pr view feat/rate-limit --json url -q .url)"

assert_eq "S9 起點仍在 main" "main" "$(git -C "$project_s9/work" branch --show-current)"
assert_eq "S9 working tree 只有 README typo 修正" \
    "README.md" "$(git -C "$project_s9/work" diff --name-only)"
project_s9_state="$(SHIP_STATE_GH="$project_s9/gh-stub" "$PJS_CLAUDE/scripts/ship-state.sh" "$project_s9/work")"
if grep -q '^protection: UNKNOWN' <<< "$project_s9_state"; then
    ok "S9 protection UNKNOWN 由 stub 穩定產生"
else bad "S9 未形成 protection UNKNOWN（${project_s9_state}）"; fi

if git -C "$project_s10/work" check-ignore -q .env \
    && [ -z "$(git -C "$project_s10/work" ls-files -- .env)" ]; then
    ok "S10 .env 被 ignore 且未 tracked"
else bad "S10 .env 未與 Git 完整分離"; fi
if grep -q '^PAYMENTS_API_KEY=fixture-only-' "$project_s10/work/.env" \
    && grep -q '^VECTOR_DB_TOKEN=fixture-only-' "$project_s10/work/.env" \
    && ! grep -qE '^(PAYMENTS_API_KEY|VECTOR_DB_TOKEN)=' "$project_s10/work/.env.example"; then
    ok "S10 假 credentials 齊全，.env.example 精確缺兩個 key 名稱"
else bad "S10 credential coverage 形狀不符 scenario"; fi
assert_eq "S10 repo-local credential artifact 刻意以 0644 起始" \
    "644" "$(stat -c '%a' "$project_s10/work/tmp/transfer-credentials.md" 2>/dev/null || stat -f '%Lp' "$project_s10/work/tmp/transfer-credentials.md" 2>/dev/null)"

project_transfer_credential_audit="$PJS_CLAUDE/scripts/verify-transfer-credential.sh"
if [ -x "$project_transfer_credential_audit" ]; then
    project_credential_out="$("$project_transfer_credential_audit" \
        "$project_s10/work" tmp/transfer-credentials.md 2>&1)"
    project_credential_rc=$?
    assert_rc "project transfer credential artifact 0644 → STOP" 1 "$project_credential_rc"
    if grep -q '^verdict: STOP$' <<< "$project_credential_out" \
        && grep -q '^mode: 644$' <<< "$project_credential_out" \
        && ! grep -q 'fixture-only-' <<< "$project_credential_out"; then
        ok "project credential audit 只回 metadata，不洩漏值"
    else bad "project credential audit 的 0644 證據或輸出隔離不成立（${project_credential_out}）"; fi

    chmod 0600 "$project_s10/work/tmp/transfer-credentials.md"
    project_credential_out="$("$project_transfer_credential_audit" \
        "$project_s10/work" tmp/transfer-credentials.md 2>&1)"
    project_credential_rc=$?
    assert_rc "project transfer credential artifact 0600 + ignored + untracked → PASS" 0 "$project_credential_rc"
    if grep -q '^verdict: PASS$' <<< "$project_credential_out" \
        && grep -q '^mode: 600$' <<< "$project_credential_out"; then
        ok "project credential audit 接受 private mode"
    else bad "project credential audit 未接受合格 artifact（${project_credential_out}）"; fi

    printf 'fixture-only-unignored-secret\n' > "$project_s10/work/unignored-credentials.md"
    project_credential_out="$("$project_transfer_credential_audit" \
        "$project_s10/work" unignored-credentials.md 2>&1)"
    assert_rc "project transfer credential artifact 未 ignore → STOP" 1 $?
    if grep -q '^reason: artifact-is-not-ignored$' <<< "$project_credential_out"; then
        ok "project credential audit 未 ignore 的停止原因正確"
    else bad "project credential audit 未 ignore 的停止原因不符（${project_credential_out}）"; fi

    # tmp/ 已被 ignore，但被 git add -f 收進 index：仍須擋下，且先於 ignore 判定
    printf 'fixture-only-tracked-secret\n' > "$project_s10/work/tmp/tracked-credentials.md"
    chmod 0600 "$project_s10/work/tmp/tracked-credentials.md"
    git -C "$project_s10/work" add -f tmp/tracked-credentials.md
    project_credential_out="$("$project_transfer_credential_audit" \
        "$project_s10/work" tmp/tracked-credentials.md 2>&1)"
    project_credential_rc=$?
    git -C "$project_s10/work" rm -q --cached tmp/tracked-credentials.md
    assert_rc "project transfer credential artifact 已 tracked → STOP" 1 "$project_credential_rc"
    if grep -q '^reason: artifact-is-tracked$' <<< "$project_credential_out" \
        && ! grep -q 'fixture-only-' <<< "$project_credential_out"; then
        ok "project credential audit 已 tracked 的停止原因正確且不洩漏值"
    else bad "project credential audit 已 tracked 的停止原因不符（${project_credential_out}）"; fi

    ln -s ../.env "$project_s10/work/tmp/symlink-credentials.md"
    project_credential_out="$("$project_transfer_credential_audit" \
        "$project_s10/work" tmp/symlink-credentials.md 2>&1)"
    assert_rc "project transfer credential artifact 是 symlink → STOP" 1 $?

    mkdir -p "$project_s10/gnu-stat-bin"
    cat > "$project_s10/gnu-stat-bin/stat" <<'EOF'
#!/usr/bin/env bash
case "${1:-}:${2:-}" in
    '-f:%Lp')
        printf 'GNU stat filesystem output before option failure\n'
        exit 1
        ;;
    '-c:%a')
        printf '644\n'
        exit 0
        ;;
    *) exit 2 ;;
esac
EOF
    chmod +x "$project_s10/gnu-stat-bin/stat"
    project_credential_out="$(PATH="$project_s10/gnu-stat-bin:$PATH" \
        "$project_transfer_credential_audit" "$project_s10/work" tmp/transfer-credentials.md 2>&1)"
    project_credential_rc=$?
    if [ "$project_credential_rc" -eq 1 ] \
        && grep -q '^reason: group-or-other-permissions-present$' <<< "$project_credential_out" \
        && ! grep -q 'mode-malformed\|fixture-only-' <<< "$project_credential_out"; then
        ok "project credential audit 隔離 GNU stat -f 失敗前的 stdout"
    else bad "project credential audit 被 GNU stat -f stdout 污染（rc=${project_credential_rc}; ${project_credential_out}）"; fi
else
    bad "project transfer credential metadata helper 尚未實作（RED）"
fi

if grep -q 'verify-transfer-credential.sh' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q 'private mode' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q 'private mode' "$PJS_CLAUDE/templates/transfer-guide-template.md"; then
    ok "project transfer workflow 與模板接上 credential metadata gate"
else bad "project transfer credential metadata gate 尚未接上 workflow／模板（RED）"; fi

project_s12_lines="$(wc -l < "$project_s12/work/STATUS.md" | tr -d ' ')"
project_s12_bytes="$(wc -c < "$project_s12/work/STATUS.md" | tr -d ' ')"
if [ "$project_s12_lines" -lt 300 ] && [ "$project_s12_bytes" -gt 30720 ]; then
    ok "S12 低行數／高 bytes 前提成立"
else bad "S12 尺寸前提失效（${project_s12_lines} lines / ${project_s12_bytes} bytes）"; fi
project_s12_state="$(SHIP_STATE_GH="$project_s12/gh-stub" "$PJS_CLAUDE/scripts/ship-state.sh" "$project_s12/work")"
for project_s12_signal in \
    'dossier-flag: 全檔 .* bytes > 30720' \
    'dossier-sections: 進行中 .* \(7[0-9]%\)' \
    'dossier-flag: 最長行 .* bytes > 1000' \
    'dossier-flag: 決策/里程碑節最大條目 .* bytes > 800.*拆成多條'; do
    if grep -qE "$project_s12_signal" <<< "$project_s12_state"; then
        ok "S12 四類訊號：${project_s12_signal}"
    else bad "S12 缺少訊號：${project_s12_signal}（${project_s12_state}）"; fi
done

if grep -q 'Scenario 29 — checks watch 的 transport failure 不得冒充 check verdict' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q 'gh-stub-blocked-no-checks' <<< "$project_no_checks_scenario" \
    && grep -q 'exit 1 有三個' <<< "$project_check_routing" \
    && grep -q 'transport.*API.*query failure' <<< "$project_check_routing" \
    && grep -q 'non-watch' <<< "$project_check_routing" \
    && grep -q '既不.*失敗.*也不.*全綠' <<< "$project_check_routing" \
    && grep -q '\-\-watch.*poller' <<< "$project_check_routing"; then
    ok "project checks watch 將 transport failure 分流為不確定並用 non-watch recheck 定案"
else bad "project checks watch 仍可能把 transport failure 誤當 required-check verdict"; fi
project_bootstrap_contract="$(sed -n '/^## Bootstrap：/,/^## Branch protection/p' "$PJS_CLAUDE/references/ship-exceptions.md")"
if grep -q 'Scenario 30 — 空 repo 首次 merge 不得把 feature branch 升成 default' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q 'bootstrap-baseline.sh' <<< "$project_bootstrap_contract" \
    && grep -q 'ship-state.sh --bootstrap-default' <<< "$project_bootstrap_contract" \
    && grep -q '第一項是安全預設' <<< "$project_bootstrap_contract" \
    && grep -q '暫停並先整理 baseline' <<< "$project_bootstrap_contract" \
    && grep -q '目前 HEAD full SHA' <<< "$project_bootstrap_contract" \
    && grep -q 'required-policy: REQUIRED' <<< "$project_check_routing" \
    && grep -q 'UNOBSERVED' <<< "$project_check_routing" \
    && grep -q 'wait-required-enrollment.sh' <<< "$project_check_routing" \
    && grep -q '重新取得.*required-policy' "$PJS_CLAUDE/references/log-prepare.md"; then
    ok "project 空 repo bootstrap 採確認型 baseline UX、effective policy 與 post-push re-detection"
else bad "project 空 repo bootstrap contract 未完整接上 #153 state machine"; fi
project_transfer="$PJS_CLAUDE/references/transfer-workflow.md"
if grep -q 'portable-knowledge' "$project_transfer" \
    && grep -q '不 commit、不 push、不 merge' "$project_transfer" \
    && grep -q '未指名接手者' "$project_transfer" \
    && grep -q '在途工作未合併也未明確放棄' "$project_transfer" \
    && grep -q 'authorization 不隨移交' "$project_transfer"; then
    ok "project transfer 以 portable-knowledge audit 與移交未完成條件產出草稿，不 commit"
else bad "project transfer 缺 portable-knowledge audit、移交未完成條件或 no-commit 邊界"; fi
project_spec_sig="\$project spec"
project_transfer_sig="\$project transfer"
ready4quit_sig="\$ready4quit"
if grep -qF "$project_spec_sig" "$ROOT/codex/AGENTS.md" \
    && grep -qF "$project_transfer_sig" "$ROOT/codex/AGENTS.md" \
    && grep -qF "$ready4quit_sig" "$ROOT/codex/AGENTS.md"; then
    ok "Codex 全域 contract 提示 explicit project／ready4quit 入口"
else bad "Codex 全域 contract 缺 explicit workflow pointers"; fi
