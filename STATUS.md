<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-16)

---

## 進行中

### B-20260824-remote-human-contributor-path

- **Context**：現行單一 Dossier Steward 契約已實證同機 Claude／Codex worker 以隔離 branch／worktree、
  semantic commit 與 Dossier delta 交付，再由 steward 驗證並 cherry-pick；Project transfer 也已有
  remote-visible endpoint 與原子 ownership switch。Backlog 仍保留「跨機器真人 contributor 若不能推專屬
  feature branch，就缺少自然 commit 傳遞媒介」的舊候選，但尚未證明目前存在真人協作需求、現行 PR 路徑
  真的阻塞，或會造成 stewardship 漂移。
- **Goal**：以現行 GitHub PR／專屬 feature branch、Project stewardship 與 regression gates 重新驗證跨機器
  真人 contributor 的安全交付路徑；只處理可重現且影響實際協作的缺口，不把舊候選直接升格成新規則。
- **Acceptance Criteria**：
  1. 建立現行 evidence matrix，分開核對實際真人協作需求、feature branch／PR 的 commit 傳遞能力、shared
     dossier mutation 邊界、Dossier delta、steward 驗證／cherry-pick，以及 default branch／merge authority。
  2. 若判定有缺口，先保存一個可重現 RED：安全的 remote contributor commit 無法抵達 steward，或現行 gate
     會放過 contributor 自改 shared surfaces／自行取得 steward authority；只靠理論風險不算 RED。
  3. 只有 RED 成立才做單一最小修正，且不得授予 contributor 修改 shared dossier、自行 merge、沿用 shipping
     authorization 或繞過 branch protection 的權力。
  4. 修正時先以沙盒行為 eval 固定 RED，再通過相關 targeted gate、doc-governance ship audit 與完整
     `./tests/run.sh`；沒有 RED 時不新增 skill prose、程序、eval 或 provider 設定。
  5. 若目前沒有使用需求或 observed failure，保留 `B-20260824-remote-human-contributor-path`，補上精確、可觀察
     的恢復條件，不寫結案 milestone、不移除 backlog。
- **Constraints**：不把「能開 PR」自行等同完整安全流程；不操作真實外部 contributor 帳號、repo 權限或
  branch protection 來製造案例；不建立 machine-local lease；不讓 handoff／memory 取得 authority；若需修改
  repo-local Project skill，先執行 skill-authoring preflight 並以 behavior eval 為 oracle。
- **Progress**：已確認 repo 為 adopted governance、trusted core byte-identical，且目前無其他 active writer；
  已定位既有單一 steward、memory-independent transfer 與 deterministic authority 決策，尚未開始實作或建立
  新規則。
- **Next step**：盤點現行 contracts、Project Scenario 23／authority gates 與既有 PR 實例，建立需求／行為／
  風險矩陣；只有發現可達且具實害的缺口後，才設計最小沙盒 RED。
- **Writer**：`codex:remote-human-contributor-path`
- **Workspace**：`branch=docs/remote-human-contributor-path`
- **Write Scope**：`shared/skills/project/references/{workflow,dossier,pressure-tests}.md`、
  `shared/skills/project/scripts/steward-authority.py`、`claude/evals/setup-sandboxes.sh`、`tests/run.sh`、
  `docs/testing-contract.md`
- **Dossier Steward**：`codex:remote-human-contributor-path`
- **Related IDs**：`B-20260824-remote-human-contributor-path`、`D-20260824-cross-runtime-dossier-stewardship`、
  `D-20260824-memory-independent-transfer`、`D-20260824-project-steward-authority`、
  `M-20260824-cross-runtime-dossier-core`

---

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。
- **deep-plan-timeout-cleanup-flake**：pending；PR #207 已加入可分辨 `rc`、manifest、`pid_count`、live
  descendants 與 process states 的 diagnostics。相同 launcher／fixture 本機序列重播 40 次、並行壓力重播
  100 次，以及 macOS required check 初跑與單獨重跑均通過，根因維持 `UNCONFIRMED`，不修改 production
  launcher。**恢復條件**：macOS required check 再次輸出 `timeout diagnostics:` RED；依第一個 divergent
  conjunct 重建 active contract，再做單一最小修正。

## 歷史入口

- 決策：`docs/archive/decisions-2026-09.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-09.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-09.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
