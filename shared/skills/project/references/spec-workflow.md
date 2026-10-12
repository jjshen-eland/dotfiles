# Project Spec workflow

依 workflow 的 Spec prerequisite 讀齊後執行；接續規則見 [dossier.md](dossier.md)「接續（內容契約）」。

## Spec 模式

開工儀式：把願望變成可驗證的 active contract。本模式只寫文檔，不改 code、不 commit。

1. 判斷 adoption：`.doc-governance.json` 與 `scripts/doc-governance.py` 兩者皆有＝adopted；兩者皆無＝legacy；
   只存在一個＝BROKEN，停止且不要回退 legacy。
2. Adopted repo 先確認 target 的 config/core adoption 完整且 core 通過 trusted-core 比對，再執行
   `python3 "<project-scripts>/doc-governance.py" --root "$repo" find '<工作問題>'`
   查相關 decision／dead end；命中的 stable IDs 稍後寫入 active item 的 `關聯`。不得先整批讀 archive。
3. 無 `STATUS.md` 時，adopted repo 從 `<project-templates>/STATUS-template.md` 建立；legacy repo
   從 `<project-templates>/STATUS-legacy-template.md` 建立。建立後確認專案定位；撞名的領域產物不得覆寫。
4. 在 `進行中` 寫 Context／Goal／Acceptance Criteria／Constraints／進度／下一步／關聯 IDs；target config 以
   `status_schema.active_item_contract` 宣告必填欄位時一併滿足。已有同一工作項時更新它，不另建重複項；工作樹有
   不是本批做的變更，或該工作的 branch 正在另一個 worktree checkout，就停下問使用者。
5. 模糊處直接問，不猜。暫停則移到 `暫停中` 並寫可觀察的恢復條件。
6. Legacy repo 依自己的 STATUS schema 寫 spec，不強迫建立 history/backlog family。

### Spec 成功後的 Log invocation 提示

Spec 寫入與必要驗證成功後，本輪未要求下一步 Log 時，直接回報結果，不做本節額外 probe 或出題。
若使用者在本次明確要求Spec後接續Log及其endpoint，完成Spec後直接進入同一logical workflow的Log，
載入所需references，不再要求重輸invocation。上一個已結束invocation或session的endpoint authorization
不 carry；提示命令本身也不是授權。尚未要求Log時，只提供可選用的命令，例如使用者已選定 merge 時：

```text
下一步請輸入：
$project --merge
```

Claude Code adapter 將 `$project` 換成 `/project`。Endpoint flag 取自使用者為下一步明確選定的終點，依
[ship-policy.md](ship-policy.md) 說法表（只有需要提示 endpoint 時讀取）正規化；未選定就不得自行預填。
若使用 runtime UI 選項，每個 option value 必須送出完整的 `$project ...`／`/project ...` invocation；只回傳編號或
顯示標籤不算新的 explicit invocation。
