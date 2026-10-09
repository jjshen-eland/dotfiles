#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
runtime_tilde='~'
echo "▶ 12d. handoff skill 跨 Claude Code／Codex 共用核心與 state store"
HFS_CLAUDE="$ROOT/claude/skills/handoff"
HFS_CODEX="$ROOT/codex/skills/handoff"
HFS_SCRIPT="$HFS_CLAUDE/scripts/handoff-anchor.sh"
if [ -f "$HFS_CLAUDE/SKILL.md" ] && [ -f "$HFS_CODEX/SKILL.md" ] \
    && [ "$HFS_CODEX/references" -ef "$HFS_CLAUDE/references" ] \
    && [ "$HFS_CODEX/scripts" -ef "$HFS_CLAUDE/scripts" ]; then
    ok "handoff 兩個薄入口共用 canonical references/scripts"
else bad "handoff 跨 runtime 封裝未共用同一核心"; fi
if grep -q 'references/workflow.md' "$HFS_CLAUDE/SKILL.md" \
    && grep -q 'references/workflow.md' "$HFS_CODEX/SKILL.md" \
    && [ -f "$HFS_CODEX/references/workflow.md" ]; then
    ok "handoff 兩個入口都載入 shared workflow"
else bad "handoff 入口未共同指向 shared workflow"; fi
if [ "$(grep -c '<handoff-anchor> survey \[--slug <slug>\] <handoff-directory>' \
        "$HFS_CLAUDE/references/workflow.md")" -eq 2 ]; then
    ok "handoff write／resume survey 都明確使用 resolver 回傳的 store"
else bad "handoff survey 可能丟失 store resolver 結果、回到 runtime 預設路徑"; fi
handoff_env_name="HANDOFF_DIR"
if grep -q '不得把它當 slug' "$HFS_CLAUDE/SKILL.md" \
    && grep -q '不得把它當 slug' "$HFS_CODEX/SKILL.md" \
    && grep -q "ambient \`$handoff_env_name\`" "$HFS_CLAUDE/SKILL.md" \
    && grep -q "ambient \`$handoff_env_name\`" "$HFS_CODEX/SKILL.md"; then
    ok "handoff 兩個 adapter 都隔離 store control token 與 slug，不信任 ambient override"
else bad "handoff adapter 的 HANDOFF_DIR control token 或 ambient-env 邊界不一致"; fi
hfs_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$HFS_CODEX/SKILL.md")"
if ! grep -Eq '^(user-invocable|disable-model-invocation|argument-hint|allowed-tools|context|agent):' \
    <<< "$hfs_codex_frontmatter"; then
    ok "Codex handoff frontmatter 無 Claude Code 專屬欄位"
else bad "Codex handoff frontmatter 混入 Claude Code 專屬欄位"; fi
handoff_sig="\$handoff"
if [ -f "$HFS_CODEX/agents/openai.yaml" ] \
    && grep -qF "$handoff_sig" "$HFS_CODEX/agents/openai.yaml"; then
    ok "Codex handoff 有可發現的 UI metadata"
else bad "Codex handoff 缺 openai.yaml 或 default prompt 未提 skill"; fi
if ! rg -q "${runtime_tilde}/.claude/skills/handoff|${runtime_tilde}/.codex/skills/handoff" \
    "$HFS_CLAUDE/references" "$HFS_CLAUDE/scripts"; then
    ok "handoff shared core 不綁 runtime skill 安裝路徑"
else bad "handoff shared core 仍綁 Claude／Codex 私有 skill path"; fi
if grep -q 'handoff invocation 本身不授權編輯' "$ROOT/shared/skills/handoff/evals.md" \
    && grep -q 'repo 內檔案必須 byte-identical' "$ROOT/shared/skills/handoff/evals.md" \
    && grep -q '只有使用者已另行授權該 repo mutation 時才寫入' \
        "$HFS_CLAUDE/references/workflow.md"; then
    ok "handoff 續寫 oracle 不把 durable-doc repo mutation 當隱性授權"
else bad "handoff 續寫 workflow／eval 仍可能未授權改 repo"; fi
handoff_write_contract="$(sed -n '/^## Write mode/,/^## Resume mode/p' \
    "$HFS_CLAUDE/references/workflow.md")"
handoff_write_order="$(awk '
    /^### W2：沉澱 durable facts$/ { route = NR }
    /^### W3：蓋最終錨點$/ { anchor = NR }
    /^### W4：寫檔$/ { artifact = NR }
    END { printf "%d %d %d\n", route + 0, anchor + 0, artifact + 0 }
' "$HFS_CLAUDE/references/workflow.md")"
read -r handoff_route_line handoff_anchor_line handoff_artifact_line <<< "$handoff_write_order"
handoff_stale_dirty_claim='anchor 的 '
handoff_stale_dirty_claim="${handoff_stale_dirty_claim}\`dirty=1\` 就是上述兩個未 commit 檔案"
if [ "$handoff_route_line" -gt 0 ] \
    && [ "$handoff_route_line" -lt "$handoff_anchor_line" ] \
    && [ "$handoff_anchor_line" -lt "$handoff_artifact_line" ] \
    && grep -q '所有已授權的 repo mutation.*anchors 前完成' <<< "$handoff_write_contract" \
    && grep -q 'H5b — write-side：已授權 durable mutation 必須先於最終錨點' \
        "$ROOT/shared/skills/handoff/evals.md" \
    && grep -qF "$handoff_stale_dirty_claim" \
        "$ROOT/shared/skills/handoff/evals.md"; then
    ok "handoff durable mutation 先於最終 anchors，且 H5b 釘住 dirty 敘述回歸"
else bad "handoff 仍可能在 anchors 後修改 repo，讓 dirty=N 與交接敘述過期"; fi
if grep -q 'H14 — cross-host' "$ROOT/shared/skills/handoff/evals.md" \
    && grep -q 'Memory availability' "$HFS_CLAUDE/references/workflow.md" \
    && grep -q 'authorization.*不得.*carry' "$HFS_CLAUDE/references/workflow.md"; then
    ok "handoff 不以 machine-local memory/checkpoint 承擔 project transfer 或授權延續"
else bad "handoff 缺 memory-independent cross-host／authorization 邊界"; fi

HFS_HOME="$TMP/handoff-store-home"
mkdir -p "$HFS_HOME"
out="$(HOME="$HFS_HOME" "$HFS_SCRIPT" store)"
assert_rc "store 無既存資料 → exit 0" 0 $?
if grep -qF "handoff-dir: $HFS_HOME/.agents/handoffs" <<< "$out" \
    && grep -q '^store-status: NEW$' <<< "$out" \
    && [ -d "$HFS_HOME/.agents/handoffs" ]; then
    ok "新安裝選 runtime-neutral canonical store 並建立可用目錄"
else bad "新安裝 store 路徑、狀態或目錄建立錯誤（${out}）"; fi

rm -rf "$HFS_HOME/.agents/handoffs"
mkdir -p "$HFS_HOME/.claude/handoffs"
out="$(HOME="$HFS_HOME" "$HFS_SCRIPT" store)"
assert_rc "store 只有 legacy 資料 → exit 0" 0 $?
if grep -qF "handoff-dir: $HFS_HOME/.claude/handoffs" <<< "$out" \
    && grep -q '^store-status: LEGACY$' <<< "$out"; then
    ok "既有 handoff 採 legacy-compatible store（不遺失資料）"
