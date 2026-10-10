#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 8. git-hygiene.sh verdict 判定"
GH_SCRIPT="$ROOT/claude/skills/ready4quit/scripts/git-hygiene.sh"

# fixture：bare origin + clone（有 upstream 的正常 repo）
git init --bare -q -b main "$TMP/gh-origin.git"
git init -q -b main "$TMP/gh-work"
(cd "$TMP/gh-work" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/gh-origin.git" && git push -qu origin main)

out="$("$GH_SCRIPT" "$TMP/gh-work")"
assert_rc "clean repo → exit 0" 0 $?
if grep -q "verdict: CLEAN" <<< "$out"; then ok "clean repo → CLEAN"; else bad "clean repo 未判 CLEAN"; fi

# status 本身失敗時，空 stdout 不能等同 working tree 乾淨。只讓 status 失敗，
# 其餘 Git 操作（包括 fetch）仍使用真 git，避免其他 UNKNOWN 掩蓋這條失敗路徑。
real_hyg_git="$(command -v git)"
mkdir -p "$TMP/hyg-bin"
cat > "$TMP/hyg-bin/git" <<'STUB'
#!/usr/bin/env bash
case " $* " in
    *' status --porcelain -uall '*) echo 'fatal: simulated status failure' >&2; exit 128 ;;
esac
exec "$REAL_HYG_GIT" "$@"
STUB
chmod +x "$TMP/hyg-bin/git"
out="$(PATH="$TMP/hyg-bin:$PATH" REAL_HYG_GIT="$real_hyg_git" "$GH_SCRIPT" "$TMP/gh-work" 2>/dev/null)"
assert_rc "status 失敗 → exit 1" 1 $?
if grep -q 'uncommitted: UNKNOWN' <<< "$out" && grep -q 'verdict: UNKNOWN' <<< "$out"; then
    ok "status 失敗 → 不把空 stdout 當作 CLEAN"
else bad "status 失敗卻未降為 UNKNOWN：$out"; fi

echo dirty > "$TMP/gh-work/untracked.txt"
out="$("$GH_SCRIPT" "$TMP/gh-work")"
assert_rc "untracked 殘留 → exit 1" 1 $?
if grep -q "verdict: RESIDUE" <<< "$out"; then ok "untracked → RESIDUE"; else bad "untracked 未判 RESIDUE"; fi
rm "$TMP/gh-work/untracked.txt"

(cd "$TMP/gh-work" && echo v2 > f.txt && "${GITC[@]}" commit -qam "unpushed change")
out="$("$GH_SCRIPT" "$TMP/gh-work")"
assert_rc "unpushed commit → exit 1" 1 $?
if grep -q "unpushed: 1 commits" <<< "$out"; then ok "unpushed commit 被偵測"; else bad "unpushed commit 未偵測"; fi

# local-only repo（無 remote）→ push 狀態無從判斷 → UNKNOWN，不可當乾淨
git init -q -b main "$TMP/gh-local"
(cd "$TMP/gh-local" && echo x > a.txt && "${GITC[@]}" add a.txt && "${GITC[@]}" commit -qm init)
out="$("$GH_SCRIPT" "$TMP/gh-local")"
assert_rc "local-only repo → exit 1" 1 $?
if grep -q "verdict: UNKNOWN" <<< "$out"; then ok "local-only → UNKNOWN（不判 CLEAN）"; else bad "local-only 未判 UNKNOWN"; fi

out="$("$GH_SCRIPT" "$TMP/not-a-repo")"
assert_rc "非 git repo → exit 1" 1 $?
if grep -q "verdict: UNKNOWN" <<< "$out"; then ok "非 repo → UNKNOWN"; else bad "非 repo 未判 UNKNOWN"; fi

"$GH_SCRIPT" >/dev/null 2>&1
assert_rc "無引數 → exit 2" 2 $?

# untracked 目錄須展開到檔案層級：porcelain 預設折疊成 "?? dir/"，殘留規模被低估、
# 檔名看不到（review-state.sh 同源前例）。命中點放輸入前段以免斷言被截斷路徑架空。
mkdir -p "$TMP/gh-work/newdir/sub"
: > "$TMP/gh-work/newdir/a.txt"
: > "$TMP/gh-work/newdir/sub/b.txt"
out="$("$GH_SCRIPT" "$TMP/gh-work")"
if grep -q "newdir/a.txt" <<< "$out" && grep -q "newdir/sub/b.txt" <<< "$out"; then
    ok "untracked 目錄展開到檔案層級"
