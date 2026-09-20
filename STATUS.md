<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-20)

---

## 進行中

### PR #231 integration shard assertion manifest 漂移

- **Writer**：codex:claude-auto-mode-contract-edits
- **Workspace**：branch=fix/claude-auto-mode-contract-edits
- **Write Scope**：`STATUS.md`, `tests/shard-manifest.tsv`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：codex:claude-auto-mode-contract-edits
- **Context**：PR #231 的 Ubuntu 24.04 與 macOS 15 required jobs 都在 integration tests 全綠後，因 assertion manifest 仍期待 1081、實際為 1083 而失敗。
- **Goal**：讓 shard manifest 與新增的兩個 deterministic regression assertions 同步，不改任何測試判準。
- **Acceptance Criteria**：本機 `tests/run-parallel.sh` 從相同 mismatch RED 轉綠；完整 suite、doc audit 與兩個 required OS 都通過。
- **Constraints**：只更新可歸因的 assertion count；不得移除或放寬新增測試，不把相同跨平台失敗誤報為 Ubuntu-only。
- **進度**：CI 與本機均重現 `integration expected 1081, got 1083`；root cause confirmed。
- **下一步**：將 integration manifest 更新為 1083，重跑 parallel／serial checks；完成後移除本 active item並記錄 milestone。
- **關聯**：PR#231;run:35517972049;Issue#228;M-20260920-issue-228-auto-mode-containment-complete

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
