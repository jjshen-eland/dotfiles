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
- **Constraints**：本輪最多兩個 CI repair commits；只處理 wait4me fake-server test harness 的已證實原因，不修改
  production sender／hook contract；不 bypass checks、不改 protection、不直推 default。
- **Progress**：root-cause terminal state 為 `ROOT CAUSE CONFIRMED`；diagnostic CI 證明兩個失敗的 Python child
  在固定 10 秒 readiness budget 後仍存活、wait status 為 143（由診斷清理送出 TERM）、stderr 為空，較晚啟動的
  第三個同類 server 則成功。第一個 causal divergence 是高負載 macOS parallel runner 的排程延遲超過測試夾具的
  固定 10 秒上限，不是 production sender／hook contract；最小修復保留 child-liveness gate，改用較少輪詢程序的
  bounded 30 秒 startup window。
- **Next step**：跑本機 CI-equivalent parallel suite，提交第二個也是最後一個 CI repair commit，送同一 PR 驗證
  Ubuntu 24.04 與 macOS 15 required suites。
- **Writer**：codex:wait4me-fleet-rollout
- **Workspace**：branch=docs/wait4me-fleet-rollout
- **Write Scope**：STATUS.md, tests/run.sh, docs/archive/milestones-2026-09.md
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
