<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### B-20260808-debt-16：結案已失去可辨識範圍的中文標點風格債 ⏳

- **Writer**：`codex:close-b16-obsolete-punctuation-debt`
- **Workspace**：`branch=docs/close-b16-obsolete-punctuation-debt`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:close-b16-obsolete-punctuation-debt`
- **Context**：B16 源自 2026-07-16 一條未指名檔案或批次的 R4 non-blocking 風格建議；2026-08-08 已明記「新增 prose」範圍不可考、無失敗案例，且標靶會隨中文文檔持續移動。現行 repo 也沒有將中文全形／半形標點定為正確性契約。
- **Goal**：確認 B16 現在沒有可實作的局部缺口，以「不再適用」結案，而不進行全 repo 文案標點正規化。
- **Acceptance Criteria**：歷史追溯證明原始建議沒有可定位 target；現況掃描證明半形標點混用是跨文檔的廣泛 prose 風格，非局部 regression；新增 milestone 記錄不做全 repo churn 的理由；B16 自 backlog 移除；doc audit 通過。
- **Constraints**：不批次重寫現有 Markdown prose；不新增沒有行為失敗支持的 style rule 或 lint gate；不改寫 2026-07／08 歷史記錄；不擴張到其他 backlog item。
- **進度**：已追溯原始與搬遷記錄；當前 54 個 Markdown 檔、約 1,734 行可命中寬鬆的中文與 ASCII 標點相鄰模式，顯示強制統一會是大面積文案 churn，而非修復可重現缺陷。
- **下一步**：記錄 B16 不再適用的結案 milestone，移除 backlog item，並執行 doc audit。
- **關聯**：`B-20260808-debt-16`, `1d96e452`, `f2e7aa0`

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
