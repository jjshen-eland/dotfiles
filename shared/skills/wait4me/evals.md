# Wait4me — Evals

> 開發／迭代用的 portable behavior oracle，**不從 SKILL.md body 連結**。
> 所有通知驗證使用 local capture／fake；不得呼叫 live Notification Center。

## A. Triggering tests

| # | 使用者輸入 | 期望 |
|---|---|---|
| T1 | `$wait4me`／`$wait4me on` | ✅ 只為目前前景 session 啟用，並發一則通知測試 |
| T2 | `$wait4me off`／`$wait4me status` | ✅ 停用；status 不改開關，on 時發一則通知測試，off 時不發 |
| T3 | `等你需要我決定時用 NC 通知我` | ✅ 觸發 skill；沒有 hook control result 時引導使用 exact `$wait4me`，不得假稱已啟用 |
| T4 | `這個 cron 跑完通知我` | ❌ 不觸發；這是 `nc-notify` 的背景工作生命週期 |
| T5 | `工作完成後寄信給我` | ❌ 不觸發；不是等待使用者回應 |

## B. Portable behavior oracle

### W1 — 無 skill／hook baseline（RED）

- 現況只有主 agent `Stop` timestamp；沒有 session 開關、NC transport、approval 事件通知或
  「真正需要人回應」與普通完成的分類。
- GREEN：bare／`on` 啟用後，hook 能在同一 session 的 approval 與 blocking response 發出通知；
  `off` 後停止，普通完成不通知。

### W2 — session isolation 與 lifecycle

- 同時建立 session A／B，只在 A 執行 bare／`on`；A enabled、B disabled。
- A 的 compact 不清除開關；new／clear／resume／`SessionEnd` 清除 A 的 enabled state。
- ownership transfer 不承接通知授權；新 actor 必須由使用者重新啟用。
- `status` 不改變狀態；on／已啟用的 status 每次各發一則測試通知，off 的 status 不發。
- 控制結果分別報開關與 probe：Gateway acknowledge 不等於使用者已收到，也不證明後續 Stop marker 路徑。
  Probe 失敗時開關仍為 on，不得宣稱通知管線正常。

### W3 — 只有真正等待人回應才通知

- enabled session 的 user-prompt hook 每回合注入 machine-readable wait marker contract。
- 主 agent 因缺資料、需要選擇或 blocker 而停止時，最後訊息帶一個短而不敏感的理由；`Stop`
  發送一次 NC notification。
- 正常完成、可選建議、進度訊息與 subagent completion 不得通知。
- 不用問號、自然語言關鍵字或 transcript parsing 猜測是否需要回應。

### W4 — approval 與去重

- enabled session 的 `PermissionRequest` 立即發一次通知；未啟用 session 不發。
- 同一 session／turn／tool request 重送 hook 時只通知一次；下一個獨立 request 仍會通知。
- approval 通知只說明 repo、動作類別與「請回 terminal 查看」，不傳完整 command／tool input。

### W5 — transport failure 與 privacy

- 缺 `NC_API_URL` 或 `NC_API_KEY` 時 no-op；不把 agent 成功或等待狀態改成失敗。
- timeout、serialization、HTTP failure 或 exception 只產生 bounded、secret-safe warning，hook exit 0。
- enabled `Stop` 留下 owner-only 的最後階段與 sender exit／錯誤類別；中途取消保留 `sending`，
  普通完成標 `marker-absent`。紀錄不得含理由、通知內容、URL、key 或 raw hook input。
- 網路不可達與連線被拒須能在去敏錯誤類別中區分；HTTP 錯誤不得回顯 curl verbose 中的金鑰或 URL；失敗不得標送達，後續成功須更新最後狀態。
- Python socket 受限時，sender 仍以已驗證可連私網的系統 curl 完成 Gateway POST；金鑰不得出現在命令列或暫存檔。
- hook未繼承NC環境時，可從adapter明示的owner-only env file載入兩個設定鍵；不得執行該檔內容。
- transport未成功時不得提前寫入sent marker；同一事件後續一次有界重試仍可送達。
- `NC_API_URL` 是NC base URL；sender必須POST `/api/v1/events`、使用 `X-API-Key`，並送合法的
  `alert` Gateway event。只有回覆顯示 `forward`／`escalate` 且 `notification_status` 為
  `sent`／`deduplicated` 才算送達；404、drop或channel failed都不得消耗去重資格。
- payload 為單行且不超過 200 Unicode characters；不得包含 command、prompt、transcript、raw
  tool input、Authorization 或 API key。
- notification task identity 固定且可辨識；測試只用 local capture，不送 live notification。

### W6 — 雙 runtime parity

- Claude Code／Codex 使用同一 canonical workflow、script 與 eval oracle；兩端只有薄入口與 hook wiring。
- Codex `Stop` 通知使用有界同步 hook：隔離 `codex exec --ephemeral` 中，背景 Stop 在 session 結束時
  可能連入口都未執行；同步 control 應完成相同 probe。此差異不改通知的可觀察語意。
- 同一組 hook fixture 在兩端產生等價的 enable／disable、wait、approval、dedup 與 failure-isolation 結果。
- 任一 runtime 缺少必要 hook capability 時 fail closed 並回報 boundary，不得假裝已啟用。
