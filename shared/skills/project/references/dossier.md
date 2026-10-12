# Project 文檔狀態與歷史契約

本 reference 說明 project workflow 如何維護 active state、backlog 與 history。已採用 repo 的完整資料模型與
CLI exit contract 以 repo-local `docs/document-governance.md` 為權威；本檔只規定 skill 的行為。

## 目錄

- 角色分工
- 接續（內容契約）
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

## 接續（內容契約）

接續靠 repo 內容，不靠 actor 身分；kernel「Shared work and durable project state」是規則本體，本節只說 skill 怎麼做。

- 進行中工作項至少有 `Goal`、`進度`、`下一步`，另可有 Context、Acceptance Criteria、Constraints 與 `關聯`。
  Repo 若以 `status_schema.active_item_contract` 宣告必填欄位，依其設定。
- 把工作留給其他 session 接續時：進度與下一步要正確；自己的未合併工作 commit 在下一步寫明的 branch；
  本身不 commit 的流程（例如 ready4quit、handoff）改為回報未 commit 的內容。push 只依安全底線取得授權，
  並告訴使用者還有什麼沒 push。
- 接手時先拿下一步寫明的 branch 與其 commit 核對工作項；branch 不存在或已合併，代表工作項已過時，先修正再續作。
  工作項裡的下一步是可以接續的邀請，不是佔用，也不是任何外向動作的授權。
- 平行 session 各用自己的 branch 與 worktree 或 clone。工作樹有不是自己做的變更，或該 branch 正在另一個
  worktree checkout，就停下問使用者。
- STATUS、backlog、history 都是一般檔案：平行 branch 衝突時保留每個工作項最新的內容與各 branch 的紀錄，
  不確定就停下問；history 只追加，不刪別人的紀錄。

## 已採用 repo 的開工與檢索

同時存在 `.doc-governance.json` 與 `scripts/doc-governance.py` 即為 adopted repo：

1. 開工先確認 target core 與 `<project-scripts>/doc-governance.py` byte-identical（self-hosted worktree 可用
   git common-dir 證明同 repo），再執行 `python3 "<project-scripts>/doc-governance.py" --root "$repo" find '<工作問題>'`
   查相關 decision／dead end；命中的 stable IDs
   寫入 active item 的 `關聯`。
2. Spec 寫 Context／Goal／Acceptance Criteria／Constraints／進度／下一步，不把歷史理由複製進 active state。
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
