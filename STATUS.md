<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### B-20260811-debt-13：清除 tests/run.sh 的 printf-to-grep-q pipeline ⏳

- **Writer**：`codex:retire-printf-grep-pipes`
- **Workspace**：`branch=test/retire-printf-grep-pipes`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`, `docs/testing-contract.md`, `tests/run.sh`
- **Dossier Steward**：`codex:retire-printf-grep-pipes`
- **Context**：B13 記錄 `tests/run.sh` 仍有 20 處 `printf … | grep -q` 潛伏 pipefail／SIGPIPE 偽判；本次重新盤點為 21 處，新增的一處來自後續 yq stub 參數判斷。
- **Goal**：將全部同型 pipeline 等價改為 herestring，並用 source regression gate 防止復發。
- **Acceptance Criteria**：修前 gate 精確列出所有命中；修後命中數為零；既有斷言語意不變；`bash -n`、repo 參數的 ShellCheck、完整 suite 與 doc-governance ship audit 全綠；有 event-time milestone，B13 自 backlog 移除。
- **Constraints**：只處理 `printf` producer；不關閉 `pipefail`，不擴張成其他 producer 的無邊界清理。
- **進度**：實作與驗證已在尚未送出的 candidate `c419a3d` 完成；正依 prompt-bound authority recovery 在最新 main 上受控重建。
- **下一步**：提交本 active contract，重建 completion candidate，重驗後依 `$project --merge` 送出。
- **關聯**：`B-20260811-debt-13`, `M-20260914-cqs-grep-pipefail-repair`

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
