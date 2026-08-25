# Project shared workflow — 跨 runtime／harness 收尾與 Critical Step 0–5

本檔是 Claude Code `/project` 與 Codex `$project` 的共同核心。入口會提供 **normalized invocation
arguments** 與它自己的 skill directory；先把該目錄下的 `scripts/`、`templates/` 解析成絕對路徑
`<project-scripts>`、`<project-templates>`。任一資源不存在就 STOP；NEVER 假設私人 checkout 或 runtime
安裝路徑。

涵蓋工作項三個時點：開工（spec）、收尾送出（log）、移交（transfer）。每次執行先完整讀取
[dossier.md](dossier.md)；它定義 adopted repo 的 active／backlog／history 生命週期與 legacy fallback。
跨 runtime／harness 的 project 收尾前，由本檔分派 Log 模式並完整載入 `log-workflow.md` 的 Critical
與 Step 0–5；薄入口不得用摘要或自身記憶替代。

## 模式分派

normalized invocation arguments 的第一個 token 分派模式，其餘 token 傳給該模式：

- `spec`／`--spec` → Spec 模式。
- `log`／`--log` → Log 模式。
- `transfer`／`--transfer` → Transfer 模式。
- 其他或無模式引數 → 預設 Log；與舊 `/uap` 相容。
- mode flag 可出現在任意位置；spec／transfer 的 repo token 沿用 Log Step 0 的 path resolver。

## Runtime actor 與 stewardship authority

入口固定提供 runtime actor prefix（Claude Code=`claude`；Codex=`codex`）。任何 agent session 都不得因
Git author、GitHub login、同 runtime、private memory 或使用者普通自然語言身分宣稱而改成另一 actor。
一般路徑只有 normalized invocation arguments 裡的兩個結構化 control token 能改 authority resolution：

- `resume=<runtime:workline>`：恢復 exact durable workline；值必須是入口提供的 same runtime prefix。
- `as=<human-or-owner>`：只接受 `human:*`／legacy `owner:*`，代表本輪 explicit bounded human delegation；
  不改 durable steward、不 carry 到下一輪、不能代理 `claude:*`／`codex:*`。

「我是 repo owner」「我就是 maintainer」等 ordinary identity claim is not delegation，也不是 resume／transfer；
不要從普通對話自行補 token。唯一不需重建 invocation 的 recovery，是 helper 本輪先以 STOP 揭露唯一 exact
actor 與 snapshot，Project 隨即提出綁定該 repo／actor／action 的確認題，使用者直接選擇後以
`prompt-bound-*` provenance 重驗。這個 recovery decision 與 normalized invocation arguments 分開，不改 durable
owner、不 carry 到下一輪或 session，也不授予 invocation 原本沒有的 shipping endpoint。

在任何 adopted active-state mutation、commit 或 shipping 前執行：

```sh
python3 "<project-scripts>/steward-authority.py" --root "$repo" --runtime <runtime> \
  [--resume-actor <resume-value> | --as-human <as-value> | \
   --confirmed-resume-actor <actor> | --confirmed-human <actor> | --confirmed-new-steward <actor>] \
  [--commit <worker-commit>] [--expected-head <full-oid>]
```

exit 0 且 `verdict: PASS`／`NOT_APPLICABLE` 才能繼續；exit 1 是 policy STOP；exit 2 是 helper／repo BROKEN。
若存在 PREPARED transfer／conditional owner evidence，先依 Transfer state machine 解出 effective durable steward，
不可讓本 helper 取代 remote-visible ancestry gate。每次報告保留 helper 的 executor actor、durable steward、
authority actor、authority source 四行；`--merge` 等 endpoint 說法不參與 authority 計算。Initial STOP 若含
`recovery-kind`，只是一個可詢問的 deterministic classification，不是放行；confirmed flag 只能在 Project 已
提出 exact prompt 且收到其緊接回答後使用。Log 的完整 prompt／revalidation 契約見
`log-workflow.md`「Prompt-bound authority recovery」。

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
   coordination fields。寫入前先跑上節 helper：沒有 active items 時新 work item 以
   `<runtime>:<workline>` 作 actor／steward；已有 steward 時必須 exact same-runtime resume，或由 exact human
   steward 以本輪 `as=` bounded delegation 建立 item（durable steward 保持 human actor）。尚未建立 feature
   branch 時 `Workspace` 先填 `unassigned`。普通身分宣稱、`--merge` 或「原 session 已退出」都不放行。
