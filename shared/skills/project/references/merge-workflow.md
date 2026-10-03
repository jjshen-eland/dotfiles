# Project merge 與 cleanup

Prerequisite：[ship-policy.md](ship-policy.md)、Log 結案階段與 [ship-paths.md](ship-paths.md)。
在第一個 outward action 及緊鄰的 Ship 摘要之前讀齊。檔中的「上方同批修復接續」指 ship-policy 的授權邊界。

## Merge 最後一哩（使用者明說 merge 後）

**Trigger: the user EXPLICITLY says "merge"** — either in any turn after the PR exists, **or by picking「送出並 merge」in the Step 4 confirmation options**（後者是同一個 gate 內收掉的預先授權，效力相同；使用者選「停在 PR」則一律不 merge）。 "push" or "open a PR" alone is NOT a merge instruction（沿用全域 CLAUDE.md 語意）。明說即是授權：不要因 skill 通篇的「絕不 merge」而拒絕或反覆再確認，把使用者卡在最後一哩。

**無 PR 可 merge 時**（形狀：使用者先前明說「不用 PR」走了 escape hatch，或全新空 repo 剛建 baseline——總之從頭到尾沒開過 PR）：**do NOT guess what "merge" meant.** 先跑 `ship-state.sh` 取當下狀態，再依狀態停下確認：

- `verdict: BOOTSTRAP` → 使用者要的其實是「把東西弄上去」，走`ship-exceptions.md`〈Bootstrap〉節（首推 baseline），這不是 merge。
- default 已存在、當前在 feature branch、但無 PR → 依 Runtime adapter 給兩個選項：**開 PR 再 merge**（留紀錄，預設建議），或**只把 branch push 上去**由使用者自行合併。
- feature branch 尚未 push → 先照 Step 4/5 送出，再回到本節。
- **"merge" is never permission to push the default branch.** 使用者要的是變更進 default，不是繞過流程進 default。

標準收尾序列（PR 已存在；`<merge-flag>` 由ship-policy 說法表決定）：

```bash
gh pr merge <PR-number|URL> -R "$repo_slug" <merge-flag> --delete-branch
# --delete-branch 刪 remote branch；在該 repo 工作目錄內執行時，gh 會順帶切回 default 並刪本地 branch
git -C <repo> switch <default>          # 若 gh 未代切（如以 -R 在 repo 外執行）
git -C <repo> pull origin <default>     # 同步本地 default——merge 產生新 commit，本地必落後
git -C <repo> branch -D <feature>       # 本地 branch 若仍殘留。squash/rebase 後 -d 會誤判「未 merge」拒刪，
                                        # 故先確認 PR 已 MERGED（gh pr view --json state）再 -D
```

- PR 內仍殘留 review 樣式 commit → **先跑 `ship-state.sh <repo>` 取 `review-residue:` 判定，不自行看 `git log` 認**（同ship-exceptions squash 節與 `log-prepare.md`「Step 1：逐 repo 狀態 + 流程偵測（先於任何 commit）」的禁令；誤認就是壓掉使用者自己的歷史，且緊接 force-push 不可回復）：有 `top-contiguous:` → 照該行的 `squash-cmd:` 壓掉再送，不必詢問；只有 `buried:` → **照常送出**，在摘要標明「N 顆 review 痕跡夾在語意 commit 中間，非互動式壓不掉」；`UNKNOWN` → 如實說明現況、不猜。
- **選定的 flag 不可用**（`Rebase merging is not allowed` / `Merge commits are not allowed`；或 branch 含 merge commit 而 GitHub 拒絕 rebase——拒絕原因不同、處置相同）→ 停下回報、以剩下可用的方式給選項。**NEVER silently fall back to another flag** — 尤其別退回 `--squash`：那會壓掉使用者要保留的 commit。這是少數仍需詢問的例外：使用者選的做法在該 repo 不存在，沒有預設可推。

### merge 受阻時的分流（先看狀態，不做「失敗就 retry」）

`gh pr merge` 失敗的原因不只 protection，而 `--admin` 只繞得過 **protection 規則**——衝突它一樣過不了。盲目 retry 只是多失敗一次，還把「繞過」用在不該用的地方。故**先查狀態再決定**：