else bad "untracked 目錄未展開（porcelain 折疊成 ?? dir/）"; fi
assert_eq "untracked 計數為展開後檔數" "uncommitted: 2 檔" \
    "$(grep -o 'uncommitted: [0-9]* 檔' <<< "$out")"
rm -rf "$TMP/gh-work/newdir"

# (h) fetch 的 remote 必須涵蓋 baseline 實際所屬的 remote。branch.<n>.remote 指向 other
#     （且沒設 branch.<n>.merge，@{upstream} 因此解析不到）時 baseline 會 fallback 到
#     origin/*——只 fetch other 就讓 stale 的 origin ref 過關，等於拿 A 的新鮮度替 B 背書
git init --bare -q -b main "$TMP/mx-origin.git"
git init --bare -q -b main "$TMP/mx-other.git"
git init -q -b main "$TMP/mx-work"
(cd "$TMP/mx-work" \
    && echo a > f && "${GITC[@]}" add f && "${GITC[@]}" commit -qm c1 \
    && git remote add origin "$TMP/mx-origin.git" && git remote add other "$TMP/mx-other.git" \
    && git push -q origin main && git push -q other main \
    && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
    && git config branch.main.remote other \
    && echo b >> f && "${GITC[@]}" commit -qam c2 && git push -q origin main)
git -C "$TMP/mx-origin.git" update-ref refs/heads/main "$(git -C "$TMP/mx-work" rev-parse HEAD~1)"
assert_eq "fixture 前置：origin 端已 rewind，本機 HEAD 不在遠端" \
    "1" "$(git -C "$TMP/mx-work" rev-list --count "$(git -C "$TMP/mx-origin.git" rev-parse main)..HEAD" 2>/dev/null)"
out="$("$GH_SCRIPT" "$TMP/mx-work")"
if grep -q "verdict: CLEAN" <<< "$out"; then
    bad "fetch 的 remote 與 baseline 的不一致，stale origin ref 過關判 CLEAN：$out"
else ok "baseline 所屬 remote 一併 fetch → 不再誤判 CLEAN"; fi

