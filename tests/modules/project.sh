#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 12c. project skill 跨 Claude Code／Codex 共用核心"
if python3 "$ROOT/tests/project-test-evidence-test.py" >"$TMP/project-test-evidence-test.out" 2>&1; then
    ok "project test evidence：摘要拒用、相同輸入沿用、變更補驗與 dirty 快照"
else
    cat "$TMP/project-test-evidence-test.out"
    bad "project test evidence regression"
fi
python3 "$ROOT/tests/project-reference-metrics-test.py" >"$TMP/project-reference-metrics-test.out" 2>&1
project_metrics_rc=$?
assert_rc "project native trace normalizer：完整末行／partial／重讀／截斷有效性／cache 計費" 0 "$project_metrics_rc"
python3 "$ROOT/tests/session-skills-host-mcp-test.py" >"$TMP/session-skills-host-mcp-test.out" 2>&1
session_skills_transport_rc=$?
assert_rc "session skill eval transport：私人路徑 probe 不執行／fixture output 不截斷／exit 保真" 0 "$session_skills_transport_rc"
PJS_CLAUDE="$ROOT/claude/skills/project"
PJS_CODEX="$ROOT/codex/skills/project"
project_scripts_shared=1
for script_name in bootstrap-baseline.sh branch-first.sh cleanup-stale-branch.sh doc-governance.py read-reference.py ship-state.sh steward-authority.py test-evidence.py wait-required-enrollment.sh; do
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
    && grep -q '不得授予.*authority.*shipping authorization' <<< "$project_step0"; then
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
if grep -q '## 平行協作與 stewardship' "$PJS_CLAUDE/references/dossier.md" \
    && grep -q 'Dossier delta' "$PJS_CLAUDE/references/dossier.md" \
    && grep -q 'authority actor 必須等於所有 active items' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q 'Worker 呼叫 Log 時立即 STOP' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q 'active_item_contract' "$PJS_CLAUDE/references/spec-workflow.md"; then
    ok "project shared workflow 區分 dossier steward 與 isolated worker"
else bad "project shared workflow 缺 stewardship／worker STOP 契約"; fi
if grep -q 'Scenario 24 — 身分宣稱不得冒充 steward actor' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q 'ordinary identity claim.*not.*delegation' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q 'explicit-bounded-human-delegation' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q 'executor actor.*durable steward.*authority source' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q 'resume=.*same runtime' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q 'candidate-shared-surface' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q '本輪稍後由合法 steward 新建' "$PJS_CLAUDE/references/log-prepare.md"; then
    ok "project stewardship gate 區分自然語言身分、workline resume 與 bounded human delegation"
else bad "project stewardship gate 仍可能把『我是 owner』誤當 actor authority"; fi

PJS_STEWARD_GATE="$PJS_CLAUDE/scripts/steward-authority.py"
if python3 "$ROOT/tests/project-sequential-assignment.py" "$PJS_STEWARD_GATE" >"$TMP/project-sequential-assignment.out" 2>&1; then
    ok "project sequential assignment：明示指派與dirty／conflict／snapshot邊界"
else
    cat "$TMP/project-sequential-assignment.out"
    bad "project sequential assignment regression"
fi
if python3 "$ROOT/tests/project-session-binding.py" "$PJS_STEWARD_GATE" >"$TMP/project-session-binding.out" 2>&1; then
    ok "project session binding：正常接續與 assignment／HEAD／runtime 邊界"
else
    cat "$TMP/project-session-binding.out"
    bad "project session binding regression"
fi
project_step2_and_3="$(sed -n '/^## Step 2：/,/^## Step 4：/p' \
    "$PJS_CLAUDE/references/log-prepare.md")"
if grep -q 'Scenario 36 — Spec 後的 multi-repo' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q 'shared dossier.*candidate 前.*authority' <<< "$project_step2_and_3" \
    && grep -q -- '--candidate-parent' <<< "$project_step2_and_3" \
    && grep -q 'candidate-rebuild: READY' <<< "$project_step2_and_3" \
    && grep -q '當前 logical Project invocation' <<< "$project_step2_and_3" \
    && grep -q '直接子 commit' <<< "$project_step2_and_3" \
    && grep -q '尚未 push.*尚未開 PR' <<< "$project_step2_and_3" \
    && grep -q '不得冒稱' <<< "$project_step2_and_3" \
    && grep -q 'formal transfer' <<< "$project_step2_and_3" \
    && grep -q '使用者.*worker.*混入.*STOP' <<< "$project_step2_and_3"; then
    ok "project candidate provenance 在寫入前解析，錯 actor local candidate 僅有界重建"
