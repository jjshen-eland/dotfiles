<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-08-26)

---

## 進行中

### Portable nc-notify skill ⟳

- **Writer**：codex:portable-nc-notify
- **Workspace**：branch=feat/portable-nc-notify
- **Write Scope**：STATUS.md, claude/skills/nc-notify/, codex/skills/nc-notify/, docs/archive/decisions-2026-08.md, docs/archive/milestones-2026-08.md, docs/testing-contract.md, tests/run.sh
- **Dossier Steward**：codex:portable-nc-notify
- **Context**：既有 Claude Code `nc-notify` 仍是單 runtime 入口，且舊範例會將 raw transport exception 寫入 warning；本輪已用 fresh 雙 runtime fixture 發現並修正 lifecycle 及 secret-safe evidence 差異，現需依 Project recovery 將尚未送出的 candidate 重建在正式 active contract 之後。
- **Goal**：讓 Claude Code 與 Codex 共用單一 runtime-neutral `nc-notify` lifecycle workflow 與 behavior oracle，並在可驗證的 steward authority 下完成 shipping。
- **Acceptance Criteria**：雙端薄 adapter 共用 canonical workflow；start/done/fail、failure isolation、可信 progress 與 secret-safe warning 在 fresh Claude Code／Codex eval 終態一致；雙 validator、doc audit、clean-clone 全測試與 candidate authority 全部通過；最終以 PR rebase merge 進入 `main`。
- **Constraints**：不傳送 live 通知、不寫 credentials、不執行或部署 cron；不複製 runtime-specific core；shared history 只由本 work item 的 Dossier Steward 重建。
- **進度**：實作與 fresh behavior eval 已完成；正在重建未 push 的 local candidate，補齊 candidate-parent authority evidence。
- **下一步**：以本 active contract 為 parent 重建 candidate，移除完成項，重跑 steward／doc／test gates，然後接續 `$project --merge`。
- **關聯**：D-20260825-portable-skill-authoring-default;D-20260826-portable-nc-notify;M-20260826-portable-nc-notify

---

## 暫停中

（目前無暫停中項目。）

## 歷史入口

- 決策：`docs/archive/decisions-2026-08.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-08.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-08.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