```bash
gh pr view <PR-number|URL> -R "$repo_slug" --json mergeStateStatus,mergeable -q .mergeStateStatus
```

⚠️ **本流程一定是「push → 開 PR → 查狀態」這個順序，所以第一次查很可能拿到 `UNKNOWN`**——GitHub 的 mergeability 是收到 push 後才非同步算的（2026-08-15 實戰即撞到，重查一次就變 `CLEAN`）。**那是暫態，不是查詢失敗**：重查（隔幾秒，最多三次）拿到實態再分流。**Never report a first-poll `UNKNOWN` as "無從判定" and stop** —— 那會讓每一次 ship 都可能卡在最後一哩。

**`BLOCKED` 不是單一成因，拿到它就必須再追問一句。** CI 還在跑、required check 失敗、protection 真的擋——三者在 `mergeStateStatus` 眼中長得一模一樣，正解卻相反（等／停／可 bypass）。**Never read a bare `BLOCKED` as "protection is really blocking"**：

```bash
# --required 只看 protection 實際在意的 check
gh pr checks <PR-number|URL> -R "$repo_slug" --required
# exit 0 = required check 全綠｜exit 8 = 還有 pending｜其他非零 = 看輸出分辨失敗、無 required check、query／transport failure
```

⚠️ **exit 1 有三個可觀察成因，必須把 exit code 與輸出一起分流**：

1. 輸出明確列出標為 failed 的 check row → required check 失敗。
2. 輸出是 gh 的兩種 exact empty-required 訊息之一：`no checks reported on the '<branch>' branch` 或
   `no required checks reported on the '<branch>' branch` → 先重跑 `ship-state.sh <repo>` 取得新的
   `required-policy:`，不得只看 PR 空輸出：
   - `required-policy: none` → 確認沒有 effective required checks，阻擋與 check 無關，當成「全綠」走
     protection 那列。
   - `required-policy: REQUIRED` → policy 宣告的 context/workflow 尚未向 Checks API enrollment。先取
     PR 當下的 exact `headRefOid`，然後呼叫 shared deterministic helper：
     ```bash
     head_sha="$(gh pr view <PR-number|URL> -R "$repo_slug" --json headRefOid -q .headRefOid)"
     <skill-dir>/scripts/wait-required-enrollment.sh "$repo_slug" <PR-number|URL> "$head_sha"
     ```
     Helper 的 startup enrollment grace 固定 **13 次 observation、間隔 5 秒**；每次都重驗 PR head。
     第 13 次仍沒有 check 時，只有 schema-valid、exact head SHA＋`pull_request` event 且 lifecycle 仍 active
     的 Actions run 能延續觀察；沒有 active matching run 就結束，不把 fixed grace 任意拉長。Run 本身不是
     check verdict；helper 只在真正 required check object 出現時回 `ENROLLED`。不手寫另一個輪詢、
     不 blind sleep、不重試 merge。
     - `verdict: ENROLLED` → 立即重跑標準 non-watch `gh pr checks ... --required`，以新的 exit
       code＋輸出回到本節三分流；pending 才進下方現有 watch＋final non-watch 路徑。不得用 helper
       之前的 no-checks snapshot，也不再開第二段 grace。
     - `verdict: UNOBSERVED` → startup grace 結束時沒有 active matching run，或 run 正常結束後仍沒有
       check object；STOP，不 `--admin`、不替 target repo 改 CI。
     - `verdict: RUN_TERMINAL` → exact-head active run 在 check enrollment 前以 failure／cancelled／其他
       non-success conclusion 結束；STOP 並回報 `run-conclusions`，不得誤稱 query error。
     - `QUERY_ERROR` / `HEAD_CHANGED` / malformed evidence → 立即 STOP，不 retry；`QUERY_ERROR` 必須保留
       helper 的 `stage`／`detail`，不能用「尚未看到 check」代替真正錯誤。
     原 `--merge` authorization 在這個 logical Project invocation 的 grace／watch 內繼續有效，approval UI
       呼叫數必須是 0；invocation 結束不 carry。已知本批CI失敗適用上方同批修復接續，不把repair hold當成結束。
   - `required-policy: UNKNOWN` → policy 不可見，STOP；不得把 403／provider gap 當成 none。
