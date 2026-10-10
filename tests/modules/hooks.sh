#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 24. .githooks/dispatcher（全域 core.hooksPath 的單一入口）"
# 為什麼是 dispatcher 而不是單一 pre-commit：全域 `core.hooksPath` **取代整個 hook 目錄**，
# 目錄裡沒有的 hook 名，repo 自己 `.git/hooks/` 的同名版本就靜默不執行（post-checkout／
# post-merge 正是 Git LFS 用的）。**「靜默」是本 repo 已知地雷的共同形狀。**
# ⚠️ 本節一律用 **local** `core.hooksPath` 指向 repo 內的 `.githooks`，不碰 `git/config`
# 也不碰全域設定——`~/.gitconfig` 已 include `git/config`，那個檔一存檔就影響本機所有 repo。
HOOKS_DIR="$ROOT/.githooks"
hk_git() { git -c user.email=t@t -c user.name=t "$@"; }
hk_repo() {   # $1=名稱 → bare origin + clone（有 origin/HEAD），local hooksPath 指向 .githooks
    git init --bare -q -b main "$TMP/$1.git"
    git clone -q "$TMP/$1.git" "$TMP/$1" 2>/dev/null
    ( cd "$TMP/$1" && echo seed > f.txt && hk_git add f.txt && hk_git commit -qm seed \
        && git push -q origin HEAD:main 2>/dev/null && git branch -q -M main
      git remote set-head origin main >/dev/null 2>&1
      git config core.hooksPath "$HOOKS_DIR" )
}

# --- 代理清單完整性：清單不由實作者挑 ---
# `.git/hooks/*.sample` 只有 14 個、**不是全集**——缺 post-commit／post-checkout／post-merge／
# post-rewrite／pre-auto-gc。未代理的（server-side receive 系列、Perforce p4-*）是刻意排除，
# **git 升版時要重新盤點**。
hk_missing=""
for h in applypatch-msg pre-applypatch post-applypatch pre-commit pre-merge-commit \
         prepare-commit-msg commit-msg post-commit pre-rebase post-checkout post-merge \
         pre-push post-rewrite pre-auto-gc post-index-change push-to-checkout \
         sendemail-validate fsmonitor-watchman; do
    if [ ! -L "$HOOKS_DIR/$h" ] || [ "$(readlink "$HOOKS_DIR/$h")" != "dispatcher" ]; then
        hk_missing="${hk_missing} ${h}"
    fi
done
if [ -z "$hk_missing" ]; then ok "18 個 client-side hook 名皆為指向 dispatcher 的 symlink"; else bad "代理清單缺漏或指錯：${hk_missing}"; fi
# 只有 dispatcher 是實體檔——新增第二個實體檔會漏掉四道 gate（它們只列 dispatcher）
hk_reg="$(find "$HOOKS_DIR" -type f -exec basename {} \; | sort | tr '\n' ' ')"
if [ "$hk_reg" = "dispatcher " ]; then ok ".githooks 目錄下只有 dispatcher 是實體檔（其餘皆 symlink）"; else bad "多了實體檔，四道 gate 掃不到：${hk_reg}"; fi
if [ -x "$HOOKS_DIR/dispatcher" ]; then ok "dispatcher 可執行"; else bad "dispatcher 缺執行位元——git 不執行也不報錯，防線靜默不存在"; fi
hk_mode="$(git -C "$ROOT" ls-files -s .githooks/dispatcher | awk '{print $1}')"
assert_eq "dispatcher 在 git 內是 100755" "100755" "${hk_mode:-none}"

# --- default branch 擋、feature 放行、逃生變數 ---
hk_repo hk1
out="$(cd "$TMP/hk1" && echo a >> f.txt && hk_git add f.txt && env -u DOTFILES_PRECOMMIT_OFF git -c user.email=t@t -c user.name=t commit -m t 2>&1)"
hk_rc=$?
if [ "$hk_rc" -ne 0 ]; then ok "default branch 上 commit 被擋"; else bad "default branch 未擋"; fi
if grep -q "branch-first.sh" <<< "$out"; then ok "訊息含可照抄的 branch-first.sh 路徑"; else bad "訊息缺 branch-first 指引"; fi
if grep -q -- "--no-verify" <<< "$out"; then ok "訊息明文封死 --no-verify（模型的第一反射）"; else bad "訊息未封 --no-verify"; fi
if (cd "$TMP/hk1" && DOTFILES_PRECOMMIT_OFF=1 hk_git commit -qm t2); then ok "逃生變數 → 放行（tests 與 eval 沙盒靠它）"; else bad "逃生變數無效——74 個 git fixture 會造不出來"; fi
if ( unset DOTFILES_PRECOMMIT_OFF; cd "$TMP/hk1" && git switch -qc feat/x && echo b >> f.txt && hk_git add f.txt && hk_git commit -qm t3 ); then ok "feature branch 不受影響"; else bad "feature branch 被誤擋"; fi

