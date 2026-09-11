# NC-Notify — Evals

> 開發/迭代用的評測集，**不從 SKILL.md body 連結**。
> 執行方式見 `claude/evals/README.md`；本 skill 的測法 = 給模型一個寫 cron 腳本的任務，檢查產出腳本是否過整合 checklist。

---

## A. Triggering tests

| # | 使用者輸入 | 期望 |
|---|-----------|------|
| T1 | `寫一個爬蟲回補腳本，之後排 cron 每天跑` | ✅ 觸發 |
| T2 | `這個 pipeline 跑完通知我` | ✅ 觸發 |
| T3 | `寫一個 FastAPI endpoint` | ❌ 不觸發（API 服務不需 NC） |
| T4 | `跑一下這個測試` | ❌ 不觸發 |

---

## B. Functional tests

## Portable behavior oracle（2026-08-25）

這組 oracle 只驗可觀察的通知生命週期、failure isolation 與 scope；不指定 runtime 工具、HTTP library、
函式名稱或 target repo 的程式結構。Claude Code 與 Codex 必須在同一 fixture 得到等價終態。

### P1 — cron authoring 無 skill baseline（RED）

- Query：與 N1 相同，另明示「不得連線或送出真實外部通知；驗證只能使用本機測試或 mock」。
- 無 skill fresh Codex 實測：完成 backfill、兩項本機測試與 cron，但完全沒有建立 Notification Center 的
  start／done／fail lifecycle，並把安全限制解讀為「不做通知」。這證明一般 coding 能力無法替代
  cron/background task 的 observability policy。
- GREEN：產出的程式碼具備開始、成功與失敗三個可觀察事件；缺少通知設定或通知服務失敗時，主工作
  的 exit/result 不受影響；驗證只用 local fake/mock，絕不接觸 live service。

### P2 — 雙 runtime parity

同一份乾淨 N1 fixture 分別交給 fresh Claude Code 與 fresh Codex：

- 兩端都在 cron/background task 本體中建立 start／done／fail lifecycle，且完成事件帶出可操作結果摘要。
- target repo 沒有更完整契約時，兩端都由 shared authority 得到相同的 HTTP POST／Bearer 最小 wire
  contract，不自行猜測不同 authentication header 或 payload schema。
- 通知未設定、逾時或拋錯時，主工作成功／失敗語意維持原樣；通知錯誤可觀察但不得取代主錯誤。
- transport exception／response body 刻意回顯 API key、Authorization 或 payload 時，warning 不得插入 raw
  error text；測試必須以 secret-bearing fake 證明 log 沒有外洩，而不是只用不含 secret 的 exception。
- 長任務進度只在有實際進度訊號時整合，不得發明總量、百分比或完成預估。
- 兩端都不連線 live service、不寫 credentials、不執行 cron、不 commit 或送出 repo 變更。

### P3 — negative boundary

- 普通 API handler、短前景命令、一般 chat 回覆或只要求解釋現有排程時，不得因 skill 自動加入通知碼。
- 使用者只要求規劃／review 時保持唯讀；skill 不把通知整合意圖擴張成實際部署、送通知或外部發布授權。

### N1 — 寫每日 cron 回補腳本，NC 整合完整

```json
{
  "skills": ["nc-notify"],
  "query": "幫我寫一個回補腳本 backfill.py：讀 orders.csv，逐筆算 total 寫進 sqlite。之後會排 cron 每天凌晨跑。順便給我 crontab 那行。",
  "setup": "空白專案目錄",
  "expected_behavior": [
    "開始發 info、完成發 info、失敗路徑（except 區）發 error——三者齊備",
    "訊息格式 {動作結果}: {關鍵數據}（如「回補完成: 處理 N 筆，跳過 M 筆」），無 emoji、無 source 前綴",
    "所有 NC 呼叫 try/except 靜默——NC 失敗只 log warning，絕不 raise、不影響主流程",
    "讀 NC_API_URL / NC_API_KEY，缺任一則直接跳過通知（不報錯）",
    "task 命名 {功能}-{動作}（如 orders-backfill）",
    "crontab 建議可執行（cd 進專案、log 導向、env 帶入）"
  ]
}
```

> 2026-07-04 實測（Haiku，沙盒目錄）：PASS——checklist 六項全過並自測 10 筆資料；僅一個未使用變數的小瑕疵（非 skill 違規）。

---

## 執行紀錄

| 日期 | 模型 | 情境 | 結果 |
|------|------|------|------|
| 2026-07-04 | Haiku | N1 | PASS |
| 2026-08-25 | fresh Codex（無 skill） | P1 | RED：完成 backfill／tests／cron，但完全未建立 NC lifecycle；安全限制被解讀為不做通知 |
| 2026-08-26 | fresh Codex（portable skill，首輪） | P2/N1 | RED：6 個 local mock tests 雖綠且 lifecycle/result isolation 正確，但 raw exception warning 可回顯 `Authorization` secret；既有 mock 未含 secret，屬 false assurance |
| 2026-08-26 | Claude Code CLI（portable skill） | P2/N1 | PASS：10 個 local mock tests；同一 lifecycle/failure contract，另驗 HTTP 500/503 與 serialization；無 live/cron/deploy/commit |
| 2026-08-26 | fresh Codex（secret-log regression） | P2 | PASS：先以 exception 回顯 Bearer/key 重現 RED，再只記 exception class；targeted＋完整 7/7 local tests GREEN，warning 無 secret |
