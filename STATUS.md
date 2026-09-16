<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-16)

---

## 進行中

### B-20260807-gap-02

- **Context**：ready4quit 的 Q4c 在 2026-08-07 因 deferred tools 無法於隔離 subagent 取得而未能構造；
  現行 Claude Code、Codex 與雙 runtime ready4quit 已經演進，舊 provider／harness 前提可能失效。
- **Goal**：以現行工具模型與 `shared/skills/ready4quit/evals.md` v3 程序重驗 Q4c，分開判定 provider
  限制、eval harness 缺口與已淘汰前提；只修正仍具決策價值且會讓錯誤契約通過的可重現缺口。
- **Acceptance Criteria**：
  1. 以現行 Claude main session、general-purpose subagent 與 Codex runtime 實測 deferred tool 能力，拒絕
     allow-list／permission boundary 造成的假陰性。
  2. 在隔離 clean fixture 執行 Claude Q4c 與 Codex 能力邊界 control，核對 verdict 與證據語彙。
  3. 只有仍具決策價值、可重現且會讓錯誤契約通過的 harness 缺口才先取得 RED 並做最小修正。
  4. 若現行工具模型已改變或 Q4c 不再需要舊 deferred-tool 前提，更新 eval oracle、移除 backlog 並記錄
     結案 milestone，不新增多餘 production 行為。
  5. 通過 ready4quit validator、doc-governance ship audit、`git diff --check` 與完整 `./tests/run.sh`。
- **Constraints**：behavior eval 是 oracle；不因舊候選直接修改 provider adapter 或 production workflow；
  不把 Codex 未提供的 schedule listing 假裝成可驗證，也不把 Claude permission denial 當 provider 限制。
- **Progress**：現行能力與隔離行為已完成重驗；Claude Q4c 為 GREEN，Codex 依能力邊界正確回報 PARTIAL；
  無 production 行為缺口，完整 suite 為 `PASS=1420 FAIL=0`，待完成 lifecycle commits 與送出。
- **Next step**：提交 active contract 作為 durable parent evidence，再以結案 commit 原子移除本項、移除
  backlog、追加 milestone 並更新 ready4quit eval oracle。
- **Writer**：`codex:gap-02-deferred-tools`
- **Workspace**：`branch=docs/gap-02-deferred-tools`
- **Write Scope**：`shared/skills/ready4quit/evals.md`、`docs/backlog.md`、
  `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:gap-02-deferred-tools`
- **Related IDs**：`B-20260807-gap-02`、`M-20260823-portable-ready4quit-skill`、
  `D-20260825-portable-skill-authoring-default`

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
