# Project Spec workflow

依 workflow 的 Spec prerequisite 讀齊後執行；authority helper 與 local reassignment 見 [authority.md](authority.md)。

## Spec 模式

開工儀式：把願望變成可驗證的 active contract。本模式只寫文檔，不改 code、不 commit。

1. 判斷 adoption：`.doc-governance.json` 與 `scripts/doc-governance.py` 兩者皆有＝adopted；兩者皆無＝legacy；
   只存在一個＝BROKEN，停止且不要回退 legacy。
2. Adopted repo 先確認 target 的 config/core adoption 完整且 core 通過 trusted-core 比對，再執行
   `python3 "<project-scripts>/doc-governance.py" --root "$repo" find '<工作問題>'`
   查相關 decision／dead end；命中的 stable IDs 稍後寫入 active item 的 `關聯`。不得先整批讀 archive。
3. 無 `STATUS.md` 時，adopted repo 從 `<project-templates>/STATUS-template.md` 建立；legacy repo
   從 `<project-templates>/STATUS-legacy-template.md` 建立。建立後確認專案定位；撞名的領域產物不得覆寫。
4. 在 `進行中` 寫 Context／Goal／Acceptance Criteria／Constraints／進度／下一步／關聯 IDs。若 target
   config 啟用 `status_schema.active_item_contract`，另依 dossier 的「平行協作與 stewardship」填四個
   coordination fields。符合authority 的 local reassignment時先做兩欄更新並重驗；其他寫入前先跑authority helper：沒有 active items 時新 work item 以
   `<runtime>:<workline>` 作 actor／steward；已有 steward 時必須 exact same-runtime resume，或由 exact human
   steward 以本輪 `as=` bounded delegation 建立 item（durable steward 保持 human actor）。尚未建立 feature
   branch 時 `Workspace` 先填 `unassigned`。普通身分宣稱、`--merge` 或「原 session 已退出」都不放行。
5. 模糊處直接問，不猜。當前使用者已委任 turbo 時，依
   [Turbo execution contract](../../turbo/references/execution-contract.md) 補可驗證的預設與執行資訊；
   同 Goal／acceptance 的一般做法由 agent 調查後選擇，改變需求解讀的歧義仍須依使用者已選預設判定。
   暫停則移到 `暫停中` 並寫可觀察的恢復條件。
6. Legacy repo 依自己的 STATUS schema 寫 spec，不強迫建立 history/backlog family。

### Spec 成功後的 Log invocation 提示

Spec 寫入與必要驗證成功後，本輪未要求下一步 Log 時，直接回報結果，不做本節額外 probe 或出題。
若使用者在本次明確要求Spec後接續Log及其endpoint，完成Spec後直接進入同一logical workflow的Log，
載入所需references並重驗authority，不再要求重輸invocation。上一個已結束invocation或session的
endpoint authorization 不 carry；提示命令本身也不是授權。尚未要求Log時，只提供以下可選用的命令。
Endpoint flag 取自使用者為下一步明確選定的終點，依
[ship-policy.md](ship-policy.md) 說法表（只有需要提示 endpoint 時讀取）正規化；未選定就不得自行預填。下例以使用者已選定 merge 為例。

**Spec 本輪新建 active contract 時，同時建立 current-session workline assignment**：這只適用於
原本沒有 active item、使用者以本次明確工作要求授權 Spec 建立 exact same-runtime Writer／Steward，
或上節 local reassignment 已完整通過的情況。以剛寫入的 coordination fields 作最初 assignment snapshot，
取得其 fingerprint 與本輪 full HEAD，立即用
`--session-resume-actor <new-exact-actor> --expected-assignment <new-original-fingerprint> --expected-head <full-oid>`
重驗；不得先用 branch-derived ordinary gate 再改跑 `--resume-actor`，也不要求使用者補 `resume=`。Workspace
此時仍為 `unassigned`、其後依 branch-first 正常前進，都不撤銷這份指派；fingerprint 只有在 coordination／
item identity 實際改變時才失配。若原本已有 active item 且不符合既有 assignment／reassignment authority，
本段不會把 Spec invocation 自己變成接管授權，仍走原 gate。

對 same-runtime durable workline，在寫入 active contract 後重新執行一次authority helper：當次 session 工作線指派
仍有效時用其專用 flags／原 fingerprint／本輪 HEAD；否則刻意**不帶任何 `resume=`、`as=` 或 confirmed flag**。
只有 exit 0、`verdict: PASS`、executor actor 與 durable steward exact match，且 authority-source 為
`active-writer-workspace-match` 或 `current-session-workline-binding`，才可為每個 repo 封存一份
**current-session binding packet**：`canonical repo root`、`exact actor`、helper 輸出的原始
`assignment fingerprint`、active item identities 與其 Writer／Workspace／Write Scope／Steward snapshot，
以及本輪查證的 full HEAD。若來源是既有 `current-session-workline-binding`，沿用該 packet 的原始
fingerprint，不拿目前值替換。Packet 只活在同一段未壓縮對話與同一 logical workline；不得寫入
memory／checkpoint／repo authority store，也不得授予或 carry shipping endpoint。完成這個封存後才同時
顯示短版與明確版：

```text
下一步請擇一輸入：

短版：
$project --merge

明確版：
$project --merge resume=<exact-actor>
```

Claude Code adapter 將上述兩行的 `$project` 換成 `/project`，所以對應為 `/project --merge` 與
`/project --merge resume=<exact-actor>`；actor 的 runtime prefix 也必須與入口一致。若使用 runtime UI 選項，
每個 option value 必須送出完整的 `$project ...`／`/project ...` invocation；只回傳編號或顯示標籤不算新的
explicit invocation。

提示旁清楚說明：endpoint flag（本例 `--merge`）授權**這次新 Log invocation**的 endpoint；
`resume=<exact-actor>` 只精確綁定 durable workline，不新增、繼承或擴大 shipping authority。短版只適用於
仍在 helper 已驗證的 branch／workspace，或上述已重驗的當次 session 指派；明確版適合新session或需要消除actor歧義時。

若 post-Spec helper 未達上述 exact PASS，絕不顯示短版。只有再以 exact same-runtime
durable actor 執行 `--resume-actor <exact-actor>` 得到 PASS 時，才可單獨顯示含 `resume=<exact-actor>` 的明確版；
否則沿用既有 recovery／STOP。Repository authority `BROKEN`、`recovery-kind: none`、scope mismatch、stale
snapshot、cross-runtime 或 conflicting stewards 都不得因本提示新增確認或繞過選項。
