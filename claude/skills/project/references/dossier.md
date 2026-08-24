# Project 文檔狀態與歷史契約

本 reference 說明 project workflow 如何維護 active state、backlog 與 history。已採用 repo 的完整資料模型與
CLI exit contract 以 repo-local `docs/document-governance.md` 為權威；本檔只規定 skill 的行為。

## 目錄

- 角色分工
- 平行協作與 stewardship
- 已採用 repo 的開工與檢索
- 記錄時機與 record schema
- Log 與 audit
- Legacy fallback

## 角色分工

| 內容 | Canonical 落點 | 生命週期 |
|---|---|---|
| 進行中／暫停工作 | `STATUS.md` | 就地更新；完成後移除 |
| 未結案技術債／缺口 | `docs/backlog.md` | `B-*`；解決或放棄後移除 |
| Decision | `docs/archive/decisions-YYYY-MM.md` | `D-*`，event-time append-only |
| Dead end | `docs/archive/dead-ends-YYYY-MM.md` | `X-*`，event-time append-only |
| Milestone | `docs/archive/milestones-YYYY-MM.md` | `M-*`，event-time append-only |
| Plan | `docs/plans/YYYY-MM-DD-<work-item>.md` | 每 work item 一檔；active 狀態原檔修訂，closed 後凍結 |

`STATUS.md` 只留 `進行中`、`暫停中`、`歷史入口`、`待辦入口`、`移交準備度`。暫停項必須寫可觀察的
恢復條件；已完成項、決策、死路與 session log 都不能殘留。

## 平行協作與 stewardship

Repo 的 `status_schema.active_item_contract` 啟用時，每個 active H3 除了 spec 欄位，還要有：

- `Writer`：`claude:<workline>`、`codex:<workline>`、`human:<name>`、`external:<party>` 或
  `unassigned:<slug>`。
- `Workspace`：repo writer 使用 `branch=<feature-branch>`；外部事項用 `external/no-repo-write`；尚未分派
  用 `unassigned`。NEVER 寫絕對 worktree path。
- `Write Scope`：逗號分隔的 repo-relative paths/modules；外部事項用 `none`；`repo-wide` 代表禁止其他
  repo writer 平行工作。
- `Dossier Steward`：所有 active items 使用同一個 actor key，且不得是 `unassigned`。

既有 repo 的 human authority 可能寫成 `human:<name>` 或 legacy `owner:<name>`；兩者都代表 durable human
steward，不代表任何 Claude／Codex session 自動取得該 actor。Runtime executor 與 authority actor 必須分開：

- `resume=<runtime:workline>` 只恢復**同 runtime、exact durable actor key** 的既有 workline；不改 ownership。
- `as=<human-or-owner>` 是使用者在**本次新的 explicit project invocation arguments** 對 human steward 的
  bounded execution delegation。值必須 exact match 所有 active items 的 durable steward，只涵蓋本輪
  Project mutation／shipping，下一輪自動失效，也不把 executor 寫成 owner。
- 普通自然語言「我是某人」、Git author、GitHub login、同 runtime 或名稱相似都不是 resume／delegation
  credential。Agent session 不得把自己重新標成 `human:*`／`owner:*`。

每次 gate 與 ship summary 都分別列 `executor actor`、`durable steward`、`authority actor`、
`authority source`。沒有 exact match、合法同-runtime resume 或 explicit bounded human delegation 就 STOP。
若 current STATUS 已因完成而沒有 active item，但入口正在評估一顆同時移除該 item 的 candidate commit，
可從 candidate parent 的 STATUS 恢復 durable steward evidence；current 與 parent 都沒有 steward 時，candidate
不得寫 history／backlog／transfer／shared plan，必須先用 Spec 建立 work item，不能把「零 active」當免 steward。

Steward 是 shared `STATUS.md`、backlog、history shards 與 shared plan 的唯一 writer。其他 writer 必須在
不同 branch/worktree 與不重疊 scope 內工作，不改上述 shared surfaces、不 push，完成後建立符合 repo
convention 的 semantic commit，交給 steward 驗證並 cherry-pick 到 integration branch。Scope 相交、workspace
相同、durable state 指向另一位 writer/steward 或 ownership 不明時一律 STOP，不自行接管或解衝突。

Worker 的 `Dossier delta` 固定回報：work item、actor、branch/workspace、commit SHA、changed scope/files、
tests、progress、decisions with reasons、dead ends、blockers、next step。這是 claim，不是 canonical state；
steward 必須自行檢查 commit ancestry／diff／scope／tests，再決定是否 cherry-pick 與寫入 dossier。Review
agent 維持 read-only。Ownership transfer 只接受使用者明示或 current steward 的 durable transfer direction；
machine-local handoff artifact 不授予 repo mutation。正式切換必須依 workflow 的 transfer state machine，
由 current steward 在同一 transfer commit 同步**所有 active items**的 steward／writer／workspace／next step；
該 commit 到達 canonical handover endpoint 前，舊 steward 仍是唯一 shared-dossier authority。若 checkout 已含
next actor 的 pending coordination fields，任何 authority check 都必須定位 conditional owner record 所在 commit、
fetch endpoint 並驗 remote-visible ancestry；不得只按字面欄位授權，證據不可得即 STOP。

