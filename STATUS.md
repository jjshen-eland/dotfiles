<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-25)

---

## 進行中

### 229-production-batch-boundary

- **Writer**: codex:229-production-batch-boundary
- **Workspace**: branch=docs/229-production-batch-boundary
- **Write Scope**: STATUS.md, docs/plans/2026-09-24-production-batch-boundary.md, docs/plans/2026-09-24-delivery-candidate.patch, AGENTS.md, codex/AGENTS.md, claude/CLAUDE.md, docs/skill-portability.md, shared/skills/project/, shared/skills/deep-plan/, shared/skills/deep-review/, codex/skills/deep-plan/, claude/skills/deep-plan/, codex/skills/repo-review/, claude/skills/deep-review/, tests/, docs/archive/decisions-2026-09.md, docs/backlog.md
- **Dossier Steward**: codex:229-production-batch-boundary
- **Goal**: 交付可直接工作的流程：移除已證實的重複授權與治理重工，保留獨立審查、回歸、安全及scope約束；不把可行性冒充效率／品質優越性。
- **Acceptance**: 雙runtime正常／安全四個既有case，不重跑before、不加相似case。不以未經使用者指定的token／美元／總時限作門檻。正常case完成mock PR endpoint、無重複授權／審查／擴scope；安全case衝突repo含.git零寫入、獨立工作接續。共同授權須雙端通過，非共同策略可分端啟用。regression／validator／audit通過。
- **Progress**: 可用版本本地完成：共同接手／同批送出接續、steward文件scope、completion parent ordering及插問接續已落地。14項assignment與1499/0回歸通過；Opus收尾與明示Project入口Sol都正確有序提交、parent gate PASS、無重問／review／history rewrite，source/tests及excluded consumer含.git不變。Generic Sol未載入Project漏接手仍記為限制，未聲稱品質／速度全面優越。未真實shipping。
- **Next**: 本批實作與必要驗證已完成，待明示commit／shipping；不是等待「繼續」做剩餘步驟。一般commit未載入Project、高風險full review與既有reviewer污染另留backlog，不自動重開整批驗收。

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
