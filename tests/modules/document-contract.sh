#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034,SC2153
echo "▶ 1d. 交叉引用完整性 gate"
# repo 的規範網靠「唯一權威」維持：同一主題只有一處定義，別處寫「見 `X 檔`「Y 節」，此處不
# 重述」。那個不變式原本**全靠散文**。指標斷掉的後果不是不整潔——claude/CLAUDE.md 要求
# 「勿憑記憶重組」，指標斷掉時重組就是唯一選擇。首次掃描實測：1 條真死指標、2 條指向
# repo 內有兩份同名檔的基名引用（reviewer-brief.md 有 Claude／Codex 兩份，刻意隔離的兩套
# 判準，指錯即破壞 blind review）。判準與反例見 `docs/testing-contract.md`「1d. 交叉引用完整性 gate」；
# tests/xref-gate.py 檔頭只承擔 compatibility wrapper 的 exit contract。
XREF_GATE="$ROOT/tests/xref-gate.py"
XR="$TMP/xref"
mkdir -p "$XR/sub"
# 共用 target：heading 帶括號補充（釘 G1 的子字串比對）、一條含 ** 修飾的內文規則（G2）、
# 一個只活在 fence 內的節名（R2）、一個只活在 HTML comment 內的節名（R3）。
cat > "$XR/target.md" <<'XREFFIX'
# 目標檔

## 說法表（唯一權威；照此分派）

- 存之前先比對既有項目，覆蓋同一主題就**更新該檔**，不要建重複檔。

```markdown
## 只活在圍欄裡的節
```

<!--
## 只活在註解裡的節
-->
XREFFIX
cat > "$XR/sub/dup.md" <<'XREFFIX'
# 同名檔（放在 root 底下的別處，不在引用檔目錄，也不在 root 直下）
## 某節
XREFFIX
xref_capture() {
    xref_out="$(python3 "$XREF_GATE" --root "$XR" "$@" 2>"$XR/xref.err")"
    xref_rc=$?
}
xref_capture_at() {
    local root="$1"; shift
    xref_out="$(python3 "$XREF_GATE" --root "$root" "$@" 2>"$XR/xref.err")"
    xref_rc=$?
}
xref_red() {
    local file="$1" pass="$2" fail="$3"
    xref_capture "$file"
    if [ "$xref_rc" -eq 0 ] && [ -n "$xref_out" ]; then ok "$pass"; else bad "${fail}（exit ${xref_rc}）"; fi
}
xref_green() {
    local file="$1" pass="$2" fail="$3"
    xref_capture "$file"
    if [ "$xref_rc" -eq 0 ] && [ -z "$xref_out" ]; then ok "$pass"; else bad "${fail}（exit ${xref_rc}）"; fi
}
# 掃描器自檢在前：少了 RED，掃描器被改壞而恆不匹配時，對真實檔案的空輸出一樣是「通過」。
cat > "$XR/r1.md" <<'XREFFIX'
見 `target.md`「這個節名根本不存在於任何地方」。
XREFFIX
cat > "$XR/r2.md" <<'XREFFIX'
見 `target.md`「只活在圍欄裡的節」。
XREFFIX
cat > "$XR/r3.md" <<'XREFFIX'
見 `target.md`「只活在註解裡的節」。
XREFFIX
cat > "$XR/r4.md" <<'XREFFIX'
見 `dup.md`「某節」。
XREFFIX
cat > "$XR/r5.md" <<'XREFFIX'
見 `target.md`「**」。
XREFFIX
cat > "$XR/r7.md" <<'XREFFIX'
<!--
維護提示：豁免條件見 `target.md`「這個節名同樣不存在」。
-->
XREFFIX
cat > "$XR/g1.md" <<'XREFFIX'
見 `target.md`「說法表」。
XREFFIX
cat > "$XR/g2.md" <<'XREFFIX'
見 `target.md`「覆蓋同一主題就更新該檔，不要建重複檔」。
XREFFIX
cat > "$XR/g3.md" <<'XREFFIX'
報告模板範例（fenced，示範怎麼寫，不是治理指標）：

