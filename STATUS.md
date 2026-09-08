<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-08)

---

## 進行中

### 九個 repo 的文檔治理 fleet rollout 收尾

- **Writer**: `codex:fleet-rollout-closeout`
- **Workspace**: `branch=docs/fleet-rollout-closeout`
- **Write Scope**: `STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**: `codex:fleet-rollout-closeout`
- **Context**: `B-20260823-fleet-rollout-remaining` 要求 trusted core 散佈完成後，對九個採用 repo 以 remote-visible fresh clones 重驗 SHA、managed blocks、`audit --ship` 與 contract tests。
- **Goal**: 取得九個 repo 的完整 closeout evidence，記錄 milestone 並移除已完成的 backlog item。
- **Acceptance Criteria**: 九個 clone HEAD 等於 remote `main`；trusted scanner、guide 與 kernel／route／portable blocks 逐 byte 相同；九個 audit rc=0；八個 agent-contract suites 與 TEJ 完整 suite 全綠；dotfiles audit 與完整測試全綠。
- **Constraints**: 不沿用舊快照或既有 working tree 作 closeout 證據；任何 SHA、byte comparison、audit 或 test gate 失敗即不關閉 backlog。
- **進度**: 九個 fresh-clone gates、dotfiles audit 與完整測試皆已通過，正在受控重建尚未送出的 closeout candidate。
- **下一步**: 寫入 completion milestone、移除 `B-20260823-fleet-rollout-remaining` 與本 active item，重驗後送出。
- **關聯**: `B-20260823-fleet-rollout-remaining`, `D-20260824-cross-runtime-dossier-stewardship`, `D-20260825-project-prompt-bound-authority-recovery`

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
