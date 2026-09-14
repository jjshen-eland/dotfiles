<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260820-debt-20：重新評估 Codex Claude plugin 的現行價值與去留 ⏳

- **Writer**：`codex:codex-plugin-reassessment`
- **Workspace**：`branch=chore/codex-plugin-reassessment`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/decisions-2026-09.md`
- **Dossier Steward**：`codex:codex-plugin-reassessment`
- **Context**：B20 原先假設 headless `codex exec` 接管 review 後 plugin 只剩 `/codex:transfer`；現機已安裝 v1.0.6，必須依實際 commands、skills、hooks、runtime 與使用紀錄重估。
- **Goal**：逐項對照 plugin v1.0.6 與 repo-local exec／skills，決定保留、官方支援的局部縮減或完整移除，不沿用舊前提。
- **Acceptance Criteria**：盤點八個 commands、三個 bundled skills、hooks、broker/state 與安裝更新入口；區分 session transfer、Project owner transfer 與 handoff；以 clean-room 測試及實際使用證據評估三條路徑，寫 event-time decision 並結清 B20。
- **Constraints**：盤點期間不解除安裝、不刪 plugin cache／marketplace／data；不虛構 plugin 未支援的 per-command disable；只有 observed behavior failure 才修改 repo-local skill。
- **進度**：已確認 plugin v1.0.6 setup ready/direct、Stop review gate 關閉；本機有 24 筆 completed task jobs，無 review jobs；upstream 隔離 suite 91/91、repo suite 1419/1419 通過。`transfer` 與 `rescue` 仍有獨有 bridge 價值，review commands 則與 repo-native workflow 重疊。
- **下一步**：記錄「完整保留為按需 bridge、canonical review 仍走 repo-local workflow」的決策，移除 B20 並送出。
- **關聯**：`B-20260820-debt-20`, `D-20260823-portable-deep-review`, `D-20260823-portable-handoff-skill`, `M-20260824-memory-independent-transfer`

---

## 暫停中

（目前無暫停中項目。）

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