# --- chain：repo 自己的 hook 存活，exit code 原樣傳回 ---
# ⚠️ **exit code 要直接呼叫 dispatcher 驗**——`git commit` 對 hook 只看零/非零、自己回 1，
# 透過它量不到 42（2026-08-14 首版測試就是這樣誤判成實作壞掉）。
hk_repo hk2
mkdir -p "$TMP/hk2/.git/hooks"
printf '#!/bin/sh\nexit 42\n' > "$TMP/hk2/.git/hooks/pre-commit"; chmod 755 "$TMP/hk2/.git/hooks/pre-commit"
( cd "$TMP/hk2" && env -u DOTFILES_PRECOMMIT_OFF "$HOOKS_DIR/pre-commit" >/dev/null 2>&1 ); hk_rc=$?
assert_eq "repo pre-commit exit 42 → dispatcher 原樣傳回" "42" "$hk_rc"
( cd "$TMP/hk2" && DOTFILES_PRECOMMIT_OFF=1 "$HOOKS_DIR/pre-commit" >/dev/null 2>&1 ); hk_rc=$?
assert_eq "逃生變數存在時仍回 42（只停 guard、不跳過 repo hook）" "42" "$hk_rc"
printf '#!/bin/sh\necho REPO-CM >&2\nexit 0\n' > "$TMP/hk2/.git/hooks/commit-msg"; chmod 755 "$TMP/hk2/.git/hooks/commit-msg"
out="$(cd "$TMP/hk2" && "$HOOKS_DIR/commit-msg" /dev/null 2>&1)"
if grep -q "REPO-CM" <<< "$out"; then ok "非 pre-commit 的 hook 也 chain（commit-msg 存活）"; else bad "commit-msg 未被 chain——LFS 那類 hook 會靜默失效"; fi

# --- fail-open：guard 的依賴故意失敗 → 仍放行 ---
# 三態設計壞掉時會靜默變 fail-closed（擋掉 14 台上所有 commit，包括修這個 bug 的那顆）。
hk_repo hk3
mkdir -p "$TMP/hk3-stub"
printf '#!/bin/sh\nexit 3\n' > "$TMP/hk3-stub/git"; chmod 755 "$TMP/hk3-stub/git"
( cd "$TMP/hk3" && env -u DOTFILES_PRECOMMIT_OFF PATH="$TMP/hk3-stub:/usr/bin:/bin" "$HOOKS_DIR/pre-commit" >/dev/null 2>&1 ); hk_rc=$?
assert_eq "guard 依賴失敗（git 回非零）→ 放行，不是擋下" "0" "$hk_rc"

# --- 邊界：三個刻意保留的 false negative，各一條固定 ---
hk_repo hk4
if ( unset DOTFILES_PRECOMMIT_OFF; cd "$TMP/hk4" && git switch -q --detach HEAD && echo e >> f.txt && hk_git add f.txt && hk_git commit -qm t ); then ok "detached 不擋（會打到 rebase／bisect／CI shallow checkout）"; else bad "detached 被誤擋"; fi
git init -q -b main "$TMP/hk-local"
( cd "$TMP/hk-local" && git config core.hooksPath "$HOOKS_DIR" )
if ( unset DOTFILES_PRECOMMIT_OFF; cd "$TMP/hk-local" && echo x > a && hk_git add a && hk_git commit -qm t ); then ok "純本地 main（無 origin）不擋——明列的 false negative"; else bad "純本地 main 被擋，fixture 會造不出來"; fi
hk_repo hk5
( cd "$TMP/hk5" && git branch -q -m main trunk && git push -q origin trunk 2>/dev/null && git remote set-head origin -d >/dev/null 2>&1 && git fetch -q origin 2>/dev/null )
if ( unset DOTFILES_PRECOMMIT_OFF; cd "$TMP/hk5" && echo f >> f.txt && hk_git add f.txt && hk_git commit -qm t ); then ok "自訂 default（trunk，無 origin/HEAD）不擋——明列的 false negative"; else bad "trunk 被誤擋"; fi

