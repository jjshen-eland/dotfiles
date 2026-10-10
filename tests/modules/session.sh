#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 15. ensure-rc-source.sh 幂等補 source 行"
ERS="$ROOT/scripts/ensure-rc-source.sh"
MARKER='shell/functions.sh'

# rc 無 marker → 補上一行
ers_rc="$TMP/rc-plain"
printf '# 既有內容\nexport FOO=bar\n' > "$ers_rc"
RC_FILE="$ers_rc" bash "$ERS"
assert_rc "無 marker → exit 0" 0 $?
if grep -qF "$MARKER" "$ers_rc"; then ok "已補上 source 行"; else bad "未補上 source 行"; fi
if grep -qxF 'export FOO=bar' "$ers_rc"; then ok "原有內容保留"; else bad "原有內容遺失"; fi

# 再跑一次 → 幂等不重複（數 source 行本身，避開含 marker 的註解行）
RC_FILE="$ers_rc" bash "$ERS"
ers_count=$(grep -cF 'source ~/.dotfiles/shell/functions.sh' "$ers_rc")
assert_eq "重跑不重複（source 行出現 1 次）" "1" "$ers_count"

# 已含 marker 的 rc → 原封不動
ers_pre="$TMP/rc-pre"
printf 'source ~/.dotfiles/shell/functions.sh\n' > "$ers_pre"
cp "$ers_pre" "$ers_pre.orig"
RC_FILE="$ers_pre" bash "$ERS"
if diff -q "$ers_pre" "$ers_pre.orig" >/dev/null; then ok "已含 marker → 內容不變"; else bad "已含 marker 仍被改動"; fi

# rc 不存在 → 不建立、exit 0
ers_none="$TMP/rc-nonexistent"
RC_FILE="$ers_none" bash "$ERS"
assert_rc "rc 不存在 → exit 0" 0 $?
if [ ! -e "$ers_none" ]; then ok "rc 不存在 → 不建立檔案"; else bad "rc 不存在卻建立了檔案"; fi

# --- 已遷移到 functions.sh 的舊 alias 清理 ---
# 不能靠 functions.sh 裡 unalias：alias 展開優先於 function 查找，而 rc 裡 alias 與
# source 行的相對順序因機器而異（實地 14 台：13 台 source 在後、macmini 在前），
# unalias 會變成「多數生效、少數靜默失效」。故這裡驗的是「確實從 rc 刪行」。
ers_stale="$TMP/rc-stale"
printf 'alias brewup=%s\nalias sysup=%s\nalias ll=%s\nexport KEEP=1\n' "'old-brewup'" "'old-sysup'" "'eza -l'" > "$ers_stale"
RC_FILE="$ers_stale" bash "$ERS" >/dev/null
assert_rc "含舊 alias → exit 0" 0 $?
ers_n=$(grep -cE '^alias (brewup|sysup)=' "$ers_stale")
assert_eq "brewup/sysup alias 已移除" "0" "$ers_n"
if grep -qxF "alias ll='eza -l'" "$ers_stale"; then ok "其他 alias 未被誤刪"; else bad "誤刪了其他 alias"; fi
if grep -qxF 'export KEEP=1' "$ers_stale"; then ok "非 alias 內容保留"; else bad "非 alias 內容遺失"; fi
if grep -qF "$MARKER" "$ers_stale"; then ok "同時補上 source 行"; else bad "未補上 source 行"; fi

# 重跑 → 幂等（已無舊 alias，檔案不再變動）
cp "$ers_stale" "$ers_stale.after1"
RC_FILE="$ers_stale" bash "$ERS" >/dev/null
if diff -q "$ers_stale" "$ers_stale.after1" >/dev/null; then ok "清理後重跑 → 內容不變"; else bad "清理後重跑仍改動檔案"; fi

# 前提檢查：減幅超過 2 行 → 原封不動（守住「破壞性覆寫前先驗行數」那道閘）
# 沒有這條，整段前提檢查可以被刪光而測試照樣全綠。
ers_many="$TMP/rc-many"
printf 'alias brewup=%s\nalias brewup=%s\nalias sysup=%s\nalias sysup=%s\nexport KEEP=1\n' \
    "'a'" "'b'" "'c'" "'d'" > "$ers_many"
cp "$ers_many" "$ers_many.orig"
RC_FILE="$ers_many" bash "$ERS" >/dev/null 2>&1
ers_many_n=$(grep -cE '^alias (brewup|sysup)=' "$ers_many")
assert_eq "減幅 4 行 > 上限 2 → 四行舊 alias 全數保留（未覆寫）" "4" "$ers_many_n"

echo "▶ 16. session-pull-check.sh（SessionStart hook）落後偵測與靜默契約"
SPC="$ROOT/claude/scripts/session-pull-check.sh"

# fixture：bare origin + clone a（推進 3 commits）+ clone b（停在第 1 個 commit）
spc="$TMP/spc"; mkdir -p "$spc"
git init -q --bare -b main "$spc/origin.git"
git clone -q "$spc/origin.git" "$spc/a" 2>/dev/null
(cd "$spc/a" && git config user.name t && git config user.email t@t.local \
  && echo 1 > f && git add . && git commit -qm c1 && git push -q origin main)
git clone -q "$spc/origin.git" "$spc/b" 2>/dev/null
(cd "$spc/b" && git config user.name t && git config user.email t@t.local)
(cd "$spc/a" && echo 2 >> f && git commit -qam c2 && echo 3 >> f && git commit -qam c3 && git push -q origin main)

# (1) 落後 clone → 提醒輸出且 exit 0
rm -f "$spc/b/.git/FETCH_HEAD"
spc_out="$(cd "$spc/b" && bash "$SPC")"
assert_rc "落後 clone → exit 0" 0 $?
if grep -q "落後" <<< "$spc_out"; then ok "落後 clone → 提醒輸出（含 behind 數）"; else bad "落後 clone 無提醒：$spc_out"; fi

# (2) 非 git repo → 靜默 exit 0
spc_out="$(cd "$TMP" && bash "$SPC")"
assert_rc "非 repo → exit 0" 0 $?
assert_eq "非 repo → 無輸出" "" "$spc_out"

# (3) detached HEAD → 靜默 exit 0
(cd "$spc/b" && git checkout -q --detach HEAD)
spc_out="$(cd "$spc/b" && bash "$SPC")"
assert_rc "detached HEAD → exit 0" 0 $?
assert_eq "detached HEAD → 無輸出" "" "$spc_out"
(cd "$spc/b" && git checkout -q main)

# (4) FETCH_HEAD 新鮮 → 跳過 fetch（證法：壞 remote 下仍能報落後 = 未嘗試 fetch；
#     對照組：FETCH_HEAD 過期時同樣壞 remote → fetch 失敗靜默 exit 0、無輸出）
(cd "$spc/b" && git remote set-url origin "$spc/nonexistent.git" && touch .git/FETCH_HEAD)
spc_out="$(cd "$spc/b" && bash "$SPC")"
assert_rc "壞 remote + FETCH_HEAD 新鮮 → exit 0" 0 $?
if grep -q "落後" <<< "$spc_out"; then ok "FETCH_HEAD 新鮮 → 跳過 fetch 仍報落後"; else bad "FETCH_HEAD 新鮮未跳過 fetch：$spc_out"; fi
rm -f "$spc/b/.git/FETCH_HEAD"
spc_out="$(cd "$spc/b" && bash "$SPC")"
assert_rc "壞 remote + 需 fetch → exit 0" 0 $?
assert_eq "壞 remote + 需 fetch → 靜默放棄偵測" "" "$spc_out"
(cd "$spc/b" && git remote set-url origin "$spc/origin.git")

