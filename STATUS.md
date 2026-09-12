<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-12)

---

## 進行中

### 1. 修復 GitHub Actions run 34676591841 的跨平台 CI 失敗 🆕

- **Writer**：`codex:ci-run-34676591841`
- **Workspace**：`branch=fix/ci-run-34676591841`
- **Write Scope**：`.github/workflows/test.yml`, `tests/run.sh`, `docs/testing-contract.md`, `STATUS.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:ci-run-34676591841`
- **Context**：PR #178 在 required policy 為 none 時完成 merge，但新增的 macOS 15／Ubuntu 24.04 matrix run 34676591841 分別出現 75／76 個失敗；遠端 log 已觀察到 `rg: command not found` 與 ShellCheck `SC2015`／`SC2002` findings。
- **Goal**：找出本地全綠、GitHub runner 失敗的第一個因果差異，加入可重現 gate，並以最小修正讓兩個 CI matrix jobs 通過。
- **Acceptance Criteria**：修正前的 regression test 能穩定重現缺漏；原失敗證據轉綠；`./tests/run.sh`、doc-governance ship audit 與 GitHub macOS／Ubuntu matrix 全綠。
- **Constraints**：先證據後修復；一次只處理一個已確認原因；不得以忽略 ShellCheck、跳過測試或放寬 CI 作為修法；不改動未授權的 runtime 行為。
- **進度**：root cause 已確認為 runner dependency 漂移：Ubuntu image 固定帶 ShellCheck 0.9.0-1、macOS 以 Homebrew 取得 0.11.0，且兩端都沒有受 workflow 保證的 `rg`。Regression contract 修正前為 `PASS=1396 FAIL=2`，明示由 Homebrew 收斂 `shellcheck`／`ripgrep`／`yq` 後本地完整 suite 為 `PASS=1398 FAIL=0`；main 的 post-merge run 34676604555 亦重現同型雙平台失敗。
- **下一步**：commit 後以 PR 觸發 macOS 15／Ubuntu 24.04 matrix；兩個 jobs 全綠後才能寫 completion milestone 並移除本 active item。
- **關聯**：`M-20260912-cross-runtime-portability`

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
