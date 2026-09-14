<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### B-20260809-debt-14：讓 handoff dirty 錨點反映最終 repo 狀態 ⏳

- **Writer**：`codex:handoff-final-anchor-order`
- **Workspace**：`branch=fix/handoff-final-anchor-order`
- **Write Scope**：`STATUS.md`, `shared/skills/handoff/references/workflow.md`, `shared/skills/handoff/evals.md`, `tests/run.sh`, `docs/testing-contract.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:handoff-final-anchor-order`
- **Context**：歷史 H5 實查證明 W2 先蓋 `dirty=1` 錨點、W3 再沉澱 `STATUS.md` 後 live dirty 變 2；2026-08-23 的授權收緊只排除未授權 repo mutation，合法另授權的 durable write 仍可重現時序缺陷。
- **Goal**：讓所有已授權 durable repo mutation 在最終 anchors 前完成，使 handoff frontmatter 的 `dirty=N` 與寫檔時 repo 狀態一致。
- **Acceptance Criteria**：新增使用 2026-08-09 逐字錯誤的行為 oracle；workflow 明定 durable routing／repo mutation 先於 anchors；source-order gate 能在舊順序下失敗、修後通過；未授權 handoff 仍不得改 repo；雙 runtime 共用 topology 不變；validator、ShellCheck、完整 suite 與 doc audit 全綠；有 milestone，B14 自 backlog 移除。
- **Constraints**：不修改 `handoff-anchor.sh` 的 dirty 定義；不放寬 handoff 的 repo mutation 授權；不重構 runtime adapters 或 shared linkage。
- **進度**：實作與驗證已完成於尚未送出的 local candidate `e325c62`；現依 prompt-bound recovery 建立 active contract 並重建 candidate。
- **下一步**：提交 active contract、重建完成內容、重驗 authority 與最終 tree，然後接續 `$project --merge`。
- **關聯**：`B-20260809-debt-14`, `M-20260823-portable-handoff-skill`, `D-20260825-portable-skill-authoring-default`

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