# (5) STATUS.md 過期（最後 commit 落後 repo 活動 > 30 天）→ staleness 提醒
(cd "$spc/a" && echo "# STATUS" > STATUS.md && git add STATUS.md \
  && GIT_COMMITTER_DATE="2026-01-01T10:00:00" git commit -qm "docs: status" --date="2026-01-01T10:00:00" \
  && echo 4 >> f && git commit -qam c4)
spc_out="$(cd "$spc/a" && bash "$SPC")"
assert_rc "stale STATUS.md → exit 0" 0 $?
if grep -q "過期" <<< "$spc_out"; then ok "stale STATUS.md → dossier 過期提醒"; else bad "stale STATUS.md 無提醒：$spc_out"; fi

# (6) 同步且無 STATUS.md → 完全靜默（happy path，「絕不留噪音」契約的正面驗證）
(cd "$spc/b" && git pull -q origin main >/dev/null 2>&1)
rm -f "$spc/b/.git/FETCH_HEAD"
spc_out="$(cd "$spc/b" && bash "$SPC")"
assert_rc "同步 clone → exit 0" 0 $?
assert_eq "同步 clone → 完全靜默" "" "$spc_out"

# --- worktree 雙寫入者與 base 建議（純本地判斷：必須在 fetch/upstream 早退之前就跑完，
#     否則離線或無 upstream 的 branch 上整組訊號失效）---

# (7) feature branch 相對 origin/<default> 有未併 commit → base 建議
(cd "$spc/b" && git switch -qc feat/base && echo x > g && git add g && git commit -qm "feat: g")
spc_out="$(cd "$spc/b" && bash "$SPC")"
assert_rc "feature branch 有未併 commit → exit 0" 0 $?
if grep -q "未併 commit" <<< "$spc_out" && grep -q "base 用 head" <<< "$spc_out"; then
    ok "feature branch 有未併 commit → 報 base 建議"
else bad "feature branch 未報 base 建議：$spc_out"; fi
# squash merge 不保留 commit id，origin/<default>..HEAD 在已合併的線上仍非空；
# hook 沒有 PR 狀態可查，只能給保守提示，不可斷言「這條線還沒併」
if grep -q "squash" <<< "$spc_out"; then
    ok "base 建議帶 squash-merge 的保守提示"
else bad "base 建議未提示 squash merge 可能已併入：$spc_out"; fi

# (8) feature branch 無未併 commit（剛開的分支）→ 完全靜默
(cd "$spc/b" && git switch -q main && git switch -qc feat/empty)
spc_out="$(cd "$spc/b" && bash "$SPC")"
assert_eq "feature branch 無未併 commit → 完全靜默" "" "$spc_out"

# (9) default branch 上有未 push commit → 不報 base 建議（刻意收斂：那是 ship 側的事，
#     git-hygiene.sh / /project log 已覆蓋，hook 不重複出聲）
(cd "$spc/b" && git switch -q main && echo y > h && git add h && git commit -qm "chore: h")
spc_out="$(cd "$spc/b" && bash "$SPC")"
if grep -q "base 用 head" <<< "$spc_out"; then
    bad "default branch 誤報 base 建議：$spc_out"
else ok "default branch 有未 push commit → 不報 base 建議"; fi

# (10) 有 linked worktree（clean）→ 報其存在與 branch，不標 dirty
git -C "$spc/b" worktree add -q "$spc/b-wt" -b feat/wt
spc_out="$(cd "$spc/b" && bash "$SPC")"
if grep -q "worktree 使用中" <<< "$spc_out" && grep -q "feat/wt" <<< "$spc_out"; then
    ok "linked worktree → 報 worktree 名與 branch"
else bad "未報 linked worktree：$spc_out"; fi
if grep -q "未 commit 變更" <<< "$spc_out"; then
    bad "clean worktree 誤標 dirty：$spc_out"
else ok "clean worktree → 不標 dirty"; fi

# (11) worktree 的 working tree 髒了 → 標示（dirty 才是「有人正在寫」的實證）
echo dirty > "$spc/b-wt/dirtyfile"
spc_out="$(cd "$spc/b" && bash "$SPC")"
if grep -q "未 commit 變更" <<< "$spc_out"; then
    ok "dirty worktree → 標示有未 commit 變更"
else bad "dirty worktree 未標示：$spc_out"; fi

# (12) 在 linked worktree 內執行 → 仍報另一個 worktree，但**不報 base 建議**
#      （base 是開 worktree 當下才要選的；feat/wt 相對 origin/main 有 commit，
#        少了這道條件就會誤報——故本斷言是條件 1 的守門）
spc_out="$(cd "$spc/b-wt" && bash "$SPC")"
assert_rc "linked worktree 內 → exit 0" 0 $?
if grep -q "worktree 使用中" <<< "$spc_out"; then
    ok "linked worktree 內 → 仍報另一個 worktree"
else bad "linked worktree 內未報 worktree：$spc_out"; fi
if grep -q "base 用 head" <<< "$spc_out"; then
    bad "linked worktree 內誤報 base 建議：$spc_out"
else ok "linked worktree 內 → 不報 base 建議"; fi

# (13) base 建議必須用 fetch 之後的 ref 重算：別台已把這些 commit 併進 default 時，
#      stale 的 origin/<default> 會讓 hook 建議「base 用 head」，而正確答案是沒有未併 commit
git clone -q "$spc/origin.git" "$spc/c" 2>/dev/null
(cd "$spc/c" && git config user.name t && git config user.email t@t.local \
  && git switch -qc feat/merged && echo m > m.txt && git add m.txt && git commit -qm "feat: m")
# 在 origin 端快轉 main（模擬別台 merge 後 push）。兩個坑：
#   1. 直接 update-ref 會失敗——那顆 commit 的 object 只在本機 clone 裡，bare repo 沒有
#      （fatal: trying to write ref with nonexistent object），main 根本不會動
#   2. 但不能用 `push origin HEAD:main` 送 object，那會順手更新本機的 origin/main，
#      stale 情境就沒了
# 故：先推到別名 ref 把 object 送過去，再 update-ref 快轉 main，最後清掉別名。
spc_c_sha="$(git -C "$spc/c" rev-parse HEAD)"
if ! git -C "$spc/c" push -q origin "HEAD:refs/heads/tmp-import" \
    || ! git -C "$spc/origin.git" update-ref refs/heads/main "$spc_c_sha"; then
    bad "fixture 建立失敗：無法在 origin 端快轉 main（下一條斷言將失去意義）"
