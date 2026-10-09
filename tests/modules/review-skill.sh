#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 12bb. deep-review skill 跨 Claude Code／Codex 共用核心"
DRS_CLAUDE="$ROOT/claude/skills/deep-review"
RRS_CODEX="$ROOT/codex/skills/repo-review"
if [ ! -e "$ROOT/codex/skills/deep-review" ] \
    && [ -f "$DRS_CLAUDE/SKILL.md" ] && [ -f "$RRS_CODEX/SKILL.md" ] \
    && [ "$RRS_CODEX/references/workflow.md" -ef "$DRS_CLAUDE/references/workflow.md" ] \
    && [ "$RRS_CODEX/references/portable-reviewer-brief.md" -ef "$DRS_CLAUDE/references/portable-reviewer-brief.md" ] \
    && [ "$RRS_CODEX/scripts/review-scope.sh" -ef "$DRS_CLAUDE/scripts/review-scope.sh" ] \
    && [ "$RRS_CODEX/scripts/review-control.py" -ef "$DRS_CLAUDE/scripts/review-control.py" ] \
    && [ "$RRS_CODEX/references/control.md" -ef "$DRS_CLAUDE/references/control.md" ] \
    && [ "$RRS_CODEX/scripts/review-terminal.sh" -ef "$DRS_CLAUDE/scripts/review-terminal.sh" ]; then
    ok "Claude deep-review 與 Codex repo-review 薄殼共用 portable core"
else bad "repo-review 薄殼未完整共用 deep-review canonical core 或仍有重複入口"; fi
if grep -q 'references/workflow.md' "$DRS_CLAUDE/SKILL.md" \
    && grep -q 'references/workflow.md' "$RRS_CODEX/SKILL.md" \
    && [ -f "$RRS_CODEX/agents/openai.yaml" ]; then
    ok "兩個 runtime 入口都路由 shared workflow，Codex metadata 完整"
else bad "deep-review adapter 或 Codex metadata 不完整"; fi
drs_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$RRS_CODEX/SKILL.md" 2>/dev/null)"
if ! grep -Eq '^(user-invocable|disable-model-invocation|argument-hint|allowed-tools|context|agent):' \
    <<< "$drs_codex_frontmatter"; then
    ok "Codex deep-review frontmatter 無 Claude Code 專屬欄位"
else bad "Codex deep-review frontmatter 混入 Claude Code 專屬欄位"; fi
deep_review_sig="\$repo-review"
drs_tilde='~'
if grep -qF "$deep_review_sig" "$RRS_CODEX/agents/openai.yaml" 2>/dev/null \
    && ! rg -q "${drs_tilde}/.claude|${drs_tilde}/.codex|codex exec|TaskOutput|AskUserQuestion" \
        "$DRS_CLAUDE/references/workflow.md" "$DRS_CLAUDE/references/portable-reviewer-brief.md" 2>/dev/null; then
    ok "repo-review metadata 與 shared core 不綁 runtime-private API、CLI 或安裝路徑"
else bad "deep-review metadata 或 shared core 仍有 runtime 偶合"; fi
if grep -q 'resolved head' "$DRS_CLAUDE/references/workflow.md" \
    && grep -q '8–12' "$DRS_CLAUDE/references/workflow.md" \
    && grep -q 'cross-repository contract pass' "$DRS_CLAUDE/references/workflow.md" \
    && grep -q 'non-overlapping primary assignments' "$DRS_CLAUDE/references/workflow.md"; then
    ok "shared workflow 承接 historical guidance 與 scale-aware partition"
else bad "portable core 尚未承接 repo-review 的必要成熟能力"; fi
if grep -q 'Portable behavior oracle (2026-08-23)' "$ROOT/shared/skills/deep-review/evals.md" \
    && grep -q 'P14 — Historical committed range uses historical guidance' "$ROOT/shared/skills/deep-review/evals.md" \
    && grep -q 'P15 — Scale-aware fresh reviewer partitioning' "$ROOT/shared/skills/deep-review/evals.md" \
    && grep -q 'P16 — Codex repo-review adapter preserves the explicit-range interface' "$ROOT/shared/skills/deep-review/evals.md" \
    && grep -q 'P17 — Empty-tree and divergent-range safety' "$ROOT/shared/skills/deep-review/evals.md" \
    && grep -q "P18 — Deterministic helper runs on the runtime's system Bash" "$ROOT/shared/skills/deep-review/evals.md" \
    && rg -q 'PASS.*FAIL.*BLOCKED' "$ROOT/shared/skills/deep-review/evals.md"; then
    ok "portable behavior oracle 覆蓋薄殼、歷史 guidance、scale partition 與 range safety"
