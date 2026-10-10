#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034,SC2153
    git init -q -b main "$TMP/gh-local"
    (cd "$TMP/gh-local" && echo x > a.txt && "${GITC[@]}" add a.txt && "${GITC[@]}" commit -qm init)

echo "▶ 9. ship-state.sh 偵測與 protection 判定"
BS_BASELINE_SCRIPT="$ROOT/claude/skills/project/scripts/bootstrap-baseline.sh"

# gh stub 三態：PROTECTED / OPEN(404 Branch not protected) / Not Found(身分分離)
make_gh_stub() {  # <path> <protection行為: protected|open|notfound>
    local mode="$2"
    cat > "$1" <<STUB
#!/usr/bin/env bash
case "\$*" in
    *nameWithOwner*) echo "acme/widget" ;;
    *viewerPermission*) echo "READ" ;;
    *"api repos/acme/widget --jq .default_branch"*) echo "main" ;;
    *"/protection"*)
        case "$mode" in
            protected) echo '{"required_status_checks":{}}'; exit 0 ;;
            open)      echo "gh: Branch not protected (HTTP 404)"; exit 1 ;;
            notfound)  echo "gh: Not Found (HTTP 404)"; exit 1 ;;
        esac ;;
    *"rules/branches"*) echo '[]' ;;
esac
STUB
    chmod +x "$1"
}
make_gh_stub "$TMP/gh-protected" protected
make_gh_stub "$TMP/gh-open" open
make_gh_stub "$TMP/gh-notfound" notfound

# bootstrap 專用 gh stub：default metadata 與 effective rules 分開控制，證明 shared
# 判準不依賴 org／ruleset／property 名稱。
make_bootstrap_gh_stub() {  # <path> <default> <rules-mode:none|required|required-exempt|creation|unreadable>
    local default="$2" rules_mode="$3"
    cat > "$1" <<STUB
#!/usr/bin/env bash
case "\$*" in
    *nameWithOwner*) echo "example/portable-repo" ;;
    *"api repos/example/portable-repo --jq .default_branch"*) echo "$default" ;;
    *"/protection"*) echo "gh: Branch not protected (HTTP 404)"; exit 1 ;;
    *"rules/branches"*)
        case "$rules_mode" in
            none) echo '[]' ;;
            required) echo '[{"type":"required_status_checks","ruleset_source_type":"Organization","ruleset_source":"example","parameters":{"do_not_enforce_on_create":false,"required_status_checks":[{"context":"portable-ci"}]}}]' ;;
            required-exempt) echo '[{"type":"required_status_checks","ruleset_source_type":"Repository","ruleset_source":"example/portable-repo","parameters":{"do_not_enforce_on_create":true,"required_status_checks":[{"context":"portable-ci"}]}}]' ;;
            creation) echo '[{"type":"creation","ruleset_source_type":"Organization","ruleset_source":"example"}]' ;;
            unreadable) echo 'gh: Resource not accessible (HTTP 403)' >&2; exit 1 ;;
        esac ;;
esac
STUB
    chmod +x "$1"
}
make_bootstrap_gh_stub "$TMP/gh-bs-trunk" trunk none
make_bootstrap_gh_stub "$TMP/gh-bs-required" main required
make_bootstrap_gh_stub "$TMP/gh-bs-required-exempt" main required-exempt
make_bootstrap_gh_stub "$TMP/gh-bs-creation" main creation
make_bootstrap_gh_stub "$TMP/gh-bs-unreadable" main unreadable

cat > "$TMP/gh-classic-required" <<'STUB'
#!/usr/bin/env bash
case "$*" in
    *nameWithOwner*) echo "example/classic-repo" ;;
    *"/protection"*) echo '{"required_status_checks":{"strict":true,"contexts":["classic-ci"],"checks":[{"context":"classic-ci","app_id":null}]}}' ;;
    *"rules/branches"*) echo '[]' ;;
esac
STUB
chmod +x "$TMP/gh-classic-required"

# fixture：bare origin + clone，feature branch 上 1 commit、tree clean
git init --bare -q -b main "$TMP/ss-origin.git"
git init -q -b main "$TMP/ss-work"
(cd "$TMP/ss-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ss-origin.git" && git push -qu origin main \
    && git switch -qc feat/x && echo v2 > f.txt && "${GITC[@]}" commit -qam "feat: x")

out="$(SHIP_STATE_GH="$TMP/gh-protected" "$SS_SCRIPT" "$TMP/ss-work")"
assert_rc "feature branch 偵測 → exit 0" 0 $?
if grep -q "protection: PROTECTED" <<< "$out"; then ok "stub protected → PROTECTED"; else bad "stub protected 未判 PROTECTED"; fi
if grep -q "ship-path: PR" <<< "$out"; then ok "PROTECTED → PR 路徑"; else bad "PROTECTED 未走 PR 路徑"; fi
if grep -q "files-vs-default: 1 檔" <<< "$out"; then ok "三點 diff 列出 branch 帶來的檔"; else bad "三點 diff 未列檔"; fi
if grep -q "branch-first: 已在 feature branch" <<< "$out"; then ok "feature branch → 免 branch-first"; else bad "feature branch 誤判 branch-first"; fi

out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ss-work")"
# 無保護仍預設 PR（`claude/skills/project/references/log-prepare.md`「Step 1：逐 repo 狀態 + 流程偵測（先於任何 commit）」）——腳本 verdict 是 model 照抄的東西，
# 印 DIRECT-PUSH 會與規則牴觸，等於誘導 agent 略過 PR（u3 eval 的 RED 即此形狀）
if grep -q "protection: OPEN" <<< "$out" && grep -q "ship-path: PR" <<< "$out" \
    && ! grep -q "ship-path: DIRECT-PUSH" <<< "$out"; then
    ok "stub open → OPEN 但 ship-path 仍為 PR（直推降為 escape hatch）"
else bad "stub open 判定錯誤"; fi
if grep -q "required-policy: none" <<< "$out"; then
    ok "無 effective required rules → required-policy none"
else bad "無 ruleset 未輸出 required-policy none（${out}）"; fi

out="$(SHIP_STATE_GH="$TMP/gh-bs-required" "$SS_SCRIPT" "$TMP/ss-work")"
if grep -q "required-policy: REQUIRED" <<< "$out" && grep -q "portable-ci" <<< "$out"; then
    ok "effective required context 以 provider-neutral evidence 輸出"
else bad "required context 未進 ship-state evidence（${out}）"; fi
out="$(SHIP_STATE_GH="$TMP/gh-classic-required" "$SS_SCRIPT" "$TMP/ss-work")"
if grep -q "required-policy: REQUIRED" <<< "$out" && grep -q "classic-ci" <<< "$out"; then
    ok "classic branch protection required context 併入 required-policy"
else bad "classic required context 被 ruleset-only 查詢漏掉（${out}）"; fi
out="$(SHIP_STATE_GH="$TMP/gh-bs-unreadable" "$SS_SCRIPT" "$TMP/ss-work")"
if grep -q "required-policy: UNKNOWN" <<< "$out"; then
    ok "required policy 403／不可見 → UNKNOWN"
else bad "required policy 不可見被冒充 none（${out}）"; fi

out="$(SHIP_STATE_GH="$TMP/gh-notfound" "$SS_SCRIPT" "$TMP/ss-work")"
if grep -q "protection: UNKNOWN" <<< "$out" && grep -q "treat as PROTECTED" <<< "$out" \
    && grep -q "viewerPermission=READ" <<< "$out" && grep -q "ship-path: PR" <<< "$out"; then
    ok "stub notfound → UNKNOWN=protected + 身分分離提示"
else bad "stub notfound 判定錯誤"; fi

# 站在 main + 未 commit 變更 → branch-first REQUIRED
(cd "$TMP/ss-work" && git switch -q main && echo dirty > new.txt)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ss-work")"
if grep -q "branch-first: REQUIRED" <<< "$out"; then ok "main + 髒 tree → branch-first REQUIRED"; else bad "未要求 branch-first"; fi

# 誤 commit 在本地 main → misplaced WARNING（情況 B）
(cd "$TMP/ss-work" && "${GITC[@]}" add new.txt && "${GITC[@]}" commit -qm "oops on main")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ss-work")"
if grep -q "misplaced: WARNING" <<< "$out"; then ok "誤 commit 在 main → misplaced WARNING"; else bad "misplaced 未偵測"; fi
if grep -q "branch-first-cmd: .*branch-first\.sh" <<< "$out"; then ok "misplaced → 附 branch-first.sh 呼叫指令供照抄"; else bad "misplaced 未附 branch-first-cmd"; fi

# 全乾淨 → changes NONE + docs-only 提醒；protection/ship-path/branch-first 仍須輸出
# （docs-only mode 隨後會產生 docs commit 走 Step 4/5，Step 1 取 verdict 不可缺）
git clone -q "$TMP/ss-origin.git" "$TMP/ss-clean"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ss-clean")"
assert_rc "乾淨 repo → exit 0" 0 $?
if grep -q "changes: NONE" <<< "$out" && grep -q "docs-only" <<< "$out"; then
    ok "乾淨 repo → changes NONE + docs-only 提醒"
else bad "乾淨 repo 輸出缺 docs-only 提醒"; fi
if grep -q "protection: OPEN" <<< "$out" && grep -q "ship-path:" <<< "$out" \
    && grep -q "branch-first: REQUIRED" <<< "$out"; then
    ok "乾淨 repo 仍印 protection/ship-path/branch-first（docs-only mode 需用）"
else bad "乾淨 repo 缺 protection/ship-path/branch-first（docs-only mode 取不到 verdict）"; fi

# local-only（無 remote）→ STOP
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/gh-local")"
if grep -q "remotes: NONE" <<< "$out"; then ok "無 remote → STOP 告知"; else bad "無 remote 未 STOP"; fi

"$SS_SCRIPT" "$TMP/not-a-repo" >/dev/null 2>&1
assert_rc "非 git repo → exit 1" 1 $?
"$SS_SCRIPT" >/dev/null 2>&1
assert_rc "無引數 → exit 2" 2 $?

# --- resolve 子指令（Step 0 repo-token 判定）---

ss_top="$(git -C "$TMP/ss-work" rev-parse --show-toplevel)"

out="$("$SS_SCRIPT" resolve "$TMP/ss-work")"
assert_rc "resolve repo 根（絕對路徑）→ exit 0" 0 $?
if grep -qF "resolve: REPO $ss_top" <<< "$out"; then ok "repo 根 → REPO + toplevel"; else bad "repo 根未判 REPO（${out}）"; fi

out="$( (cd "$TMP/ss-work" && "$SS_SCRIPT" resolve .) )"
if grep -qF "resolve: REPO $ss_top" <<< "$out"; then ok "'.' → REPO（pwd 所在 repo 根）"; else bad "'.' 未判 REPO（${out}）"; fi

mkdir -p "$TMP/ss-work/sub/dir"
out="$( (cd "$TMP/ss-work" && "$SS_SCRIPT" resolve sub/dir) )"
if grep -q "resolve: MODULE" <<< "$out"; then ok "repo 內子路徑 → MODULE（不鎖定）"; else bad "子路徑未判 MODULE（${out}）"; fi

# '.' 在 repo 子目錄下也必須指向所屬 repo 根（舊 SKILL.md 契約：`.` → pwd 所在的 git repo 根）
out="$( (cd "$TMP/ss-work/sub/dir" && "$SS_SCRIPT" resolve .) )"
if grep -qF "resolve: REPO $ss_top" <<< "$out"; then ok "子目錄下 '.' → REPO（舊契約語意）"; else bad "子目錄下 '.' 未判 REPO（${out}）"; fi

ln -s "$TMP/ss-work" "$TMP/ss-link"
out="$("$SS_SCRIPT" resolve "$TMP/ss-link")"
if grep -qF "resolve: REPO $ss_top" <<< "$out"; then ok "symlink 到 repo 根 → REPO（realpath 正規化）"; else bad "symlink 未判 REPO（${out}）"; fi

out="$( (cd "$TMP" && "$SS_SCRIPT" resolve ss-work) )"
if grep -qF "resolve: REPO $ss_top" <<< "$out"; then ok "相對路徑到 repo 根 → REPO"; else bad "相對路徑未判 REPO（${out}）"; fi

# CDPATH 誘餌：cd builtin 吃環境 CDPATH，相對 token 會被拐去別處 → 必須隔離
mkdir -p "$TMP/cdpath-decoy/ss-work"
out="$( (cd "$TMP" && CDPATH="$TMP/cdpath-decoy" "$SS_SCRIPT" resolve ss-work) )"
if grep -qF "resolve: REPO $ss_top" <<< "$out"; then ok "CDPATH 誘餌下相對路徑仍判 REPO（cd 已隔離）"; else bad "CDPATH 干擾 resolve 判定（${out}）"; fi

out="$("$SS_SCRIPT" resolve "$TMP/no-such-token")"
assert_rc "resolve 不存在路徑 → exit 0（verdict 即成功）" 0 $?
if grep -q "resolve: UNKNOWN" <<< "$out"; then ok "不存在路徑 → UNKNOWN（交回 session 記憶比對）"; else bad "不存在路徑未判 UNKNOWN（${out}）"; fi

out="$("$SS_SCRIPT" resolve "$TMP")"
if grep -q "resolve: UNKNOWN" <<< "$out"; then ok "repo 外目錄 → UNKNOWN"; else bad "repo 外目錄未判 UNKNOWN（${out}）"; fi

"$SS_SCRIPT" resolve >/dev/null 2>&1
assert_rc "resolve 無 token → exit 2" 2 $?

# --- branch 與**自己的** remote tracking ref 分岔（只比對 default 會漏）---
# 缺口實據：2026-08-07 跑 eval 時，是受測 agent 自己去 `branch -vv` 才發現分岔——
# 腳本所有訊號都在講「對 default 領先多少」，push 那一刻才被 non-fast-forward 拒。
git init --bare -q -b main "$TMP/bd-origin.git"
git init -q -b main "$TMP/bd-work"
(cd "$TMP/bd-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/bd-origin.git" && git push -qu origin main)

out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bd-work")"
if ! grep -q '^branch-diverged:' <<< "$out"; then ok "在 default 上 → 不報 branch-diverged"; else bad "default 誤報分岔（${out}）"; fi

# feature branch 尚未 push → 無從分岔，必須靜默（噪音會讓訊號被學會忽略）
(cd "$TMP/bd-work" && git switch -qc feat/bd \
    && echo a > a.txt && "${GITC[@]}" add a.txt && "${GITC[@]}" commit -qm "feat: a")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bd-work")"
if ! grep -q '^branch-diverged:' <<< "$out"; then ok "未 push 過的 branch → 不報分岔"; else bad "未 push 的 branch 誤報分岔（${out}）"; fi

# push 之後單純領先（正常 ship 途中的常態）→ 仍須靜默
(cd "$TMP/bd-work" && git push -qu origin feat/bd \
    && echo b > b.txt && "${GITC[@]}" add b.txt && "${GITC[@]}" commit -qm "feat: b")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bd-work")"
if ! grep -q '^branch-diverged:' <<< "$out"; then ok "純領先 upstream → 不報分岔"; else bad "純領先誤報成分岔（${out}）"; fi

# 純落後：別台主機/另一個 session 推過，本地只是舊的（fetch 過但沒 merge）
git clone -q "$TMP/bd-origin.git" "$TMP/bd-other"
(cd "$TMP/bd-other" && git switch -q feat/bd \
    && echo c > c.txt && "${GITC[@]}" add c.txt && "${GITC[@]}" commit -qm "feat: c" \
    && git push -q origin feat/bd)
(cd "$TMP/bd-work" && git reset -q --hard origin/feat/bd && git fetch -q origin)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bd-work")"
if grep -q '^branch-diverged:' <<< "$out"; then ok "落後自己的 upstream → 報 branch-diverged"; else bad "落後 upstream 完全沒訊號（${out}）"; fi
if grep -qE '^branch-diverged: .*零領先' <<< "$out"; then ok "純落後與真分岔的措辭分開（處置不同）"; else bad "純落後被講成 push 會被拒（處置會被導錯）"; fi

