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
6. 在途工作以 remote default branch 為準逐項盤點，不憑印象：先 `git fetch`，再以 `git branch -a --no-merged
   origin/<default>` 列出未合併的 local 與 remote branch（含目前所在的 branch），`git rev-list --count
   origin/<default>..<default>` 檢查本地 default 有無未 push 的 commit，`git worktree list` 列出其他 worktree，
   `git status --short` 列出未 commit 變更。每一項判定為已合併，或以 decision record 明確放棄並記理由；其餘都寫進指南第 5 節並列為缺項。本次 Transfer
   自己產出、尚待 Log 送出的指南、紀錄與判分檔不算在途工作。
7. 接手驗收題組：依指南各節出題，涵蓋接手者必須能獨立完成或回答的事（至少含環境驗證、部署或排程、一項決策或
   死路）。`command` 題只能是唯讀、本地、沒有對外副作用的驗證（例如跑測試、lint、build）；部署、排程、對外服務
   或需要 credential 的事一律出 `answer` 題。題目寫進指南第 9 節；預期答案寫進 `tmp/transfer-acceptance.json`，不得出現在指南或任何 tracked 檔。
   該檔必須已被 gitignore（`git check-ignore -q`）且未 tracked；不符就列缺項，Transfer 不改 `.gitignore`。格式：

   ```json
   {"schema": 1, "questions": [
     {"id": "Q1", "kind": "command", "stdout_contains": "passed"},
     {"id": "Q2", "kind": "answer", "contains": ["02:00"], "paths": ["deploy/crontab"], "ids": ["D-YYYYMMDD-slug"]}
   ]}
   ```

   `command` 題必須有 `stdout_contains`，答案是一行指令，判分時在拋棄式 fresh clone 執行，exit 0 且輸出含
   `stdout_contains` 才過；`answer` 題的答案須含全部 `contains` 與 `ids`，`paths` 須出現在答案中且在 clone 內存在。預期答案只寫能
   從 repo 內容查到的事實；只有移交人知道的事要先寫進 repo，不能只放在判分檔。判分檔的每一項檢查都要在題目裡講明
   （例如要檢查 `paths`，題目就要求引用檔案路徑），不得比題目嚴。

### 產物與移交未完成條件

1. 從 `<project-templates>/transfer-guide-template.md` 建立或更新 `<repo>/docs/transfer.md`，記接手者、
   portable-knowledge audit 結果、credentials separation、進行中工作的指標、接手驗收題組與缺項清單。
2. 下列任一成立時，移交未完成，指南維持草稿並逐項列出缺項：
   - 未指名接手者（取自 invocation 的 `to=<recipient>` 或使用者同輪明說；這個 token 不交給 repo resolver）；
   - credential plan 未完成：沒有安全交付管道，或選了 repo-local artifact 而 `verify-transfer-credential.sh` 非 PASS；
   - adopted repo 的 `audit --ship` 未通過，或程式碼與 tracked 檔仍有硬編碼 secret；
   - fresh clone 無法只靠 repo 內的指引 setup、跑 QA、定位 active state 與歷史；
   - 仍有只存在對話或私人記憶的專案事實；
   - 在途工作未合併也未明確放棄；
   - 接手驗收題組未建立，或判分檔未被 gitignore、已被 tracked。

   缺項解除前不得在指南或歷史紀錄宣稱移交完成。
3. 指南與 audit 補寫的紀錄由之後明確叫用的 `$project log`／`/project log` 送出，Log／shipping 的既有授權
   gate 完整適用。Repo 權限調整由人完成，本 workflow 不代做。

### 接手驗收（指南送出之後）

1. 接手者（或沒有移交人記憶的 fresh-context agent）在 fresh clone 中只靠 repo 與第 9 節題目作答，答案存成
   `{"<id>": "<答案>"}` JSON。
2. 移交人在自己的 repo 根目錄執行
   `python3 <project-scripts>/grade-handover.py --spec tmp/transfer-acceptance.json --answers <答案檔> --clone <拋棄式 clone>`。
   有 `command` 題時第一次會列出接手者的指令並以 exit 3 停下、不執行；移交人確認每一條都只是唯讀本地驗證後，
   才加 `--allow-exec` 重跑，有對外動作或不明指令的那題直接判失敗、不執行。執行時只給最小環境（不帶呼叫者的
   環境變數與 credential、HOME 為暫存目錄、沒有 stdin）並有 timeout。exit 0 且 `verdict: PASS` 才算通過，exit 1
   列出失敗題，exit 2 是判分檔或答案檔格式錯誤。失敗題代表 repo 少了
   接手者需要的資訊：先補 repo 內容，再請接手者重答，不改題目或預期答案來遷就。
3. 指南已合併、移交未完成條件全部解除、驗收通過、權限調整由人完成，才可由 Log 寫移交完成的 milestone。