else bad "project candidate provenance 仍可能延後成使用者決策或無界重寫"; fi
if grep -q -- '--completion-parent' <<< "$project_step2_and_3" \
    && grep -q 'completion-candidate: READY' <<< "$project_step2_and_3" \
    && grep -q 'plain.*no-active-items.*不得.*PASS' <<< "$project_step2_and_3" \
    && grep -q 'endpoint.*未達成.*不得.*shipped' <<< "$project_step2_and_3"; then
    ok "project completion candidate 以 parent authority 驗證且不提前宣稱 shipped"
else bad "project completion candidate 可在移除 active item 後洗掉 authority 或提前宣稱 shipped"; fi
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
PSG="$TMP/project-steward-gate"
mkdir -p "$PSG/repo/docs/archive" "$PSG/repo/src"
git init -q -b main "$PSG/repo"
git -C "$PSG/repo" config user.name test
git -C "$PSG/repo" config user.email test@example.com
printf '%s\n' '{"status_schema":{"path":"STATUS.md","active_item_contract":{"required_fields":["Writer","Workspace","Write Scope","Dossier Steward"],"uniform_fields":["Dossier Steward"]}},"history_paths":{"decision":"docs/archive/decisions-{YYYY-MM}.md","dead_end":"docs/archive/dead-ends-{YYYY-MM}.md","milestone":"docs/archive/milestones-{YYYY-MM}.md"},"plan_dir":"docs/plans"}' > "$PSG/repo/.doc-governance.json"
printf '%s\n' '# Status' '' '## 進行中' '' '### Contract sync' '' '- **Writer**：codex:agent-contract-sync' '- **Workspace**：branch=docs/agent-contract-sync' '- **Write Scope**：AGENTS.md, CLAUDE.md, tests/' '- **Dossier Steward**：owner:repo-maintainer' '' '## 暫停中' > "$PSG/repo/STATUS.md"
printf '%s\n' '# Milestones' > "$PSG/repo/docs/archive/milestones-2026-08.md"
git -C "$PSG/repo" add .doc-governance.json STATUS.md docs/archive/milestones-2026-08.md
git -C "$PSG/repo" commit -qm "chore: seed authority fixture"
git -C "$PSG/repo" switch -qc docs/agent-contract-sync
printf '%s\n' 'implemented = true' > "$PSG/repo/src/change.py"
printf '%s\n' '' '- worker wrote steward-only milestone' >> "$PSG/repo/docs/archive/milestones-2026-08.md"
git -C "$PSG/repo" add src/change.py docs/archive/milestones-2026-08.md
git -C "$PSG/repo" commit -qm "docs: sync contract"
psg_commit="$(git -C "$PSG/repo" rev-parse HEAD)"

psg_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --commit "$psg_commit" 2>"$PSG/err")"
psg_rc=$?
assert_rc "steward gate：owner 身分未顯式 delegation → STOP" 1 "$psg_rc"
if grep -q '^executor-actor: codex:agent-contract-sync$' <<< "$psg_out" \
    && grep -q '^durable-steward: owner:repo-maintainer$' <<< "$psg_out" \
    && grep -q '^authority-source: active-writer-workspace-match$' <<< "$psg_out" \
    && grep -q '^verdict: STOP$' <<< "$psg_out"; then
    ok "steward gate 不把普通『我是 repo owner』身分宣稱映射成 owner actor"
else bad "steward gate actor／steward／authority evidence 不完整"; fi
if grep -q '^candidate-shared-surface: docs/archive/milestones-2026-08.md$' <<< "$psg_out"; then
    ok "steward gate 揭露 worker commit 越界 milestone surface"
else bad "steward gate 未揭露 worker 的 shared-surface 越界"; fi
if grep -q '^recovery-kind: confirm-human-delegation$' <<< "$psg_out" \
    && grep -q '^recovery-actor: owner:repo-maintainer$' <<< "$psg_out"; then
    ok "steward gate 對唯一 human steward 提供 deterministic guided recovery"