fi
git -C "$spc/origin.git" update-ref -d refs/heads/tmp-import
rm -f "$spc/c/.git/FETCH_HEAD"
# 前置條件：此刻本機 ref 仍是 stale 的（ahead=1），fetch 之後才會變 0。
# 這條斷言在守 fixture 本身——沒有它，fixture 一壞就會偽裝成「實作有問題」
assert_eq "fixture 前置：fetch 前 ahead=1（stale ref 情境成立）" \
    "1" "$(git -C "$spc/c" rev-list --count origin/main..HEAD 2>/dev/null)"
spc_out="$(cd "$spc/c" && bash "$SPC")"
if grep -q "base 用 head" <<< "$spc_out"; then
    bad "base 建議未用 fetch 後的 ref 重算（stale origin/<default> 造成誤報）：$spc_out"
else ok "base 建議在 fetch 後重算 → 已併入 default 時不再誤報"; fi

# (14) 多 remote：fetch 別的 remote 讓 FETCH_HEAD 變新鮮，但 origin/<default> 仍是舊的。
#      base 建議固定比較 origin/<default>，不能把「剛 fetch 過某個 remote」當成它新鮮
git init --bare -q -b main "$spc/mr-other.git"
git clone -q "$spc/origin.git" "$spc/d" 2>/dev/null
(cd "$spc/d" && git config user.name t && git config user.email t@t.local \
  && git remote add other "$spc/mr-other.git" && git push -q other main \
  && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
  && git switch -qc feat/mr && echo mr > mr.txt && git add mr.txt && git commit -qm "feat: mr")
spc_d_sha="$(git -C "$spc/d" rev-parse HEAD)"
if ! git -C "$spc/d" push -q origin "HEAD:refs/heads/tmp-mr" \
    || ! git -C "$spc/origin.git" update-ref refs/heads/main "$spc_d_sha"; then
    bad "fixture 建立失敗：無法在 origin 端快轉 main（下一條斷言將失去意義）"
fi
git -C "$spc/origin.git" update-ref -d refs/heads/tmp-mr
git -C "$spc/d" fetch -q other        # 只碰 other，卻讓 repo-global FETCH_HEAD 變新鮮
assert_eq "fixture 前置：origin/<default> 仍 stale（ahead=1）" \
    "1" "$(git -C "$spc/d" rev-list --count origin/main..HEAD 2>/dev/null)"
spc_out="$(cd "$spc/d" && bash "$SPC")"
if grep -q "base 用 head" <<< "$spc_out" && ! grep -q "可能已過期" <<< "$spc_out"; then
    bad "fetch 別的 remote 後仍給無警告的 base 建議（stale origin/<default>）：$spc_out"
else ok "多 remote：未實際 fetch baseline remote → base 建議不出現或帶過期警告"; fi

# (15) 多 remote 的落後偵測：剛 fetch 過別的 remote 會讓 repo-global 的 FETCH_HEAD 變新鮮，
#      但 upstream（origin/main）的 tracking ref 仍是舊的。拿快取當「upstream 已刷新」的
#      證據 → 真正落後的 clone 完全不出聲。這是 false negative，配上 hook「失敗一律靜默」
#      的契約更難察覺——(14) 只保護 base 建議那一半，這條保護落後偵測那一半。
git init --bare -q -b main "$spc/mr2-other.git"
git clone -q "$spc/origin.git" "$spc/e" 2>/dev/null
(cd "$spc/e" && git config user.name t && git config user.email t@t.local \
  && git remote add other "$spc/mr2-other.git" && git push -q other main)
spc_e_old="$(git -C "$spc/e" rev-parse HEAD)"
(cd "$spc/e" && echo behind > behind.txt && git add behind.txt && git commit -qm c4 && git push -q origin main)
# 本機退回舊 commit，並把 tracking ref 一起退回 → 不 fetch 就看不出落後
(cd "$spc/e" && git reset -q --hard "$spc_e_old")
git -C "$spc/e" update-ref refs/remotes/origin/main "$spc_e_old"
git -C "$spc/e" fetch -q other        # 只碰 other，卻讓 repo-global FETCH_HEAD 變新鮮
assert_eq "fixture 前置：stale 的 origin/main 看不出落後（behind=0）" \
    "0" "$(git -C "$spc/e" rev-list --count HEAD..origin/main 2>/dev/null)"
assert_eq "fixture 前置：origin 端實際已前進 1 個 commit" \
    "1" "$(git -C "$spc/origin.git" rev-list --count "${spc_e_old}..refs/heads/main" 2>/dev/null)"
spc_out="$(cd "$spc/e" && bash "$SPC")"
if grep -q "落後" <<< "$spc_out"; then
    ok "多 remote：fetch other 不會讓落後偵測改用 stale upstream 判定"
else bad "多 remote：真實落後的 clone 未提醒（fetch other 讓 FETCH_HEAD 假新鮮）：$spc_out"; fi

# (16) fetch 真的失敗（單 remote，快取不介入）→ base 建議仍要出，但必須帶過期警告。
#      (14) 在多 remote 快取失效後走的是「建議不出現」那一臂，這條把「出現且帶警告」
#      那一臂釘住，否則 stale_note 整段會變成沒有測試覆蓋的死碼。
git clone -q "$spc/origin.git" "$spc/f" 2>/dev/null
(cd "$spc/f" && git config user.name t && git config user.email t@t.local \
  && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
  && git switch -qc feat/stale && echo s > s.txt && git add s.txt && git commit -qm "feat: stale")
(cd "$spc/f" && git remote set-url origin "$spc/nonexistent.git")
rm -f "$spc/f/.git/FETCH_HEAD"        # 強制真的去 fetch（而且會失敗）
spc_out="$(cd "$spc/f" && bash "$SPC")"
assert_rc "fetch 失敗 + feature branch → exit 0" 0 $?
if grep -q "base 用 head" <<< "$spc_out" && grep -q "可能已過期" <<< "$spc_out"; then
    ok "fetch 失敗 → base 建議帶「可能已過期」警告"
else bad "fetch 失敗後的 base 建議未標示 ref 可能過期：$spc_out"; fi


echo "▶ 16b. agent-turn-end-timestamp.sh（Claude Code／Codex Stop hook）"
TET="$ROOT/scripts/agent-turn-end-timestamp.sh"
tet_bin="$TMP/tet-bin"
mkdir -p "$tet_bin"
cat > "$tet_bin/date" <<'STUB'
#!/usr/bin/env bash
printf '%s|%s\n' "${TZ:-}" "$*" > "${TET_DATE_CALL:?}"
if [ "${TET_DATE_FAIL:-0}" -eq 1 ]; then exit 1; fi
printf '%s\n' '2026-09-02 16:05:06 GMT+8'
STUB
chmod +x "$tet_bin/date"

