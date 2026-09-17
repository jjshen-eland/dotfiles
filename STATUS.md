<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-18)

---

## 進行中

### deep-plan-timeout-cleanup-flake

- **Context**：PR #222 final head `d84877a` 的 required run `35246416742` 在 Ubuntu 24.04 通過，
  macOS 15 則唯一失敗於 timeout cleanup：`rc=2`、無 canonical `ok:false` manifest、兩個
  descendant PID 都已 `missing`。同一 run 的 SIGHUP 與 single-cleanup fixtures 皆通過，精確命中
  暫停項原訂的 `timeout diagnostics:` 恢復條件。
- **Goal**：找出 timeout 路徑在 descendants 已清除後仍以 rc 2 退出、無法輸出 canonical
  failure manifest 的第一因果差異，並做不改 reviewer／timeout 語意的最小修正。
- **Acceptance Criteria**：
  1. 先保留 run `35246416742` 的 exact RED，並讓 timeout failure diagnostics 可區分 raw launcher
     output、exception／cleanup phase、rc、manifest、PID count 與 live states；不以重跑同一 commit
     或接受機率綠取代根因證據。
  2. 用 deterministic RED 證明同一第一因果差異，再做單一最小修正；修後 timeout
     必須回 exit 1、canonical `ok:false`、恰好兩個 PID 且零 live descendants。
  3. SIGHUP、single-cleanup 與既有 process-tree contract 不得回歸；受影響壓力、integration、
     parallel／serial、no-local clean clone、ShellCheck、doc audit 全綠，且 PR required
     macOS＋Ubuntu 皆通過後才結案。
- **Constraints**：不放寬 rc／manifest／PID／liveness oracle；不把 rc 2 當可接受；不改
  reviewer 數量、timeout 政策或 signal semantics；不以 `--admin`、rerun failed job 或移除 macOS
  required check 繞過。
- **Progress**：remote RED 固定為 run `35246416742`：Ubuntu 1m16s 通過，macOS 2m17s
  失敗；`timeout diagnostics: rc=2 manifest=0 pid_count=2 live=0`，而 signal 相關兩項全綠。本機 120 次、
  12 路 timeout 壓測重現相同 rc 2，raw output 確認為 cleanup 的 `PermissionError: [Errno 1]
  Operation not permitted` 逃出內層 handler。新增 force-signal fault fixture 先取得 deterministic RED
  （rc 2、無 canonical manifest、零 live descendants），再把各 cleanup phase 的次級例外收進原 manifest
  後轉綠；修後同規模壓測 120/120 皆回 rc 1 canonical failure。完整 serial `PASS=1468 FAIL=0`
  （137s）、parallel `SHARD_AGGREGATE pass=1468 fail=0 shards=3`，以及 no-local clean clone
  `PASS=1468 FAIL=0`（135s）皆通過。
- **Next step**：依本輪 `$project --merge` 提交並推送候選；PR required macOS＋Ubuntu 皆通過後才結案。
- **Writer**：`codex:gap-08-biz-chat-transfer`
- **Workspace**：`branch=docs/gap-08-biz-chat-transfer`
- **Write Scope**：`STATUS.md`、`codex/skills/deep-plan/scripts/launch-reviewers.py`、
  `tests/fixtures/deep-plan-*`、`tests/run.sh`、`tests/shard-manifest.tsv`、
  `docs/archive/{decisions,dead-ends,milestones}-2026-09.md`
- **Dossier Steward**：`codex:gap-08-biz-chat-transfer`
- **Related IDs**：`PR#222`、`run:35246416742`、`M-20260917-deep-plan-signal-single-cleanup`、
  `M-20260918-pr222-macos-signal-fixture-synchronized`

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
