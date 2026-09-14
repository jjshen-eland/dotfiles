<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### PR #184 macOS CI 的 `cqs_grep` pipefail 偽失敗修復 ⏳

- **Writer**：`codex:close-linux-ci-debt`
- **Workspace**：`branch=docs/close-linux-ci-debt`
- **Write Scope**：`STATUS.md`, `tests/run.sh`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:close-linux-ci-debt`
- **Context**：B11 結案 PR #184 的 Ubuntu 24.04 required check 通過，但 macOS 15 在 600-source crawl-quality assertion 出現 `echo: write error: Broken pipe`；`cqs_grep` 的 `echo "$out" | grep -q` 在 `pipefail` 下把 SIGPIPE 誤判成 pattern 不存在。
- **Goal**：移除 assertion helper 的 pipefail 偽陰性根因，讓大型輸出在 macOS Bash 3.2 與其他 Bash 環境皆穩定判定。
- **Acceptance Criteria**：修前大型輸出 pipeline 可重現 rc=141、herestring control 為 0；`cqs_grep` 不再建立 early-exit pipeline；原 600-source assertion、完整 suite、doc audit 與 PR 的 macOS／Ubuntu required checks 全綠；追加 corrective milestone 後清除此 active item。
- **Constraints**：不改 crawl-quality engine 或抽樣演算法；不以 rerun、忽略失敗或 bypass merge 冒充修復；不擴張成一次清理所有 B13 pipeline debt。
- **進度**：root cause 已由 PR #184 job `103824000828` log 與本機 controlled reproduction 確認。
- **下一步**：先提交本 failure-recovery contract，再以 herestring 修正 `cqs_grep`，補 corrective milestone 並重驗。
- **關聯**：`B-20260815-debt-11`, `B-20260811-debt-13`, `M-20260914-linux-suite-continuous-verification`, `PR #184`

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