```markdown
見 `target.md`「範例用的假節名」。
```
XREFFIX
# G5：外層四反引號、內層三反引號。內層若被當 closer，fence 會提前關欄，
# 後面那條假引用就會被誤報。
cat > "$XR/g5.md" <<'XREFFIX'
````markdown
```
見 `target.md`「巢狀圍欄裡的假節名」。
```
````
XREFFIX
# G6：四格縮排的字面 ``` 不是 fence opener（CommonMark 上限 3 格）。若誤判為 opener，
# 後面那條**真的壞掉**的引用會被吞掉而漏報——所以這條的期望是「必須命中」。
cat > "$XR/g6.md" <<'XREFFIX'
    ```
    這是四格縮排的字面內容，不是圍欄。

見 `target.md`「縮排誤判就會漏掉這條」。
XREFFIX
# G7：fence 內的 ```text 不是 closer（closer 後只允許空白）。若誤判為 closer，
# 圍欄提前結束 → 圍欄內那條假引用被誤報，且真正的 closer 之後那條壞引用反被吞掉。
cat > "$XR/g7.md" <<'XREFFIX'
```
```text
見 `target.md`「圍欄內的假節名」。
```

見 `target.md`「圍欄外必須抓到的節名」。
XREFFIX
xref_red "$XR/r1.md" "gate 自檢：節名與內文皆無 → 命中" "gate 失效（RED 沒被抓，真實掃描的空輸出不可信）"
xref_red "$XR/r2.md" "gate 自檢：目標節名只在 fenced block → 仍是死指標" "target 端未剝 fence（圍欄裡的範例標題被當成節存在 → 假綠）"
xref_red "$XR/r3.md" "gate 自檢：目標節名只在 HTML comment → 仍是死指標" "target 端未剝 comment（註解掉的模板被當成節存在 → 假綠）"
xref_red "$XR/r4.md" "gate 自檢：同名檔在 root 別處但引用處解析不到 → 命中（不做全 repo 模糊搜尋）" "gate 用基名模糊搜尋放行了——repo 內兩份 reviewer-brief.md 是刻意隔離的判準，指錯無警訊"
xref_red "$XR/r5.md" "gate 自檢：節名 normalize 後為空 → 命中" "空節名放行（空字串是任何字串的子字串，會恆假綠）"
xref_red "$XR/r7.md" "gate 自檢：source 的 HTML comment 內死指標 → 命中" "source 端漏掃 comment（krepo 的豁免指標就寫在 comment 裡）"
xref_missing_rc=0
xref_capture "$XR/nosuch-file.md"
xref_missing_rc=$xref_rc
if [ "$xref_missing_rc" -eq 2 ]; then ok "gate 自檢：不存在的輸入檔 → exit 2（錯誤不得冒充零命中）"; else bad "scanner 失敗未走 exit 2（實得 ${xref_missing_rc}）——run.sh 無 set -e，空 stdout 會被判成乾淨"; fi
xref_green "$XR/g1.md" "gate 自檢：節名前綴對上帶括號補充的 heading → 不報" "子字串比對失效（heading 帶括號補充是常態寫法，會全面誤紅）"
xref_green "$XR/g2.md" "gate 自檢：引用內文一行（原文含 ** 修飾）→ 不報" "normalize 未剝 inline 修飾（合法的規則引用被判紅）"
xref_green "$XR/g3.md" "gate 自檢：source 的 fenced 範例 → 不報" "source 端未剝 fence（報告模板的範例被當治理指標，逼人改模板文字）"
xref_green "$XR/g5.md" "gate 自檢：巢狀圍欄（4 反引號包 3）不提前關欄" "closer 未檢查同字元與長度 → 圍欄提前關，內層範例被誤報"
xref_red "$XR/g6.md" "gate 自檢：四格縮排的圍欄標記不是 opener（後續正文照掃）" "縮排無上限 → 四格縮排被當 opener，後面的真死指標被吞掉"
xref_capture "$XR/g7.md"
xref_g7="$xref_out"
if [ "$xref_rc" -eq 0 ] && [ -n "$xref_g7" ] && ! grep -q '圍欄內的假節名' <<< "$xref_g7"; then
    ok "gate 自檢：fence 內的 \`\`\`text 不是 closer（圍欄內不誤報、圍欄外照抓）"
else
    bad "closer 後未限定只允許空白 → 圍欄提前結束，內文被當正文誤報／圍欄外的死指標漏抓"
fi
# -- 反向守門：分層證據檔的節級孤兒（EVIDENCE_LAYERS）--
# 自己的 root，因為反向只在**全 repo 掃描**時跑（無 files 引數），而 $XR 下那堆 r*.md 是
# 刻意壞掉的正向 fixture，全掃會被它們的 finding 淹掉。
mkdir -p "$XR/rev/docs" "$XR/nolayer"
cat > "$XR/rev/docs/dead-ends.md" <<'XREFFIX'
# 死路 — 完整推導與證據

## 分工

| 問題 | 權威 |
|---|---|

## 有人指名的節

推導內容。

## 只被內文引用的節

這一行是會被內文比對命中的規則原文。

## 證據分層

舊節名「分工」仍是內文裡的通用詞。

## 沒人指的節

推導內容。

### 節內細分不該被當成一個單位

level 3 不是「一條結論的證據層」。
XREFFIX
cat > "$XR/rev/STATUS.md" <<'XREFFIX'
# STATUS

## 死路(試過但放棄——防重工)

- **甲**:結論一句。推導見 `docs/dead-ends.md`「有人指名的節」。
- **乙**:結論一句。見 `docs/dead-ends.md`「這一行是會被內文比對命中的規則原文」。
- **丙**:結論一句。舊指標見 `docs/dead-ends.md`「分工」。
XREFFIX
cat > "$XR/nolayer/README.md" <<'XREFFIX'
# 未採用分層的 repo

沒有 docs/dead-ends.md。
XREFFIX
xref_capture_at "$XR/rev"
xref_rev="$xref_out"; xref_rev_rc=$xref_rc
if [ "$xref_rev_rc" -eq 0 ] && grep -q '沒人指的節' <<< "$xref_rev"; then ok "反向 gate：無人指名的節 → 命中孤兒"; else bad "節級孤兒漏抓（exit ${xref_rev_rc}）"; fi
if [ "$xref_rev_rc" -eq 0 ] && grep -q '只被內文引用的節' <<< "$xref_rev"; then ok "反向 gate：只被內文引用（非節名）→ 仍算孤兒"; else bad "把 has_body 命中當成入邊，或 scanner 失敗（exit ${xref_rev_rc}）"; fi
if [ "$xref_rev_rc" -eq 0 ] && grep -q '證據分層' <<< "$xref_rev" && ! grep -q 'STATUS.md.*分工' <<< "$xref_rev"; then ok "反向 gate：舊節名只剩 body 命中 → 改名後 heading 仍報孤兒"; else bad "body fallback 掩蓋節名改壞，或 scanner 失敗（exit ${xref_rev_rc}）"; fi
if [ "$xref_rev_rc" -eq 0 ] && ! grep -q '有人指名的節' <<< "$xref_rev"; then ok "反向 gate：被節名指到 → 不報"; else bad "入邊未記錄，或 scanner 失敗（exit ${xref_rev_rc}）"; fi
if [ "$xref_rev_rc" -eq 0 ] && ! grep -q '節內細分' <<< "$xref_rev"; then ok "反向 gate：level 3 不納入（不是一條結論的證據層）"; else bad "h2_sections 收了非 level-2 heading，或 scanner 失敗（exit ${xref_rev_rc}）"; fi
xref_capture_at "$XR/rev" "$XR/rev/STATUS.md"
if [ "$xref_rc" -eq 0 ] && [ -z "$xref_out" ]; then ok "反向 gate：指定 files 子集 → 反向不跑（inbound 不完整會誤報真指標）"; else bad "子集掃描誤報或失敗（exit ${xref_rc}）"; fi
xref_capture_at "$XR/nolayer"
if [ "$xref_rc" -eq 0 ] && [ -z "$xref_out" ]; then ok "反向 gate：無 docs/dead-ends.md → 零輸出（未採用分層的 repo 零回填）"; else bad "未採用分層的 repo 被誤報或 scanner 失敗（exit ${xref_rc}）"; fi

# 真實掃描：本 repo 的治理指標必須全部可解析
xref_hits="$(python3 "$XREF_GATE" --root "$ROOT")"
xref_rc=$?
if [ "$xref_rc" -ne 0 ]; then
    bad "xref-gate 掃描器執行失敗（exit ${xref_rc}）——空輸出不可信"
elif [ -z "$xref_hits" ]; then
    ok "無斷掉的交叉引用"
else
    bad "有斷掉的交叉引用（節名改過就要同步指標；權威搬家要改指向）"
    printf '%s\n' "$xref_hits" | sed 's/^/     /'
fi

echo "▶ 1e. agent contract kernel block 完整性 gate"
# 契約 kernel 在三個 canonical 來源逐字存在；root CLAUDE.md 以原生 @AGENTS.md import 載入共同正文。
# G1c clean-room 已驗證普通指標不生效、import 與 Claude-specific precedence 各 2/2。判準見 scanner 檔頭。
KERNEL_GATE="$ROOT/tests/kernel-gate.py"
KG="$TMP/kernel"
KG_CODES=""

kg_make() {   # $1=fixture 根；$2=kernel body（三份共用）；$3=覆寫給 codex；$4=route body（後兩者可省）
    local d="$1" body="$2" codex_body="${3:-$2}"
    local route_body='## 文檔檢索路由

先執行 doc-find。'
    [ "$#" -lt 4 ] || route_body="$4"
    mkdir -p "$d/claude" "$d/codex"
    {
        echo "# Agent Contract"
        echo "<!-- agent-contract:kernel:start v1 -->"
        printf '%s\n' "$body"
        echo "<!-- agent-contract:kernel:end -->"
        echo "<!-- agent-contract:route:start v1 -->"
        printf '%s\n' "$route_body"
        echo "<!-- agent-contract:route:end -->"
        echo "<!-- agent-contract:portable:start v1 -->"
        echo "## Documentation authority"
        echo "- Generated docs never win."
        echo "<!-- agent-contract:portable:end -->"
        echo "## Repo specifics"
        echo "- 本節可以出現 ~/.dotfiles 與 dotsync，因為它逐 repo 重填、不會被複製走"
    } > "$d/AGENTS.md"
    printf '@AGENTS.md\n\n# Claude-specific\n' > "$d/CLAUDE.md"
    for f in "$d/claude/CLAUDE.md" "$d/codex/AGENTS.md"; do
        b="$body"; [ "$f" = "$d/codex/AGENTS.md" ] && b="$codex_body"
        {
            echo "# 全域規則"
            echo "<!-- agent-contract:kernel:start v1 -->"
            printf '%s\n' "$b"
            echo "<!-- agent-contract:kernel:end -->"
        } > "$f"
    done
}

kg_capture() {
    kg_out="$(python3 "$KERNEL_GATE" --root "$1" 2>"$KG/kernel.err")"
    kg_rc=$?
}
kg_red() {
    local root="$1" pattern="$2" pass="$3" fail="$4"
    kg_capture "$root"
    KG_CODES="${KG_CODES} $(sed -n 's/.*\[\([^]]*\)\].*/\1/p' <<< "$kg_out" | tr '\n' ' ')"
    if [ "$kg_rc" -eq 0 ] && grep -q "$pattern" <<< "$kg_out"; then ok "$pass"; else bad "${fail}（exit ${kg_rc}）"; fi
}
kg_reverse_markers() {  # $1=檔案；$2=block 名。保留各一個 marker，只反轉順序。
    local file="$1" name="$2"
    sed -i.bak \
        -e "s|<!-- agent-contract:${name}:start v1 -->|<!-- agent-contract:${name}:swap -->|" \
        -e "s|<!-- agent-contract:${name}:end -->|<!-- agent-contract:${name}:start v1 -->|" \
        -e "s|<!-- agent-contract:${name}:swap -->|<!-- agent-contract:${name}:end -->|" \
        "$file" && rm -f "$file.bak"
}

# 合法 body（GREEN 基準）：八條以上，並帶齊跨 runtime dossier 的必要行為指紋。
# shellcheck disable=SC2016  # backtick 是餵給 gate 的 Markdown 字面，不是 command substitution。
kg_body='- rule 1
- rule 2
- rule 3
- **Container-network collision safety.** Before first attach, prove its CIDR avoids host/LAN/VPN/production routes; inline/E2E included. NEVER copy production/LAN CIDRs to preserve IP literals—use auto allocation plus DNS/test config. If unproven, STOP. On macOS/OrbStack, cleanup is incomplete until the isolation table is checked for collisions; report them, never auto-delete unrelated entries.
- One writer per work item.
- Use a separate branch/worktree for another writer.
- The Dossier Steward owns shared state.
- A worker returns a Dossier delta.
- The steward uses `git cherry-pick` for integration.
- Do NOT create a dossier when none exists.'

rm -rf "$KG"; kg_make "$KG/green" "$kg_body"
kg_capture "$KG/green"
assert_rc "gate 自檢：合法 fixture → exit 0" 0 "$kg_rc"
assert_eq "gate 自檢：合法 fixture 無 findings" "" "$kg_out"

# root CLAUDE import 的檔案、唯一性、首行順序與禁止複製 managed block 都各有 RED。
kg_make "$KG/root-claude-missing" "$kg_body"; rm -f "$KG/root-claude-missing/CLAUDE.md"
kg_red "$KG/root-claude-missing" '\[ROOT_CLAUDE_FILE_MISSING\]' "gate 自檢：root CLAUDE 缺失 → 命中" "gate 自檢：root CLAUDE missing 分支未命中"

kg_make "$KG/root-import-count" "$kg_body"; printf '\n@AGENTS.md\n' >> "$KG/root-import-count/CLAUDE.md"
kg_red "$KG/root-import-count" '\[ROOT_CLAUDE_IMPORT_COUNT\]' "gate 自檢：root import 非唯一 → 命中" "gate 自檢：root import count 分支未命中"

kg_make "$KG/root-import-order" "$kg_body"; sed -i.bak '1i\
# 前置文字' "$KG/root-import-order/CLAUDE.md" && rm -f "$KG/root-import-order/CLAUDE.md.bak"
kg_red "$KG/root-import-order" '\[ROOT_CLAUDE_IMPORT_ORDER\]' "gate 自檢：root import 不是首行 → 命中" "gate 自檢：root import order 分支未命中"

kg_make "$KG/root-managed-copy" "$kg_body"
sed -n '/agent-contract:kernel:start/,/agent-contract:kernel:end/p' "$KG/root-managed-copy/AGENTS.md" >> "$KG/root-managed-copy/CLAUDE.md"
kg_red "$KG/root-managed-copy" '\[ROOT_CLAUDE_MANAGED_BLOCK\]' "gate 自檢：root CLAUDE 重複 managed block → 命中" "gate 自檢：root managed-copy 分支未命中"

# 漂移：其中一份的 body 不同
kg_make "$KG/drift" "$kg_body" "$(printf '%s\n' "$kg_body" | sed 's/rule 3/rule 3 （偷改）/')"
kg_red "$KG/drift" '漂移' "gate 自檢：複本漂移 → 命中" "gate 自檢：複本漂移未命中"

# route block 被掏空時仍需獨立擋住假綠。
kg_make "$KG/route-hollow" "$kg_body" "$kg_body" 'doc-find'
kg_red "$KG/route-hollow" 'route block 只有 1 條規則行' "gate 自檢：route 複本同時掏空 → 命中" "gate 自檢：route 複本同時掏空仍假綠"

# 兩份 route 保持逐字相同但拿掉 executable token，漂移與行數檢查都不會代打。
kg_make "$KG/route-no-exec" "$kg_body" "$kg_body" '## 文檔檢索路由

只看人工 pointer。'
kg_red "$KG/route-no-exec" 'route block 缺 executable route 規則行' "gate 自檢：route 缺 executable token → 命中" "gate 自檢：route executable token 分支未被 RED fixture 命中"

# route 與 kernel／portable 一樣會被複製到其他 repo，私人路徑與跨檔指標都必須受 portability 管理。
kg_make "$KG/route-private" "$kg_body" "$kg_body" '## 文檔檢索路由

先執行 doc-find，詳見 ~/.dotfiles 的 ship-state.sh。'
kg_red "$KG/route-private" 'route block 含私人路徑' "gate 自檢：route 私人路徑 → 命中" "gate 自檢：route 私人路徑逃過 portability"

# shellcheck disable=SC2016  # backtick 是要餵給 gate 的 Markdown 指標字面。
kg_make "$KG/route-xref" "$kg_body" "$kg_body" '## 文檔檢索路由

先執行 doc-find，規則見 `other.md`「寫入」。'
kg_red "$KG/route-xref" 'route block 含跨檔指標' "gate 自檢：route 跨檔指標 → 命中" "gate 自檢：route 跨檔指標逃過 portability"

# route block 只屬 repo-resident 契約；放進全域部署來源即使內容合法也要紅。
kg_make "$KG/route-misplaced" "$kg_body"
sed -n '/agent-contract:route:start/,/agent-contract:route:end/p' "$KG/route-misplaced/AGENTS.md" >> "$KG/route-misplaced/claude/CLAUDE.md"
kg_red "$KG/route-misplaced" '\[ROUTE_MISPLACED\]' "gate 自檢：route 出現在全域來源 → 命中" "gate 自檢：misplaced route block 未命中"

# route 自己的 marker 與空 block 分支也要各有 executable RED fixture。
kg_make "$KG/route-unpaired" "$kg_body"
sed -i.bak 's|<!-- agent-contract:route:end -->||' "$KG/route-unpaired/AGENTS.md" && rm -f "$KG/route-unpaired/AGENTS.md.bak"
kg_red "$KG/route-unpaired" '\[ROUTE_MARKER_COUNT\]' "gate 自檢：route marker 不成對 → 命中" "gate 自檢：route marker count 分支未命中"

kg_make "$KG/route-order" "$kg_body"
kg_reverse_markers "$KG/route-order/AGENTS.md" route
kg_red "$KG/route-order" '\[ROUTE_MARKER_ORDER\]' "gate 自檢：route marker 反序 → 命中" "gate 自檢：route marker order 分支未命中"

kg_make "$KG/route-empty" "$kg_body" "$kg_body" '   '
kg_red "$KG/route-empty" '\[ROUTE_EMPTY\]' "gate 自檢：route 空 block → 命中" "gate 自檢：route empty 分支未命中"

# 三份都被掏空 → 「空 == 空」會相等，靠條目數下限擋
kg_make "$KG/hollow" "- rule 1"
kg_red "$KG/hollow" '規則行' "gate 自檢：三份同時掏空 → 命中（空==空 的假綠）" "gate 自檢：掏空未命中——這是最關鍵的假綠"

# 條目數足夠、三份也一致，但拿掉 stewardship 語意仍須紅，否則可用 filler 騙過下限。
kg_make "$KG/required-rule" "$(printf '%s\n' "$kg_body" | sed 's/Dossier delta/worker report/')"
kg_red "$KG/required-rule" '\[KERNEL_REQUIRED_RULE\]' "gate 自檢：kernel 缺 stewardship 必要規則 → 命中" "gate 自檢：kernel required-rule 分支未命中"

# 安全規則本身也須有可證偽 fixture；三份完全同步仍不得以 filler 騙過 required-rule gate。
kg_make "$KG/required-network-rule" "$(printf '%s\n' "$kg_body" | sed 's/production\/LAN CIDRs/test CIDRs/')"
kg_red "$KG/required-network-rule" '\[KERNEL_REQUIRED_RULE\]' "gate 自檢：kernel 缺 container-network 安全規則 → 命中" "gate 自檢：container-network required-rule 分支未命中"

# 缺一份
kg_make "$KG/missing" "$kg_body"; rm -f "$KG/missing/codex/AGENTS.md"
kg_red "$KG/missing" '檔案不存在' "gate 自檢：缺一份 → 命中" "gate 自檢：缺一份未命中"

# marker 不成對
kg_make "$KG/unpaired" "$kg_body"
sed -i.bak 's|<!-- agent-contract:kernel:end -->||' "$KG/unpaired/claude/CLAUDE.md" && rm -f "$KG/unpaired/claude/CLAUDE.md.bak"
kg_red "$KG/unpaired" 'marker' "gate 自檢：marker 不成對 → 命中" "gate 自檢：marker 不成對未命中"

kg_make "$KG/kernel-order" "$kg_body"
kg_reverse_markers "$KG/kernel-order/claude/CLAUDE.md" kernel
kg_red "$KG/kernel-order" '\[KERNEL_MARKER_ORDER\]' "gate 自檢：kernel marker 反序 → 命中" "gate 自檢：kernel marker order 分支未命中"

# canary：規則本體在 block 之外又出現一份
kg_make "$KG/canary" "$kg_body"
# shellcheck disable=SC2016  # 反引號是 markdown 行內 code 的字面內容，單引號內不展開（正是要餵給 gate 的 canary）
echo '- 另外提醒一下：NEVER `git add -A`' >> "$KG/canary/claude/CLAUDE.md"
kg_red "$KG/canary" '指紋' "gate 自檢：block 外的複本 → 命中" "gate 自檢：block 外的複本未命中"

# 可攜性：managed block 內出現私人路徑
kg_make "$KG/private" "$(printf '%s\n- 詳見 ~/.claude/skills/project 的說明\n' "$kg_body")"
kg_red "$KG/private" '私人路徑' "gate 自檢：block 內私人路徑 → 命中" "gate 自檢：block 內私人路徑未命中"

# 可攜性：Repo specifics 節（block 外）出現私人路徑 → **不得**命中，否則本 repo 那節無法寫
kg_capture "$KG/green"
if [ "$kg_rc" -ne 0 ]; then bad "gate 自檢：合法 fixture scanner 失敗（exit ${kg_rc}）"; elif grep -q '私人路徑' <<< "$kg_out"; then bad "gate 自檢：誤報 block 外的私人路徑（Repo specifics 是逐 repo 重填的）"; else ok "gate 自檢：block 外的私人路徑不誤報"; fi

# 可攜性：跨檔指標句型（在 dotfiles 內 xref-gate 判它活著，裝到別的 repo 就是死的）
# shellcheck disable=SC2016  # 同上：要構造的就是「指標句型」這個字面，不是命令替換
kg_make "$KG/xref" "$(printf '%s\n- 完整條文見 `ship-paths.md`「說法表」\n' "$kg_body")"
kg_red "$KG/xref" '跨檔指標' "gate 自檢：block 內跨檔指標 → 命中" "gate 自檢：block 內跨檔指標未命中"

# portable block 的檔案、marker、內容與巢狀分支逐一造 RED。
kg_make "$KG/portable-missing" "$kg_body"; rm -f "$KG/portable-missing/AGENTS.md"
kg_red "$KG/portable-missing" '\[PORTABLE_FILE_MISSING\]' "gate 自檢：portable 檔案缺失 → 命中" "gate 自檢：portable file missing 分支未命中"

kg_make "$KG/portable-unpaired" "$kg_body"
sed -i.bak 's|<!-- agent-contract:portable:end -->||' "$KG/portable-unpaired/AGENTS.md" && rm -f "$KG/portable-unpaired/AGENTS.md.bak"
kg_red "$KG/portable-unpaired" '\[PORTABLE_MARKER_COUNT\]' "gate 自檢：portable marker 不成對 → 命中" "gate 自檢：portable marker count 分支未命中"

kg_make "$KG/portable-order" "$kg_body"
kg_reverse_markers "$KG/portable-order/AGENTS.md" portable
kg_red "$KG/portable-order" '\[PORTABLE_MARKER_ORDER\]' "gate 自檢：portable marker 反序 → 命中" "gate 自檢：portable marker order 分支未命中"

kg_make "$KG/portable-empty" "$kg_body"
sed -i.bak -e '/## Documentation authority/d' -e '/Generated docs never win/d' "$KG/portable-empty/AGENTS.md" && rm -f "$KG/portable-empty/AGENTS.md.bak"
kg_red "$KG/portable-empty" '\[PORTABLE_EMPTY\]' "gate 自檢：portable 空 block → 命中" "gate 自檢：portable empty 分支未命中"

kg_make "$KG/portable-nested" "$kg_body"
sed -i.bak 's/Generated docs never win/agent-contract:kernel/' "$KG/portable-nested/AGENTS.md" && rm -f "$KG/portable-nested/AGENTS.md.bak"
kg_red "$KG/portable-nested" '\[PORTABLE_NESTED_KERNEL\]' "gate 自檢：portable 巢狀 kernel → 命中" "gate 自檢：portable nested 分支未命中"

# portable block 只能在 AGENTS.md；全域來源出現第二份會替別的 repo 宣告本 repo 權威。
kg_make "$KG/portable-misplaced" "$kg_body"
sed -n '/agent-contract:portable:start/,/agent-contract:portable:end/p' "$KG/portable-misplaced/AGENTS.md" >> "$KG/portable-misplaced/claude/CLAUDE.md"
kg_red "$KG/portable-misplaced" '\[PORTABLE_MISPLACED\]' "gate 自檢：portable 出現在全域來源 → 命中" "gate 自檢：misplaced portable block 未命中"

# meta-test：掃描器宣告的每一種 blocking finding 都必須由上方某個 RED fixture 實際輸出。
kg_expected_codes="$(python3 "$KERNEL_GATE" --list-finding-codes | LC_ALL=C sort)"
kg_actual_codes="$(printf '%s\n' "$KG_CODES" | tr ' ' '\n' | sed '/^$/d' | LC_ALL=C sort -u)"
if [ "$kg_actual_codes" = "$kg_expected_codes" ]; then
    ok "gate 自檢：每個 kernel-gate finding 分支都有 RED fixture"
else
    bad "gate 自檢：finding 分支覆蓋不完整"
    comm -23 <(printf '%s\n' "$kg_expected_codes") <(printf '%s\n' "$kg_actual_codes") | sed 's/^/     missing: /'
fi

# scanner 自身失敗必須 exit 2（不可與「內容乾淨」的 exit 0 混用）
python3 "$KERNEL_GATE" --root "$KG/does-not-exist" >/dev/null 2>&1
assert_rc "gate 自檢：--root 不存在 → exit 2（不與乾淨混用）" 2 $?

# 真實 repo
kernel_hits="$(python3 "$KERNEL_GATE" --root "$ROOT" 2>/dev/null)"
kernel_rc=$?
if [ "$kernel_rc" -ne 0 ]; then
    bad "kernel-gate 掃描器執行失敗（exit ${kernel_rc}）——空輸出不可信"
elif [ -z "$kernel_hits" ]; then
    ok "三份 kernel 一致、root CLAUDE import 唯一且 route／契約可攜"
else
    bad "kernel block 有問題（複本漂移／被掏空／混入私人路徑）"
    printf '%s\n' "$kernel_hits" | sed 's/^/     /'
fi


echo "▶ 1g. doc-governance 跨檔契約"
if grep -q 'references/workflow.md' "$ROOT/claude/skills/deep-review/SKILL.md" \
    && ! grep -q '見上方「Codex 呼叫協議」' "$ROOT/claude/skills/deep-review/SKILL.md"; then
    ok "deep-review 入口指向現行 portable workflow"
else
    bad "deep-review 入口未指向 portable workflow 或仍留 stale Codex protocol 指標"
fi
if sed -n '1,24p' "$ROOT/tests/xref-gate.py" | grep -q 'finding.*0.*error.*2'; then
    ok "xref compatibility wrapper 檔頭保留 exit contract"
else
    bad "xref compatibility wrapper 檔頭缺判準／exit contract，既有指標已指空"
fi
if grep -q 'scripts/.*references/.*evals.md' "$ROOT/claude/skills/deep-review/references/modes-and-scope.md"; then
    ok "skill-authoring scope 完整列出 scripts/references/evals"
else
    bad "skill-authoring scope 搬遷時漏掉 references/"
fi
# shellcheck disable=SC2016 # 比對 Markdown backtick 字面，不做 command substitution
if grep -q 'doc-governance.*verdict: STOP' "$ROOT/claude/skills/project/references/log-prepare.md" \
    && ! grep -q 'legacy `dossier: NONE` / doc finding' "$ROOT/claude/skills/project/references/log-prepare.md"; then
    ok "log workflow 把 doc finding 當 STOP，不當未處理附註"
else
    bad "log workflow 對 doc finding 的摘要表與 STOP 清單互相矛盾"
fi
scenario7="$(sed -n '/^## Scenario 7 /,/^---$/p' "$ROOT/claude/skills/project/references/pressure-tests.md")"
if [ -n "$scenario7" ] && ! grep -q 'STATUS.md.*關鍵決策.*死路' <<< "$scenario7"; then
    ok "pressure Scenario 7 不再要求寫入 adopted STATUS 歷史節"
else
    bad "pressure Scenario 7 缺少正向 anchor，或仍要求新 schema 禁止的 STATUS 歷史節"
fi
if grep -q 'STATUS-legacy-template.md' "$ROOT/claude/skills/project/references/spec-workflow.md" \
    && [ -f "$ROOT/shared/skills/project/templates/STATUS-legacy-template.md" ]; then
    ok "project spec 對 legacy repo 使用 legacy template"
else
    bad "project spec 把 adopted-only STATUS template 無條件發給 legacy repo"
fi
project_reader="$ROOT/shared/skills/project/scripts/read-reference.py"
if [ -f "$project_reader" ]; then
    ok "project bounded reference reader 存在"
    reader_cursor=1
    reader_round=0
    reader_lines="$TMP/project-reader-lines"
    reader_content="$TMP/project-reader-content"
    : > "$reader_lines"
    : > "$reader_content"
    reader_ok=1
    while [ "$reader_round" -lt 100 ]; do
        reader_out="$(python3 "$project_reader" workflow.md --start "$reader_cursor" --max-bytes 700)"
        reader_rc=$?
        if [ "$reader_rc" -ne 0 ]; then
            reader_ok=0
            break
        fi
        printf '%s\n' "$reader_out" | awk -F '\t' '/^L[0-9][0-9][0-9][0-9][0-9][0-9]\t/ { print $1 }' >> "$reader_lines"
        printf '%s\n' "$reader_out" | awk '/^L[0-9][0-9][0-9][0-9][0-9][0-9]\t/ { sub(/^[^\t]*\t/, ""); print }' >> "$reader_content"
        reader_next="$(printf '%s\n' "$reader_out" | awk -F '\t' '$1 == "NEXT" { print $2 }')"
        if printf '%s\n' "$reader_out" | awk -F '\t' '$1 == "EOF" { found = 1 } END { exit !found }'; then
            break
        fi
        if [ -z "$reader_next" ] || [ "$reader_next" -le "$reader_cursor" ]; then
            reader_ok=0
            break
        fi
        reader_cursor="$reader_next"
        reader_round=$((reader_round + 1))
    done
    reader_total="$(wc -l < "$ROOT/shared/skills/project/references/workflow.md" | tr -d ' ')"
    awk -v n="$reader_total" 'BEGIN { for (i = 1; i <= n; i++) printf "L%06d\n", i }' > "$TMP/project-reader-expected-lines"
    if [ "$reader_ok" -eq 1 ] \
        && cmp -s "$TMP/project-reader-expected-lines" "$reader_lines" \
        && cmp -s "$ROOT/shared/skills/project/references/workflow.md" "$reader_content"; then
        ok "project reader 小額度逐段讀到 EOF，內容完整且無重複"
    else
        bad "project reader chunk cursor 有缺行／重複、未到 EOF 或內容漂移"
    fi
    reader_resume="$(python3 "$project_reader" log-workflow.md --start 37 --max-bytes 700)"
    if printf '%s\n' "$reader_resume" | awk -F '\t' '$1 == "L000037" { found = 1 } END { exit !found }' \
        && ! printf '%s\n' "$reader_resume" | awk -F '\t' '$1 == "L000036" { found = 1 } END { exit !found }'; then
        ok "project reader 可從最後完整行的下一行續讀，不必回到檔首"
    else
        bad "project reader resume cursor 未精確從指定行開始"
    fi
    python3 "$project_reader" ../workflow.md >/dev/null 2>&1
    assert_rc "project reader 拒絕 path traversal" 2 $?
else
    bad "project bounded reference reader 缺失"
fi
# shellcheck disable=SC2016 # 比對 Markdown backtick 字面，不做 expansion
project_reader_bootstrap='read-reference.py` 逐段讀取 `workflow.md`，每次 tool call 只呼叫 reader 取得一個 chunk，不合併其他命令或結果；看見該檔 `EOF` 前不得執行任何 repo mutation'
if grep -Fq "$project_reader_bootstrap" "$ROOT/claude/skills/project/SKILL.md" \
    && grep -Fq "$project_reader_bootstrap" "$ROOT/codex/skills/project/SKILL.md"; then
    ok "Project 雙入口共用同一個 bounded workflow bootstrap"
