<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-17)

---

## 進行中

### PR222-macos-signal-readiness

- **Context**：PR #222 run `35243167732` 的 Ubuntu required job 通過；macOS signal fixture 回
  `rc=2`／無 canonical manifest，但兩個 descendant states 都是 `missing`。本機序列 50 次及八路並行
  400 次皆回 exit 1／`ok:false`，顯示 cleanup production path 已收乾淨，差異落在 fixture 送 signal 的時點。
- **Goal**：讓 signal fixture 只在兩個 reviewer stub 都已讀完 launcher 輸入後送 SIGHUP，移除以「descendant
  PID 檔已出現」代理 launcher readiness 的排程競態；保留 rc、manifest、pid count、live states 診斷。
- **Acceptance Criteria**：
  1. hanging stub 在建立 descendant／寫 PID 前先完整讀取 stdin；兩個 PID 因而證明 launcher 已完成兩個 prompt
     pipe 的 dispatch，不再允許 signal 落在未穩定的 startup 區段。
  2. signal fixture 仍要求 exit 1、canonical `ok:false`、恰好兩個 PID、零 live descendants；失敗時附 raw
     launcher output，不能用放寬 oracle 取得綠燈。
  3. 本機序列／並行壓力、integration shard、parallel／serial、clean clone、ShellCheck 與 doc audit 全綠；
     PR required macOS＋Ubuntu 重跑皆通過後才結案。
- **Constraints**：不改 reviewer／timeout 語意，不重跑同一失敗 commit，不把 rc=2 當可接受，不因 test flake
  放寬 required checks；一次只修 fixture readiness。
- **Progress**：remote RED 已保留為 run `35243167732`；本機控制組序列 50/50、八路並行 400/400 全綠。
- **Next step**：修 fixture readiness，重跑受影響範圍與完整驗證；取得新的 push 授權後更新 PR #222。
- **Writer**：`codex:gap-08-biz-chat-transfer`
- **Workspace**：`branch=docs/gap-08-biz-chat-transfer`
- **Write Scope**：`STATUS.md`、`tests/fixtures/deep-plan-hanging-stub.py`、`tests/run.sh`、
  `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:gap-08-biz-chat-transfer`
- **Related IDs**：`PR#222`、`run:35243167732`、`M-20260917-deep-plan-signal-single-cleanup`

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
