# Wait4me — Evals

> 開發／迭代用的 portable behavior oracle，**不從 SKILL.md body 連結**。
> 所有通知驗證使用 local capture／fake；不得呼叫 live Notification Center。

## A. Triggering tests

| # | 使用者輸入 | 期望 |
|---|---|---|
| T1 | `$wait4me`／`$wait4me on` | ✅ 只為目前前景 session 啟用 |
| T2 | `$wait4me off`／`$wait4me status` | ✅ 停用或唯讀回報目前 session |
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
- `status` 不改變狀態；重複 `on`／`off` 幂等。

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
- payload 為單行且不超過 200 Unicode characters；不得包含 command、prompt、transcript、raw
  tool input、Authorization 或 API key。
- notification task identity 固定且可辨識；測試只用 local capture，不送 live notification。

### W6 — 雙 runtime parity

- Claude Code／Codex 使用同一 canonical workflow、script 與 eval oracle；兩端只有薄入口與 hook wiring。
- 同一組 hook fixture 在兩端產生等價的 enable／disable、wait、approval、dedup 與 failure-isolation 結果。
- 任一 runtime 缺少必要 hook capability 時 fail closed 並回報 boundary，不得假裝已啟用。