else bad "legacy store 未被安全沿用（${out}）"; fi

mkdir -p "$HFS_HOME/.agents/handoffs"
out="$(HOME="$HFS_HOME" "$HFS_SCRIPT" store 2>&1)"
assert_rc "canonical 與 legacy 分裂 → exit 1" 1 $?
if grep -q '^store-status: SPLIT$' <<< "$out"; then
    ok "兩份獨立 store → STOP，避免跨 harness split-brain"
else bad "split store 未被明確攔截（${out}）"; fi

rm -rf "$HFS_HOME/.agents/handoffs"
ln -s ../.claude/handoffs "$HFS_HOME/.agents/handoffs"
out="$(HOME="$HFS_HOME" "$HFS_SCRIPT" store)"
assert_rc "canonical symlink 指向 legacy → exit 0" 0 $?
if grep -q '^store-status: SHARED$' <<< "$out"; then
    ok "同一實體 store 可由兩個相容路徑共同使用"
else bad "同實體 store 被誤判 split（${out}）"; fi


echo "▶ 13. handoff-anchor.sh 錨點驗證與生命週期判定"
HA_SCRIPT="$ROOT/claude/skills/handoff/scripts/handoff-anchor.sh"
# 錨點記的是 `rev-parse --show-toplevel`，會解析 symlink（macOS 的 $TMPDIR 走 /var → /private/var），
# 故路徑期望值用解析後的形式；Linux 的 /tmp 無 symlink，兩者相同
HA_REAL="$(cd "$TMP" && pwd -P)"

# fixture：單 repo，1 commit
git init -q -b main "$TMP/ha-work"
(cd "$TMP/ha-work" && echo v1 > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init)

# anchors：格式與 dirty 計數
echo dirty > "$TMP/ha-work/untracked.txt"
out="$("$HA_SCRIPT" anchors "$TMP/ha-work")"
assert_rc "anchors 正常 repo → exit 0" 0 $?
if echo "$out" | grep -q "^created: " && echo "$out" | grep -q "^anchor: $HA_REAL/ha-work main .* dirty=1$"; then
    ok "anchors 輸出 created + anchor（dirty=1）"
else bad "anchors 輸出格式錯誤"; fi
rm "$TMP/ha-work/untracked.txt"

"$HA_SCRIPT" anchors "$TMP/not-a-repo" >/dev/null 2>&1
assert_rc "anchors 非 git repo → exit 1" 1 $?

# anchors：路徑含空白 → 寫入端擋下（anchor 行以空白分欄，這種錨點 verify 必誤判）
git init -q -b main "$TMP/ha spaced"
(cd "$TMP/ha spaced" && echo v1 > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init)
out="$("$HA_SCRIPT" anchors "$TMP/ha spaced" 2>&1)"
assert_rc "anchors 含空白路徑 → exit 1" 1 $?
if ! echo "$out" | grep -q "^anchor: " && echo "$out" | grep -q "含空白"; then
    ok "含空白路徑 → 報錯且不輸出 anchor 行"
else bad "含空白路徑未被寫入端擋下"; fi

# anchors：相對路徑／repo 子目錄輸入 → 錨點記 toplevel 絕對路徑。原樣記 `.` 的話，cwd 已不同的
# 新 session 會 verify 到別的 repo，且誤報成 DIVERGED「歷史改寫」（真相是路徑錯）→ 整份降級
mkdir -p "$TMP/ha-work/sub"
out="$(cd "$TMP/ha-work/sub" && "$HA_SCRIPT" anchors .)"
assert_rc "anchors 子目錄相對路徑 → exit 0" 0 $?
if echo "$out" | grep -q "^anchor: $HA_REAL/ha-work main "; then
    ok "相對路徑/子目錄輸入 → 錨點記 toplevel 絕對路徑"
else bad "錨點未正規化為 toplevel 絕對路徑（${out}）"; fi

# 空白檢查對解析後的 toplevel 而非原輸入——相對輸入本身無空白、toplevel 卻含空白時仍須擋下
out="$(cd "$TMP/ha spaced" && "$HA_SCRIPT" anchors . 2>&1)"
assert_rc "anchors 相對輸入但 toplevel 含空白 → exit 1" 1 $?
if ! echo "$out" | grep -q "^anchor: " && echo "$out" | grep -q "含空白"; then
    ok "含空白 toplevel 經相對路徑輸入仍被擋"
else bad "相對路徑繞過了 toplevel 空白檢查（${out}）"; fi

# --- 錨點完整性：寫入端原子輸出 ---
# 部分失敗仍印 created:/anchor: 的話，agent 會把「少一條錨點」的半成品貼進 frontmatter，
# 而 cmd_verify 只在**完全無錨點**時才判 UNVERIFIABLE——少一條時它什麼都不說，那個 repo
# 的交接內容從此沒有 checksum。stdout/stderr 必須分開捕捉：用 2>&1 驗原子輸出契約等於自廢武功
git init -q -b main "$TMP/ha-work2"
(cd "$TMP/ha-work2" && echo v1 > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init)

out="$("$HA_SCRIPT" anchors "$TMP/ha-work" "$TMP/not-a-repo" 2>/dev/null)"
assert_rc "anchors 混合 good/bad → exit 1" 1 $?
if [ -z "$out" ]; then ok "混合 good/bad → stdout 全空（不留半成品錨點）"
else bad "部分失敗仍輸出錨點行（${out}）"; fi

# unborn HEAD：合法 repo 但尚無 commit（新 repo 剛 git init 正是會寫交接檔的時機）。
# `rev-parse HEAD` 失敗卻沒被檢查時，字面字串 "HEAD" 被寫進 sha 欄位且 rc=0，之後
# verify 拿 HEAD^{commit} 解析永遠等於當下 HEAD → **永久判 FRESH**，比沒有錨點更糟
git init -q -b main "$TMP/ha-empty"
out="$("$HA_SCRIPT" anchors "$TMP/ha-work" "$TMP/ha-empty" 2>/dev/null)"
assert_rc "anchors 遇 unborn HEAD → exit 1" 1 $?
if [ -z "$out" ]; then ok "unborn HEAD → stdout 全空"
else bad "unborn HEAD 仍輸出錨點（${out}）"; fi

err="$("$HA_SCRIPT" anchors "$TMP/ha-empty" 2>&1 >/dev/null)"
if grep -q "尚無 commit" <<< "$err"; then ok "unborn HEAD 錯誤訊息點名「尚無 commit」（可操作）"
else bad "unborn HEAD 錯誤訊息不可操作（${err}）"; fi

# 成功路徑不得被原子化改壞
out="$("$HA_SCRIPT" anchors "$TMP/ha-work" "$TMP/ha-work2")"
assert_rc "anchors 兩個好 repo → exit 0" 0 $?
assert_eq "多 repo 恰一行 created" "1" "$(grep -c '^created: ' <<< "$out")"
assert_eq "多 repo 恰兩行 anchor" "2" "$(grep -c '^anchor: ' <<< "$out")"

