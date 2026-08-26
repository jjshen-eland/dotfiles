<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-08-26)

---

## 進行中

### project 空 repo bootstrap default（#153）

- **Writer**：`codex:project-bootstrap-default`
- **Workspace**：`branch=fix/project-bootstrap-default`
- **Write Scope**：`STATUS.md`、`claude/skills/project/scripts/ship-state.sh`、`claude/skills/project/scripts/bootstrap-baseline.sh`、`claude/skills/project/references/`、`tests/run.sh`、`docs/archive/milestones-2026-08.md`
- **Dossier Steward**：`codex:project-bootstrap-default`
- **Context**：空 remote 的 bootstrap 目前直接推目前 branch；HEAD 在 feature 且本地無 intended-default 時會把 feature 名設成 GitHub default。
- **Goal**：以 provider-agnostic evidence 解析 intended default 與 creation policy，缺 baseline 時用確認型 UX 取得明示 boundary，bootstrap 後再重新偵測一般 ship 狀態。
- **Acceptance Criteria**：feature HEAD 不再取得 bootstrap push 指令；main／非 main、ruleset 無／有／不可見、creation check deadlock、首次 `--merge` 與雙 runtime eval 皆 fail closed 或走安全 baseline；validator／audit／完整 tests 全綠。
- **Constraints**：不硬編碼 org、ruleset、property 或 check 名；不猜 baseline commit、不繞過 required checks、不無界等待、不改 portable topology。
- **進度**：實作與驗證完成；regression RED 已轉綠，1242 tests、雙 runtime packaging、三臂 fresh-context forward 與 elandcomtw read-only probe 均通過。
- **下一步**：使用者明確叫用 Project Log 後，提交本批、同步 milestone 並依指定 endpoint ship；進 `origin/main` 後關閉 #153。
- **關聯**：GitHub #153；`D-20260825-portable-skill-authoring-default`；2026-07-22 bootstrap milestone。

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
