#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 1f. deep-review 同型處置紀錄：五個終態模板都要接上共用定義"
# 「同型處置紀錄」刻意做成**單一定義 + 五處引用**（複製表格必漂移）。守門的真正對象是
# **覆蓋率**：只接通過路徑等於在最需要的地方最弱——R5 終止時 branch 上正躺著四輪修復，
# 而收斂失敗時該問的就是「每輪有沒有做同型全修」。定義與觸發契約見
# claude/skills/deep-review/references/report-templates.md「同型處置紀錄（共用區塊）」。
# **章節名一律端錨定精確比對**（不用子字串：「## 報告模板 — 通過」是多個 Codex 模板名的
# 子字串，寬比對會讓漏接的模板假綠）；代價是改標題就會紅，那正是要的訊號。
RT_MD="$ROOT/claude/skills/deep-review/references/report-templates.md"
homotype_missing() {   # $1=檔案；印出「缺引用」的終態模板名，全接上則無輸出
    # 章節邊界**只認 `^## 報告模板`**：模板正文本身就含 `## Deep Review — Round {N}`／
    # `## Codex 第三方審查 — 通過`（那是要照抄進報告的標題，且與引用行同在 fence 內、
    # 無法靠剝 fence 排除）。拿泛用的 `^## ` 當邊界會在模板第二行就結算，五個模板全數誤報。
    awk '
        /^## 報告模板/ {
            if (want && !seen) print sec
            sec = $0; seen = 0
            want = (sec == "## 報告模板 — 通過" ||
                    sec == "## 報告模板 — Autofix 終止（R5 未通過）" ||
                    sec == "## 報告模板 — Codex 第三方審查通過" ||
                    sec == "## 報告模板 — Codex 第三方審查終止（C3 仍有 true positive）" ||
                    sec == "## 報告模板 — Codex 第三方審查 blocked（救援階梯走完仍無報告）")
            next
        }
        want && /^### 同型處置紀錄/ { seen = 1 }
        END { if (want && !seen) print sec }
    ' "$1"
}
if [ ! -f "$RT_MD" ]; then
    bad "找不到 report-templates.md（${RT_MD}）——覆蓋率無從驗證，空輸出不可信"