else
    bad "Project 雙入口未在 workflow EOF 前 fail closed，或 bootstrap 漂移"
fi
if grep -q '^## 必讀 reference 的有界讀取協定' "$ROOT/shared/skills/project/references/workflow.md" \
    && grep -q '^## Scenario 31 — 必讀 references' "$ROOT/shared/skills/project/references/pressure-tests.md"; then
    ok "Project reader protocol 與 behavior oracle 已接線"
else
    bad "Project reader protocol 或 Scenario 31 oracle 缺失"
fi
if grep -q 'G7 template placeholder missing' "$ROOT/claude/evals/setup-sandboxes.sh"; then
    ok "G7 fixture builder 對模板替換 no-op fail closed"
else
    bad "G7 fixture builder 的 str.replace miss 仍會靜默產生空 oracle"
fi
# shellcheck disable=SC2016 # 比對 Markdown 裡的舊 $skill-creator 字面，不做變數展開
if grep -Fq 'uv run --no-project --with pyyaml python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>' \
        "$ROOT/codex/skill-building-guide.md" \
    && ! grep -Fq '$skill-creator/scripts/quick_validate.py' "$ROOT/codex/skill-building-guide.md" \
    && grep -q '不要假設 system Python 已安裝 PyYAML' "$ROOT/codex/skill-building-guide.md"; then
    ok "skill validator 使用絕對 system path 並以 uv 隔離 PyYAML"
