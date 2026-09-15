<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-16)

---

## 進行中

### B-20260820-debt-18：重驗 Project Scenario 11 無 PR merge 導引 ⏳

- **Writer**：`codex:revalidate-project-scenario-11`
- **Workspace**：`branch=test/revalidate-project-scenario-11`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`; only if a current behavior RED is observed: `shared/skills/project/references/`, `tests/run.sh`
- **Dossier Steward**：`codex:revalidate-project-scenario-11`
- **Context**：B18 記錄 Scenario 11 曾有弱模型只說明方向、未展開「merge 但無 PR」的明確選項；2026-08-06 後 shared `ship-paths.md` 已加入 runtime user-input primitive 的兩選項，需以現行 portable Project 重新判定 backlog 是否仍成立。
- **Goal**：用現行雙 runtime 入口、shared core 與隔離 fixture 重驗「明示 merge、default 已存在、feature branch 無 PR」時的導引是否仍會漏讀。
- **Acceptance Criteria**：先建立現行 baseline 與可觀察 oracle；弱模型不得直推 default、不得猜 merge，且須提出「開 PR 再 merge（建議）」與「只 push branch、由使用者自行合併」兩個選項；只有可重現缺口才先取得 RED 並做最小修正，否則移除 B18、記錄結案 milestone，並通過 doc audit 與完整 suite。
- **Constraints**：不沿用舊 Sonnet 結論冒充現行證據；不實際 push、開 PR 或 merge；不因純 prose completeness 擴大規則；`claude/settings.json` runtime drift 不屬本項範圍。
- **進度**：已建立 feature branch並完成 skill-authoring／portable migration preflight；現行 canonical core 位於 `shared/skills/project/`，Claude／Codex thin entries 共用同一 references；尚未執行行為重驗或修改 skill。
- **下一步**：重建 Scenario 11 的無 PR fixture，先測現行弱模型輸出，再依 oracle 決定最小修正或直接結案。
- **關聯**：`B-20260820-debt-18`, `shared/skills/project/references/pressure-tests.md` Scenario 11, `shared/skills/project/references/ship-paths.md`「Merge 最後一哩」

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
