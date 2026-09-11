<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-11)

---

## 進行中

### 1. 跨平台與跨 runtime 收斂 ⏳

- **Writer**：`codex:cross-runtime-portability`
- **Workspace**：`branch=refactor/cross-runtime-portability`
- **Write Scope**：`repo-wide`
- **Dossier Steward**：`codex:cross-runtime-portability`
- **Context**：macOS／Ubuntu 與 Claude Code／Codex 的測試、設定同步、outward-action gate、skill canonical topology 已出現可重現漂移或錯誤 ownership 暗示。
- **Goal**：完成 `docs/plans/2026-09-11-cross-runtime-portability.md` 的四段實作與驗收；遠端 shipping／fleet rollout 不在本輪授權內。
- **Acceptance Criteria**：雙 OS CI；push/merge gate；Codex 三層 config 原子收斂；dotsync 精確 exit；neutral shared skill core 與 `$HOME/.agents/skills` discovery；完整 tests／validators／doc audit 全綠。
- **Constraints**：維持 Claude Auto、Codex `danger-full-access`；Linux 僅 Ubuntu 24.04+；不修改第三方或 unmanaged legacy skill；每個外送操作另取授權。
- **進度**：前三段已完成；Codex config 三層 merge、managed-path deletion、TOML/race/lock guard 與 dotsync 本機＋遠端聚合終判皆通過，完整 suite `PASS=1379 FAIL=0`。
- **下一步**：把 portable skill 核心搬至 `shared/skills/`，遷移 Codex discovery 至 `$HOME/.agents/skills` 並跑 validators／evals。

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