else
    # gate 自檢：抽掉第 5 處引用必須被抓到。掃描器改壞而恆不匹配時，
    # 對真實檔案的空輸出一樣長得像「通過」。
    ht_red="$TMP/homotype-red.md"
    awk 'BEGIN { n = 0 } /^### 同型處置紀錄/ { n++; if (n == 5) next } { print }' "$RT_MD" > "$ht_red"
    if [ -n "$(homotype_missing "$ht_red")" ]; then
        ok "gate 自檢：抽掉一處引用 → 命中"
    else
        bad "gate 失效（RED 沒被抓，真實檔案的空輸出不可信）"
    fi
    if grep -q '^## 同型處置紀錄（共用區塊）' "$RT_MD"; then
        ok "共用定義區塊存在"
    else
        bad "共用定義區塊不見了——五處引用會全部指空"
    fi
    ht_missing="$(homotype_missing "$RT_MD")"
    if [ -z "$ht_missing" ]; then
        ok "五個終態模板都接上同型處置紀錄"
    else
        bad "有終態模板漏接同型處置紀錄（產生過修復卻不留痕，掃了與沒掃在輸出上同形）"
        printf '%s\n' "$ht_missing" | sed 's/^/     /'
    fi
    # 總數恰為 5：多出來代表接到了中途輪次的「未通過」模板（那不是終態，會逼 reviewer 填 fixer 的表）
    ht_n=$(grep -c '^### 同型處置紀錄' "$RT_MD") || ht_n=-1
    if [ "$ht_n" -eq 5 ]; then
        ok "引用數恰為 5（未溢出到未通過模板）"
    else
        bad "引用數為 ${ht_n}，應為 5——多出的多半接在「未通過」模板上（中途輪次不是終態）"
    fi
    # 三軸（相依端，2026-08-13）：相依端與命中點軸**正交且 grep 抓不到**——依賴端的用字
    # 常與被改的東西不同甚至反義（改了 predicate、錯誤訊息仍描述舊判準）。沒有獨立欄位時，
    # 「掃過了」永遠只證明掃過同名字串。欄數以表頭的 `|` 個數判：4 欄 → 5 個 `|`。
    ht_header="$(awk '/^## 同型處置紀錄（共用區塊）/ { f = 1 } f && /^\| 規則/ { print; exit }' "$RT_MD")"
    ht_cols=$(printf '%s' "$ht_header" | tr -cd '|' | LC_ALL=C wc -c | tr -d ' ')
    if [ "${ht_cols:-0}" -eq 5 ]; then
        ok "同型處置紀錄為三軸（規則＋命中點＋輸入空間＋相依端）"
    else
        bad "同型處置紀錄表頭欄數不符（|=${ht_cols}，三軸應為 5）——缺相依端欄則掃了與沒掃在輸出上同形"
    fi
    # 引用處不得複述軸名（2026-08-13）：本檔的設計是**單一定義 + 五處引用**，而軸數會再成長
    # （命中點 → +輸入空間 → +相依端）。引用行只要自己列了軸名，就成為第二份定義，加軸時必然
    # 漏改一處——實地：加相依軸那批漏了通過模板的引用行，它仍寫「命中點軸與輸入空間軸並排」，
    # 照它填會產出缺欄的表，而驗表頭的斷言抓不到填寫者的產出。故引用行只准指路、不准複述。
    ht_restate="$(grep -n '同型處置紀錄（共用區塊）' "$RT_MD" \
        | grep -E '命中點軸|輸入空間軸|相依端|[兩三四]軸' || true)"
    if [ -z "$ht_restate" ]; then
        ok "五處引用只指路、未複述軸名（加軸時不會漏改）"
    else
        bad "引用行複述了軸名——它會變成第二份定義，加軸時必漏改："
        printf '%s\n' "$ht_restate" | sed 's/^/     /'
    fi
    # D4：根因重複時，「變更上」與「修復方法上」的處置相反（重做設計 vs 換掃描維度）。
    # 沒有這道分流，終止報告會對後者也建議重寫——那救不了，因為變更本身沒問題。
    if grep -q '根因重複時必答' "$RT_MD" && grep -q '未答不得逕自建議重寫' "$RT_MD"; then
        ok "終止報告有根因重複的分流（變更上 vs 修復方法上）"
    else
        bad "終止報告缺根因重複分流——「根因重複 → 架構有問題」只對『變更上』成立，對『方法上』會給出錯建議"
    fi
fi


echo "▶ 1h. known-hazards pipeline 狀態指引的 shell 邊界"
known_hazards="$ROOT/claude/known-hazards.md"
if grep -Fq "別接管線（或用 \`PIPESTATUS\`）" "$known_hazards"; then
    bad "known-hazards 仍把 Bash 專用的 PIPESTATUS 當成無條件備選"
else
    ok "known-hazards 不再無條件推薦 PIPESTATUS"
fi
if grep -Fq '**首選**：不要接管線。' "$known_hazards" \
    && grep -Fq "\`PIPESTATUS\` **只在 Bash 下可用**；zsh 使用小寫的 \`pipestatus\`。" "$known_hazards" \
    && grep -Fq '跨 shell 的腳本不要倚賴任一個。' "$known_hazards"; then
    ok "known-hazards 明列跨 shell 首選與 Bash／zsh 各自狀態陣列"
else
    bad "known-hazards 缺跨 shell 首選或 Bash／zsh 的狀態陣列邊界"
fi


echo "▶ 12e. ready4quit skill 跨 Claude Code／Codex 共用核心"
RQS_CLAUDE="$ROOT/claude/skills/ready4quit"
RQS_CODEX="$ROOT/codex/skills/ready4quit"
if [ -f "$RQS_CLAUDE/SKILL.md" ] && [ -f "$RQS_CODEX/SKILL.md" ] \
    && [ "$RQS_CODEX/references" -ef "$RQS_CLAUDE/references" ] \
    && [ "$RQS_CODEX/scripts" -ef "$RQS_CLAUDE/scripts" ]; then
    ok "ready4quit 兩個薄入口共用 canonical references/scripts"
