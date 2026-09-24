<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-24)

---

## 進行中

### 229-review-followup-ci

- **Writer**：codex:229-review-followup-design
- **Workspace**：branch=docs/229-review-followup-design
- **Write Scope**：STATUS.md, tests/run.sh, tests/shard-manifest.tsv, docs/archive/milestones-2026-09.md
- **Dossier Steward**：codex:229-review-followup-design
- **Context**：PR #233 macOS run 35938302086 的 integration 全通過，但新增平台條件測試使計數 1090 與 manifest 1087 不符；Ubuntu 1087 通過。
- **Goal**：修正跨平台測試計數契約，接續原 PR 合併。
- **Acceptance Criteria**：兩平台執行相同三項 capture／fingerprint／verify 斷言，macOS 加 sandbox 限制；固定 manifest 與實際計數一致，完整 suite 與 required CI 通過。
- **Constraints**：不放寬聚合器、不重跑模型驗收、不關閉 #229、不將 Linux control 宣稱為 sandbox 驗收。
- **進度**：CI RED 與原始碼已確認根因，尚未修改測試。
- **下一步**：修正測試與 manifest、驗證並接續 push／merge。
- **關聯**：Issue#229；PR#233；M-20260924-review-followup-bounded-result

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
