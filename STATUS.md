<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### B-20260814-debt-12：驗證 xref 節名完整性的反向守門 ⏳

- **Writer**：`codex:close-xref-heading-debt`
- **Workspace**：`branch=test/close-xref-heading-debt`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`, `tests/run.sh`
- **Dossier Steward**：`codex:close-xref-heading-debt`
- **Context**：B12 記錄 xref 正向比對允許 heading 或 body，通用詞節名被改壞時可能被 body 假綠；後續已加入 `requires_inbound` 證據層的反向節級孤兒檢查。
- **Goal**：以 B12 原始 `docs/dead-ends.md`「分工」節名突變驗證現行 gate，補上組合回歸 oracle 並正式結案。
- **Acceptance Criteria**：正向 body fallback 仍可放行合法內文引用；完整 repo xref scan 必須因反向孤兒檢查抓到節名改壞；`tests/run.sh` 有精確組合回歸；完整 suite 與 doc-governance ship audit 全綠；有 event-time milestone，B12 自 backlog 移除。
- **Constraints**：保留合法 body fallback；不把 xref 收窄成 heading-only；不擴張到其他 xref 債項。
- **進度**：隔離突變已證明現行反向 gate 擋下原始失效形狀；組合回歸、里程碑與 backlog 結案已完成，完整 suite `PASS=1403 FAIL=0`、ship audit `OK`。
- **下一步**：由 Project Log 重建尚未送出的 candidate，再依 `$project --merge` 送出。
- **關聯**：`B-20260814-debt-12`, `M-20260914-xref-heading-body-fallback-composition`

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