# 成功 fetch remote 不代表 baseline ref 已刷新：自訂 remote.origin.fetch 只涵蓋
# keep，origin/main 被遠端刪除後，fetch --prune keep 不會刪掉 stale origin/main。
git init --bare -q -b main "$TMP/refspec-origin.git"
git init -q -b main "$TMP/refspec-work"
(cd "$TMP/refspec-work" \
    && echo hi > f && "${GITC[@]}" add f && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/refspec-origin.git" && git push -qu origin main)
refspec_head="$(git -C "$TMP/refspec-work" rev-parse HEAD)"
git -C "$TMP/refspec-origin.git" update-ref refs/heads/keep "$refspec_head"
git -C "$TMP/refspec-origin.git" update-ref -d refs/heads/main
git -C "$TMP/refspec-work" config --replace-all remote.origin.fetch \
    '+refs/heads/keep:refs/remotes/origin/keep'
out="$("$GH_SCRIPT" "$TMP/refspec-work")"
assert_rc "fetch refspec 漏刷 baseline → exit 1" 1 $?
if grep -q 'unpushed: UNKNOWN' <<< "$out" && ! grep -q 'verdict: CLEAN' <<< "$out"; then
    ok "fetch 成功但 baseline ref 未涵蓋 → 不判 CLEAN"
else bad "stale baseline ref 在自訂 fetch refspec 下誤判 CLEAN：$out"; fi

# upstream feature 本身新鮮，也不能用漏刷的 origin/main 判「相對 default 無 commit」。
# 先讓遠端 main 到 feature head、正常 fetch，再由遠端 rewind，留下真實的 stale ref。
git init --bare -q -b main "$TMP/refspec-pr-origin.git"
git init -q -b main "$TMP/refspec-pr-work"
(cd "$TMP/refspec-pr-work" \
    && echo a > f && "${GITC[@]}" add f && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/refspec-pr-origin.git" && git push -qu origin main)
refspec_base="$(git -C "$TMP/refspec-pr-work" rev-parse HEAD)"
(cd "$TMP/refspec-pr-work" \
    && git switch -qc feat/refspec && echo b >> f \
    && "${GITC[@]}" commit -qam feature && git push -qu origin feat/refspec)
refspec_feature="$(git -C "$TMP/refspec-pr-work" rev-parse HEAD)"
git -C "$TMP/refspec-pr-origin.git" update-ref refs/heads/main "$refspec_feature"
git -C "$TMP/refspec-pr-work" fetch -q origin
git -C "$TMP/refspec-pr-origin.git" update-ref refs/heads/main "$refspec_base" "$refspec_feature"
git -C "$TMP/refspec-pr-work" config --replace-all remote.origin.fetch \
    '+refs/heads/feat/refspec:refs/remotes/origin/feat/refspec'
out="$("$GH_SCRIPT" "$TMP/refspec-pr-work")"
assert_rc "fetch refspec 漏刷 PR default → exit 1" 1 $?
if grep -q 'pr: UNKNOWN' <<< "$out" && ! grep -q 'verdict: CLEAN' <<< "$out"; then
    ok "feature upstream 新鮮但 default ref 過期 → PR 不判 n/a/CLEAN"
else bad "stale default ref 架空 PR 檢查：$out"; fi

# git-hygiene 的 gh stub：只回應 `pr view`。腳本取 url,state,isDraft 三欄（tsv），
# 因為只讀 url 會把 CLOSED（未合併就關掉）與 draft 都當成「已有 PR、無殘留」
make_hyg_gh_stub() {  # <path> <nopr|authfail|open|draft|closed|merged> [headRefOid]
    case "$2" in
        nopr)
            cat > "$1" <<'STUB'
#!/usr/bin/env bash
echo 'no pull requests found for branch "feat/y"' >&2
exit 1
STUB
            ;;
        authfail)
            cat > "$1" <<'STUB'
#!/usr/bin/env bash
echo 'HTTP 401: Bad credentials (https://api.github.com/graphql)' >&2
exit 1
STUB
            ;;
        open)
            cat > "$1" <<'STUB'
#!/usr/bin/env bash
printf 'OPEN\tfalse\thttps://github.com/acme/widget/pull/7\n'
STUB
            ;;
        draft)
            cat > "$1" <<'STUB'
#!/usr/bin/env bash
printf 'OPEN\ttrue\thttps://github.com/acme/widget/pull/8\n'
STUB
            ;;
        closed)
            cat > "$1" <<'STUB'
#!/usr/bin/env bash
printf 'CLOSED\tfalse\thttps://github.com/acme/widget/pull/9\n'
STUB
            ;;
        merged)
            # 第 4 欄 headRefOid = PR 合併當下的 head；用它區分「squash 前的原始 commit」
            # 與「合併之後才寫的 commit」——後者是真殘留。
            # sha 由外部檔案供給，同一支 stub 才能服務多個情境（各自寫入不同的 head）
            cat > "$1" <<STUB
#!/usr/bin/env bash
printf 'MERGED\tfalse\thttps://github.com/acme/widget/pull/10\t%s\n' "\$(cat '${3:-/dev/null}' 2>/dev/null)"
STUB
            ;;
    esac
    chmod +x "$1"
}
make_hyg_gh_stub "$TMP/hyg-gh-nopr" nopr
make_hyg_gh_stub "$TMP/hyg-gh-authfail" authfail
make_hyg_gh_stub "$TMP/hyg-gh-open" open
make_hyg_gh_stub "$TMP/hyg-gh-draft" draft
make_hyg_gh_stub "$TMP/hyg-gh-closed" closed
: > "$TMP/hyg-head-oid"        # merged stub 讀這個檔取得 headRefOid
make_hyg_gh_stub "$TMP/hyg-gh-merged" merged "$TMP/hyg-head-oid"

# fixture：feature branch 已 push 到 origin/feat/y 但**未設 upstream**（tree clean）
git init --bare -q -b main "$TMP/gh-b4-origin.git"
git init -q -b main "$TMP/gh-b4"
(cd "$TMP/gh-b4" \
    && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/gh-b4-origin.git" && git push -qu origin main \
    && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
    && git switch -qc feat/y && echo v2 > f.txt && "${GITC[@]}" commit -qam "feat: y" \
    && git push -q origin feat/y)

