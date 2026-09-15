<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260821-debt-26：重驗 doc-governance Round 3 非阻斷後續 ⏳

- **Writer**：`codex:reassess-b26-doc-governance-round3`
- **Workspace**：`branch=docs/reassess-b26-doc-governance-round3`
- **Write Scope**：`STATUS.md`, `.doc-governance.json`, `scripts/doc-governance.py`, `tests/test_doc_governance.py`, `tests/fixtures/doc-governance/**`, `docs/document-governance.md`, `docs/testing-contract.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:reassess-b26-doc-governance-round3`
- **Context**：B26 是 2026-08-21 Round 3 留下的集合型非阻斷候選；後續 doc-governance 與 regression gates 已演進，不能把舊清單直接視為現行缺口。
- **Goal**：逐項以現行實作、文件與 regression gate 判定已解決、已淘汰或仍有 observed behavior gap；只修最後一類。
- **Acceptance Criteria**：十二個候選各有可追溯判定；仍有效的缺口先取得 RED，再做最小修正並取得 GREEN；完成時記錄 milestone、移除 B26 與本 active item，且通過 doc-governance ship audit 與完整測試。
- **Constraints**：behavior eval 與 deterministic regression gate 是 oracle；不沿用舊集合直接開發，不為未觀察成本新增程序；不修改任何 repo-local skill surface。
- **進度**：四個可重現缺口已先取得 RED 並完成最小修正；其餘八項已有現行 gate 或不具新增規則的決策價值。doc-governance 84 tests 與完整 suite `PASS=1419 FAIL=0`。
- **下一步**：提交本 active contract 後，在下一顆受控 lifecycle commit 移除 active/backlog、保留 milestone 與實作，並完成 PR／merge。
- **關聯**：`B-20260821-debt-26`, `M-20260914-xref-heading-body-fallback-composition`, `M-20260915-doc-governance-round2-revalidated`

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
