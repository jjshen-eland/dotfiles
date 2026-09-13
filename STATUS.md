<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-14)

---

## 進行中

### Identity fleet 結案與 dotfiles remote migration helper 退役 ⏳

- **Writer**：`codex:retire-dotfiles-remote-migration`
- **Workspace**：`branch=chore/retire-dotfiles-remote-migration`
- **Write Scope**：`STATUS.md`, `docs/backlog.md`, `docs/archive/decisions-2026-09.md`, `docs/archive/milestones-2026-09.md`, `scripts/brewup.sh`, `scripts/dotfiles-sync.sh`, `scripts/ensure-dotfiles-remote.sh`, `tests/run.sh`
- **Dossier Steward**：`codex:retire-dotfiles-remote-migration`
- **Context**：inventory 14 台與家用 Mac 已完成 identity 收斂；公司 MacBook 已明示不再阻塞 rollout。一次性 dotfiles remote migration helper 的全機隊移除條件因此成立。
- **Goal**：關閉 identity fleet blocker，記錄公司 Mac 的非阻斷邊界，並移除已完成使命的 remote migration helper 與三個常態呼叫點。
- **Acceptance Criteria**：identity backlog item 有 decision／milestone 並移除；B-20260815-debt-09 有 milestone 並移除；helper 與 steady-state 引用不存在；既有 warning 聚合和 dotsync 逐目標終判不變；完整 suite 全綠。
- **Constraints**：不喚醒或遠端修改公司 MacBook；保留 B10 已進 main 的 dossier 狀態；不降低現有同步錯誤可見性。
- **進度**：實作與驗證已在尚未送出的 candidate `fe0ec5e` 完成；正依 prompt-bound authority recovery 在最新 main 上受控重建。
- **下一步**：提交本 active contract，重建 completion candidate，重驗後依 `$project --merge` 送出。
- **關聯**：`B-20260902-identity-fleet-rollout`, `B-20260815-debt-09`, `D-20260913-company-mac-nonblocking-identity-rollout`

---

## 暫停中

（目前無暫停中項目。）

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
