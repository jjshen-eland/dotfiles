# 以內容契約取代 steward 身分授權，並以移交給同事為重點（#309）

- 日期：2026-10-12
- 工作項：issue-309-content-continuity
- 狀態：draft
- 種類：implementation plan
- 需求來源：[GitHub #309](https://github.com/jjshen-eland/dotfiles/issues/309)。使用者 2026-10-12 指出機制的實際目標是「同時使用 Codex 與
  Claude 時如何接續」，並在評估後選定 D-20261012-content-continuity-model、D-20261012-handover-to-colleague-focus、
  D-20261012-kernel-shared-work-rewrite。
- 基線：origin/main `ae5de29`

## 目標

1. 任何 runtime、任何 session、任何主機都能只靠 repo 接續進行中的工作，不需要 actor 身分、改派或 Transfer 狀態機。
2. 移交給新同事後，repo 本身足以讓接手者掌握全貌：系統組成、怎麼建環境與驗證、怎麼部署與維運、進行中的工作、
   為什麼這樣設計與哪些路走不通、外部帳號與排程、已知風險；並且有可機械判定的接手驗收。

## 評估摘要（2026-10-12，唯讀、啟發式）

分析腳本與逐筆輸出在評估 session 的 scratchpad，不入庫；暫存遺失時以下列方法重算，不補造。

- 授權詢問：2026-08-25 起真實 repo 的 Codex／Claude 主 session 中，`steward-authority.py` 實際執行 2,314 次、STOP
  260 件（同 session 兩則人類訊息之間連續 STOP 算一件），179 件向使用者提問：直接同意 92%、照指示重下或選建議項
  再 5%、選停止 0 件；126 件是同 runtime 下從 branch 推出的 actor 名稱與 steward 名稱不同，112 件是同一 session 對
  同一 steward 重複提問，只有 14 件落在新 session 前 3 則人類訊息內，跨 runtime 1 件；37 件是 commit 帶共享紀錄但
  parent 沒有 active contract，同意後需重建尚未 push 的 commit，共 60 次。量不到任何一件擋下不該寫的寫入；有一次
  兩個 session 以同一 workline 名稱同時工作，helper 全部 PASS（只認名稱、不認 session）。
- 成本：agent 約 11–12 小時；使用者回覆延遲總和約 16 小時（單件上限 30 分），不設上限約 40 小時。
- 實際形態（11 個啟用 contract 的受治理 repo，2026-08-20 起 origin/main 的 STATUS 歷史）：177 個工作項中跨 runtime
  接續 5 項；同版同時有 codex 與 claude Writer 33 版；steward 代號 82 個、換手 74 次，多為工作線輪替；Workspace
  指向的 branch 299 個中 289 個已不存在；正式移交 1 次（agent 對 agent，移交指南存在約 8 小時）；STATUS 從未出現
  `human:`。dotfiles 另有跨 runtime 換手 6 次、正式移交 1 次（約 5.6 小時、使用者輸入 9 次）。
- 接手時讀的來源（43 份接手 session）：STATUS 39、git status/diff 38、handoff 檔 36、`find` 35、plans 28、archive 27；
  抽樣 15 份中 7 份遇到 STATUS 把已完成項目列為進行中、Workspace 指向已刪除的 branch、handoff 筆數錯誤或重問已定案
  的設計。
- 讀取成本：Log 有變更時必讀的 authority、dossier、log-prepare 中 steward 相關約 28 KB，佔三份的 41.6%。
- 唯一的真人協作者曾在一個 repo 開 PR，未接觸 STATUS 或 archive。

## 範圍

**移除（身分授權層）**：`shared/skills/project/scripts/steward-authority.py`、`references/authority.md`；`dossier.md`
「平行協作與 stewardship」；`log-prepare.md` Step 2 第 1 點的 binding／ordinary gate／worker／candidate provenance、
completion-parent 重驗、Runtime steward retirement gate、Prompt-bound authority recovery、Step 4／5 的 stewardship
欄位；`spec-workflow.md` 的四欄與 session assignment／binding packet；`SKILL.md`、`log-workflow.md` 的 `resume=`／
`as=`／`to=` token；STATUS 範本的 Writer／Workspace／Write Scope／Dossier Steward；對應測試（`tests/project-sequential-
assignment.py`、`tests/project-session-binding.py`、`tests/modules/project.sh` 的相關比對與 helper 段）與 eval
（`pressure-tests.md` 相關 Scenario、`claude/evals/contract-evals.md` G11 與 `make_g11`）。

**保留**：kernel 安全底線、branch-first、ship-state、merge／ship 流程、`audit --ship`、record schema、STATUS 的目標／
驗收／進度／下一步、handoff skill、`verify-transfer-credential.sh`。受信任 scanner 不改；各 repo 以 config 關閉
`active_item_contract`。

**改寫（移交）**：`transfer-workflow.md`、`templates/transfer-guide-template.md`、`docs/project-spec.md` F8。

**改寫（kernel）**：`AGENTS.md`、`claude/CLAUDE.md`、`codex/AGENTS.md` 的「Shared work and durable project state」段
（三份手動逐字維護）、`tests/kernel-gate.py` 的 REQUIRED／CANARIES 與 `tests/modules/document-contract.sh` 對應
fixture；`AGENTS.md` 中「上面三個 managed block 由工具維護」的不實說明一併更正。逐字內容須使用者核定。

## 階段

每階段各開 branch、各自驗收、可單獨回退。

### P1：各受治理 repo 關閉 active_item_contract

對啟用 contract 的受治理 repo（kapi-infra、kapi-protocol、krepo-common、krepo-company、krepo-judicial、
krepo-mops-disclosure、krepo-mops-financial-statements、krepo-mops-major-news、krepo-tej-export、krepo；
已封存的 kapi-kb-hub-legacy 不處理），各刪除 `.doc-governance.json` 的 `status_schema.active_item_contract`，
依該 repo 的 contract 開 branch、commit、跑其測試與 `audit --ship`。每個 repo 的 push／PR／merge 須另經使用者
具名批次授權；各 repo 的 STATUS 欄位暫不清除。驗收：每個 repo 的 `steward-authority.py` 回 `NOT_APPLICABLE`、
`audit --ship` OK、該 repo 測試通過。回退：還原該行。

### P2：移除身分授權層（含移交的 actor 狀態機與 kernel 改寫）

P2 與原 P4 合為一批：skill 一移除 steward，kernel 的 Dossier Steward 條文即與之矛盾，不留空窗。移交的 actor
狀態機也在本批移除，否則移交流程會引用已刪除的 authority；移交內容的強化留給 P3。

**刪除**

- `shared/skills/project/scripts/steward-authority.py`、`claude/skills/project/scripts/steward-authority.py`（逐檔連結；
  Codex 端整目錄連結隨之消失）、`shared/skills/project/references/authority.md`。
- 測試：`tests/project-sequential-assignment.py`、`tests/project-session-binding.py`；`tests/modules/project.sh` 中
  比對 steward／binding／recovery／transfer 狀態機字樣的檢查與 helper fixture 段、共用腳本清單的
  `steward-authority.py`；`tests/suites.json` 對應 route；`tests/modules/document-contract.sh` 比對 `ACTOR_RE` 兩份
  複本的漂移檢查（scanner 的 `ACTOR_RE` 保留，仍服務啟用 contract 的 repo）。
- eval：`claude/evals/contract-evals.md` G11 改為退役說明，`claude/evals/setup-sandboxes.sh` 的 `make_g11` 與其分派
  移除；`shared/skills/project/references/pressure-tests.md` 的 #229 批次段與 S23、S24、S26、S27、S28、S33、S34、
  S36、Transfer forward 在各自標題下加一行退役說明並指向 D-20261012-content-continuity-model，原文保留為歷史。

**改寫**

- `dossier.md`：「平行協作與 stewardship」改為「接續（內容契約）」：進行中工作項的必要內容是 Context、Goal、
  Acceptance Criteria、Constraints、進度、下一步；停手（Log 收尾或中途換手）時進度與下一步正確，未合併的工作已
  commit 並 push，下一步寫明所在 branch；平行作業各用 branch／worktree，共享檔案的衝突在 rebase／merge 時解決，
  不丟棄其他 branch 的紀錄。
- `log-prepare.md`：Step 2 第 1 點改為「讀 active items，依內容契約更新進度／下一步」；第 2 點刪除 worker delta 與
  cherry-pick 整合；第 3 點保留 milestone 與移除已完成項目的規則，刪除 completion-parent helper 重驗；刪除 Runtime
  steward retirement gate 與 Prompt-bound authority recovery 兩節；Step 4 摘要範本與說明刪除 stewardship 欄位；
  Step 5 進入條件刪除 stewardship。
- `spec-workflow.md`：刪除四欄與 session assignment／binding packet，Spec 只寫內容契約的欄位。
- `workflow.md`：路由表移除 `authority.md`；Transfer 列不再提 conditional owner。
- `log-workflow.md`、`claude/skills/project/SKILL.md` argument-hint：移除 `resume=`、`as=`；`to=` 保留為移交的接手者名稱。
- `transfer-workflow.md` 與 `templates/transfer-guide-template.md`：刪除 BLOCKED／PREPARED／TRANSFERRED、current／
  next steward、conditional owner record、active-item mapping、remote ancestry；保留 portable-knowledge audit、
  credential 分離與 `verify-transfer-credential.sh`、authorization 不隨移交；移交產物是指南草稿與待補清單，不 commit。
- `templates/STATUS-template.md`：刪除 Writer／Workspace／Write Scope／Dossier Steward。dotfiles 自己的 STATUS
  各工作項一併刪除這四欄（contract 已關閉，無機械依賴）。
- `shared/skills/deep-review/references/workflow.md` autofix 的「Establish writer/steward authority」改為「確認工作樹
  沒有歸屬不明的變更、目標 repo 的寫入規則允許」；`shared/skills/ready4quit/references/workflow.md` 的「合法 steward」
  改為「repo 有既定 sink」。
- `docs/project-spec.md` F8、`docs/document-governance.md` 中 contract 的說明改為「選用、dotfiles 與受治理 repo
  皆已關閉」；`docs/testing-contract.md` 對應段落同步。
- kernel 三份（`AGENTS.md`、`claude/CLAUDE.md`、`codex/AGENTS.md`）「Shared work and durable project state」依下方
  草稿改寫，`tests/kernel-gate.py` REQUIRED 改為新句（One writer per work item.／separate branches or worktrees／
  Continuity lives in the repo／Do NOT create a dossier／Runtime-local memory is a non-authoritative cache），
  `tests/modules/document-contract.sh` 對應 fixture 同步；`AGENTS.md` 中「上面三個 managed block 由工具維護」改為
  「三份手動逐字維護，由 `tests/kernel-gate.py` 驗漂移」。其他受治理 repo 的 kernel 複本與其
  `tests/test_agent_contract.py` 不在本批，另列後續 rollout。

**kernel 草稿（待使用者核定逐字內容）**

```markdown
### Shared work and durable project state

- **Do NOT create a dossier or decision store that the repo has not adopted.** When an existing active-state store is present, record the success criteria for non-trivial work before implementation; when both a governance config and its scanner exist, use that adopted lifecycle, when neither exists follow the repo's legacy store, and when only one exists STOP as broken adoption.
- **One writer per work item.** Parallel sessions, in the same runtime or not, work on separate branches or worktrees; changes you did not make fall under the safety floor above.
- **Continuity lives in the repo, not in an actor identity.** Whenever you stop or hand off a work item, leave its active-state entry with an accurate goal, acceptance criteria, progress and next step, and commit and push unmerged work to the branch named in that next step. Any runtime, session or host then continues from the repo without reassignment.
- Record durable decisions, dead ends, and milestones at event time, not reconstructed at shipping time. Active state and history are ordinary files: resolve conflicts between parallel branches while rebasing or merging, never by discarding another branch's records.
- Remove completed items from active state, write milestones to the repo's existing history store, and pass its documentation audit before declaring the work complete.
- **Handover to another person** must leave a repo the recipient can understand without the previous owner: follow the repo's transfer guide, keep credentials out of git, and never hand over action authorization.
- **Runtime-local memory is a non-authoritative cache, never a prerequisite.** Safety/Git rules, cross-runtime agreements, project facts/state, cross-host continuity, and action authorization must not exist only there. Route shared behavior to native instructions and project facts/state to the repo's adopted authority; whether any runtime memory is on, off, unavailable, or differently configured must not change correctness, safety, or handover readiness. Authorization never survives a session or a handover.
```

**驗收**

- `rg -n 'steward-authority|Dossier Steward|Write Scope|resume=|as=<|binding packet|conditional owner|PREPARED|TRANSFERRED'`
  （排除 `docs/archive/`、`docs/plans/`）只剩逐筆列明的歷史段、退役說明，以及 scanner 中服務選用 contract 的程式碼。
- `tests/kernel-gate.py` 以舊 kernel 跑新 REQUIRED 先紅、改寫後綠；全套測試與 `audit --ship` 通過；必讀 reference
  改前改後 bytes 列入報告。
- 行為：`tests/project-reference-eval.py` 的 `committed`、`spec`、`transfer`、`tested` case，在 Claude Code 樓層模型
  與 Codex production model 各跑一次：不呼叫 steward 授權、不出授權確認題、到達原本的終點（`transfer` 為產出
  不含 secret 的指南草稿、不 commit）。另以一個 STATUS 工作項 Writer 寫著 `codex:<workline>` 的 fixture 讓 Claude
  執行 Log：不因 Writer 不同而停下，依下一步完成收尾。記錄 alias、resolved model、effort、CLI 版本。
- 審查：會改變放行／攔下行為與 permission 邊界，實作前跑一批 deep-plan；kernel 逐字內容在 deep-plan 後請使用者核定。

### P3：移交給同事（重點）

P2 移除 actor 狀態機後，移交改為「讓接手的人掌握全貌」：

1. 移交指南（`docs/transfer.md`）涵蓋：系統組成與外部依賴；環境建置與驗證指令；部署、排程與維運（哪些主機、
   cron、服務在跑，掛了先看哪）；外部帳號、權限與 credential 清單（只記名稱與存放位置，值不進 git）；進行中的
   工作（指向 STATUS）；決策與死路的入口（`find` 查詢範例與關鍵 D／X ID）；已知風險與技術債；移交人的支援期限
   與聯絡方式；待雙方決定的事項。
2. **接手驗收題組**：移交人在指南中列出接手者必須能獨立完成的任務與問題，每題附可機械判定的預期結果（指令
   exit 0、輸出包含指定內容、答案引用的路徑存在或 D／X ID 正確）。驗收方式是在只有 fresh clone、沒有移交人
   記憶的環境中由接手者（或 fresh-context agent）作答，以腳本判分；人工主觀判讀不當作驗收。
3. 移交完成以「指南合併、接手驗收題組通過、權限調整由人完成」記錄。

驗收：以一個 fixture repo 實跑一次移交，接手驗收題組由 fresh-context agent 作答並以腳本判分全數通過。

### P5：縮減必讀 reference 與端到端量測

P2 刪除後，依 #285 計畫第 5、6 步量測必讀 reference 的讀取量與一筆真實交付的耗時。

## 不做

- 不新增接續相關的機檢或 gate；STATUS 內容正確靠 Log 既有的同步步驟。
- 不改受信任 scanner；不清除其他 repo 的歷史紀錄。
- 不處理已封存的 kapi-kb-hub-legacy 與已移交的 ais-platform。

## 寫入範圍

`shared/skills/project/`、`claude/skills/project/`、`codex/skills/project/`、`tests/`、`claude/evals/`、
`docs/testing-contract.md`、`docs/project-spec.md`、`docs/document-governance.md`、`AGENTS.md`、`claude/CLAUDE.md`、
`codex/AGENTS.md`（kernel 段需使用者核定）、本計畫、STATUS.md、`docs/archive/`；P1 另含各受治理 repo 的
`.doc-governance.json`。