3. 兩者皆非，且末尾是 GraphQL／GitHub API／network 錯誤（例如 `Post "https://api.github.com/graphql":
   ... operation timed out`），或輸出根本無法產生 check verdict → 這是 transport／API 的 **query failure**。
   它**既不是 required check 失敗，也不代表全綠**；不得 merge 或 `--admin`。

第三類最多重跑一次相同的 **non-watch** `gh pr checks ... --required`。若那次仍無法取得 verdict，STOP 並回報
實際錯誤，不做無界 retry。若第三類正是從下方 `--watch` 返回，該次 mandatory non-watch recheck 已經是這一次，
失敗就停。**Never read a bare exit 1 as a failing test or a green result** —— 對「有 required review、沒有 CI」的
repo，前一種誤讀會捏造不存在的壞 check；對 transport error，後一種誤讀會讓未知狀態的變更提前進 default。

判準吃 **exit code**，不要自己數 `statusCheckRollup`——rollup 單筆沒有 `isRequired` 欄位（分不出必要與非必要：非必要 check 還在跑會讓你空等、非必要 check 失敗會讓你誤停）、同名 check 會有多筆（被取代的 workflow run 仍留在清單裡）、且它混了 check run 與 legacy commit status 兩種型別（後者用 `state`/`context`，拿 `status != "COMPLETED"` 去篩對它恆真）。`gh pr checks` 已把這三件事正規化。

| 狀態 | 意思 | 「merge」 | 「bypass merge」 |
|---|---|---|---|
| `CLEAN` / `HAS_HOOKS` / `UNSTABLE` | 沒有硬性阻擋（`UNSTABLE` = **非必要** check 有問題，protection 不在意——與上面 `--required` 是同一判準的兩面） | 直接 merge | 直接 merge（`--admin` 用不到） |
| `BLOCKED` ＋ checks **exit 8** | **CI 還在跑，不是 protection 擋** | **等它跑完再 merge**（見下方等待策略） | **一樣等**——`--admin` 在此繞過的是還沒跑完的測試，不是規則 |
| `BLOCKED` ＋ checks **其他非零，且列出了失敗的 check** | required check 失敗 | 暫停merge；依同批修復接續處理，不以失敗結束已授權修復 | **一樣不merge**——修復後重驗，不能bypass失敗測試 |
| `BLOCKED` ＋ authoritative non-watch checks 是 **query／transport failure**，沒有 failed row、也不是上述任一 exact empty-required 訊息 | check 狀態不確定 | 停，回報查詢錯誤；不得猜失敗或全綠 | **一樣停**——`--admin` 不得繞過未知狀態 |
| `BLOCKED` ＋ checks **exit 0**，或 **exact empty-required + required-policy none**（見上方 ⚠️） | protection 真的擋（缺 review／其他規則），與 check 無關 | **停**，回報並告知可用「bypass merge」 | 加 `--admin` 重試 |
| `BLOCKED` ＋ **required-policy REQUIRED** 但收到 exact empty-required 訊息 | startup enrollment pending、dependency-gated active run，或 grace 後的 UNOBSERVED | 跑 identity-bound helper；ENROLLED 回到原 checks 分流，UNOBSERVED／RUN_TERMINAL／error 就停 | **一樣等／停**——沒有測試結果可 bypass |
| `DIRTY` | 有衝突 | 停，回報 | **一樣停**——`--admin` 不解決衝突 |
| `BEHIND` | base 落後、protection 要求最新 | 停，回報 | **一樣停**——該做的是更新 branch，不是繞過 |
| `DRAFT` | 這是 draft PR，本來就不能 merge | 停，問「要我先 `gh pr ready` 轉正式嗎」——**不自行轉** | 一樣停——`--admin` 不能 merge draft |
| `UNKNOWN`，**且剛 push／剛開 PR** | GitHub 還在算 mergeability（非同步，數秒內解析）——**暫態，不是查詢失敗** | **重查**（隔幾秒，最多三次），拿到實態再依本表分流 | 同左 |
| 其他／查詢失敗（含**重查後仍** `UNKNOWN`） | 無從判定 | 停，回報實際錯誤 | 停，回報 |

