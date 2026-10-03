# Project shipping 例外處置

只有 workflow 列出的條件成立才先完整讀本檔；不是一般 Log prerequisite。
授權仍以 [ship-policy.md](ship-policy.md) 為準，正常送出見 [ship-paths.md](ship-paths.md)。

## Bootstrap：全新空 repo 的第一次 ship

**唯一觸發來源**：`ship-state.sh` 印 `verdict: BOOTSTRAP`。遠端零 branch 只是第一個必要條件；腳本還會驗
intended default、local baseline ancestry 與 effective creation policy。任何其他來源——使用者說「這是新
repo」、上一輪對話的授權、你自己的推論——都**不構成** bootstrap。

為什麼此處是例外：遠端還沒有 default branch，**沒有既有 default 可走 PR**。而 GitHub 以**第一個被 push
的 branch** 為 default branch；因此不能把「remote 空」解成「目前 HEAD 可推」，只能推 target authority 指向的
intended default。GitHub adapter 取 repository metadata 與 `rules/branches/<intended>` 的 effective rules；
provider 不支援、403、schema 不明、creation restriction，或 required check/workflow 未豁免 create 都 STOP。
先讀 target root contract；它與 provider metadata 衝突時先 STOP，以確認型問題列出兩個來源與 branch，使用者
選定後才把答案傳給 `ship-state.sh --bootstrap-default <name> <repo>`。該 flag 是當輪 explicit evidence，
不是讓 agent 靜默覆蓋 metadata 的 escape hatch。

若 intended-default local ref 不存在，Project 必須依 Runtime adapter 提出確認型選項，第一項是安全預設：

1. 暫停並先整理 baseline。
2. 以畫面列出的目前 HEAD full SHA 作 baseline（明說：全部現有內容會直接成為初始 default）。
3. 指定畫面列出的 ancestor commit/ref；沒有候選才收自由輸入。

只有當輪回答能選 baseline；不得從 `init.defaultBranch`、branch 名慣例或上一輪回答補值。選定後照抄
`bootstrap-baseline.sh <repo> <intended-default> <commit/ref>`；它只建立 local ref、不切 branch、不 push。
隨即以 `ship-state.sh --bootstrap-default <intended-default> <repo>` 重跑；仍只有它能發出 `BOOTSTRAP`。

```bash
# 1. 照抄 ship-state.sh 的 bootstrap-cmd（repo / remote / intended-default 已填好）
git -C <repo> push -u origin <local-default>
# 2. baseline 建立後重跑偵測：BOOTSTRAP 應已消失，protection / branch-first 回到正常判定
<project-scripts>/ship-state.sh <repo>
```

- **仍走 Step 4 硬 gate**：摘要須明列「此 push 將決定遠端 default branch = `<branch>`」再等確認。
- **The exemption covers exactly this one push — creating the baseline.** It expires the moment the baseline exists; every later commit goes through a feature branch, rules unchanged. The script stops printing the verdict on its own, so re-check it — never carry the exemption forward from memory or from an earlier turn's authorization.
- 拿到的是 `verdict: STOP`（遠端有 branch、authority／policy／baseline 不完整、`ls-remote` 失敗、detached
  HEAD）→ **NOT bootstrap**：照訊息或確認選項處理，**絕不**改推目前 branch。

## gh 帳號權限 vs git push 身分（身分分離）

protection classic 回 **`Not Found`**（非 `Branch not protected`）常代表 **gh 帳號對該 repo 沒有 admin/read-protection 權限**（GitHub 對非 admin 隱藏 protection 狀態），而**不是**「無保護」。此時 `gh repo view --json viewerPermission` 多半是 `READ`。

關鍵：**gh 帳號的權限 ≠ git push 用的身分**。git remote 走 SSH（如 `git@github.com:org/repo`）時，push 用的是 **SSH key 對應的 GitHub 身分**，可能與 gh CLI 登入的帳號**不同**——常見「gh 帳號 READ（開不了 PR / 讀不到 protection）、但 SSH key 有 WRITE（推得動）」。

偵測到此情境時：
1. `gh repo view "$repo_slug" --json viewerPermission -q .viewerPermission`（多 repo：repo 用 **positional 引數**綁定——`gh repo view` **不吃 `-R`**，與 `gh pr` / `gh api` 不同）→ 若 `READ` 且 protection 回 `Not Found` → **主動向使用者點明身分分離**（別假設無權限就停、也別假設無保護就直推）。
2. **用 `git push --dry-run` 探實際 push 權限**（`--dry-run` 不傳資料、不改 remote，**不算 Critical / Step 4 所指的 push**，無需事先確認）：
   ```bash
   git -C <repo> push --dry-run -u origin <branch> 2>&1
   # 成功印 "[new branch] ... -> ..." / "Would set upstream" → SSH 身分有 write
   # 403 / "permission denied" → 無 write
   ```
