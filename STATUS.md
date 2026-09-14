<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### B-20260815-debt-11：結案 Linux 完整 suite 無流程驗證的技術債 ⏳

- **Writer**：`codex:close-linux-ci-debt`
- **Workspace**：`branch=docs/close-linux-ci-debt`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:close-linux-ci-debt`
- **Context**：B11 原先記錄 `tests/run.sh` 只有 macOS 日常執行、Linux 無任何固定流程；PR #179 已建立 macOS 15＋Ubuntu 24.04 完整 suite，PR #183 再次證明兩個 required checks 實際通過。
- **Goal**：核對現行 workflow、測試契約與 GitHub required-check 證據，將已解決的 B11 正式結案。
- **Acceptance Criteria**：PR workflow 固定在 macOS 15＋Ubuntu 24.04 執行 `./tests/run.sh`；cross-platform regression gate 存在；兩個 check contexts 仍為 `main` required；有 event-time milestone；B11 自 backlog 移除；doc-governance 與完整 suite 全綠。
- **Constraints**：不新增 merge 後 `push: main` 的重複完整 run；不降低 macOS 或 Ubuntu 覆蓋；不把單次本機 Linux 測試冒充持續驗證。
- **進度**：已確認 repo 內 workflow／contract／既有 CI 里程碑符合原始缺口的解法；待重驗 GitHub protection、補結案紀錄與回歸驗證。
- **下一步**：取得 required-check 現況，加入 milestone、移除 B11，執行完整 suite 與 ship audit。
- **關聯**：`B-20260815-debt-11`, `M-20260912-cross-runtime-portability`, `M-20260912-ci-run-34676591841-repair`, `D-20260913-project-merge-authorization-ci`

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
