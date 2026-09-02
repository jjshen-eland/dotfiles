<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-02)

---

## 進行中

### Claude Code／Codex turn-end 時間戳

- Context: 工作回合結束後缺少明確的等待起點，無法直接判斷操作者已 idle 多久。
- Goal: Claude Code 與 Codex 的主 agent 每回合結束、開始等待輸入時，顯示當下 GMT+8 日期時間。
- Acceptance Criteria:
  - Claude Code 與 Codex 都只在主 agent 的 Stop lifecycle 顯示時間戳。
  - 顯示格式固定包含 `YYYY-MM-DD HH:MM:SS GMT+8`，不受主機時區影響。
  - hook 輸入不外洩，日期指令失敗時安靜退場且不阻擋 agent。
  - 自動測試覆蓋輸出、時區、失敗模式與兩套 runtime wiring。
- Constraints: 共用單一腳本；保留 live Codex config 的使用者本機差異；Codex 新 hook 仍須由使用者透過 `/hooks` 信任。
- **Writer**: codex:turn-end-timestamps
- **Workspace**: branch=feat/turn-end-timestamps
- **Write Scope**: STATUS.md, claude/settings.json, codex/config.toml, docs/archive/milestones-2026-09.md, scripts/agent-turn-end-timestamp.sh, tests/run.sh
- **Dossier Steward**: codex:turn-end-timestamps
- 進度: 實作與測試完成，正在重建為可驗證的 lifecycle commit sequence。
- 下一步: 完成候選重建、驗證 tree equivalence 與 shipping gates。
- 關聯: none

---

## 暫停中

（目前無暫停中項目。）

## 歷史入口

- 決策：`docs/archive/decisions-2026-09.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-08.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-09.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
