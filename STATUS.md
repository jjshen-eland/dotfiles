<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-08-26)

---

## 進行中

### Portable send-mail skill ⟳

- **Writer**：codex:portable-send-mail
- **Workspace**：branch=feat/portable-send-mail
- **Write Scope**：STATUS.md, claude/skills/send-mail/, codex/skills/send-mail/, docs/archive/decisions-2026-08.md, docs/archive/milestones-2026-08.md, docs/testing-contract.md, tests/run.sh
- **Dossier Steward**：codex:portable-send-mail
- **Context**：tracked tree 只有 Claude Code `send-mail` 入口與既有 eval，沒有 Codex entry、shared linkage 或 portable rollout record；本輪以 clean-room 黑箱規格重建雙 runtime skill。Shipping recovery 需讓 active contract 成為 semantic candidate 的可驗證 parent。
- **Goal**：建立 Claude Code／Codex 雙薄入口、單一 runtime-neutral send-mail behavior core 與 canonical eval oracle，讓兩端得到相同 recipient、sender、authorization 與 terminal semantics。
- **Acceptance Criteria**：雙 runtime hostile／boundary／sender-conflict eval 等價；shared resources 單一實體；fresh reviewer blockers closed；雙 validator、doc audit 與全 repo tests 全綠。
- **Constraints**：不寄 live email、不連線 relay、不使用 credentials；原 Claude skill 只由 clean-room subagent 閱讀；不把 confirmation 擴張到這顆未 push candidate 之外。
- **進度**：實作與行為驗證完成；正在重建 active-contract parent 後的 semantic completion commit。
- **下一步**：提交本 contract，重建完成 commit，重跑 authority／audit／tests，繼續本輪 `$project --merge`。
- **關聯**：D-20260826-portable-send-mail;M-20260826-portable-send-mail;D-20260825-portable-skill-authoring-default

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
