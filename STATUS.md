<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260819-debt-02：重驗 handoff survey／list 等價 gate ⏳

- **Writer**：`codex:reassess-b02-handoff-equivalence`
- **Workspace**：`branch=test/reassess-b02-handoff-equivalence`
- **Write Scope**：`STATUS.md`, `shared/skills/handoff/**`, `claude/skills/handoff/**`, `codex/skills/handoff/**`, `tests/**`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:reassess-b02-handoff-equivalence`
- **Context**：B02 在 2026-08 因 handoff `survey`／`list` 等價 gate 只比對 `active:`、`path:`、`title:` 固定前綴而建立，當時預想未來可能新增 `repos:` 子行；現行輸出與 portable handoff topology 已演進，舊候選是否仍代表真實行為風險需重新驗證。
- **Goal**：以現行 handoff shared implementation、雙 runtime 薄入口、eval oracle 與 regression gate，確認固定前綴是否仍會讓 `survey`／`list` 的實際輸出漂移卻通過驗證；不因舊提案直接新增 `repos:` 或擴大 gate。
- **Acceptance Criteria**：逐項盤點兩個入口的 active 輸出來源、現行所有子行與等價 gate 覆蓋；只有可重現且會讓兩介面行為漂移卻仍通過 gate 的案例，才先取得 RED 並做最小修正；若目前沒有新增子行需求或實際風險，移除 B02、追加結案 milestone，並通過 handoff behavior eval、doc-governance ship audit 與完整 suite。
- **Constraints**：先完成 skill-authoring preflight 並以 behavior eval 為 oracle；重用既有 fixture，不製造只為證明 mutation 的人工欄位；維持 Claude／Codex portable topology，不改 Claude Auto approval lifecycle 或 Project `--merge` 零重問契約；`claude/settings.json` 的未提交 runtime drift 不屬本項範圍。
- **進度**：已完成 skill-authoring preflight、portable topology、shared `emit_active`、現行輸出、既有 gate、Git history／blame、eval oracle 與完整 suite盤點；未找到第四種 active 子行、分叉輸出或可重現 behavior gap，判定不需修改 handoff skill、eval 或測試。
- **下一步**：以 commit-aware stewardship gate 驗證 contract parent，再移除 active item、寫入 B02 結案 milestone並從 backlog 移除，重跑 ship audit 與完整 suite。
- **關聯**：`B-20260819-debt-02`, `D-20260819-handoff-active-mtime`, `D-20260819-handoff-no-ranking`, `docs/plans/2026-08-19-handoff-active-mtime.md`

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