# --- 錨點完整性：驗證端 canonical object ID ---
# 只修寫入端擋不住**既存**的壞錨點：手寫 head=HEAD 的檔案照樣會被判 FRESH。
# 判準用「解析結果 == 記錄值」而非硬編長度——SHA-1 是 40 hex、SHA-256 是 64 hex
mkdir -p "$TMP/ha-oid"
printf -- '---\ncreated: %s\nanchor: %s/ha-work main HEAD dirty=0\n---\n' \
    "$(date +%Y-%m-%d)" "$HA_REAL" > "$TMP/ha-oid/head-literal.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-oid/head-literal.md")"
assert_rc "verify head=HEAD 的錨點 → exit 1" 1 $?
if grep -q "BAD-ANCHOR" <<< "$out" && ! grep -q "status: FRESH" <<< "$out"; then
    ok "head=HEAD → BAD-ANCHOR（不得判 FRESH）"
else bad "head=HEAD 被當成有效錨點（${out}）"; fi

# 短 sha 同理——腳本檔頭早就警告它會隨物件增長變 ambiguous，這裡把警告變成守門
ha_short="$(git -C "$TMP/ha-work" rev-parse --short HEAD)"
printf -- '---\ncreated: %s\nanchor: %s/ha-work main %s dirty=0\n---\n' \
    "$(date +%Y-%m-%d)" "$HA_REAL" "$ha_short" > "$TMP/ha-oid/short-sha.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-oid/short-sha.md")"
assert_rc "verify 短 sha 錨點 → exit 1" 1 $?
if grep -q "BAD-ANCHOR" <<< "$out"; then ok "短 sha → BAD-ANCHOR（刻意收緊）"
else bad "短 sha 未被判 BAD-ANCHOR（${out}）"; fi

# SHA-256 repo 的正常路徑：長度期望由該 repo 的 rev-parse 推導，不在測試裡再硬編一次數字
if git init -q -b main --object-format=sha256 "$TMP/ha-256" 2>/dev/null; then
    (cd "$TMP/ha-256" && echo v1 > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init)
    ha256_sha="$(git -C "$TMP/ha-256" rev-parse HEAD)"
    out="$("$HA_SCRIPT" anchors "$TMP/ha-256")"
    assert_rc "anchors SHA-256 repo → exit 0" 0 $?
    assert_eq "SHA-256 錨點記完整 OID" "$ha256_sha" "$(awk '/^anchor: /{print $4}' <<< "$out")"
    { echo "---"; printf '%s\n' "$out"; echo "---"; } > "$TMP/ha-oid/sha256.md"
    out="$("$HA_SCRIPT" verify "$TMP/ha-oid/sha256.md")"
    assert_rc "verify SHA-256 repo 未動 → exit 0" 0 $?
    if grep -q "verdict: FRESH" <<< "$out"; then ok "SHA-256 repo 判 FRESH（判準不綁 40 hex）"
    else bad "SHA-256 repo 被誤判（${out}）"; fi
else
    bad "本機 git 不支援 --object-format=sha256——64 位 OID 守門未執行（git ≥ 2.29 才有）"
fi

# verify：FRESH
mkdir -p "$TMP/ha-handoffs"
{ echo "---"; "$HA_SCRIPT" anchors "$TMP/ha-work"; echo "---"; echo "# Handoff: test"; } > "$TMP/ha-handoffs/t.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/t.md")"
assert_rc "verify 未動的 repo → exit 0" 0 $?
if echo "$out" | grep -q "verdict: FRESH"; then ok "未動的 repo → FRESH"; else bad "未判 FRESH"; fi

# verify 的 metadata 邊界：正文可以引用 created/anchor 範例，但不能參與驗證。
# 一份有效交接若因正文範例多出壞錨點而降級，就是 false STALE-RISK。
{ echo "---"; "$HA_SCRIPT" anchors "$TMP/ha-work"; echo "---";
  printf '\n~~~text\nanchor: /example/not-a-repo main 0000000000000000000000000000000000000000 dirty=0\n~~~\n';
} > "$TMP/ha-handoffs/body-example.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/body-example.md")"
assert_rc "verify 忽略正文錨點範例 → exit 0" 0 $?
if echo "$out" | grep -q 'verdict: FRESH' && ! echo "$out" | grep -q 'status: MISSING'; then
    ok "正文錨點範例不造成假 STALE-RISK"
else bad "正文錨點範例污染驗證結果（${out}）"; fi

# 更嚴重的反面：沒有 frontmatter，只有正文 code block 的 metadata，不能假裝通過驗證。
{ echo '```text'; "$HA_SCRIPT" anchors "$TMP/ha-work"; echo '```'; } > "$TMP/ha-handoffs/body-only.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/body-only.md")"
assert_rc "verify 只有正文範例 → exit 1" 1 $?
if echo "$out" | grep -q 'age: UNKNOWN' && echo "$out" | grep -q 'verdict: UNVERIFIABLE' \
    && ! echo "$out" | grep -q 'status: FRESH'; then
    ok "正文 metadata 不會假放行"
else bad "正文 metadata 被誤認為 frontmatter（${out}）"; fi

# 缺失的 dirty 欄位使錨點不完整；HEAD 恰相同也不得 FRESH。
{ echo '---'; "$HA_SCRIPT" anchors "$TMP/ha-work" | sed 's/ dirty=[0-9][0-9]*$//'; echo '---'; } \
    > "$TMP/ha-handoffs/missing-dirty.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/missing-dirty.md")"
assert_rc "verify 缺 dirty 欄位 → exit 1" 1 $?
if echo "$out" | grep -q 'status: BAD-ANCHOR' && ! echo "$out" | grep -q 'status: FRESH'; then
    ok "缺 dirty 欄位不得 FRESH"
else bad "缺 dirty 欄位被放行（${out}）"; fi

# verify：DRIFTED（記錄後 repo 前進，列出中間 commit）
(cd "$TMP/ha-work" && echo v2 > f.txt && "${GITC[@]}" commit -qam "advance after handoff")
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/t.md")"
assert_rc "verify 前進後的 repo → exit 1" 1 $?
if echo "$out" | grep -q "status: DRIFTED" && echo "$out" | grep -q "advance after handoff"; then
    ok "repo 前進 → DRIFTED + 列中間 commit"
else bad "DRIFTED 判定或 commit 清單缺失"; fi
if echo "$out" | grep -q "verdict: STALE-RISK"; then ok "DRIFTED → verdict STALE-RISK"; else bad "verdict 未標 STALE-RISK"; fi

# verify：DIVERGED（記錄的 HEAD 被 rebase 掉、不在現行歷史）
{ echo "---"; "$HA_SCRIPT" anchors "$TMP/ha-work"; echo "---"; } > "$TMP/ha-handoffs/t.md"
(cd "$TMP/ha-work" && echo v3 > f.txt && "${GITC[@]}" commit -qa --amend -m "rewritten")
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/t.md")"
assert_rc "verify 歷史改寫 → exit 1" 1 $?
if echo "$out" | grep -q "status: DIVERGED"; then ok "歷史改寫 → DIVERGED"; else bad "未判 DIVERGED"; fi

# verify：MISSING（repo 路徑不存在）
printf -- '---\ncreated: %s\nanchor: %s/gone main abc1234 dirty=0\n---\n' "$(date +%Y-%m-%d)" "$TMP" > "$TMP/ha-handoffs/t.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/t.md")"
assert_rc "verify repo 消失 → exit 1" 1 $?
if echo "$out" | grep -q "status: MISSING"; then ok "repo 消失 → MISSING"; else bad "未判 MISSING"; fi