else bad "steward gate 未分類可確認的 human delegation recovery"; fi

psg_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --as-human owner:repo-maintainer --commit "$psg_commit" 2>"$PSG/err")"
psg_rc=$?
assert_rc "steward gate：exact human delegation → PASS" 0 "$psg_rc"
if grep -q '^authority-actor: owner:repo-maintainer$' <<< "$psg_out" \
    && grep -q '^authority-source: explicit-bounded-human-delegation$' <<< "$psg_out" \
    && grep -q '^verdict: PASS$' <<< "$psg_out"; then
    ok "steward gate 保留 runtime executor 並以 bounded human delegation 放行"
else bad "steward gate human delegation evidence 不完整"; fi
psg_head="$(git -C "$PSG/repo" rev-parse HEAD)"
psg_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --confirmed-human owner:repo-maintainer --commit "$psg_commit" --expected-head "$psg_head" 2>"$PSG/err")"
assert_rc "steward gate：prompt-bound exact human confirmation → PASS" 0 $?
if grep -q '^authority-source: prompt-bound-human-delegation$' <<< "$psg_out" \
    && grep -q "^repository-head: $psg_head$" <<< "$psg_out" \
    && grep -q "^candidate-commit: $psg_commit$" <<< "$psg_out"; then
    ok "steward gate human confirmation 綁定 full HEAD／candidate snapshot"
else bad "steward gate human confirmation 缺 prompt-bound provenance 或 snapshot"; fi
psg_stale_head="$(git -C "$PSG/repo" rev-parse HEAD^)"
python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --confirmed-human owner:repo-maintainer --expected-head "$psg_stale_head" >"$PSG/stale.out" 2>"$PSG/err"
assert_rc "steward gate：prompt snapshot stale → STOP" 1 $?
if grep -q '^authority-source: stale-prompt-snapshot$' "$PSG/stale.out" \
    && grep -q '^recovery-kind: none$' "$PSG/stale.out"; then
    ok "steward gate 不沿用 stale prompt confirmation"
else bad "steward gate stale prompt 未 fail closed"; fi
python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --confirmed-human owner:repo-maintainer >/dev/null 2>&1
assert_rc "steward gate：prompt-bound flag 缺 exact snapshot → usage error" 2 $?

python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --as-human owner:someone-else >/dev/null 2>&1
assert_rc "steward gate：human delegation actor 非 durable steward → STOP" 1 $?
python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --as-human codex:integration >/dev/null 2>&1
assert_rc "steward gate：as= 不得代理 agent actor" 2 $?
python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --resume-actor owner:repo-maintainer >/dev/null 2>&1
assert_rc "steward gate：resume= 不得冒充 human actor" 2 $?

sed -i.bak 's/owner:repo-maintainer/codex:cross-runtime-dossier-rollout/' "$PSG/repo/STATUS.md" && rm -f "$PSG/repo/STATUS.md.bak"
psg_resume_prompt_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --commit "$psg_commit" 2>"$PSG/err")"
assert_rc "steward gate：same-runtime steward 未確認前仍 STOP" 1 $?
if grep -q '^recovery-kind: confirm-same-runtime-resume$' <<< "$psg_resume_prompt_out" \
    && grep -q '^recovery-actor: codex:cross-runtime-dossier-rollout$' <<< "$psg_resume_prompt_out"; then
    ok "steward gate 對唯一 same-runtime steward 提供 deterministic guided recovery"
else bad "steward gate 未分類可確認的 same-runtime resume recovery"; fi
psg_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --resume-actor codex:cross-runtime-dossier-rollout 2>"$PSG/err")"
psg_rc=$?
assert_rc "steward gate：same-runtime exact workline resume → PASS" 0 "$psg_rc"
if grep -q '^executor-actor: codex:cross-runtime-dossier-rollout$' <<< "$psg_out" \
    && grep -q '^authority-source: explicit-same-runtime-resume$' <<< "$psg_out"; then
    ok "steward gate resume evidence 精確指向 durable workline"
else bad "steward gate resume evidence 不完整"; fi
psg_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --confirmed-resume-actor codex:cross-runtime-dossier-rollout --expected-head "$psg_head" 2>"$PSG/err")"
assert_rc "steward gate：prompt-bound same-runtime confirmation → PASS" 0 $?
if grep -q '^authority-source: prompt-bound-same-runtime-resume$' <<< "$psg_out"; then
    ok "steward gate same-runtime confirmation 使用獨立 provenance"
