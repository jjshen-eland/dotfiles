#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 1b. 全形標點吞變數名 gate"
# bash 在部分 locale 下會把緊接在 $var 後的多位元組字元併進變數名：
#   echo "（exit=$rc）"  →  set -u 下噴 `rc）: unbound variable`
# 本 repo 大量使用繁中訊息，這個雷已在 2026-07-20 一天內踩中三次（run/resume 訊息、
# ensure-codex-skills 接管告知、range 驗證），且只在錯誤路徑觸發、正常測試照樣全綠。
# 一律要求寫成 ${var}。DO NOT relax this gate — 它守的是「只有出事時才會爆」的那條路徑。
# 寫法必須可攜：`grep -P` 只有 GNU grep 有，macOS 的 BSD grep 會直接報錯——若再把 stderr
# 導掉並 `|| true`，gate 會把「執行失敗」誤判成「乾淨」（本 gate 初版即如此假綠）。
# 改用 C locale + `[^[:print:][:space:]]`：C locale 下多位元組字元的每個 byte 都非 print，
# 且排除 space/tab（`$var<TAB>` 在 bash 中會正常斷詞，不是問題）。
fullwidth_hits="$(LC_ALL=C grep -nE '\$[A-Za-z_][A-Za-z0-9_]*[^[:print:][:space:]]' \
    "$ROOT"/scripts/*.sh "$ROOT/scripts/lib/inventory.sh" \
    "$ROOT"/claude/scripts/*.sh \
    "$ROOT"/claude/skills/*/scripts/*.sh "$ROOT"/claude/skills/*/scripts/lib/*.sh \
    "$ROOT"/codex/skills/*/scripts/*.sh \
    "$ROOT/.githooks/dispatcher" \
    "$ROOT"/shell/*.sh \
    "$ROOT"/claude/evals/*.sh \
    "$ROOT"/tests/*.sh)"
fullwidth_rc=$?
# grep 的 exit：0=有命中、1=無命中、>1=執行錯誤（後者必須大聲失敗，不可當成乾淨）
fullwidth_hits="$(printf '%s\n' "$fullwidth_hits" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)"
if [ "$fullwidth_rc" -gt 1 ]; then
    bad "全形標點 gate 無法執行（grep rc=${fullwidth_rc}）——不可視為通過"
elif [ -z "$fullwidth_hits" ]; then
    ok "無 \$var 緊接全形/多位元組字元的寫法"
else
    bad "有 \$var 緊接多位元組字元（set -u 下會 unbound variable，須改 \${var}）"
    printf '%s\n' "$fullwidth_hits" | sed 's/^/     /'
fi

echo "▶ 1c. unquoted heredoc 反引號 gate"
# bash 對 `<<EOF`（delimiter 未加引號）的 body 做命令替換 → 文字裡一組行內 code 的反引號
# 會**真的被執行**。2026-08-07 兩次實地：一次讓 `git push` 真的推了一條 branch 上 GitHub；
# 一次是 dotfiles-sync/setup 用 `<< SSHEOF` 灌 ssh/config，而 ssh/config 正是會長註解的檔案
# ——差一步就把毀損的 ~/.ssh/config 部署到全機隊。判準與掃描器見 tests/heredoc-gate.awk。
# DO NOT relax this gate — 失敗是靜默的：產出的檔案少一段文字，副作用發生在別的地方。
HD_GATE="$ROOT/tests/heredoc-gate.awk"
mkdir -p "$TMP/hd"
# 掃描器自檢（RED 抓得到、GREEN 不誤報）。少了這兩條，掃描器被改壞而恆不匹配時，
# 底下對真實檔案的空輸出一樣是「通過」——gate 會靜默變成永遠綠。
cat > "$TMP/hd/red.sh" <<'HDFIX'
cat > /tmp/out.md << EOF
說明：`git push` 會把 branch 推上去
EOF
HDFIX
# `$(cat 某檔)` 注入外部檔案內容 → **不得**報。命令替換的結果不會被重新掃描，該檔裡的
# 反引號不會被執行（2026-08-07 實測；當時誤判成同一個地雷、為它加過一條誤報規則，
# 那條規則會把每個「用 heredoc 灌檔」的正常寫法都判紅）。
cat > "$TMP/hd/green-cat.sh" <<'HDFIX'
cat > ~/.ssh/config << SSHEOF
# 此檔案由 dotfiles setup 腳本產生
$(cat "$DOTFILES_DIR/ssh/config")
SSHEOF
HDFIX
cat > "$TMP/hd/green.sh" <<'HDFIX'
cat > /tmp/out.md << 'SAFE'
說明：`git push` 在這裡是字面，不會被執行
內含 <<INNER 樣式的文字也不該讓掃描器誤判成新的 heredoc
SAFE
grep -q pattern <<< "$big"
echo "一般行的 `date` 不歸本 gate 管"
# 註解裡討論 <<EOF 這個寫法時不得被當成 heredoc 起始——本 gate 自己的註解就會這樣寫，
# 誤判會把後面數行全報成 body（第一版即如此，真正的問題行反而被蓋掉）
echo "上一行是註解，這行的 `date` 同樣不歸本 gate 管"
cat > "$1" <<STUB
printf '%s\n' "\$(cat '${3:-/dev/null}')"
STUB
HDFIX
if [ -n "$(awk -f "$HD_GATE" "$TMP/hd/red.sh")" ]; then ok "gate 自檢：unquoted heredoc 含反引號 → 命中"; else bad "gate 失效（RED fixture 沒被抓，真實掃描的空輸出不可信）"; fi
if [ -z "$(awk -f "$HD_GATE" "$TMP/hd/green-cat.sh")" ]; then ok "gate 自檢：\$(cat 某檔) 注入 → 不報（展開結果不重新掃描，實測確認）"; else bad "gate 把安全的灌檔寫法判紅——每個用 heredoc 灌檔的地方都會被逼著改"; fi
if [ -z "$(awk -f "$HD_GATE" "$TMP/hd/green.sh")" ]; then ok "gate 自檢：quoted heredoc／herestring／註解／跳脫的 \\\$(cat → 不誤報"; else bad "gate 誤報（會逼人把安全寫法改壞以求過測）"; fi
hd_hits="$(awk -f "$HD_GATE" \
    "$ROOT"/scripts/*.sh "$ROOT"/scripts/lib/*.sh \
    "$ROOT"/claude/scripts/*.sh \
    "$ROOT"/claude/skills/*/scripts/*.sh "$ROOT"/claude/skills/*/scripts/lib/*.sh \
    "$ROOT"/codex/skills/*/scripts/*.sh \
    "$ROOT/.githooks/dispatcher" \
    "$ROOT"/shell/*.sh \
    "$ROOT/setup-mac-env.sh" "$ROOT/setup-linux-env.sh" "$ROOT/write-mac-defaults.sh" \
    "$ROOT"/claude/evals/*.sh \
    "$ROOT"/tests/*.sh)"
