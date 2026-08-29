<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-08-30)

---

## 進行中

### W-20260830-codex-trusted-approval-flow

- **Writer**: `codex:codex-trusted-approval-flow`
- **Workspace**: `branch=chore/codex-trusted-approval-flow`
- **Write Scope**: `STATUS.md`, `codex/AGENTS.md`, `claude/evals/README.md`,
  `claude/evals/contract-evals.md`, `claude/evals/setup-sandboxes.sh`,
  `claude/skills/handoff/evals.md`, `claude/skills/handoff/references/workflow.md`,
  `docs/archive/dead-ends-2026-08.md`, `docs/archive/decisions-2026-08.md`,
  `docs/archive/milestones-2026-08.md`
- **Dossier Steward**: `codex:codex-trusted-approval-flow`
- **Context**: Codex approval UI 久候時曾被読成操作失敗而重送；handoff resume 也缺少一個可完成、
  不逐步重問且不延續舊 session 授權的替代流程。
- **Goal**: trusted repo 使用 local never-approval 設定；always-on guidance 固定 pending lifecycle；
  handoff resume 在 verify／reconcile 後只取得一次 session-bounded batch authorization。
- **Acceptance Criteria**:
  1. G12 與 H15 behavior eval 分別重現 duplicate pending request 與 consume-before-consent 的 RED。
  2. 修後 H15 第一段零 repo／artifact mutation，第二段只在明確同意後 consume 並執行 exact scope。
  3. Claude／Codex validator、shellcheck、doc-governance ship audit 與完整 `./tests/run.sh` 全綠。
- **Constraints**: project-local `approval_policy = "never"` 不進產品 repo 版控；bounded batch 永不涵蓋
  push、PR、merge、deploy、delete、credentials／grants、traffic、destructive Git 或 scope expansion。
- **Progress**: 實作與 behavior eval 已完成，完整測試 `PASS=1242 FAIL=0`；待以 Project Log 完成 commit／PR／merge。
- **Next Step**: 由 current steward 重建 candidate commit，重跑 authority／doc audit 後依明示 `--merge` 送出。
- **關聯**: D-20260830-codex-trusted-approval-flow;X-20260830-handoff-resume-unbounded;
  M-20260830-codex-trusted-approval-flow

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
