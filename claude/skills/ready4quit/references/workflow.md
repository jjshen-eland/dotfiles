# Ready4Quit shared workflow

心智模型：退出前做一次 `sync`。把 session 結束後可能永久遺失的 durable facts flush 到正確持久層，
把未送出的 repo 狀態、未確認的 async work 與對話 loose ends 攤開，最後給出不高於實際證據的 verdict。

本流程是 pre-quit audit／flush，不是 shipping、handoff、進度摘要或補做原任務：

- 想在 clear／換 session 後繼續 → handoff，不建立 ready4quit checkpoint。
- 想 commit／push／PR／merge → target repo 的 shipping workflow；本流程只報告殘留。
- 想完成 TODO、修測試或清 branch → 另行要求；本流程只盤點。

Runtime adapter 必須提供 runtime label、exit wording、skill directory、durable-memory availability，以及目前
真正可用的 async／schedule evidence surface。**另一個 runtime 的 private path 或工具不是 fallback。**

## Critical — mutation boundary

第一次收尾 pass 可做的 mutation 只有「寫入正確既有 authority、且不抹掉既有內容」的 additive flush：

- 可直接做：新增 user memory；對同主題 memory 純附加；向 target repo 已存在的 canonical history／decision／
  dead-end／backlog authority 追加新 record。逐筆報告寫了什麼與落點。
- 先報告、等明確同意：kill／cancel background 或 schedule；刪除 memory；任何會抹掉、推翻、搬移或重排
  既有內容的修改；其他 destructive／outward action。
- 即使使用者同意也不在本流程做：commit、push、開 PR、merge；改寫／整理既有 project history，或替 active／
  backlog 做 lifecycle transition。把它們導向 target repo 自己的 shipping／project workflow。

不得建立 target repo 沒有採用的治理檔案族，也不得把 project fact 塞進 machine-local user memory 來假裝已跨主機
持久化。找不到合法 sink 時保留為明列的未 flush residue。

使用者催促、聲稱「應該乾淨」，或要求快速給 OK，都不改變檢查與 mutation boundary。

## Evidence strength × residue

每個面向分開標兩軸：

| 證據 | 定義 |
|---|---|
| `VERIFIED` | 有本輪 authoritative tool／command 的實際輸出，且覆蓋該面向 |
| `RECALLED` | 只能從本 session 對話回溯；來源本質不可完整枚舉 |
| `PARTIAL` | 該查的介面不可用、失敗、context 已壓縮，或 scope 可能不完整 |

殘留欄只有 `✓`（沒有找到具體殘留）與 `⚠`（後面必須列得出具體項目）。

- 查不到只會降低證據強度，**不會憑空製造 `⚠`**。
- `RECALLED` 找到的 open item 仍是具體殘留，必須標 `⚠`。
- 枚舉到一個 task 但無法確認 liveness 時，可標 `⚠ task <id> 狀態未確認`；`⚠` 的依據是那個具體 candidate，
  不是「工具不可用」。
- 只有 `VERIFIED + ✓` 能稱為該面向 GREEN；`RECALLED + ✓` 只能說「沒有已知殘留」。
- 任何 `PARTIAL` 都要點名盲區與原因。

## 1. Scope 與 Git 衛生

從 session 記憶列出本輪動過檔案的所有 repo，再加 pwd 所在 repo；不要掃 `~/Projects` 或其他廣泛目錄。
若 context 被壓縮或 repo scope 無法完整回溯，仍檢查能確認的 repo，但把 scope 證據降為 `PARTIAL` 並請使用者補充。

以**單一呼叫**把所有 repo 一次交給：

```text
<ready4quit-skill-directory>/scripts/git-hygiene.sh <repo1> <repo2> ...
```

不要逐 repo 呼叫，也不要再逐條重跑 helper 已涵蓋的底層 Git／GitHub 指令。逐 repo 讀取：

- `CLEAN`：remote、working tree、unpushed 與 PR evidence 都完整且無殘留。
- `RESIDUE`：列出 helper 指出的 modified／untracked／unpushed／PR residue。
- `UNKNOWN`：如實標 `PARTIAL`；不得把 stale tracking ref 或另一個 CLEAN repo 當成它已乾淨。

Helper 的 aggregate verdict 採 residue-priority：同一 repo 可能同時是 `verdict: RESIDUE`，欄位卻含
`remote: UNKNOWN`／`unpushed: UNKNOWN`／`pr: UNKNOWN`。**Evidence strength 必須逐欄判定；任一欄 UNKNOWN，
該 repo 的 Git evidence 就是 `PARTIAL`，不得因 aggregate RESIDUE 改標 VERIFIED。** 已確認的 residue 仍照列。

一個 repo 的 CLEAN 不得掩蓋另一個的 RESIDUE／UNKNOWN；報告逐 repo 列出，整體取最弱 evidence 與所有具體 residue。
每個 Git residue 都必須出現在 final `Next actions`：target repo 有 shipping workflow 就指名；沒有就明說
「ready4quit 不 ship，請另開一個明確授權 commit／push／PR endpoint 的 shipping task」。不得虛構 repo 沒有的
`/project`／`$project` 命令，也不要 offer to commit。

