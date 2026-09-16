<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-16)

---

## 進行中

### deep-plan-timeout-cleanup-flake

- **Context**：PR #207 的 required macOS check 在 deep-plan timeout cleanup case 以
  `PASS=1419 FAIL=1` 失敗，Ubuntu 通過；相同 SHA 的本地完整 suite 與前一個 macOS control 均為
  `PASS=1420 FAIL=0`。現有單一失敗訊息同時涵蓋 `rc`、failure manifest、PID 檔案數量與 live
  descendants，尚不能把失敗歸因到其中任一條件。
- **Goal**：先建立可區分四項觀測值的 diagnostic RED，確認第一個因果差異，再做最小修正；不得把目前的
  readiness／timing race 假說當成已確認根因。
- **Acceptance Criteria**：
  1. timeout failure output 可獨立顯示 `rc`、manifest 是否存在、`pid_count`，以及 live descendants 的
     count／state（或等價且精確的 observable evidence）。
  2. 取得可重現的 RED，並以正常 control 證明是哪一項條件最先偏離預期。
  3. 最小修正直接消除已證實成因，不以 blanket retry、全面增加 timeout 或放寬 cleanup 判準代替修正。
  4. macOS 上 targeted timeout／signal cleanup tests 重複通過，本地完整 `./tests/run.sh` 通過，PR #207
     required macOS 與 Ubuntu checks 均通過。
  5. required checks 全綠前不 merge PR #207。
- **Constraints**：遵守 root-cause-first，先保存 RED evidence 再修；retry 不是修正；維持 process-tree cleanup
  fail-closed 與跨平台契約；除非證據要求推翻既有決策，不改 portable deep-plan topology；本次 Spec 僅寫
  active contract，不改程式或測試。
- **Progress**：既有 timeout assertion 已補 diagnostics-only 輸出，可分辨 `rc`、manifest、`pid_count`、
  live descendants 與 process states；Bash syntax、ShellCheck、完整 suite `PASS=1420 FAIL=0` 均通過。
  相同 production launcher／hanging fixture 在本機序列重播 40 次、並行壓力重播 100 次皆為
  `rc=1 / manifest=1 / pid_count=2 / live=0`。PR #207 舊 log 只有合併後的 assertion 訊息，無法回推第一個
  divergent conjunct，故根因維持 `UNCONFIRMED`，production launcher 尚未修改。
- **Next step**：先讓 diagnostics-only 變更跑 PR #207 required macOS check；只有新 RED 指出第一個
  divergent conjunct 後，才做單一最小修正並重跑 targeted、完整 suite 與雙 OS required checks。
- **Writer**：`codex:pending-gh-account-autoswitch`
- **Workspace**：`branch=docs/pending-gh-account-autoswitch`
- **Write Scope**：`tests/run.sh`、`tests/fixtures/deep-plan-hanging-stub.py`、
  `codex/skills/deep-plan/scripts/launch-reviewers.py`、`shared/skills/deep-plan/evals.md`、
  `docs/testing-contract.md`
- **Dossier Steward**：`codex:pending-gh-account-autoswitch`
- **Related IDs**：`D-20260825-deep-plan-empty-wait`、`M-20260825-portable-deep-plan-revalidation`、
  `X-20260825-deep-plan-duplicate-port`、`M-20260915-b07-timeout-zombie-oracle-fixed`、
  `M-20260916-deep-plan-signal-pid-race-oracle-fixed`、PR #207

---

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。

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
