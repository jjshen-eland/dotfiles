<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-20)

---

## 進行中

### #229 — review convergence baseline

- **Writer**：codex:229-handoff-current-authorization
- **Workspace**：branch=fix/229-handoff-current-authorization
- **Write Scope**：本項 STATUS、docs/plans/2026-09-23-review-convergence-audit.md、shared/skills/deep-plan/{evals.md,references/workflow.md}、{codex,claude}/skills/deep-plan/SKILL.md、docs/archive/{decisions,milestones}-2026-09.md；只落地已驗證risk activation候選，full-review finding gate／brief／launcher／其他helper未改。
- **Dossier Steward**：codex:229-handoff-current-authorization
- **Goal**：查證計畫／code review 的阻斷分類與重掃成本，不以 handoff 單一候選失敗停止 umbrella audit。
- **Acceptance Criteria**：fixed cross-repo plan 中的真實 wire-contract blocker 被指出；optional improvements／既有無關 debt 不變成開工條件。reviewer-stage baseline 與完整 orchestration evidence 分開，不以前者冒充全流程驗收。
- **Constraints**：Astra medium（先前有界high分析已完成）；P18/P19均reject，不重跑洗綠。Risk-route stage150秒、native600秒／Claude USD4、每target每arm一次；harness污染與有效behavior結果分開，詳見active audit。
- **下一步**：risk activation已依使用者選擇完成本地增量，repo1488/0／雙entry validators通過，見M-20260923-risk-routing-local-increment；完整高風險review收斂、Claude prompt transport偏差與code-review污染仍未完，不把本次正常路徑改善當全#229結案。
- **進度**：plan候選拒絕：Sol完整GO；Opus第二輪reviews無blocking但parent等待超過900秒，未出有效終態；Sonnet仍擴張測試並NO-GO，且reviewer違反唯讀。Production brief未改。Code兩端一批修復產物正確，但Opus驗證reviewer讀到前輪資料仍被parent判PASS；其獨立驗收不成立。Handoff 增量已本地驗收、未ship，見 M-20260923-handoff-task-reference-local-acceptance 與 [凍結紀錄](docs/plans/2026-09-22-workflow-audit.md)。

### #229 — sequential coordination baseline

- **Writer**：codex:229-handoff-current-authorization
- **Workspace**：branch=fix/229-handoff-current-authorization
- **Write Scope**：本項STATUS、docs/plans/2026-09-23-coordination-audit.md、shared/skills/project/references/{workflow,log-workflow,dossier,pressure-tests}.md、shared/skills/project/scripts/steward-authority.py、tests/project-session-binding.py、tests/run.sh、tests/shard-manifest.tsv、docs/archive/{decisions,milestones}-2026-09.md；已驗證的same-session binding及同機單item local reassignment；後者只改workflow／dossier及oracle，kernel／runtime entry／正式transfer與shipping authorization不改。
- **Dossier Steward**：codex:229-handoff-current-authorization
- **Goal**：查證明確順序交棒的正常路徑與真實writer conflict的安全路徑。
- **Acceptance Criteria**：native targets完成原Goal而不重問內部token；衝突arm不改task／owner；無outward操作。
- **Constraints**：每target每arm一次、300秒、Claude USD2；不重跑追綠，不把helper probe當完整驗收。
- **進度**：same-session binding已本地落地；雙primary完整Spec不重問、scope變更STOP、一次新指示後續作皆通過。Helper9 tests與repo1488/0通過，見M-20260923-project-session-binding-local-acceptance。未push／跨機散佈；kernel／runtime entry／shipping authorization未改。先前batch／交棒與guided-recovery瑕疵保留，非全部coordination完成。
- **下一步**：cross-runtime Spec第二候選已本地驗收、未push，見M-20260923-project-local-reassignment-acceptance；第一候選reject保留。接續聚焦必要互動的一答恢復與完整Log／shipping未驗部分，不重測已通過的小型local Spec或parallel control；review未解部分仍在其active audit。

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

- 決策：`docs/archive/decisions-2026-09.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-09.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-09.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
