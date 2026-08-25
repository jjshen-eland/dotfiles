# Portable Notification Center integration workflow

目的：讓排程與無人值守工作具有可操作的生命週期 observability，同時確保通知永遠是旁路能力，不改變主工作的成功、失敗或錯誤證據。

## Scope and authority

在建立或修改 cron job、scheduler task、crawler、backfill、training／annotation pipeline 或其他無人值守背景工作時套用本流程。由 API handler 啟動但脫離 request lifecycle 的 queue/background job 仍屬背景工作；一般 request handler、短前景命令、單純跑測試、解釋或只讀 review 不屬於整合範圍。

使用者明確要求替現有工作加入完成或進度通知時同樣適用。若只是希望目前這次互動任務結束後收到通知、沒有要修改任何程式或 pipeline，不要臨時對 live service 發 request；說明 capability boundary，或請使用者指定要整合的工作。

這個 skill 只授權使用者已要求的程式碼／設定修改。它不授權實際部署排程、啟動背景工作、傳送 live 測試通知、建立或修改 credentials、commit、push、PR 或其他外部發布動作。Plan／review 請求保持唯讀。

## Confirm the integration contract

先找 target repo 已採用的通知 client、wrapper、設定名稱、測試 fake 與通知 schema；repo-local contract 優先。使用者提供或 repo 可驗證的完整 Notification Center 契約存在時，才使用其中的進階能力。

沒有完整契約時，明告使用者此次只能交付最小相容整合，且只使用以下已確認介面：

- 設定由 `NC_API_URL` 與 `NC_API_KEY` 取得；缺任一項時通知 no-op，主工作照常執行。
- 將 `NC_API_URL` 視為完整通知 endpoint，以 HTTP `POST` 傳送 JSON，並以
  `Authorization: Bearer <NC_API_KEY>` 驗證；這是最小 wire compatibility contract，不是由 target
  repo writer 自行選擇的實作偏好。
- 最小 notification data 為 `message` 與 `level`；需要關聯同一工作時可加 `task`。
- 不臆造 status、deduplication、recipient、progress schema 或其他進階欄位。

不要依賴私人 home path、某台工作機才存在的文件或 runtime-local memory。不要把 secrets 寫入 source、測試 fixture、command example、crontab 或 log。

## Integrate the lifecycle

依 target repo 的語言、dependency 與既有 abstraction 實作；不要為相同目的平行建立第二套 client。保持通知 wrapper 小而可測，並讓所有 call sites 具有同一個 failure contract。

必要的無人值守工作包含三個事件：

1. `start`：主工作開始前送出一般資訊。
2. `done`：只有主工作真正成功、必要 transaction/output 已完成後才送出一般資訊；不得從 `finally` 發成功通知。
3. `fail`：捕捉主工作錯誤後嘗試送出錯誤通知，再保留原 exception、exit code 與 failure evidence。

非致命但可操作的異常可用 warning；部分成功的最終分類跟隨 target job 的既有 success contract，不由通知層重定義。

預期超過五分鐘的工作，在已有可信 progress signal 時加入可關聯的進度事件。使用穩定的 kebab-case `{feature}-{action}` task identity。未知總量、百分比、ETA 或完成時間不得自行推估；沒有可靠進度訊號時，保留 start／done／fail 並向使用者指出 progress 尚無可信資料來源。一次性人工腳本預期超過十分鐘時，只提出整合建議，除非使用者要求，不自動擴張修改範圍。

## Preserve the main result

**Notification failure never changes the main task's result.**

- 缺少設定時直接略過通知，不把它當成 job failure。
- Transport exception、timeout、serialization error 或非成功 response 都是 notification failure；留下不含 secret 的 warning，然後繼續主流程。不要直接插入 raw exception text、response body、request headers 或 payload，因為 transport error 可能回顯 API key／Authorization；只記 exception class、已清理的 operation/status 等安全摘要。
- Notification code 不向主工作拋錯，不覆蓋原 exception，不把成功改成失敗，也不把失敗改成成功。
- 主工作已失敗且 fail notification 也失敗時，最終仍回傳或拋出原始主錯誤；notification warning 只是附加證據。
- 不做無界 retry。若 target repo 已有明確 retry/dedup contract，才沿用其有界行為。

## Message contract

訊息使用單行 `{action result}: {key facts}`，結果在前、可操作數據在後，最多 200 個 Unicode characters。移除換行；不自行加 emoji，也不重複服務會附加的 source label。

完成訊息使用實際已知數據，例如處理量、略過量、輸出位置或耗時。失敗訊息保留足以定位工作的摘要，但不包含 credentials、完整敏感 payload 或無界 stack trace。Level 使用 `info`、`warning`、`error`；不要發明其他值。

## Verify without live side effects

新增或修改整合時，用 target repo 的 local fake/mock 測試，不連線 live Notification Center：

- 成功路徑依序觀察到 start 與 done，且沒有 fail。
- 主工作失敗時觀察到 start 與 fail，沒有 done；原 failure type／exit 保持不變。
- 缺少任一設定時不送通知，主工作仍依自身契約完成。
- Transport error、timeout 與非成功 response 只留下 warning；主工作結果不變。
- Mock exception／response 即使刻意回顯 API key、Authorization header 或 payload，warning 也不得包含該值；只用一般不含敏感資料的 error class／status 證據。
- Message 單行、長度有界、level 合法；task identity 在同一工作內一致。
- 有 progress 時只使用 fixture 提供的真實進度，不發明百分比或 ETA。

若同時產出 cron/scheduler 設定，使用正確工作目錄、絕對 executable／script path 與既有 log 方式。通知設定只能由 target repo 已採用的安全環境或 secret mechanism 提供；cron 通常不繼承 interactive shell 環境，因此缺少已驗證的供應方式時，將它列為部署 prerequisite，不把 secret inline。

完成時回報修改位置、三個 lifecycle 路徑、local mock 驗證結果、使用的 schema authority，以及仍需部署者提供的安全設定。不得因 mock GREEN 宣稱已部署或 live delivery 成功。