3. **檢查 gh 是否已登入其他有權帳號**：`gh auth status` 會列出**所有**已登入帳號（active 只有一個）——若另一已登入帳號對該 repo 有 write（如個人 repo 的 owner 本尊、active 卻是工作帳號），`gh auth switch -u <有權帳號>` 後執行 gh 操作（`pr create`／merge 最後一哩），**用完切回原 active 帳號**（實證：active 帳號 READ 時 `gh pr create` 吃 `must be a collaborator`，switch 到已登入的 owner 帳號即通）。
4. 把「protection 無法判定 + dry-run 的 push 權限結果」一併放進 Step 4 ship 摘要，讓使用者定奪：開 PR、換身分、或（若使用者選擇直推）**由使用者自行 push**。**agent 端預設 PR、不自行 push default branch**（Unknown=protected，見下方 ⚠）。**仍不在確認前實際 push。**

> ⚠ **不可**把「硬推會被 remote 擋（無害）」當作直推 default branch 的理由：protection 對 gh 不可見（gh 帳號 READ）但分支實際無保護的 repo（SSH 身分有 write）下，硬推會**成功**，正中 `Unknown = protected` 要防的破口（見 `pressure-tests.md` Scenario 4）。所以「protection 未知 + 使用者要直推」→ **agent 不自行 push default branch**：停下、向使用者點明身分分離與 protection 不可判定，由**使用者自行**執行 push，或明確改走 PR 路徑。

## Branch-first 與誤 commit 搬移

> 本節序列已封裝於 `scripts/branch-first.sh`（情況 A/B 自動判定、前置檢查全過才動、porcelain 前後快照驗證，以腳本為可執行權威——`log-prepare.md`「Step 1：逐 repo 狀態 + 流程偵測（先於任何 commit）」要求整行照抄呼叫）；以下逐條指令供除錯、或腳本 `verdict: STOP` 後人工處理時參照。

**情況 A：變更在 working tree（人在 default branch），或在 detached HEAD（含已在其上 commit）**
```bash
git -C <repo> switch -c <feature-branch>   # working-tree 變更與 detached HEAD 上的 commit 都跟著切過去；default branch 不動
```

**情況 B：變更已誤 commit 在本地 default branch（未 push）**
```bash
# 先用 feature branch 保住 commit，再把 default branch 退回 origin
git -C <repo> branch <feature-branch>            # 在當前 HEAD 建 branch（保住 commit）
git -C <repo> switch <feature-branch>
git -C <repo> branch -f <default> origin/<default>   # 本地 default 退回 remote（commit 只留在 feature branch）
# 注意：branch -f 不能對當前 branch 用，故先 switch 到 feature branch 再 -f default
```

branch 名先遵循 target repo contract；沒有規定時，slug 由變更語意產生（kebab-case，如
`feat/mops-announce-backfill`），type ∈ feat/fix/refactor/docs/chore/test。

## 送出前的 branch 內 squash（Step 4 選了「先 squash 再送出」時）

**只壓 review 迭代痕跡，不動獨立語意的 commit**——與 deep-review 收尾同一條原則（語意 commit 在 PR 裡逐顆可讀，有參照價值）。

**reset 目標一律照抄 `log-prepare.md`「Step 1：逐 repo 狀態 + 流程偵測（先於任何 commit）」中 `ship-state.sh` 記下的那一行，NEVER recompute it, NEVER pick a hash by eyeballing `git log`**——它是**使用者語意 commit 的邊界**（Step 1 跑在 Step 3 之前，此刻 HEAD 之上還沒有本流程自己的 commit）。**Step 3 一旦產生 commit**，套用當下重跑就會讓 verdict 形狀翻轉（頂端連續段歸零），現場只剩會壓掉語意 commit 的全壓指令（實測見同節「Review 痕跡」）。判「哪顆是 review 迭代痕跡」需要 deep-review 的權威 subject 清單（理由同前），挑錯就是把使用者的語意 commit 一起壓掉。

| 使用者在 Step 4 選的 | 照抄哪一行 | 結果 |
|---|---|---|
| 壓掉頂端那段 review 痕跡 | `squash-cmd:` | 語意 commit 原樣保留 |
| 整支壓成一顆（僅在使用者明確要求時） | `squash-all-cmd:` | **連語意 commit 一起收**，選項文案須已講明。**該行只在有 `buried:` 時才印**——沒有 buried 卻臨時要全壓，現場無行可抄 → 照本節末條「目標拿不準就不要壓」，回報現況讓使用者定奪 |