else bad "deep-review portable behavior oracle 尚未落地"; fi

drs_tmp="$TMP/deep-review-portable"
mkdir -p "$drs_tmp"
git init -q -b main "$drs_tmp/repo"
(cd "$drs_tmp/repo" && "${GITC[@]}" commit --allow-empty -qm base)
drs_base="$(git -C "$drs_tmp/repo" rev-parse HEAD)"
drs_capture="$("$DRS_CLAUDE"/scripts/review-scope.sh capture --repo "$drs_tmp/repo" --mode working-tree)"
drs_manifest="$(awk '/^manifest: / {sub(/^manifest: /, ""); print}' <<< "$drs_capture")"
"$DRS_CLAUDE"/scripts/review-scope.sh verify --manifest "$drs_manifest" >/dev/null
assert_rc "deep-review immutable scope capture 後未漂移 → FRESH" 0 $?
touch "$drs_tmp/repo/untracked"
"$DRS_CLAUDE"/scripts/review-scope.sh verify --manifest "$drs_manifest" >/dev/null 2>&1
assert_rc "deep-review scope 新增 untracked → BLOCKED" 5 $?
rm -f "$drs_tmp/repo/untracked"

(cd "$drs_tmp/repo" && git switch -qc feat/portable && "${GITC[@]}" commit --allow-empty -qm change)
drs_head="$(git -C "$drs_tmp/repo" rev-parse HEAD)"
"$DRS_CLAUDE"/scripts/review-scope.sh capture --repo "$drs_tmp/repo" --mode range \
    --range "$drs_base...$drs_head" >/dev/null 2>&1
assert_rc "deep-review 明示 three-dot range → 拒絕猜 two endpoints" 4 $?

drs_anchor="$(git -C "$drs_tmp/repo" rev-parse --absolute-git-dir)/deep-review/anchor"
mkdir -p "$(dirname "$drs_anchor")"
echo 'base=legacy-compatible' > "$drs_anchor"
"$DRS_CLAUDE"/scripts/review-terminal.sh record --repo "$drs_tmp/repo" \
    --reason blocking-findings --head "$drs_base" >/dev/null
drs_before_show="$(cat "$drs_anchor")"
drs_show="$("$DRS_CLAUDE"/scripts/review-terminal.sh show --repo "$drs_tmp/repo")"
if grep -qxF 'terminal_reason=blocking-findings' <<< "$drs_show" \
    && grep -qxF "terminal_head=$drs_base" <<< "$drs_show" \
    && grep -Eq '^terminal_at=[0-9]+$' <<< "$drs_show" \
    && [ "$(wc -l <<< "$drs_show" | tr -d ' ')" -eq 3 ]; then
    ok "deep-review show 在系統 sed 完整顯示 terminal 三欄、不洩 legacy"
else bad "deep-review show 遺失 terminal evidence 或混入其他欄位"; fi
assert_eq "deep-review show 不改 anchor" "$drs_before_show" "$(cat "$drs_anchor")"
"$DRS_CLAUDE"/scripts/review-terminal.sh clear --repo "$drs_tmp/repo" \
    --base "$drs_head" --head "$drs_head" >/dev/null 2>&1
assert_rc "deep-review PASS scope 未涵蓋舊 terminal → 保留 signal" 5 $?
"$DRS_CLAUDE"/scripts/review-terminal.sh clear --repo "$drs_tmp/repo" \
    --base "$drs_base" --head "$drs_head" >/dev/null
assert_rc "deep-review ancestry 涵蓋但缺 receipt → 保留 legacy signal" 5 $?
if grep -qx 'base=legacy-compatible' "$drs_anchor" && grep -q '^terminal_reason=' "$drs_anchor"; then
    ok "deep-review 缺 coverage receipt 時同時保留 legacy 與 terminal 欄位"
else bad "deep-review terminal helper 破壞 legacy anchor 或清掉未知 coverage"; fi
drs_show="$("$DRS_CLAUDE"/scripts/review-terminal.sh show --repo "$drs_tmp/repo")"
assert_eq "deep-review 拒絕 ancestry-only clear 後 signal 保持原樣" "$drs_before_show" "$(cat "$drs_anchor")"
if python3 -B "$ROOT/tests/review-primary-scope.py" "$ROOT" >"$TMP/review-primary-scope.out" 2>&1; then
    ok "review primary scope：path partitions、aggregate receipt、drift 與 incomplete 原始證據"
else
    cat "$TMP/review-primary-scope.out"
    bad "review primary responsibility regression"
fi