# verify：EXPIRED（created 超過 EXPIRE_DAYS）
{ echo "---"; echo "created: 2026-01-01"; "$HA_SCRIPT" anchors "$TMP/ha-work" | grep '^anchor: '; echo "---"; } > "$TMP/ha-handoffs/t.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/t.md")"
assert_rc "verify 過期交接檔 → exit 1" 1 $?
if echo "$out" | grep -q "EXPIRED"; then ok "created 超過 7 天 → EXPIRED"; else bad "未標 EXPIRED"; fi

# verify：無錨點 → UNVERIFIABLE
printf -- '---\ncreated: %s\n---\nno anchors here\n' "$(date +%Y-%m-%d)" > "$TMP/ha-handoffs/t.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/t.md")"
assert_rc "verify 無錨點 → exit 1" 1 $?
if echo "$out" | grep -q "verdict: UNVERIFIABLE"; then ok "無錨點 → UNVERIFIABLE"; else bad "未判 UNVERIFIABLE"; fi

"$HA_SCRIPT" verify "$TMP/ha-handoffs/no-such.md" >/dev/null 2>&1
assert_rc "verify 檔案不存在 → exit 1" 1 $?

# verify：錨點行欄位不足（手寫殘缺）→ BAD-ANCHOR 優雅判定，不裸崩潰
printf -- '---\ncreated: %s\nanchor: %s/ha-work\n---\n' "$(date +%Y-%m-%d)" "$TMP" > "$TMP/ha-handoffs/t.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/t.md" 2>&1)"
assert_rc "verify 欄位不足錨點 → exit 1" 1 $?
if echo "$out" | grep -q "status: BAD-ANCHOR" && ! echo "$out" | grep -q "unbound variable"; then
    ok "欄位不足 → BAD-ANCHOR（無 bash 錯誤）"
else bad "欄位不足錨點未優雅判定"; fi

# verify：錨點路徑含 glob 字元 → 不做 pathname expansion（欄位原樣進判定）
printf -- '---\ncreated: %s\nanchor: * main abc1234 dirty=0\n---\n' "$(date +%Y-%m-%d)" > "$TMP/ha-handoffs/t.md"
out="$("$HA_SCRIPT" verify "$TMP/ha-handoffs/t.md")"
assert_rc "verify glob 字元錨點 → exit 1" 1 $?
if echo "$out" | grep -q "recorded: branch=main head=abc1234" && echo "$out" | grep -q "status: MISSING"; then
    ok "glob 字元不展開 → 判 MISSING"
else bad "glob 字元錨點被 pathname expansion 展開"; fi

# list：EXPIRED 標記 + archive 自動清理
rm "$TMP/ha-handoffs/t.md"
printf -- '---\ncreated: %s\n---\n' "$(date +%Y-%m-%d)" > "$TMP/ha-handoffs/fresh.md"
printf -- '---\ncreated: 2026-01-01\n---\n' > "$TMP/ha-handoffs/old.md"
mkdir -p "$TMP/ha-handoffs/archive"
printf 'consumed\n' > "$TMP/ha-handoffs/archive/20260101-dead.md"
touch -t 202601011200 "$TMP/ha-handoffs/archive/20260101-dead.md"
printf 'consumed\n' > "$TMP/ha-handoffs/archive/recent.md"
out="$("$HA_SCRIPT" list "$TMP/ha-handoffs")"
assert_rc "list → exit 0" 0 $?
# 時戳欄的值會變（取 mtime），故用 pattern 吃掉；但 `0d` 與 `OK` **仍必須被斷言**——
# 只留 `grep -q "active: fresh.md"` 也會全綠，那格從此不再守 age 與 flag
if echo "$out" | grep -qE '^active: fresh\.md — 更新 [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} — 0d — OK$'; then
    ok "list 新檔標 OK（含 mtime 時戳欄）"
else bad "list 新檔標記錯誤或缺時戳欄"; fi
if echo "$out" | grep "active: old.md" | grep -q "EXPIRED"; then ok "list 過期檔標 EXPIRED"; else bad "list 未標 EXPIRED"; fi
if [ ! -f "$TMP/ha-handoffs/archive/20260101-dead.md" ] && [ -f "$TMP/ha-handoffs/archive/recent.md" ]; then
    ok "list 清超過保留期的 archive、留新的"
else bad "archive 清理行為錯誤"; fi
if echo "$out" | grep -q "archive: 已清 1 份"; then ok "list 回報清理數量"; else bad "list 未回報清理"; fi

# list：path 行（verify/consume 吃完整路徑，讀取端不必手拼）與 title 行（多份待選時只看 slug
# 分不出是哪條工作線）；無標題行的檔整行省略，不留空欄位
printf -- '---\ncreated: %s\n---\n# Handoff: 訂單重試強化\n' "$(date +%Y-%m-%d)" > "$TMP/ha-handoffs/titled.md"
out="$("$HA_SCRIPT" list "$TMP/ha-handoffs")"
if echo "$out" | grep -q "^  path: .*/ha-handoffs/titled.md$"; then ok "list 印完整 path 行"; else bad "list 缺 path 行"; fi
if echo "$out" | grep -q "^  title: 訂單重試強化$"; then ok "list 印 title 行"; else bad "list 缺 title 行"; fi
assert_eq "無標題行的檔不印 title" "1" "$(echo "$out" | grep -c '^  title: ')"
rm "$TMP/ha-handoffs/titled.md"

# --- find-predecessor（W1 判首輪/續寫：依 slug 精確定位前一份）---
# 關鍵迴歸：`archive/*-<slug>.md` 的尾錨定擋不住中間的工作線名——查 foo 會命中 bar-foo，
# 且 tail -1 剛好選它（時戳較新、字典序在後）。同一處定位邏輯被三輪第三方審查逐輪擠，
# 這節把「精確比對」釘死。DO NOT relax these back into a glob.
FP="$TMP/ha-fp"; mkdir -p "$FP/archive"
fp_mk() { printf -- '---\nslug: %s\ncreated: 2026-08-01\n---\n# Handoff: %s\n' "$2" "$2" > "$FP/$1"; }
# bar-foo 的時戳**必須最新**，否則 glob 實作的 tail -1 也會剛好答對，斷言就沒有鑑別力
# （同「守門測試的命中點要放在逼得出缺陷的位置」那條教訓）
fp_mk "archive/20260804-120000-bar-foo.md" "bar-foo"
fp_mk "archive/20260801-090000-foo.md" "foo"
fp_mk "archive/20260803-100000-foo.md" "foo"

out="$("$HA_SCRIPT" find-predecessor foo "$FP")"
assert_rc "find-predecessor 命中 → exit 0" 0 $?
assert_eq "後綴同名的別條工作線不得誤中（bar-foo vs foo），且取同 slug 最新一份" \
    "$FP/archive/20260803-100000-foo.md" "$(echo "$out" | sed -n 's/^predecessor: //p')"
if echo "$out" | grep -q "^location: archive"; then ok "命中 archive 標 location"; else bad "location 標記錯誤"; fi

