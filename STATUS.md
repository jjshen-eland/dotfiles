<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-04)

---

## 進行中

### Project reference 按執行階段載入

- **Writer**：codex:project-reference-routing
- **Workspace**：branch=refactor/project-reference-routing
- **Write Scope**：shared/skills/project/, codex/skills/project/, claude/skills/project/, tests/, docs/project-spec.md, docs/testing-contract.md
- **Dossier Steward**：codex:project-reference-routing
- **Context**：使用者要求處理先前的 skill 長度分析；現行 Log 必讀四份 reference，連 noop 都載入其他模式與 provider 故障分支。#246 單純 mode split 曾無雙端收益，不重做同一候選。
- **Goal**：依模式與實際執行階段降低無關必讀內容，保留 domain／authority／shipping 契約及 bounded reader。
- **Acceptance Criteria**：雙端 fresh native trace 證明 noop／正常 Log 少讀無關內容、各階段 mutation 前已完整讀必要契約；Spec／Transfer／未授權 shipping／截斷恢復不退步；機械判定以腳本與真 fixture 驗證；適用 validators、repo suite、doc audit 通過。
- **Constraints**：沿用 neutral shared core 與雙薄入口；不靠任意字數上限或刪安全規則；不做反覆 prose 審查；不新增持久 receipt／authority store；本輪只本機實作驗證，不 push／PR／merge／dotsync。
- **進度**：共同 reference 已按盤點／結案／送出與条件例外拆分；雙端 noop 15→3 reader calls、約少 87% bytes。正常 Log 保留測試沿用，截斷修正版、Transfer 壓力與本機 provider 終點／CI 查詢失敗停止已驗；原始 RED 與限制保留在 plan。
- **下一步**：本機結果待 shipping；使用者明示當批 endpoint 後核對既有證據與輸入差異，沿用適用結果，不因進入 Log 重跑全套。
- **關聯**：D-20260822-portable-project-skill;D-20261002-project-model-bootstrap;X-20261002-project-loading-candidates;D-20261004-project-reuse-mechanical-adoption;D-20261004-project-stage-routing;docs/plans/2026-10-04-project-reference-routing.md

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。
- **B-20260824-remote-human-contributor-path**：pending；現行 feature branch／PR 可作為 Git 傳遞媒介，
  Project authority gate 也能在 steward 評估 candidate commit 時列出 shared-surface 越界；但既有 worker
  契約仍不允許自行 push，PR CI 亦不依 contributor 身分判斷 stewardship。可取得的 dotfiles 與三個已 rollout
  repo 的 PR／commit 紀錄沒有 remote-human contributor 實例，未觀察到傳遞阻塞或 authority drift，故不新增
  程序、eval 或 provider gate。**恢復條件**：第一位具名、跨主機真人 contributor 需要交付 commit，或首次出現
  非 steward PR；保留其 exact SHA、declared scope 與 Dossier delta，實測 steward fetch／shared-surface 檢查／
  cherry-pick。任一步受阻，或越權 shared dossier mutation 未被攔下，才以該事件取得 RED 並做最小修正。

## 歷史入口

- 決策：`docs/archive/decisions-2026-10.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-10.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
