<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### B-20260820-debt-15：結案已被 testing contract 吸收的兩條判準 ⏳

- **Writer**：`codex:close-b15-retained-test-criteria`
- **Workspace**：`branch=docs/close-b15-retained-test-criteria`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:close-b15-retained-test-criteria`
- **Context**：2026-08-10 將已結案技術債歸檔時，另開一項要求保留「repo-local 測試權威」與「便宜 gate 趁乾淨加入」兩條判準；`d5c1564` 已於翌日把兩者移入 `docs/testing-contract.md`，但 item 未同步結案，2026-08-16 又被機械搬進 backlog。
- **Goal**：依現行 repo 與歷史證據判定 B15 是否仍有實作缺口；若既有權威與 gate 仍有效，移除 stale backlog item，避免製造重複規則。
- **Acceptance Criteria**：確認 repo-local test authority 仍由 root `CLAUDE.md`／`AGENTS.md` 承接、root import 有機檢、xref audit 通過；確認 shellcheck gate 仍涵蓋 `claude/evals/*.sh` 且設計理由保留；新增 milestone 記錄既已滿足與不新增重複 gate 的理由；B15 自 backlog 移除；doc audit 通過。
- **Constraints**：不為已滿足項新增行為規則、skill instruction 或重複 gate；不改寫 2026-08 歷史記錄；不擴張到其他 backlog item。
- **進度**：歷史與現況已核對；`d5c1564` 是實質完成點，現行 xref audit 為 0 findings，root import 與 shellcheck coverage 均仍有對應機制。
- **下一步**：記錄 B15 stale-state 結案 milestone、移除 backlog item並跑 doc audit。
- **關聯**：`B-20260820-debt-15`, `d5c1564`, `3c7e0a6`, `f2e7aa0`

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
