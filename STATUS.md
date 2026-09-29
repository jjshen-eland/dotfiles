<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-29)

---

## 進行中

### W-20260929-wait4me-session-notify

- **Writer**: `codex:wait4me`
- **Workspace**: `branch=feat/wait4me`
- **Write Scope**: `claude/settings.json`, `claude/skills/wait4me/`, `codex/config.toml`,
  `codex/skills/wait4me/`, `shared/skills/wait4me/`, `tests/run.sh`,
  `docs/archive/{decisions,milestones}-2026-09.md`, `STATUS.md`
- **Dossier Steward**: `codex:wait4me`
- **Goal**: 提供不持久、以 session lifecycle 為邊界的 `$wait4me` 通知開關。
- **Acceptance Criteria**: 啟用後在 approval 或 main agent 因需使用者回應而停下時發送
  bounded NC 通知；關閉、resume／clear／new／SessionEnd、普通完成、其他 session 與
  subagent 不發送；雙 runtime packaging、validators、doc audit 與完整測試通過。
- **Constraints**: 不傳 raw command／prompt／transcript／secret；通知 transport 失敗不得影響 agent
  lifecycle；狀態不持久且不成為 authority。
- **Progress**: 實作與本機驗收完成；正在建立可查證的 completion parent，尚未 push／開 PR／merge。
- **Next step**: 建立 direct-child completion commit，通過 `--completion-parent` gate 後送出。
- **關聯**: `D-20260929-wait4me-session-hook-boundary`,
  `M-20260929-wait4me-portable-session-notifications`, `shared/skills/wait4me/evals.md`

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
