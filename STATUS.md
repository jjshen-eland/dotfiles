<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-24)

---

## 進行中

### 229-ci-continuation

- **Writer**：codex:229-ci-continuation
- **Workspace**：branch=fix/229-ci-continuation
- **Write Scope**：STATUS.md, docs/backlog.md, docs/plans/2026-09-24-ci-continuation.md, docs/archive/decisions-2026-09.md, docs/archive/milestones-2026-09.md, shared/skills/project/references/ship-paths.md, shared/skills/project/references/pressure-tests.md, shared/skills/project/references/dossier.md
- **Dossier Steward**：codex:229-ci-continuation
- **Context**：#229 持續改善授權仍有效；PR #233 已合併，但 agent 再次把子任務終點當整體停點。CI failure 路由另明令修綠後重新要求 merge，需區分本地修復與送出阻擋。
- **Goal**：依使用者最新選項1收斂交付：保留已驗證改善，Stop／lifecycle 未通過候選不採用，不追加模型驗收。
- **Acceptance Criteria**：結果、未通過原因與剩餘缺口記錄一致；不將 prototype 能力或失效 fixture 當正式改善；文件檢查通過，無 production skill／runtime 變更。
- **Constraints**：不重測既有已綠案例、不改 default 模型、不擴充驗證、不沿用 PR #233 的 push／merge 授權；#229 umbrella 未完成。
- **進度**：本輪稽核與交付紀錄已整理；兩候選均不採用，缺口保留在 backlog。此 item 僅剩未提交的交付／結案，不代表仍在執行實驗或 #229 已完成。
- **下一步**：保存本 active contract 的提交證據，再處理文件結案與當次 Project 送出；不新增模型驗收或部署。
- **關聯**：Issue#229；B-20260924-workflow-verification-economy；D-20260924-continuation-bounded-closeout

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
