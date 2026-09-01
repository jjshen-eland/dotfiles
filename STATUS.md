<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-01)

---

## 進行中

### Container network collision safety

- **Writer**: `codex:container-network-collision-safety`
- **Workspace**: `branch=fix/container-network-collision-safety`
- **Write Scope**: `AGENTS.md`, `claude/CLAUDE.md`, `codex/AGENTS.md`, `claude/evals/contract-evals.md`, `tests/kernel-gate.py`, `tests/run.sh`, `STATUS.md`, `docs/archive/decisions-2026-09.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**: `codex:container-network-collision-safety`
- **Success Criteria**: Claude Code 與 Codex 都在 first attach 前拒絕與 host／LAN／VPN／production routes 重疊的 container CIDR；不得複製 production IP/CIDR；OrbStack cleanup 必須驗 isolation table；三份 kernel、G13、完整 tests 與 doc audit 全綠。

---

## 暫停中

（目前無暫停中項目。）

## 歷史入口

- 決策：`docs/archive/decisions-2026-08.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-08.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-08.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