else bad "ready4quit 跨 runtime 封裝未共用同一核心"; fi
if grep -q 'references/workflow.md' "$RQS_CLAUDE/SKILL.md" \
    && grep -q 'references/workflow.md' "$RQS_CODEX/SKILL.md" \
    && [ -f "$RQS_CODEX/references/workflow.md" ]; then
    ok "ready4quit 兩個入口都載入 shared workflow"
else bad "ready4quit 入口未共同指向 shared workflow"; fi
rqs_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$RQS_CODEX/SKILL.md")"
if ! grep -Eq '^(user-invocable|disable-model-invocation|argument-hint|allowed-tools|context|agent):' \
    <<< "$rqs_codex_frontmatter"; then
    ok "Codex ready4quit frontmatter 無 Claude Code 專屬欄位"
else bad "Codex ready4quit frontmatter 混入 Claude Code 專屬欄位"; fi
ready4quit_sig="\$ready4quit"
if grep -q '^disable-model-invocation: true$' "$RQS_CLAUDE/SKILL.md" \
    && grep -q '^  allow_implicit_invocation: false$' "$RQS_CODEX/agents/openai.yaml" \
    && grep -qF "$ready4quit_sig" "$RQS_CODEX/agents/openai.yaml"; then
    ok "ready4quit 在兩個 runtime 都保留 explicit-only policy"
else bad "ready4quit explicit-only policy 未跨 runtime 對齊"; fi
if ! rg -q 'TaskOutput|TaskList|CronList|ScheduleWakeup|scratchpad|~/.claude|~/.codex' \
    "$RQS_CLAUDE/references" "$RQS_CLAUDE/scripts"; then
    ok "ready4quit shared core 不綁 runtime private evidence surface 或安裝路徑"
else bad "ready4quit shared core 混入 runtime-private evidence surface 或安裝路徑"; fi
if grep -q 'Codex 無 skill baseline' "$ROOT/shared/skills/ready4quit/evals.md" \
    && grep -q '不得改用 handoff/checkpoint workflow' "$ROOT/shared/skills/ready4quit/evals.md" \
    && grep -q 'target repo contract 指定的' "$RQS_CLAUDE/references/workflow.md" \
    && grep -q 'project authority。只有目前 actor' "$RQS_CLAUDE/references/workflow.md"; then
    ok "ready4quit portable behavior oracle 與 authority routing 已落地"
else bad "ready4quit portable eval 或 authority routing contract 缺失"; fi
if grep -q 'Q7 — memory 開關矩陣' "$ROOT/shared/skills/ready4quit/evals.md" \
    && grep -q 'instruction promotion candidate' "$RQS_CLAUDE/references/workflow.md" \
    && grep -q '未升格候選就是 concrete residue' "$RQS_CLAUDE/references/workflow.md" \
    && grep -q 'disabled/unavailable.*skipped' "$RQS_CLAUDE/references/workflow.md" \
    && grep -q 'explicit retain request.*residue' "$RQS_CLAUDE/references/workflow.md" \
    && grep -q 'generated state' "$RQS_CODEX/SKILL.md"; then
    ok "ready4quit authority routing 不受 memory toggle／private store 影響"
else bad "ready4quit 缺 memory-independent promotion／skip／residue 契約"; fi

echo "▶ 12f. root-cause-first skill 跨 Claude Code／Codex 共用 evidence gate"
RCF_CLAUDE="$ROOT/claude/skills/root-cause-first"
RCF_CODEX="$ROOT/codex/skills/root-cause-first"
if [ -f "$RCF_CLAUDE/SKILL.md" ] && [ -f "$RCF_CODEX/SKILL.md" ] \
    && [ -L "$RCF_CODEX/references" ] \
    && [ "$RCF_CODEX/references/workflow.md" -ef "$RCF_CLAUDE/references/workflow.md" ]; then
    ok "root-cause-first 雙薄入口共用 canonical workflow"