out="$("$HA_SCRIPT" find-predecessor bar-foo "$FP")"
assert_eq "查較長的工作線名照樣精確" \
    "$FP/archive/20260804-120000-bar-foo.md" "$(echo "$out" | sed -n 's/^predecessor: //p')"

# active 未消費者優先（它比 archive 任何一輪都新）
fp_mk "foo.md" "foo"
out="$("$HA_SCRIPT" find-predecessor foo "$FP")"
assert_eq "active 未消費的同 slug 優先於 archive" "$FP/foo.md" "$(echo "$out" | sed -n 's/^predecessor: //p')"

# 檔名對得上但檔內 slug 不符 → 不採用（手改過的殘檔不得被撿）
printf -- '---\nslug: someone-else\n---\n' > "$FP/archive/20260804-110000-mismatch.md"
out="$("$HA_SCRIPT" find-predecessor mismatch "$FP")"
if echo "$out" | grep -q "predecessor: NONE"; then ok "檔內 slug 與檔名不符 → 不採用"; else bad "採用了 slug 不符的檔"; fi

# 無命中＝首輪，是正常結果不是錯誤
out="$("$HA_SCRIPT" find-predecessor brand-new "$FP")"
assert_rc "find-predecessor 無命中 → exit 0（首輪是正常結果）" 0 $?
if echo "$out" | grep -q "predecessor: NONE"; then ok "無命中印 NONE"; else bad "無命中輸出錯誤"; fi

# slug 含 glob 字元 → 不做 pathname expansion（slug 已不進 glob）
out="$("$HA_SCRIPT" find-predecessor '*' "$FP")"
if echo "$out" | grep -q "predecessor: NONE"; then ok "slug 含 glob 字元不誤匹配"; else bad "glob 字元被展開"; fi

# active 檔名就是 <slug>.md，**不得**剝任何前綴——W4 只禁 YYYYMMDD-HHMMSS- 開頭，
# 日期-only 的 slug 合法；剝了會把它比成 `foo`、判成首輪，接著整檔覆寫、前一輪內容無聲蒸發
fp_mk "20260804-dated-slug.md" "20260804-dated-slug"
out="$("$HA_SCRIPT" find-predecessor "20260804-dated-slug" "$FP")"
assert_eq "以日期開頭的合法 slug（active）不被前綴剝除誤判為首輪" \
    "$FP/20260804-dated-slug.md" "$(echo "$out" | sed -n 's/^predecessor: //p')"
rm "$FP/20260804-dated-slug.md"

# archive 取最新用**時戳數值**而非 glob 字典序：legacy 的 `YYYYMMDD-` 第 10 字元是 slug 首字，
# 字典序上排在同日 `YYYYMMDD-HHMMSS-` 之後（'l' > '1'），靠字典序會選到較舊那份
fp_mk "archive/20260807-120000-legacy-mix.md" "legacy-mix"   # 新格式，當日 12:00
fp_mk "archive/20260807-legacy-mix.md" "legacy-mix"          # legacy 無時分秒，視為當日最早
out="$("$HA_SCRIPT" find-predecessor legacy-mix "$FP")"
assert_eq "legacy 與新格式同日並存 → 取真正較新的那份（非字典序末筆）" \
    "$FP/archive/20260807-120000-legacy-mix.md" "$(echo "$out" | sed -n 's/^predecessor: //p')"

# 無 slug: frontmatter 的檔仍採用——舊手寫交接檔沒有該欄位，這是刻意的向後相容、不是漏驗
printf -- '---\ncreated: 2026-08-01\n---\n' > "$FP/archive/20260808-100000-nofm.md"
out="$("$HA_SCRIPT" find-predecessor nofm "$FP")"
assert_eq "無 slug: frontmatter 的檔仍採用（向後相容，契約如此）" \
    "$FP/archive/20260808-100000-nofm.md" "$(echo "$out" | sed -n 's/^predecessor: //p')"

# `YYYYMMDD-<slug>` 與 `YYYYMMDD-HHMMSS-<slug>` 在 slug 恰以「6 位數字-」開頭時無法從檔名
# 區分（20260807-120000-foo 可讀成 slug=foo 或 slug=120000-foo）。歧義消不掉 → 兩種解讀都試，
# 否則正確的那個 slug 反而找不到自己的前一份
printf -- '---\nslug: 120000-ambig\n---\n' > "$FP/archive/20260807-120000-ambig.md"
out="$("$HA_SCRIPT" find-predecessor "120000-ambig" "$FP")"
assert_eq "legacy 檔的 slug 恰以 6 位數字開頭 → 仍定位得到" \
    "$FP/archive/20260807-120000-ambig.md" "$(echo "$out" | sed -n 's/^predecessor: //p')"

# frontmatter 判定只掃第一個 --- 到下一個 ---：正文／code fence 裡的 `slug:` 不算數
# （W4 模板本身就長那樣，交接檔在講 handoff skill 時會把它貼進正文）
# shellcheck disable=SC2016  # 三個反引號是 fixture 的字面 markdown code fence，不是命令替換
printf -- '---\ncreated: 2026-08-01\n---\n# Handoff\n\n```\nslug: other-line\n```\n' \
    > "$FP/archive/20260808-110000-fenced.md"
out="$("$HA_SCRIPT" find-predecessor fenced "$FP")"
assert_eq "正文/code fence 內的 slug: 不得被當成 frontmatter" \
    "$FP/archive/20260808-110000-fenced.md" "$(echo "$out" | sed -n 's/^predecessor: //p')"

# 歧義檔名 **+ 無 slug: frontmatter** → 兩種解讀都合法，同一份必然被兩個 slug 撈到。
# 資訊不足、消不掉，但必須附 AMBIGUOUS note 讓讀取端知道要先確認內容再採用
printf -- '---\ncreated: 2026-08-01\n---\n' > "$FP/archive/20260810-120000-ambignofm.md"
out="$("$HA_SCRIPT" find-predecessor ambignofm "$FP")"
if echo "$out" | grep -q "^note: AMBIGUOUS"; then
    ok "歧義檔名 + 無 metadata → 附 AMBIGUOUS note"
else bad "歧義且無 metadata 卻未標 AMBIGUOUS"; fi
assert_eq "歧義檔確實會被另一個 slug 也撈到（故 note 是必要的，不是裝飾）" \
    "$(echo "$out" | sed -n 's/^predecessor: //p')" \
    "$("$HA_SCRIPT" find-predecessor "120000-ambignofm" "$FP" | sed -n 's/^predecessor: //p')"

# 有 slug: frontmatter 佐證者無歧義 → 不得誤標 AMBIGUOUS
out="$("$HA_SCRIPT" find-predecessor "120000-ambig" "$FP")"
if echo "$out" | grep -q "^note: AMBIGUOUS"; then
    bad "檔內 slug: 已可佐證歸屬，卻誤標 AMBIGUOUS"
else ok "有 slug: 佐證 → 不標 AMBIGUOUS"; fi

# frontmatter 有 slug: 但值為空 → malformed，不可當成「沒有欄位」放行
printf -- '---\nslug:\ncreated: 2026-08-01\n---\n' > "$FP/archive/20260809-100000-emptyfm.md"
out="$("$HA_SCRIPT" find-predecessor emptyfm "$FP")"
if echo "$out" | grep -q "predecessor: NONE"; then
    ok "frontmatter slug: 空值 → 不採用（不等同缺少欄位）"
