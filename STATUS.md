<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-25)

---

## 進行中

### instruction-quality — 規則與 skill 撰寫品質優化計劃

- **Writer**：codex:instruction-quality
- **Workspace**：branch=docs/instruction-quality-plan
- **Write Scope**：docs/plans/2026-09-25-instruction-quality.md；STATUS.md 本工作項
- **Dossier Steward**：codex:instruction-quality
- **Context／Goal**：使用者要求維持規格與功能，核對 #229 後提出效率、一致性與品質優化計劃。
- **Acceptance Criteria**：逐項對應現行 authority、#229 已接受決策、候選範圍及正常／安全驗證；不改生效規則、不重開已驗收工作。
- **進度**：已核對 GitHub #229、後續決策及 frozen plans；分項計劃 draft 已備妥，doc audit／diff check 通過，完整 tests/run.sh exit 0（1500 PASS／0 FAIL）。未修改生效規則。
- **下一步**：後續實作待使用者指派，依計劃逐項驗證；不自動啟動 eval 或 shipping。
- **關聯**：docs/plans/2026-09-25-instruction-quality.md；D-20260924-remove-unrequested-eval-budget；D-20260925-task-continuity-and-steward-scope

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

- 決策：`docs/archive/decisions-2026-09.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-09.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-09.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
