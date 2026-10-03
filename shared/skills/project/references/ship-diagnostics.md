# Project read-only diagnostics

僅 helper 除錯時按需讀取；正常執行以 ship-state 的結果為準，不重新推導。

## Repo / default branch 解析

> 本節與下節〈Branch protection 偵測〉的邏輯已封裝於 `scripts/ship-state.sh`（Step 0/1 單次呼叫，以腳本為可執行權威）；以下逐條指令供除錯、或腳本不可用時的手動 fallback。

```bash
# owner/repo（多 repo：在該 repo 目錄下執行，勿靠 cwd 隱式解析）
repo_slug=$( (cd <repo> && gh repo view --json nameWithOwner -q .nameWithOwner) )    # 如 elandcomtw/krepo
# 或從 remote URL 推（gh 不可用時 fallback）：
git -C <repo> remote get-url origin

# default branch（remote HEAD）
git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null   # 如 origin/main → 取 basename main
# 失敗 fallback：(cd <repo> && gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
# 再 fallback：依序試 main / master（git rev-parse --verify origin/main）
```

## Branch protection 偵測

GitHub 有兩套保護：**classic branch protection** 與**新式 rulesets**，兩者都要查（只看 classic 會漏掉用 ruleset 的 repo）。

```bash
# 先取實際值代入——gh api 只替換 {owner}/{repo}/{branch}，**不認 {default}**；
# 且多 repo 時 {owner}/{repo} 依 cwd 解析會打到錯 repo，故顯式帶 owner/repo 與 default 名。
default=$(git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
[ -z "$default" ] && default=$(for b in main master; do git -C <repo> rev-parse --verify -q "origin/$b" >/dev/null && echo "$b" && break; done)   # symbolic-ref 失敗 → 實際試 origin/main、origin/master（不可留空，否則 endpoint 變 branches//protection；origin 為 canonical remote stand-in，見 `log-prepare.md`「Step 1：逐 repo 狀態 + 流程偵測（先於任何 commit）」）
default_enc=${default//\//%2F}   # default 名含 '/'（如 release/2026，少見）→ encode，否則 endpoint path 會被切錯段
repo_slug=$( (cd <repo> && gh repo view --json nameWithOwner -q .nameWithOwner) )                        # owner/repo（gh 無 -C，用子 shell cd）
# classic：未保護回 404 {"message":"Branch not protected"}；有保護回 200 JSON
classic=$(gh api "repos/$repo_slug/branches/$default_enc/protection" 2>&1)
classic_rc=$?
# ruleset：無規則回 []，有規則回非空陣列
rules=$(gh api "repos/$repo_slug/rules/branches/$default_enc" 2>/dev/null)
```

判定（依序）：
- classic exit 0（200）**或** `rules` 非 `[]` → **protected** → PR 路徑。
- classic 訊息含 `Branch not protected`（404）**且** `rules` == `[]` → **確定無保護** → 直接 push 路徑。
- 其他（403 無權限 / 網路 / 無 gh / 無法分辨）→ **未知 → 視為 protected**（Unknown = protected）。

> 注意：404「Branch not protected」是 GitHub 對「該分支無 classic 保護」的明確回應（即使你是 ADMIN 也是 404），**不是**權限錯誤——要靠訊息字串分辨，別只看 exit code。
> 額外訊號（輔助判斷團隊習慣，非決策依據）：repo 有 `.github/PULL_REQUEST_TEMPLATE*` 或 `CODEOWNERS` → 偏向 PR 流程。
