<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-13)

---

## 進行中

### 1. 審查診斷的執行隔離：import-time 寫入副作用（#315） 🆕

- **Context**：2026-10-12 Codex `$repo-review` 審 krepo-mops-disclosure#112 時，reviewer 在 review worktree 跑 pytest，被審 repo 的 `scripts/mops/__init__.py` 在 import 時 `mkdir` 出 ignored 的 `logs/`、`logs/locks/`；`-B`、`-p no:cacheprovider`、乾淨 `git status`、`review-scope.sh verify` 的 `FRESH` 都沒攔到，也證明不了零寫入。主 agent 以 `result: incomplete` 交出、controller `BLOCKED`；同 commit 的外部 archive snapshot 跑 905 tests 則未觸及 target。現行規則只在 `shared/skills/deep-review/references/portable-reviewer-brief.md` 的 diagnostics 段，這是第三次同型：前兩次（X-20261007-review-python-isolated-bytecode、X-20261007-review-git-status-index-mtime）都以補 brief 文字收斂。
- **Goal**：需要 import 或執行目標程式的審查診斷，在結構上不會寫到 review target；做不到時準確回報驗證邊界，而不是再多一句唯讀提醒。
- **Acceptance Criteria**：
  1. 修前先有 clean-room 行為 eval 為 RED：fixture repo 的 module import 會寫 ignored 目錄／檔案，審查需要 import 或跑測試；以 target 內容與 metadata 的 before／after 判定，不比對提示文字。
  2. Eval 覆蓋 ignored artifacts 起初不存在、已存在兩種情況；判定涵蓋內容、mode、size、mtime 與 Git metadata，before snapshot 在 agent 第一個 tool call 之前取得。
  3. 修後執行型診斷在與 immutable scope 一致的外部 validation snapshot 進行，或受實際能阻止寫入的 runtime 邊界保護；暫存 fixtures／cache 也在 target 外。
  4. 必要診斷無法安全執行時回報實際驗證邊界；不得以 `-B`、停用 pytest cache、乾淨 Git status 或 range fingerprint 宣稱唯讀。
  5. 修後 forward eval 通過；純靜態審查與合法外部副本測試不被多擋，各有 control case。
  6. 原安全契約不退：fresh-context reviewer 隔離、target／Git metadata 不寫入、不得私自清理副作用、不繞過 controller 重試額度。
- **Constraints**：修在哪一層（reviewer 執行路由、validation snapshot helper、runtime filesystem 保護）由 RED oracle 決定，不預先指定。Brief 是 canonical 規則唯一處，Claude `deep-review` 與 Codex `repo-review` 共用，修復須兩個入口都生效。不擴張 reviewer 寫入權限；不刪或重建失敗批次的證據來洗綠。可沿用 `tests/review-primary-native-eval.py` 既有的 target／Git snapshot guard。本項只追蹤審查流程，#112 的業務缺陷不在範圍。
- **進度**：使用者「開工」授權本地實作。修前 native eval Codex 2/2 RED（X-20261013-review-import-write-in-target），Claude 2/2 未紅；修復選在執行路由：`review-scope.sh materialize` 外部快照＋packet `validation_snapshot`＋brief／workflow 規則（D-20261013-review-execution-snapshot）。修後 Codex 4/4、Claude 2/2 target 零變動，靜態對照 PASS；情境記於 deep-review `evals.md` P24。
- **下一步**：branch `fix/review-diagnostic-isolation` 本地 commit 後，送出（push／PR／merge）與機隊散佈需另行具名授權；合併後寫 milestone、結案本項並關閉 #315。
- **關聯**：Issue#315；X-20261007-review-python-isolated-bytecode；X-20261007-review-git-status-index-mtime；M-20261007-deep-review-primary-contract；X-20261013-review-import-write-in-target；D-20261013-review-execution-snapshot

## 暫停中

- **#309 內容契約與移交給同事**：P1、P2、P2b、P3、P5 已完成（[計畫](docs/plans/2026-10-12-content-continuity-redesign.md)、D-20261012-steward-identity-removed），剩兩個 repo 待補 P1／P2b，見計畫「待補 repo」；**恢復條件**：使用者告知 krepo-mops-financial-statements 開發完成且工作樹淨空，或 kapi-nc-v2 通過驗證、取代現行 NC 成為生產 repo 並採用文件治理。
- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。

## 歷史入口

- 決策：`docs/archive/decisions-2026-10.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-10.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- 「3. Deep-review reviewer 分工投影修復（#274）」的結案契約入口：[M-20261007-deep-review-primary-contract](docs/archive/milestones-2026-10.md)；原 spec 保存在 implementation commit `d36d2b7ea5f22d4196d964423844d29074b1eb9e`。
- 「CI 最慢分片量測與保守縮時驗證（#279）」的結案契約與後續正式採用邊界：[M-20261008-ci-critical-path-measurement-complete](docs/archive/milestones-2026-10.md)。
- 「CI controller 靜態重分配本地採用（#279）」的結案契約與驗收：[M-20261008-ci-controller-core-local](docs/archive/milestones-2026-10.md)；hosted 效能仍待具名交付授權後驗證。
- 「brewup 自動更新 bun 全域套件」的本地結案契約與驗收：[M-20261008-brewup-bun-global-update-local](docs/archive/milestones-2026-10.md)；已完成本批本地來源，尚未取得 push／PR／merge／部署授權。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 「移除 turbo skill 與其他 skill 的耦合」的結案與散佈結果：[M-20261011-turbo-retired](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-11-turbo-retirement.md` 已凍結。
- 「/project 流程減量與驗證成本（#285）」的結案與量測：[M-20261012-project-process-reduction-complete](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-12-project-process-reduction.md` 已凍結。
- 「Setup 工具與 agent shell 環境對齊」的結案與 14 台驗收：[M-20261010-setup-fleet-complete](docs/archive/milestones-2026-10.md)；未做的 adopt／keep 整理見 D-20261012-setup-adopt-review-dropped。
- 「Runtime 目錄收斂與 legacy 遷移」的結案與 14 台驗收：[M-20261012-runtime-layout-complete](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-06-runtime-layout-convergence.md` 已凍結。
- 「`~/.agents` 狀態目錄治理與審查紀錄搬出 repo／`/tmp`」的結案與 14 台驗收：[M-20261012-agents-state-registry-complete](docs/archive/milestones-2026-10.md)；登記表在 `docs/repo-guide.md`。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
