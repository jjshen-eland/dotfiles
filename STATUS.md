<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-16)

---

## 進行中

### B-20260820-debt-17：重驗四個 stub-only 情境的現行實戰證據 ⏳

- **Writer**：`codex:revalidate-b17-real-world-gaps`
- **Workspace**：`branch=test/revalidate-b17-real-world-gaps`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:revalidate-b17-real-world-gaps`
- **Context**：B17 合併四個 deterministic stub 已覆蓋、但尚無實戰證據的候選；後續 deep-review portable migration 可能已使其中部分路徑退役。
- **Goal**：依現行 production entry、deterministic gate 與可歸因的真實事件，逐項判定已實證、已退役、仍待自然觸發或存在 observed gap。
- **Acceptance Criteria**：建立四項 evidence matrix；不以 stub 冒充 field evidence；只對可重現的現行缺口先取得 RED 後最小修正；將尚有決策價值的自然觸發拆成精確 backlog，其餘以 milestone 結案，並通過 doc audit 與完整 suite。
- **Constraints**：不人工製造 remote drift、空 reviewer 報告、付費 review 或破壞性 rebase；不修改不可達的舊 production path；`claude/settings.json` runtime drift 不屬本項範圍。
- **進度**：已建立 feature branch，並以 repo router 召回 B17 與相關歷史契約；尚未改動 production hook、skill、eval 或 test。
- **下一步**：盤點四條現行 reachability 與 event-time 證據，再依 evidence matrix 收旂。
- **關聯**：`B-20260820-debt-17`, `docs/testing-contract.md`, `shared/skills/deep-review/references/workflow.md`

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