## 2. Durable knowledge flush

掃描本 session 才出現、未持久化且對未來有價值的 facts。先分類，再讀既有 authority 判斷是否已記：

- user／feedback（跨專案工作偏好、使用者糾正；feedback 記 Why／How to apply）→ runtime 提供的 durable user memory。
- project decision／dead end／milestone／known gap／active state → target repo contract 指定的 project authority。
- reference → 依適用範圍走 project authority 或 user memory。

對每個 target repo，先讀 root contract 與最接近改動位置的 contract；若 repo 規定文檔搜尋 router，先用它定位。
依 repo 現行 schema 寫入，不固定假設 `STATUS.md`，也不把 generated doc 當 authority。沒有 canonical sink 就不新建；
報告 fact 與缺少的接收點。

User memory 只有在目前 runtime 確實提供 facility 與格式時才能寫。寫前比對既有項：

- 完全相同 → 跳過並報告已存在。
- 同主題新增資訊 → 純附加到既有項，索引不得新增重複列。
- 新主題 → 新增一項並補既有索引。
- 新資訊會推翻／抹掉舊內容 → 不寫相反的新項；列出 proposed change 等明確同意。

Project records 同樣 additive only：已有同一事實就跳過；新增 record 可寫 working tree，但不 commit。不得刪 active/backlog、
改寫 history 或把 plan 標成完成。任何 repo-side flush 都會新增 Git residue，最終 Git 行必須納入該檔與「尚未 ship」；
可由本輪已做的寫入直接證明，不必把 helper 的底層指令再跑一遍。

若沒有候選，明說「本 session 無新增 durable-memory／project-record 候選」，不要靜默略過。

## 3. Async／schedule reconciliation

先用 runtime adapter 指定的 authoritative surfaces 枚舉與查狀態：

- background command／subagent：runtime task/agent status 或 completion notification 才能證明 liveness。
- cron／routine／automation：runtime 的 authoritative listing 才能證明目前清單。
- loop／scheduled wakeup 等沒有 listing 的狀態：依對話回溯，最高 `RECALLED`；context 壓縮後為 `PARTIAL`。

禁止以下替代證據：

- todo list 為空，不代表沒有 background work。
- output／log artifact 的存在、大小或內容，不能證明 task 還活著或已完成。
- OS process table 不能可靠對應 session-owned task，不用它補 runtime evidence 缺口。
- 未收到完成通知，不等於仍在執行。

對每個 concrete candidate 列狀態與建議（保留、等待、或待確認後取消）。找不到 authoritative enumeration surface 時，
該子面向標 `PARTIAL`；若對話也沒有 candidate，殘留仍為 `✓`，不得因不確定而虛構 `⚠`。
任何 kill／cancel／delete 都只列選項，第一次 pass 不執行。

## 4. Loose ends

從對話盤點：答應做但未做的 TODO、half-done 工作、失敗後未重試／未交代的步驟、以及等使用者回答的開放問題。
逐項標「未做／半成品／待你決定」，不自動補做。

本面向最高 `RECALLED`；context 被壓縮就是 `PARTIAL`。列出的每一項都是具體 residue，必須標 `⚠`。

## 5. Final report and verdict

報告至少包含：

```text
Ready4Quit report (<runtime>):
  Git hygiene       [VERIFIED|PARTIAL] ✓|⚠ <per-repo evidence/residue>
  Durable flush     [VERIFIED|PARTIAL|RECALLED] ✓|⚠ <written/skipped/unsunk facts>
  Async / schedule  [VERIFIED|PARTIAL|RECALLED] ✓|⚠ <status and blind spots>
  Loose ends        [RECALLED|PARTIAL] ✓|⚠ <open items>
  Verdict: ...
```

另列：已做的 additive writes、因已存在而跳過的 facts、缺少合法 sink 的 candidates、待明確同意的 destructive/outward
options，以及每個 Git residue 的 `Next actions`。有 Git `⚠` 卻沒有這一行，報告即不完整。不要讓使用者必須從
過程訊息拼湊結論。

Verdict 規則：

- 任一面向有 `⚠` → `NOT READY`，先列具體 residue；PARTIAL 不得拿來淡化它。
- 全部 `✓` 且全部 relevant evidence 都是 `VERIFIED` → volatile state 已 flush，可使用 runtime exit wording 安全結束。
- 全部 `✓` 但最低為 `RECALLED` → 「沒有已知殘留，可以結束」；不得說「已驗證乾淨／已驗證安全」。
- 全部 `✓` 但任何面向 `PARTIAL` → 「沒有已知殘留，但下列項目無法驗證」，由使用者決定是否帶盲區結束。

不得產生一個指不出具體待辦的 `NOT READY`，也不得因使用者催促而省略任何面向。