hd_rc=$?
if [ "$hd_rc" -ne 0 ]; then
    bad "heredoc scanner 執行失敗（exit ${hd_rc}），不可視為零命中"
elif [ -z "$hd_hits" ]; then
    ok "無 unquoted heredoc 的 body 含反引號"
else
    bad "有 unquoted heredoc 的 body 含反引號（一律改 <<'EOF'，變數走 os.environ/sys.argv）"
    printf '%s\n' "$hd_hits" | sed 's/^/     /'
fi

echo "▶ 1cc. pipe-to-grep early-exit gate"
# `grep -q`／`-m` 命中後會提早關閉 pipe；上游若還有一次寫入就收到 SIGPIPE，
# `set -o pipefail` 便把真命中翻成失敗。producer 不限 printf：bash 的 stdout 是 line-buffered，
# 多行 `echo "$out"` 會分次寫入，PR #302 的 Ubuntu run 即因此在 ship-state 偽紅、重跑轉綠。
# 存在性檢查一律寫 `grep -q ... <<< "$value"`。Regex 拆開組裝，避免 gate 自己成為命中。
pipe_grep_re='[|][[:space:]]*grep[[:space:]]+-[A-Za-z]*'
pipe_grep_re="${pipe_grep_re}[qm]"
pipe_grep_scan() {  # <file...>：印出非註解、非 `||`、未標 intentional 的命中行
    awk -v re="(^|[^|])$pipe_grep_re" '!/^[[:space:]]*#/ && !/# pipe-grep: intentional/ && $0 ~ re { print FILENAME ":" FNR ":" $0 }' "$@"
}
mkdir -p "$TMP/pg"
# shellcheck disable=SC2016  # fixture 是字面程式碼
printf '%s\n' 'if echo "$out" @ grep -q x; then :; fi' 'git log @ grep -qE y' | tr '@' '|' > "$TMP/pg/red.sh"
# shellcheck disable=SC2016
printf '%s\n' 'if grep -q x <<< "$out"; then :; fi' '# echo "$out" @ grep -q x' 'grep -v x f @ sort' \
    'a @@ grep -q x <<< "$b"' | tr '@' '|' > "$TMP/pg/green.sh"
if [ "$(pipe_grep_scan "$TMP/pg/red.sh" | wc -l | tr -d ' ')" = 2 ]; then ok "gate 自檢：echo／指令接 grep -q 都命中"; else bad "pipe-to-grep gate 漏抓 RED fixture"; fi
if [ -z "$(pipe_grep_scan "$TMP/pg/green.sh")" ]; then ok "gate 自檢：herestring、註解、非早退 grep、|| 不誤報"; else bad "pipe-to-grep gate 誤報安全寫法"; fi
# 機制對照：上游第二次寫入晚於 grep 命中時，pipefail 必把真命中翻成失敗；herestring 不受影響。
pg_rc=0; { echo hit; sleep 0.3; echo more; } | grep -q hit || pg_rc=$?  # pipe-grep: intentional
if [ "$pg_rc" -ne 0 ] && grep -q hit <<< "$(printf 'hit\nmore\n')"; then
    ok "機制對照：早退 grep + pipefail 翻成失敗（rc=${pg_rc}），herestring 正確命中"
else
    bad "機制對照未重現（rc=${pg_rc}）——gate 的前提需重新查證"
fi
pipe_grep_hits="$(pipe_grep_scan "$ROOT/tests/module-shell.sh" "$ROOT/tests/modules/"*.sh)"
if [ -z "$pipe_grep_hits" ]; then
    ok "test modules 無 pipe-to-grep early-exit pipeline"
else
    bad "test modules 仍有 pipe-to-grep -q／-m（改用 grep -q ... <<< \"\$value\"）：$(wc -l <<< "$pipe_grep_hits" | tr -d ' ') 處"
    head -5 <<< "$pipe_grep_hits" | sed 's/^/     /'
fi


echo "▶ 2. bash -n 語法 gate"
syntax_fail=0
for f in "${SHELL_GATE_FILES[@]}"; do
    bash -n "$f" || { syntax_fail=1; echo "     syntax fail: $f"; }
done
if [ "$syntax_fail" -eq 0 ]; then ok "bash -n 全部通過"; else bad "bash -n 有語法錯誤"; fi
