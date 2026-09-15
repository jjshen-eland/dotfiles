<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260817-debt-07：重驗 deep-plan eval oracle 的獨立全文審查需求 ⏳

- **Writer**：`codex:reassess-b07-deep-plan-eval-review`
- **Workspace**：`branch=test/reassess-b07-deep-plan-eval-review`
- **Write Scope**：`STATUS.md`, `shared/skills/deep-plan/**`, `claude/skills/deep-plan/**`, `codex/skills/deep-plan/**`, `docs/backlog.md`, `docs/archive/decisions-2026-09.md`, `docs/archive/dead-ends-2026-09.md`, `docs/archive/milestones-2026-09.md`, `docs/testing-contract.md`, `tests/**`
- **Dossier Steward**：`codex:reassess-b07-deep-plan-eval-review`
- **Context**：B07 建立於 2026-08-17，原始問題只是當時的 `deep-plan/evals.md` 因 batch prompt 隔離而未進 `/deep-review`；其後該檔加入 P8–P12 與多次行為紀錄，又經 portable revalidation、雙 runtime thin entries、deterministic Codex launcher 與 neutral shared core 遷移。現行 canonical oracle 已位於 `shared/skills/deep-plan/evals.md`，Claude compatibility path 共用內容，且 repo gates 持續驗證 topology、orchestration 與 failure contract；需重新判斷舊的「未曾全文審查」是否仍代表可觀察風險。
- **Goal**：以現行 canonical eval oracle、fixture、實作、歷史 revalidation 與 regression gates 判定是否仍需一次獨立全文審查；不把「從未做過」本身當成缺口，也不讓 prose review 取代 behavior eval oracle。
- **Acceptance Criteria**：完成 existing-skill portability preflight，盤點 `shared/skills/deep-plan/evals.md` 的現行行為契約、fixture 可達性、stale pointers、oracle 自洽性，以及每項仍承重的 production 行為是否有對應 regression evidence；建立決策矩陣，明列全文審查的不同可能結果會改變哪個驗收或設計決定。只有找到可重現的 oracle 自相矛盾、失效 fixture、錯誤 canonical linkage，或能讓壞行為通過的 coverage gap，才先取得 RED 並做最小修正；若後續 revalidation 已涵蓋決策風險、其餘只會產生 prose completeness findings，則不執行獨立全文審查、不新增 skill／eval／gate，移除 B07、記錄結案 milestone，並通過必要 behavior／deterministic gates、doc-governance ship audit 與完整 suite。
- **Constraints**：behavior eval 是 skill 正確性的 oracle，全文 reviewer finding 只可作待查線索；修改任何 repo-local skill 或 eval 前須完成 system skill-creator、repo authoring guide 與 portability preflight，且先保存具體 RED；不把歷史結果表、舊模型名稱或已淘汰 orchestration 當成現行發布門檻；不為 prose 完整度、風格或理論風險擴寫 oracle；不把 eval oracle 注入 production reviewer prompt；未獲明確授權不建立 fresh subagent 全文審查；`claude/settings.json` 的未提交 runtime drift 不屬本項範圍。
- **進度**：已確認 doc-governance adoption、project trusted core 與 B07 stable-ID retrieval，建立 feature branch並通過無 active item 時的 steward authority；初步命中 portable deep-plan、neutral-core topology、testing contract、B23 模型樓層與 B06 reviewer-count 結案證據。尚未修改任何 skill、eval、fixture 或 gate。
- **下一步**：完成 skill-authoring preflight與 canonical topology baseline，逐節把現行 oracle claims 對到 fixture、實作與 regression gate，先判定是否存在會改變決策的 observed gap。
- **關聯**：`B-20260817-debt-07`, `M-20260818-deep-plan-structural-fixes`, `M-20260822-portable-deep-plan`, `D-20260825-deep-plan-empty-wait`, `M-20260825-portable-deep-plan-revalidation`, `D-20260912-neutral-portable-skill-core`, `M-20260915-b06-deep-plan-reviewer-count-reassessed`, `shared/skills/deep-plan/evals.md`, `docs/testing-contract.md`

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
