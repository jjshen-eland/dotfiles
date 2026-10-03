# Project Transfer workflow

依 workflow 的 Transfer prerequisite 讀齊後執行；普通 authority 見 [authority.md](authority.md)。

## Transfer 模式

本模式建立可由另一 runtime／host／owner 獨立驗證的 durable transfer，**不 commit、不 push、不 merge、
不改 repo 權限**。產物留在 working tree，只有後續由 current steward 明確叫用 Log 才能組成 transfer
commit；credentials 永遠不進 git。Memory on/off 只影響 optional cache，不能改變 transfer readiness。

使用者若把合法 transfer 與「把 credentials 寫進 tracked 文件」或「現在 commit」綁在同一個要求，
**只拒絕這些越界子要求，當輪繼續安全的 Transfer 流程**：盤點 `.env.example` 的 key 名稱、
產生不含值的 draft guide，並把缺 recipient／安全交付管道列為 `BLOCKED`。不得因拒絕 secret
要求就整體停下或反問「要不要開始」；也不得因使用者明說 commit 就改寫本模式的 no-commit 邊界。

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
6. 盤點 `.env.example` 或等價設定範本、掃描硬編碼 secrets；秘密走 gitignored 檔與安全通道。Credential
   plan 若選 repo-local artifact，只把 repo 與相對 path 傳給
   `<project-scripts>/verify-transfer-credential.sh <repo> <repo-relative-artifact>`：helper 只驗
   tracked／ignore／symlink／mode metadata，不讀或輸出內容。exit 0 且 `verdict: PASS`（group／other 無任何權限，
   即 private mode）才可通過；exit 1 維持 `BLOCKED`，exit 2 是 BROKEN。Transfer mode 不自行 `chmod` 或改權限；
   改走密碼管理器且沒有 local artifact 時不建立檔案或臆造 mode gate。以 fresh clone 可取得的 contract、docs、
   commands 與非秘密 fixture 驗證接手者能 setup、跑 QA、定位 active state 與歷史；不把「兩邊 memory 都開著」
   當 self-contained evidence。
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