# --- 進行中操作早退：查 --absolute-git-dir，不是 common-dir ---
hk_repo hk6
touch "$(cd "$TMP/hk6" && git rev-parse --absolute-git-dir)/MERGE_HEAD"
if ( unset DOTFILES_PRECOMMIT_OFF; cd "$TMP/hk6" && echo g >> f.txt && hk_git add f.txt && hk_git commit -qm t ); then ok "MERGE_HEAD 存在 → guard 早退（merge 收尾不被擋）"; else bad "merge 進行中被誤擋"; fi

# --- linked worktree：hooks 在 common-dir、操作狀態在 absolute-git-dir，兩者不可互換 ---
hk_repo hk7
mkdir -p "$TMP/hk7/.git/hooks"
printf '#!/bin/sh\necho WT-CHAIN >&2\nexit 0\n' > "$TMP/hk7/.git/hooks/pre-commit"; chmod 755 "$TMP/hk7/.git/hooks/pre-commit"
( cd "$TMP/hk7" && git worktree add -q --detach "$TMP/hk7-wt" HEAD 2>/dev/null )
out="$( unset DOTFILES_PRECOMMIT_OFF; cd "$TMP/hk7-wt" && "$HOOKS_DIR/pre-commit" 2>&1 )"
if grep -q "WT-CHAIN" <<< "$out"; then ok "worktree 內仍 chain 到 common-dir 的 repo hook"; else bad "worktree 內 chain 失效（common-dir 解析錯）"; fi
touch "$(cd "$TMP/hk7-wt" && git rev-parse --absolute-git-dir)/MERGE_HEAD"
( unset DOTFILES_PRECOMMIT_OFF; cd "$TMP/hk7-wt" && "$HOOKS_DIR/pre-commit" >/dev/null 2>&1 ); hk_rc=$?
assert_eq "worktree-specific 的 MERGE_HEAD 能停用 guard" "0" "$hk_rc"
( cd "$TMP/hk7" && git worktree remove --force "$TMP/hk7-wt" >/dev/null 2>&1 )


echo "▶ 26. outward-action gate（push／merge only）"
OUTWARD_GATE="$ROOT/scripts/outward-action-gate.py"
gate_classify() { python3 "$OUTWARD_GATE" --classify "$1" 2>/dev/null; }

python3 -B "$ROOT/tests/project-push-command-test.py" >"$TMP/project-push-command-test.out" 2>&1
project_push_rc=$?
assert_rc "Project published push 與 outward gate 組合／repo binding／lease controls" 0 "$project_push_rc"
if [ "$project_push_rc" -ne 0 ]; then cat "$TMP/project-push-command-test.out"; fi

assert_eq "direct git push → canonical push" "push canonical" "$(gate_classify 'git push origin feat/x')"
assert_eq "direct git send-pack → canonical push" "push canonical" "$(gate_classify 'git send-pack origin refs/heads/x')"
assert_eq "direct gh pr merge → canonical merge" "merge canonical" "$(gate_classify 'gh pr merge 176 --squash')"
assert_eq "bash -lc 內藏 push → opaque push" "push opaque" "$(gate_classify "bash -lc 'git push origin feat/x'")"
assert_eq "git -C push（rules 無法精確 match）→ opaque push" "push opaque" "$(gate_classify 'git -C /tmp/repo push origin feat/x')"
assert_eq "compound command 內含 push → opaque push" "push opaque" "$(gate_classify 'git status && git push origin feat/x')"
assert_eq "git push --dry-run → none" "none" "$(gate_classify 'git push --dry-run origin feat/x')"
assert_eq "git status → none" "none" "$(gate_classify 'git status --short')"
assert_eq "gh pr view → none" "none" "$(gate_classify 'gh pr view 176')"
assert_eq "echo 的資料不是命令 → none" "none" "$(gate_classify 'echo git push')"

gate_input='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push origin feat/x"}}'