else bad "root-cause-first 跨 runtime 封裝未共用 workflow"; fi
if [ ! -e "$RCF_CODEX/evals.md" ] \
    && ! rg -q 'defense-in-depth|root-cause-tracing' "$RCF_CLAUDE/SKILL.md" "$RCF_CODEX/SKILL.md" \
    && grep -q '^Portable compatibility pointer only\.' "$RCF_CLAUDE/references/defense-in-depth.md" \
    && grep -q '^Portable compatibility pointer only\.' "$RCF_CLAUDE/references/root-cause-tracing.md"; then
    ok "root-cause-first eval 單一來源且舊 method reference 內容已退場"
else bad "root-cause-first 複製 eval、載入舊 reference 或殘留舊 method 內容"; fi
rcf_claude_description="$(sed -n 's/^description: //p' "$RCF_CLAUDE/SKILL.md")"
rcf_codex_description="$(sed -n 's/^description: //p' "$RCF_CODEX/SKILL.md")"
if [ -n "$rcf_claude_description" ] \
    && [ "$rcf_claude_description" = "$rcf_codex_description" ]; then
    ok "root-cause-first 雙端 description 語意入口一致"
else bad "root-cause-first 雙端 description 漂移"; fi
rcf_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$RCF_CODEX/SKILL.md")"
if ! grep -Eq '^(user-invocable|disable-model-invocation|argument-hint|allowed-tools|context|agent):' \
    <<< "$rcf_codex_frontmatter"; then
    ok "Codex root-cause-first frontmatter 無 Claude Code 專屬欄位"
else bad "Codex root-cause-first frontmatter 混入 Claude Code 專屬欄位"; fi
# These are intentional literal runtime-private tokens.
# shellcheck disable=SC2088
if ! rg -q '~/.claude|~/.codex|CLAUDE_SKILL_DIR|TaskOutput|spawn_agent' \
    "$RCF_CLAUDE/references/workflow.md"; then
    ok "root-cause-first shared workflow runtime-neutral"
else bad "root-cause-first shared workflow 洩漏 runtime-private surface"; fi
# shellcheck disable=SC2016
rcf_sig='$root-cause-first'
if grep -qF "$rcf_sig" "$RCF_CODEX/agents/openai.yaml" \
    && grep -q 'CONTAINMENT ONLY' "$RCF_CLAUDE/references/workflow.md" \
    && grep -q 'No false completion' "$RCF_CLAUDE/references/workflow.md" \
    && grep -q '完整 suite 仍 1/6 失敗' "$ROOT/shared/skills/root-cause-first/evals.md"; then
    ok "root-cause-first UI metadata、pressure RED 與 completion gate 已接線"
else bad "root-cause-first portable behavior contract 缺失"; fi

echo "▶ 12g. nc-notify skill 跨 Claude Code／Codex 共用 lifecycle contract"
NCN_CLAUDE="$ROOT/claude/skills/nc-notify"
NCN_CODEX="$ROOT/codex/skills/nc-notify"
if [ -f "$NCN_CLAUDE/SKILL.md" ] && [ -f "$NCN_CODEX/SKILL.md" ] \
    && [ -L "$NCN_CODEX/references" ] \
    && [ "$NCN_CODEX/references/workflow.md" -ef "$NCN_CLAUDE/references/workflow.md" ]; then
    ok "nc-notify 雙薄入口共用 canonical workflow"
else bad "nc-notify 跨 runtime 封裝未共用 workflow"; fi
if [ ! -e "$NCN_CODEX/evals.md" ]; then
    ok "nc-notify eval oracle 只留 canonical tree"
else bad "nc-notify Codex adapter 複製了 eval oracle"; fi
ncn_claude_description="$(sed -n 's/^description: //p' "$NCN_CLAUDE/SKILL.md")"
ncn_codex_description="$(sed -n 's/^description: //p' "$NCN_CODEX/SKILL.md" 2>/dev/null)"
if [ -n "$ncn_claude_description" ] \
    && [ "$ncn_claude_description" = "$ncn_codex_description" ]; then
    ok "nc-notify 雙端 description 語意入口一致"