# commit 已在 remote，退用 origin/<default> 當 baseline 會誤報「未 push」
out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-nopr" "$GH_SCRIPT" "$TMP/gh-b4")"
if grep -q "unpushed: none" <<< "$out"; then
    ok "已 push 到 origin/<branch> 但無 upstream → 不誤報 unpushed"
else bad "無 upstream 的已 push branch 被誤報 unpushed"; fi

# gh 執行失敗 ≠ 沒有 PR：兩者都 exit 1，吞掉 stderr 就分不出來（腳本檔頭設計原則）
if grep -q "pr: MISSING" <<< "$out"; then ok "gh 明示無 PR → MISSING"; else bad "真無 PR 未判 MISSING"; fi

out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-authfail" "$GH_SCRIPT" "$TMP/gh-b4")"
if grep -q "pr: UNKNOWN" <<< "$out" && ! grep -q "pr: MISSING" <<< "$out"; then
    ok "gh 認證失敗 → UNKNOWN（不誤報 MISSING）"
else bad "gh 認證失敗被誤判成無 PR"; fi
if grep -q "401" <<< "$out"; then ok "UNKNOWN 附 gh 失敗原因"; else bad "UNKNOWN 未印失敗原因"; fi
if grep -q "verdict: UNKNOWN" <<< "$out"; then ok "gh 失敗 → verdict UNKNOWN"; else bad "gh 失敗 verdict 錯誤"; fi

out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-open" "$GH_SCRIPT" "$TMP/gh-b4")"
if grep -q "pull/7" <<< "$out"; then ok "OPEN PR → 印出 URL"; else bad "OPEN PR 未印 URL"; fi
if grep -q "verdict: CLEAN" <<< "$out"; then ok "已 push + OPEN PR → CLEAN"; else bad "已 push + OPEN PR 未判 CLEAN"; fi

# PR 存在不等於變更送得出去：只讀 url 會把下面三種都當成「有 PR、無殘留」
out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-draft" "$GH_SCRIPT" "$TMP/gh-b4")"
if grep -q "DRAFT" <<< "$out" && grep -q "verdict: RESIDUE" <<< "$out"; then
    ok "draft PR → 標 DRAFT 且判 RESIDUE"
else bad "draft PR 被當成完備的 PR：$out"; fi

out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-closed" "$GH_SCRIPT" "$TMP/gh-b4")"
if grep -q "CLOSED" <<< "$out" && grep -q "verdict: RESIDUE" <<< "$out"; then
    ok "CLOSED PR（未合併）→ 標 CLOSED 且判 RESIDUE"
else bad "CLOSED PR 被當成已送出：$out"; fi

# MERGED 反過來不算殘留——squash merge 後 branch 的 commit 不在 default 歷史裡，
# 相對 default 仍「未併」但東西已經進去了，只是 branch 可以清掉
git -C "$TMP/gh-b4" rev-parse HEAD > "$TMP/hyg-head-oid"   # 合併後沒有新 commit
out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-merged" "$GH_SCRIPT" "$TMP/gh-b4")"
if grep -q "MERGED" <<< "$out"; then ok "MERGED PR → 標 MERGED"; else bad "MERGED PR 未標示：$out"; fi
if grep -q "verdict: RESIDUE" <<< "$out"; then bad "MERGED PR 誤判 RESIDUE：$out"; else ok "MERGED PR → 不算殘留"; fi

# --- remote 事實 vs 本機 cache：unpushed 判定不能只信 remote-tracking ref ---

# (a) 遠端 branch 被刪掉，本機 origin/feat/y 仍指向 HEAD → 未 fetch 會誤報「已送出」
git -C "$TMP/gh-b4-origin.git" update-ref -d refs/heads/feat/y
rm -f "$TMP/gh-b4/.git/FETCH_HEAD"
out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-nopr" "$GH_SCRIPT" "$TMP/gh-b4")"
if grep -q "unpushed: none" <<< "$out"; then
    bad "遠端 branch 已刪除仍報 unpushed: none（stale tracking ref 被當成遠端事實）"
else ok "遠端 branch 已刪除 → 不再報 unpushed: none"; fi
if grep -q "verdict: CLEAN" <<< "$out"; then
    bad "遠端 branch 已刪除仍判 CLEAN：$out"
