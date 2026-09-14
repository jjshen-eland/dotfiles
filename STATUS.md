<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260721-debt-21：確認 quick_validate.py 路徑修復並結清舊 finding ⏳

- **Writer**：`codex:close-b21-validator-path`
- **Workspace**：`branch=docs/close-b21-validator-path`
- **Write Scope**：`STATUS.md`, `codex/skill-building-guide.md`, `tests/run.sh`, `docs/testing-contract.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:close-b21-validator-path`
- **Context**：B21 來自 2026-07-21 Codex C2 finding F6：舊指令 `$skill-creator/scripts/quick_validate.py <skill-dir>` 依賴呼叫端 context。2026-08-24 commit `e2f1afec` 已改成以 `uv` 隔離 PyYAML、指向 `~/.codex/skills/.system/skill-creator/scripts/quick_validate.py`；目前 system validator 實體存在，`tests/run.sh` 也有 validator gate，但現有靜態斷言是否完整守住絕對路徑仍需驗證。
- **Goal**：以現行安裝與可執行 regression evidence 判定 F6 是否已完整解決；成立就只做 backlog／milestone 結案，不為已修好的行為新增實作。
- **Acceptance Criteria**：核對 B21 原始失效形狀與 `e2f1afec` 的修正邊界；從 repo root 與無關 CWD 各執行文件中的 validator command，兩者都須以 `uv` 隔離依賴、解析同一 system `quick_validate.py` 並成功驗證代表性 repo-local skill；以最小 mutant 證明 regression gate 會在絕對 validator 路徑退回 context-dependent 形式時變 RED，且正常版本為 GREEN；若上述證據已由現況滿足，不修改 guide／gate，直接寫 completion milestone、移除 B21 與 active item；若唯有 gate 未守住原 failure mode，只補能使該 mutant 變 RED 的最小斷言，不擴張其他 skill-authoring 規則；最終通過相關定向驗證、`./tests/run.sh`、`git diff --check` 與 doc-governance ship audit。
- **Constraints**：behavior／可執行證據優先於文字看似正確；不因 backlog 年代久遠就假設仍適用，也不因目前指令可跑就忽略防回歸缺口；不修改任何 repo-local skill；不安裝或污染 system Python；不改寫已歸檔的歷史紀錄。
- **進度**：已確認舊版確實使用 context-dependent `$skill-creator/scripts/quick_validate.py`，現版指令從 repo root 與無關 `/tmp` 各執行一次均成功；舊 gate 對路徑退化 mutant 假綠，最小斷言修正後 control 為 GREEN、同一 mutant 為 RED，完整 suite `PASS=1419 FAIL=0`。
- **下一步**：由 Project Log 寫 milestone、移除 B21／active item 並送出。
- **關聯**：`B-20260721-debt-21`, `M-20260824-memory-independent-transfer`, `e2f1afec`

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