if [ -x "$TET" ]; then
    ok "turn-end timestamp hook script 存在且可執行"
    tet_date_call="$TMP/tet-date-call"
    tet_out="$(printf '%s\n' '{"hook_event_name":"Stop","secret":"must-not-leak"}' \
        | PATH="$tet_bin:$PATH" TZ=UTC TET_DATE_CALL="$tet_date_call" "$TET")"
    assert_rc "turn-end timestamp hook 成功 → exit 0" 0 $?
    assert_eq "turn-end timestamp 輸出兩端共用的有效 JSON" \
        '{"systemMessage":"🕒 等待輸入起點：2026-09-02 16:05:06 GMT+8"}' "$tet_out"
    if printf '%s\n' "$tet_out" | jq -e '.systemMessage | type == "string"' >/dev/null 2>&1; then
        ok "turn-end timestamp stdout 可被 hook runtime 當作 JSON 解析"
    else bad "turn-end timestamp stdout 不是有效 hook JSON：$tet_out"; fi
    assert_eq "turn-end timestamp 強制固定 GMT+8，不受 host TZ 影響" \
        "Etc/GMT-8|+%Y-%m-%d %H:%M:%S GMT+8" "$(cat "$tet_date_call" 2>/dev/null)"
    if grep -qF 'must-not-leak' <<< "$tet_out"; then
        bad "turn-end timestamp 把 hook input 內容洩漏到 UI"
    else ok "turn-end timestamp 不回顯 hook input"; fi

    tet_fail_out="$(printf '%s\n' '{"hook_event_name":"Stop"}' \
        | PATH="$tet_bin:$PATH" TET_DATE_CALL="$tet_date_call" TET_DATE_FAIL=1 "$TET")"
    assert_rc "date 失敗 → hook 仍 exit 0" 0 $?
    assert_eq "date 失敗 → hook 靜默，不阻斷 agent 收尾" "" "$tet_fail_out"
else
    bad "turn-end timestamp hook script 不存在或不可執行：$TET"
fi

