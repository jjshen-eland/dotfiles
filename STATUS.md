<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260805-debt-22：重新判定輪次隱蔽 A/B 擴樣的現行決策價值 ⏳

- **Writer**：`codex:reassess-b22-round-framing`
- **Workspace**：`branch=docs/reassess-b22-round-framing`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`, `shared/skills/deep-review/evals.md`
- **Dossier Steward**：`codex:reassess-b22-round-framing`
- **Context**：B22 來自 2026-08-05 的 Sonnet 盲測：不提輪次與告知「最後一輪」各 `n=3`，blocking 平均 `3.67→2.67`，但組內變異大、六個 reviewer 皆判 FAIL，故只記為方向一致的弱證據。同期已有直接 transcript 證據顯示後期 prompt 曾洩漏 review cap 並主動放寬任務，輪次隱蔽與中性 fix commit 亦已落地；需重新確認現行 deep-review 契約是否還依賴這個舊模型的效應量問題。
- **Goal**：判定擴大舊 Sonnet A/B 樣本是否仍能改變任何現行設計決策；無決策價值就結清 B22，仍有價值才預註冊一個當代、最小且可判定的實驗。
- **Acceptance Criteria**：盤點現行 Claude／portable deep-review 中關於 fresh reviewer、輪次／review-cap 隱蔽、中性 checkpoint commit 與 blocking bar 不隨流程放寬的載入契約及可執行 gates；核對 2026-08-05 後的 behavior eval、transcript 與實戰證據，分開「已觀察的 prompt 洩漏／任務放寬」與「輪次提示對 finding 數量的因果效應量」；以決策矩陣明列 A/B 若為正向、無效應或反向，各自會不會改變現行契約。若三種結果都不會改變設計，不發動新模型呼叫、不修改 skill／gate，移除 B22 並記錄「舊效應量研究已失去行動價值」的 milestone，且不把舊弱證據改寫成已證實或無效應。若任一可能結果會改變具體規則，先在 `shared/skills/deep-review/evals.md` 預註冊現行模型與 runtime、immutable fixture/range、單一操弄變因、主要 outcome、sample size 與 stop rule、污染控制、成本上限及會導向哪個設計決策的預定門檻；不沿用舊 `n=3` 判準、不在預註冊前跑樣本。最終通過 doc-governance ship audit，若修改 eval 或 Markdown 權威節名則依 repo 契約補跑完整 suite。
- **Constraints**：不用當前模型的直覺覆蓋舊實驗；不因舊數據弱就反向宣告「沒有效應」；不為了結案而放寬 fresh-context 或 blocking-bar 安全契約；behavior eval 為 oracle，只為會改變決策的失敗補規則；如後續需修改 `shared/skills/deep-review/evals.md` 或任何 repo-local skill surface，先完整執行當前 runtime 的 `$skill-creator` 與 repo skill-building guide preflight；不改寫已歸檔歷史。
- **進度**：已確認 2026-08-23 的 `D-20260823-portable-deep-review` 已將 legacy R1–R5 編排收旂為雙 runtime portable core，2026-09-12 再依 `D-20260912-neutral-portable-skill-core` 搬到 neutral core。現行 workflow 與 P5／P15 behavior oracle 以 fresh-context independence 直接排除 prior findings、pass number 與 remaining budget；舊 A/B 只計 findings／blocking 數、未驗證正確率與召回率，且六個樣本全判 FAIL。決策矩陣的正向、零效應、反向三格都不會改變現行契約：正向只增強現狀；零效應無法推翻已觀察的 cap 洩漏／任務放寬；反向的數量增加也不證明 finding 更正確。故擴大舊 Sonnet A/B 已無行動價值，不預註冊或執行新實驗。
- **下一步**：由 Project Log 記錄結案 milestone、移除 B22 與 active item，不修改 skill／gate／eval。
- **關聯**：`B-20260805-debt-22`, `D-20260823-portable-deep-review`, `D-20260912-neutral-portable-skill-core`

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