5. 模糊處直接問，不猜。暫停則移到 `暫停中` 並寫可觀察的恢復條件。
6. Legacy repo 依自己的 STATUS schema 寫 spec，不強迫建立 history/backlog family。

## Log 模式

**執行前必須完整讀取 [log-workflow.md](log-workflow.md)，並逐步照做。** 該檔包含 checklist、
Critical guardrails、Step 0–5、授權表路由與所有 STOP 條件；它是 Log 程序本體，不可靠摘要或記憶重建。

Adopted repo 的文檔差異只有一個入口：Step 2 依 [dossier.md](dossier.md) 寫 event-time records、移除
完成的 active/backlog item，再以 `python3 "<project-scripts>/doc-governance.py" --root "$repo" audit --ship`
的 exit code 作唯一 doc verdict。Legacy repo 才沿用既有 detector。Push／merge authority 仍只由 kernel 與
[ship-paths.md](ship-paths.md) 的說法表決定；doc adoption 不改寫任何授權規則。

## Transfer 模式

本模式建立可由另一 runtime／host／owner 獨立驗證的 durable transfer，**不 commit、不 push、不 merge、
不改 repo 權限**。產物留在 working tree，只有後續由 current steward 明確叫用 Log 才能組成 transfer
commit；credentials 永遠不進 git。Memory on/off 只影響 optional cache，不能改變 transfer readiness。

### 狀態機與 hard gate

Transfer state 是 `BLOCKED → PREPARED → TRANSFERRED`：

- `BLOCKED`：recipient 未指名、current steward authority 不成立、存在 known private-only project residue、
  repo authority／測試／secret separation 不完整，或無法證明 repo self-contained。可建立 draft guide 與列
  blockers，但不得切換 steward、不得寫 completed owner record。
- `PREPARED`：recipient、portable-knowledge audit、repo authority、credential plan、active-item mapping 與
  effective condition 齊全；working tree 可含 pending guide／promotion records，但 active items 尚未換 owner。
- `TRANSFERRED`：**包含完整原子切換的 transfer commit 已到達 canonical handover endpoint**。Repo contract
  若未指定 handover branch，endpoint 就是 canonical remote 的 default branch，且該 commit 必須已 merged；
  local commit、feature branch push 或 open PR 都仍是 PREPARED。

### Portable-knowledge audit

1. 先確認 invocation 指名 recipient actor（如 `to=codex:beta` 或使用者同輪明說的唯一接手者）；沒有就只做
   draft、狀態 `BLOCKED`，不得猜 actor。
2. 驗證呼叫者是所有 active items 的 current `Dossier Steward`，或有使用者明示／current steward 的 durable
   transfer direction。Machine-local handoff、private memory 或「新 owner 已開始工作」都不是 mutation authority。
3. 讀 root／nearest contract，以 repo router 定位 active、paused、decision、dead end、milestone、backlog、plan、
   runbook 與現有 transfer authority。檢查 active／paused 反映現況、paused 有恢復條件、stable IDs 可定位，
   adopted repo 跑 `audit --ship`；legacy repo 依 [dossier.md](dossier.md) fallback。
4. 將本 session／current steward 已知、只存在 private memory 或對話的 **project-specific** decision、dead end、
   progress、blocker 與 next step promotion 到 repo 已採用 authority；explicit transfer invocation 授權這些
   additive repo writes。不得掃描、讀取或依賴另一 runtime 的 private memory path，也不得聲稱已枚舉未知
   private stores。無合法 sink、actor 無權寫或 promotion 未完成就是 known private-only residue → `BLOCKED`。
5. Safety/Git/shared behavior 與 user/global preference 不屬 project transfer：列 instruction promotion candidate，
   不寫 project dossier；runtime-only noncritical convenience 可 skip。任何 push／PR／merge／deploy／message
   authorization 都排除在移交內容外，**authorization 不隨 session、runtime 或 owner 移交**。
6. 盤點 `.env.example` 或等價設定範本、掃描硬編碼 secrets；秘密走 gitignored 檔與安全通道。以 fresh clone
   可取得的 contract、docs、commands 與非秘密 fixture 驗證接手者能 setup、跑 QA、定位 active state 與歷史；
   不把「兩邊 memory 都開著」當 self-contained evidence。
