<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260818-debt-06：重驗 deep-plan 預設 reviewer 數量 ⏳

- **Writer**：`codex:reassess-b06-deep-plan-reviewer-count`
- **Workspace**：`branch=test/reassess-b06-deep-plan-reviewer-count`
- **Write Scope**：`STATUS.md`, `shared/skills/deep-plan/**`, `claude/skills/deep-plan/**`, `codex/skills/deep-plan/**`, `claude/evals/**`, `docs/backlog.md`, `docs/archive/decisions-2026-09.md`, `docs/archive/milestones-2026-09.md`, `docs/testing-contract.md`, `tests/**`
- **Dossier Steward**：`codex:reassess-b06-deep-plan-reviewer-count`
- **Context**：舊 E1 以 4 個 i.i.d. reviewer 的巢狀子集量到阻斷級聯集 N=2→5.00、N=3→6.00，但 N=3 多出的內容是既有問題的嚴重度分歧，不是新問題；因此舊判準的「沒有新增就維持 2」分支雖不成立，仍不足以證成調高預設。現行雙 runtime 已共用一份 workflow、每輪預設 N=2，Claude 以 fresh background Agent、Codex 以 deterministic launcher 實作；B05 又確立審查品質是 hard gate，成本／延遲只在品質全綠候選間排序。需以這個現況重驗 reviewer 數量，而非沿用 finding 數量。
- **Goal**：以現行 Claude／Codex deep-plan 實作與可驗證證據，判定每輪預設 N=2 或 N=3；品質只計「經查證、由 N=3 獨有命中、且會改變 GO／NO-GO」的 blocking finding。
- **Acceptance Criteria**：盤點雙 runtime 的 reviewer 建立路徑、共同 workflow、既有 behavior eval／field evidence 及其可比性；先建立 N=2／N=3 決策矩陣，只有結果仍可能改變預設值時才預註冊最小當代實驗，並以同一 frozen 有效 fixture、相同 model／effort 與可歸因的獨立 reviewer 比較。嚴重度分歧、同一缺陷的不同措辭、未查證 finding 與不影響 gate 的新增 finding 均不算品質增益。只有 N=3 能穩定增加會改變 GO／NO-GO 的獨有 blocking recall 才調高；否則維持 N=2，不新增 skill／eval／gate，移除 B06、記錄結案 milestone，並通過必要 behavior eval、deterministic gates、doc-governance ship audit 與完整 suite。
- **Constraints**：品質先於成本；成本／延遲只能在品質門通過後比較。behavior eval 是 oracle，修改任何 repo-local skill 前須完成 system skill-creator、repo authoring guide 與 portability preflight，且先取得可重現 RED；不把舊 Sonnet 樣本、raw finding 數量或 severity disagreement 當成 reviewer-count 證據；不把第二輪的獨有產出混入每輪 N 的比較；沒有決策價值就不執行付費模型批次；`claude/settings.json` 的未提交 runtime drift 不屬本項範圍。
- **進度**：已確認 doc-governance adoption 與 project trusted core，建立 feature branch，通過無 active item 時的 steward authority；已由 B06 stable ID 與自然語言查詢找回舊 E1／E3 決策、portable deep-plan、Codex deterministic launcher、B05 品質門與既有 field evidence。尚未修改任何 skill、eval 或 gate。
- **下一步**：完成 skill-authoring preflight，逐項判定既有證據是否已足以填滿決策矩陣；只有尚有會改變預設值的未決格，才預註冊並執行最小 N=2／N=3 實驗。
- **關聯**：`B-20260818-debt-06`, `D-20260819-no-single-round-deep-plan`, `D-20260825-deep-plan-empty-wait`, `D-20260825-portable-skill-authoring-default`, `M-20260915-b05-deep-plan-model-policy-reassessed`, `shared/skills/deep-plan/evals.md`, `shared/skills/deep-plan/field-log.md`

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