# SubagentStop may collect Turbo reviewer evidence, but must never emit main-agent
# waiting notices. Check those commands instead of forbidding unrelated hooks.
claude_subagent_quiet='
    [(.hooks.SubagentStop // [])[] | .hooks[]?
     | select(.command | contains("agent-turn-end-timestamp.sh") or contains("wait4me-hook.sh"))]
    | length == 0
'
if jq -e \
    --arg timestamp '"$HOME"/.dotfiles/scripts/agent-turn-end-timestamp.sh claude' \
    --arg turbo 'python3 "$HOME"/.dotfiles/shared/skills/turbo/scripts/turbo-state.py hook Stop --runtime claude' \
    --arg wait4me 'WAIT4ME_ENV_FILE="$HOME/Projects/krepo/.env" "$HOME"/.dotfiles/shared/skills/wait4me/scripts/wait4me-hook.sh stop' '
    .hooks.Stop == [{hooks: [
        {type: "command", command: $timestamp, timeout: 3},
        {type: "command", command: $wait4me, timeout: 5, async: true}
    ]}, {hooks: [{type: "command", command: $turbo, timeout: 5}]}]
' "$ROOT/claude/settings.json" >/dev/null 2>&1 \
    && jq -e "$claude_subagent_quiet" "$ROOT/claude/settings.json" >/dev/null 2>&1 \
    && ! jq -e ".hooks.SubagentStop = [{hooks: [{command: \"agent-turn-end-timestamp.sh\"}]}] | $claude_subagent_quiet" \
        "$ROOT/claude/settings.json" >/dev/null 2>&1 \
    && ! jq -e ".hooks.SubagentStop = [{hooks: [{command: \"wait4me-hook.sh stop\"}]}] | $claude_subagent_quiet" \
        "$ROOT/claude/settings.json" >/dev/null 2>&1; then
    ok "Claude Code 主 agent Stop 同時接線 timestamp 與 wait4me"
else bad "Claude Code Stop hook 未精確接線 timestamp／wait4me"; fi

codex_tet_hook="$(awk '
    /^\[\[hooks\.Stop\]\]$/ { capture = 1 }
    capture && /^\[/ && $0 !~ /^\[\[hooks\.Stop(\.hooks)?\]\]$/ { exit }
    capture { print }
' "$ROOT/codex/config.toml")"
# shellcheck disable=SC2016 # $HOME 是 TOML command 的字面值，要留到 hook 執行時才展開。
codex_tet_expected='[[hooks.Stop]]

[[hooks.Stop.hooks]]
type = "command"
command = '\''"$HOME"/.dotfiles/scripts/agent-turn-end-timestamp.sh codex'\''
timeout = 3

[[hooks.Stop.hooks]]
type = "command"
command = '\''WAIT4ME_ENV_FILE="$HOME/Projects/krepo/.env" "$HOME"/.dotfiles/shared/skills/wait4me/scripts/wait4me-hook.sh stop'\''
timeout = 5'
if [ "$codex_tet_hook" = "$codex_tet_expected" ] \
    && ! grep -q '^\[\[hooks\.SubagentStop' "$ROOT/codex/config.toml"; then
    ok "Codex 主 agent Stop 同時接線 timestamp 與同步 wait4me"
else bad "Codex Stop hook 未精確接線 timestamp／同步 wait4me"; fi

echo "▶ 16bb. wait4me session 開關與 notification failure isolation"
W4M_HOOK="$ROOT/shared/skills/wait4me/scripts/wait4me-hook.sh"
W4M_SEND="$ROOT/shared/skills/wait4me/scripts/wait4me-send.py"
w4m_fix="$TMP/wait4me"
w4m_state="$w4m_fix/state"
w4m_capture="$w4m_fix/capture.jsonl"
w4m_probe_capture="$w4m_fix/probe-capture.jsonl"
mkdir -p "$w4m_fix"
w4m_env_file="$w4m_fix/notify.env"
cat > "$w4m_env_file" <<'EOF'
NC_API_URL=https://invalid.example/from-env-file
NC_API_KEY=fixture-env-file-key
EOF
chmod 600 "$w4m_env_file"

w4m_run() {
    local mode="$1" input="$2" capture="${3-$w4m_capture}"
    printf '%s\n' "$input" | env -u NC_API_URL -u NC_API_KEY \
        WAIT4ME_STATE_ROOT="$w4m_state" WAIT4ME_TEST_CAPTURE="$capture" \
        WAIT4ME_ENV_FILE="$w4m_env_file" \
        "$W4M_HOOK" "$mode"
}

if [ -x "$W4M_HOOK" ] && [ -x "$W4M_SEND" ]; then
    ok "wait4me hook 與 sender 存在且可執行"
else bad "wait4me hook 或 sender 缺失／不可執行"; fi

w4m_out="$(w4m_run prompt "{\"session_id\":\"session-a\",\"prompt\":\"\$wait4me\",\"cwd\":\"/work/kapi-infra\"}" "$w4m_probe_capture")"
if jq -e '.hookSpecificOutput.additionalContext | contains("wait4me-control: enabled")' \
    <<< "$w4m_out" >/dev/null 2>&1; then
    ok "bare wait4me 只啟用目前 session 並回傳 hook context"
else bad "bare wait4me 未啟用或未回傳可驗證 context：$w4m_out"; fi
if jq -e '.hookSpecificOutput.additionalContext | contains("probe=accepted")' <<< "$w4m_out" >/dev/null 2>&1 \
    && [ "$(wc -l < "$w4m_probe_capture" | tr -d ' ')" -eq 1 ] \
    && jq -e '.message | contains("wait4me 通知測試")' "$w4m_probe_capture" >/dev/null 2>&1; then
    ok "on 立即發一則可辨識的 NC 測試通知"
else bad "on 未發測試通知或誤報送達：$w4m_out"; fi

w4m_out="$(w4m_run prompt "{\"session_id\":\"session-b\",\"prompt\":\"\$wait4me status\"}" "$w4m_probe_capture")"
if jq -e '.hookSpecificOutput.additionalContext | contains("status=disabled")' \
    <<< "$w4m_out" >/dev/null 2>&1; then
    ok "另一個 session 維持 disabled"
else bad "wait4me state 洩漏到另一個 session：$w4m_out"; fi
if jq -e '.hookSpecificOutput.additionalContext | contains("probe=not-sent")' <<< "$w4m_out" >/dev/null 2>&1 \
    && [ "$(wc -l < "$w4m_probe_capture" | tr -d ' ')" -eq 1 ]; then
    ok "off 的 status 回報狀態且不發測試通知"
else bad "off 的 status 誤發通知或未回報 probe 狀態：$w4m_out"; fi

w4m_out="$(w4m_run prompt "{\"session_id\":\"session-a\",\"prompt\":\"\$wait4me status\"}" "$w4m_probe_capture")"
if jq -e '.hookSpecificOutput.additionalContext | contains("status=enabled") and contains("probe=accepted")' <<< "$w4m_out" >/dev/null 2>&1 \
    && [ "$(wc -l < "$w4m_probe_capture" | tr -d ' ')" -eq 2 ]; then
    ok "on 的 status 回報狀態且發一則測試通知"
else bad "on 的 status 未完成通知測試：$w4m_out"; fi

w4m_out="$(WAIT4ME_TEST_ERROR=1 w4m_run prompt "{\"session_id\":\"session-a\",\"prompt\":\"\$wait4me status\"}" "" 2>/dev/null)"
if jq -e '.hookSpecificOutput.additionalContext | contains("status=enabled") and contains("probe=failed") and contains("kind=RuntimeError")' <<< "$w4m_out" >/dev/null 2>&1 \
    && [ "$(wc -l < "$w4m_probe_capture" | tr -d ' ')" -eq 2 ]; then
    ok "通知失敗時 status 仍為 on，但不假報送達"
else bad "status 未區分開關與通知送達：$w4m_out"; fi

w4m_out="$(w4m_run prompt '{"session_id":"session-a","prompt":"continue"}')"
if jq -e '.hookSpecificOutput.additionalContext | contains("<!-- wait4me: concise reason -->")' \
    <<< "$w4m_out" >/dev/null 2>&1; then
    ok "enabled session 每回合取得 deterministic wait marker contract"
else bad "enabled session 未取得 wait marker contract：$w4m_out"; fi

w4m_run stop '{"session_id":"session-a","turn_id":"done-1","cwd":"/work/kapi-infra","last_assistant_message":"工作完成。"}' >/dev/null
if [ ! -e "$w4m_capture" ]; then
    ok "普通完成的 Stop 不通知"
else bad "普通完成被誤判為等待回應"; fi
w4m_first_diag=("$w4m_state"/*/last-stop)
if [ "${#w4m_first_diag[@]}" -eq 1 ] && [ -f "${w4m_first_diag[0]}" ] \
    && grep -q '^stage=marker-absent rc=0 kind=none$' "${w4m_first_diag[0]}"; then
    ok "普通完成留下去敏 marker-absent 診斷"
else bad "普通完成無法與 sender 未執行區分"; fi

w4m_wait='{"session_id":"session-a","turn_id":"wait-1","cwd":"/work/kapi-infra","last_assistant_message":"需要你的選擇。 <!-- wait4me: 選擇要接續的 durable steward -->"}'
w4m_run stop "$w4m_wait" >/dev/null
assert_eq "blocking Stop 發出一則通知" 1 "$(wc -l < "$w4m_capture" | tr -d ' ')"
w4m_run stop "$w4m_wait" >/dev/null
assert_eq "相同 blocking Stop 去重" 1 "$(wc -l < "$w4m_capture" | tr -d ' ')"

w4m_permission='{"session_id":"session-a","tool_use_id":"approval-1","tool_name":"Bash","cwd":"/work/kapi-infra","tool_input":{"command":"rm -rf TOP-SECRET-COMMAND"}}'
w4m_run permission "$w4m_permission" >/dev/null
assert_eq "PermissionRequest 發出一則獨立通知" 2 "$(wc -l < "$w4m_capture" | tr -d ' ')"
w4m_run permission "$w4m_permission" >/dev/null
assert_eq "相同 PermissionRequest 去重" 2 "$(wc -l < "$w4m_capture" | tr -d ' ')"
if ! grep -qF 'TOP-SECRET-COMMAND' "$w4m_capture" \
    && jq -s -e 'all(.[]; (.task == "agent-response-needed") and (.level == "info") and ((.message | length) <= 200) and (.message | contains("\n") | not))' \
        "$w4m_capture" >/dev/null 2>&1; then
    ok "notification payload 有界且不含 raw tool input"
else bad "notification payload 洩漏 raw input 或違反 message contract"; fi

w4m_run session-start '{"session_id":"session-a","source":"compact"}' >/dev/null
w4m_out="$(w4m_run prompt "{\"session_id\":\"session-a\",\"prompt\":\"\$wait4me status\"}" "$w4m_probe_capture")"
if grep -q 'status=enabled' <<< "$w4m_out"; then ok "compact 保留 switch"; else bad "compact 誤清 switch"; fi
w4m_run session-start '{"session_id":"session-a","source":"resume"}' >/dev/null
w4m_out="$(w4m_run prompt "{\"session_id\":\"session-a\",\"prompt\":\"\$wait4me status\"}" "$w4m_probe_capture")"
if grep -q 'status=disabled' <<< "$w4m_out"; then ok "resume 清除 switch"; else bad "resume 延續了舊授權"; fi
if [ ! -e "${w4m_first_diag[0]}" ]; then
    ok "session 清理會移除暫存 Stop 診斷"
else bad "session 清理遺留 Stop 診斷"; fi

w4m_run prompt "{\"session_id\":\"session-a\",\"prompt\":\"\$wait4me on\"}" "$w4m_probe_capture" >/dev/null
w4m_run prompt "{\"session_id\":\"session-a\",\"prompt\":\"\$wait4me off\"}" >/dev/null
w4m_out="$(w4m_run prompt "{\"session_id\":\"session-a\",\"prompt\":\"\$wait4me status\"}")"
if grep -q 'status=disabled' <<< "$w4m_out"; then ok "off 立即且幂等停用"; else bad "off 未停用"; fi

w4m_secret='wait4me-super-secret'
w4m_error="$(printf '%s\n' '{"message":"等待回應: fixture","level":"info","task":"agent-response-needed"}' \
    | NC_API_URL='https://invalid.example/secret-url' NC_API_KEY="$w4m_secret" WAIT4ME_TEST_ERROR=1 \
        "$W4M_SEND" 2>&1)"
assert_rc "sender transport failure回報hook內部non-success" 75 $?
if ! grep -qF "$w4m_secret" <<< "$w4m_error" \
    && ! grep -qF 'secret-url' <<< "$w4m_error" \
    && grep -q 'RuntimeError' <<< "$w4m_error"; then
    ok "transport warning bounded 且不回顯 secret／URL"
else bad "transport warning 洩漏敏感 transport 細節或缺少安全摘要：$w4m_error"; fi

python3 - "$W4M_SEND" <<'PY'
import errno
import importlib.util
import sys
import urllib.error

spec = importlib.util.spec_from_file_location("wait4me_send", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
assert module.failure_kind(OSError(errno.EHOSTUNREACH, "private detail")) == "network-unreachable"
assert module.failure_kind(ConnectionRefusedError(errno.ECONNREFUSED, "private detail")) == "connection-refused"
assert module.failure_kind(urllib.error.URLError(OSError(errno.EHOSTUNREACH, "private detail"))) == "network-unreachable"
assert module.failure_kind(urllib.error.URLError(ConnectionRefusedError(errno.ECONNREFUSED, "private detail"))) == "connection-refused"
assert module.failure_kind(urllib.error.HTTPError("private URL", 401, "private detail", None, None)) == "http-error"
assert module.failure_kind(RuntimeError("private detail")) == "RuntimeError"
PY
assert_rc "sender 把網路例外歸為不含細節的錯誤類別" 0 $?

w4m_protocol_error="$(printf '%s\n' '{"message":"wait4me protocol fixture","level":"info","task":"agent-response-needed"}' \
    | NC_API_URL='file:///private-fixture' NC_API_KEY='fixture-key' \
        WAIT4ME_TEST_CAPTURE="$w4m_fix/protocol-capture.jsonl" "$W4M_SEND" 2>&1)"
if [ "$?" -eq 75 ] && [ "$w4m_protocol_error" = 'wait4me: notification skipped (invalid-config)' ] \
    && [ ! -e "$w4m_fix/protocol-capture.jsonl" ]; then
    ok "sender 在傳輸前拒絕非 HTTP(S) 目的地"
else bad "sender 接受非 HTTP(S) 目的地"; fi

w4m_env_error="$(printf '%s\n' '{"message":"等待回應: fixture","level":"info","task":"agent-response-needed"}' \
    | env -u NC_API_URL -u NC_API_KEY WAIT4ME_ENV_FILE="$w4m_env_file" WAIT4ME_TEST_ERROR=1 \
        "$W4M_SEND" 2>&1)"
if grep -q 'RuntimeError' <<< "$w4m_env_error" \
    && ! grep -qF 'fixture-env-file-key' <<< "$w4m_env_error" \
    && ! grep -qF 'from-env-file' <<< "$w4m_env_error"; then
    ok "sender在hook未繼承環境時從明示env file載入NC設定"
else bad "sender未從明示env file載入NC設定或洩漏設定：$w4m_env_error"; fi

w4m_nc_server="$w4m_fix/fake-nc.py"
w4m_nc_port="$w4m_fix/fake-nc.port"
w4m_nc_request="$w4m_fix/fake-nc-request.json"
w4m_nc_stderr="$w4m_fix/fake-nc.stderr"
w4m_nc_boot="$w4m_fix/fake-nc.boot"
cat > "$w4m_nc_server" <<'PY'
import sys


port_path, request_path, action_taken, notification_status, boot_path = sys.argv[1:]


def mark(stage):
    with open(boot_path, "a", encoding="utf-8") as stream:
        stream.write(stage + "\n")


mark("interpreter-entered")
import json
import socketserver
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
mark("imports-complete")


if notification_status == "none":
    notification_status = None


class LoopbackHTTPServer(HTTPServer):
    def server_bind(self):
        # HTTPServer.server_bind() performs an unnecessary reverse-name lookup
        # after binding. The fixture only needs a loopback port and never reads
        # server_name, so keep the TCP bind while avoiding external DNS state.
        mark("before-tcp-bind")
        socketserver.TCPServer.server_bind(self)
        mark("after-tcp-bind")
        self.server_name = self.server_address[0]
        self.server_port = self.server_address[1]


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = json.loads(self.rfile.read(length))
        with open(request_path, "w", encoding="utf-8") as stream:
            json.dump(
                {
                    "path": self.path,
                    "x_api_key": self.headers.get("X-API-Key"),
                    "authorization": self.headers.get("Authorization"),
                    "body": body,
                },
                stream,
                ensure_ascii=False,
            )
        response = json.dumps(
            {
                "event_id": 1,
                "action_taken": action_taken,
                "matched_rule_id": 10,
                "notification_id": 2,
                "heartbeat_updated": False,
                "notification_status": notification_status,
                "notification_error": None,
            }
        ).encode()
        self.send_response(302 if action_taken == "redirect" else 401 if action_taken == "reject" else 201)
        if action_taken == "redirect":
            self.send_header("Location", f"http://127.0.0.1:{self.server.server_port}/redirect-target")
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response)))
        self.end_headers()
        if action_taken == "slow":
            try:
                for byte in response:
                    self.wfile.write(bytes([byte]))
                    self.wfile.flush()
                    time.sleep(0.1)
            except (BrokenPipeError, ConnectionResetError):
                pass
        else:
            self.wfile.write(response)

    def do_GET(self):
        with open(request_path, "w", encoding="utf-8") as stream:
            json.dump({"path": self.path, "x_api_key": self.headers.get("X-API-Key")}, stream)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'{}')

    def log_message(self, _format, *_args):
        pass


mark("before-bind")
server = LoopbackHTTPServer(("127.0.0.1", 0), Handler)
mark("after-bind")
server.timeout = 5
with open(port_path, "w", encoding="utf-8") as stream:
    stream.write(str(server.server_port))
mark("port-written")
server.handle_request()
if action_taken == "redirect":
    server.timeout = 1
    server.handle_request()
mark("request-complete")
PY
w4m_wait_nc_server() {
    # Keep readiness bounded and fail early if the child exits. Diagnostics below
    # distinguish scheduling/exec, import, bind, and port-file stages on timeout.
    for _ in {1..60}; do
        [ -s "$w4m_nc_port" ] && return 0
        kill -0 "$w4m_nc_pid" 2>/dev/null || return 1
        sleep 0.5
    done
    return 1
}
w4m_capture_nc_failure() {
    local w4m_nc_state w4m_nc_wait_rc w4m_nc_error w4m_nc_process w4m_nc_processes w4m_nc_markers
    if kill -0 "$w4m_nc_pid" 2>/dev/null; then
        w4m_nc_state="alive-after-readiness-timeout"
        w4m_nc_process="$(ps -o pid= -o ppid= -o state= -o time= -o wchan= -o command= \
            -p "$w4m_nc_pid" 2>&1 | tr '\n' ' ' | cut -c1-400)"
        w4m_nc_processes="$(ps -ax -o pid= 2>/dev/null | wc -l | tr -d ' ')"
        kill "$w4m_nc_pid" 2>/dev/null || true
    else
        w4m_nc_state="exited-before-ready"
        w4m_nc_process="<exited>"
        w4m_nc_processes="$(ps -ax -o pid= 2>/dev/null | wc -l | tr -d ' ')"
    fi
    wait "$w4m_nc_pid" 2>/dev/null
    w4m_nc_wait_rc=$?
    w4m_nc_error="$(sed -n '1p' "$w4m_nc_stderr" 2>/dev/null)"
    [ -n "$w4m_nc_error" ] || w4m_nc_error="<empty>"
    w4m_nc_markers="$(tr '\n' ',' < "$w4m_nc_boot" 2>/dev/null | cut -c1-300)"
    [ -n "$w4m_nc_markers" ] || w4m_nc_markers="<none>"
    w4m_nc_failure_detail="state=${w4m_nc_state}; wait_rc=${w4m_nc_wait_rc}; processes=${w4m_nc_processes}; process=${w4m_nc_process}; markers=${w4m_nc_markers}; stderr=${w4m_nc_error}"
}

rm -f "$w4m_nc_boot"
python3 "$w4m_nc_server" "$w4m_nc_port" "$w4m_nc_request" forward sent "$w4m_nc_boot" \
    2> "$w4m_nc_stderr" &
w4m_nc_pid=$!
if w4m_wait_nc_server; then
    w4m_nc_base="http://127.0.0.1:$(cat "$w4m_nc_port")"
    printf '%s\n' '{"message":"等待回應: fixture","level":"info","task":"agent-response-needed"}' \
        | NC_API_URL="$w4m_nc_base" NC_API_KEY='fixture-env-file-key' "$W4M_SEND" >/dev/null 2>&1
    w4m_nc_rc=$?
    wait "$w4m_nc_pid"
    assert_rc "sender接受NC Gateway已送達回覆" 0 "$w4m_nc_rc"
    if jq -e '
        .path == "/api/v1/events"
        and .x_api_key == "fixture-env-file-key"
        and .authorization == null
        and .body.event_type == "alert"
        and .body.source == "agent-wait4me"
        and .body.level == "info"
        and .body.message == "等待回應: fixture"
        and (.body.task == null)
    ' "$w4m_nc_request" >/dev/null 2>&1; then
        ok "sender將base URL、認證與bounded payload轉成NC Gateway wire contract"
    else
        bad "sender未遵守NC Gateway wire contract：$(cat "$w4m_nc_request" 2>/dev/null)"
    fi
else
    w4m_capture_nc_failure
    bad "fake NC server未就緒：${w4m_nc_failure_detail}"
fi

w4m_native_python="$w4m_fix/native-python"
mkdir -p "$w4m_native_python"
cat > "$w4m_native_python/sitecustomize.py" <<'PY'
import subprocess


def blocked_process(*args, **kwargs):
    raise RuntimeError("External transport denied by fixture")


subprocess.Popen = blocked_process
PY
rm -f "$w4m_nc_port" "$w4m_nc_request" "$w4m_nc_stderr" "$w4m_nc_boot"
python3 "$w4m_nc_server" "$w4m_nc_port" "$w4m_nc_request" forward sent "$w4m_nc_boot" \
    2> "$w4m_nc_stderr" &
w4m_nc_pid=$!
if w4m_wait_nc_server; then
    w4m_nc_base="http://127.0.0.1:$(cat "$w4m_nc_port")"
    printf '%s\n' '{"message":"wait4me native Python fixture","level":"info","task":"agent-response-needed"}' \
        | PYTHONPATH="$w4m_native_python" NC_API_URL="$w4m_nc_base" \
            NC_API_KEY='fixture"key\value' "$W4M_SEND" >/dev/null 2>&1
    w4m_nc_rc=$?
    wait "$w4m_nc_pid"
    if [ "$w4m_nc_rc" -eq 0 ] \
        && jq -e --arg key 'fixture"key\value' \
            '.x_api_key == $key and .body.message == "wait4me native Python fixture"' \
            "$w4m_nc_request" >/dev/null 2>&1; then
        ok "禁止外部程序時 sender 仍以原生 Python 完成 POST"
    else bad "sender 仍依賴外部傳輸程序"; fi
else
    w4m_capture_nc_failure
    bad "native Python fake NC server未就緒：${w4m_nc_failure_detail}"
fi

for w4m_nc_result in 'forward failed' 'drop none'; do
    rm -f "$w4m_nc_port" "$w4m_nc_request" "$w4m_nc_stderr" "$w4m_nc_boot"
    read -r w4m_nc_action w4m_nc_status <<< "$w4m_nc_result"
    python3 "$w4m_nc_server" "$w4m_nc_port" "$w4m_nc_request" \
        "$w4m_nc_action" "$w4m_nc_status" "$w4m_nc_boot" 2> "$w4m_nc_stderr" &
    w4m_nc_pid=$!
    if w4m_wait_nc_server; then
        w4m_nc_base="http://127.0.0.1:$(cat "$w4m_nc_port")"
        printf '%s\n' '{"message":"等待回應: fixture","level":"info","task":"agent-response-needed"}' \
            | NC_API_URL="$w4m_nc_base" NC_API_KEY='fixture-env-file-key' "$W4M_SEND" >/dev/null 2>&1
        w4m_nc_rc=$?
        wait "$w4m_nc_pid"
        assert_rc "sender拒絕未確認channel送達的Gateway回覆（${w4m_nc_result}）" 75 "$w4m_nc_rc"
    else
        w4m_capture_nc_failure
        bad "fake NC server未就緒（${w4m_nc_result}）：${w4m_nc_failure_detail}"
    fi
done

rm -f "$w4m_nc_port" "$w4m_nc_request" "$w4m_nc_stderr" "$w4m_nc_boot"
python3 "$w4m_nc_server" "$w4m_nc_port" "$w4m_nc_request" reject failed "$w4m_nc_boot" \
    2> "$w4m_nc_stderr" &
w4m_nc_pid=$!
if w4m_wait_nc_server; then
    w4m_nc_base="http://127.0.0.1:$(cat "$w4m_nc_port")"
    w4m_http_error="$(printf '%s\n' '{"message":"wait4me HTTP error fixture","level":"info","task":"agent-response-needed"}' \
        | NC_API_URL="$w4m_nc_base" NC_API_KEY='fixture-secret-for-redaction' \
            "$W4M_SEND" 2>&1)"
    w4m_http_rc=$?
    wait "$w4m_nc_pid"
    if [ "$w4m_http_rc" -eq 75 ] \
        && [ "$w4m_http_error" = 'wait4me: notification skipped (http-error)' ]; then
        ok "HTTP 錯誤只回傳去敏分類，不回顯金鑰或 URL"
    else bad "HTTP 錯誤診斷未正確去敏"; fi
else
    w4m_capture_nc_failure
    bad "HTTP error fake NC server未就緒：${w4m_nc_failure_detail}"
fi

for w4m_boundary in slow redirect; do
    rm -f "$w4m_nc_port" "$w4m_nc_request" "$w4m_nc_stderr" "$w4m_nc_boot"
    python3 "$w4m_nc_server" "$w4m_nc_port" "$w4m_nc_request" "$w4m_boundary" sent "$w4m_nc_boot" \
        2> "$w4m_nc_stderr" &
    w4m_nc_pid=$!
    if w4m_wait_nc_server; then
        w4m_nc_base="http://127.0.0.1:$(cat "$w4m_nc_port")"
        w4m_boundary_error="$(printf '%s\n' '{"message":"wait4me boundary fixture","level":"info","task":"agent-response-needed"}' \
            | NC_API_URL="$w4m_nc_base" NC_API_KEY='fixture-secret' "$W4M_SEND" 2>&1)"
        w4m_boundary_rc=$?
        wait "$w4m_nc_pid"
        if [ "$w4m_boundary" = slow ]; then w4m_expected_kind=timeout; else w4m_expected_kind=http-error; fi
        if [ "$w4m_boundary_rc" -eq 75 ] \
            && [ "$w4m_boundary_error" = "wait4me: notification skipped ($w4m_expected_kind)" ] \
            && jq -e '.path == "/api/v1/events"' "$w4m_nc_request" >/dev/null 2>&1; then
            ok "sender 保留傳輸邊界（${w4m_boundary}）：總時限或拒絕認證轉址"
        else bad "sender 傳輸邊界退步（${w4m_boundary}）"; fi
    else
        w4m_capture_nc_failure
        bad "boundary fake NC server未就緒（${w4m_boundary}）：${w4m_nc_failure_detail}"
    fi
done

w4m_retry_state="$w4m_fix/retry-state"
w4m_retry_capture="$w4m_fix/retry-capture.jsonl"
w4m_retry='{"session_id":"retry-session","turn_id":"retry-turn","cwd":"/work/kapi-infra","last_assistant_message":"需要你的選擇。 <!-- wait4me: 選擇後續處理方式 -->"}'
# shellcheck disable=SC2016 # `$wait4me` 是送給hook的literal command。
printf '%s\n' '{"session_id":"retry-session","prompt":"$wait4me on"}' \
    | WAIT4ME_STATE_ROOT="$w4m_retry_state" WAIT4ME_TEST_CAPTURE="$w4m_probe_capture" \
        WAIT4ME_ENV_FILE="$w4m_env_file" "$W4M_HOOK" prompt >/dev/null
printf '%s\n' "$w4m_retry" \
    | env -u NC_API_URL -u NC_API_KEY WAIT4ME_STATE_ROOT="$w4m_retry_state" \
        WAIT4ME_ENV_FILE="$w4m_env_file" WAIT4ME_TEST_ERROR=1 "$W4M_HOOK" stop >/dev/null
w4m_diag_files=("$w4m_retry_state"/*/last-stop)
if [ "${#w4m_diag_files[@]}" -eq 1 ] && [ -f "${w4m_diag_files[0]}" ] \
    && grep -q '^stage=send-failed rc=75 kind=RuntimeError$' "${w4m_diag_files[0]}" \
    && ! grep -qE 'fixture-env-file-key|from-env-file|選擇後續' "${w4m_diag_files[0]}"; then
    ok "Stop 失敗保留去敏階段、exit 與錯誤類別"
else bad "Stop 失敗沒有可查且不洩漏的診斷狀態"; fi
printf '%s\n' "$w4m_retry" \
    | env -u NC_API_URL -u NC_API_KEY WAIT4ME_STATE_ROOT="$w4m_retry_state" \
        WAIT4ME_ENV_FILE="$w4m_env_file" WAIT4ME_TEST_CAPTURE="$w4m_retry_capture" \
        "$W4M_HOOK" stop >/dev/null
if [ "${#w4m_diag_files[@]}" -eq 1 ] && [ -f "${w4m_diag_files[0]}" ] \
    && grep -q '^stage=delivered rc=0 kind=none$' "${w4m_diag_files[0]}"; then
    ok "後續成功送達更新診斷狀態"
else bad "送達成功未更新診斷狀態"; fi
if [ -f "$w4m_retry_capture" ]; then
    assert_eq "delivery失敗不會提前消耗同一事件的去重資格" 1 \
        "$(wc -l < "$w4m_retry_capture" | tr -d ' ')"
else
    bad "delivery失敗後相同事件無法重試"
fi

codex_wait4me_prompt="$(awk '
    /^\[\[hooks\.UserPromptSubmit\]\]$/ { capture = 1 }
    capture && /^\[/ && $0 !~ /^\[\[hooks\.UserPromptSubmit(\.hooks)?\]\]$/ { exit }
    capture { print }
' "$ROOT/codex/config.toml")"
# shellcheck disable=SC2016 # $HOME stays literal until the hook runtime expands it.
codex_wait4me_prompt_expected='[[hooks.UserPromptSubmit]]

[[hooks.UserPromptSubmit.hooks]]
type = "command"
command = '\''WAIT4ME_ENV_FILE="$HOME/Projects/krepo/.env" "$HOME"/.dotfiles/shared/skills/wait4me/scripts/wait4me-hook.sh prompt'\''
timeout = 5'
if jq -e \
    --arg prompt 'WAIT4ME_ENV_FILE="$HOME/Projects/krepo/.env" "$HOME"/.dotfiles/shared/skills/wait4me/scripts/wait4me-hook.sh prompt' \
    --arg permission 'WAIT4ME_ENV_FILE="$HOME/Projects/krepo/.env" "$HOME"/.dotfiles/shared/skills/wait4me/scripts/wait4me-hook.sh permission' \
    --arg stop 'WAIT4ME_ENV_FILE="$HOME/Projects/krepo/.env" "$HOME"/.dotfiles/shared/skills/wait4me/scripts/wait4me-hook.sh stop' \
    --arg end '"$HOME"/.dotfiles/shared/skills/wait4me/scripts/wait4me-hook.sh session-end' '
    ([.hooks.UserPromptSubmit[].hooks[] | select(.command == $prompt and .timeout == 5)] | length) == 1
    and ([.hooks.PermissionRequest[].hooks[] | select(.command == $permission and .async == true)] | length) == 1
    and ([.hooks.Stop[].hooks[] | select(.command == $stop and .async == true)] | length) == 1
    and ([.hooks.SessionEnd[].hooks[] | select(.command == $end)] | length) == 1
' "$ROOT/claude/settings.json" >/dev/null 2>&1 \
    && jq -e "$claude_subagent_quiet" "$ROOT/claude/settings.json" >/dev/null 2>&1 \
    && [ "$codex_wait4me_prompt" = "$codex_wait4me_prompt_expected" ] \
    && grep -q '^\[\[hooks\.UserPromptSubmit\]\]$' "$ROOT/codex/config.toml" \
    && grep -q '^\[\[hooks\.PermissionRequest\]\]$' "$ROOT/codex/config.toml" \
    && grep -q '^\[\[hooks\.SessionEnd\]\]$' "$ROOT/codex/config.toml" \
    && ! grep -q '^\[\[hooks\.SubagentStop\]\]$' "$ROOT/codex/config.toml"; then
    ok "Claude Code／Codex hooks 接線且不通知 SubagentStop"
else bad "wait4me runtime hooks wiring 缺失或誤接 SubagentStop"; fi