else ok "遠端 branch 已刪除 → 不判 CLEAN"; fi

# (b) fetch 跑不動（remote 壞掉）→ remote 狀態無從得知，只能 UNKNOWN，絕不可 CLEAN
git -C "$TMP/gh-b4" remote set-url origin "$TMP/nonexistent-origin.git"
rm -f "$TMP/gh-b4/.git/FETCH_HEAD"
out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-nopr" "$GH_SCRIPT" "$TMP/gh-b4")"
if grep -q "verdict: CLEAN" <<< "$out"; then
    bad "fetch 失敗仍判 CLEAN（把本機 cache 當遠端事實）：$out"
else ok "fetch 失敗 → 不判 CLEAN"; fi
if grep -q "unpushed: UNKNOWN" <<< "$out"; then
    ok "fetch 失敗 → unpushed 標 UNKNOWN"
else bad "fetch 失敗未把 unpushed 標 UNKNOWN：$out"; fi

# (c) 多 remote：fetch 別的 remote 不算「baseline 那個 remote 已同步」。
#     FETCH_HEAD 是 repo-global 的，拿它的 mtime 當新鮮度會讓 origin 的 stale ref
#     從側門被當成新鮮——正是本節其餘測試想擋的失效模式
git init --bare -q -b main "$TMP/mr-origin.git"
git init --bare -q -b main "$TMP/mr-other.git"
git init -q -b main "$TMP/mr-work"
(cd "$TMP/mr-work" \
    && echo a > f && "${GITC[@]}" add f && "${GITC[@]}" commit -qm c1 \
    && git remote add origin "$TMP/mr-origin.git" && git remote add other "$TMP/mr-other.git" \
    && git push -q origin main && git push -q other main \
    && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
    && echo b >> f && "${GITC[@]}" commit -qam c2 && git push -q origin main)
# origin 端 rewind 掉 c2（force-push 情境），本機 origin/main 仍指向 c2
mr_first="$(git -C "$TMP/mr-work" rev-parse HEAD~1)"
git -C "$TMP/mr-origin.git" update-ref refs/heads/main "$mr_first"
git -C "$TMP/mr-work" fetch -q other      # 只碰 other，卻會更新 repo-global FETCH_HEAD
out="$("$GH_SCRIPT" "$TMP/mr-work")"
if grep -q "verdict: CLEAN" <<< "$out"; then
    bad "fetch 別的 remote 後仍判 CLEAN（freshness 未綁 remote）：$out"
else ok "多 remote：fetch other 不會讓 origin 的 stale ref 過關"; fi

# (d) squash merge 後 remote branch 被刪：commit 已經以 squash 形式進了 default，
#     baseline 退回 default 會把它們算成「未 push」——PR 是 MERGED 時不該計入殘留
#     fixture 名前綴 hyg-：第 9 節（ship-state）另有一組同語意的 sq-work/sq-origin，
#     兩節共用 $TMP，撞名會讓後建的那組 `git init` 落在既有 repo 上（re-init + remote
#     already exists），fixture 靜默不成立、斷言整批假紅。前綴是唯一防線，勿改回裸 sq-。
git init --bare -q -b main "$TMP/hyg-sq-origin.git"
git init -q -b main "$TMP/hyg-sq-work"
(cd "$TMP/hyg-sq-work" \
    && echo a > f && "${GITC[@]}" add f && "${GITC[@]}" commit -qm c1 \
    && git remote add origin "$TMP/hyg-sq-origin.git" && git push -q origin main \
    && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
    && git switch -qc feat/sq && echo b > g && "${GITC[@]}" add g && "${GITC[@]}" commit -qm "feat: sq" \
    && git push -q origin feat/sq)
git -C "$TMP/hyg-sq-origin.git" update-ref -d refs/heads/feat/sq   # merge 後刪 remote branch
git -C "$TMP/hyg-sq-work" rev-parse HEAD > "$TMP/hyg-head-oid"     # PR 合併當下的 head = 現在的 HEAD
out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-merged" "$GH_SCRIPT" "$TMP/hyg-sq-work")"
if grep -q "verdict: RESIDUE" <<< "$out"; then
    bad "MERGED + remote branch 已刪仍判 RESIDUE（與『MERGED 不算殘留』矛盾）：$out"
