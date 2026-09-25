<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-25)

---

## 進行中

### 1. Project 文字選項呈現回歸 🆕

- **Writer**：`codex:project-numbered-text-options`
- **Workspace**：`branch=fix/project-numbered-text-options`
- **Write Scope**：`STATUS.md`, `shared/skills/project/references/workflow.md`, `shared/skills/project/references/pressure-tests.md`, `tests/run.sh`, `docs/archive/decisions-2026-09.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:project-numbered-text-options`
- **Context**：Project 在無 runtime user-input primitive 時應列文字編號選項，實地卻連續將 authority 與 branch 決策壓成「請回覆確認或停止」。
- **Goal**：固定 Project 的文字 fallback 呈現，保留現有決策時機與全部 authority／branch 行為。
- **Acceptance Criteria**：離散決策的文字 fallback 列 2–3 個完整編號選項、建議項先列，不再要求關鍵字「確認／停止」；新增 observed-failure eval；雙 runtime linkage、validator、doc audit 與 `./tests/run.sh` 通過。
- **Constraints**：不新增 branch collision 預檢、不改變詢問時機、不改 authority／scope／shipping 邊界，不新增 script 或 runtime-specific 副本。
- **進度**：已以 Scenario 35 與 static gate 重現 `1499 PASS / 1 FAIL`；修正 shared runtime adapter 後完整 suite `1500 PASS / 0 FAIL`，Codex validator 與 doc audit 通過。
- **下一步**：核對最終 diff；若要送出，另行依 Project Log 完成 commit／PR。
- **關聯**：`D-20260925-project-numbered-text-options`, `D-20260825-project-prompt-bound-authority-recovery`, `M-20260825-project-guided-authority-recovery`

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