else bad "空值 slug 被當成缺少欄位而放行"; fi

"$HA_SCRIPT" find-predecessor >/dev/null 2>&1
assert_rc "find-predecessor 無引數 → exit 2" 2 $?
"$HA_SCRIPT" find-predecessor foo "$TMP/no-such-dir" >/dev/null
assert_rc "find-predecessor 目錄不存在 → exit 0" 0 $?

out="$("$HA_SCRIPT" list "$TMP/no-such-dir")"
assert_rc "list 目錄不存在 → exit 0（回報 NONE）" 0 $?
if echo "$out" | grep -q "handoffs: NONE"; then ok "list 無目錄 → NONE"; else bad "list 無目錄輸出錯誤"; fi

# --- survey（W1／R1 單一入口：清理 → active → worklines → predecessor）---
# 存在理由是機制取代散文契約：W1 曾把 `list` 寫成「只在未指定 slug 時跑」，W5 的 EXPIRED 回報
# 與 archive 保留期清理在 `/handoff <slug>` 路徑上雙雙沉默失效。單一無條件呼叫讓該分支不存在。
SV="$TMP/ha-sv"; mkdir -p "$SV/archive"
sv_mk() { printf -- '---\nslug: %s\ncreated: %s\n---\n# Handoff: %s\n' "$2" "$3" "$2" > "$SV/$1"; }
sv_mk "cur.md" "cur" "$(date +%Y-%m-%d)"
sv_mk "old.md" "old" "2026-01-01"
sv_mk "archive/20260801-101500-pipe.md" "pipe" "2026-08-01"
sv_mk "archive/20260803-090000-pipe.md" "pipe" "2026-08-03"
sv_mk "archive/20260802-120000-gate.md" "gate" "2026-08-02"

out="$("$HA_SCRIPT" survey "$SV")"
assert_rc "survey → exit 0" 0 $?
# active 區段必須與 list 逐字等價——兩個入口對同一份 active 目錄給出不同答案的話，
# 「SKILL.md 一律走 survey」就成了行為變更而非單純收斂
assert_eq "survey 的 active 區段與 list 逐字等價" \
    "$("$HA_SCRIPT" list "$SV" | grep -E '^(active: |  path: |  title: )')" \
    "$(grep -E '^(active: |  path: |  title: )' <<< "$out")"
if grep -q "^active: old.md — .* — EXPIRED" <<< "$out"; then ok "survey active 標 EXPIRED"
else bad "survey 未標 EXPIRED"; fi

assert_eq "worklines 依 slug 聚合輪數與最近日期" \
    "workline: pipe — 2 輪 — 最近 2026-08-03" "$(grep '^workline: pipe ' <<< "$out")"
assert_eq "worklines 依最近時戳新到舊排序" "pipe gate" \
    "$(awk '/^workline: /{printf "%s%s", sep, $2; sep=" "}' <<< "$out")"
if ! grep -q '^predecessor: ' <<< "$out"; then ok "未給 --slug → 不印 predecessor 區段"
else bad "未給 --slug 卻印了 predecessor"; fi

out="$("$HA_SCRIPT" survey --slug pipe "$SV")"
assert_eq "--slug 命中 archive 最新一輪" \
    "$HA_REAL/ha-sv/archive/20260803-090000-pipe.md" "$(sed -n 's/^predecessor: //p' <<< "$out")"

# --- archive parser 的三條身分解析政策（predecessor 與 worklines 共用同一份解析）---
printf -- '---\ncreated: 2026-08-04\n---\n' > "$SV/archive/20260804-110000-nofm.md"
printf -- '---\nslug: someone-else\n---\n' > "$SV/archive/20260805-110000-mism.md"
printf -- 'handwritten\n' > "$SV/archive/manual-drop.md"
out="$("$HA_SCRIPT" survey "$SV")"

# ① 歧義檔名 + 無 frontmatter：兩種解讀都合法，標出來讓讀取端先確認內容
if grep -q '^workline: nofm — 1 輪 — 最近 2026-08-04（檔名格式歧義' <<< "$out"; then
    ok "parser ①：歧義檔名 + 無 frontmatter → 標歧義"
else bad "歧義檔名未標記（$(grep '^workline: nofm' <<< "$out")）"; fi

# ② frontmatter 與所有候選都不符：**以檔名歸戶 + 標不可達**，不讓 frontmatter 當索引。
# 這種殘檔 find-predecessor 兩個方向都撈不到（檔名閘門擋 frontmatter 值、frontmatter 閘門
# 擋檔名值），本來完全隱形；正反兩面都要釘，只釘一面會讓「改用 frontmatter 當索引」照樣全綠
if grep -q '^workline: mism — 1 輪 — 最近 2026-08-05（檔內 slug=someone-else' <<< "$out"; then
    ok "parser ②：frontmatter 不符 → 以檔名歸戶並標不可達"
else bad "fm-mismatch 未以檔名歸戶或未標註（$(grep '^workline: mism' <<< "$out")）"; fi
if "$HA_SCRIPT" find-predecessor mism "$SV" | grep -q 'predecessor: NONE' \
    && "$HA_SCRIPT" find-predecessor someone-else "$SV" | grep -q 'predecessor: NONE'; then
    ok "fm-mismatch 檔：查檔名與查 frontmatter 值皆 NONE（frontmatter 是否決權不是索引）"
else bad "fm-mismatch 檔被某個方向撿走了"; fi

# ③ 無歸檔前綴的手工檔：沒有日期來源，但不得因此從清單消失
if grep -q '^workline: manual-drop — 1 輪 — 最近 —（有手工放入' <<< "$out"; then
    ok "parser ③：無歸檔前綴 → 日期印「—」且仍列出"
else bad "無前綴手工檔遺失或格式錯（$(grep '^workline: manual-drop' <<< "$out")）"; fi
assert_eq "無前綴檔排序視為最舊（排在最後，但不得消失）" "manual-drop" \
    "$(awk '/^workline: /{last=$2} END{print last}' <<< "$out")"

# --- worklines 顯示上限：只截顯示並印出略過筆數，不靜默截斷 ---
SVC="$TMP/ha-sv-cap"; mkdir -p "$SVC/archive"
for i in 01 02 03 04 05 06 07 08 09 10 11 12; do
    printf -- '---\nslug: wl%s\n---\n' "$i" > "$SVC/archive/202608${i}-120000-wl${i}.md"
done
out="$("$HA_SCRIPT" survey "$SVC")"
assert_eq "worklines 顯示上限 10 條" "10" "$(grep -c '^workline: ' <<< "$out")"
if grep -q '^…（其餘 2 條工作線略）' <<< "$out"; then ok "超出上限印出略過筆數（不靜默截斷）"
else bad "超出上限未印略過筆數"; fi

# --- survey 的 archive 過期清理：**獨立 fixture** ---
# 沿用 list 已清過的目錄會讓斷言變空條件（清過的目錄裡沒東西可清），與 h5/h8 沙盒同一個教訓
SVP="$TMP/ha-sv-prune"; mkdir -p "$SVP/archive"
printf 'consumed\n' > "$SVP/archive/20260101-120000-dead.md"
touch -t 202601011200 "$SVP/archive/20260101-120000-dead.md"
printf 'consumed\n' > "$SVP/archive/20260807-120000-alive.md"
out="$("$HA_SCRIPT" survey "$SVP")"
if [ ! -f "$SVP/archive/20260101-120000-dead.md" ] && [ -f "$SVP/archive/20260807-120000-alive.md" ]; then
    ok "survey 清掉過保留期的已消費交接檔、保留期內的不動"
