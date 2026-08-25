# Skill portability contract

這是本 repo 對 Claude Code／Codex skill authoring 的單一跨 runtime 契約。兩邊各自的 guide 只補官方格式、
runtime metadata、驗證器與工具差異；skill 的產品行為、共享資源與移植判準以本檔為準。

## Portable by default

在任一 harness 新建 skill，預設同時交付 Claude Code 與 Codex 可發現的入口。最初的 writer 或實體目錄不決定
平台歸屬；只有可證實另一 runtime 缺少必要能力時才可做單平台例外，且必須留下 failure eval、相容邊界與重議條件。

跨 runtime skill 採三層：

1. **Shared behavior core**：目的、輸入／輸出、分類、gate、失敗語意與平台無關的 workflow，只保留一份。
2. **Thin runtime entries**：Claude Code／Codex 各自有可發現的 `SKILL.md`，只處理 invocation、tool binding、
   metadata 與該 runtime 無法共享的 lifecycle。
3. **Shared resources**：共同 references、scripts、templates、schemas 與 eval oracle 只有一個 canonical copy；另一端
   用 nested symlink 或同等 linkage 共用。不要 whole-directory symlink，否則兩端無法獨立演進薄入口與 metadata。

這是新 skill 與有 topology RED 的改版預設；已通過雙端 eval 的既有 linkage 不因本規則自動重構，仍依 preflight
與最小修正原則處理。

Shared core 不得出現 runtime 私有工具或私人安裝路徑。兩端可以使用不同 primitive，但必須產生相同的可觀察
語意與 fail-closed 結果。不要為了逐字相同而複製兩份 workflow，也不要讓 adapter 重新定義 core 的 gate。

## Existing-skill preflight

在讀舊方法、派 clean-room agent 或修改 existing skill 前，主 writer 必須先判斷它是未移植、已移植，或已移植後
發生 regression：

1. 依 root documentation route 執行
   `scripts/doc-governance.py find '<skill-name> portable migration decision milestone dead end'`。
2. 同時檢查 Claude／Codex 兩端的 tracked tree、`readlink`／realpath，resolve every symlink 到實際 canonical source；
   不得用 `claude/`、`codex/` 路徑名稱推論 ownership。
3. 讀既有 defaults、scripts、metadata、eval oracle、compatibility contract，以及命中的 decision／milestone／dead end。
4. 把當前 topology、canonical copy、雙端入口與既有 live evidence 列成 baseline，才可定義 RED。

Clean-room agent 可在完成上述分類後重建 behavior contract；它不能判斷 migration status，也不能取代 history／linkage
查證。若 skill 已 portable，先以 frozen behavior eval 重現具體 regression，再做最小修正。改變 canonical location、
adapter 分層或 linkage 等 topology，必須有新證據並以 `supersedes:<decision-id>` 明確取代舊決策；測試不得和實作
一起改成只會認新 topology，而漏掉舊 compatibility contract。

## New-skill workflow

1. 先寫 runtime-neutral behavior contract 與 with／without-skill eval；不要從任一 harness 的工具名稱開始設計。
2. 選一份 canonical shared core，建立兩個 thin entries，並明列 linkage；canonical 在哪一棵 tree 不代表由哪個
   runtime 擁有。
3. 先用 native primitive。只有 frozen RED 證明 ordering、attribution、mutation safety 或其他脆弱 invariant 不承重時，
   才加入 deterministic helper；helper 必須有界、無隱式 retry，並公開失敗而非自行降級。
4. 使用同一 realistic query／fixture 驗證 Claude Code 與 Codex：trigger、核心結果、主要 failure path、未授權 mutation、
   shared resource identity，以及任一端接手後不依賴前一 runtime 的 private session state。
5. 各端 validator、behavior eval、repo tests 與必要 live forward test 全綠後才算 portable；單端 GREEN 不得宣稱完成。

跨 runtime 接手不延續 action authorization，也不把 runtime-local memory、session ID 或私有 telemetry 當作 repo 事實。
需要跨 session／writer 保存的專案狀態走 repo 已採用的 durable authority；skill 本身不要另建狀態 store。

## Review and rollout gate

- Review shared behavior 與 runtime adapter 分開進行；reviewer 必須能指出 finding 屬於 core、Claude entry 或 Codex entry。
- Packaging gate 驗兩端 description／trigger 相容、entry 薄、shared resources 指向同一實體、eval oracle 不複製。
- Behavior gate 驗相同 fixture 的 normalized outcome；平台專屬 evidence 可以不同，但不得改變 gate 語意。
- 任何 harness 缺能力時 fail closed，回報 capability boundary；不得由另一端的成功冒充雙端完成。
- Ship 前記錄 canonical topology、雙端 live evidence 與重議條件。之後換 writer 時以 repo evidence 重驗，不靠前一
  harness 的對話或記憶。