else bad "nc-notify 雙端 description 漂移"; fi
ncn_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$NCN_CODEX/SKILL.md" 2>/dev/null)"
if ! grep -Eq '^(user-invocable|disable-model-invocation|argument-hint|allowed-tools|context|agent):' \
    <<< "$ncn_codex_frontmatter"; then
    ok "Codex nc-notify frontmatter 無 Claude Code 專屬欄位"
else bad "Codex nc-notify frontmatter 混入 Claude Code 專屬欄位"; fi
# These patterns intentionally assert that literal runtime/private paths stay out.
# shellcheck disable=SC2088
if [ -f "$NCN_CLAUDE/references/workflow.md" ] \
    && ! rg -q '~/.claude|~/.codex|CLAUDE_SKILL_DIR|TaskOutput|spawn_agent|~/Projects/' \
        "$NCN_CLAUDE/references/workflow.md"; then
    ok "nc-notify shared workflow runtime-neutral 且不依賴私人 schema 路徑"
else bad "nc-notify shared workflow 洩漏 runtime-private surface 或私人 schema 路徑"; fi
# shellcheck disable=SC2016
ncn_sig='$nc-notify'
if grep -qF "$ncn_sig" "$NCN_CODEX/agents/openai.yaml" 2>/dev/null \
    && grep -q 'Portable behavior oracle' "$ROOT/shared/skills/nc-notify/evals.md" \
    && grep -q 'failure isolation' "$ROOT/shared/skills/nc-notify/evals.md"; then
    ok "nc-notify UI metadata 與 portable behavior oracle 已接線"
else bad "nc-notify metadata 或 portable behavior oracle 缺失"; fi
# Markdown backticks are part of the literal contract.
# shellcheck disable=SC2016
if grep -q 'HTTP `POST`' "$NCN_CLAUDE/references/workflow.md" \
    && grep -q 'Authorization: Bearer' "$NCN_CLAUDE/references/workflow.md"; then
    ok "nc-notify fallback wire contract 不留給 runtime 自行猜測"
else bad "nc-notify fallback wire contract 缺失"; fi

echo "▶ 12gg. wait4me skill 跨 Claude Code／Codex 共用 session notification contract"
W4M_CLAUDE="$ROOT/claude/skills/wait4me"
W4M_CODEX="$ROOT/codex/skills/wait4me"
W4M_SHARED="$ROOT/shared/skills/wait4me"
if [ -f "$W4M_CLAUDE/SKILL.md" ] && [ -f "$W4M_CODEX/SKILL.md" ] \
    && [ -L "$W4M_CLAUDE/references" ] && [ -L "$W4M_CODEX/references" ] \
    && [ -L "$W4M_CLAUDE/scripts" ] && [ -L "$W4M_CODEX/scripts" ] \
    && [ "$W4M_CODEX/references/workflow.md" -ef "$W4M_CLAUDE/references/workflow.md" ] \
    && [ "$W4M_CODEX/scripts/wait4me-hook.sh" -ef "$W4M_SHARED/scripts/wait4me-hook.sh" ]; then
    ok "wait4me 雙薄入口共用 canonical workflow 與 scripts"
else bad "wait4me 跨 runtime 封裝未共用 canonical resources"; fi
if [ "$W4M_CLAUDE/evals.md" -ef "$W4M_SHARED/evals.md" ] && [ ! -e "$W4M_CODEX/evals.md" ]; then
    ok "wait4me eval oracle 只留 canonical tree"
else bad "wait4me eval oracle topology 錯誤"; fi
w4m_claude_description="$(sed -n 's/^description: //p' "$W4M_CLAUDE/SKILL.md")"
w4m_codex_description="$(sed -n 's/^description: //p' "$W4M_CODEX/SKILL.md")"
if [ -n "$w4m_claude_description" ] && [ "$w4m_claude_description" = "$w4m_codex_description" ]; then
    ok "wait4me 雙端 description 語意入口一致"
else bad "wait4me 雙端 description 漂移"; fi
w4m_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$W4M_CODEX/SKILL.md")"
if ! grep -Eq '^(user-invocable|disable-model-invocation|argument-hint|allowed-tools|context|agent):' \
    <<< "$w4m_codex_frontmatter"; then
    ok "Codex wait4me frontmatter 無 Claude Code 專屬欄位"