# Project 的既有 behavior oracle（Scenario 13）把 `--merge` 定義成同輪 push + merge
# endpoint authorization，AskUserQuestion 呼叫數必須是 0。這裡補 runtime composition：
# 若 Claude settings 另掛一個不讀 invocation 的 outward hook，它會在兩個 Bash call 各發
# 一次 approval UI，單看 Project eval 或單看 hook classifier 都抓不到這個衝突。
claude_outward_hooks="$(jq '[
    .hooks.PreToolUse[]?
    | select(.matcher == "Bash")
    | .hooks[]?
    | select(.command | contains("outward-action-gate.py --runtime claude"))
] | length' "$ROOT/claude/settings.json")"
project_merge_approval_calls=0
for project_merge_command in \
    'git push -u origin feat/example' \
    'gh pr merge 176 --rebase --delete-branch'; do
    if [ "$(gate_classify "$project_merge_command")" != "none" ]; then
        project_merge_approval_calls=$((project_merge_approval_calls + claude_outward_hooks))
    fi
done
assert_eq "Claude /project --merge 的 push + merge approval UI 呼叫數為 0" \
    "0" "$project_merge_approval_calls"

out="$(printf '%s' "$gate_input" | python3 "$OUTWARD_GATE" --runtime codex 2>/dev/null)"; rc=$?
assert_rc "Codex canonical action 交由 rules → exit 0" 0 "$rc"
assert_eq "Codex canonical action hook 不重複 deny" "" "$out"

gate_opaque='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"bash -lc '\''git push origin feat/x'\''"}}'
out="$(printf '%s' "$gate_opaque" | python3 "$OUTWARD_GATE" --runtime codex 2>/dev/null)"; rc=$?
assert_rc "Codex opaque action hook → exit 0" 0 "$rc"
if jq -e '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny"' <<< "$out" >/dev/null 2>&1; then
    ok "Codex opaque action → deny 並要求 canonical rerun"
else
    bad "Codex opaque action 未回 deny"
fi

if jq -e '
    .permissions.defaultMode == "auto"
    and ([.hooks.PreToolUse[]?.hooks[]?.command? | select(contains("outward-action-gate.py"))] | length) == 0
' "$ROOT/claude/settings.json" >/dev/null; then
    ok "Claude 維持 Auto 且不另掛無 invocation context 的 outward gate"
else
    bad "Claude Auto 或 Project shipping 授權相容性不成立"
fi
if grep -q 'sandbox_mode = "danger-full-access"' "$ROOT/codex/config.toml" \
    && grep -q '^\[\[hooks\.PreToolUse\]\]$' "$ROOT/codex/config.toml"; then
    ok "Codex 維持 danger-full-access 並接上 PreToolUse gate"
else
    bad "Codex autonomy／PreToolUse gate contract 不成立"
fi

if jq -e '
    (.autoMode.allow | index("$defaults")) != null
    and any(.autoMode.allow[];
        contains("Documentation Governance Reads")
        and contains("scripts/doc-governance.py")
        and contains("find")
        and contains("record-path")
        and contains("report")
        and contains("audit")
        and contains("read-only")
        and contains("record-path` only computes and prints")
        and contains("no earlier Edit, Write, or Bash tool call"))
' "$ROOT/claude/settings.json" >/dev/null; then
    ok "Claude Auto 精確允許未被本輪修改的 doc-governance 唯讀子命令"
else
    bad "Claude Auto 缺少 bounded doc-governance read-only allow，或未保留 defaults／modified-script 邊界"
fi

if grep -q 'repo-specific contract text' "$ROOT/claude/CLAUDE.md" \
    && grep -q 'managed Kernel' "$ROOT/claude/CLAUDE.md" \
    && grep -q 'Edit.*Write' "$ROOT/claude/CLAUDE.md" \
    && grep -q 'Bash heredoc' "$ROOT/claude/CLAUDE.md"; then
    ok "Claude always-on 契約釘住 repo-specific 授權邊界與結構化編輯工具"
else
    bad "Claude always-on 契約缺少 repo-specific／Kernel 分界或 Edit/Write 規則"
fi
for rule in 'git", "push' 'git", "send-pack' 'gh", "pr", "merge'; do
    if grep -q 'decision="prompt"' <<< "$(grep -F "$rule" "$ROOT/codex/rules/default.rules")"; then
        ok "Codex canonical rule prompt: $rule"
    else
        bad "Codex canonical rule 未 prompt: $rule"
    fi
done