else bad "steward gate same-runtime confirmation provenance 不完整"; fi
sed -i.bak 's/codex:cross-runtime-dossier-rollout/claude:foreign-workline/' "$PSG/repo/STATUS.md" && rm -f "$PSG/repo/STATUS.md.bak"
psg_cross_runtime_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG/repo" --runtime codex --commit "$psg_commit" 2>"$PSG/err")"
assert_rc "steward gate：cross-runtime steward mismatch → STOP" 1 $?
if grep -q '^recovery-kind: none$' <<< "$psg_cross_runtime_out" \
    && ! grep -q '^recovery-actor:' <<< "$psg_cross_runtime_out"; then
    ok "steward gate 不為 cross-runtime actor 提供 guided takeover"
else bad "steward gate 不得把 cross-runtime mismatch 分類成可確認 recovery"; fi

PSG_EMPTY="$TMP/project-steward-empty"
mkdir -p "$PSG_EMPTY/repo/docs/archive"
git init -q -b main "$PSG_EMPTY/repo"
git -C "$PSG_EMPTY/repo" config user.name test
git -C "$PSG_EMPTY/repo" config user.email test@example.com
cp "$PSG/repo/.doc-governance.json" "$PSG_EMPTY/repo/.doc-governance.json"
printf '%s\n' '# Status' '' '## 進行中' '' '目前無進行中項目。' '' '## 暫停中' > "$PSG_EMPTY/repo/STATUS.md"
printf '%s\n' '# Milestones' > "$PSG_EMPTY/repo/docs/archive/milestones-2026-08.md"
git -C "$PSG_EMPTY/repo" add .doc-governance.json STATUS.md docs/archive/milestones-2026-08.md
git -C "$PSG_EMPTY/repo" commit -qm "chore: seed empty authority fixture"
git -C "$PSG_EMPTY/repo" switch -qc docs/no-steward-history
printf '%s\n' '' '- milestone without a steward' >> "$PSG_EMPTY/repo/docs/archive/milestones-2026-08.md"
git -C "$PSG_EMPTY/repo" add docs/archive/milestones-2026-08.md
git -C "$PSG_EMPTY/repo" commit -qm "docs: write ownerless milestone"
psg_empty_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG_EMPTY/repo" --runtime codex --commit HEAD 2>"$PSG_EMPTY/err")"
assert_rc "steward gate：current／parent 零 steward 的 shared history candidate → STOP" 1 $?
if grep -q '^authority-source: no-durable-steward-for-shared-surface$' <<< "$psg_empty_out" \
    && grep -q '^candidate-shared-surface: docs/archive/milestones-2026-08.md$' <<< "$psg_empty_out"; then
    ok "steward gate 不把零 active item 當成 shared-history 免責"
else bad "steward gate 未攔下無 durable steward 的 shared history"; fi
if grep -q '^recovery-kind: confirm-create-active-contract$' <<< "$psg_empty_out" \
    && grep -q '^recovery-actor: codex:no-steward-history$' <<< "$psg_empty_out"; then
    ok "steward gate 對零 steward 的明確 shared candidate 提供 Spec recovery"
else bad "steward gate 未分類可確認的 active-contract recovery"; fi
psg_empty_head="$(git -C "$PSG_EMPTY/repo" rev-parse HEAD)"
printf '%s\n' '# Status' '' '## 進行中' '' '### Adopt local candidate' '' '- **Writer**：codex:no-steward-history' '- **Workspace**：branch=docs/no-steward-history' '- **Write Scope**：docs/archive/' '- **Dossier Steward**：codex:no-steward-history' '' '## 暫停中' > "$PSG_EMPTY/repo/STATUS.md"
psg_empty_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG_EMPTY/repo" --runtime codex --confirmed-new-steward codex:no-steward-history --commit "$psg_empty_head" --expected-head "$psg_empty_head" 2>"$PSG_EMPTY/err")"
assert_rc "steward gate：Spec subflow 後 prompt-bound new steward → PASS" 0 $?
if grep -q '^authority-source: prompt-bound-new-workline-confirmation$' <<< "$psg_empty_out" \
    && grep -q '^durable-steward: codex:no-steward-history$' <<< "$psg_empty_out"; then
    ok "steward gate 新 workline confirmation 只在 durable contract 落地後放行"