else ok "MERGED + remote branch 已刪 → 不判 RESIDUE"; fi

# (f) MERGED 不可掩蓋「合併之後才寫的 commit」——那些是真殘留。
#     撤銷的依據必須是 PR 的 headRefOid，不能因為 state=MERGED 就整批清掉
(cd "$TMP/hyg-sq-work" && echo after > after.txt && "${GITC[@]}" add after.txt \
    && "${GITC[@]}" commit -qm "feat: 合併後才寫的")
# headRefOid 仍停在 PR 合併當下那顆（上一行的新 commit 不在其中）
out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-merged" "$GH_SCRIPT" "$TMP/hyg-sq-work")"
if grep -q "verdict: RESIDUE" <<< "$out"; then
    ok "MERGED 後新增的 commit → 仍判 RESIDUE"
else bad "MERGED 掩蓋了合併後新增的 commit（假 CLEAN）：$out"; fi

# headRefOid 拿不到時必須保守：不可撤銷（寧可誤報殘留，不可誤報乾淨）
: > "$TMP/hyg-head-oid"
out="$(GIT_HYGIENE_GH="$TMP/hyg-gh-merged" "$GH_SCRIPT" "$TMP/hyg-sq-work")"
if grep -q "verdict: CLEAN" <<< "$out"; then
    bad "headRefOid 不可得時仍撤銷 unpushed（假 CLEAN）：$out"
else ok "headRefOid 不可得 → 保守不撤銷"; fi

# (e) fetch 必須有硬上限：本機可能沒有 timeout/gtimeout，不能靠外部指令
#     ext:: transport 直接執行指令當 transport，是純本地製造「fetch 卡住」的可靠方法
git init -q -b main "$TMP/slow-work"
(cd "$TMP/slow-work" \
    && git config protocol.ext.allow always \
    && echo a > f && "${GITC[@]}" add f && "${GITC[@]}" commit -qm c1 \
    && git remote add origin "ext::sleep 30")
slow_start="$(date +%s)"
out="$(GIT_HYGIENE_FETCH_TIMEOUT=2 "$GH_SCRIPT" "$TMP/slow-work" 2>/dev/null)"
slow_elapsed=$(( $(date +%s) - slow_start ))
#     界線由契約推導，不是拍腦袋的寬鬆值：每個 fetch 目標最多 FETCH_TIMEOUT + KILL_GRACE
#     秒，本 fixture 只有 origin 一個目標 → 2+1=3s，再給 3s 餘裕吸收 process 啟動（實測 2s）。
#     放寬到十幾秒等於讓「每個 repo 卡 10 秒」的 regression 照樣綠，多 repo 時還會累加。
#     改 fixture 的 remote 數時照 (timeout+grace)×目標數 重算，不要直接調大這個數字。
slow_budget=6
if [ "$slow_elapsed" -lt "$slow_budget" ]; then
    ok "fetch 卡住 → 在上限內放棄（實測 ${slow_elapsed}s，界線 ${slow_budget}s）"
else bad "fetch 卡住未被中斷（${slow_elapsed}s ≥ ${slow_budget}s，宣告的上限不存在）"; fi
if grep -q "remote: UNKNOWN" <<< "$out"; then
    ok "fetch 逾時 → remote 標 UNKNOWN"
else bad "fetch 逾時未標 remote UNKNOWN：$out"; fi

# (g) fetch 成功時不可還等滿 timeout：watchdog 的 sleep 若持有輸出 pipe，
#     command substitution 會等到它結束才收到 EOF——每個 repo 都固定耗掉整個上限
fast_start="$(date +%s)"
out="$(GIT_HYGIENE_FETCH_TIMEOUT=6 "$GH_SCRIPT" "$TMP/gh-work" 2>/dev/null)"
fast_elapsed=$(( $(date +%s) - fast_start ))
if [ "$fast_elapsed" -lt 4 ]; then
    ok "本地 remote fetch 成功 → 立刻返回（實測 ${fast_elapsed}s，上限 6s）"
else bad "fetch 成功仍等滿 watchdog timeout（${fast_elapsed}s）"; fi

