<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260821-debt-27：重驗程序型文件的 title-free recall ⏳

- **Writer**：`codex:reassess-b27-title-free-recall`
- **Workspace**：`branch=docs/reassess-b27-title-free-recall`
- **Write Scope**：`STATUS.md`, `.doc-governance.json`, `scripts/doc-governance.py`, `tests/test_doc_governance.py`, `tests/fixtures/doc-governance/**`, `docs/document-governance.md`, `docs/testing-contract.md`, `docs/backlog.md`, `docs/archive/decisions-2026-09.md`, `docs/archive/dead-ends-2026-09.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:reassess-b27-title-free-recall`
- **Context**：B27 的舊結論來自 2026-08 的 dotfiles 與 canary 語料；其後 doc-governance 的分節、per-file cap、fixture 與 B26 的 Git-ignore／xref 行為已演進，不能直接沿用當時的 4/20、12/20 或 13/20 結果，也不能假設舊的 ranking 候選仍具決策價值。
- **Goal**：以現行 dotfiles 與可取得的真實語料重新量測程序型文件的 title-free recall，分別判定跨語言、作者面 H2 結構與權重形狀是否仍造成會影響實際查找的可重現 miss；只修仍有效的行為缺口。
- **Acceptance Criteria**：以不複製目標標題的 query 建立現行 baseline，逐題保存預期目標、排名與 miss 分類；明確核對 B26 後的分節、Git-ignore 與檢索行為是否改變舊結論；跨語言、H2 作者結構與權重形狀各有證據支持的現行判定；若缺口仍有效，先以 deterministic fixture／regression gate 取得 RED，再做最小修正並取得 GREEN；若舊候選已失去決策價值，不新增實作，移除 B27 並記錄結案 milestone；最終通過 doc-governance ship audit 與完整測試。
- **Constraints**：behavior eval 與 deterministic regression gate 是 oracle；不直接調 ranking，不沿用或重跑舊 Sonnet 實驗，不把目標標題塞回 query 製造假綠；不重做已由 `X-20260822-doc-h1-token-signal` 與 `X-20260823-retrieval-idf-and-h3-chunking` 證偽的 H1／IDF／H3 方案，除非先有新的 observed evidence；外部真實語料只作唯讀量測，不改其他 repo。
- **進度**：以 dotfiles `8341350` 與 fresh canary `5b6db0c` 完成既有 20 題及事前固定的新 12 題量測。兩條獨立 synthetic RED 已以正確 history title 邊界與比例 reason boost 轉綠；doc-governance 86 tests、ship audit 與兩次完整 suite 均通過 `PASS=1419 FAIL=0`。
- **下一步**：由本次 Project Log 建立 code＋docs commit，再以 lifecycle commit 記錄 milestone、移除 B27／B30 與本 active item，送至 PR 並依 `--merge` 完成最後一哩。
- **關聯**：`B-20260821-debt-27`, `B-20260822-debt-30`, `D-20260915-b27-cross-language-boundary`, `X-20260822-doc-h1-token-signal`, `X-20260823-retrieval-idf-and-h3-chunking`

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