else bad "steward gate new-workline confirmation 未重驗 durable contract"; fi

project_authority_recovery="$(sed -n '/^## Prompt-bound authority recovery/,/^## /p' "$PJS_CLAUDE/references/log-prepare.md")"
if grep -q 'Scenario 26 — 可安全修復的 authority STOP 改用綁定式確認續行' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q 'normalized invocation arguments' <<< "$project_authority_recovery" \
    && grep -q '同一個 logical Project invocation' <<< "$project_authority_recovery" \
    && grep -q '取消.*零 mutation' <<< "$project_authority_recovery" \
    && grep -q '不得授予.*endpoint' <<< "$project_authority_recovery"; then
    ok "project authority recovery 以 prompt-bound 選項續行且不擴張授權"
else bad "project authority recovery 尚未形成可確認、可取消且不重建 invocation 的契約"; fi

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
if grep -q 'Scenario 27 — Spec 收尾同時提示短版與 exact resume 明確版' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q '不帶任何' <<< "$project_spec_completion" \
    && grep -q 'resume=.*as=' <<< "$project_spec_completion" \
    && grep -q 'active-writer-workspace-match' <<< "$project_spec_completion" \
    && grep -qF "\$project --merge" <<< "$project_spec_completion" \
    && grep -qF '/project --merge' <<< "$project_spec_completion" \
    && grep -q 'resume=<exact-actor>' <<< "$project_spec_completion" \
    && grep -q 'endpoint authorization' <<< "$project_spec_completion" \
    && grep -q '不 carry' <<< "$project_spec_completion" \
    && grep -q 'BROKEN.*recovery-kind.*scope mismatch' <<< "$project_spec_completion"; then
    ok "project Spec 收尾只在 helper 精確證明時同列短版與 resume 明確版"
else bad "project Spec 收尾未安全區分短版 invocation、workline binding 與新 endpoint 授權"; fi
project_log_authority="$(sed -n '/^## Step 2：/,/^### Runtime steward retirement gate/p' \
    "$PJS_CLAUDE/references/log-prepare.md")"
if grep -q 'Scenario 36 — Spec 後的 multi-repo' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q 'current-session binding packet' <<< "$project_spec_completion" \
    && grep -q 'Spec.*新建.*active contract.*current-session workline assignment' <<< "$project_spec_completion" \
    && grep -q -- '--session-resume-actor' <<< "$project_spec_completion" \
    && grep -q '不要求.*resume=' <<< "$project_spec_completion" \
    && grep -q 'canonical repo root' <<< "$project_spec_completion" \
    && grep -q 'exact actor' <<< "$project_spec_completion" \
    && grep -q 'assignment fingerprint' <<< "$project_spec_completion" \
    && grep -q '先消費.*binding packet.*branch-derived actor' <<< "$project_log_authority" \
    && grep -q '重驗通過.*不詢問.*resume=' <<< "$project_log_authority" \
    && grep -q 'binding delta' <<< "$project_log_authority" \
    && grep -q '套用既有 recovery' <<< "$project_log_authority" \
    && grep -q '不得授予.*shipping endpoint' <<< "$project_spec_completion"; then
    ok "project Log 消費同 session Spec workline binding，無 delta 不重問 resume"
else bad "project Log 未可靠消費同 session Spec workline binding"; fi