# (i) 多 repo 單次呼叫：`claude/skills/project/references/log-workflow.md`「Step 0：範圍鎖定」要求一次帶完所有 session repo。彙總有兩個失效
#     方向——漏印某個 repo 的區段，或讓某個 repo 的 RESIDUE/UNKNOWN 被另一個的 CLEAN
#     蓋掉（exit 0 = 全 CLEAN，是使用者唯一會看的那個數字）。此前所有呼叫都是單 repo，
#     聚合迴圈與 overall exit code 完全沒有覆蓋。
git init --bare -q -b main "$TMP/mrepo-o1.git"
git init --bare -q -b main "$TMP/mrepo-o2.git"
git init -q -b main "$TMP/mrepo-clean"
(cd "$TMP/mrepo-clean" && echo a > a.txt && "${GITC[@]}" add a.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/mrepo-o1.git" && git push -q -u origin main)
git init -q -b main "$TMP/mrepo-residue"
(cd "$TMP/mrepo-residue" && echo a > a.txt && "${GITC[@]}" add a.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/mrepo-o2.git" && git push -q -u origin main \
    && echo wip > untracked.txt)
git init -q -b main "$TMP/mrepo-unknown"
(cd "$TMP/mrepo-unknown" && echo a > a.txt && "${GITC[@]}" add a.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/mrepo-nonexistent.git")

# 前置：三個 repo 單獨跑時各自是 CLEAN / RESIDUE / UNKNOWN——沒有這條，下面的彙總
# 斷言可能只是因為 fixture 根本沒造出三種狀態而「剛好對」
for mrepo_case in "clean:CLEAN" "residue:RESIDUE" "unknown:UNKNOWN"; do
    mrepo_name="${mrepo_case%%:*}"; mrepo_want="${mrepo_case##*:}"
    mrepo_one="$(GIT_HYGIENE_GH=/usr/bin/false "$GH_SCRIPT" "$TMP/mrepo-${mrepo_name}" 2>/dev/null)"
    if grep -q "verdict: ${mrepo_want}" <<< "$mrepo_one"; then
        ok "fixture 前置：mrepo-${mrepo_name} 單獨跑為 ${mrepo_want}"
    else bad "fixture 前置不成立：mrepo-${mrepo_name} 不是 ${mrepo_want}：$mrepo_one"; fi
done

# CLEAN 排最前面：先看到 CLEAN 不能讓後面的殘留被吞掉
mrepo_out="$(GIT_HYGIENE_GH=/usr/bin/false "$GH_SCRIPT" \
    "$TMP/mrepo-clean" "$TMP/mrepo-residue" "$TMP/mrepo-unknown" 2>/dev/null)"
mrepo_rc=$?
assert_rc "多 repo：任一 RESIDUE/UNKNOWN → exit 1" 1 "$mrepo_rc"
mrepo_sections="$(grep -c '^=== ' <<< "$mrepo_out")"
assert_eq "多 repo：三個 repo 的區段都印出（不漏 repo）" "3" "$mrepo_sections"
assert_eq "多 repo：verdict 逐 repo 各自成立（1 CLEAN / 1 RESIDUE / 1 UNKNOWN）" \
    "1 1 1" \
    "$(grep -c 'verdict: CLEAN' <<< "$mrepo_out") $(grep -c 'verdict: RESIDUE' <<< "$mrepo_out") $(grep -c 'verdict: UNKNOWN' <<< "$mrepo_out")"

# CLEAN 排最後面：反方向再測一次，擋「用最後一個 repo 的結果覆寫 overall」這種寫法
mrepo_out="$(GIT_HYGIENE_GH=/usr/bin/false "$GH_SCRIPT" \
    "$TMP/mrepo-residue" "$TMP/mrepo-unknown" "$TMP/mrepo-clean" 2>/dev/null)"
mrepo_rc=$?
assert_rc "多 repo：CLEAN 排最後仍 exit 1（overall 不被最後一個覆寫）" 1 "$mrepo_rc"

# 全 CLEAN 才是 exit 0——否則上面兩條可能只是「永遠回 1」
mrepo_out="$(GIT_HYGIENE_GH=/usr/bin/false "$GH_SCRIPT" "$TMP/mrepo-clean" "$TMP/mrepo-clean" 2>/dev/null)"
mrepo_rc=$?
assert_rc "多 repo：全部 CLEAN → exit 0" 0 "$mrepo_rc"