- **`--admin` 只在「bypass merge」＋「`BLOCKED` 且 required check 全綠」這一格出現。** Never reach for it on any other row, and never as a retry after an unexplained failure. 它需要 admin 權限；ruleset 也可設成連 admin 都不能繞——兩種情況都是失敗即停、回報，不再想別的辦法。
- **`BLOCKED` ＋ CI 還在跑時的等待策略**（`--watch` 自己輪詢，不要手寫迴圈）：
  ```bash
  gh pr checks <PR-number|URL> -R "$repo_slug" --required --watch --interval 15 --fail-fast
  # --watch 的 exit 只代表 poller 如何返回，不是 authoritative check verdict；回來後固定用 non-watch 重查一次
  gh pr checks <PR-number|URL> -R "$repo_slug" --required
  # 上一行取得明確 verdict 後才重查 merge 狀態——判準看新的 check 結果，不看上一次 merge 失敗沒有
  gh pr view <PR-number|URL> -R "$repo_slug" --json mergeStateStatus -q .mergeStateStatus
  ```
  - **`--watch` 是 poller，不是 check-state authority。** 不論 watch 以 0、1、8 或其他 code 返回，都要跑上面的
    一次 non-watch recheck，並以它的 exit code ＋輸出分流。若 recheck 是 query／transport failure，STOP；不要
    沿用 watch 最後一屏、不要只看新的 `mergeStateStatus`，也不要再 retry。
  - **刻意不封頂**：跑到 check 收斂為止。agent 全程在場、使用者隨時可中斷，那就是上限。
  - **NEVER wrap the wait in `timeout` / `gtimeout`.** Neither exists on macOS, and `command not found` is exit 127 — the whole wait silently never runs while the exit code still reads like a pass. 需要停就中斷，不要引入 `timeout`。
  - **NEVER re-run `gh pr merge` while waiting.** 這正是本節標題那條「不做失敗就 retry」的具體化：判準是 check 狀態，不是上一次 merge 失敗與否；重試只是多一次 API 呼叫，還把「還是被擋」的假訊號餵回自己。
  - 「有的還在跑、有的已失敗」同時成立時 exit code 只會回一個。**不論回哪個，處置都不是 `--admin`**——差別只在「等」還是「立刻回報」；`--fail-fast` 會讓 watch 在第一個失敗就返回。
- **required check失敗依同批修復接續處理**：範圍內可修就直接修復並重查，不要求再說merge。
  只有修復超出原批次、額度耗盡或確有未決權限時，才列具體差異、選項及回答後的下一步。
- **`--auto` 預設不用。** GitHub 的錯誤訊息會建議它，但 merge 真正發生時 agent 已經結束，「Merge 最後一哩」剩下的三步（切回 default、`pull` 同步、刪 branch）沒有人做——本地 default 落後、feature branch 殘留，要等下一輪 `ship-state.sh` 的 `stale-branches:` 才補報。只有在 CI 明顯很慢、使用者不想等時才提供它當選項，並在回報明說「本地 default 與 branch 清理要你之後自己做」。
- **`BLOCKED` 缺的是什麼，去讀規則與 check，NEVER infer it from an empty PR field.** `reviewDecision: ""` 不等於「缺 approval」——`required_approving_review_count: 0` 的 repo 它本來就一直是空的（2026-08-14 與 08-15 兩次實地誤診同一來源）。要確認 protection 要求什麼就直接讀：`gh api repos/{owner}/{repo}/rulesets`（再取 `/rulesets/{id}` 看內容）與`ship-diagnostics.md`〈Branch protection 偵測〉那組指令。
- **動用了 `--admin` 就必須在送出回報裡明說「這次繞過了 protection」。** 繞過本身要留在使用者看得到的地方。
- **失敗即停**：gh 帳號無 write 權限、其他未列狀態 → 停下回報實際錯誤。**Never bypass checks by other means, never fall back to pushing the default branch directly.**
- 多 repo（多個 PR 同輪開出）：先確認使用者的 merge 指令涵蓋哪些 PR，勿一句 merge 就全 merge。
- merge 完成後回報：merged commit / 本地 default 已同步 / branch 已清。
- **本序列只清它自己 merge 的那支**——更早的、或走別條路合併的 branch 不在此列，由 `ship-state.sh` 的 `stale-branches:` 訊號在下一輪 Step 1 攤開（附 `cleanup-cmd:`，經使用者同意才刪）。
