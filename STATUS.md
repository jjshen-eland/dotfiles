<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260817-debt-07：修正 deep-plan timeout fixture 的 zombie 誤判 ⏳

- **Writer**：`codex:reassess-b07-deep-plan-eval-review`
- **Workspace**：`branch=test/reassess-b07-deep-plan-eval-review`
- **Write Scope**：`STATUS.md`, `docs/archive/milestones-2026-09.md`, `docs/testing-contract.md`, `tests/**`
- **Dossier Steward**：`codex:reassess-b07-deep-plan-eval-review`
- **Context**：B07 初次盤點與本機完整 suite 均未見 RED；shipping 時 required macOS job 唯一失敗於 deep-plan timeout process-tree fixture。該 job 約一秒即完成 launcher timeout，而測試隨即以 `kill -0` 判 descendant 存活；macOS 控制實驗證明已退出但尚未回收的 zombie 同時會讓 `kill -0` 成功並呈現 `ps state=Z`，故現行 oracle 會把不再持有 pipe 的退出程序誤判為 live descendant。
- **Goal**：讓 timeout／signal cleanup regression gate 量測仍可執行的 descendant，而不把已退出的 zombie 當成 process-tree leak。
- **Acceptance Criteria**：保留 launcher fail-closed、兩個 descendant PID 與零 live descendant 的原判準；以跨 macOS／Linux 可用的 process-state 判定排除 zombie，且仍把任何非-zombie PID 視為失敗；更新 B07 milestone 的現場 RED 與最小修正，通過完整 suite、doc-governance ship audit及 required macOS＋Ubuntu checks。
- **Constraints**：不放寬 production launcher cleanup 契約；不以 sleep 或 CI retry 掩蓋 race；只修 fixture oracle，不修改 deep-plan skill、eval 或 launcher；`claude/settings.json` 的未提交 runtime drift 不屬本項範圍。
- **進度**：已保存 required macOS job `34989144024` 的 `PASS=1418 FAIL=1` 與唯一失敗訊息；同版 Ubuntu、前序 macOS runs 及本機 macOS 完整 suite 通過；本機控制確認 `kill -0` 對 `Z` state 回傳成功，根因定位為 zombie 誤判。
- **下一步**：先提交重新開啟的 active contract，再最小修正 timeout／signal PID 判定並重跑完整驗證。
- **關聯**：`B-20260817-debt-07`, `M-20260915-b07-deep-plan-eval-review-reassessed`, `docs/testing-contract.md`, `tests/run.sh`

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