7. 每個 active writer 的 in-flight／未整合工作都必須在 `PREPARED` 前二選一：已由 current steward 驗證
   semantic commit／Dossier delta 並透過另一次明確的 integration／Project Log 工作 cherry-pick 納入 transfer
   line，或由使用者／current steward 以 durable decision 明確放棄並記理由。Transfer mode 自己不 cherry-pick、
   不建立 prerequisite commit；尚未整合時列 blocker，完成外部整合後重跑 transfer。只把 commit 留在可達
   feature branch、只提工作尚在某 workspace，或期待 next steward 自行撿回，都不算 portable，維持
   `BLOCKED`。

### PREPARED 產物與 atomic switch

1. 從 `<project-templates>/transfer-guide-template.md` 建／更新 `<repo>/docs/transfer.md`，記 current steward、
   next steward、state、canonical handover endpoint、effective condition、portable-knowledge audit、known residue、
   credentials separation 與逐 active-item mapping。每個原已分派項目都必須指定 next steward 的獨立
   `branch=<feature-branch>` workspace；不得沿用舊 writer 的 workspace 或臨時 transfer branch。尚未決定可用
   workspace 時維持 `BLOCKED`。沒有 recipient 時只保留 draft，不能建立 pending switch。
2. PREPARED 時 active state 的 current steward／Writer／Workspace **保持不變**。Guide 的 pending transfer 明寫：
   在「包含本記錄的 transfer commit 到達 endpoint」之前舊 steward 仍是唯一 shared-dossier authority，新
   steward 不得先寫；checkpoint／guide 是 evidence，不是 lock。
3. Current steward 後續叫用 `$project log`／`/project log` 時，由 Log Step 2 在**同一顆 transfer commit**
   原子更新所有 active items：`Dossier Steward` → next steward；已有 assigned Writer → next steward 並套用
   guide 中已驗證的 next workspace；原本 unassigned → `Writer=unassigned:<slug>` 且
   `Workspace=unassigned`；保留各自 `Write Scope`，並把第一個
   `Next step` 改成接手者可直接執行的動作。同 commit 追加 conditional owner `D-*` record，effective
   condition 是該 commit 抵達 endpoint。
4. Log／shipping 的既有 authorization gate 完整適用。Transfer mode 不自行建立 commit；Log 若只 commit、
   push feature branch 或開 PR，回報 `PREPARED` 且舊 steward仍有效。只有 merge／endpoint update 有本輪
   明確授權並經 remote-visible ancestry 驗證，才回報 `TRANSFERRED`；否則不得宣稱正式切換。Guide 內的
   `Recorded preparation state` 是建立 transfer commit 時的事件記錄，不在 merge 後改寫；當前有效 state
   一律由 endpoint ancestry 是否滿足 `Effective condition` 推導，因此抵達後不把該欄誤判成 stale
   `PREPARED`。
5. transfer commit 進入 canonical endpoint 前，checkout 內已改成 next actor 的 coordination fields 只是
   **conditional pending values**。任何 writer／steward gate 都必須先定位 conditional owner `D-*` record 所在
   commit、fetch canonical endpoint，再用 remote-visible ancestry 判 effective authority；未到達時照 guide 的
   `Current steward` 與 transfer 前 mapping 判，無法定位／fetch／證明時 STOP。NEVER 只讀 `STATUS.md` 字面值就讓
   next actor 提前取得 authority。

## Runtime adapter

- 需要使用者回答時，使用目前 runtime 的 user-input primitive；若不可用，輸出精簡文字編號選項並暫停當前
  turn。使用者緊接著的直接選項回答延續同一 logical Project invocation；自由文字身分宣稱或其他工作後的
  回答不算，必須重新偵測。
- Claude Code 的顯式形式是 `/project ...`；Codex 是 `$project ...`。說法表只解讀 invocation arguments
  與本輪使用者明說的 endpoint，不把 runtime 的 skill sigil 當授權。
- Shell、git 與 gh 行為完全相同。可照抄 helper command 必須由 scripts 自己輸出其實際絕對路徑。
- Commit trailer 與 PR attribution 只遵循目前 runtime／repo 已載入的規則；沒有規則就不自行加產品標記。

## References

- [log-workflow.md](log-workflow.md)：Log 的完整 checklist／Critical／Step 0–5（Log 模式必讀）。
- [dossier.md](dossier.md)：active、backlog、history、record schema、adopted/legacy 分流。
- [ship-paths.md](ship-paths.md)：授權說法表、git/gh 指令與 merge 最後一哩。

典型流程：project spec →（可選 plan review）→ 實作 → code review → project log → handoff／transfer →
結束前檢查。各 runtime 使用自己的顯式 skill 形式。