PSG_PARENT="$TMP/project-steward-parent"
mkdir -p "$PSG_PARENT/repo/docs/archive"
git init -q -b main "$PSG_PARENT/repo"
git -C "$PSG_PARENT/repo" config user.name test
git -C "$PSG_PARENT/repo" config user.email test@example.com
cp "$PSG/repo/.doc-governance.json" "$PSG_PARENT/repo/.doc-governance.json"
printf '%s\n' '# Status' '' '## 進行中' '' '### Completing item' '' '- **Writer**：codex:integration' '- **Workspace**：branch=docs/completed-item' '- **Write Scope**：docs/' '- **Dossier Steward**：codex:integration' '' '## 暫停中' > "$PSG_PARENT/repo/STATUS.md"
printf '%s\n' '# Milestones' > "$PSG_PARENT/repo/docs/archive/milestones-2026-08.md"
git -C "$PSG_PARENT/repo" add .doc-governance.json STATUS.md docs/archive/milestones-2026-08.md
git -C "$PSG_PARENT/repo" commit -qm "chore: seed completing item"
git -C "$PSG_PARENT/repo" switch -qc docs/completed-item
printf '%s\n' '# Status' '' '## 進行中' '' '目前無進行中項目。' '' '## 暫停中' > "$PSG_PARENT/repo/STATUS.md"
printf '%s\n' '' '- completed item milestone' >> "$PSG_PARENT/repo/docs/archive/milestones-2026-08.md"
git -C "$PSG_PARENT/repo" add STATUS.md docs/archive/milestones-2026-08.md
git -C "$PSG_PARENT/repo" commit -qm "docs: complete item"
psg_parent_out="$(python3 "$PJS_STEWARD_GATE" --root "$PSG_PARENT/repo" --runtime codex --resume-actor codex:integration --commit HEAD 2>"$PSG_PARENT/err")"
assert_rc "steward gate：completed candidate 從 parent STATUS 恢復 steward → PASS" 0 $?
if grep -q '^durable-steward: codex:integration$' <<< "$psg_parent_out" \
    && grep -q '^durable-steward-source: commit-parent-active-state$' <<< "$psg_parent_out" \
    && grep -q '^verdict: PASS$' <<< "$psg_parent_out"; then
    ok "steward gate 保留 completed-item 跨 session shipping liveness"
else bad "steward gate 無法從 candidate parent 恢復 completed-item steward"; fi
project_retired_steward_gate="$(sed -n '/^### Runtime steward retirement gate/,/^## /p' "$PJS_CLAUDE/references/log-prepare.md")"
if grep -q 'Scenario 28 — runtime steward workline 結案不得留下 active dead reference' "$PJS_CLAUDE/references/pressure-tests.md" \
    && grep -q 'Step 0.*完整.*repo' <<< "$project_retired_steward_gate" \
    && grep -q 'completion milestone.*移除' <<< "$project_retired_steward_gate" \
    && grep -q 'claude:\*.*codex:\*' <<< "$project_retired_steward_gate" \
    && grep -q 'owner:\*.*human:\*' <<< "$project_retired_steward_gate" \
    && grep -q '明示 successor' <<< "$project_retired_steward_gate" \
    && grep -q 'PREPARED' <<< "$project_retired_steward_gate" \
    && grep -q '所有.*active items' <<< "$project_retired_steward_gate" \
    && grep -q '同一.*lifecycle commit' <<< "$project_retired_steward_gate" \
    && grep -q '不得宣告.*完成' <<< "$project_retired_steward_gate"; then
    ok "project Log 在 runtime steward workline 結案前消除跨 repo dead references"
else bad "project Log 仍可能讓已結案 runtime actor 留在 active steward contract"; fi
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
if grep -q 'BLOCKED.*PREPARED.*TRANSFERRED' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q 'portable-knowledge' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q 'canonical handover endpoint' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q '所有 active items' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q 'in-flight.*未整合' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q 'conditional pending values' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q 'remote-visible ancestry' "$PJS_CLAUDE/references/log-prepare.md" \
    && grep -q 'authorization.*不.*移交' "$PJS_CLAUDE/references/transfer-workflow.md" \
    && grep -q 'Scenario 23' "$PJS_CLAUDE/references/pressure-tests.md"; then
    ok "project transfer 有 portable-knowledge hard gate 與原子 stewardship 狀態機"
else bad "project transfer 缺 BLOCKED/PREPARED/TRANSFERRED、可攜知識或原子切換契約"; fi
project_spec_sig="\$project spec"
project_transfer_sig="\$project transfer"
ready4quit_sig="\$ready4quit"
if grep -qF "$project_spec_sig" "$ROOT/codex/AGENTS.md" \
    && grep -qF "$project_transfer_sig" "$ROOT/codex/AGENTS.md" \
    && grep -qF "$ready4quit_sig" "$ROOT/codex/AGENTS.md"; then
    ok "Codex 全域 contract 提示 explicit project／ready4quit 入口"
else bad "Codex 全域 contract 缺 explicit workflow pointers"; fi
