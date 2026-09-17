<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-17)

---

## 進行中

### PR222-ci-and-issue-219-followups

- **Context**：PR #222 run `35210169602` 的 Ubuntu required check 通過，但 macOS signal fixture 在 descendants
  已清乾淨時仍回 launcher `rc=2`／非 canonical manifest；另有 ais-infra PR #70 實證 gh 2.101.0 的
  `no required checks reported ...` 未被 enrollment helper 分類，對應既有 open Issue #219。
- **Goal**：分別取得 deterministic RED，修正 deep-plan signal cleanup 的重入／單一終態問題，以及 Project
  enrollment helper 對 GitHub CLI 兩種官方 empty-required-check 訊息的精確相容性；不放寬未知 exit 1。
- **Acceptance Criteria**：
  1. macOS failure fixture 能穩定區分 cleanup 結果、launcher rc 與 manifest；signal 路徑只 cleanup 一次，
     回 canonical `ok:false` manifest／exit 1，且 descendants 全數消失。
  2. Issue #219 fixture 在修正前對 `no required checks reported ...` 取得 QUERY_ERROR RED；修正後新舊官方訊息
     都進入 exact-head run lifecycle，含單引號的合法 branch 可解析，其他未知／transport 輸出仍 QUERY_ERROR。
  3. 現有 watch、final non-watch、fresh merge-state、head-change、RUN_TERMINAL 與明示 `--merge` approval UI=0
     契約不變；shard manifest 精確同步。
  4. 受影響 shards、parallel、serial、clean clone、syntax、ShellCheck、skill validators 與 doc audit 全綠；
     記錄 milestone，Issue #219 僅在修正進入 main 後結案。
- **Constraints**：一次只改一個已證實原因；不把所有 exit 1 當 pending；不 retry／bypass failing CI；不改
  deep-plan reviewer semantics 或 Project authorization；本輪沒有新的 push／merge 授權。
- **Progress**：PR #222 macOS failure 只在 signal 路徑回 `rc=2`；deterministic wait guard 證實 signal handler
  cleanup 後共用 exception path 又 cleanup 一次。最小修正讓 handler 只提出中止、由共用路徑清理一次。
  Issue #219 與 ais-infra PR #70 證據吻合；新版 gh exact empty-required 字串（含合法單引號 branch）已進入原
  lifecycle，未知 exit 1 仍 `QUERY_ERROR`。兩組 RED 修後 integration 為 `PASS=1063 FAIL=0`。
- **Next step**：完成 syntax、ShellCheck、skill validators、parallel／serial／clean-clone 與 doc audit，記錄
  milestone 並本地 commit；本輪沒有 push 授權。
- **Writer**：`codex:gap-08-biz-chat-transfer`
- **Workspace**：`branch=docs/gap-08-biz-chat-transfer`
- **Write Scope**：`STATUS.md`、`docs/archive/milestones-2026-09.md`、
  `codex/skills/deep-plan/scripts/launch-reviewers.py`、`tests/fixtures/deep-plan-wait-guard/sitecustomize.py`、
  `claude/evals/setup-sandboxes.sh`、`shared/skills/project/scripts/wait-required-enrollment.sh`、
  `shared/skills/project/references/pressure-tests.md`、`shared/skills/project/references/ship-paths.md`、
  `tests/run.sh`、`tests/shard-manifest.tsv`
- **Dossier Steward**：`codex:gap-08-biz-chat-transfer`
- **Related IDs**：`Issue#219`、`PR#222`、`run:35210169602`、`M-20260916-deep-plan-signal-pid-race-oracle-fixed`、
  `M-20260917-required-aggregation-enrollment`

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
