<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-08-26)

---

## 進行中

### project watch transport error（#150）

- **Writer**：`codex:project-watch-transport-error`
- **Workspace**：`branch=fix/project-watch-transport-error`
- **Write Scope**：`claude/skills/project/references/pressure-tests.md`、`claude/skills/project/references/ship-paths.md`、`docs/archive/milestones-2026-08.md`、`tests/run.sh`
- **Dossier Steward**：`codex:project-watch-transport-error`
- **Context**：`gh pr checks --required --watch` 的 exit 1 可能是 API／transport failure，但既有展開規則只列 check failure 與 no-checks。
- **Goal**：讓 watch 結果以 non-watch recheck 定案，並把 query failure 保持為未知、fail closed。
- **Acceptance Criteria**：三路 exit-1 分流、Scenario 29 RED→GREEN、雙 runtime shared core、validator／audit／完整 tests 全綠。
- **Constraints**：不以 `statusCheckRollup` 補判、不無界 retry、不把 query failure 報成失敗或全綠。
- **進度**：實作與驗證完成；正以 prompt-bound recovery 重建尚未 push 的 shipping candidate。
- **下一步**：提交本 active contract，再提交完成變更與 milestone，重驗 authority 後走 PR／merge。
- **關聯**：GitHub #150；`M-20260826-project-watch-transport-error`；`X-20260815-ci-rollup-jq`。

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