else
    bad "skill validator 路徑依賴呼叫 context，或仍會因 system Python 缺 PyYAML 而失敗"
fi
portable_skill_contract="$ROOT/docs/skill-portability.md"
if [ -f "$portable_skill_contract" ] \
    && grep -q 'docs/skill-portability.md' "$ROOT/codex/skill-building-guide.md" \
    && grep -q 'docs/skill-portability.md' "$ROOT/claude/skill-building-guide.md"; then
    ok "Claude Code／Codex authoring guide 共用單一 portable skill contract"
else
    bad "雙 harness authoring guide 未載入同一份 portable skill contract"
fi
if [ -f "$portable_skill_contract" ] \
    && grep -q 'Portable by default' "$portable_skill_contract" \
    && grep -q 'doc-governance.py find' "$portable_skill_contract" \
    && grep -q 'resolve.*symlink' "$portable_skill_contract" \
    && grep -q 'supersed' "$portable_skill_contract" \
    && grep -q 'Claude Code.*Codex' "$portable_skill_contract" \
    && grep -q 'shared.*core' "$portable_skill_contract"; then
    ok "portable skill contract 守新建雙入口與 existing-skill migration preflight"
else
    bad "portable skill contract 缺新建預設、歷史／symlink preflight 或 topology 取代 gate"