else bad "survey 的 archive 清理失效"; fi
if grep -q '^archive: 已清 1 份' <<< "$out"; then ok "survey 印出清理摘要"
else bad "survey 未印清理摘要"; fi

# --- TTL × predecessor：清理必須先於任何 archive 衍生輸出 ---
# 某工作線唯一一份 archive 剛好過 TTL 時，先印後刪會讓讀取端拿到 dangling 的
# workline/predecessor 路徑——連「把內容當線索讀」都做不到
SVT="$TMP/ha-sv-ttl"; mkdir -p "$SVT/archive"
printf 'consumed\n' > "$SVT/archive/20260101-120000-gone.md"
touch -t 202601011200 "$SVT/archive/20260101-120000-gone.md"
out="$("$HA_SCRIPT" survey --slug gone "$SVT")"
if ! grep -q '^workline: gone' <<< "$out" && grep -q '^predecessor: NONE' <<< "$out"; then
    ok "唯一一份 archive 過 TTL → 清理先行，不輸出隨即失效的 workline/predecessor"
else bad "survey 印出了會被自己刪掉的 archive 路徑（${out}）"; fi

# --- survey 介面守門 ---
"$HA_SCRIPT" survey "$SV" --slug >/dev/null 2>&1
assert_rc "survey --slug 缺值 → exit 2" 2 $?
"$HA_SCRIPT" survey --slug "" "$SV" >/dev/null 2>&1
assert_rc "survey --slug 空值 → exit 2（不得靜默當成沒給 slug）" 2 $?
"$HA_SCRIPT" survey --bogus "$SV" >/dev/null 2>&1
assert_rc "survey 未知 flag → exit 2" 2 $?
"$HA_SCRIPT" survey "$SV" "$SV" >/dev/null 2>&1
assert_rc "survey 多餘位置參數 → exit 2" 2 $?
out="$("$HA_SCRIPT" survey "$TMP/no-such-dir")"
assert_rc "survey 目錄不存在 → exit 0" 0 $?
if grep -q "handoffs: NONE" <<< "$out"; then ok "survey 無目錄 → NONE"; else bad "survey 無目錄輸出錯誤"; fi

# --- active 清單的「最後更新時戳」與 mtime 排序 ---
# **獨立 fixture**：沿用 $SV 會改變上面那批斷言依賴的 active 集合（§13 記過同型教訓）。
# 時戳取 mtime 而非 created，因為 created 只有日粒度（`cmd_anchors` 寫 `date +%Y-%m-%d`），
# 同日多份必然平手——而那正是「多份 active 選不出來」的實地情境。
SVM="$TMP/ha-sv-mtime"; mkdir -p "$SVM"
svm_mk() {  # <檔名> <touch -t 時戳>
    printf -- '---\nslug: %s\ncreated: %s\n---\n# Handoff: %s\n' \
        "${1%.md}" "$(date +%Y-%m-%d)" "${1%.md}" > "$SVM/$1"
    touch -t "$2" "$SVM/$1"
}
# ⚠️ mtime 順序必須與檔名**字典序相反**：否則現行 glob（字典序升冪）也剛好答對，斷言等於虛設
# （同 §13 記過的 `bar-foo` 教訓）
svm_mk "a-oldest.md" 202601010900
svm_mk "b-middle.md" 202602021000
svm_mk "c-newest.md" 202603031100
out="$("$HA_SCRIPT" survey "$SVM")"
assert_rc "survey（mtime fixture）→ exit 0" 0 $?
assert_eq "active 依 mtime 新到舊排序" "c-newest.md b-middle.md a-oldest.md" \
    "$(awk '/^active: /{printf "%s%s", sep, $2; sep=" "}' <<< "$out")"
if grep -qE '^active: c-newest\.md — 更新 2026-03-03 11:00 — [0-9]+d — OK$' <<< "$out"; then
    ok "時戳欄取自 mtime、精確到分"
else bad "時戳欄缺漏或格式錯（$(grep '^active: c-newest' <<< "$out")）"; fi
# 排序改的是外層迴圈次序，縮排子行若在迴圈外組裝就會與父行錯配
assert_eq "path/title 子行跟著各自的 active 行（排序後不錯配）" "OK" \
    "$(awk '/^active: /{f=$2}
            /^  path: /{n=$2; sub(/.*\//, "", n); if (n != f) e=1}
            /^  title: /{if ($2 != substr(f, 1, length(f)-3)) e=1}
            END{print e ? "MISMATCH" : "OK"}' <<< "$out")"
# 有項目時**不得**印 none：`... | sort | while read` 會讓 found 困在 subshell，
# 結果是列完全部項目後再多印一行 active: none
assert_eq "有 active 檔時不得印 active: none" "0" "$(grep -c '^active: none$' <<< "$out")"

# SUSPECT 分支（created 無法解析）同樣要帶時戳——這條分支先前零測試、零文件
printf 'no frontmatter here\n' > "$SVM/d-suspect.md"
touch -t 202604041200 "$SVM/d-suspect.md"
out="$("$HA_SCRIPT" survey "$SVM")"
if grep -qE '^active: d-suspect\.md — 更新 2026-04-04 12:00 — created 無法解析 — SUSPECT$' <<< "$out"; then
    ok "SUSPECT 分支也帶時戳"
else bad "SUSPECT 分支格式錯（$(grep '^active: d-suspect' <<< "$out")）"; fi

# tie-break：同 mtime → 檔名升冪。⚠️ 這條在改動前**本來就綠**（glob 即字典序），
# 它是回歸護欄、不是紅先行測試；真正防的是 sort 同鍵不保證穩定
SVT2="$TMP/ha-sv-tie"; mkdir -p "$SVT2"
# ⚠️ `a-Zed` 是讓 `LC_ALL=C` **可被觀測**的那一份，不是湊數：只有 `a-first`/`z-second` 的話，
# 拿掉 LC_ALL=C 這條斷言照樣綠（＝虛設）。實測同一組輸入 C 與 UTF-8 locale 給出**相反**順序，
# 兩平台皆然（BSD sort 2.3-Apple 與 glibc sort 都會翻），故它同時守住 macOS 與 Linux 兩條路。
for n in z-second a-first a-Zed; do
    printf -- '---\ncreated: %s\n---\n' "$(date +%Y-%m-%d)" > "$SVT2/$n.md"
done
touch -t 202605051300 "$SVT2/z-second.md" "$SVT2/a-first.md" "$SVT2/a-Zed.md"
out="$("$HA_SCRIPT" survey "$SVT2")"
assert_eq "同 mtime → 檔名升冪（C locale 序，穩定可重跑）" "a-Zed.md a-first.md z-second.md" \
    "$(awk '/^active: /{printf "%s%s", sep, $2; sep=" "}' <<< "$out")"

# active: none —— 先前零測試覆蓋。它是 R1 的硬依賴（`claude/skills/handoff/references/workflow.md`「R1：定位」）
# 與 eval H3 的判定證據。空 rows 若照 `done <<< "$rows"` 讀會產生**一次空行迭代**，
# found 被誤設為 1、這一行反而消失
SVN="$TMP/ha-sv-none"; mkdir -p "$SVN"
out="$("$HA_SCRIPT" survey "$SVN")"
assert_rc "survey 空目錄 → exit 0" 0 $?
assert_eq "目錄存在但無交接檔 → active: none 恰印一次" "1" "$(grep -c '^active: none$' <<< "$out")"
assert_eq "印了 none 就不得同時列出項目" "1" "$(grep -c '^active: ' <<< "$out")"

# --- consume 子指令（R4 消費歸檔：驗位置 → mkdir archive → mv 加秒級時戳前綴 → 印 archived:）---

printf -- '---\ncreated: %s\n---\n# Handoff: c\n' "$(date +%Y-%m-%d)" > "$TMP/ha-handoffs/consume-me.md"
out="$("$HA_SCRIPT" consume "$TMP/ha-handoffs/consume-me.md")"
assert_rc "consume 正常 → exit 0" 0 $?
archived_path="$(echo "$out" | sed -n 's/^archived: //p')"
if [ -n "$archived_path" ] && [ -f "$archived_path" ]; then ok "consume 印 archived: 行且檔案已落 archive"; else bad "consume 未印 archived: 或檔案不存在（${out}）"; fi
if [ ! -f "$TMP/ha-handoffs/consume-me.md" ]; then ok "consume 後 active 原檔已移走"; else bad "consume 後原檔仍留在 active"; fi
case "$(basename "${archived_path:-x}")" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]-consume-me.md)
        ok "archive 檔名帶 YYYYMMDD-HHMMSS 前綴（同日同 slug 二次消費不互覆）" ;;
    *)  bad "archive 檔名前綴格式錯誤（${archived_path}）" ;;
