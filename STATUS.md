<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-17)

---

## 進行中

### B-20260820-gap-07

- **Context**：backlog 曾假設 `general-rag-cs` template 產生的 crawler configuration `STATUS.md`，會在
  `npm-cs` 與 `knowledge-builder` 與 Project dossier 撞名，並預想改名為 `CRAWL-CONFIG.md`；現行 repo
  root、consumer 與 Project resolver 已完成重驗。
- **Goal**：以現行三個 repo 的實際路徑與行為判定是否仍有會覆寫 dossier、誤路由 active state 或讓治理
  gate 失效的 collision；只處理可重現且會改變行為的缺口。
- **Acceptance Criteria**：
  1. 逐 repo 核對 `STATUS.md` 的語意、producer／consumer、Git root、lifecycle 與 doc-governance adoption。
  2. 只有同一路徑覆寫、Project 誤認或 gate 漏判可重現時才取得 RED 並設計最小 migration。
  3. 沒有 observed behavior gap 時保留現行檔名，移除 B07 並追加結案 milestone。
  4. 外部 repo 零 mutation；dotfiles 的 ship audit、diff check 與完整 suite 通過。
- **Constraints**：本項只授權 dotfiles 的 dossier／backlog／history 文件；不直接沿用舊
  `CRAWL-CONFIG.md` 提案，不為 archived repo 製造 migration，不擴大為全 repo 命名整理。
- **Progress**：重驗完成且沒有 RED。三個同名 artifact 都位於 Git module 子目錄，resolver 均回 `MODULE`；
  現行 root-collision STOP 契約與 deterministic signature gate 已涵蓋假設風險。B07 已自 working-tree backlog
  移除，`M-20260917-gap-07-status-collision-retired` 已追加，三個外部 repo 保持乾淨。
- **Next step**：完成驗證後，以 Project Log 先提交本 active contract 作 durable parent，再以結案 commit
  原子移除本項並納入 backlog／milestone 變更。
- **Writer**：`codex:gap-07-status-collision`
- **Workspace**：`branch=docs/gap-07-status-collision`
- **Write Scope**：`STATUS.md`、`docs/backlog.md`、`docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:gap-07-status-collision`
- **Related IDs**：`B-20260820-gap-07`、`M-20260917-gap-07-status-collision-retired`、
  `claude/evals/doc-governance-evals.md:E7`

---

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。
- **deep-plan-timeout-cleanup-flake**：pending；PR #207 已加入可分辨 `rc`、manifest、`pid_count`、live
  descendants 與 process states 的 diagnostics。相同 launcher／fixture 本機序列重播 40 次、並行壓力重播
  100 次，以及 macOS required check 初跑與單獨重跑均通過，根因維持 `UNCONFIRMED`，不修改 production
  launcher。**恢復條件**：macOS required check 再次輸出 `timeout diagnostics:` RED；依第一個 divergent
  conjunct 重建 active contract，再做單一最小修正。
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
