# Project Transfer workflow

依 workflow 的 Transfer prerequisite 讀齊後執行。移交的對象是另一個人（例如新同事）；同一使用者在不同
runtime／session／主機間接續不需要移交，依 [dossier.md](dossier.md)「接續（內容契約）」即可。

## Transfer 模式

本模式產出讓接手者不靠移交人就能掌握全貌的移交指南草稿與缺項清單，**不 commit、不 push、不 merge、
不改 repo 權限**。產物留在 working tree，之後由明確叫用的 Log 送出；credentials 永遠不進 git。Memory on/off
只影響 optional cache，不能改變移交是否完整。

使用者若把合法 transfer 與「把 credentials 寫進 tracked 文件」或「現在 commit」綁在同一個要求，
**只拒絕這些越界子要求，當輪繼續安全的 Transfer 流程**：盤點 `.env.example` 的 key 名稱、產生不含值的
draft guide，並把缺接手者／安全交付管道列為缺項。不得因拒絕 secret 要求就整體停下或反問「要不要開始」；
也不得因使用者明說 commit 就改寫本模式的 no-commit 邊界。

### Portable-knowledge audit

1. 讀 root／nearest contract，以 repo router 定位 active、paused、decision、dead end、milestone、backlog、plan
   與 runbook。檢查 active／paused 反映現況、paused 有恢復條件、stable IDs 可定位；adopted repo 跑
   `audit --ship`，legacy repo 依 [dossier.md](dossier.md) fallback。
2. 將本 session 已知、只存在 private memory 或對話的 **project-specific** decision、dead end、progress、blocker
   與 next step 寫進 repo 已採用的 authority；explicit transfer invocation 授權這些 additive repo writes。不得
   掃描、讀取或依賴另一 runtime 的 private memory path，也不得聲稱已枚舉未知 private stores。沒有合法 sink 的
   事實列為殘留缺項。
3. Safety／Git／shared behavior 與 user／global preference 不屬 project transfer：列 instruction promotion
   candidate，不寫 project dossier。任何 push／PR／merge／deploy／message authorization 都排除在移交內容外，
   **authorization 不隨移交**。
4. 盤點 `.env.example` 或等價設定範本、掃描硬編碼 secrets；秘密走 gitignored 檔與安全通道。Credential plan 若
   選 repo-local artifact，只把 repo 與相對 path 傳給
   `<project-scripts>/verify-transfer-credential.sh <repo> <repo-relative-artifact>`：helper 只驗
   tracked／ignore／symlink／mode metadata，不讀或輸出內容。exit 0 且 `verdict: PASS`（private mode：group／other 無任何權限）
   才算通過；exit 1 是缺項，exit 2 是 BROKEN。Transfer mode 不自行 `chmod` 或改權限；改走密碼管理器且沒有
   local artifact 時不建立檔案或臆造 mode gate。
5. 以 fresh clone 可取得的 contract、docs、commands 與非秘密 fixture 驗證接手者能 setup、跑 QA、定位 active
   state 與歷史；不把「兩邊 memory 都開著」當作完整的證據。
6. 在途工作（未合併的 branch、未 commit 的變更）逐項判定：已合併，或以 decision record 明確放棄並記理由；只留在
   feature branch／worktree 的工作列為缺項。

### 產物與移交未完成條件

1. 從 `<project-templates>/transfer-guide-template.md` 建立或更新 `<repo>/docs/transfer.md`，記接手者、
   portable-knowledge audit 結果、credentials separation、進行中工作的指標與缺項清單。
2. 下列任一成立時，移交未完成，指南維持草稿並逐項列出缺項：未指名接手者；`verify-transfer-credential.sh`
   非 PASS；仍有只存在對話或私人記憶的專案事實；在途工作未合併也未明確放棄。缺項解除前不得在指南或歷史紀錄
   宣稱移交完成。
3. 指南與 audit 補寫的紀錄由之後明確叫用的 `$project log`／`/project log` 送出，Log／shipping 的既有授權
   gate 完整適用。Repo 權限調整由人完成，本 workflow 不代做。
