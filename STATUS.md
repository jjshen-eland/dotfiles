<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-29)

---

## 進行中

### W-20260929-wait4me-macos-ci-readiness

- **Context**：PR #243 的 Ubuntu required suite、本機 serial 與本機 parallel 均全綠，但 macOS 15 required suite
  在同一 head 連續兩次無法啟動 wait4me fake NC HTTP server；第一次 1/3 失敗，重跑 3/3 失敗，現有 stderr
  在 child wait 前讀取而為空，尚無法區分 process exit、signal 或 readiness timeout。
- **Goal**：以可反駁的 child lifecycle evidence 確認 macOS-only failure 的第一個 causal divergence，做最小修復，
  讓 PR #243 的 required checks 在 exact head 全綠後完成 merge。
- **Acceptance Criteria**：先保留原 CI failure 並讓 readiness failure 回報 child exit／signal／timeout；因果來源有
  control evidence；最小修復使本機 serial／parallel、Ubuntu 24.04 與 macOS 15 suites 全綠；不得以 retry、bypass
  或放寬 required checks 冒充修復；PR #243 合併後本地 main 同步並清除 branch。
- **Constraints**：前輪兩個 CI repair commits 已用完；使用者已授權新的 systemic-diagnosis round，最多兩個新的
  CI-facing commits：第一顆只加入能區分 process／shared-state 假設的 bounded diagnostics，第二顆僅在 root cause
  confirmed 後做單一 causal repair。該 repair 已讓 macOS required suite 轉綠；使用者另授權一顆窄修復 commit，只處理
  已證實的 review fixture Git maintenance race。不修改 production sender／hook contract；不 bypass checks、不改
  protection、不直推 default。
- **Progress**：使用者授權重開 systemic diagnosis 後，root-cause terminal state 為 `ROOT CAUSE CONFIRMED`。
  Diagnostic CI 曾證明兩個失敗的 Python
  child 在固定 10 秒 readiness budget 後仍存活、wait status 為 143（由診斷清理送出 TERM）、stderr 為空；但把
  window 改為 30 秒並降低輪詢頻率後，macOS CI 的三個 child 仍全數以相同 evidence 失敗，已反證「只是 10 秒太短」
  的 causal model。同一 macOS job 另重現 review fixture 的 Git `maintenance.lock` metadata 漂移；Ubuntu required
  suite 與本機 parallel suite `1536 PASS／0 FAIL`。舊 head 第三次 macOS CI 仍以相同四個 failures 重現。新 diagnostic
  candidate 會在 timeout 前擷取 child command／state／CPU time／wait channel／system process count，並以 bounded markers
  區分 interpreter、import、bind、port write 階段；review fixture 改回報 exact added／removed／changed paths，未改 pass／
  fail 判準。本機 integration shard `1132 PASS／0 FAIL`。macOS diagnostic head 顯示三個 child 均已完成 interpreter 與
  imports；前兩個停在 `HTTPServer(...)` constructor 內 30 秒且 CPU time 僅 0.06–0.11 秒，第三個在 deadline 附近完成
  bind／port write。CPython 3.14 的 `HTTPServer.server_bind()` 在 TCP bind 後執行 fixture 不需要的
  `socket.getfqdn(host)`；這是 constructor path 中唯一會等待外部 name-service state、且符合 sleeping child、低 CPU、
  intermittent completion 與 OS-specific control 的 causal divergence。Fixture subclass 跳過該 lookup 後，macOS
  required suite 由連續失敗轉為 `PASS`（2m14s），確認 wait4me root cause 與 repair。相同 exact head 的 Ubuntu 唯一
  failure 精確顯示 snapshot 前存在、capture 後消失的 `.git/objects/maintenance.lock`；Git 的 `maintenance.auto` 預設
  會 detached background maintenance，故 assertion 量到的是 fixture 自己尚未收斂的 transient state，不是 review mutation。
- **Next step**：在 review fixture 寫入任何 Git objects 前，局部設定 `maintenance.auto=false` 與 `gc.auto=0`，保留完整
  metadata assertion；跑本機完整 parallel suite後提交唯一獲授權的額外修復，再以 Ubuntu／macOS exact-head CI 驗證。
- **Writer**：codex:wait4me-fleet-rollout
- **Workspace**：branch=docs/wait4me-fleet-rollout
- **Write Scope**：STATUS.md, tests/run.sh, tests/run-parallel.sh, tests/review-readonly.py,
  docs/archive/milestones-2026-09.md
- **Dossier Steward**：codex:wait4me-fleet-rollout
- **關聯**：PR#243;M-20260929-wait4me-fleet-rollout;M-20260929-wait4me-nc-wire-repair;D-20260929-wait4me-nc-wire-contract

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
