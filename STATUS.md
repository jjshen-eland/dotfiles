<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-08-26)

---

## 進行中

### Project Spec shipping invocation 提示 ⟳

- **Writer**：codex:project-spec-shipping-hints
- **Workspace**：branch=fix/project-spec-shipping-hints
- **Write Scope**：STATUS.md, claude/skills/project/references/pressure-tests.md, claude/skills/project/references/workflow.md, docs/archive/milestones-2026-08.md, tests/run.sh
- **Dossier Steward**：codex:project-spec-shipping-hints
- **Context**：Project Spec 成功後只顯示含 `resume=` 的 Log invocation，使用者難以分辨 short-form 合法性、endpoint authorization 與 durable workline binding。
- **Goal**：讓 Claude／Codex Project adapter 在 helper 精確證明 branch／workspace actor 時同列短版與明確版，其他 authority 形狀維持 fail closed。
- **Acceptance Criteria**：Scenario 27 與 blocking gate 覆蓋雙 runtime sigil、舊授權不 carry、BROKEN／無 recovery／scope mismatch 不繞過；skill validator、doc audit 與全 repo tests 通過。
- **Constraints**：維持 portable shared core；提示本身不授權 shipping；不放寬既有 recovery 或 STOP。
- **進度**：實作與驗證完成，正在以受控 history rebuild 建立可驗證的 steward-authored completion candidate。
- **下一步**：提交本 active contract，重建 completion commit，重驗 authority 後繼續本輪 `$project --merge`。
- **關聯**：GitHub #148;D-20260824-project-steward-authority;D-20260825-project-prompt-bound-authority-recovery

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