esac

# 重複消費（檔案已在 archive 內）→ 拒絕，不動檔案
out="$("$HA_SCRIPT" consume "$archived_path" 2>&1)"
assert_rc "consume archive 內檔案 → exit 1" 1 $?
if echo "$out" | grep -q "已在 archive"; then ok "重複消費 → 拒絕（已在 archive）"; else bad "重複消費未被拒（${out}）"; fi
if [ -f "$archived_path" ]; then ok "拒絕後 archive 檔原地不動"; else bad "拒絕路徑動到了 archive 檔"; fi

"$HA_SCRIPT" consume "$TMP/ha-handoffs/no-such.md" >/dev/null 2>&1
assert_rc "consume 不存在檔案 → exit 1" 1 $?
"$HA_SCRIPT" consume >/dev/null 2>&1
assert_rc "consume 無引數 → exit 2" 2 $?

# 同秒碰撞防覆蓋（-e 前置檢查的迴歸守衛）：date stub 固定時戳，連續消費兩份同名檔
# → 第二次 exit 1、archive 檔內容不變、第二份仍留在 active
mkdir -p "$TMP/datestub"
# shellcheck disable=SC2016  # stub 內容刻意不展開（$1/$@ 屬 stub 自身）
printf '#!/bin/sh\n[ "$1" = "+%%Y%%m%%d-%%H%%M%%S" ] && { echo 20990101-000000; exit 0; }\nexec /bin/date "$@"\n' > "$TMP/datestub/date"
chmod +x "$TMP/datestub/date"
printf 'first\n' > "$TMP/ha-handoffs/same.md"
PATH="$TMP/datestub:$PATH" "$HA_SCRIPT" consume "$TMP/ha-handoffs/same.md" >/dev/null
assert_rc "date stub 第一次 consume → exit 0" 0 $?
printf 'second\n' > "$TMP/ha-handoffs/same.md"
PATH="$TMP/datestub:$PATH" "$HA_SCRIPT" consume "$TMP/ha-handoffs/same.md" >/dev/null 2>&1
assert_rc "同秒同名第二次 consume → exit 1（拒絕覆蓋）" 1 $?
assert_eq "碰撞拒絕後 archive 檔內容不變" "first" "$(cat "$TMP/ha-handoffs/archive/20990101-000000-same.md")"
if [ -f "$TMP/ha-handoffs/same.md" ]; then ok "碰撞拒絕後第二份仍在 active"; else bad "碰撞拒絕卻弄丟 active 檔"; fi
rm "$TMP/ha-handoffs/same.md"

# 已消費偵測用「工具不變量」（直接父目錄 archive／檔名時戳前綴），不掃整條路徑——
# 祖先目錄剛好叫 archive 的合法 active 檔不得誤拒（如 /srv/archive/<user>/handoffs/x.md）
mkdir -p "$TMP/archive/alice/handoffs"
printf 'legit\n' > "$TMP/archive/alice/handoffs/task.md"
out="$("$HA_SCRIPT" consume "$TMP/archive/alice/handoffs/task.md")"
assert_rc "祖先名 archive 的合法 active 檔 → 照常消費 exit 0" 0 $?
arch2="$(echo "$out" | sed -n 's/^archived: //p')"
if [ -n "$arch2" ] && [ -f "$arch2" ]; then ok "祖先名 archive 不誤拒（檔已正常歸檔）"; else bad "祖先名 archive 被誤拒或未歸檔（${out}）"; fi

# 檔名已帶時戳前綴（曾被工具歸檔，即使被手工搬進巢狀子目錄）→ 拒絕，原地不動
mkdir -p "$TMP/ha-handoffs/archive/sub"
printf 'old\n' > "$TMP/ha-handoffs/archive/sub/20990101-000000-nested.md"
out="$("$HA_SCRIPT" consume "$TMP/ha-handoffs/archive/sub/20990101-000000-nested.md" 2>&1)"
assert_rc "時戳前綴檔（巢狀位置）→ exit 1" 1 $?
if echo "$out" | grep -q "已消費"; then ok "時戳前綴 → 拒絕（不變量認得曾歸檔）"; else bad "時戳前綴未被拒（${out}）"; fi
if [ -f "$TMP/ha-handoffs/archive/sub/20990101-000000-nested.md" ]; then ok "前綴拒絕後檔案原地不動"; else bad "前綴拒絕卻動了檔案"; fi
rm -rf "$TMP/ha-handoffs/archive/sub"

# date 失敗 → 拒絕歸檔（不產生 archive/-<name> 這種無時戳檔名）
mkdir -p "$TMP/datefail"
printf '#!/bin/sh\nexit 1\n' > "$TMP/datefail/date"
chmod +x "$TMP/datefail/date"
printf 'keep\n' > "$TMP/ha-handoffs/df.md"
PATH="$TMP/datefail:$PATH" "$HA_SCRIPT" consume "$TMP/ha-handoffs/df.md" >/dev/null 2>&1
assert_rc "date 失敗 → exit 1（拒絕歸檔）" 1 $?
if [ -f "$TMP/ha-handoffs/df.md" ]; then ok "date 失敗後交接檔仍在 active"; else bad "date 失敗卻動了交接檔"; fi
rm "$TMP/ha-handoffs/df.md"

"$HA_SCRIPT" >/dev/null 2>&1
assert_rc "無引數 → exit 2" 2 $?
"$HA_SCRIPT" bogus >/dev/null 2>&1
assert_rc "未知子指令 → exit 2" 2 $?
