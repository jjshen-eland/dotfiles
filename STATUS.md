<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-05)

---

## 進行中

### #267 — 已處置 legacy review-terminal 的有界結案

- **Writer**：`codex:issue-267-legacy-review-terminal`
- **Workspace**：`branch=fix/issue-267-legacy-review-terminal`
- **Write Scope**：`shared/skills/project, shared/skills/deep-review, tests, claude/evals, docs/project-spec.md, docs/deep-review-spec.md, docs/testing-contract.md`
- **Dossier Steward**：`codex:issue-267-legacy-review-terminal`
- **Context**：[#267](https://github.com/jjshen-eland/dotfiles/issues/267) 記錄同一個缺少
  `terminal_scope` 的舊 `blocked-review` 訊號，因祖先 commit 已進 default branch，持續阻擋後續
  feature branches。新的唯讀 PASS 不具現行 terminal-clear 所需的 autofix mutation authority；
  Log 仍提供「重跑審查，通過後清除」，無法解決這條 legacy 分支。Issue 的來源基準為
  `29f76ed44fc1a689c803a3d38e113fc93684fa71`，因果與修復須以隔離 fixture 驗證。
- **Goal**：補齊 Project／Deep Review 的 legacy 訊號生命週期，讓當次明示且有界的處置可稽核地
  結案原訊號；合法結案後不再反覆攔截無關新批次，同時維持新 review 訊號與各批 shipping gates。
- **Acceptance Criteria**：
  1. 修復前先取得跨工具測試／behavior eval 的 RED：隔離 repo 以只有 reason／head／time 的
     legacy marker，重現當批已明示處置、祖先進 default branch、下一批 fresh 唯讀 PASS 後仍 STOP；
     另證明再次唯讀 review 無法走現行清除路徑。
  2. 結案必須具名、可稽核，限定 exact 原訊號與 scope／endpoint；缺少原 coverage 時要求相應的
     當次 legacy 處置。普通 merge、舊批「照送」及不相容 PASS 均不能自動產生永久結案或授權。
  3. 合法結案的舊訊號不再阻擋無關後續批次；原始歷史、controller 與已用額度保留，不能刪除全部
     訊號、重設 budget，或用無關 autofix 取得清除資格。
  4. 新增、未處置、scope 不匹配、必要驗證未完成的 blocking／blocked review 仍 fail closed；
     新程式變更不能靠舊結案 receipt 被放行，須有相應反向測試。
  5. 相容 current-content PASS、唯讀 review 與 autofix 的 mutation authority 邊界有驗證；
     不相容或 legacy 狀態不能再被描述成「單純重跑即能清除」，Log 分流須提供實際可完成的動作。
  6. 訊號結案不授予 shipping 或 bypass：每批 push／PR／merge、CI 與 production 授權保持獨立，
     並以 behavior eval 驗證結案 receipt 不能成為下一批外向動作的授權。
  7. Claude／Codex 共用核心與 references 一致；相關 behavior eval、文件治理 audit 與
     `./tests/run.sh` 均以 exit code 通過，測試不觸碰任何 live consumer 審查狀態。
- **Constraints**：Spec 實作階段依「開工」完成本機驗收；本次 Log 的 normalized invocation arguments
  為 `--merge`，依當次 endpoint 授權與所有 gates 送出此批，不散佈。實作前依
  repo authoring route 完整讀取 system `$skill-creator`、`codex/skill-building-guide.md` 與
  `docs/skill-portability.md`，以觀察到的 RED 與既有安全契約決定最小修復。禁止修改 live consumer
  的 `.git` marker、轉移 consumer owner、修改 image、publication／production 或跨機散佈；
  不放寬 review、CI、production 或外向授權門檻。
- **進度**：本機實作與驗收完成。先取得有效跨工具 RED，再加入 exact legacy disposition、
  archive 重驗與 Log 分流；原 signal／review history／budget 保留，新訊號與無效 receipt 仍 STOP。
  Controller 23 tests、完整 `./tests/run.sh` 1568 PASS／0 FAIL（exit 0）、適用 validators 與
  文件治理通過。雙 production targets 的三個 disposition／authorization replay cases 及 blind
  forward 通過；首批 Codex metadata 權限 BLOCKED 保留，以只開放 fixture metadata leaf 的
  fresh native case 補驗完成。Replay 的 PASS 為 supplied evidence，不代表完整 native review。
  Log 補跑全套 exit 0、1568／0、303 秒，351 inputs 前後一致，helper 同環境 REUSE；六個 native
  replay 的保留 runtime source inputs 亦為 REUSE。PR／required CI／merge endpoint pending，
  未部署，未修改 live consumer。
- **下一步**：先將實作與此 active assignment 存於語意 commit，再做移除 active item 的結案提交；
  完成 candidate authority、doc audit 與 Ship 摘要後，建立 PR、等待 required CI 並 merge。
- **關聯**：Issue#267；`M-20260923-review-terminal-display-local`（既有顯示修復，非本次結案路徑）；
  `D-20261005-legacy-terminal-disposition`；`X-20261005-legacy-disposition-native-sandbox`；
  `M-20261005-legacy-terminal-disposition-local`；`shared/skills/project/references/log-prepare.md`；
  `shared/skills/deep-review/references/control.md`。

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。
- **B-20260824-remote-human-contributor-path**：pending；現行 feature branch／PR 可作為 Git 傳遞媒介，
  Project authority gate 也能在 steward 評估 candidate commit 時列出 shared-surface 越界；但既有 worker
  契約仍不允許自行 push，PR CI 亦不依 contributor 身分判斷 stewardship。可取得的 dotfiles 與三個已 rollout
  repo 的 PR／commit 紀錄沒有 remote-human contributor 實例，未觀察到傳遞阻塞或 authority drift，故不新增
  程序、eval 或 provider gate。**恢復條件**：第一位具名、跨主機真人 contributor 需要交付 commit，或首次出現
  非 steward PR；保留其 exact SHA、declared scope 與 Dossier delta，實測 steward fetch／shared-surface 檢查／
  cherry-pick。任一步受阻，或越權 shared dossier mutation 未被攔下，才以該事件取得 RED 並做最小修正。

## 歷史入口

- 決策：`docs/archive/decisions-2026-10.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-10.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