# 真分岔：本地在落後狀態上又 commit → 互不為祖先，push 必被拒
(cd "$TMP/bd-work" && echo d > d.txt && "${GITC[@]}" add d.txt && "${GITC[@]}" commit -qm "feat: d")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bd-work")"
if grep -qE '^branch-diverged: .*已分岔' <<< "$out"; then ok "與 upstream 互不為祖先 → 報已分岔"; else bad "真分岔未被偵測（${out}）"; fi
if grep -q 'non-fast-forward' <<< "$out"; then ok "分岔訊號說明後果（push 會被拒）"; else bad "分岔訊號未說明後果"; fi
if grep -q 'force-with-lease' <<< "$out"; then ok "處置給 --force-with-lease（不給裸 --force）"; else bad "處置未指定 lease"; fi
# 負面斷言鎖「可照抄的裸指令形式」，不鎖字串 `--force` 本身——處置文案裡的「勿裸 --force」
# 是**警語**，把它一起判紅會逼人刪掉警語來過測試（第一版就誤中，正是這個形狀）
if grep -qE 'push +--force([^-]|$)' <<< "$out"; then bad "處置給出裸 push --force（照抄會蓋掉遠端別人的 commit）"; else ok "處置不含可照抄的裸 push --force"; fi

# 沒設 upstream 但已 push（`git push origin <b>` 不帶 -u，常態）→ 仍須以同名 tracking ref 受檢。
# 只認 @{upstream} 會讓這一整批 branch 完全不受檢，而它們正是最容易被別台主機推過的一批。
(cd "$TMP/bd-work" && git switch -qc feat/bd-noup \
    && echo e > e.txt && "${GITC[@]}" add e.txt && "${GITC[@]}" commit -qm "feat: e" \
    && git push -q origin feat/bd-noup)
if (cd "$TMP/bd-work" && git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1); then
    bad "fixture 前提失效：feat/bd-noup 竟有 upstream（fallback 分支測不到）"
else
    ok "fixture 前提成立：feat/bd-noup 無 upstream"
    (cd "$TMP/bd-work" && "${GITC[@]}" commit -q --amend -m "feat: e (rewritten)")
    out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bd-work")"
    if grep -qE '^branch-diverged: .*已分岔' <<< "$out"; then ok "無 upstream 者退用同名 tracking ref，分岔仍被偵測"; else bad "無 upstream 的已 push branch 不受檢（${out}）"; fi
fi

# --- 殘留 branch 衛生（已完全併入 default 的 local/remote branch）---
# merge 最後一哩只清它自己 merge 的那支，規則生效前的老 branch 會無聲累積
# （實證：dotfiles 累到 2 支才被偶然發現）。只印訊號 + 清掃指令，絕不代刪。

git init --bare -q -b main "$TMP/sb-origin.git"
git init -q -b main "$TMP/sb-work"
(cd "$TMP/sb-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/sb-origin.git" && git push -qu origin main)

# 乾淨（只有 main）→ 不得印 stale-branches（無殘留時保持安靜）
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/sb-work")"
if ! grep -q "stale-branches" <<< "$out"; then ok "無殘留 branch → 不印 stale-branches（不噪音）"; else bad "無殘留卻印 stale-branches（${out}）"; fi

