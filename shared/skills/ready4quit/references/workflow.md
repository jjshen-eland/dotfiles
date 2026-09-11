# Ready4Quit shared workflow

心智模型：退出前做一次 `sync`。把 session 結束後可能永久遺失的 durable facts flush 到正確持久層，
把未送出的 repo 狀態、未確認的 async work 與對話 loose ends 攤開，最後給出不高於實際證據的 verdict。

本流程是 pre-quit audit／flush，不是 shipping、handoff、進度摘要或補做原任務：

- 想在 clear／換 session 後繼續 → handoff，不建立 ready4quit checkpoint。
- 想 commit／push／PR／merge → target repo 的 shipping workflow；本流程只報告殘留。
- 想完成 TODO、修測試或清 branch → 另行要求；本流程只盤點。

Runtime adapter 必須提供 runtime label、exit wording、skill directory、durable-memory availability，以及目前
真正可用的 async／schedule evidence surface。**另一個 runtime 的 private path 或工具不是 fallback。**
Memory facility 只影響非關鍵 cache 是否可寫；不得改 memory toggle，也不得讓 on／off／unavailable 改變
authority routing、safety verdict 或工作是否可跨 runtime 延續。

## Critical — mutation boundary

第一次收尾 pass 可做的 mutation 只有「寫入正確既有 authority、且不抹掉既有內容」的 additive flush：

- 可直接做：向 target repo 已存在的 canonical history／decision／dead-end／backlog authority 追加新 record；
  對**只具 runtime-local 便利價值且非關鍵**的 cache 新增或純附加。逐筆報告寫了什麼與落點。
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

掃描本 session 才出現、未持久化且對未來有價值的 facts。先按**權威需求**分類；memory availability
不得參與分類：

- safety／Git 規則、使用者要求兩個 runtime 都遵守的穩定工作方式、明確要求保存的穩定 global preference，
  或跨專案糾正 → **instruction promotion candidate**。
  只在報告列出候選、適用 scope 與理由；ready4quit 不自行改 always-on instruction，也不先寫 private memory
  假裝已升格。若既有 native instruction 尚未包含它，這筆未升格候選就是 concrete residue，標 `⚠` 並使
  verdict 為 `NOT READY`；只有讀過 authority、確認已存在才可跳過。
- project decision／dead end／milestone／known gap／active state／跨主機延續所需 facts → target repo contract 指定的
  project authority。只有目前 actor 是合法 steward 且 repo 已有 sink 才 additive 寫入；否則列 concrete residue。
- 只對目前 runtime 有便利價值、遺失不影響 safety／governance／project continuity 的偏好或 reference → optional
  runtime cache。有 supported facility 時 best-effort 新增／純附加；**disabled/unavailable → `skipped`**，不是 residue。
- 使用者本輪明確提出「記住／保存」的 **explicit retain request**，卻沒有合法 instruction、repo authority 或
  supported runtime cache sink → **`residue`**。必須列出未保存內容與缺少的 sink；不能因無設施假裝已 flush。
- 一次性、可由 repo/code 推導且沒有未來價值 → 不保存，報告 `discarded` 或略述理由。

對每個 target repo，先讀 root contract 與最接近改動位置的 contract；若 repo 規定文檔搜尋 router，先用它定位。
依 repo 現行 schema 寫入，不固定假設 `STATUS.md`，也不把 generated doc 當 authority。沒有 canonical sink 就不新建；
報告 fact 與缺少的接收點。

Optional runtime cache 只有在目前 runtime 確實提供 facility、允許本 session contribute 且格式已知時才能寫。
不得為本流程切換 global／project／chat memory 設定。寫前比對既有項：

- 完全相同 → 跳過並報告已存在。
- 同主題新增資訊 → 純附加到既有項，索引不得新增重複列。
- 新主題 → 新增一項並補既有索引。
- 新資訊會推翻／抹掉舊內容 → 不寫相反的新項；列出 proposed change 等明確同意。

Codex local memory files 是 generated state，不是本流程的直接編輯 surface；只有 runtime 明確提供的 supported
facility 才算 cache sink。Claude Code 也只使用當下提供的 facility，不猜 private storage path。

Project records 同樣 additive only：已有同一事實就跳過；新增 record 可寫 working tree，但不 commit。不得刪 active/backlog、
改寫 history 或把 plan 標成完成。任何 repo-side flush 都會新增 Git residue，最終 Git 行必須納入該檔與「尚未 ship」；
可由本輪已做的寫入直接證明，不必把 helper 的底層指令再跑一遍。

**Memory disabled/unavailable 本身不是 residue。** 殘留必須指向一筆被要求保存或為正確延續所必要、卻沒有
合法 authority 的具體 fact。若沒有候選，明說「本 session 無新增 instruction／project／optional-cache 候選」，
不要靜默略過。

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

另列：instruction promotion candidates、已做的 additive writes、`skipped`／`discarded` facts、因已存在而跳過的
facts、explicit retain request 或必要 project fact 的 unsunk residue、待明確同意的 destructive/outward
options，以及每個 Git residue 的 `Next actions`。有 Git `⚠` 卻沒有這一行，報告即不完整。不要讓使用者必須從
過程訊息拼湊結論。

Verdict 規則：

- 任一面向有 `⚠` → `NOT READY`，先列具體 residue；PARTIAL 不得拿來淡化它。
- 全部 `✓` 且全部 relevant evidence 都是 `VERIFIED` → volatile state 已 flush，可使用 runtime exit wording 安全結束。
- 全部 `✓` 但最低為 `RECALLED` → 「沒有已知殘留，可以結束」；不得說「已驗證乾淨／已驗證安全」。
- 全部 `✓` 但任何面向 `PARTIAL` → 「沒有已知殘留，但下列項目無法驗證」，由使用者決定是否帶盲區結束。

不得產生一個指不出具體待辦的 `NOT READY`，也不得因使用者催促而省略任何面向。
