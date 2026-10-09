#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034,SC2153
    git init -q -b main "$TMP/gh-local"
    (cd "$TMP/gh-local" && echo x > a.txt && "${GITC[@]}" add a.txt && "${GITC[@]}" commit -qm init)

echo "▶ 9b. branch-first.sh 情況 A/B 判定與救援序列"
BF_SCRIPT="$ROOT/claude/skills/project/scripts/branch-first.sh"

git init --bare -q -b main "$TMP/bf-origin.git"
git init -q -b main "$TMP/bf-work"
(cd "$TMP/bf-work" \
    && echo base > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/bf-origin.git" && git push -qu origin main)

# 情況 A：在 main、working tree 有未 commit 變更、無誤 commit → switch -c，變更跟隨
echo dirty > "$TMP/bf-work/wip.txt"
out="$("$BF_SCRIPT" "$TMP/bf-work" feat/a)"
assert_rc "情況 A → exit 0" 0 $?
if echo "$out" | grep -q "case: A" && echo "$out" | grep -q "verdict: OK"; then ok "情況 A 判定 + OK"; else bad "情況 A 判定錯誤（${out}）"; fi
assert_eq "情況 A 後 HEAD 在 feature branch" "feat/a" "$(git -C "$TMP/bf-work" symbolic-ref --short HEAD)"
if [ -f "$TMP/bf-work/wip.txt" ]; then ok "情況 A working tree 變更跟隨"; else bad "情況 A 弄丟 working tree 變更"; fi
assert_eq "情況 A main 未動（== origin/main）" \
    "$(git -C "$TMP/bf-work" rev-parse origin/main)" "$(git -C "$TMP/bf-work" rev-parse main)"
(cd "$TMP/bf-work" && rm wip.txt && git switch -q main && git branch -qD feat/a)

# 情況 B：誤 commit 在本地 main（未 push）、tree clean → branch 保住 → switch → branch -f 退回
(cd "$TMP/bf-work" && echo v2 > f.txt && "${GITC[@]}" commit -qam "oops: on main")
out="$("$BF_SCRIPT" "$TMP/bf-work" feat/b)"
assert_rc "情況 B → exit 0" 0 $?
if echo "$out" | grep -q "case: B" && echo "$out" | grep -q "verdict: OK"; then ok "情況 B 判定 + OK"; else bad "情況 B 判定錯誤（${out}）"; fi
assert_eq "情況 B 後 HEAD 在 feature branch" "feat/b" "$(git -C "$TMP/bf-work" symbolic-ref --short HEAD)"
assert_eq "情況 B feature branch 接住 1 commit" "1" \
    "$(git -C "$TMP/bf-work" rev-list --count origin/main..feat/b)"
assert_eq "情況 B main 已退回 origin/main" \
    "$(git -C "$TMP/bf-work" rev-parse origin/main)" "$(git -C "$TMP/bf-work" rev-parse main)"
(cd "$TMP/bf-work" && git switch -q main && git branch -qD feat/b)

# mixed state：誤 commit + working tree 另有未 commit 檔 → 救援後未 commit 檔完好（H6 核心斷言）
(cd "$TMP/bf-work" && echo v3 > f.txt && "${GITC[@]}" commit -qam "oops2: on main" && echo precious > notes.txt)
out="$("$BF_SCRIPT" "$TMP/bf-work" feat/c)"
assert_rc "mixed state → exit 0" 0 $?
if echo "$out" | grep -q "case: B"; then ok "mixed state 判為情況 B"; else bad "mixed state 判定錯誤"; fi
assert_eq "mixed state 未 commit 檔完好無損" "precious" "$(cat "$TMP/bf-work/notes.txt" 2>/dev/null)"
if echo "$out" | grep -q "verify: porcelain 前後一致"; then ok "mixed state 附 porcelain 前後快照驗證"; else bad "缺 porcelain 快照驗證行"; fi
assert_eq "mixed state main 已退回 origin/main" \
    "$(git -C "$TMP/bf-work" rev-parse origin/main)" "$(git -C "$TMP/bf-work" rev-parse main)"
(cd "$TMP/bf-work" && rm notes.txt && git switch -q main && git branch -qD feat/c)

# detached HEAD（其上有 commit）→ 情況 A：switch -c 一併接走 commit，不需 ref 重置
git clone -q "$TMP/bf-origin.git" "$TMP/bf-detach"
(cd "$TMP/bf-detach" && git checkout -q --detach && echo dh > d.txt && "${GITC[@]}" add d.txt && "${GITC[@]}" commit -qm "on detached")
out="$("$BF_SCRIPT" "$TMP/bf-detach" feat/dh)"
assert_rc "detached HEAD → exit 0" 0 $?
if echo "$out" | grep -q "case: A"; then ok "detached HEAD 判為情況 A"; else bad "detached HEAD 判定錯誤（${out}）"; fi
assert_eq "detached 後 HEAD 在 feature branch" "feat/dh" "$(git -C "$TMP/bf-detach" symbolic-ref --short HEAD)"
assert_eq "detached commit 被 feature branch 接走" "1" \
    "$(git -C "$TMP/bf-detach" rev-list --count origin/main..feat/dh)"

# branch 撞名 → STOP、不動任何狀態
(cd "$TMP/bf-work" && git branch feat/exists && echo dirty2 > wip2.txt)
out="$("$BF_SCRIPT" "$TMP/bf-work" feat/exists)"
assert_rc "branch 撞名 → exit 1" 1 $?
if echo "$out" | grep -q "verdict: STOP"; then ok "撞名 → STOP"; else bad "撞名未 STOP"; fi
assert_eq "撞名後仍在 main（未半途執行）" "main" "$(git -C "$TMP/bf-work" symbolic-ref --short HEAD)"
(cd "$TMP/bf-work" && rm wip2.txt && git branch -qD feat/exists)

# 已在 feature branch（非 default）→ STOP（無事可做，不疊 branch）
(cd "$TMP/bf-work" && git switch -qc feat/other)
out="$("$BF_SCRIPT" "$TMP/bf-work" feat/d)"
assert_rc "非 default branch → exit 1" 1 $?
if echo "$out" | grep -q "verdict: STOP"; then ok "已在 feature branch → STOP"; else bad "非 default 未 STOP"; fi
if git -C "$TMP/bf-work" show-ref --verify -q refs/heads/feat/d; then bad "STOP 卻建了 branch"; else ok "STOP 未建 branch"; fi
(cd "$TMP/bf-work" && git switch -q main && git branch -qD feat/other)

# 分岔（remote default 已被他人推進、本地 main 另有誤 commit）→ ambiguous → STOP、零 mutation
git clone -q "$TMP/bf-origin.git" "$TMP/bf-push2"
(cd "$TMP/bf-push2" && echo other > g.txt && "${GITC[@]}" add g.txt && "${GITC[@]}" commit -qm "other work" && git push -q origin main)
(cd "$TMP/bf-work" && echo v4 > f.txt && "${GITC[@]}" commit -qam "local oops" && git fetch -q origin)
bf_main_before="$(git -C "$TMP/bf-work" rev-parse main)"
out="$("$BF_SCRIPT" "$TMP/bf-work" feat/e)"
assert_rc "分岔 → exit 1" 1 $?
if echo "$out" | grep -q "verdict: STOP"; then ok "分岔 → STOP（交回使用者）"; else bad "分岔未 STOP（${out}）"; fi
assert_eq "分岔 STOP 後 main ref 未動" "$bf_main_before" "$(git -C "$TMP/bf-work" rev-parse main)"
if git -C "$TMP/bf-work" show-ref --verify -q refs/heads/feat/e; then bad "分岔 STOP 卻建了 branch"; else ok "分岔 STOP 未建 branch"; fi

# 無 remote → STOP（無法核對誤 commit 是否已被 remote 涵蓋 → ambiguous；驗原因避免
# 未來 STOP 換理由時假綠）
out="$("$BF_SCRIPT" "$TMP/gh-local" feat/x)"
assert_rc "無 remote → exit 1" 1 $?
if echo "$out" | grep -q "verdict: STOP（無 remote"; then ok "無 remote → STOP（含原因）"; else bad "無 remote 未 STOP 或原因缺失"; fi

# 非 git repo / 用法錯誤
"$BF_SCRIPT" "$TMP/not-a-repo" feat/x >/dev/null 2>&1
assert_rc "非 git repo → exit 1" 1 $?
"$BF_SCRIPT" >/dev/null 2>&1
assert_rc "無引數 → exit 2" 2 $?
"$BF_SCRIPT" "$TMP/bf-work" >/dev/null 2>&1
assert_rc "缺 branch 名 → exit 2" 2 $?
"$BF_SCRIPT" "$TMP/bf-work" "bad..name" >/dev/null 2>&1
assert_rc "非法 branch 名 → exit 2" 2 $?

echo "▶ 10. review-state.sh scope-priority / round 判定"

# fixture：bare origin + clone，main 已 push
git init --bare -q -b main "$TMP/rs-origin.git"
git init -q -b main "$TMP/rs-work"
(cd "$TMP/rs-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/rs-origin.git" && git push -qu origin main)

# dirty tree（modified + untracked）→ priority 2
(cd "$TMP/rs-work" && echo v2 > f.txt && echo new > new.txt)
out="$("$RS_SCRIPT" "$TMP/rs-work")"
assert_rc "dirty tree 偵測 → exit 0" 0 $?
if echo "$out" | grep -q "scope-priority: 2"; then ok "dirty tree → priority 2"; else bad "dirty tree 未判 priority 2"; fi
if echo "$out" | grep -qA2 "untracked" && echo "$out" | grep -q "new.txt"; then ok "untracked 另列（diff HEAD 不含）"; else bad "untracked 未另列"; fi

# feature branch 領先、tree clean → priority 3 + merge-base
(cd "$TMP/rs-work" && git checkout -q -- f.txt && rm new.txt \
    && git switch -qc feat/y && echo v3 > f.txt && "${GITC[@]}" commit -qam "feat: y")
mb_expect="$(git -C "$TMP/rs-work" rev-parse origin/main)"
out="$("$RS_SCRIPT" "$TMP/rs-work")"
if echo "$out" | grep -q "scope-priority: 3"; then ok "clean+領先 → priority 3"; else bad "未判 priority 3"; fi
if echo "$out" | grep -q "base: origin/main"; then ok "base 偵測 origin/main"; else bad "base 偵測錯誤"; fi
if echo "$out" | grep -q "hash-merge-base: $mb_expect"; then ok "merge-base = 分叉點（squash base 候選）"; else bad "merge-base 錯誤"; fi
if echo "$out" | grep -q "round: 1"; then ok "無 fix commit → Round 1"; else bad "round 誤判"; fi

# 加 fix commit → Round 2
(cd "$TMP/rs-work" && echo v4 > f.txt && "${GITC[@]}" commit -qam "fix: R1 review fixes")
out="$("$RS_SCRIPT" "$TMP/rs-work")"
if echo "$out" | grep -q "round: 2"; then ok "1 個 fix commit → Round 2"; else bad "fix commit 輪次誤判"; fi

# 現行中性格式（主 agent 階段 + codex 階段）在 round 端也要認得——上面只驗到舊的 R{N} 格式，
# review-state 側對主要格式的 ^(...)$ 錨定屬未測路徑
(cd "$TMP/rs-work" && echo v5 > f.txt && "${GITC[@]}" commit -qam "fix: address review findings")
out="$("$RS_SCRIPT" "$TMP/rs-work")"
if echo "$out" | grep -q "round: 3"; then ok "中性主格式計入 round"; else bad "中性主格式未被 round 偵測認出"; fi
(cd "$TMP/rs-work" && echo v6 > f.txt && "${GITC[@]}" commit -qam "fix: address external review findings")
out="$("$RS_SCRIPT" "$TMP/rs-work")"
if echo "$out" | grep -q "round: 4"; then ok "codex 階段格式計入 round"; else bad "codex 階段格式未被 round 偵測認出"; fi

# 使用者自寫的 fix: 中斷連續段 → 輪次歸零重算。
# 注意 round 與 squash 是刻意不同的集合：`wip:` 中斷 round、卻會被 squash 收攏，
# 兩者邊界因此不同（見 review-state.sh 註解），不要把這兩組斷言互相對齊。
(cd "$TMP/rs-work" && echo v7 > f.txt && "${GITC[@]}" commit -qam "fix: 修正邊界處理")
out="$("$RS_SCRIPT" "$TMP/rs-work")"
if echo "$out" | grep -q "round: 1"; then ok "使用者自寫的 fix: 中斷連續段 → round 歸 1"; else bad "使用者的 fix: 未中斷計數（會灌水吃掉 R5 預算）"; fi

# 跨場次殘留不得灌進新一場：上一場被語意 commit 隔開而未壓掉的 review commit（squash-note
# 情境）仍在 branch 下層，新一場的輪次只能數自己這段——全範圍計數在此會得 round 5。
(cd "$TMP/rs-work" && echo v8 > f.txt && "${GITC[@]}" commit -qam "fix: address review findings")
out="$("$RS_SCRIPT" "$TMP/rs-work")"
if echo "$out" | grep -q "round: 2"; then ok "更早場次的殘留 review commit 不計入新一場"; else bad "跨場次殘留灌進 round（白吃修復輪次額度）"; fi

# wip snapshot 位於連續段底部（真實流程的位置）→ 不算輪次，也不影響其上 fix 的計數
git clone -q "$TMP/rs-origin.git" "$TMP/rs-wip"
(cd "$TMP/rs-wip" && git switch -qc feat/wip \
    && echo w1 > w.txt && "${GITC[@]}" add w.txt && "${GITC[@]}" commit -qm "wip: pre-review snapshot" \
    && echo w2 > w.txt && "${GITC[@]}" commit -qam "fix: address review findings")
out="$("$RS_SCRIPT" "$TMP/rs-wip")"
if echo "$out" | grep -q "round: 2"; then ok "wip snapshot 不算輪次（其上的 fix 照常計）"; else bad "wip snapshot 計數錯誤"; fi

# clean 且與 base 同步 → priority 4 MUST ASK
git clone -q "$TMP/rs-origin.git" "$TMP/rs-clean"
out="$("$RS_SCRIPT" "$TMP/rs-clean")"
if echo "$out" | grep -q "scope-priority: 4" && echo "$out" | grep -q "MUST ASK USER"; then
    ok "clean 同步 → priority 4 + MUST ASK USER"
else bad "priority 4 gate 輸出缺失"; fi

# local-only repo（無 remote，有本地 main）→ base 退用本地 branch
out="$("$RS_SCRIPT" "$TMP/gh-local")"
if echo "$out" | grep -q "base: main"; then ok "無 remote → base 退用本地 main"; else bad "本地 base fallback 錯誤"; fi

"$RS_SCRIPT" "$TMP/not-a-repo" >/dev/null 2>&1
assert_rc "非 git repo → exit 1" 1 $?
"$RS_SCRIPT" >/dev/null 2>&1
assert_rc "無引數 → exit 2" 2 $?

# --- branch-first / continuity / empty-tree（增量輸出行）---

# feature branch（rs-work 現在 feat/y、clean）→ 資訊行、無 continuity
out="$("$RS_SCRIPT" "$TMP/rs-work")"
if echo "$out" | grep -q "branch-first: 已在 feature branch（feat/y）"; then ok "feature branch → branch-first 資訊行"; else bad "feature branch branch-first 誤判"; fi
if echo "$out" | grep -q "continuity: WARNING"; then bad "clean tree 不應有 continuity 警告"; else ok "clean tree 無 continuity 警告"; fi

# dirty + ahead>0 → continuity WARNING
(cd "$TMP/rs-work" && echo v5 > f.txt)
out="$("$RS_SCRIPT" "$TMP/rs-work")"
if echo "$out" | grep -q "continuity: WARNING"; then ok "dirty+ahead → continuity WARNING"; else bad "continuity 警告缺失"; fi
(cd "$TMP/rs-work" && git checkout -q -- f.txt)

# HEAD 在 main（rs-clean、priority 4）→ REQUIRED + branch-cmd + empty-tree 常數
out="$("$RS_SCRIPT" "$TMP/rs-clean")"
if echo "$out" | grep -q "branch-first: REQUIRED"; then ok "HEAD 在 main → branch-first REQUIRED"; else bad "main branch-first 誤判"; fi
if echo "$out" | grep -qF "branch-cmd: git -C '$TMP/rs-clean' switch -c <type>/<slug>"; then ok "branch-cmd 印出待填指令"; else bad "branch-cmd 缺失"; fi
if echo "$out" | grep -q "empty-tree: 4b825dc642cb6eb9a060e54bf8d69288fbee4904"; then ok "priority 4 印 empty-tree 常數"; else bad "empty-tree 常數缺失"; fi

# dirty 但 ahead=0 → 無 continuity（兩條件須同時成立）
(cd "$TMP/rs-clean" && echo x > d.txt)
out="$("$RS_SCRIPT" "$TMP/rs-clean")"
if echo "$out" | grep -q "continuity: WARNING"; then bad "ahead=0 不應有 continuity 警告"; else ok "dirty 但 ahead=0 → 無 continuity 警告"; fi
(cd "$TMP/rs-clean" && rm d.txt)

# detached HEAD → REQUIRED
git clone -q "$TMP/rs-origin.git" "$TMP/rs-detach"
(cd "$TMP/rs-detach" && git checkout -q --detach)
out="$("$RS_SCRIPT" "$TMP/rs-detach")"
if grep -q "branch-first: REQUIRED（HEAD 在 DETACHED" <<< "$out"; then ok "detached HEAD → branch-first REQUIRED"; else bad "detached branch-first 誤判"; fi

echo "▶ 11. portable review-scope range / historical guidance / autofix gate"
DRS_CLAUDE="$ROOT/claude/skills/deep-review"
RRS_CODEX="$ROOT/codex/skills/repo-review"
DR_SCOPE="$DRS_CLAUDE/scripts/review-scope.sh"
if python3 "$ROOT/tests/review-readonly.py" "$ROOT"; then
    ok "review inspection preserves target files and Git metadata"
else bad "review inspection mutated target metadata"; fi
DR_EMPTY_TREE="4b825dc642cb6eb9a060e54bf8d69288fbee4904"

git init -q -b main "$TMP/drs-context"
(cd "$TMP/drs-context" \
    && mkdir -p src \
    && printf 'root historical\n' > AGENTS.md \
    && printf 'subtree historical\n' > src/AGENTS.md \
    && printf 'v1\n' > src/app.txt \
    && "${GITC[@]}" add AGENTS.md src/AGENTS.md src/app.txt \
    && "${GITC[@]}" commit -qm init)
drs_base="$(git -C "$TMP/drs-context" rev-parse HEAD)"
(cd "$TMP/drs-context" && printf 'v2\n' > src/app.txt && "${GITC[@]}" commit -qam change)
drs_historical_head="$(git -C "$TMP/drs-context" rev-parse HEAD)"
drs_historical_guidance="$(git -C "$TMP/drs-context" rev-parse "$drs_historical_head:src/AGENTS.md")"
(cd "$TMP/drs-context" \
    && git rm -q src/AGENTS.md \
    && printf 'root current\n' > AGENTS.md \
    && "${GITC[@]}" commit -qam current)

/bin/bash "$DR_SCOPE" capture --repo "$TMP/drs-context" --mode working-tree >/dev/null 2>&1
assert_rc "review-scope 空 path list 相容 macOS Bash 3.2" 0 $?

drs_capture_runner=(/bin/bash)
drs_capture_environment='portable control'
if [ -x /usr/bin/sandbox-exec ]; then
    drs_device_policy='(version 1)(allow default)(deny file-write* (subpath "/dev"))(allow file-write* (literal "/dev/null"))'
    drs_capture_runner=(/usr/bin/sandbox-exec -p "$drs_device_policy" /bin/bash)
    drs_capture_environment='sandbox device restriction'
fi
drs_control="$(/bin/bash "$DR_SCOPE" capture --repo "$TMP/drs-context" --mode working-tree)"
drs_capture="$("${drs_capture_runner[@]}" "$DR_SCOPE" capture --repo "$TMP/drs-context" --mode working-tree 2>&1)"
assert_rc "review-scope capture（${drs_capture_environment}）" 0 $?
drs_control_fingerprint="$(sed -n 's/^fingerprint: //p' <<< "$drs_control")"
if [ -n "$drs_control_fingerprint" ] && [ "$drs_control_fingerprint" = "$(sed -n 's/^fingerprint: //p' <<< "$drs_capture")" ]; then
    ok "capture fingerprint 相同（${drs_capture_environment}）"
else bad "capture fingerprint 遺失或改變（${drs_capture_environment}）"; fi
drs_capture_manifest="$(sed -n 's/^manifest: //p' <<< "$drs_capture")"
"${drs_capture_runner[@]}" "$DR_SCOPE" verify --manifest "$drs_capture_manifest" >/dev/null 2>&1
assert_rc "capture 後仍能 verify scope（${drs_capture_environment}）" 0 $?

out="$("$DR_SCOPE" capture --repo "$TMP/drs-context" --mode range \
    --range "$drs_base..$drs_historical_head")"
assert_rc "portable range capture → exit 0" 0 $?
drs_context_manifest="$(sed -n 's/^manifest: //p' <<< "$out")"
drs_context_show="$("$DR_SCOPE" show --manifest "$drs_context_manifest")"
if grep -q "^base: $drs_base$" <<< "$drs_context_show" \
    && grep -q "^head: $drs_historical_head$" <<< "$drs_context_show"; then
    ok "range endpoints 固定為 immutable object IDs"
else bad "range endpoints 解析錯誤"; fi
if grep -q '^guidance-source: head$' <<< "$drs_context_show" \
    && grep -q "guidance: head .* AGENTS.md$" <<< "$drs_context_show" \
    && grep -q "guidance: head $drs_historical_guidance src/AGENTS.md$" <<< "$drs_context_show"; then
    ok "historical range 從 resolved head tree 取得 root + subtree guidance"
else bad "historical guidance 被 current worktree 污染或遺漏"; fi
"$DR_SCOPE" verify --manifest "$drs_context_manifest" >/dev/null
assert_rc "current checkout 前進不污染 immutable historical range" 0 $?
drs_noncurrent="$("$DR_SCOPE" autofix-check --manifest "$drs_context_manifest" 2>/dev/null)"
assert_rc "historical non-current head autofix → BLOCKED" 5 $?
if grep -q '^autofix-reason: requested-head-not-current$' <<< "$drs_noncurrent"; then
    ok "non-current head autofix reason 明確"
else bad "non-current head autofix reason 錯誤"; fi

empty_out="$("$DR_SCOPE" capture --repo "$TMP/drs-context" --mode range \
    --range "$DR_EMPTY_TREE..HEAD")"
empty_manifest="$(sed -n 's/^manifest: //p' <<< "$empty_out")"
if grep -q '^base-type: tree$' <<< "$empty_out" && grep -q '^baseline: yes$' <<< "$empty_out"; then
    ok "canonical empty-tree baseline 可固定為全量 range"
else bad "empty-tree baseline range 不相容"; fi
"$DR_SCOPE" autofix-check --manifest "$empty_manifest" >/dev/null
assert_rc "empty-tree current-head structural autofix gate → yes" 0 $?

arbitrary_tree="$(git -C "$TMP/drs-context" rev-parse 'HEAD^{tree}')"
tree_out="$("$DR_SCOPE" capture --repo "$TMP/drs-context" --mode range \
    --range "$arbitrary_tree..HEAD")"
tree_manifest="$(sed -n 's/^manifest: //p' <<< "$tree_out")"
tree_gate="$("$DR_SCOPE" autofix-check --manifest "$tree_manifest" 2>/dev/null)"
assert_rc "arbitrary tree base autofix → BLOCKED" 5 $?
if grep -q '^autofix-reason: arbitrary-tree-base$' <<< "$tree_gate"; then
    ok "arbitrary tree 不冒充 ancestor"
else bad "arbitrary tree autofix reason 錯誤"; fi

drs_main_tip="$(git -C "$TMP/drs-context" rev-parse HEAD)"
(cd "$TMP/drs-context" \
    && git switch -qc feat/diverge "$drs_base" \
    && printf 'side\n' > side.txt \
    && "${GITC[@]}" add side.txt \
    && "${GITC[@]}" commit -qm side)
diverge_out="$("$DR_SCOPE" capture --repo "$TMP/drs-context" --mode range \
    --range "$drs_main_tip..HEAD")"
diverge_manifest="$(sed -n 's/^manifest: //p' <<< "$diverge_out")"
if grep -q '^base-is-ancestor: no$' <<< "$diverge_out" \
    && ! grep -q '^merge-base: (none)$' <<< "$diverge_out"; then
    ok "divergent commit pair 記錄 merge base"
else bad "divergent range ancestry 訊號錯誤"; fi
diverge_gate="$("$DR_SCOPE" autofix-check --manifest "$diverge_manifest" 2>/dev/null)"
assert_rc "divergent range autofix → BLOCKED" 5 $?
if grep -q '^autofix-reason: base-not-ancestor$' <<< "$diverge_gate"; then
    ok "divergent range autofix reason 明確"
else bad "divergent range autofix reason 錯誤"; fi

attached_out="$("$DR_SCOPE" capture --repo "$TMP/drs-context" --mode range \
    --range "$drs_base..HEAD")"
attached_manifest="$(sed -n 's/^manifest: //p' <<< "$attached_out")"
git -C "$TMP/drs-context" checkout -q --detach HEAD
detached_gate="$("$DR_SCOPE" autofix-check --manifest "$attached_manifest" 2>/dev/null)"
assert_rc "detached HEAD autofix → BLOCKED" 5 $?
if grep -q '^autofix-reason: detached-head$' <<< "$detached_gate"; then
    ok "detached HEAD autofix reason 明確"
else bad "detached HEAD autofix reason 錯誤"; fi

"$DR_SCOPE" capture --repo "$TMP/not-a-repo" --mode working-tree >/dev/null 2>&1
assert_rc "review-scope 非 git repo → exit 3" 3 $?
"$DR_SCOPE" capture --repo "$TMP/drs-context" --mode range --range 'HEAD...HEAD' >/dev/null 2>&1
assert_rc "review-scope three-dot range → exit 4" 4 $?
"$DR_SCOPE" >/dev/null 2>&1
assert_rc "review-scope 無引數 → exit 2" 2 $?

echo "▶ 12. repo-review 薄殼 packaging"
if [ -f "$ROOT/shared/skills/deep-review/evals.md" ] \
    && [ "$DRS_CLAUDE/evals.md" -ef "$ROOT/shared/skills/deep-review/evals.md" ] \
    && [ ! -e "$RRS_CODEX/evals.md" ]; then
    ok "behavior oracle 實體只留 neutral core，Claude compatibility path 共用 inode"
else bad "repo-review adapter 重複暴露或缺少 canonical eval oracle"; fi
if python3 - "$ROOT/.doc-governance.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    config = json.load(stream)
skill_eval = next(item for item in config["classes"] if item["name"] == "skill-eval")
raise SystemExit(skill_eval["paths"] != ["shared/skills/*/evals.md"])
PY
then
    ok "doc-governance 只分類 canonical eval tree，不要求 adapter 重複 eval"
else bad "doc-governance 仍要求 Codex adapter eval，與 single-oracle 架構衝突"; fi
if ! grep -qi 'evals\.md' "$RRS_CODEX/SKILL.md"; then
    ok "repo-review runtime entry 不載入 eval oracle"
else bad "repo-review runtime entry 不應連結 evals.md"; fi
rrs_lines="$(wc -l < "$RRS_CODEX/SKILL.md" | tr -d ' ')"
if [ "$rrs_lines" -le 30 ] \
    && grep -q 'references/workflow.md' "$RRS_CODEX/SKILL.md" \
    && grep -q 'references/portable-reviewer-brief.md' "$RRS_CODEX/SKILL.md"; then
    ok "repo-review 是薄入口，不複製 shared workflow"
else bad "repo-review adapter 過厚或未路由 shared resources"; fi
if [ ! -e "$RRS_CODEX/scripts/review-context.sh" ] \
    && [ ! -e "$RRS_CODEX/references/reviewer-brief.md" ]; then
    ok "repo-review 舊獨立 helper 與 brief 已退役"
else bad "repo-review 仍殘留第二套 runtime contract"; fi