# 造一支已完全併入 main 的 local + remote branch（模擬 merge 後沒清）
(cd "$TMP/sb-work" \
    && git switch -qc feat/old-merged && git push -qu origin feat/old-merged \
    && git switch -q main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/sb-work")"
if grep -q "stale-branches:" <<< "$out"; then ok "已併入 default 的殘留 branch → 印 stale-branches"; else bad "殘留 branch 未偵測（${out}）"; fi
if grep -q "feat/old-merged" <<< "$out"; then ok "stale-branches 列出 branch 名"; else bad "stale-branches 未列名"; fi
if grep -q "cleanup-cmd:" <<< "$out"; then ok "stale-branches 附清掃指令（供照抄，不代刪）"; else bad "stale-branches 缺 cleanup-cmd"; fi
if grep -q "fetch --prune" <<< "$out"; then ok "清掃指令前置 fetch --prune（防 remote-tracking 殘影誤刪）"; else bad "清掃指令未前置 fetch --prune"; fi

# --- dossier 章節完整性：整節被刪必須被抓到 ---
# 簽章只要求「任一」專屬章節在，尺寸 flag 只管上限——兩者都攔不住「刪掉整節」。
# 2026-08-06 實地踩過：兩整節被誤刪、行數反而變少、一路 merge 進 main 才發現。
mkdir -p "$TMP/ds-full"
cat > "$TMP/ds-full/STATUS.md" <<'DOSSIER'
# STATUS.md
專案一句話定位(更新日期:2026-08-06)

## 進行中
- 一個工作項

## 關鍵決策(附理由)
- 一條決策

## 死路(試過但放棄——防重工)
- 一條死路

## 技術債
- 一條技術債

## 已完成(里程碑)
- ✅ 一個里程碑

## 已知缺口
- 一條缺口

## 移交準備度
(暫無)
DOSSIER
# 需有 remote：無 remote 時 ship-state 在 verdict: STOP 就返回，dossier 檢查根本跑不到
# （前一版漏了這點，「七節齊全→不報」那條是假綠——輸出裡沒有該字串只是因為沒執行）
git init --bare -q -b main "$TMP/ds-full-origin.git"
(cd "$TMP/ds-full" && git init -q -b main . && "${GITC[@]}" add STATUS.md && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ds-full-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-full" 2>/dev/null)"
if grep -q "缺少規範章節" <<< "$out"; then bad "完整的 dossier 誤報缺章節"; else ok "七節齊全 → 不報缺章節"; fi

# 刪掉兩節（模擬邊界判斷吃掉尾段）→ 必須抓到
python3 - "$TMP/ds-full/STATUS.md" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
p.write_text(s[:s.index("## 已知缺口")])
PYEOF
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-full" 2>/dev/null)"
if grep -q "缺少規範章節" <<< "$out" && grep -q "已知缺口" <<< "$out" && grep -q "移交準備" <<< "$out"; then ok "整節被刪 → 印缺少規範章節並列出是哪幾節"; else bad "整節被刪未被抓到（尺寸 flag 抓不到、簽章也放行）"; fi

# --- backlog（docs/backlog.md）章節完整性 ---
# 分家後待辦落在這個檔，而它**刻意沒有尺寸 flag**（待辦壓不動，量體門檻對它無效——那正是
# 分家要消掉的東西）。代價是整節消失時沒有第二道訊號，比 2026-08-06 那個 dossier 事故更靜默，
# 所以這道章節檢查是本檔唯一的機械保障。
mkdir -p "$TMP/bl-full/docs"
cat > "$TMP/bl-full/STATUS.md" <<'DOSSIER'
# STATUS.md
專案一句話定位(更新日期:2026-08-15)

## 進行中
- 一個工作項

## 關鍵決策(附理由)
- 一條決策

## 死路(試過但放棄——防重工)
- 一條死路

## 技術債
> 條目已移至 docs/backlog.md

## 已完成(里程碑)
- ✅ 一個里程碑

## 已知缺口
> 條目已移至 docs/backlog.md

## 移交準備度
(暫無)
DOSSIER
cat > "$TMP/bl-full/docs/backlog.md" <<'BACKLOG'
# Backlog

## 技術債
- [ ] 一條債

## 已知缺口
- 一條缺口
BACKLOG
git init --bare -q -b main "$TMP/bl-full-origin.git"
(cd "$TMP/bl-full" && git init -q -b main . && "${GITC[@]}" add STATUS.md docs/backlog.md && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/bl-full-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bl-full" 2>/dev/null)"
if grep -q "backlog-flag:" <<< "$out"; then bad "完整的 backlog 誤報缺章節"; else ok "backlog 兩節齊全 → 不報 flag"; fi
# 分家後的 STATUS.md（兩節只剩指標）仍須通過 dossier 章節完整性——這是「保留標題」的用意，
# 未分家與已分家的 repo 走同一條檢查，工具面零分叉。
if grep -q "缺少規範章節" <<< "$out"; then bad "已分家的 STATUS.md（兩節留指標）被誤報缺章節"; else ok "分家後 STATUS.md 保留標題 → 章節檢查照常通過"; fi
# 未分家的 repo 必須完全看不到 backlog 訊號——零回填是這個設計能落地的前提
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-full" 2>/dev/null)"
if grep -q "backlog" <<< "$out"; then bad "無 docs/backlog.md 的 repo 仍印 backlog 訊號（未分家 repo 應零影響）"; else ok "無 docs/backlog.md → 零輸出（未分家 repo 零回填）"; fi
# 刪掉一節 → 必須抓到
python3 - "$TMP/bl-full/docs/backlog.md" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
p.write_text(s[:s.index("## 已知缺口")])
PYEOF
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bl-full" 2>/dev/null)"
if grep -q "backlog-flag:" <<< "$out" && grep -q "已知缺口" <<< "$out"; then ok "backlog 整節被刪 → 印 backlog-flag 並列出是哪一節"; else bad "backlog 整節被刪未被抓到（本檔無尺寸 flag，沒有第二道訊號）"; fi
# fenced 內的假標題不算章節：驗新消費者確實吃 strip_fences 的輸出。
# 「新增消費者忘了吃 unfenced」在 dossier 端已漏過一次（✅ 偵測），同一個洞不該在新檔重開。
python3 - "$TMP/bl-full/docs/backlog.md" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
p.write_text(p.read_text() + "\n```markdown\n## 已知缺口\n- 圍欄內的範例，不算章節\n```\n")
PYEOF
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bl-full" 2>/dev/null)"
if grep -q "backlog-flag:" <<< "$out"; then ok "fenced 內的假標題不算章節（backlog 走 strip_fences）"; else bad "圍欄內的範例標題被當成真章節 → 缺節誤放行"; fi

# --- dossier 條目上限：邊界須止於條目本身，不得吃進其後的獨立區塊 ---
# 實地（krepo-mops-major-news 2026-08-13）：一條 280B 的決策 ＋ 其後 524B 的**歸檔指標
# blockquote** 被算成同一條 804B，報超標 4 bytes。處置指引「涵蓋多個決策 → 拆成多條」
# 對它無效——它本來就是一條，於是只剩擰字或搬走指標兩條無效路。而那個 blockquote 正是
# 把建置期取捨歸檔後留下的指向：**做對了收斂動作，產物反而被判超標**。
# 條目邊界因此止於 blockquote / 標題 / 分隔線——三者都不是「續行」，原註解「以頂層
# `- ` bullet 為條目邊界、續行併入」講的也一直是這個意思，只是實作沒攔。
mkdir -p "$TMP/ds-entry"
python3 - "$TMP/ds-entry/STATUS.md" <<'PYEOF'
import sys, pathlib
head = "# STATUS.md\n專案一句話定位(更新日期:2026-08-13)\n\n## 進行中\n- 一個工作項\n\n"
# 決策本體遠低於上限；其後三種獨立區塊各自也不足以單獨超標，合計才越線
entry = "- **2026-08-12 一條決策**:" + "決" * 80 + "。\n"
quote = "> **已歸檔的建置期取捨在 `docs/archive/status-x.md`**:" + "史" * 180 + "。\n"
tail = ("\n## 死路(試過但放棄——防重工)\n- 一條死路\n\n## 技術債\n- 一條技術債\n\n"
        "## 已完成(里程碑)\n- ✅ 一個里程碑\n\n## 已知缺口\n- 一條缺口\n\n## 移交準備度\n(暫無)\n")
doc = head + "## 關鍵決策(附理由)\n" + entry + "\n" + quote + tail
pathlib.Path(sys.argv[1]).write_text(doc)
# 前提斷言：本體本身必須低於上限，合計必須高於——否則這個 fixture 測不到邊界
b_entry = len(entry.encode())
b_total = b_entry + 1 + len(quote.encode())
assert b_entry < 800 < b_total, f"fixture 失效: 本體 {b_entry} / 合計 {b_total}"
PYEOF
git init --bare -q -b main "$TMP/ds-entry-origin.git"
(cd "$TMP/ds-entry" && git init -q -b main . && "${GITC[@]}" add STATUS.md && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ds-entry-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-entry" 2>/dev/null)"
if grep -q "最大條目" <<< "$out"; then bad "條目後的 blockquote 被併入 → 假陽性超標（${out}）"; else ok "條目後的 blockquote 不併入條目（歸檔指標不再被判超標）"; fi

# 同一個邊界的另外兩面：標題與分隔線也不是續行
python3 - "$TMP/ds-entry/STATUS.md" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
p.write_text(s.replace("> **已歸檔的建置期取捨在 `docs/archive/status-x.md`**:",
                       "### 一個子標題\n\n說明文字:", 1))
PYEOF
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-entry" 2>/dev/null)"
if grep -q "最大條目" <<< "$out"; then bad "條目後的 ### 子標題被併入條目（${out}）"; else ok "條目後的 ### 子標題不併入條目"; fi

# 真超標仍須抓到——上面的邊界收窄不得把「條目本身確實過長」一起放掉
mkdir -p "$TMP/ds-entry-real"
python3 - "$TMP/ds-entry-real/STATUS.md" <<'PYEOF'
import sys, pathlib
entry = "- **2026-08-12 一條過長的決策**:" + "字" * 320 + "。\n"
doc = ("# STATUS.md\n專案一句話定位(更新日期:2026-08-13)\n\n## 進行中\n- 一個工作項\n\n"
       "## 關鍵決策(附理由)\n" + entry +
       "\n## 死路(試過但放棄——防重工)\n- 一條死路\n\n## 技術債\n- 一條技術債\n\n"
       "## 已完成(里程碑)\n- ✅ 一個里程碑\n\n## 已知缺口\n- 一條缺口\n\n## 移交準備度\n(暫無)\n")
pathlib.Path(sys.argv[1]).write_text(doc)
assert len(entry.encode()) > 800, "fixture 失效: 本體未超標"
PYEOF
git init --bare -q -b main "$TMP/ds-entry-real-origin.git"
(cd "$TMP/ds-entry-real" && git init -q -b main . && "${GITC[@]}" add STATUS.md && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ds-entry-real-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-entry-real" 2>/dev/null)"
if grep -q "最大條目" <<< "$out"; then ok "條目本身真超標 → 仍報（邊界收窄未放過真陽性）"; else bad "真超標未被抓到（收窄過頭）"; fi

# 條目 flag 須附建議收斂目標：全檔 flag 早有（DOSSIER_TARGET_PCT），條目漏了套用。
# 實測後果——壓到剛好低於上限，下次任何編輯即再觸發：2026-08-13 五個 repo 的最大條目
# 分別是 798 / 788 / 784 / 778 / 725（上限 800），聚在門檻下緣不是巧合。
if grep -qE "建議.*≤ [0-9]+ bytes" <<< "$out"; then ok "條目 flag 附建議收斂目標（不再壓到剛好過關）"; else bad "條目 flag 缺建議收斂目標（${out}）"; fi

# --- 全檔 flag 的收斂順序：歸檔必須排在蒸餾之前 ---
# `references/dossier.md` 早就寫了「超標時**優先歸檔**、不要為幾百 bytes 去壓無關舊條目」，
# 而 flag 文字寫的是「蒸餾＋歸檔」——**規範與工具訊息相反，且只有 flag 會被讀到**。
# 危險不對稱是這條的理由：歸檔只是搬家（留指標即可取回），蒸餾砍掉的是理由與實測數字，
# git history 找得回文字、找不回「當初為什麼認為這個數字重要」。把最不可逆的手段排在
# 訊息第一個，等於預設引導往最貴的方向走。
mkdir -p "$TMP/ds-order"
python3 - "$TMP/ds-order/STATUS.md" <<'PYEOF'
import sys, pathlib
doc = ("# STATUS.md\n專案一句話定位(更新日期:2026-08-14)\n\n## 進行中\n- 一個工作項\n"
       + "".join(f"- 第 {i} 條佔位敘述{'佔' * 18}。\n" for i in range(400))
       + "\n## 關鍵決策(附理由)\n- 一條決策\n\n## 死路(試過但放棄——防重工)\n- 一條死路\n\n"
         "## 技術債\n- 一條技術債\n\n## 已完成(里程碑)\n- ✅ 一個里程碑\n\n"
         "## 已知缺口\n- 一條缺口\n\n## 移交準備度\n(暫無)\n")
# 前提斷言必須在 write **之前**：assert 失敗時 python exit 1，但 tests/run.sh 是
# `set -uo pipefail`（無 -e）不會中止——寫在後面的話，檔案已經落地、測試照跑，
# 斷言形同虛設。2026-08-14 首版即踩到（60 條只有 12802 bytes，沒超標卻靜默跑完）。
assert len(doc.encode()) > 30720, f"fixture bytes 未超標: {len(doc.encode())}"
assert doc.count("\n") > 300, f"fixture 行數未超標: {doc.count(chr(10))}"
pathlib.Path(sys.argv[1]).write_text(doc)
PYEOF
git init --bare -q -b main "$TMP/ds-order-origin.git"
(cd "$TMP/ds-order" && git init -q -b main . && "${GITC[@]}" add STATUS.md && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ds-order-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-order" 2>/dev/null)"
order_line="$(grep 'bytes >' <<< "$out")"
if grep -q "最後才蒸餾" <<< "$order_line"; then ok "全檔 flag 帶收斂順序（蒸餾排最後）"; else bad "全檔 flag 缺收斂順序（${order_line}）"; fi
p_arch="$(awk '{print index($0, "歸檔")}' <<< "$order_line")"
p_dist="$(awk '{print index($0, "蒸餾")}' <<< "$order_line")"
if [ "$p_arch" -gt 0 ] && [ "$p_dist" -gt 0 ] && [ "$p_arch" -lt "$p_dist" ]; then ok "歸檔排在蒸餾之前（最不可逆的手段不排第一）"; else bad "收斂順序錯：歸檔@${p_arch} 蒸餾@${p_dist}"; fi
lines_line="$(grep '行 >' <<< "$out")"
if grep -q "最後才蒸餾" <<< "$lines_line"; then ok "行數 flag 同樣帶收斂順序（兩條 flag 不得各自演化）"; else bad "行數 flag 缺收斂順序（${lines_line}）"; fi

# --- 歸檔孤兒：docs/archive/ 裡沒有任何 md 連到的檔 ---
# 歸檔正是「內容還在 git 裡、但從 dossier 走不到」的主要製造途徑，而腳本自己的註解說
# 「內容遺失是 dossier 最貴的失效，靜默是最糟的形式」。dotfiles 的 xref-gate 只驗**正向**
# （指標指到的東西在不在），反向從來沒查過，且它只保護本 repo。
# 2026-08-14 實測：evint 6/10、krepo 9/29 是孤兒——而提出這條的 repo 自己是 0/8，
# 風險真實但在自己的 repo 裡看不見。
mkdir -p "$TMP/ds-orph/docs/archive"
cat > "$TMP/ds-orph/STATUS.md" <<'DOSSIER'
# STATUS.md
專案一句話定位(更新日期:2026-08-14)

## 進行中
- 一個工作項

## 關鍵決策(附理由)
- 較舊條目已歸檔至 `docs/archive/kept.md`。

## 死路(試過但放棄——防重工)
- 一條死路

## 技術債
- 一條技術債

## 已完成(里程碑)
- ✅ 一個里程碑

## 已知缺口
- 一條缺口

## 移交準備度
(暫無)
DOSSIER
printf '# 被連到的歸檔\n\n有指標指向本檔。\n' > "$TMP/ds-orph/docs/archive/kept.md"
printf '# 沒人連的歸檔\n\n從 dossier 走不到這裡。\n' > "$TMP/ds-orph/docs/archive/lost.md"
git init --bare -q -b main "$TMP/ds-orph-origin.git"
(cd "$TMP/ds-orph" && git init -q -b main . && "${GITC[@]}" add . && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ds-orph-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-orph" 2>/dev/null)"
if grep -q "歸檔孤兒" <<< "$out"; then ok "無人連到的歸檔 → 印孤兒訊號"; else bad "歸檔孤兒未偵測（${out}）"; fi
if grep -q "lost.md" <<< "$out"; then ok "孤兒訊號列出檔名（可直接處置）"; else bad "孤兒訊號未列檔名"; fi
orph_line="$(grep '歸檔孤兒' <<< "$out" || true)"
if grep -q "kept.md" <<< "$orph_line"; then bad "被連到的歸檔誤報為孤兒（假陽性）"; else ok "被連到的歸檔不誤報"; fi

# 補上指標 → 訊號消失（避免只驗到「恆印」）
python3 - "$TMP/ds-orph/STATUS.md" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
p.write_text(s.replace("- 一條死路", "- 一條死路(全文見 `docs/archive/lost.md`)", 1))
PYEOF
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-orph" 2>/dev/null)"
if grep -q "歸檔孤兒" <<< "$out"; then bad "補上指標後仍報孤兒（恆印，非偵測）"; else ok "補上指標 → 孤兒訊號消失"; fi

# 指標不含 "archive" 字樣時仍須認得——掃描 pattern 收太窄就會在這裡變成假陽性。
# 實地反例（evint，2026-08-14）：`> （`…2026-07-27-status-pre-condense.md`）` 整行
# 沒有 archive 字樣。假陽性比多掃幾行貴得多：它會叫人補一條本來就在的指標，
# 或更糟——以為那份歸檔可以刪。
python3 - "$TMP/ds-orph/STATUS.md" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace("(全文見 `docs/archive/lost.md`)", "(全文見 `…lost.md`)", 1)
assert "…lost.md" in s and "docs/archive/lost.md" not in s, "fixture 未改成省略號形式"
p.write_text(s)
PYEOF
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-orph" 2>/dev/null)"
if grep -q "歸檔孤兒" <<< "$out"; then bad "省略號形式的指標未被認出 → 假陽性（掃描 pattern 太窄）"; else ok "指標不含 archive 字樣也認得（pattern 以 .md 為準）"; fi

# archive 目錄不存在 → 靜默（多數 repo 沒有這個目錄，不得製造噪音）
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-full" 2>/dev/null)"
if grep -q "歸檔孤兒" <<< "$out"; then bad "無 docs/archive 卻印孤兒訊號"; else ok "無 docs/archive → 不印（不製造噪音）"; fi

# --- always-on 量體訊號（純資訊，不判 flag）---
# 為什麼要有：`claude/CLAUDE.md`(全域,每 session 載入) ＋ 各 repo 的 root `CLAUDE.md`／
# `AGENTS.md` 完全沒有任何大小 gate，而**不自動載入**的 STATUS.md 卻有五層治理——治理的
# 對象錯了。08-11 收斂後兩份 CLAUDE.md 已回漲 +2783 bytes 且無人看得住。
# **刻意背離** `dossier-sections:`「只在超標時印、平時是噪音」那條原則：本行是 baseline
# 觀測而非處置訊號，無條件印才看得到趨勢。升級成 flag 的前置條件是先解決「結構下限出口」
# （機隊 root CLAUDE.md 最大 102968、dotfiles 16993 排第十，貿然設 flag 會有七八個 repo 常亮）。
mkdir -p "$TMP/ds-ao"
printf '# Repo conventions\n\n用 uv,測試 uv run pytest。\n' > "$TMP/ds-ao/CLAUDE.md"
printf '# Agent contract\n\nkernel 見下。\n' > "$TMP/ds-ao/AGENTS.md"
git init --bare -q -b main "$TMP/ds-ao-origin.git"
(cd "$TMP/ds-ao" && git init -q -b main . && "${GITC[@]}" add -A && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ds-ao-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-ao" 2>/dev/null)"
ao_line="$(grep '^always-on:' <<< "$out" || true)"
if [ -n "$ao_line" ]; then ok "有 CLAUDE.md／AGENTS.md → 印 always-on 訊號"; else bad "缺 always-on 訊號（${out}）"; fi
if grep -qE 'CLAUDE\.md [0-9]+' <<< "$ao_line" && grep -qE 'AGENTS\.md [0-9]+' <<< "$ao_line"; then ok "兩份檔的 bytes 都印出來"; else bad "bytes 未逐檔印出（${ao_line}）"; fi
# 不得是 flag——`dossier-flag:` 前綴會讓「乾淨 dossier → 無 flag」那條立刻紅
if grep -q "^dossier-flag: always-on" <<< "$out"; then bad "always-on 誤用 dossier-flag 前綴（它是純資訊）"; else ok "always-on 是純資訊、不是 flag"; fi

# 只存在其中一份 → 逐檔標示，不得整行消失或整行 NONE
rm -f "$TMP/ds-ao/AGENTS.md"
(cd "$TMP/ds-ao" && "${GITC[@]}" add -A && "${GITC[@]}" commit -qm "drop agents")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-ao" 2>/dev/null)"
ao_line="$(grep '^always-on:' <<< "$out" || true)"
if grep -qE 'CLAUDE\.md [0-9]+' <<< "$ao_line" && grep -q 'AGENTS.md NONE' <<< "$ao_line"; then ok "只有一份時逐檔標示（另一份 NONE）"; else bad "部分存在的標示不對（${ao_line}）"; fi

# 兩份都無 → 整體 NONE（用第 9 節既有的乾淨 fixture，它沒有 CLAUDE.md）
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-full" 2>/dev/null)"
if grep -q '^always-on: NONE' <<< "$out"; then ok "兩份都無 → always-on: NONE"; else bad "無檔時未印 NONE（$(grep '^always-on:' <<< "$out"))"; fi

# **無 remote 的 repo 也要印** —— check_repo 在無 remote 時提早 return，訊號放錯位置就會被吞掉。
# 這條是落點的守門：它紅了代表 always-on 被移到 early return 之後。
mkdir -p "$TMP/ds-ao-local"
printf '# Local only\n\n沒有 remote 的 repo。\n' > "$TMP/ds-ao-local/CLAUDE.md"
(cd "$TMP/ds-ao-local" && git init -q -b main . && "${GITC[@]}" add -A && "${GITC[@]}" commit -qm init)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-ao-local" 2>/dev/null)"
if grep -q '^always-on:' <<< "$out"; then ok "無 remote 的 repo 仍印 always-on（落點在 early return 之前）"; else bad "無 remote 時訊號被 early return 吞掉——落點錯"; fi
if grep -q '^verdict: STOP' <<< "$out"; then ok "無 remote 仍照常 verdict: STOP（未改變既有行為）"; else bad "無 remote 的 STOP 消失了"; fi

# --- review 痕跡偵測（Step 4 squash 選項的判定依據；prose 下沉）---
# 為何下沉：判「哪些 commit 算 review 迭代痕跡」需要 deep-review 的權威 subject 清單，
# model 憑印象比對會把使用者自己的 `fix: 修正某某` 當痕跡建議壓掉，而使用者一句「好」
# 就 force-push 了。reset 目標 hash 同理，不讓 model 湊。
git clone -q "$TMP/sb-origin.git" "$TMP/rr-work"   # 沿用 stale-branches 段的 origin（同段 fixture，baseline 明確）
(cd "$TMP/rr-work" && git switch -qc feat/rr \
    && echo r1 > r.txt && "${GITC[@]}" add r.txt && "${GITC[@]}" commit -qm "feat: 使用者的語意實作")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-work")"
if grep -q "^review-residue: none" <<< "$out"; then ok "無 review 痕跡 → review-residue: none"; else bad "無痕跡卻未印 none（${out}）"; fi

# 頂端連續段 → 可安全 reset（目標 = 第一顆語意 commit，不動它以下）
rr_feat="$(git -C "$TMP/rr-work" rev-parse HEAD)"
(cd "$TMP/rr-work" && echo r2 > r.txt && "${GITC[@]}" commit -qam "fix: address review findings" \
    && echo r3 > r.txt && "${GITC[@]}" commit -qam "fix: address external review findings")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-work")"
if grep -q "^review-residue: 2 顆" <<< "$out"; then ok "review-residue 計數正確"; else bad "review-residue 計數錯誤（${out}）"; fi
if grep -q "top-contiguous: 2 顆" <<< "$out"; then ok "頂端連續段顆數正確"; else bad "頂端連續段錯誤"; fi
if grep -qE "^  squash-cmd: git -C .* reset --soft ${rr_feat}( |\$)" <<< "$out"; then ok "squash-cmd 指向第一顆語意 commit（腳本解析，model 不湊 hash）"; else bad "squash-cmd 目標錯誤"; fi   # 路徑取 toplevel（realpath），只驗 hash；hash 後可接說明註解
if grep -q "buried:" <<< "$out"; then bad "無 buried 卻誤印"; else ok "無 buried 時不印該行"; fi

# 被非 review commit 隔開（Step 3 的 docs commit 壓在最上）→ reset --soft 壓不到，
# 須改印整支全壓指令，且明示會連語意 commit 一起收
(cd "$TMP/rr-work" && echo r4 > r.txt && "${GITC[@]}" commit -qam "docs: 同步 dossier")
rr_mb="$(git -C "$TMP/rr-work" merge-base origin/main HEAD)"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-work")"
if grep -q "top-contiguous:" <<< "$out"; then bad "頂端非 review commit 卻報 top-contiguous"; else ok "頂端被隔開 → 不報可安全壓的連續段"; fi
if grep -q "buried: 2 顆" <<< "$out"; then ok "被隔開的痕跡計為 buried"; else bad "buried 計數錯誤（${out}）"; fi
if grep -qE "^  squash-all-cmd: git -C .* reset --soft ${rr_mb} " <<< "$out"; then ok "buried 時改印整支全壓指令"; else bad "缺 squash-all-cmd"; fi
if grep -q "會連語意 commit 一起收" <<< "$out"; then ok "全壓指令附後果警語"; else bad "全壓指令缺警語"; fi

# --- 跨 Step 時序：Step 1 的 hash 是「使用者語意 commit 的邊界」，Step 3 之後不得重算 ---
# 2026-08-06 一次真實回歸的重現：曾把規則改成「套用當下重跑」，但 Step 3 的 docs commit 會讓
# 頂端連續段恆為 0、verdict 從 top-contiguous 翻成 buried，現場只剩會壓掉語意 commit 的全壓
# 指令——使用者勾的處置沒有對應指令可執行。連兩輪 review 沒被測試擋住，故在此釘死。
git clone -q "$TMP/sb-origin.git" "$TMP/rr-time"
(cd "$TMP/rr-time" && git switch -qc feat/t \
    && echo t1 > t.txt && "${GITC[@]}" add t.txt && "${GITC[@]}" commit -qm "feat: 使用者的語意實作" \
    && echo t2 > t.txt && "${GITC[@]}" commit -qam "fix: address review findings" \
    && echo t3 > t.txt && "${GITC[@]}" commit -qam "fix: address review findings")
rr_t_feat="$(git -C "$TMP/rr-time" rev-parse HEAD~2)"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-time")"       # 模擬 Step 1
rr_t_hash="$(grep -oE "reset --soft [0-9a-f]{40}" <<< "$out" | head -1 | awk '{print $3}')"
if [ "$rr_t_hash" = "$rr_t_feat" ]; then ok "Step 1 的 squash-cmd 指向使用者語意 commit（邊界）"; else bad "Step 1 hash 未指向語意 commit"; fi

(cd "$TMP/rr-time" && echo t4 > t.txt && "${GITC[@]}" commit -qam "docs: 同步 dossier")   # 模擬 Step 3
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-time")"
if grep -q "top-contiguous:" <<< "$out"; then bad "Step 3 後仍報 top-contiguous（測試前提失效，重看 detect_review_residue）"; else ok "Step 3 後 top-contiguous 消失——這就是不得重算的理由"; fi
if grep -q "buried: 2 顆" <<< "$out"; then ok "Step 3 後形狀翻轉為 buried（重算只會剩全壓指令）"; else bad "buried 未如預期出現"; fi

(cd "$TMP/rr-time" && git reset --soft "$rr_t_hash")                     # 模擬 Step 4 用 Step 1 的 hash
if [ "$(git -C "$TMP/rr-time" rev-parse HEAD)" = "$rr_t_feat" ]; then ok "用 Step 1 的 hash reset → 停在使用者語意 commit"; else bad "reset 目標錯誤"; fi
if [ "$(git -C "$TMP/rr-time" rev-list --count origin/main..HEAD)" = "1" ]; then ok "語意 commit 保留、其上全部收攏"; else bad "語意 commit 未保留"; fi
if [ -n "$(git -C "$TMP/rr-time" diff --cached --name-only)" ]; then ok "review 痕跡 + 本輪 docs 進 index（內容零損失）"; else bad "index 為空（內容遺失）"; fi

# --- top-contiguous 與 buried 同時出現：SKILL 為此專列一行處置，須有守門 ---
git clone -q "$TMP/sb-origin.git" "$TMP/rr-both"
(cd "$TMP/rr-both" && git switch -qc feat/b2 \
    && echo b1 > b.txt && "${GITC[@]}" add b.txt && "${GITC[@]}" commit -qm "feat: 第一段語意" \
    && echo b2 > b.txt && "${GITC[@]}" commit -qam "fix: address review findings" \
    && echo b3 > b.txt && "${GITC[@]}" commit -qam "feat: 第二段語意" \
    && echo b4 > b.txt && "${GITC[@]}" commit -qam "fix: address review findings" \
    && echo b5 > b.txt && "${GITC[@]}" commit -qam "fix: address external review findings")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-both")"
if grep -q "^review-residue: 3 顆" <<< "$out"; then ok "混合情境總數正確"; else bad "混合情境總數錯誤"; fi
if grep -q "top-contiguous: 2 顆" <<< "$out" && grep -q "buried: 1 顆" <<< "$out"; then ok "混合情境兩組訊號並存"; else bad "混合情境訊號缺失（SKILL 有此列處置卻無守門）"; fi
if grep -qE "^  squash-cmd: " <<< "$out" && grep -qE "^  squash-all-cmd: " <<< "$out"; then ok "混合情境兩條指令都印（由使用者選，不由 agent 併）"; else bad "混合情境指令不全"; fi

# --- lib 缺席 → UNKNOWN 降級（不猜、不 set -u 爆炸）---
mkdir -p "$TMP/ss-nolib"
cp "$SS_SCRIPT" "$TMP/ss-nolib/ship-state.sh"      # 不複製 ../../deep-review/scripts/lib/
out="$(SHIP_STATE_GH="$TMP/gh-open" "$TMP/ss-nolib/ship-state.sh" "$TMP/rr-both" 2>&1)"
assert_rc "lib 缺席 → ship-state 照常完成（不因缺 pattern 而死）" 0 $?
if grep -q "^review-residue: UNKNOWN" <<< "$out"; then ok "lib 缺席 → review-residue 降級 UNKNOWN"; else bad "缺 UNKNOWN 降級（model 會被迫憑印象猜）"; fi
if grep -q "^protection:" <<< "$out"; then ok "lib 缺席不影響其餘偵測輸出"; else bad "lib 缺席拖垮了其他輸出"; fi

# --- review-terminal：上一場審查是「R5 終止」收場時，ship 前必須停 ---
# 為何存在：Step 4 改成「說法關鍵字即授權、不再逐批確認」後，原本那道確認 gate 會順帶
# 接住的「這批還沒審完」就沒人接了。拆掉守衛就得補上它接住的東西——這不是為沒見過的
# 問題加規則，是為新造出的暴露補償。
# 鑑別力來源是 ancestry：anchor 存在 .git/ 下、跨 branch 共用，只憑「有沒有 terminal_reason」
# 會讓一場舊終止把之後每一批都擋住。terminal_head 必須是當前 HEAD 的祖先才算涵蓋這批。
RA_FOR_SS="$ROOT/claude/skills/deep-review/scripts/review-anchor.sh"
git clone -q "$TMP/sb-origin.git" "$TMP/rt-work"
(cd "$TMP/rt-work" && git switch -qc feat/rt \
    && echo t1 > t.txt && "${GITC[@]}" add t.txt && "${GITC[@]}" commit -qm "feat: 待審的實作")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rt-work")"
if grep -q "^review-terminal:" <<< "$out"; then bad "無 anchor 卻報 review-terminal（會把每一批都擋住）"; else ok "無 anchor → 不印 review-terminal"; fi

# 正常審查中（record 過但未終止）→ 不得誤報：那是進行中，不是終止收場
"$RA_FOR_SS" record --repo "$TMP/rt-work" --mode branch-diff --base origin/main >/dev/null
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rt-work")"
if grep -q "^review-terminal:" <<< "$out"; then bad "anchor 存在但未終止卻報 review-terminal"; else ok "anchor 存在但無 terminal_reason → 不報"; fi

# R5 終止 → 必須印訊號且壓成 STOP（走真腳本寫入，順帶守住兩支腳本間的 anchor 格式漂移）
"$RA_FOR_SS" terminate --repo "$TMP/rt-work" --reason r5-blocking >/dev/null
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rt-work")"
if grep -q "^review-terminal: r5-blocking" <<< "$out"; then ok "terminal 且為祖先 → 印 review-terminal"; else bad "R5 終止未被偵測（未審完的變更會被關鍵字一路送出）"; fi
if grep -q "^verdict: STOP" <<< "$out"; then ok "review-terminal 壓成 verdict: STOP"; else bad "缺 STOP——說法關鍵字會直接覆蓋掉這道攔截"; fi
if grep -q "^ship-path:" <<< "$out"; then ok "STOP 之外的偵測輸出照常保留"; else bad "review-terminal 早退吃掉了其餘輸出"; fi

# 換到另一條由 default 長出的 branch → terminal_head 非祖先 → 那場終止與這批無關，須靜默
(cd "$TMP/rt-work" && git switch -q main && git switch -qc feat/rt-other \
    && echo o1 > o.txt && "${GITC[@]}" add o.txt && "${GITC[@]}" commit -qm "feat: 另一批工作")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rt-work")"
if grep -q "^review-terminal:" <<< "$out"; then bad "非祖先的舊終止仍攔截（每批都會被擋，訊號會被學會忽略）"; else ok "terminal_head 非祖先 → 不攔（那是別批的事）"; fi

# terminal_head 指向已不存在的物件（歷史被重建/gc）→ 無法鑑別，一律 fail-safe 報出來
(cd "$TMP/rt-work" && git switch -q feat/rt)
python3 - "$TMP/rt-work/.git/deep-review/anchor" <<'PYEOF'
import sys, pathlib, re
p = pathlib.Path(sys.argv[1]); s = p.read_text()
assert "terminal_head=" in s, "fixture 前提失效：anchor 無 terminal_head"
p.write_text(re.sub(r"^terminal_head=.*$", "terminal_head=" + "0" * 40, s, flags=re.M))
PYEOF
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rt-work")"
if grep -q "^review-terminal:" <<< "$out"; then ok "terminal_head 物件不存在 → fail-safe 仍報"; else bad "物件不存在時靜默放行（fail-open）"; fi

# origin/HEAD 存在時（真實 clone 的常態）：其 short form 是**裸 remote 名**（"origin"），
# 不是 branch——列進去會污染清單並讓 cleanup-cmd 拼出 `--deleteorigin`（實地跑真 repo 才
# 抓到，原 fixture 無 origin/HEAD 故漏測）
(cd "$TMP/sb-work" && git remote set-head origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/sb-work")"
if ! grep -qE "^  remote: origin$" <<< "$out"; then ok "origin/HEAD 不被當成殘留 branch"; else bad "裸 remote 名混入殘留清單（${out}）"; fi
# remote 側的刪除**一律走 cleanup-stale-branch.sh**（執行當下 ls-remote 重驗 + lease），
# **絕不退化成裸 `push --delete`**：local 側有 git 自己把關（`-d` 對未併入的 branch 直接拒），
# remote 側沒有等價保護——偵測後有人推過，裸刪就把那些 commit 從唯一的副本上砍掉。
if grep -qE "^  cleanup-cmd: .*cleanup-stale-branch\.sh'? .+ remote " <<< "$out"; then ok "remote 殘留附 cleanup-stale-branch.sh（帶執行當下重驗）"; else bad "remote 殘留缺帶重驗的刪除指令（${out}）"; fi
if grep -qE "push .*--delete" <<< "$out"; then bad "remote 刪除退回裸 push --delete（無 lease、無執行當下重驗）"; else ok "cleanup-cmd 不含裸 push --delete"; fi
if grep -qF "remote 'origin/" <<< "$out"; then bad "cleanup-cmd 的 remote branch 名未剝 remote 前綴"; else ok "cleanup-cmd 剝除 remote 前綴"; fi
# expected SHA 必須是該 tracking ref 的當下 tip。給錯就一律 STOP——指令看起來還在、實際上
# 每次照抄都被擋，等於訊號默默廢掉（且失敗長相像「有人推過」，會誤導去查不存在的第二寫入者）
sb_exp="$(git -C "$TMP/sb-work" rev-parse refs/remotes/origin/feat/old-merged)"
if grep -qE "^  cleanup-cmd: .*remote 'feat/old-merged' ${sb_exp}\$" <<< "$out"; then ok "cleanup-cmd 帶正確的 expected SHA（＝tracking ref 當下 tip）"; else bad "cleanup-cmd 的 expected SHA 不符 tracking ref tip（照抄必被 STOP）"; fi

# 未併入 default 的 branch（有獨立 commit）→ 不得列入（那是還沒 ship 的工作）
(cd "$TMP/sb-work" \
    && git switch -qc feat/in-progress && echo wip > w.txt \
    && "${GITC[@]}" add w.txt && "${GITC[@]}" commit -qm "feat: wip" \
    && git switch -q main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/sb-work")"
if ! grep -q "feat/in-progress" <<< "$out"; then ok "未併入 default 的 branch 不列入殘留（不誤報未 ship 的工作）"; else bad "誤把未 merge 的 branch 當殘留（${out}）"; fi

# 當前 branch 即使已併入 default 也不列入（不建議刪自己腳下那支）
(cd "$TMP/sb-work" && git switch -q feat/old-merged)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/sb-work")"
if ! grep -qE "^  local: .*feat/old-merged" <<< "$out"; then ok "當前 branch 不列入 local 殘留"; else bad "把當前 branch 列為可刪殘留（${out}）"; fi
(cd "$TMP/sb-work" && git switch -q main)

# 當前 branch 的 **remote 對應**同樣不得列入（2026-08-07 實地誤報：意外 push 了一條指向
# main tip 的同名 branch，腳本排除了 local 卻沒排除 origin/<當前 branch>，於是建議刪掉
# 「本次正要送出的那條」——照抄就會把自己的 branch 從遠端砍掉）
(cd "$TMP/sb-work" && git switch -q feat/old-merged)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/sb-work")"
if ! grep -qE "^  remote: origin/feat/old-merged" <<< "$out"; then ok "當前 branch 的 remote 對應不列入殘留"; else bad "把當前 branch 的 remote 對應列為可刪（照抄會砍掉正要送出的 branch）"; fi
(cd "$TMP/sb-work" && git switch -q main)

# 端到端：把 remote 的 cleanup-cmd **照抄執行**，遠端 branch 必須真的消失。
# 為何不只比對字串：上面驗的是「拼出來的樣子」，拼對了仍可能整條跑不動——參數順序、
# quoting、SHA 位置任一錯都是**靜默失敗**，腳本回 STOP，而 STOP 的長相與「偵測後有人推過」
# 這個正常保護一模一樣，讀不出是 bug。獨立 fixture（sbe- 前綴），不動上面共用的 sb-work。
# helper path 必須由正在執行的 ship-state.sh 自己解析；worktree／乾淨 clone 不得跳去全域安裝副本。
git init --bare -q -b main "$TMP/sbe-origin.git"
git init -q -b main "$TMP/sbe-work"
(cd "$TMP/sbe-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/sbe-origin.git" && git push -qu origin main \
    && git switch -qc feat/e2e-merged && git push -qu origin feat/e2e-merged \
    && git switch -q main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/sbe-work")"
sbe_cmd="$(grep -E "^  cleanup-cmd: .*cleanup-stale-branch\\.sh'? .+ remote " <<< "$out" | head -1 | sed 's/^  cleanup-cmd: //')"
if [ -n "$sbe_cmd" ]; then
    runtime_tilde='~'
    if grep -qF "$ROOT/claude/skills/project/scripts/cleanup-stale-branch.sh" <<< "$sbe_cmd" \
        && ! grep -qE "${runtime_tilde}/.+(claude|codex)/skills/project" <<< "$sbe_cmd"; then
        ok "cleanup-cmd 使用目前 checkout 的 runtime-neutral helper path"
    else
        bad "cleanup-cmd 綁到全域／runtime 專屬副本（${sbe_cmd}）"
    fi
    if bash -c "$sbe_cmd" >/dev/null 2>&1; then ok "照抄 remote cleanup-cmd 可實際刪除（路徑與參數端到端成立）"; else bad "照抄 remote cleanup-cmd 執行失敗（STOP／路徑／參數錯，訊號等於廢掉）"; fi
    if [ -n "$(git -C "$TMP/sbe-work" ls-remote --heads origin feat/e2e-merged 2>/dev/null)" ]; then bad "照抄後遠端 branch 仍在（指令實際沒生效）"; else ok "照抄後遠端殘留 branch 確實消失"; fi
else
    bad "未取得 remote 的 cleanup-cmd（fixture 前提失效）"
fi

# --- squash-merge 盲視（B1：只加訊號，不產生 -D 指令）---
# 為何存在：`git branch --merged` 判的是**祖先關係**，而 squash-merge 在 default 上產生
# 一顆全新 commit、與 branch 無祖先鏈——內容零損失卻永遠偵測不到。**本 repo 家規正是
# squash-merge**，等於這條訊號對主要情境完全無效；而既有 fixture 用「branch 不加 commit」
# （純祖先）才會綠，是「測試綠、功能無效」的教科書形狀。
# 判準取 `gh pr list` 的 merged PR：**headRefOid 必須等於本機 branch tip** 才算數——
# 同名 branch 事後又有新工作時 SHA 會不同，那些 commit 不在 default 上，列進去就是誘導刪掉。
make_gh_prlist_stub() {   # $1=路徑 $2=headRefOid $3=owner $4=額外 PR 筆數(湊 limit 用)
    cat > "$1" <<STUB
#!/usr/bin/env bash
case "\$*" in
    *nameWithOwner*) echo "acme/widget" ;;
    *viewerPermission*) echo "READ" ;;
    *"/protection"*) echo "gh: Branch not protected (HTTP 404)"; exit 1 ;;
    *"rules/branches"*) echo '[]' ;;
    *"pr list"*)
        printf '12\tfeat/squashed\t%s\t%s\n' "$2" "$3"
        i=0
        while [ "\$i" -lt "$4" ]; do
            printf '%d\tfiller-%d\tdeadbeef\tacme\n' "\$((100+i))" "\$i"
            i=\$((i+1))
        done ;;
esac
STUB
    chmod +x "$1"
}

# fixture：squash-merge 的真實形狀——branch 有自己的 commit，main 上是「內容相同但另一顆」
git init --bare -q -b main "$TMP/sq-origin.git"
git init -q -b main "$TMP/sq-work"
(cd "$TMP/sq-work" \
    && echo base > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/sq-origin.git" && git push -qu origin main \
    && git switch -qc feat/squashed && echo feature > f.txt && "${GITC[@]}" commit -qam "feat: 功能" \
    && git push -qu origin feat/squashed \
    && git switch -q main && echo feature > f.txt && "${GITC[@]}" commit -qam "feat: 功能 (#12)" \
    && git push -q origin main)
sq_tip="$(git -C "$TMP/sq-work" rev-parse feat/squashed)"

# 前提自檢：祖先判定看不到它（看得到就代表 fixture 沒造出 squash-merge 的形狀，後面全是假的）
if ! grep -qx 'feat/squashed' <<< "$(git -C "$TMP/sq-work" branch --merged origin/main --format='%(refname:short)')"; then
    ok "fixture 前提成立：squash-merge 後 branch --merged 看不到它（結構盲視）"
else bad "fixture 未造出 squash-merge 形狀（branch 仍是祖先，後續斷言全部失效）"; fi

make_gh_prlist_stub "$TMP/gh-sq" "$sq_tip" acme 0
out="$(SHIP_STATE_GH="$TMP/gh-sq" "$SS_SCRIPT" "$TMP/sq-work")"
if grep -q "^squash-merged-branches:" <<< "$out"; then ok "squash-merge 的殘留 branch 被偵測"; else bad "squash-merged branch 漏偵測（家規就是 squash-merge，等於訊號無效）"; fi
if grep -q "feat/squashed" <<< "$out"; then ok "列出 branch 名與 PR 編號"; else bad "未列出 squash-merged branch"; fi
if grep -qE "^  scan: complete" <<< "$out"; then ok "未達 limit → scan: complete"; else bad "缺 scan 狀態（達 limit 與否無從分辨）"; fi
if grep -q "cleanup-stale-branch.sh" <<< "$out"; then ok "清掃走專用腳本（執行當下重驗 SHA），不給裸 -D"; else bad "squash-merged 段給了裸刪除指令或無指令"; fi
if grep -qE "^  (local|remote): .*feat/squashed.* -[dD] " <<< "$out"; then bad "squash-merged 段出現裸 -D"; else ok "squash-merged 段不產生裸 -D 指令"; fi

# headRefOid 與本地 tip 不符（同名 branch 已有新工作）→ 只印診斷，**不列入清理**
make_gh_prlist_stub "$TMP/gh-sq-mismatch" 0000000000000000000000000000000000000000 acme 0
out="$(SHIP_STATE_GH="$TMP/gh-sq-mismatch" "$SS_SCRIPT" "$TMP/sq-work")"
if grep -q "SHA mismatch" <<< "$out"; then ok "headRefOid 不符 → 印診斷"; else bad "SHA 不符卻無診斷（靜默）"; fi
if grep -qE "^  (local|remote): .*feat/squashed" <<< "$out"; then bad "SHA 不符仍列入可清理（會誘導刪掉不在 default 上的 commit）"; else ok "SHA 不符 → 不列入清理清單"; fi

# fork 來源的 PR 不採信（headRefName 同名但那是別人 repo 的 branch）
make_gh_prlist_stub "$TMP/gh-sq-fork" "$sq_tip" outsider 0
out="$(SHIP_STATE_GH="$TMP/gh-sq-fork" "$SS_SCRIPT" "$TMP/sq-work")"
if grep -qE "^  (local|remote): .*feat/squashed" <<< "$out"; then bad "採信了 fork 來源的 PR"; else ok "fork 來源不採信"; fi

# 達 limit → partial，**絕不輸出 none**（截斷處靜默＝謊報「掃完了、沒有」）
make_gh_prlist_stub "$TMP/gh-sq-limit" "$sq_tip" acme 199
out="$(SHIP_STATE_GH="$TMP/gh-sq-limit" "$SS_SCRIPT" "$TMP/sq-work")"
if grep -qE "^  scan: partial" <<< "$out"; then ok "結果數達 limit → scan: partial"; else bad "達 limit 未標 partial（截斷被當成掃完）"; fi

# gh 不可用 → partial，且不得宣稱沒有殘留
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/gh-sq-dead"; chmod +x "$TMP/gh-sq-dead"
out="$(SHIP_STATE_GH="$TMP/gh-sq-dead" "$SS_SCRIPT" "$TMP/sq-work" 2>/dev/null)"
if grep -qE "^squash-merged-branches: none" <<< "$out"; then bad "gh 失敗卻宣稱 none（查不到不等於沒有）"; else ok "gh 失敗 → 不宣稱 none"; fi

# --- B1b：remote 行必須以**遠端事實**為準，不得拿本地 tracking 殘影當殘留 ---
# 形狀：`gh pr merge --delete-branch` 之後遠端 branch 已不存在，但本機沒 prune，
# `refs/remotes/origin/<name>` 還在。只讀本地 ref 就會把「本地沒 prune」報成「遠端有殘留」。
# 危害不是誤刪（清理端 `cleanup-stale-branch.sh` 會 ls-remote 重驗並 STOP），而是**真有殘留時
# 分不出哪支是真的**——訊號一旦混入虛報就失去可信度，正是本 repo 最在意的「結論高於證據」。
# 同一支腳本的 `detect_stale_branches` 早就知道這個殘影問題（見其註解），只是選了另一種緩解；
# 這裡改為對齊 `cleanup-stale-branch.sh` 的判準：直接問遠端。
git init --bare -q -b main "$TMP/sqs-origin.git"
git init -q -b main "$TMP/sqs-work"
(cd "$TMP/sqs-work" \
    && echo base > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/sqs-origin.git" && git push -q origin main \
    && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
    && git switch -qc feat/squashed && echo feature > f.txt && "${GITC[@]}" commit -qam "feat: 功能" \
    && git push -q -u origin feat/squashed \
    && git switch -q main && echo feature > f.txt && "${GITC[@]}" commit -qam "feat: 功能 (#12)" \
    && git push -q origin main)
sqs_tip="$(git -C "$TMP/sqs-work" rev-parse feat/squashed)"
git -C "$TMP/sqs-origin.git" update-ref -d refs/heads/feat/squashed   # 模擬 --delete-branch

# 前置自檢：缺任一條，下面的斷言就不是在測它宣稱要測的東西
if [ -z "$(git -C "$TMP/sqs-origin.git" for-each-ref --format='%(refname:short)' refs/heads/feat/squashed)" ]; then
    ok "fixture 前置：遠端已無 feat/squashed"
else bad "fixture 未刪掉遠端 branch，虛報情境不成立（後續斷言失效）"; fi
if git -C "$TMP/sqs-work" rev-parse --verify -q origin/feat/squashed >/dev/null; then
    ok "fixture 前置：本地 tracking 殘影仍在（未 prune）"
else bad "fixture 的本地殘影不存在，虛報情境不成立（後續斷言失效）"; fi

make_gh_prlist_stub "$TMP/gh-sqs" "$sqs_tip" acme 0
out="$(SHIP_STATE_GH="$TMP/gh-sqs" "$SS_SCRIPT" "$TMP/sqs-work")"
if grep -qE "^  local: feat/squashed" <<< "$out"; then ok "本地 branch 仍列出（那是真殘留）"; else bad "連真的本地殘留也漏掉：$out"; fi
if grep -qE "^  remote: origin/feat/squashed" <<< "$out"; then
    bad "拿本地 tracking 殘影當遠端殘留（虛報——遠端其實已無該 branch）：$out"
else ok "遠端已刪 → remote 行不列入（以遠端事實為準）"; fi
if grep -qE "^  skipped: feat/squashed — 遠端已無" <<< "$out"; then
    ok "殘影有診斷（使用者知道該 prune，不是靜默消失）"
else bad "殘影被靜默丟棄，使用者不知道本地要 prune：$out"; fi

# ls-remote 失敗 → **不得**靜默把 remote 行丟掉（查不到 ≠ 沒有，與 gh 失敗那條同判準）
(cd "$TMP/sqs-work" && git remote set-url origin "$TMP/sqs-nonexistent.git")
out="$(SHIP_STATE_GH="$TMP/gh-sqs" "$SS_SCRIPT" "$TMP/sqs-work" 2>/dev/null)"
if grep -qE "^  remote: origin/feat/squashed.*未驗證" <<< "$out"; then
    ok "ls-remote 失敗 → remote 行保留並標「未驗證」"
else bad "ls-remote 失敗時把 remote 行靜默丟掉、或未標未驗證：$out"; fi
(cd "$TMP/sqs-work" && git remote set-url origin "$TMP/sqs-origin.git")

# --- B1c：多 remote —— 非 canonical remote 的 branch 不得產生刪除指令 ---
# 病灶（2026-08-16 實地重現）：候選來自 `branch -r`，它列**所有** remote 的 tracking ref，
# 但組 cleanup-cmd 時只剝 canonical 前綴 → `fork/feat/x` 原樣被當成 branch 名傳給
# cleanup-stale-branch.sh，而後者自己把 remote 解析成 canonical → 等於
# `ls-remote origin fork/feat/x`，必然落空、verdict: STOP。訊號說「可清」、指令永遠清不掉。
# 既有 fixture 全是單 remote，兩種認知恰好等價，故此路徑一直沒現形。
# 判準刻意釘在**行為**而非文字：凡印出的 cleanup-cmd，照抄執行必須 exit 0。這是 B1 那條
# 端到端斷言的推廣——「指令長得對」不等於「指令跑得動」，後者才是訊號的價值所在；
# 釘行為也讓判準不隨修法搖擺（不論選擇不發指令、或發一條帶對 remote 的指令，都適用）。
git init --bare -q -b main "$TMP/mrb-origin.git"
git init --bare -q -b main "$TMP/mrb-fork.git"
git init -q -b main "$TMP/mrb-work"
(cd "$TMP/mrb-work" \
    && echo a > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/mrb-origin.git" && git push -qu origin main \
    && git remote add fork "$TMP/mrb-fork.git" \
    && git push -q origin main:feat/canon-merged \
    && git push -q fork main:feat/fork-merged \
    && git switch -qc feat/fork-unmerged && echo b > f.txt && "${GITC[@]}" commit -qam "feat: 未併入" \
    && git push -q fork feat/fork-unmerged \
    && git switch -q main && git branch -q -D feat/fork-unmerged \
    && git fetch -q --all)
make_gh_prlist_stub "$TMP/gh-mrb" deadbeef acme 0
out="$(SHIP_STATE_GH="$TMP/gh-mrb" "$SS_SCRIPT" "$TMP/mrb-work")"
mrb_cmds="$(grep -E "^  cleanup-cmd: .*cleanup-stale-branch\\.sh'? " <<< "${out}")"

# canonical 側不得因本修法被誤傷（它才是唯一該給刪除指令的來源）
if grep -qE '^  remote: origin/feat/canon-merged' <<< "${out}"; then
    ok "多 remote：canonical remote 的殘留照常列出"
else bad "多 remote：canonical 側殘留被誤過濾掉：${out}"; fi

# 非 canonical 的 ref 不得出現在任何 cleanup-cmd 的引數裡——那正是永遠 STOP 的那條
if grep -q 'fork/' <<< "${mrb_cmds}"; then
    bad "非 canonical remote 的 ref 被當成 branch 名塞進 cleanup-cmd：${mrb_cmds}"
else ok "多 remote：非 canonical 的 ref 不進 cleanup-cmd"; fi

# 訊號不因「不可清」而消失。fork-merged 走祖先路徑、fork-unmerged 走 squash 路徑——
# 兩條路徑都要說得出它們存在（後者原本在名字比對就 `continue`，是靜默漏報）
if grep -q 'fork/feat/fork-merged' <<< "${out}" && grep -q 'fork/feat/fork-unmerged' <<< "${out}"; then
    ok "多 remote：非 canonical 上的殘留仍被列出（兩條偵測路徑都不靜默）"
else bad "非 canonical remote 的殘留被靜默丟棄，使用者不知道它們存在：${out}"; fi

# 只說「不給刪除指令」不夠——要指出合法出路，否則使用者只能自己猜
if grep -q 'remote remove' <<< "${out}"; then
    ok "多 remote：附上停止追蹤的出路（不是只丟一句不處理）"
else bad "非 canonical 殘留只被列出、未給任何出路：${out}"; fi

# 通則（破壞性，故放最後）：凡印出的 cleanup-cmd，照抄執行必須 exit 0
if [ -z "$mrb_cmds" ]; then
    bad "多 remote fixture 未產生任何 cleanup-cmd（fixture 前提失效——canonical 側應有殘留）"
else
    mrb_bad=0; mrb_last=""
    while IFS= read -r mrb_line; do
        [ -n "$mrb_line" ] || continue
        mrb_cmd="${mrb_line#  cleanup-cmd: }"
        bash -c "$mrb_cmd" >/dev/null 2>&1 \
            || { mrb_bad=$((mrb_bad + 1)); mrb_last="$mrb_line"; }
    done <<< "$mrb_cmds"
    if [ "$mrb_bad" -eq 0 ]; then
        ok "多 remote：每一條 cleanup-cmd 照抄都跑得動（exit 0）"
    else bad "多 remote：有 ${mrb_bad} 條 cleanup-cmd 照抄後失敗（例：${mrb_last}）"; fi
fi

# --- B2：cleanup-stale-branch.sh（破壞性刪除，執行當下重驗）---
# 為何要專用腳本而非照抄 `git branch -D`：偵測與刪除之間有 TOCTOU 窗口——ship-state 印出
# 訊號後，另一個 session（或使用者自己）可能在那支 branch 上又 commit 了東西。照抄的 `-D`
# 對此完全無感，砍下去就砍了；把 expected SHA 綁在**執行當下**重驗才關得掉那個窗口。
CL_SCRIPT="$ROOT/claude/skills/project/scripts/cleanup-stale-branch.sh"
mk_cl_repo() {   # $1=路徑；造 main + feat/gone（local + remote）
    rm -rf "$1"
    git init --bare -q -b main "$1-origin.git"
    git init -q -b main "$1"
    (cd "$1" && echo a > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
        && git remote add origin "$1-origin.git" && git push -qu origin main \
        && git switch -qc feat/gone && echo b > f.txt && "${GITC[@]}" commit -qam "feat: gone" \
        && git push -qu origin feat/gone && git switch -q main)
}

mk_cl_repo "$TMP/cl-work"
cl_tip="$(git -C "$TMP/cl-work" rev-parse feat/gone)"

# SHA 相符 → 刪得掉（local）
out="$("$CL_SCRIPT" "$TMP/cl-work" local feat/gone "$cl_tip" 2>&1)"; rc=$?
assert_rc "SHA 相符 → local 刪除成功（exit 0）" 0 $rc
if ! git -C "$TMP/cl-work" rev-parse --verify -q feat/gone >/dev/null; then ok "local branch 已刪除"; else bad "回報成功卻沒刪掉（${out}）"; fi

# SHA 不符（branch 在偵測之後又前進）→ STOP，且**不得刪**
mk_cl_repo "$TMP/cl-moved"
cl_old="$(git -C "$TMP/cl-moved" rev-parse feat/gone)"
(cd "$TMP/cl-moved" && git switch -q feat/gone && echo c > f.txt && "${GITC[@]}" commit -qam "feat: 別的 session 又推進了" && git switch -q main)
out="$("$CL_SCRIPT" "$TMP/cl-moved" local feat/gone "$cl_old" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then ok "SHA 不符 → 非 0 退出"; else bad "SHA 不符卻回報成功（TOCTOU 窗口沒關）"; fi
if git -C "$TMP/cl-moved" rev-parse --verify -q feat/gone >/dev/null; then ok "SHA 不符 → branch 原封不動（零 mutation）"; else bad "SHA 不符仍把 branch 刪了（不可逆）"; fi
if grep -q "STOP" <<< "$out"; then ok "SHA 不符 → 輸出 STOP verdict"; else bad "缺 STOP verdict（${out}）"; fi

# 當前 checked-out 的 branch → 拒刪（git 自己也會拒，但要給清楚 verdict 而非 git 的錯誤訊息）
mk_cl_repo "$TMP/cl-cur"
cl_cur_tip="$(git -C "$TMP/cl-cur" rev-parse feat/gone)"
(cd "$TMP/cl-cur" && git switch -q feat/gone)
out="$("$CL_SCRIPT" "$TMP/cl-cur" local feat/gone "$cl_cur_tip" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then ok "刪當前 branch → 非 0 退出"; else bad "刪掉了自己腳下那支"; fi
if grep -q "STOP" <<< "$out"; then ok "刪當前 branch → 輸出 STOP verdict"; else bad "缺 STOP verdict（${out}）"; fi

# remote 刪除：帶 lease，SHA 相符才刪
mk_cl_repo "$TMP/cl-rem"
cl_rem_tip="$(git -C "$TMP/cl-rem" rev-parse feat/gone)"
out="$("$CL_SCRIPT" "$TMP/cl-rem" remote feat/gone "$cl_rem_tip" 2>&1)"; rc=$?
assert_rc "SHA 相符 → remote 刪除成功（exit 0）" 0 $rc
if [ -z "$(git -C "$TMP/cl-rem" ls-remote --heads origin feat/gone)" ]; then ok "remote branch 已刪除"; else bad "remote 未刪除（${out}）"; fi

# remote SHA 不符 → STOP，遠端原封不動
mk_cl_repo "$TMP/cl-rem-moved"
cl_rm_old="$(git -C "$TMP/cl-rem-moved" rev-parse feat/gone)"
(cd "$TMP/cl-rem-moved" && git switch -q feat/gone && echo d > f.txt && "${GITC[@]}" commit -qam "feat: 遠端也前進了" && git push -q origin feat/gone && git switch -q main)
out="$("$CL_SCRIPT" "$TMP/cl-rem-moved" remote feat/gone "$cl_rm_old" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then ok "remote SHA 不符 → 非 0 退出"; else bad "remote SHA 不符卻刪了"; fi
if [ -n "$(git -C "$TMP/cl-rem-moved" ls-remote --heads origin feat/gone)" ]; then ok "remote SHA 不符 → 遠端 branch 仍在"; else bad "remote SHA 不符仍刪掉遠端（不可逆）"; fi
# lease 是第二道防線（拿掉前置比對它照樣會擋），故另立一條看**前置檢查本身**還在不在——
# 少了這條，前置比對可以被整段刪掉而全綠：使用者拿到的會是 git 的 lease 錯誤訊息而非 STOP
if grep -q "STOP" <<< "$out"; then ok "remote SHA 不符 → 輸出 STOP verdict（前置比對，不倚賴 lease 兜底）"; else bad "remote SHA 不符只靠 lease 擋（輸出是 git 錯誤，非 STOP verdict）"; fi

# 引數與環境錯誤：用法錯 → 2；非 git repo → 非 0；branch 不存在 → STOP
"$CL_SCRIPT" "$TMP/cl-work" local feat/gone >/dev/null 2>&1; assert_rc "引數不足 → exit 2" 2 $?
"$CL_SCRIPT" "$TMP/cl-work" bogus feat/gone "$cl_tip" >/dev/null 2>&1; assert_rc "未知 scope → exit 2" 2 $?
mkdir -p "$TMP/cl-notgit"
if ! "$CL_SCRIPT" "$TMP/cl-notgit" local feat/gone "$cl_tip" >/dev/null 2>&1; then ok "非 git repo → 非 0 退出"; else bad "非 git repo 卻回報成功"; fi
out="$("$CL_SCRIPT" "$TMP/cl-work" local feat/nonexistent "$cl_tip" 2>&1)"
if grep -q "STOP" <<< "$out"; then ok "branch 不存在 → STOP（不當成已刪成功）"; else bad "branch 不存在未給 STOP（${out}）"; fi

# 傳進 remote-tracking ref 的路徑（`fork/x`）→ STOP 訊息要指出 **remote 錯了**，不是名字錯。
# 發射端已過濾掉這種輸入，這條測的是 defence in depth：手打指令的人仍可能踩，而
# 「確認名字是否正確」在這個案例裡名字其實是對的，會把人導向錯誤的排查方向。
(cd "$TMP/cl-work" && git remote add fork "$TMP/cl-work-origin.git")
out="$("$CL_SCRIPT" "$TMP/cl-work" remote fork/feat/gone "$cl_tip" 2>&1)"
if grep -q "STOP" <<< "$out"; then ok "傳 tracking ref 路徑 → STOP（零 mutation）"; else bad "傳 tracking ref 路徑未給 STOP（${out}）"; fi
if grep -q "remote-tracking ref" <<< "$out"; then
    ok "STOP 訊息指出是 remote-tracking ref 路徑（不誤導成名字打錯）"
else bad "STOP 訊息仍只說「確認名字是否正確」，把人導向錯誤的排查方向（${out}）"; fi

# --- bootstrap 偵測（全新空 repo 的第一次 ship；default 定位不到時才觸發）---
# 兩種「default: NONE」的正確處置完全相反：遠端零 branch → 可建 baseline；遠端有
# branch 但本地定位不到 → 絕不可推（推了就把 feature branch 變成遠端 default）。
# 本區塊釘死「分辨得出來」與「baseline 建立後豁免自動失效」。

# 情境 0（#153 regression）：遠端零 branch + HEAD 在 feature + 本地沒有 intended-default
# → 遠端為空不是把 feature 升成 default 的充分證據。必須 STOP，且不可輸出 push feature。
git init --bare -q -b main "$TMP/bs-feature-origin.git"
git init -q -b refactor/initial-import "$TMP/bs-feature-work"
(cd "$TMP/bs-feature-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/bs-feature-origin.git")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bs-feature-work")"
if grep -q "verdict: STOP" <<< "$out" && ! grep -q "bootstrap-cmd:" <<< "$out"; then
    ok "空 remote + feature HEAD + 無 intended-default → STOP 且不輸出 bootstrap push"
else bad "空 remote 把 feature HEAD 當 default bootstrap（${out}）"; fi
if grep -q "baseline" <<< "$out"; then
    ok "missing intended-default STOP 揭露 baseline evidence 缺口"
else bad "missing intended-default STOP 未說明 baseline 缺口（${out}）"; fi

# 情境 1：遠端零 branch + 本地 main 有 commit → BOOTSTRAP
git init --bare -q -b main "$TMP/bs-origin.git"
git init -q -b main "$TMP/bs-work"
(cd "$TMP/bs-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/bs-origin.git")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bs-work")"
assert_rc "空 remote → exit 0（verdict 即成功）" 0 $?
if grep -q "verdict: BOOTSTRAP" <<< "$out"; then ok "遠端零 branch → BOOTSTRAP verdict"; else bad "遠端零 branch 未判 BOOTSTRAP（${out}）"; fi
if grep -q "remote-heads: 0" <<< "$out"; then ok "BOOTSTRAP 附遠端 branch 數證據"; else bad "BOOTSTRAP 缺 remote-heads 證據"; fi
if grep -qF "push -u 'origin' 'main'" <<< "$out"; then ok "BOOTSTRAP 附可照抄 push 指令（remote/branch 均已 quote）"; else bad "BOOTSTRAP 缺 bootstrap-cmd"; fi
if grep -q "bootstrap-note:.*default branch" <<< "$out"; then ok "BOOTSTRAP 標明首推將決定遠端 default"; else bad "BOOTSTRAP 未標明 default 後果"; fi
if grep -q "bootstrap-scope:" <<< "$out"; then ok "BOOTSTRAP 標明豁免作用域（防授權蔓延）"; else bad "BOOTSTRAP 缺 scope 行（授權會蔓延到後續 commit）"; fi

# 非 main intended default + HEAD 在 feature，但 local trunk 是 ancestor → 推 trunk，不推 feature。
git init --bare -q -b trunk "$TMP/bs-nonmain-origin.git"
git init -q -b trunk "$TMP/bs-nonmain-work"
(cd "$TMP/bs-nonmain-work" \
    && echo base > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git switch -qc feat/import && echo feature >> f.txt && "${GITC[@]}" commit -qam feature \
    && git remote add origin "$TMP/bs-nonmain-origin.git")
out="$(SHIP_STATE_GH="$TMP/gh-bs-trunk" "$SS_SCRIPT" "$TMP/bs-nonmain-work")"
if grep -qF "bootstrap-default: trunk" <<< "$out" \
    && grep -qF "push -u 'origin' 'trunk'" <<< "$out" \
    && ! grep -qF "push -u 'origin' 'feat/import'" <<< "$out"; then
    ok "非 main metadata + feature HEAD → bootstrap intended trunk"
else bad "非 main bootstrap 未鎖定 intended default（${out}）"; fi

# explicit contract／當輪確認可選非 metadata branch；輸出必須揭露衝突，不能默默覆蓋。
(cd "$TMP/bs-nonmain-work" && git branch release trunk)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" --bootstrap-default release "$TMP/bs-nonmain-work")"
if grep -q "bootstrap-default-conflict:" <<< "$out" \
    && grep -qF "push -u 'origin' 'release'" <<< "$out"; then
    ok "explicit intended default 解決 metadata 衝突並揭露 evidence"
else bad "explicit default 未安全處理 metadata 衝突（${out}）"; fi

# creation policy：required check/workflow 若不豁免 create，空 repo 沒有可先產生 status 的
# target ref → deterministic deadlock STOP；明示豁免 create 才可 bootstrap。
out="$(SHIP_STATE_GH="$TMP/gh-bs-required" "$SS_SCRIPT" "$TMP/bs-work")"
if grep -q "bootstrap-policy: BLOCKED" <<< "$out" \
    && grep -q "required-check/workflow-on-create=1" <<< "$out" \
    && ! grep -q "bootstrap-cmd:" <<< "$out"; then
    ok "required check enforced on create → policy deadlock STOP"
else bad "creation-required check 未阻止 bootstrap（${out}）"; fi
out="$(SHIP_STATE_GH="$TMP/gh-bs-required-exempt" "$SS_SCRIPT" "$TMP/bs-work")"
if grep -q "bootstrap-policy: CLEAR" <<< "$out" && grep -q "verdict: BOOTSTRAP" <<< "$out"; then
    ok "required check 明示 exempt on create → 可建立 baseline"
else bad "creation-exempt required check 誤擋 bootstrap（${out}）"; fi
out="$(SHIP_STATE_GH="$TMP/gh-bs-creation" "$SS_SCRIPT" "$TMP/bs-work")"
if grep -q "creation-restrictions=1" <<< "$out" && grep -q "verdict: STOP" <<< "$out"; then
    ok "effective creation restriction → STOP，不假設有 bypass"
else bad "creation restriction 未 fail closed（${out}）"; fi
out="$(SHIP_STATE_GH="$TMP/gh-bs-unreadable" "$SS_SCRIPT" "$TMP/bs-work")"
if grep -q "bootstrap-policy: UNKNOWN" <<< "$out" && grep -q "verdict: STOP" <<< "$out"; then
    ok "effective policy 403／不可見 → UNKNOWN STOP"
else bad "不可見 policy 被當成無 ruleset（${out}）"; fi

# 使用者在確認型 UX 選定 baseline 後，專用 helper 只建立 local intended-default ref；
# 不 push、不切 branch、不碰 working tree。接著重跑 ship-state 才能取得 bootstrap-cmd。
before_branch="$(git -C "$TMP/bs-feature-work" branch --show-current)"
before_porcelain="$(git -C "$TMP/bs-feature-work" status --porcelain)"
selected_head="$(git -C "$TMP/bs-feature-work" rev-parse HEAD)"
out="$("$BS_BASELINE_SCRIPT" "$TMP/bs-feature-work" main "$selected_head" 2>&1)"; bs_rc=$?
assert_rc "明示 HEAD baseline → helper exit 0" 0 "$bs_rc"
if git -C "$TMP/bs-feature-work" show-ref --verify -q refs/heads/main \
    && [ "$(git -C "$TMP/bs-feature-work" rev-parse main)" = "$selected_head" ]; then
    ok "baseline helper 建立 intended-default ref 指向明示 SHA"
else bad "baseline helper 未建立正確 local default（${out}）"; fi
assert_eq "baseline helper 不切換目前 feature branch" "$before_branch" "$(git -C "$TMP/bs-feature-work" branch --show-current)"
assert_eq "baseline helper 不碰 working tree" "$before_porcelain" "$(git -C "$TMP/bs-feature-work" status --porcelain)"
if ! git -C "$TMP/bs-feature-origin.git" show-ref --verify -q refs/heads/main; then
    ok "baseline helper 不 push remote"
else bad "baseline helper 越權 push remote"; fi
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bs-feature-work")"
if grep -q "bootstrap-baseline: READY" <<< "$out" \
    && grep -qF "push -u 'origin' 'main'" <<< "$out"; then
    ok "明示 baseline 準備後重跑 detection → 只推 intended default"
else bad "baseline preparation 後未取得安全 bootstrap（${out}）"; fi

# helper failure paths：non-ancestor、remote 已非空與既有 ref 指向不同 SHA 都要零 mutation STOP。
git init -q -b side "$TMP/bs-side"
(cd "$TMP/bs-side" && echo side > side && "${GITC[@]}" add side && "${GITC[@]}" commit -qm side)
side_sha="$(git -C "$TMP/bs-side" rev-parse HEAD)"
git -C "$TMP/bs-feature-work" fetch -q "$TMP/bs-side" "$side_sha"
out="$("$BS_BASELINE_SCRIPT" "$TMP/bs-feature-work" trunk "$side_sha" 2>&1)"; bs_rc=$?
if [ "$bs_rc" -ne 0 ] && grep -q "verdict: STOP" <<< "$out" \
    && ! git -C "$TMP/bs-feature-work" show-ref --verify -q refs/heads/trunk; then
    ok "non-ancestor baseline → STOP 且不建立 ref"
else bad "non-ancestor baseline 未保持零 mutation（${out}）"; fi
out="$("$BS_BASELINE_SCRIPT" "$TMP/bs-feature-work" option-injection --help 2>&1)"; bs_rc=$?
if [ "$bs_rc" -ne 0 ] && grep -q "verdict: STOP" <<< "$out" \
    && ! git -C "$TMP/bs-feature-work" show-ref --verify -q refs/heads/option-injection; then
    ok "baseline candidate option injection → STOP 且不建立 ref"
else bad "baseline candidate 被 rev-parse 當 option（${out}）"; fi
(cd "$TMP/bs-feature-work" \
    && echo later >> f.txt && "${GITC[@]}" commit -qam later \
    && git branch conflict main)
conflict_candidate="$(git -C "$TMP/bs-feature-work" rev-parse HEAD)"
out="$("$BS_BASELINE_SCRIPT" "$TMP/bs-feature-work" conflict "$conflict_candidate" 2>&1)"; bs_rc=$?
if [ "$bs_rc" -ne 0 ] && grep -q "verdict: STOP" <<< "$out" \
    && [ "$(git -C "$TMP/bs-feature-work" rev-parse conflict)" = "$selected_head" ]; then
    ok "既有 default ref 指向不同 SHA → STOP 且不改 ref"
else bad "既有 ref conflict 被覆寫（${out}）"; fi
(cd "$TMP/bs-feature-work" && git push -qu origin refactor/initial-import)
out="$("$BS_BASELINE_SCRIPT" "$TMP/bs-feature-work" race HEAD 2>&1)"; bs_rc=$?
if [ "$bs_rc" -ne 0 ] && grep -q "remote-heads: 1" <<< "$out" \
    && ! git -C "$TMP/bs-feature-work" show-ref --verify -q refs/heads/race; then
    ok "確認後 remote 已被先推 → helper 重新檢查並零 mutation STOP"
else bad "remote race 未被 helper 擋下（${out}）"; fi

# 情境 2：遠端零 branch + detached HEAD → 不可 bootstrap（無 branch 名可當 default）
(cd "$TMP/bs-work" && git checkout -q --detach)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bs-work")"
if grep -q "verdict: STOP" <<< "$out" && ! grep -q "verdict: BOOTSTRAP" <<< "$out"; then
    ok "空 remote + detached HEAD → STOP（非 bootstrap）"
else bad "detached HEAD 誤判 bootstrap（${out}）"; fi
(cd "$TMP/bs-work" && git checkout -q main)

# 情境 3（關鍵反例）：遠端**有** branch 但本地無 remote-tracking 且名非 main/master
# → default 定位不到，但**絕不可** bootstrap 直推
git init --bare -q -b trunk "$TMP/bs-trunk.git"
git init -q -b trunk "$TMP/bs-seed"
(cd "$TMP/bs-seed" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/bs-trunk.git" && git push -qu origin trunk)
git init -q -b main "$TMP/bs-nofetch"
(cd "$TMP/bs-nofetch" \
    && echo hi > g.txt && "${GITC[@]}" add g.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/bs-trunk.git")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bs-nofetch")"
if grep -q "verdict: STOP" <<< "$out" && ! grep -q "BOOTSTRAP" <<< "$out"; then
    ok "遠端有 branch 但定位不到 default → STOP（不得誤判 bootstrap）"
else bad "遠端有 branch 卻判 bootstrap——會把 feature branch 推成遠端 default（${out}）"; fi
if grep -q "remote-heads: 1" <<< "$out"; then ok "反例附遠端 branch 數證據（供使用者 fetch/指定）"; else bad "反例缺 remote-heads 證據"; fi

# 情境 4（機制失效）：baseline 建立後 → 永不再印 BOOTSTRAP，branch-first 恢復 REQUIRED
(cd "$TMP/bs-work" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/bs-work")"
if ! grep -q "BOOTSTRAP" <<< "$out"; then ok "baseline 建立後 → BOOTSTRAP 豁免自動失效（機制而非記憶）"; else bad "baseline 已存在仍印 BOOTSTRAP（授權可蔓延）"; fi
if grep -q "branch-first: REQUIRED" <<< "$out"; then ok "baseline 建立後 → branch-first 恢復 REQUIRED"; else bad "baseline 後未恢復 branch-first"; fi

# --- dossier 偵測行（Step 2 衛生檢查；門檻單一來源 = 本腳本）---

# 無 STATUS.md → dossier: NONE
git init --bare -q -b main "$TMP/ds-origin.git"
git init -q -b main "$TMP/ds-work"
(cd "$TMP/ds-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ds-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier: NONE" <<< "$out"; then ok "無 STATUS.md → dossier: NONE"; else bad "缺 dossier: NONE 行"; fi

# 乾淨 dossier（<300 行、進行中無 ✅、無 Session Log、剛 commit）→ 無 flag
# （已完成節的 ✅ 是合法用法，不得誤報——負向測試就藏在這份 fixture 裡）
cat > "$TMP/ds-work/STATUS.md" <<'DOSSIER'
# 測試專案 STATUS

## 進行中
- 項目一：還在做

## 關鍵決策（附理由）
- 選了 X 因為 Y

## 已完成（里程碑）
- ✅ 2026-07-01 已完成項（合法 ✅，不應觸發 flag）

## 死路（試過但放棄）
- 試過 Z，放棄

## 技術債
- 一條債

## 已知缺口
- 一條缺口

## 移交準備度
（暫無）
DOSSIER
(cd "$TMP/ds-work" && "${GITC[@]}" add STATUS.md && "${GITC[@]}" commit -qm "docs: dossier")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier: STATUS.md" <<< "$out"; then ok "有 STATUS.md → dossier 行含行數"; else bad "缺 dossier: STATUS.md 行"; fi
if grep -q "dossier-flag:" <<< "$out"; then bad "乾淨 dossier 不應有 flag（$(echo "$out" | grep 'dossier-flag:')）"; else ok "乾淨 dossier → 無 dossier-flag（已完成節 ✅ 未誤報）"; fi
# 各節佔比只在全檔超標時印——常態輸出多一段佔比表就成了每次 ship 的噪音
if grep -q "^dossier-sections:" <<< "$out"; then bad "未超標卻印 dossier-sections（污染常態輸出）"; else ok "未超標 → 不印 dossier-sections"; fi

# 「進行中」含 ✅ → flag（working tree 內容即測，不需 commit）
cat > "$TMP/ds-work/STATUS.md" <<'DOSSIER'
# 測試專案 STATUS

## 進行中
- ✅ 做完了卻沒移走的項目
- 項目二：還在做

## 已完成（里程碑）
- 無
DOSSIER
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then ok "進行中含 ✅ → flag"; else bad "進行中 ✅ 未偵測"; fi

# 規範外章節（Session Log）→ flag
cat > "$TMP/ds-work/STATUS.md" <<'DOSSIER'
# 測試專案 STATUS

## 進行中
- 項目

## Session Log
- 2026-07-01 做了一堆事
DOSSIER
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*Session Log" <<< "$out"; then ok "Session Log 章節 → flag"; else bad "Session Log 未偵測"; fi

# append-only 章節的**別名家族**：規範是「NEVER add an append-only log section」，不是
# 「不要叫 Session Log」——只認一個字面時，換個名字就整個漏掉。訊息須附**實際命中的
# heading**，否則別名命中卻回報 Session Log，處置會指向錯的章節。
for ao_name in "變更紀錄" "變更記錄" "工作日誌" "開發日誌" "CHANGELOG" "Change Log" "Session Log（2026-08）"; do
    { echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 項目"; echo; echo "## ${ao_name}"; echo "- 條目"; } > "$TMP/ds-work/STATUS.md"
    out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
    if grep -q "dossier-flag:.*append-only log：## ${ao_name}" <<< "$out"; then
        ok "append-only 別名「${ao_name}」→ flag（訊息附實際 heading）"
    else
        bad "append-only 別名「${ao_name}」未偵測或訊息未附實際 heading"
    fi
done
# 負向：討論性章節不得誤報——gate 誤報的代價是逼人把安全寫法改壞以求過測
for ao_safe in "為何不使用 Change Log" "Session Log 的替代方案" "已完成(里程碑)"; do
    { echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 項目"; echo; echo "## ${ao_safe}"; echo "- 條目"; } > "$TMP/ds-work/STATUS.md"
    out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
    if grep -q "dossier-flag:.*append-only log" <<< "$out"; then
        bad "討論性章節「${ao_safe}」被誤報成 append-only log"
    else
        ok "討論性章節「${ao_safe}」→ 不誤報"
    fi
done

# 全檔 > 300 行 → flag
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; seq 1 310 | sed 's/^/- filler /'; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*> 300" <<< "$out"; then ok "全檔 >300 行 → flag"; else bad ">300 行未偵測"; fi
if grep -q "建議收斂至 ≤ 255 行" <<< "$out"; then ok "行數 flag 附建議收斂目標（300 × 85%）"; else bad "行數 flag 缺建議收斂目標"; fi

# 總量 bytes 超標但行數遠低於 300 → bytes flag（行數代理被巨型單行架空的後盾；
# 每行 ~548 bytes < 1000，不得連帶觸發最長行 flag——測試隔離）
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"
  awk 'BEGIN { s = "- 填充"; for (i = 0; i < 30; i++) s = s "巨量內容累積"; for (r = 0; r < 120; r++) print s }'
  echo; echo "## 已完成（里程碑）"; echo "- ✅ 無"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -qE "dossier-flag:.*全檔.*bytes > " <<< "$out"; then ok "行數少但總 bytes 超標 → bytes flag（風格不敏感後盾）"; else bad "bytes 超標未偵測（行數代理可被巨型單行架空）"; fi
if grep -q "dossier-flag:.*> 300" <<< "$out"; then bad "bytes fixture 不應觸發行數 flag（行數僅 ~125）"; else ok "bytes fixture 未誤觸發行數 flag"; fi
if grep -q "dossier-flag:.*最長行" <<< "$out"; then bad "bytes fixture 不應觸發最長行 flag（每行 ~548B < 1000）"; else ok "bytes fixture 未誤觸發最長行 flag"; fi
# 建議收斂目標：壓到「剛好低於門檻」等於下次 ship 必再觸發，故 flag 要直接給目標值
if grep -q "建議收斂至 ≤ 26112 bytes" <<< "$out"; then ok "bytes flag 附建議收斂目標（門檻 85%）"; else bad "bytes flag 缺建議收斂目標（agent 會停在剛好過關處）"; fi
# 各節佔比：超標時才印，供 model 決定收哪一節（憑印象挑會挑錯——krepo 實證 905B/PR）
if grep -q "^dossier-sections:" <<< "$out"; then ok "全檔超標 → 印各節佔比"; else bad "全檔超標未印 dossier-sections（收斂對象只能靠猜）"; fi
# 釘住「最大戶排第一」＋數值形狀：排序方向是這功能的全部價值（挑錯對象正是它要防的），
# 只 grep「行存在 + 含某節名」的斷言在 sort -rn → sort -n 突變下照樣全綠（R1 審查實證）
if grep -qE "^dossier-sections: 進行中 [0-9]{4,} \([0-9]+%\)" <<< "$out"; then ok "各節佔比：最大戶排第一、附 bytes 與百分比"; else bad "dossier-sections 排名或數值形狀錯（實得：$(echo "$out" | grep dossier-sections)）"; fi

# fence 重的章節不得被低估到排名倒轉：剝 fence 時若「清空」該行（而非哨兵前綴保留長度），
# 決策節 30KB 的 code block 會被算成幾百 bytes、沉到小章節後面——而 SKILL.md 正是要 agent
# 照這張表挑收斂對象，等於主動誤導（R1 審查實證：26KB 節報成 403 bytes）
# 本 fixture 一份守四件事（皆需「大檔 + fenced 假章節」才會發作，故合為一份）：
#   ①分節 bytes 不因剝 fence 而低估（排名倒轉）②fence 內假標題不誤判簽章
#   ③fence 內的「## 進行中 / - ✅」範例不誤報完成項未移走
#   ④大輸入下 Session Log 仍偵測得到（herestring；pipe 版會 SIGPIPE 早退成偽陰性）
# ⚠️ Session Log 與假 ✅ 都必須放在**大 fence 之前**：grep -q / awk 命中即退出，命中點在
# 檔尾的話上游 printf 早就寫完、SIGPIPE 不會發作，守門形同虛設（實測：置於檔尾時把
# herestring 改回 printf|grep 仍全綠）。前段命中才逼出「寫不完 → SIGPIPE → pipefail」
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 短項目"; echo
  echo "## Session Log"
  echo "- 2026-07-29 這是規範外章節，應被偵測到"; echo
  echo "## 關鍵決策（附理由）"
  echo '```markdown'
  echo "## 進行中"
  echo "- ✅ 這是文件範例裡的完成項，不是真的狀態"
  awk 'BEGIN { s = "# "; for (i = 0; i < 20; i++) s = s "fenced_payload_line_content_"; for (r = 0; r < 200; r++) print s }'
  echo '```'
  echo
  echo "## 已完成（里程碑）"
  awk 'BEGIN { s = "- ✅ 里程碑填充"; for (i = 0; i < 10; i++) s = s "內容"; for (r = 0; r < 30; r++) print s }'; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -qE "^dossier-sections: 關鍵決策（附理由） [0-9]{5,}" <<< "$out"; then ok "fenced 內容計入分節 bytes（大 fence 章節排第一，未被低估）"; else bad "fence 章節被低估／排名倒轉（實得：$(echo "$out" | grep dossier-sections)）"; fi
if grep -q "dossier-flag:.*簽章" <<< "$out"; then bad "大輸入下簽章偽陽性（herestring 或括號 ERE 不相容）"; else ok "大檔簽章判定正確（herestring + GNU/BSD grep 括號 ERE）"; fi
# ✅ 偵測必須吃 unfenced：讀原檔會把 fence 內的範例當成真的「進行中含 ✅」
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then bad "fence 內的 ✅ 範例被誤報為完成項未移走（✅ 偵測未吃 unfenced）"; else ok "fence 內的 ✅ 範例不誤報"; fi
# Session Log 偵測的失效方向是偽陰性（命中才早退），比簽章那處更隱蔽——必須有具名守門
if grep -q "dossier-flag:.*Session Log" <<< "$out"; then ok "大檔（>pipe buffer）Session Log 仍偵測到（herestring 防 SIGPIPE 偽陰性）"; else bad "大輸入下 Session Log 偽陰性（grep -q 早退 + pipefail）"; fi

# 巨型單行（1202 bytes > 1000）→ 最長行 flag（總量未爆前的早期風格糾正）
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"
  awk 'BEGIN { s = "- "; for (i = 0; i < 1200; i++) s = s "x"; print s }'
  echo; echo "## 已完成（里程碑）"; echo "- ✅ 無"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*最長行" <<< "$out"; then ok "1202 bytes 單行 → 最長行 flag"; else bad "巨型單行未偵測"; fi
if grep -qE "dossier-flag:.*全檔.*bytes > " <<< "$out"; then bad "最長行 fixture 不應觸發總量 bytes flag（全檔 <2KB）"; else ok "最長行 fixture 未誤觸發 bytes flag"; fi

# 決策節單一條目 >800 bytes（正常換行的多行條目，每行 <1000B）→ 條目 flag（行數繞不過蒸餾上限）
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 項目：還在做"; echo
  echo "## 關鍵決策（附理由）"
  awk 'BEGIN { s = "- 選了方案甲："; for (i = 0; i < 60; i++) s = s "理由與推導"; print s
               t = "  續行補充："; for (i = 0; i < 60; i++) t = t "更多細節"; print t }'
  echo "- 短決策：一行帶過"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*最大條目" <<< "$out"; then ok "決策節條目 >800 bytes → 條目 flag（蒸餾上限）"; else bad "決策節超大條目未偵測"; fi
if grep -q "dossier-flag:.*最長行" <<< "$out"; then bad "條目 fixture 不應觸發最長行 flag（每行 <1000B）"; else ok "條目 fixture 未誤觸發最長行 flag"; fi
# 定位：只報 bytes 不報位置時，agent 會預設「應該是我剛寫的那條」——多 session 並行改同一份
# dossier 時經常猜錯（krepo 2026-07-29 實證：猜錯兩次、白壓兩輪）。大條目在本 fixture 的第 7 行
if grep -q "dossier-flag:.*最大條目.*在第 7 行" <<< "$out"; then ok "條目 flag 帶正確行號（定位）"; else bad "條目 flag 缺行號或行號錯（實得：$(echo "$out" | grep '最大條目')）"; fi
# 手段提示：條目超標更常是粒度過粗（一條記多個決策），壓字壓不動
if grep -q "拆成多條" <<< "$out"; then ok "條目 flag 提示拆分而非壓字"; else bad "條目 flag 缺拆分提示"; fi

# 條目 bytes 同樣要剝哨兵：條目續行區含 fence 時每行虛胖 1 byte，足以把未超標的條目推過門檻
# （300 行 fence = +300B，650B 的條目就被誤判成 >800B）。fixture 調成「剝哨兵→不觸發、
# 不剝→觸發」，故拿掉條目 awk 的 sub(/^\001/) 就會紅——這是該防線唯一的守門
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 項目"; echo
  echo "## 關鍵決策（附理由）"
  echo "- 選了方案甲：理由見範例"
  echo '```yaml'
  awk 'BEGIN { for (r = 0; r < 300; r++) print "k" }'
  echo '```'; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*最大條目" <<< "$out"; then bad "條目 bytes 因 fence 虛胖而誤觸發門檻（條目 awk 未剝哨兵；實得：$(echo "$out" | grep '最大條目')）"; else ok "條目 bytes 已剝哨兵（fence 續行不虛胖）"; fi

# ✅ 偵測的非錨定比對：`/✅/` 沒有行首錨點，哨兵中和不了它——fence 必須放在「進行中」節內
# 才測得到（既有 fence fixture 把圍欄放在決策節，in_sec=0 永遠踩不到這條路徑）。
# 圍欄內同時放假標題與 ✅：假標題被哨兵擋掉後不再切節，若沒 skip 哨兵行，in_sec 會一路
# 開著把圍欄內的 ✅ 全算進來（此為加哨兵後才出現的回歸方向）
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 還在做的項目"
  echo '```text'
  echo "## 已完成（里程碑）"
  echo "- ✅ 這是貼在圍欄內的範例／測試輸出，不是真的完成項"
  echo '```'
  echo; echo "## 關鍵決策（附理由）"; echo "- 選了 X 因為 Y"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then bad "「進行中」節內圍欄的 ✅ 被誤報為完成項（非錨定比對未 skip 哨兵行）"; else ok "「進行中」節內圍欄的 ✅ 不誤報（非錨定比對有 skip 哨兵）"; fi

# ✅ 只在**條目形狀（list item）**上算數：表格儲存格的 ✅ 是子項狀態欄，不是「做完卻沒
# 移走的項目」。krepo 2026-08-10 連三次 ship 都被這條誤報（進行中節的一張盤點表，4 列
# 全綠），每次只能在 Step 4 附註寫「未處理」——flag 訊息叫人「移入里程碑」，而一列表格
# 搬進里程碑節無處可放，訊息本身就透露判準抓錯了對象。
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 還在做的項目"; echo
  echo "| 符號 | 現況 | 拆分處置 |"
  echo "|---|---|---|"
  echo "| foo | ✅ 已就位 | 已就位 |"
  echo "| bar | ✅ 已就位 | 已就位 |"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then bad "表格儲存格的 ✅ 被誤報為完成項未移走（判準未收窄到 list item）"; else ok "表格儲存格的 ✅ 不誤報（判準限 list item）"; fi

# 同一件事的完整實地形狀，釘住「把續行併入所屬條目」那個候選判準**不可行**：krepo 的表格
# 前面隔著散文、但更前面（第 259 行）有 bullet，而條目 bytes 那套寬續行模型（bullet 之後
# 直到下一個 bullet/標題都算續行）會把表格收回同一條目 → 照樣誤報。故只認 bullet 行本身。
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"
  echo "- 某個 Phase：還在做"
  echo "  - 子項說明"; echo
  echo "它需要的外部符號，盤點結果："; echo
  echo "| 符號 | 現況 |"
  echo "|---|---|"
  echo "| foo | ✅ 已就位 |"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then bad "bullet 之後、隔著散文的表格 ✅ 被算成該條目的續行而誤報（判準採了寬續行模型）"; else ok "bullet 之後隔著散文的表格 ✅ 不誤報（未採寬續行模型）"; fi

# 收窄不得只認頂層 bullet：縮排子項同樣是條目形狀，`  - ✅ x` 是真的完成項未移走
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"
  echo "- 某個 Phase：還在做"
  echo "  - ✅ 這個子項做完了卻沒移走"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then ok "縮排 list item 的 ✅ → flag（收窄未誤殺子項）"; else bad "縮排 list item 的 ✅ 未偵測（收窄只認了頂層 bullet）"; fi

# `*` / `+` 兩種 marker 同樣算條目（CommonMark 三種 bullet 都合法，只認 `-` 會漏）
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "* ✅ 做完了卻沒移走的項目"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then ok "\`*\` marker 的 ✅ → flag"; else bad "\`*\` marker 的 ✅ 未偵測"; fi

# marker 後**必須**有空白，否則 `**粗體** ✅` 這種散文行會被當成 bullet 而讓收窄失效
# （`*` 開頭 + 行內有 ✅ = 本次要排除的形狀之一，寬版 pattern 抓不出差別）
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 還在做的項目"; echo
  echo "**盤點結論** ✅ 這句是散文強調，不是條目"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then bad "\`**粗體**\` 開頭的散文行被當成 bullet（marker 後未要求空白）"; else ok "marker 後要求空白：\`**粗體** ✅\` 散文行不誤報"; fi

# 明示放棄的 false negative（不是 bug，改動前先讀這條）：✅ 寫在條目的**續行**上不會亮。
# 上面那條 krepo 回歸證明了續行併入會把表格一起收回來，兩者不可兼得；選擇讓「條目內部的
# 進度標註」漏掉，因為它與盤點表同性質——都不是「整條做完該搬去里程碑」。
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"
  echo "- 某個 Phase：還在做"
  echo "  ✅ 其中一步完成了（續行標註，非條目本身）"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*進行中.*✅" <<< "$out"; then bad "續行 ✅ 亮了——判準比預期寬，請確認是否連帶讓表格列也回來了"; else ok "續行 ✅ 不亮（已知且刻意放棄的 false negative）"; fi

# 分節 bytes 不得虛胖：剝 fence 的 \001 哨兵若在量長度時沒剝掉，每個 fenced 行多算 1 byte，
# 短行多的 fence（YAML/JSON/log 片段）會讓單節 bytes 超過全檔總量、百分比破 100%
# （實測曾出現 149%），兩節接近時足以造成排名倒轉——正是這功能要防的失效
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- x"; echo
  echo "## 關鍵決策（附理由）"; echo '```yaml'
  awk 'BEGIN { for (r = 0; r < 4000; r++) print "k: v" }'
  echo '```'; echo; echo "## 已完成（里程碑）"; echo "- ✅ 無"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
maxpct="$(echo "$out" | grep '^dossier-sections:' | grep -oE '\([0-9]+%\)' | tr -d '()%' | LC_ALL=C sort -rn | head -1)"
if [ -n "$maxpct" ] && [ "$maxpct" -le 100 ]; then ok "分節佔比不破 100%（哨兵長度已剝除，短行 fence 不虛胖）"; else bad "分節佔比異常或 dossier-sections 消失：maxpct=${maxpct:-<空>}（實得：$(echo "$out" | grep dossier-sections)）"; fi

# 第一個 ## 之前的前言不得被靜默丟棄：SKILL.md 要 agent 照這張表挑收斂對象，
# 殘量不現身時會把人導向兩個 4 bytes 的小節
{ echo "# 測試專案 STATUS"
  awk 'BEGIN { s = "前言填充"; for (i = 0; i < 20; i++) s = s "內容"; for (r = 0; r < 300; r++) print s }'
  echo; echo "## 進行中"; echo "- x"; echo; echo "## 關鍵決策（附理由）"; echo "- y"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -qE "^dossier-sections: \(前言/未分節\) [0-9]{4,}" <<< "$out"; then ok "前言殘量現身於分節表（不靜默丟棄）"; else bad "前言 bytes 被丟棄，表格會誤導收斂對象（實得：$(echo "$out" | grep dossier-sections)）"; fi

# 分節 bytes 必須把**標題行本身**算進它開啟的那一節：歸零會讓各節加總系統性少掉每個標題
# 的長度，讀表的人會以為有一塊沒被算到。此 fixture 無 fence、節數 < TOP_N，故加總應**恰好**
# 等於檔案 bytes（差額只可能來自標題行被漏計）。
{ echo "# 測試專案 STATUS"
  awk 'BEGIN { s = "前言填充"; for (i = 0; i < 20; i++) s = s "內容"; for (r = 0; r < 300; r++) print s }'
  echo; echo "## 進行中"; echo "- x"
  echo; echo "## 關鍵決策（附理由）"; echo "- y"
  echo; echo "## 已完成（里程碑）"; echo "- z"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
sec_sum="$(echo "$out" | grep '^dossier-sections:' | grep -oE ' [0-9]+ \([0-9]+%\)' | grep -oE '[0-9]+ ' | LC_ALL=C awk '{ t += $1 } END { print t+0 }')"
file_bytes="$(LC_ALL=C wc -c < "$TMP/ds-work/STATUS.md" | tr -d ' ')"
if [ "${sec_sum:-0}" = "$file_bytes" ]; then ok "分節 bytes 加總 == 檔案 bytes（標題行已計入所屬節）"; else bad "分節加總 ${sec_sum:-0} ≠ 檔案 ${file_bytes}（標題行未計入，佔比表恆偏低）"; fi

# 行號 vs fenced block：剝 code fence 時若「丟棄」該行而非**前綴 \001 哨兵保留原行**，後續行號
# 全數位移、flag 指向錯的地方。fixture 讓真條目落在第 12 行、其前有 4 行 fenced（含假標題）
# ——完全丟棄式剝除會報第 8 行。本條守的是**行號對齊**；長度保留（分節佔比不被低估）由上面
# 那條 fence 佔比測試守，兩條分工不同、勿合併，也勿與更上面的無 fence 版合併
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 項目：還在做"; echo
  echo '```markdown'; echo "## 關鍵決策（附理由）"; echo "- fence 內的假條目"; echo '```'
  echo
  echo "## 關鍵決策（附理由）"
  awk 'BEGIN { s = "- 選了方案甲："; for (i = 0; i < 60; i++) s = s "理由與推導"; print s
               t = "  續行補充："; for (i = 0; i < 60; i++) t = t "更多細節"; print t }'; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*最大條目.*在第 12 行" <<< "$out"; then ok "行號不受 fenced block 位移（哨兵前綴式剝除）"; else bad "fenced block 使行號位移（實得：$(echo "$out" | grep '最大條目')）"; fi

# 里程碑節超大條目（單行 872 bytes：>800 條目上限、<1000 最長行門檻）→ 條目 flag（一行化的機器面）
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 項目：還在做"; echo
  echo "## 已完成（里程碑）"
  awk 'BEGIN { s = "- ✅ 2026-07-01 大功告成："; for (i = 0; i < 70; i++) s = s "過程敘事"; print s }'; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*最大條目" <<< "$out"; then ok "里程碑節散文條目 → 條目 flag（一行化機器面）"; else bad "里程碑超大條目未偵測"; fi

# 作用域反例：「進行中」的 >800 bytes 條目（spec 區合法偏大）不得觸發條目 flag
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"
  awk 'BEGIN { s = "- 工作項 spec："; for (i = 0; i < 70; i++) s = s "合約細節"; print s }'
  echo; echo "## 已完成（里程碑）"; echo "- ✅ 無"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*最大條目" <<< "$out"; then bad "進行中的大條目誤觸發條目 flag（作用域應限決策/里程碑）"; else ok "進行中大條目未誤觸發（spec 區合法偏大）"; fi

# 作用域比對必須**錨在標題開頭**，不是子字串：`## 進行中（已完成 M1）` 含「已完成」三個字，
# 子字串版會把整個進行中章節當里程碑節掃進來——而 spec 區合法偏大，於是恆誤報。
# 這種標題是自然寫法（記錄里程碑進度），不是刻意刁難的 fixture。
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中（已完成 M1）"
  awk 'BEGIN { s = "- 工作項 spec："; for (i = 0; i < 70; i++) s = s "合約細節"; print s }'
  echo; echo "## 已完成（里程碑）"; echo "- ✅ 無"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*最大條目" <<< "$out"; then bad "標題含「已完成」的進行中章節被當成里程碑節（作用域用子字串比對，未端錨定）"; else ok "節名端錨定：`## 進行中（已完成 M1）` 不被當成里程碑節"; fi

# ✅ 掃描同型：`## 已完成（進行中殘項）` 含「進行中」，子字串版會把里程碑的 ✅ 當成
# 「進行中章節有已完成項」而誤報。此處進行中章節本身沒有 ✅，故不得印該 flag。
{ echo "# 測試專案 STATUS"; echo; echo "## 進行中"; echo "- 還在做的事"
  echo; echo "## 已完成（進行中殘項）"; echo "- ✅ 2026-07-01 某里程碑"; } > "$TMP/ds-work/STATUS.md"
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*✅" <<< "$out"; then bad "標題含「進行中」的里程碑節，其 ✅ 被當成進行中章節的（✅ 掃描未端錨定）"; else ok "✅ 掃描節名端錨定（不被標題內的「進行中」三字騙到）"; fi

# 簽章不符：STATUS.md 存在但非 dossier（撞名領域產物，無「進行中」章節）→ flag
cat > "$TMP/ds-work/STATUS.md" <<'DOSSIER'
# 爬蟲設定檢查表

## 站台清單
- site-a
- site-b
DOSSIER
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*簽章" <<< "$out"; then ok "撞名非 dossier → 簽章不符 flag"; else bad "簽章不符未偵測"; fi

# 簽章假陽性防護：恰含「進行中」字樣標題的領域文件仍非 dossier（簽章需雙訊號——
# 誤放行會讓 spec/log 模式直接編輯領域文件，比誤攔截危險）
cat > "$TMP/ds-work/STATUS.md" <<'DOSSIER'
# 部署狀態看板

## 進行中的部署
- api-server v2 rolling update

## 機器清單
- host-a
DOSSIER
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*簽章" <<< "$out"; then ok "僅含進行中字樣標題 → 仍判簽章不符（雙訊號）"; else bad "簽章假陽性：單訊號誤認 dossier"; fi

# 簽章需標題語意錨定：兩個訊號都被「子字串」命中的領域看板（進行中的部署/已完成的部署）
# 仍非 dossier——章節名必須是標題結尾，不是任意子字串
cat > "$TMP/ds-work/STATUS.md" <<'DOSSIER'
# 部署狀態看板

## 進行中的部署
- api-server v2 rolling update

## 已完成的部署
- web v1
DOSSIER
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*簽章" <<< "$out"; then ok "雙訊號皆子字串命中 → 仍判簽章不符（端錨定）"; else bad "簽章假陽性：子字串比對誤認 dossier"; fi

# fenced code block 內的範例標題不算章節
cat > "$TMP/ds-work/STATUS.md" <<'DOSSIER'
# 工具說明文件

```markdown
## 進行中
## 已完成(里程碑)
```

## 使用方式
- 照上面範例寫
DOSSIER
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*簽章" <<< "$out"; then ok "fenced 範例標題 → 仍判簽章不符（剝圍欄）"; else bad "簽章假陽性：fenced 範例標題誤認 dossier"; fi

# 巢狀圍欄（CommonMark：closer 須同字元且長度 ≥ opener）：四反引號外層包三反引號範例，
# 內層 ``` 不得誤判關欄——否則範例標題洩出、簽章誤放行
cat > "$TMP/ds-work/STATUS.md" <<'DOSSIER'
# 工具說明文件

````markdown
範例模板：
```
## 進行中
## 已完成(里程碑)
```
````

## 使用方式
- 照上面範例寫
DOSSIER
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-work")"
if grep -q "dossier-flag:.*簽章" <<< "$out"; then ok "巢狀圍欄範例 → 仍判簽章不符（opener 字元/長度追蹤）"; else bad "簽章假陽性：內層三反引號誤關外層四反引號圍欄"; fi

# 過期：STATUS.md 最後 commit 落後 repo 活動 > 30 天 → flag
# （固定舊日期使 lag 恆 >30 天，不依賴執行當日）
git init -q -b main "$TMP/ds-stale"
(cd "$TMP/ds-stale" \
    && printf '# STATUS\n\n## 進行中\n- 舊項目\n' > STATUS.md \
    && "${GITC[@]}" add STATUS.md \
    && GIT_AUTHOR_DATE='2026-01-01T00:00:00' GIT_COMMITTER_DATE='2026-01-01T00:00:00' \
       "${GITC[@]}" commit -qm "docs: old dossier" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm "feat: recent work" \
    && git init --bare -q -b main "$TMP/ds-stale-origin.git" \
    && git remote add origin "$TMP/ds-stale-origin.git" && git push -qu origin main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/ds-stale")"
if grep -q "dossier-flag:.*落後 repo 活動" <<< "$out"; then ok "STATUS.md 落後 repo 活動 >30 天 → 過期 flag"; else bad "過期未偵測"; fi
