<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-17)

---

## 進行中

### B-20260820-gap-08

- **Context**：三機 metadata-only 盤點已重現 biz-chat 移交路徑與 credential artifact 權限漂移；本 workline
  只修 dotfiles 的通用 Project transfer guard，biz-chat repo-local remediation 另需該 repo authority。
- **Goal**：讓 Project transfer 對 repo-local credential artifact 只以 metadata 驗證 untracked、gitignored、
  非 symlink 與 private mode，不讀值、不輸出值、不自行改權限。
- **Acceptance Criteria**：先取得 0644 artifact 的 RED；最小修正 shared workflow、template、helper 與雙 runtime
  packaging；integration、完整 suite、clean clone 與 doc audit 全綠；B08 backlog 保留並寫明後續觸發條件。
- **Constraints**：不讀取、輸出、搬運或修改 secret values；外部 biz-chat 與三台機器維持 read-only；不把
  dotfiles guard 冒充 project-local remediation 或 rotation。
- **Progress**：已取得 integration `PASS=1050 FAIL=2` RED，修後 integration `PASS=1057 FAIL=0`；完整 suite 與
  clean no-local clone 均為 `PASS=1461 FAIL=0`，doc-governance 與 ShellCheck 通過。原 candidate 因 active contract
  未先進 Git history 而被 stewardship gate 擋下，現依 prompt-bound recovery 建立 durable parent 後受控重建。
- **Next step**：以已保存的 rescue candidate 重建 completion commit，驗 tree identity、authority、audit 與
  ship-state，之後沿用本輪明示 `$project --merge` 完成 PR、required checks 與 merge。
- **Writer**：`codex:gap-08-biz-chat-transfer`
- **Workspace**：`branch=docs/gap-08-biz-chat-transfer`
- **Write Scope**：`STATUS.md`、`docs/backlog.md`、`docs/archive/milestones-2026-09.md`、
  `shared/skills/project/references/workflow.md`、`shared/skills/project/references/pressure-tests.md`、
  `shared/skills/project/templates/transfer-guide-template.md`、
  `shared/skills/project/scripts/verify-transfer-credential.sh`、
  `claude/skills/project/scripts/verify-transfer-credential.sh`、`claude/evals/setup-sandboxes.sh`、`tests/run.sh`
- **Dossier Steward**：`codex:gap-08-biz-chat-transfer`
- **Related IDs**：`B-20260820-gap-08`、`shared/skills/project/references/pressure-tests.md:Scenario 10`

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