fi
if grep -q 'any repo-local skill' "$ROOT/AGENTS.md" \
    && grep -q 'any repo-local skill' "$ROOT/codex/AGENTS.md" \
    && grep -q 'docs/skill-portability.md' "$ROOT/AGENTS.md" \
    && grep -q 'shared core.*claude/skills.*codex/skills.*shared/skills' "$ROOT/codex/AGENTS.md"; then
    ok "Codex always-on authoring trigger 涵蓋任一 canonical tree 的 repo-local skill"
else
    bad "Codex always-on trigger 仍可能把 claude/skills canonical source 誤判成非 Codex authoring"
fi


# ACTOR_RE 是刻意的複本：doc-governance.py 逐字 vendored 進每個受治理的 repo，不能 import
# skill tree 的東西；steward-authority.py 只活在 project skill 裡。兩份規則一旦漂移，
# audit 與 authority gate 就會對同一個 STATUS.md 給出相反答案——而那正是本 gate 要防的事
# （實地：被裝飾過的 Dossier Steward 讓 audit --ship 全綠、authority gate 回 exit 2 BROKEN）。
actor_re_scanner="$(sed -n 's/^ACTOR_RE = re\.compile(\(.*\))$/\1/p' "$ROOT/scripts/doc-governance.py")"
actor_re_authority="$(sed -n 's/^ACTOR_RE = re\.compile(\(.*\))$/\1/p' "$ROOT/claude/skills/project/scripts/steward-authority.py")"
if [ -n "$actor_re_scanner" ] && [ "$actor_re_scanner" = "$actor_re_authority" ]; then
    ok "ACTOR_RE 兩份複本逐字相同（audit 與 authority gate 判準一致）"
else
    bad "ACTOR_RE 複本漂移：scanner=[${actor_re_scanner}] authority=[${actor_re_authority}]"
fi
