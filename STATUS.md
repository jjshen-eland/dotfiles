<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### B-20260815-debt-10 Project no-checks regression coverage ⏳

- **Writer**：`codex:project-no-checks-reported-eval`
- **Workspace**：`branch=test/project-no-checks-reported-eval`
- **Write Scope**：`STATUS.md`, `claude/evals/README.md`, `claude/evals/setup-sandboxes.sh`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`, `shared/skills/project/references/pressure-tests.md`, `tests/run.sh`
- **Dossier Steward**：`codex:project-no-checks-reported-eval`
- **Context**：Project merge 分流已能辨識 `BLOCKED`、`no checks reported` 與 `required-policy: none`，但 B-20260815-debt-10 指出正式 eval 缺少這個實戰形狀。
- **Goal**：加入可重跑的第三控制臂，證明 no-checks 不是 required check failure，而是與 CI 無關的 protection blocker。
- **Acceptance Criteria**：fixture 精確回傳 no-checks 與 exit 1、ship-state 回報 required-policy none；全綠與 pending 控制臂維持；完整 suite、skill validators、ShellCheck 與 doc audit 全綠，且不顯著拉長 CI。
- **Constraints**：不更改既有 merge 判斷語意；不混入另一條 B09 分支；不降低 macOS／Ubuntu PR coverage。
- **進度**：實作與驗證已在尚未送出的 candidate `5fdad97` 完成；正依 prompt-bound authority recovery 受控重建。
- **下一步**：提交本 active contract，重建 completion candidate，重驗後依 `$project --merge` 送出。
- **關聯**：`B-20260815-debt-10`, `D-20260913-project-merge-authorization-ci`

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
