<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-17)

---

## 進行中

### B-20260820-gap-08-ci-portability-fix

- **Context**：PR #222 的兩個 required contexts 都在 `Run complete suite` fail closed。Ubuntu 的 Project
  credential helper 因 GNU `stat -f` stdout 污染 fallback 結果而回 `mode-malformed`，integration 為
  `PASS=1053 FAIL=4`；macOS 行為 assertions `PASS=1057 FAIL=0`，但 shard manifest 仍期待 1049。
- **Goal**：以 deterministic GNU-stat RED 固定第一因果差異，將 mode probe 改回已驗證的 GNU `-c` 優先、BSD
  `-f` fallback，並同步 integration assertion manifest；不改 transfer policy 或放寬 fail-closed gate。
- **Acceptance Criteria**：
  1. 修正前新增的 GNU-stat fixture 穩定重現 helper exit 2／`mode-malformed`，不依賴 Linux runner。
  2. 最小修正後，同 fixture 對 0644 artifact 回 STOP、既有 macOS／Linux semantics 與 secret-output isolation 不變。
  3. `tests/shard-manifest.tsv` 精確反映新的 integration assertion count；serial、parallel、clean clone、skill
     validation、ShellCheck 與 doc audit 全綠。
  4. 另記 milestone supersede PR #222 初次 CI 結論；B08 backlog 仍保留給 biz-chat-targeted remediation。
- **Constraints**：一次只改一個已確認因果來源；不 retry/bypass required checks；不讀取或輸出 credential value；
  不改雙 runtime topology。修正只 commit 在目前 feature branch，沒有新的 push／merge 授權。
- **Progress**：已保存 PR #222／run 35205077128 兩端 failed logs。History 命中
  `M-20260815-linux-stat-fix`，確認相同 GNU `stat -f` stdout contamination 機制；portable topology 與 steward
  authority 已重驗通過。Deterministic GNU-stat fixture 取得 integration `PASS=1057 FAIL=1` RED；最小修正後
  integration `PASS=1058 FAIL=0`，parallel、serial 與 clean no-local clone 均為 `PASS=1462 FAIL=0`，syntax、
  ShellCheck 與 Codex Project skill validator 全綠。
- **Next step**：記錄 superseding milestone、移除本 active item，完成 doc audit 後 commit closure。
- **Writer**：`codex:gap-08-biz-chat-transfer`
- **Workspace**：`branch=docs/gap-08-biz-chat-transfer`
- **Write Scope**：`STATUS.md`、`docs/archive/milestones-2026-09.md`、
  `shared/skills/project/scripts/verify-transfer-credential.sh`、`tests/run.sh`、`tests/shard-manifest.tsv`
- **Dossier Steward**：`codex:gap-08-biz-chat-transfer`
- **Related IDs**：`B-20260820-gap-08`、`M-20260815-linux-stat-fix`、
  `M-20260917-gap-08-dotfiles-transfer-guard`、`PR#222`、`run:35205077128`

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