else bad "Codex wait4me frontmatter 混入 Claude Code 專屬欄位"; fi
# shellcheck disable=SC2016 # `$wait4me on` is the literal UI prompt under test.
if grep -qF 'default_prompt: "$wait4me on"' "$W4M_CODEX/agents/openai.yaml" \
    && grep -q 'Portable behavior oracle' "$W4M_SHARED/evals.md" \
    && grep -q 'Notification delivery is always a side channel' "$W4M_SHARED/references/workflow.md"; then
    ok "wait4me UI metadata、behavior oracle 與 failure contract 已接線"
else bad "wait4me portable behavior contract 缺失"; fi

echo "▶ 12h. send-mail skill 跨 Claude Code／Codex 共用 recipient-authority contract"
SM_CLAUDE="$ROOT/claude/skills/send-mail"
SM_CODEX="$ROOT/codex/skills/send-mail"
if [ -f "$SM_CLAUDE/SKILL.md" ] && [ -f "$SM_CODEX/SKILL.md" ] \
    && [ -L "$SM_CODEX/references" ] \
    && [ "$SM_CODEX/references/workflow.md" -ef "$SM_CLAUDE/references/workflow.md" ]; then
    ok "send-mail 雙薄入口共用 canonical workflow"
else bad "send-mail 跨 runtime 封裝未共用 workflow"; fi
if [ ! -e "$SM_CODEX/evals.md" ]; then
    ok "send-mail eval oracle 只留 canonical tree"
else bad "send-mail Codex adapter 複製了 eval oracle"; fi
sm_claude_description="$(sed -n 's/^description: //p' "$SM_CLAUDE/SKILL.md")"
sm_codex_description="$(sed -n 's/^description: //p' "$SM_CODEX/SKILL.md" 2>/dev/null)"
if [ -n "$sm_claude_description" ] \
    && [ "$sm_claude_description" = "$sm_codex_description" ]; then
    ok "send-mail 雙端 description 語意入口一致"
else bad "send-mail 雙端 description 漂移"; fi
sm_codex_frontmatter="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$SM_CODEX/SKILL.md" 2>/dev/null)"
if ! grep -Eq '^(user-invocable|disable-model-invocation|argument-hint|allowed-tools|context|agent):' \
    <<< "$sm_codex_frontmatter"; then
    ok "Codex send-mail frontmatter 無 Claude Code 專屬欄位"
else bad "Codex send-mail frontmatter 混入 Claude Code 專屬欄位"; fi
# These patterns intentionally assert that literal runtime/private paths stay out.
# shellcheck disable=SC2088
if [ -f "$SM_CLAUDE/references/workflow.md" ] \
    && ! rg -q '~/.claude|~/.codex|CLAUDE_SKILL_DIR|TaskOutput|spawn_agent|~/Projects/' \
        "$SM_CLAUDE/references/workflow.md"; then
    ok "send-mail shared workflow runtime-neutral"
else bad "send-mail shared workflow 洩漏 runtime-private surface"; fi
# shellcheck disable=SC2016
sm_sig='$send-mail'
if grep -qF "$sm_sig" "$SM_CODEX/agents/openai.yaml" 2>/dev/null \
    && grep -q 'Portable behavior oracle' "$ROOT/shared/skills/send-mail/evals.md" \
    && grep -q 'ambient identity' "$ROOT/shared/skills/send-mail/evals.md"; then
    ok "send-mail UI metadata 與 hostile-identity oracle 已接線"
else bad "send-mail metadata 或 portable behavior oracle 缺失"; fi
if grep -q 'jjshen@eland.com.tw' "$SM_CLAUDE/references/workflow.md" \
    && grep -q "NEVER use \`# userEmail\`" "$SM_CLAUDE/references/workflow.md" \
    && grep -q 'One explicit send request permits at most one delivery attempt' \
        "$SM_CLAUDE/references/workflow.md"; then
    ok "send-mail recipient authority 與 one-attempt safety contract 可達"
