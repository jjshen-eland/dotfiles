<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-13)

---

## 進行中

### 1. 恢復 Project merge 授權並縮短 CI ⏳

- **Writer**：`codex:restore-merge-authorization-ci`
- **Workspace**：`branch=fix/restore-merge-authorization-ci`
- **Write Scope**：`.github/workflows/test.yml`, `claude/settings.json`, `scripts/outward-action-gate.py`, `tests/run.sh`, `docs/testing-contract.md`, `docs/archive/`
- **Dossier Steward**：`codex:restore-merge-authorization-ci`
- **Context**：Claude outward hook 無法辨識 `/project --merge` 已授權，並造成重複 approval UI；CI 同套完整 suite 在 PR 與 main 重跑。
- **Goal**：只撤回 Claude hook、保留 Codex gate/classifier，維持 PR 雙平台 coverage 並縮短 suite。
- **Acceptance Criteria**：組合 approval UI 計數為 0；Codex 行為不變；PR-only macOS＋Ubuntu；required checks 生效；完整 suite 全綠且耗時下降。
- **Constraints**：不整顆 revert `c086aca`；不 push default；本輪 endpoint 只到 PR、不 merge。
- **進度**：本地實作與驗證完成；正在依 prompt-bound recovery 重建未送出的 candidate。
- **下一步**：建立可驗證的 steward parent，重建 completion candidate 後執行 `$project --pr`。
- **關聯**：`D-20260913-project-merge-authorization-ci`; `M-20260913-project-merge-authorization-ci`

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