Bounded human delegation 不是 ownership transfer：durable steward 不變，runtime 只是本輪受指示的 executor。
它不能代理 `claude:*`／`codex:*` steward；agent workline 的接續只能用 same-runtime `resume=` exact match。
Worker commit 若含 `STATUS.md`、backlog、history shard、shared plan 或 transfer guide，delta 已越界；不得原樣
ship 或當作合格 cherry-pick。先由 worker 交出不含 shared surfaces 的 semantic commit，或由合法 steward
在受控整合中重建 commit 並重新驗 diff／tests。

## 已採用 repo 的開工與檢索

同時存在 `.doc-governance.json` 與 `scripts/doc-governance.py` 即為 adopted repo：

1. 開工先確認 target core 與 `<project-scripts>/doc-governance.py` byte-identical（self-hosted worktree 可用
   git common-dir 證明同 repo），再執行 `python3 "<project-scripts>/doc-governance.py" --root "$repo" find '<工作問題>'`
   查相關 decision／dead end；命中的 stable IDs
   寫入 active item 的 `關聯`。
2. Spec 寫 Context／Goal／Acceptance Criteria／Constraints／進度／下一步，不把歷史理由複製進 active state；
   啟用 active item contract 時，同時依上節寫入四個 coordination fields。
3. 無路徑線索也使用 `find`；history／archive 的人工 pointer 不作為可檢索性的代理。

## 記錄時機與 record schema

Decision／dead end 在事件當下追加，milestone 在完成當下追加；不要等 ship 才靠記憶重建。先用：

```sh
python3 "<project-scripts>/doc-governance.py" --root "$repo" record-path --type <decision|dead_end|milestone> --date YYYY-MM-DD --slug '<短名>'
```

再把 record 寫入輸出的 shard 與固定 `## 事件記錄（event-time）`：

```markdown
- **D-YYYYMMDD-short-slug · YYYY-MM-DD 標題**:結論與理由。
  - 日期來源:direct
  - 放棄:<替代方案與原因>
  - 重議:<可觀察條件；無則 none>
  - 關聯:<work item、B/D/X/M ID、commit 或 PR；無則 none>
```

ID prefix 隨 type 改為 `D`／`X`／`M`。日期決定 ID 與 shard 月份；不可拿 archive batch date 代填。
已 commit record 不改不刪。翻案另寫新 record，`關聯` 加 `supersedes:<old-id>`；不再適用的 dead end
也以新 decision/milestone 說明，不抹去原判斷。

Backlog 新項建立時就給 `B-YYYYMMDD-slug`。解決時寫 `M-*`、明確放棄時寫 `X-*`、變成「決定先不做」
時寫 `D-*`；history record 的 `關聯` 保留原 `B-*`，然後把 backlog item 整條移除。未解決項不可因太長
或看不順眼而刪。

## Log 與 audit

Log Step 2 核對本 session 是否漏記 history，完成的 active item 是否已移除，paused 是否有恢復條件，
backlog 是否只剩未結案項。之後執行 `python3 "<project-scripts>/doc-governance.py" --root "$repo" audit --ship`：

- exit 0：文檔 verdict 通過。
- exit 1：content findings；修正後重跑，送出前維持 STOP。
- exit 2：scanner/config BROKEN；fail closed，不回退 legacy detector。

Shipping 只讀 exit code，不 grep 顯示文案。`audit --ship` 是 adopted repo 唯一文檔 verdict；其他摘要訊號
仍可繼續收集，但最終 verdict 必須由 doc finding 優先變成 STOP。

全機隊的 `ship-state.sh` 不直接執行外部 target repo 的 Python：target core 必須與 dotfiles 受信任 scanner
byte-for-byte 相同，再由受信任 scanner 讀 target config；mismatch 直接 BROKEN／STOP。唯一例外是兩支 core
經 Git `common-dir` 證實屬同一 repository 的 self-hosted linked worktree，此時執行 worktree core。

## Legacy fallback

兩個 adoption 檔都不存在的 repo 維持既有 dossier 慣例：依該 repo 的 `STATUS.md`／`docs/backlog.md` schema
記錄，`ship-state.sh` 走 legacy detectors，不強迫補 archive family。只有一個 adoption 檔存在代表宣告破損，
必須 BROKEN／STOP；NEVER 靜默退回 legacy。

Legacy plan、archive 與 evidence 保持原位，不為新 schema 重寫。rollout 先 `audit --shadow`，再用該 repo
自己的 adapter 對應既有 paths；不得把 dotfiles 的 class map 直接覆蓋到別的 repo。
