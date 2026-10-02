<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-03)

---

## 進行中

### Handoff／Ready4quit 新版模型內容品質評估

- **Writer**: codex:session-skills-model-behavior
- **Workspace**: branch=refactor/session-skills-model-behavior
- **Write Scope**: shared/skills/handoff, shared/skills/ready4quit, codex/skills/handoff, codex/skills/ready4quit, claude/skills/handoff, claude/skills/ready4quit, tests, docs/testing-contract.md
- **Dossier Steward**: codex:session-skills-model-behavior
- **Context**: 本機內容品質評估與候選驗證已完成；本輪使用者明確叫用 `$project --merge` 收尾。
- **Goal**: 保存原工作線的可驗證 assignment，依既有 shipping 流程送出並合併本批。
- **Acceptance Criteria**: 內容與已測候選一致；assignment 在 completion parent 可查；doc／authority gates 與雙平台 required checks 通過；PR rebase merge 並同步本地 main。
- **Constraints**: 評估目標為完成品質，不以 token reduction 採用；不修改 frozen implemented plan，不新增產品範圍、不部署。
- **進度**: 58 native fixtures／62 turns、兩個 fresh blind forwards及本機 suite 1564/0 已驗證；本機交付時過早移除的 assignment 正在補正提交順序。
- **下一步**: 先提交含 assignment 的本批實作，再建立結案 candidate 並通過 completion-parent authority gate。
- **關聯**: D-20261002-ready4quit-contract-first;D-20261002-ready4quit-evidence-rollup;M-20261002-session-skills-final-tree-verified;docs/plans/2026-10-02-session-skills-model-behavior.md

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