```bash
# 0. branch 已 push 過才需要。**先 fetch 那支 branch**——下面兩步都讀 remote-tracking ref，
#    而它不會自己更新：不 fetch 就是拿舊資料做安全判斷，協作者剛推的 commit 看不見，
#    ancestry 檢查會放行、reset 照跑，一路到 push 才被 lease 擋下——那時本地歷史已經重寫。
git -C <toplevel> fetch origin <feature-branch>

# 錨定遠端當下的 SHA（Step 5 的 lease 要用）。**錨定之後值就固定了**，此後流程再怎麼
# fetch（commit 計數、cleanup 的 --prune）都不影響它——這正是帶 expected SHA 的用意。
git -C <toplevel> rev-parse origin/<feature-branch>    # ← 記下這個值

# 確認遠端沒有你沒有的東西。判準是**祖先關係、不是 SHA 相等**——push 之後又加了
# review fix / docs commit 是正常狀態，本地領先本來就會讓 SHA 不同。
git -C <toplevel> merge-base --is-ancestor origin/<feature-branch> HEAD
# 非 0 → **停下**：遠端 tip 不在本地歷史裡（協作者推過），squash + force-push 會覆蓋掉它們。
# **這一步的價值全靠上面那次 fetch**——沒 fetch 的話它檢查的是本地舊快照，等於沒檢查。

# 1. reset 到腳本給的 hash（整行照抄，勿自行改寫路徑或 hash）
git -C <toplevel> reset --soft <腳本給的 hash>

# 2. 重新 commit。message 要同時涵蓋「這批 review 修復」與「本輪文檔同步」——本輪 Step 3
#    產生的 commit 位於 reset 目標之上，會一併被收進這顆；不沿用被保留 commit 的 subject。
#    附環境指定的 Co-Authored-By trailer，同 Step 3 的規則。
git -C <toplevel> commit -m "<符合 target repo convention 的語意描述>

<Co-Authored-By trailer，取 runtime system prompt 的 Git 區塊>"
```

> `review-anchor.sh squash-cmd` **不是這裡的來源**——portable deep-review 不以 review commits／squash
> 編排 autofix；該 helper 只保留給舊 review recovery。送出前的 squash 邊界一律取本流程 Step 1
> 記下的 `ship-state.sh` 輸出。

**本節到 commit 為止，不含任何 push。** branch 已 push 過時，覆寫 remote 需要 `--force-with-lease`——**那是 Step 5 的送出動作**，必須等重印摘要、使用者再次確認後才做（`git -C <repo> push --force-with-lease=<feature-branch>:<步驟 0 記下的 SHA> origin <feature-branch>`——**帶 expected SHA，理由見下**）。在這裡順手推掉，等於用 gate 沒顯示過的 commit set 重寫 remote，正是 Step 4 硬 gate 要防的事。

- **`--force-with-lease`, NEVER `--force`** —— 前者在 remote 有他人新 commit 時會拒絕，後者直接蓋掉。
- **一律帶 expected SHA：`--force-with-lease=<feature-branch>:<步驟 0 記下的 SHA>`**。裸的 `--force-with-lease` 比對的是本地 remote-tracking ref，而**本流程自己就會 fetch**（本節步驟 0 的 `fetch origin <feature-branch>`、`cleanup-cmd` 的 `fetch --prune`）——fetch 一跑，tracking ref 就更新成遠端的新狀態，lease 檢查形同虛設，協作者剛推的 commit 會被靜默覆蓋。**「別在中間 fetch」不是有效的防護**（流程自己會跑），錨定 SHA 才是。
- **`cleanup-cmd`（stale branch 清掃）仍建議排在 force-push 之後**——順序清楚、少一件要想的事。但**它已不是安全前提**：lease 帶了步驟 0 錨定的 SHA，中間再怎麼 fetch 都不影響比較基準。（此條在錨定 SHA 之前確實是硬要求，別讀成現在還是。）
- **NEVER reset past anything already on the default branch** —— 目標最遠只到 `merge-base(<default>, HEAD)`（`squash-all-cmd:` 用的就是它），絕不越過它往 default 上已有的 commit 去。
- 目標拿不準就**不要壓**：回報現況讓使用者定奪。壓錯要救比不壓貴得多。

## push 失敗處理

- `! [rejected] ...`：**先分流，兩種成因的處置相反**——
  - **本輪做過 branch 內 squash**（歷史被刻意改寫，見上節）→ `git -C <toplevel> push --force-with-lease=<feature-branch>:<squash 前記下的遠端 SHA> origin <feature-branch>`（帶 expected SHA 的理由見上節）。**NEVER `pull --rebase` here** —— 它會把剛壓掉的那串 review commit 原封不動拉回來，squash **靜默失效**（PR 上痕跡照舊），或因同內容重疊卡在 rebase 衝突中途。
  - **沒改寫歷史**（純粹 remote 有他人新 commit）→ 提示 `git -C <repo> pull --rebase origin <branch>` 後重試（feature branch 通常不會撞，除非他人也 push 同 branch）。
- `src refspec ... does not match` / 無 upstream → 用 `-u origin <branch>`。
- gh 未登入（`gh auth status` 失敗）→ 停下，提示使用者 `gh auth login`，不要硬推。
