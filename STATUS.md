<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-01)

---

## 進行中

### #229 backlog 發佈狀態校正

- **Writer**：codex:issue-229-backlog-status
- **Workspace**：branch=docs/issue-229-backlog-status
- **Write Scope**：docs/backlog.md
- **Dossier Steward**：codex:issue-229-backlog-status
- **Context**：PR #247 已合併且 #229 已關閉，`B-20260928-project-merge-continuation` 仍以合併前時態描述發佈狀態。
- **Goal**：校正 backlog 現況，保留尚未完成的 first-delta safety 驗證。
- **Acceptance Criteria**：條目正確記載交付 SHA、PR 與 issue 狀態；未完成 safety arm 仍留在同一 B-*；doc-governance ship audit 通過。
- **Constraints**：僅改此工作項的既有 backlog 條目及必要 lifecycle 文件；不改已凍結驗收計畫，不重開 #229。
- **進度**：原本地提交 `98663aa` 未 push、無 PR，已依使用者確認保留 diff 並重建 steward authority。
- **下一步**：提交 assignment，再以 steward 身分重建 backlog 修正與 completion milestone；驗證後依本次 `$project --merge` 送出。
- **關聯**：Issue#229;PR#247;B-20260928-project-merge-continuation

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
