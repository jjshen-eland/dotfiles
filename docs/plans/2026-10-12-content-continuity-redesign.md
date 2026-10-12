# 以內容契約取代 steward 身分授權；transfer 模式改以移交給同事為重點（#309）

- 日期：2026-10-12
- 工作項：issue-309-content-continuity
- 狀態：in-progress
- 種類：implementation plan
- 需求來源：[GitHub #309](https://github.com/jjshen-eland/dotfiles/issues/309)。使用者 2026-10-12 指出機制的實際目標是「同時使用 Codex 與
  Claude 時如何接續」，並在評估後選定 D-20261012-content-continuity-model、D-20261012-handover-to-colleague-focus、
  D-20261012-kernel-shared-work-rewrite。
- 基線：計畫起草於 origin/main `ae5de29`；P1 完成後為 `58cde42`

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
  `human:`，但 legacy 的 human steward 寫法 `owner:jjshen`（使用者本人）出現在 8 個 repo。dotfiles 的 Writer runtime
  前綴變化 3 次，以工作項計為 6 次（新舊工作項之間 3 次、同一次正式移交中 3 項）；正式移交 1 次（約 5.6 小時、
  使用者輸入 9 次）。
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

### P1：各受治理 repo 關閉 active_item_contract（已完成 9／10）

2026-10-12 在 kapi-infra #179、kapi-protocol #36、krepo-common #85、krepo-company #61、krepo-judicial #139、
krepo-mops-disclosure #115（ruleset 要求核准，依使用者指示 bypass merge）、krepo-mops-major-news #98、krepo-tej-export #11、
krepo #192 刪除 `status_schema.active_item_contract`，各 repo `audit --ship` OK、authority 回 `NOT_APPLICABLE`、
`unit-tests` 通過；STATUS 欄位保留。krepo-mops-financial-statements 的工作樹有他人未 commit 的工作，待淨空後處理。
已封存的 kapi-kb-hub-legacy 不處理。關閉 contract 時一併關掉了 scanner 的兩項內容檢查，由 P2／P2b 以 `Goal`
contract 恢復。

### P2：移除身分授權層（含移交的 actor 狀態機與 kernel 改寫）

P2 與原 P4 合為一批：skill 一移除 steward，kernel 的 Dossier Steward 條文即與之矛盾。移交的 actor 狀態機也在本批
移除，否則移交流程會引用已刪除的 authority；移交內容的強化留給 P3。其他受治理 repo 的 kernel 複本與 STATUS 欄位
由 P2b 緊接處理；在 P2b 完成前，那些 repo 的舊 kernel 仍要求遇他人 Writer 時 STOP，屬已知過渡期。

**刪除**

- `shared/skills/project/scripts/steward-authority.py`、`claude/skills/project/scripts/steward-authority.py`（逐檔連結；
  Codex 端整目錄連結隨之消失）、`shared/skills/project/references/authority.md`。
- 測試：`tests/project-sequential-assignment.py`、`tests/project-session-binding.py`；`tests/modules/project.sh` 中
  比對 steward／binding／recovery／transfer 狀態機字樣的檢查與 helper fixture 段、共用腳本清單的
  `steward-authority.py`；`tests/suites.json` 對應 route；`tests/modules/document-contract.sh` 比對 `ACTOR_RE` 兩份
  複本的漂移檢查。scanner 的 `ACTOR_RE` 與其註解（宣稱是 steward-authority 的複本、由測試驗漂移）保留不改：
  scanner 逐 byte 複製到各 repo，改動需全機隊同步；這段註解在 P2 後不再正確，照實接受。
- eval：`shared/skills/project/references/pressure-tests.md` 的 #229 批次段與 S23、S24、S26、S27、S28、S33、S34、
  S36、Transfer forward 在各自標題下加一行退役說明並指向 D-20261012-content-continuity-model，原文保留為歷史；
  S10、S39 中預期 transfer 產出 `BLOCKED` 的判準改為新的移交未完成條件。`claude/evals/contract-evals.md` G11 只退役
  steward 與平行 worker 的子情境，保留 G11-C（未採用 dossier 不得新建）與 G11-D（半採用 STOP），這是 kernel 第一條
  僅有的行為 eval；`make_g11` 保留其 legacy 與 half-adopted repo，`claude/evals/README.md` g11 列同步。

**改寫**

- `dossier.md`：「平行協作與 stewardship」改為「接續（內容契約）」，內容與 kernel 一致：進行中工作項至少有 Goal、
  進度、下一步（另可有 Context、Acceptance Criteria、Constraints）；把工作留給其他 session 接續時，進度與下一步
  正確、自己的未合併工作 commit 在下一步寫明的 branch，不 commit 的流程改為回報未 commit 的內容；push 依安全底線；
  接手者先以 branch 與 commit 核對工作項，branch 不存在或已合併即視為過時；平行作業各用自己的 branch 與 worktree
  或 clone；衝突時保留每個工作項最新的內容與各 branch 的紀錄，不確定就停下問。
- `log-prepare.md`：Step 2 第 1 點改為「讀 active items，依內容契約更新進度／下一步」；第 2 點刪除 worker delta 與
  cherry-pick 整合；第 3 點保留 milestone 與移除已完成項目的規則，刪除 completion-parent helper 重驗；刪除 Runtime
  steward retirement gate 與 Prompt-bound authority recovery 兩節；Step 4 摘要範本與說明刪除 stewardship 欄位；
  Step 5 進入條件刪除 stewardship。
- `spec-workflow.md`：刪除四欄與 session assignment／binding packet，Spec 只寫內容契約的欄位。
- `workflow.md`：路由表移除 `authority.md`；Transfer 列不再提 conditional owner。
- `log-workflow.md`、兩份 `SKILL.md`：移除 `resume=`、`as=` token 與「runtime actor prefix 固定」的說明；`to=` 保留為
  移交的接手者名稱。
- `transfer-workflow.md` 與 `templates/transfer-guide-template.md`：刪除 BLOCKED／PREPARED／TRANSFERRED、current／
  next steward、conditional owner record、active-item mapping、remote ancestry；保留 portable-knowledge audit、
  credential 分離與 `verify-transfer-credential.sh`、authorization 不隨移交。移交未完成條件（任一成立即維持草稿、
  列出缺項）：未指名接手者（取自 `to=` 或使用者同輪明說）；credential plan 未完成（無安全交付管道，或選了 local
  artifact 而 `verify-transfer-credential.sh` 非 PASS）；adopted repo 的 `audit --ship` 未通過或仍有硬編碼 secret；
  fresh clone 無法 setup／跑 QA；仍有只存在對話或私人記憶的專案事實；在途工作未合併或未明確放棄（本次 Transfer
  自己的產出不算）。deep-review 指出初版只列四項，漏掉舊 BLOCKED 涵蓋的 authority、secret 與 self-contained 缺項，
  且 helper 條件與密碼管理器路徑矛盾，已補。Transfer 模式本身不 commit；指南與補寫的紀錄由之後的 Log 送出。
- `templates/STATUS-template.md`：刪除 Writer／Workspace／Write Scope／Dossier Steward。dotfiles 自己的 STATUS
  各工作項一併刪除這四欄。
- dotfiles `.doc-governance.json` 以 `{"required_fields": ["Goal"], "uniform_fields": []}` 重新啟用
  `active_item_contract`：恢復 scanner 既有的「進行中項目標題帶 ✅／已完成」與「進行中區段有 H3 以外內容」兩項檢查
  （關閉 contract 時一併關掉）。只設 `Goal` 是因各 repo 的進度與下一步欄位名稱不一（進度、Progress、Next、帶日期
  的變體），`Goal` 是各 repo 共有的單行欄位；這兩項檢查只抓得到標題有標記的項目，抓不到未標記但已完成的項目。
  `steward-authority.py` 在同一批刪除，所以重新啟用不會觸發舊的 actor 檢查。
- `shared/skills/deep-review/references/workflow.md` autofix 的「Establish writer/steward authority」改為「確認工作樹
  沒有歸屬不明的變更、目標 repo 的寫入規則允許」；`shared/skills/ready4quit/references/workflow.md` 的「合法 steward」
  改為「repo 有既定 sink」，`shared/skills/ready4quit/evals.md` 的 Q1、Q8、Q9(c) 與 `tests/session-skills-model-eval.py`
  的 q-owner case 改用新判準；`shared/skills/handoff/references/workflow.md` 中 ownership 與「代替 writer reassignment」
  的說法改為內容契約。
- `tests/project-reference-metrics.py` 的 required references 移除 `authority.md`。
- `docs/project-spec.md` F8、`docs/document-governance.md` 的 contract 說明（選用；dotfiles 以 Goal 啟用，其餘依各 repo
  設定）、`docs/testing-contract.md` 對應段落同步。
- kernel 三份（`AGENTS.md`、`claude/CLAUDE.md`、`codex/AGENTS.md`）「Shared work and durable project state」依下方使用者
  核定的逐字內容改寫。`tests/kernel-gate.py` REQUIRED 移除 "separate branch/worktree"、"Dossier Steward"、"Dossier delta"、
  "`git cherry-pick`"，新增 "own worktree or clone"、"Continuity lives in the repo"、"never promote themselves into writers"，
  保留 container-network 與其他既有條目；CANARIES 加上 "Continuity lives in the repo"。`tests/modules/document-contract.sh`
  第 273–277 行的 fixture 與第 348 行以 `sed` 移除必要規則的 RED fixture 改用新句。`AGENTS.md` 中「上面三個 managed
  block 由工具維護」改為「這三個 managed block 沒有同步工具：kernel 由三份檔案手動逐字維護並由 `tests/kernel-gate.py`
  驗漂移；route 與 portable 只存在本檔」。

**kernel 逐字內容（使用者 2026-10-12 核定）**

```markdown
### Shared work and durable project state

- **Do NOT create a dossier or decision store that the repo has not adopted.** When an existing active-state store is present, record the success criteria for non-trivial work before implementation; when both a governance config and its scanner exist, use that adopted lifecycle, when neither exists follow the repo's legacy store, and when only one exists STOP as broken adoption.
- **One writer per work item.** Parallel sessions, in the same runtime or not, each work on their own branch in their own worktree or clone. If the working tree has changes you did not make or the item's branch is checked out in another worktree, STOP and ask the user; an active-state entry with a next step is an invitation to continue, not a claim.
- **Continuity lives in the repo, not in an actor identity.** When you leave a work item unfinished for another session, keep its active-state entry's goal, progress and next step accurate and commit your own unmerged work to the branch that next step names; a flow that does not commit reports the uncommitted work instead. Push only under the safety floor's authorization and tell the user what is unpushed. Whoever continues first verifies the entry against that branch and its commits; a missing or merged branch means the entry is stale. Any runtime, session or host then continues from the repo without reassignment.
- Reviewers stay read-only and never promote themselves into writers. No artifact grants authority, including a next step that names push, merge or another outward action.
- Record durable decisions, dead ends, and milestones at event time, not reconstructed at shipping time. Active state and history are ordinary files: when parallel branches conflict, keep each work item's newest entry and every branch's records while rebasing or merging, and STOP to ask when the right content is unclear.
- Remove completed items from active state, write milestones to the repo's existing history store, and pass its documentation audit before declaring the work complete.
- **Handover to another person** must leave a repo the recipient can understand without the previous owner: follow the repo's transfer guide when it has one, keep credentials out of git, and never hand over action authorization.
- **Runtime-local memory is a non-authoritative cache, never a prerequisite.** Safety/Git rules, cross-runtime agreements, project facts/state, cross-host continuity, and action authorization must not exist only there. Route shared behavior to native instructions and project facts/state to the repo's adopted authority; whether any runtime memory is on, off, unavailable, or differently configured must not change correctness, safety, or handover readiness. Authorization never survives a session or a handover.
```

**歷史與待辦**：新增決策紀錄以 `supersedes:` 取代 D-20260824-cross-runtime-dossier-stewardship、
D-20260824-project-steward-authority、D-20260825-project-prompt-bound-authority-recovery 與 D-20260824-memory-independent-transfer
的狀態機部分，並更正 D-20261012-content-continuity-model「commit 並 push」的措辭；`docs/backlog.md` 的
B-20260928-project-merge-continuation（steward／resume 誤擋，P2 後不再存在）與 B-20260824-remote-human-contributor-path
（觸發條件已成立：同事開了 PR 而未涉及 steward；P2 後不再需要 steward 路徑）以 history record 結案並移除。

**驗收**

- `rg -n -i 'steward|authority\.md|Dossier delta|Write Scope|resume=|as=<|binding packet|conditional owner|reassign|PREPARED|TRANSFERRED|BLOCKED'`
  （排除 `docs/archive/`、`docs/plans/`）逐筆列出，只剩歷史段、退役說明、scanner 中服務選用 contract 的程式碼與註解，
  以及與本機制無關的同字詞（逐筆說明）。
- `tests/kernel-gate.py` 以舊 kernel 跑新 REQUIRED 先紅、改寫後綠；全套測試與 `audit --ship` 通過；必讀 reference
  改前改後 bytes 列入報告。
- 行為（記錄 alias、resolved model、effort、CLI 版本）：
  - 有鑑別力的 fixture：fixture repo 含 `.doc-governance.json`（啟用舊四欄 contract）、受信任 scanner、帶舊 kernel 的
    `AGENTS.md`，以及 Writer／Dossier Steward 為 `codex:<workline>` 的進行中工作項；Claude 樓層模型執行 Log。改前
    （origin/main source）預期因 actor 不符停下並詢問；改後（本 branch source、fixture 的 `AGENTS.md` 換新 kernel、
    config 換為 Goal contract）預期不停下、依下一步完成到送出確認。改後另以 Codex production model 跑一次。
  - 回歸護欄：`committed`、`spec`、`transfer`、`tested` 在 Claude 樓層模型與 Codex production model 各跑一次，不出
    授權確認題、到達原本的終點；`transfer` 產出不含 secret 的指南草稿、不 commit，缺項依移交未完成條件列出。
  - ready4quit 不 commit：既有 ready4quit eval 中含未 commit 變更的情境在兩模型各跑一次，新 kernel 下不 commit。
- 審查：deep-plan 一批第一輪的 findings 已修進本節，未跑第二輪；實作後以 deep-review 審實際 diff。

**實作結果（2026-10-12，branch `refactor/remove-steward-identity`，未 push）**

- 驗收 grep 剩餘命中：pressure-tests 與 contract-evals G11 的退役段、scanner 中服務選用 contract 的程式碼與註解（其中
  「tests/run.sh 驗 ACTOR_RE 漂移」的註解已過時，scanner 不改，留待下次 scanner 版本）、`test_doc_governance.py`
  對 scanner 舊欄位驗證的測試、backlog B-20260924-workflow-review-residuals 的歷史證據，以及與本機制無關的同字詞
  （GitHub `BLOCKED` 合併狀態、審查 verdict、runtime-layout 的 `prepared` receipt、`--resume` 參數等）。
- `kernel-gate.py` 舊 kernel 紅、新 kernel 綠；`./tests/run.sh --base origin/main` 29／29 模組通過；`audit --ship` OK。
  dotfiles 的 Goal contract 以突變確認有效（標題加 ✅ 與缺 Goal 各出一筆 finding）。
- Log 路徑必讀 reference（workflow、log-workflow、ship-policy、authority、dossier、log-prepare、ship-paths）由
  91,284 B 降為 64,896 B（−26,388 B）；spec 路徑 30,518 → 14,607 B，transfer 路徑 32,141 → 15,970 B。
- 行為（Claude Code 2.1.296、codex-cli 0.162.1；Sonnet＝claude-sonnet-5-5、Codex＝gpt-6.1-sol，effort high）：
  - 鑑別 fixture：舊 source＋舊 kernel 的 Sonnet 在 authority gate 停下，要求由 Codex 收尾或先做 steward transfer；
    新 source＋新 kernel 的 Sonnet 不問身分，走到送出選項。新 source 的 Codex 也不問身分並完成收尾準備，但 Codex
    sandbox 把 `.git` 設為唯讀、commit 被拒，未到送出選項（harness 限制，終點記為未到達）。
  - 回歸：`committed`、`spec`、`transfer` 兩模型都不出授權確認題、到達原終點；transfer 不含 secret、不 commit，
    缺項列出未指名接手者、credential 交付、在途 commit。`tested` 的 Codex 在最終 HEAD 實跑一次；Sonnet 首次沿用
    先前結果、未實跑（RED），同 fixture 加跑舊 source 2 次、新 source 2 次皆實跑，判為模型變異，新 source 合計 2／3。
  - ready4quit：`q-residue`、`q-owner` 兩模型 HEAD 都不變、不 commit；`q-owner` 依新判準把 dead-end 列為未落點殘留。
- deep-review（full，4 位 fresh reviewer，58cde42..c44ed80）：FAIL，2 條 medium、10 條 low，均查證屬實。medium 為
  transfer 未完成條件漏列舊 BLOCKED 涵蓋的缺項且 helper 條件與密碼管理器路徑矛盾，以及 q-flush fixture 未寫寫入授權；
  low 含漏寫 supersedes、STATUS 過時描述、`to=` 未在 transfer 說明、路由表殘留 Spec subflow、Transfer 自身產出被算成
  在途工作、退役標記不完整。已依使用者指示全部修正（scanner 註解除外，留待 P2b）；修正由作者驗證，未再派 reviewer。
  修正後全套測試通過；transfer 兩模型重跑都列出新增缺項（安全交付管道、setup／QA 指引），不含 secret、不 commit；
  q-flush 兩模型追加 dead-end、不 commit，q-owner 兩模型不寫入。
- 觀察（留給 P3）：Sonnet 判定「在途工作」不穩定。transfer fixture 的 feature branch 有一顆未合併 commit，修正前
  source 3 次中 2 次抓到、修正後 3 次中 1 次明確抓到（另 1 次誤判沒有、1 次標未核對），前後差異在變異範圍內，
  不歸因於修正；第 6 步沒有指明以 default branch 比對未合併 commit，P3 強化移交內容時一併處理。

### 待補 repo（觸發時做 P1／P2b）

- krepo-mops-financial-statements：已採用文件治理、仍是舊 kernel 與四欄 contract。觸發條件：使用者告知其開發完成、
  工作樹淨空。屆時一次做完 P1 與 P2b（kernel 換 dotfiles 現版、Goal contract、STATUS 刪四欄、scanner 與受信任版本
  一致）。
- kapi-nc-v2：2026-10-12 尚未採用文件治理（無 `.doc-governance.json`、scanner 與 kernel 區塊），準備在通過驗證後
  取代現行 NC 成為生產 repo。觸發條件：該 repo 上線並採用文件治理時，直接套 dotfiles 現版 kernel 與只要求 `Goal` 的
  contract，沒有舊 contract 需要關閉。

### P2b：其他受治理 repo 同步（P2 合併後緊接）

對 P1 的 9 個 repo（krepo-mops-financial-statements 待其工作樹淨空）：kernel 複本換為新內容、`tests/test_agent_contract.py`
（krepo-common、krepo）改驗新句、`.doc-governance.json` 以 `{"required_fields": ["Goal"], "uniform_fields": []}` 重新啟用
contract（先確認該 repo 進行中工作項都有 Goal，否則先補）、STATUS 刪除四欄。每個 repo 的 push／PR／merge 另經使用者
具名批次授權。驗收：各 repo `audit --ship` OK、該 repo 測試通過、kernel 與 dotfiles 逐字相同。

**實作結果（2026-10-12，各 repo branch `chore/content-continuity-kernel`，未 push）**

- 各 repo 的 kernel 停在 2026-09-25 前的版本（push 規則舊措辭、缺 Continue authorized work；krepo-company 另缺
  container-network 規則）。使用者選定整段換成 dotfiles 現版，9 個 repo 的 kernel 區塊與 dotfiles 逐字相同。
- `.doc-governance.json` 加上 Goal contract：單行檔以 JSON 往返重建，kapi-infra、krepo-common 為手排格式，只插入
  一行；兩者皆驗證解析結果只多了該欄位。STATUS 刪除四欄：kapi-infra 12 行、krepo-tej-export 4 行、krepo 8 行（含
  續行）；krepo-tej-export 與 krepo 的 Goal 原為段落粗體，改為清單欄位以符合 scanner 欄位格式。工作項其餘內容未
  核對是否過時。krepo-common、krepo 的 `tests/test_agent_contract.py` 改驗新句。
- krepo-tej-export、krepo 的 scanner 自 2026-09-07 起與受信任版本不同，`ship-state.sh` 會以 trusted core mismatch
  STOP；依其修法另起一顆 commit 同步。兩者原有的「STATUS stale」finding 在 main 上即存在，本批 commit STATUS 後解除。
- 測試：kapi-protocol 672、krepo-common 156、krepo-company 217、krepo-judicial 894、krepo-mops-disclosure 864、
  krepo-mops-major-news 837、krepo-tej-export 55、krepo 1067 passed；kapi-infra 的 CI 本地檢查以 Python 3.12 全過
  （本機 `python3` 3.9 缺 `tomllib`，屬環境）。9 個 repo 的 `audit --ship` OK，`ship-state.sh` 無 STOP。

### P3：transfer 模式的移交給同事（重點）

P2 移除 actor 狀態機後，移交改為「讓接手的人掌握全貌」：

1. 移交指南（`docs/transfer.md`）涵蓋：系統組成與外部依賴；環境建置與驗證指令；部署、排程與維運（哪些主機、
   cron、服務在跑，掛了先看哪）；外部帳號、權限與 credential 清單（只記名稱與存放位置，值不進 git）；進行中的
   工作（指向 STATUS）；決策與死路的入口（`find` 查詢範例與關鍵 D／X ID）；已知風險與技術債；移交人的支援期限
   與聯絡方式；待雙方決定的事項。
2. **接手驗收題組**：移交人列出接手者必須能獨立完成的任務與問題，每題附可機械判定的預期結果（指令 exit 0、
   輸出包含指定內容、答案引用的路徑存在或 D／X ID 正確）。題目可放在指南，**預期答案不放在接手者會讀的 repo 文件**
   （另存於移交人交付的判分檔），避免讀了指南即得答案。驗收方式是在只有 fresh clone、沒有移交人記憶的環境中由接手者
   （或 fresh-context agent）作答，以腳本判分；另以刻意缺少指南章節的負對照確認判分會失敗。人工主觀判讀不當作驗收。
3. 移交完成以「指南合併、移交未完成條件全部解除、接手驗收題組通過、權限調整由人完成」記錄。題組由移交人出題，偵測
   不到移交人自己遺漏的資訊；這部分由 D-20261012-handover-to-colleague-focus 的重議條件在實際移交後判斷。

驗收：以一個 fixture repo 實跑一次移交，接手驗收題組由 fresh-context agent 作答並以腳本判分全數通過，負對照失敗。

**P3 細節（2026-10-12）**

- `templates/transfer-guide-template.md` 依第 1 點重組章節；原「QA 驗收標準」併入接手驗收題組，原「合併與 owner 切換」
  併入移交步驟。題組章節只放題目與作答方式，不放預期答案。
- 判分檔 `tmp/transfer-acceptance.json`（移交人產出，必須被 gitignore 且未 tracked；不 ignore 就列缺項，Transfer 不改
  `.gitignore`）。格式：`{"schema":1,"questions":[...]}`，每題 `id` 與 `kind`：
  - `command`：接手者的答案是一行指令，判分在接手者的 fresh clone 執行，exit 0 且（若有）輸出含 `stdout_contains` 才過；
  - `answer`：答案文字須含全部 `contains` 字串與 `ids`，`paths` 須出現在答案中且在 clone 內存在。
  接手者的答案檔是 `{"<id>": "<答案>"}`。
- 新增 `scripts/grade-handover.py --spec --answers --clone`：逐題 PASS／FAIL，全過 exit 0，有失敗 exit 1，格式錯誤 exit 2；
  只在拋棄式 clone 執行 `command` 題。附 deterministic 測試（全過、缺字串、路徑不存在、指令失敗、格式錯誤）。
- `transfer-workflow.md`：在途工作改為以 default branch 比對未合併的 local／remote branch，並列出 worktree 與未 commit
  變更（P2 觀察：Sonnet 判定不穩）；新增出題步驟；移交未完成條件加「接手驗收題組或判分檔未建立」；新增「接手驗收」
  一節說明 fresh clone 作答、判分與完成紀錄（milestone 由之後的 Log 寫）。Transfer 模式仍不 commit。
- 驗收：判分測試進 `tests/`；fixture repo（含排程、外部帳號、決策紀錄與一條未合併 branch）由 Sonnet 執行
  `/project transfer`，產出指南、題組與判分檔；指南 commit 到 fixture 後，fresh-context agent 只用 fresh clone 與題目作答，
  判分全數通過；負對照把移交人獨有的事實從指南移除，對應題目判分失敗。另以原 `transfer` case 在 Sonnet 跑 3 次，
  確認在途工作（未合併 commit）每次都列為缺項。

**P3 實作結果（2026-10-12，branch `feat/issue-309-handover-acceptance`）**

- `grade-handover.py` 先寫 9 項測試（紅），實作後全綠；接進 project 模組與選測設定。
- Fixture（Claude Code 2.1.296、Sonnet claude-sonnet-5-5、effort high）：移交人 session 只給四項 repo 沒寫的事實（主機、
  log 位置、credential 存放處與核發者、支援期限）。Transfer 產出指南與 5 題題組，事實全部寫進指南、無 credential 值、
  不 commit；判分檔已 gitignore 且未 tracked；未合併的 `feat/retry-backoff` 列為缺項；另指出 fixture 的 `bin/sync`
  不在 repo、`tests/run.sh` 寫死 macOS Python 路徑。指南 commit 後，fresh-context Sonnet 只用 fresh clone 作答，未讀
  clone 外檔案，判分 5／5 通過。
- 負對照：只刪「部署、排程與維運」一節時仍 5／5 通過，因指南在其他節也提到主機名稱，刪一節不具鑑別力；改為把移交人
  獨有的事實（主機、credential 存放處）從整份指南移除後，對應的 Q2、Q5 失敗（3／5），作答者照實回答 repo 查不到。
- 在途工作：原 `transfer` case 在 Sonnet 跑 3 次，3 次都把未合併 commit 寫進指南與缺項（P2 修正後同 case 為 3 次中
  1 次明確抓到）；加上 fixture 那次共 4／4。


### P5：縮減必讀 reference 與端到端量測

P2 刪除後量測必讀 reference 的讀取量與一筆真實交付的耗時；#285 計畫第 5、6 步由本階段承擔。

## 不做

- 不新增接續相關的新機檢；重新啟用的 `active_item_contract` 只沿用 scanner 既有的兩項內容檢查，不改 scanner。
- 不改受信任 scanner；不清除其他 repo 的歷史紀錄。
- 不處理已封存的 kapi-kb-hub-legacy 與已移交的 ais-platform。
- 接受的殘留：同主機以外的平行 session 沒有可觀察訊號，衝突在 rebase 時才出現；STATUS 衝突的解法只靠 kernel 文字；
  `Goal` contract 抓不到未標記的已完成項目。

## 寫入範圍

`shared/skills/project/`、`claude/skills/project/`、`codex/skills/project/`、`shared/skills/deep-review/`、
`shared/skills/ready4quit/`、`shared/skills/handoff/`、`tests/`、`claude/evals/`、`docs/testing-contract.md`、
`docs/project-spec.md`、`docs/document-governance.md`、`docs/backlog.md`、`.doc-governance.json`、`AGENTS.md`、
`claude/CLAUDE.md`、`codex/AGENTS.md`（kernel 段依使用者核定內容）、本計畫、STATUS.md、`docs/archive/`；P1、P2b
另含各受治理 repo 的 `.doc-governance.json`、`AGENTS.md`、`tests/test_agent_contract.py` 與 STATUS.md。
