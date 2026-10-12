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

### P2：shared skill 移除身分授權層

依「範圍」移除；STATUS 的接續要求改寫為內容契約：停手時（Log 收尾或中途換手）工作項的目標、驗收、進度、下一步
正確，未合併的工作已 commit 並 push、在下一步寫明所在 branch。平行作業維持 branch／worktree 與 kernel 安全底線。
驗收：

- `rg -n 'steward-authority|Dossier Steward|Write Scope|resume=|as=|binding packet|conditional owner'`（排除
  `docs/archive/`、`docs/plans/` 與歷史段）只剩逐筆列明的歷史或退役說明。
- 全套測試、`audit --ship` 通過；必讀 reference 改前改後 bytes 列入報告。
- 行為：以 `tests/project-reference-eval.py` 的 `committed`、`spec`、`tested` case 在 Claude Code 樓層模型與 Codex
  production model 各跑一次，oracle 為不呼叫 steward 授權、不出授權確認題、到達原本的終點；另以一個跨 runtime
  接續 fixture（Codex 寫 Spec 並停手，Claude 只靠 repo 接續到 Log）驗證接手方能從 STATUS 與 git 找到下一步並完成。
- 審查：會改變放行／攔下行為，實作前跑一批 deep-plan（D-20261012-deep-plan-full-review-routing）。

### P3：移交給同事（重點）

移交改為「讓接手的人掌握全貌」的流程，不再切換 actor：

1. 移交指南（`docs/transfer.md`）涵蓋：系統組成與外部依賴；環境建置與驗證指令；部署、排程與維運（哪些主機、
   cron、服務在跑，掛了先看哪）；外部帳號、權限與 credential 清單（只記名稱與存放位置，值不進 git）；進行中的
   工作（指向 STATUS）；決策與死路的入口（`find` 查詢範例與關鍵 D／X ID）；已知風險與技術債；移交人的支援期限
   與聯絡方式；待雙方決定的事項。
2. Portable-knowledge audit 保留：只存在對話或私人記憶的專案事實先寫進 repo；credential 分離與 metadata helper
   保留；authorization 不隨移交。
3. **接手驗收題組**：移交人在指南中列出接手者必須能獨立完成的任務與問題，每題附可機械判定的預期結果（指令
   exit 0、輸出包含指定內容、答案引用的路徑存在或 D／X ID 正確）。驗收方式是在只有 fresh clone、沒有移交人
   記憶的環境中由接手者（或 fresh-context agent）作答，以腳本判分；人工主觀判讀不當作驗收。
4. 移除 BLOCKED／PREPARED／TRANSFERRED 狀態機、conditional owner record、active-item mapping 與 remote ancestry
   判定；移交完成以「指南合併、接手驗收題組通過、權限調整由人完成」記錄。

驗收：以一個 fixture repo 實跑一次移交，接手驗收題組由 fresh-context agent 作答並以腳本判分全數通過；
`verify-transfer-credential.sh` 既有測試保留通過。

### P4：kernel「Shared work」段改寫

提出逐字草稿請使用者核定：保留「一個工作項一個 writer、平行 writer 用不同 branch／worktree」與既有安全底線；
移除 Dossier Steward、Dossier delta、cherry-pick 整合與 steward 移交相關句；接續改指向內容契約。三份同步手改，
`kernel-gate.py` REQUIRED／CANARIES 與 fixture 同步。驗收：`kernel-gate.py` 先紅後綠、全套測試通過。

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