else bad "send-mail recipient authority 或 one-attempt contract 缺失"; fi
if grep -q '172.17.1.143' "$SM_CLAUDE/references/workflow.md" \
    && grep -q "port \`25\`" "$SM_CLAUDE/references/workflow.md" \
    && grep -q '不需要 authentication' "$SM_CLAUDE/references/workflow.md"; then
    ok "send-mail fallback relay facts 不留給 runtime 自行猜測"
else bad "send-mail fallback relay facts 缺失"; fi


echo "▶ 28. neutral shared skill core topology"
SHARED_SKILLS="$ROOT/shared/skills"
portable_skills="check-crawl-quality deep-plan handoff nc-notify ready4quit root-cause-first send-mail turbo wait4me"
if [ -d "$SHARED_SKILLS" ] && [ -z "$(find "$SHARED_SKILLS" -name SKILL.md -print 2>/dev/null)" ]; then
    ok "shared skill core 存在且不暴露 runtime entry"
else bad "shared skill core 缺漏或誤放 SKILL.md"; fi
for skill_name in $portable_skills; do
    claude_entry="$ROOT/claude/skills/$skill_name"
    codex_entry="$ROOT/codex/skills/$skill_name"
    shared_core="$SHARED_SKILLS/$skill_name"
    if [ -f "$claude_entry/SKILL.md" ] && [ -f "$codex_entry/SKILL.md" ] \
        && [ ! -L "$claude_entry" ] && [ ! -L "$codex_entry" ] \
        && [ -f "$shared_core/evals.md" ] \
        && [ "$claude_entry/evals.md" -ef "$shared_core/evals.md" ] \
        && [ ! -e "$codex_entry/evals.md" ]; then
        ok "$skill_name 雙薄入口與 single shared eval oracle"
    else bad "$skill_name adapter/core/eval topology 錯誤"; fi
done
if [ -d "$SHARED_SKILLS/project/references" ] \
    && [ -d "$SHARED_SKILLS/project/scripts" ] \
    && [ -d "$SHARED_SKILLS/project/templates" ] \
    && [ ! -e "$SHARED_SKILLS/project/evals.md" ] \
    && [ "$ROOT/claude/skills/project/references" -ef "$SHARED_SKILLS/project/references" ] \
    && [ "$ROOT/codex/skills/project/references" -ef "$SHARED_SKILLS/project/references" ]; then
    ok "project 雙薄入口共用 neutral resources（無虛構 eval oracle）"
else bad "project adapter/core topology 錯誤"; fi
if [ -f "$SHARED_SKILLS/deep-review/evals.md" ] \
    && [ "$ROOT/claude/skills/deep-review/references/workflow.md" -ef "$SHARED_SKILLS/deep-review/references/workflow.md" ] \
    && [ "$ROOT/codex/skills/repo-review/references/workflow.md" -ef "$SHARED_SKILLS/deep-review/references/workflow.md" ] \
    && [ "$ROOT/claude/skills/deep-review/scripts/lib/review-subjects.sh" -ef "$SHARED_SKILLS/deep-review/scripts/lib/review-subjects.sh" ] \
    && [ "$ROOT/codex/skills/repo-review/scripts/lib/review-subjects.sh" -ef "$SHARED_SKILLS/deep-review/scripts/lib/review-subjects.sh" ] \
    && [ "$ROOT/claude/skills/deep-review/evals.md" -ef "$SHARED_SKILLS/deep-review/evals.md" ] \
    && [ ! -e "$ROOT/codex/skills/repo-review/evals.md" ]; then
    ok "deep-review/repo-review 共用 neutral portable core 與 single eval oracle"
else bad "deep-review neutral core topology 錯誤"; fi
if grep -q 'DST_ROOT=.*\.agents/skills' "$ROOT/scripts/ensure-codex-skills.sh" \
    && ! rg -q '__codex_link_skills' "$ROOT/setup-mac-env.sh" "$ROOT/setup-linux-env.sh"; then
    ok "Codex personal skill discovery 收旂到 ~/.agents/skills"
else bad "Codex skill discovery 仍依賴 legacy ~/.codex/skills"; fi