CLAUDE_DRIFT="$ROOT/scripts/check-claude-auto-mode-drift.sh"
mkdir -p "$TMP/claude-drift/bin"
cat > "$TMP/claude-drift/bin/claude" <<'DRIFTEOF'
#!/usr/bin/env bash
case "$1 $2" in
  'auto-mode defaults') printf '%s\n' '{"environment":["alpha: built in","beta: built in"]}' ;;
  'auto-mode config')
    if [ "${CLAUDE_DRIFT_FIXTURE:-same}" = drift ]; then
      printf '%s\n' '{"environment":["alpha: local","gamma: local"]}'
    else
      printf '%s\n' '{"environment":["alpha: built in","beta: built in"]}'
    fi
    ;;
  *) exit 1 ;;
esac
DRIFTEOF
chmod +x "$TMP/claude-drift/bin/claude"
out="$(PATH="$TMP/claude-drift/bin:$PATH" bash "$CLAUDE_DRIFT" 2>&1)"; rc=$?
assert_rc "Claude auto-mode slots 相同 → warn-only checker exit 0" 0 "$rc"
assert_eq "Claude auto-mode slots 相同 → 靜默" "" "$out"
out="$(CLAUDE_DRIFT_FIXTURE=drift PATH="$TMP/claude-drift/bin:$PATH" bash "$CLAUDE_DRIFT" 2>&1)"; rc=$?
assert_rc "Claude auto-mode slots 漂移 → checker 仍 exit 0" 0 "$rc"
if grep -q 'autoMode.environment' <<< "$out" && grep -q 'beta' <<< "$out" && grep -q 'gamma' <<< "$out"; then
    ok "Claude auto-mode 漂移提示列出本機缺少與多出的 slot"
else
    bad "Claude auto-mode 漂移提示缺少可操作差異"
fi
# 真實 slot 名帶 `**`／`###`，且 comm 的 collation 與 sort 不同時，舊版會把同名 slot
# 同時列進「missing」與「local-only」。fixture 必須用真實形狀才抓得到。
cat > "$TMP/claude-drift/bin/claude" <<'DRIFTEOF'
#!/usr/bin/env bash
case "$1 $2" in
  'auto-mode defaults')
    printf '%s\n' '{"environment":["**Organization**: built in","**Host containment**: built in","**Source control**: built in"]}' ;;
  'auto-mode config')
    printf '%s\n' '{"environment":["### Org-wide","**Organization**: local","**Source control**: local","### User-specific"]}' ;;
  *) exit 1 ;;
esac
DRIFTEOF
chmod +x "$TMP/claude-drift/bin/claude"
# pipefail 下 `locale -a | grep -q` 會因 SIGPIPE 讓整條 pipeline 非零，探測永遠 fallback
# 到 C、測試就測不到 bug。改 herestring（known-hazards 記載的解法）。
drift_collate=C
drift_locales="$(locale -a 2>/dev/null)"
drift_c_first="$(printf '%s\n' '### b' '**a**' | LC_ALL=C sort | head -1)"
for cand in zh_TW.UTF-8 en_US.UTF-8; do
    grep -qx "$cand" <<< "$drift_locales" || continue
    if [ "$drift_c_first" \
         != "$(printf '%s\n' '### b' '**a**' | LC_COLLATE="$cand" sort | head -1)" ]; then
        drift_collate="$cand"
        break
    fi
done
out="$(LC_COLLATE="$drift_collate" PATH="$TMP/claude-drift/bin/:$PATH" bash "$CLAUDE_DRIFT" 2>&1)"
if grep -q 'missing locally: \*\*Host containment\*\*' <<< "$out"; then
    ok "Claude auto-mode 漂移提示列出真正缺少的 slot（collate=${drift_collate}）"
else
    bad "Claude auto-mode 漂移提示漏掉真正缺少的 slot（collate=${drift_collate}）"
fi
for noise in '\*\*Organization\*\*' '\*\*Source control\*\*'; do
    if grep -q "$noise" <<< "$out"; then
        bad "Claude auto-mode 把兩邊都有的 slot 誤報成漂移（collate=${drift_collate}）: $noise"
    else
        ok "Claude auto-mode 未誤報兩邊都有的 slot: $noise"
    fi
done
if grep -q '###' <<< "$out"; then
    bad "Claude auto-mode 把章節標題誤報成 slot"
else
    ok "Claude auto-mode 忽略 environment 的章節標題"
fi

if grep -q 'check-claude-auto-mode-drift.sh' "$ROOT/scripts/brewup.sh"; then
    ok "brewup 在 Claude update 後執行 drift checker"
else
    bad "brewup 未接上 Claude auto-mode drift checker"
fi
