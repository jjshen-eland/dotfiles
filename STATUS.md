<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-16)

---

## 進行中

### PR-204：修正 deep-plan SIGHUP cleanup 的 macOS regression ⏳

- **Writer**：`codex:revalidate-b17-real-world-gaps`
- **Workspace**：`branch=test/revalidate-b17-real-world-gaps`
- **Write Scope**：`STATUS.md`, `tests/run.sh`, `tests/fixtures/deep-plan-hanging-stub.py`, `docs/testing-contract.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:revalidate-b17-real-world-gaps`
- **Context**：PR #204 required Ubuntu check 通過；macOS check 唯一失敗於 deep-plan launcher 的 SIGHUP descendant-cleanup gate。前次只修正 zombie 誤判，這次 signal path 已再次觸發其重議條件。
- **Goal**：以可觀測 RED 定位 signal cleanup 的真實失敗 invariant，做最小修正並保持 timeout、fail-closed manifest 與雙 runtime portable 契約不變。
- **Acceptance Criteria**：失敗輸出可區分 exit code、manifest、PID 數與 live descendant；重現根因後先保留 RED，再修到 targeted signal／timeout fixtures、doc audit 與完整 suite 全綠；`claude/settings.json` 不進入本項 diff。
- **Constraints**：不以重跑 CI 或固定 sleep 掩蓋 race；不修改 production launcher、shared workflow、reviewer prompt、模型或 reviewer 數；不改 skill topology；沒有新 push 授權前不更新遠端 branch。
- **進度**：已完成 skill-authoring preflight、portable topology／歷史／eval baseline 盤點；正在建立 targeted macOS signal-cleanup 診斷。
- **下一步**：讓既有 fixture 在失敗時輸出各 conjunct 與 process state，重複執行 signal path以取得 RED。
- **關聯**：`PR#204`, `M-20260915-b07-timeout-zombie-oracle-fixed`, `docs/testing-contract.md`, `shared/skills/deep-plan/evals.md`

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
