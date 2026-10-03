<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-04)

---

## 進行中

### project-test-evidence-reuse — 收尾沿用有效測試證據

- **Writer**: codex:project-test-evidence-reuse
- **Workspace**: branch=fix/project-test-evidence-reuse
- **Write Scope**: shared/skills/project/references/log-workflow.md, shared/skills/project/references/pressure-tests.md, shared/skills/project/scripts/test-evidence.py, claude/skills/project/scripts/test-evidence.py, tests/project-reference-eval.py, tests/project-test-evidence-test.py, tests/run.sh, tests/shard-manifest.tsv, docs/testing-contract.md
- **Dossier Steward**: codex:project-test-evidence-reuse
- **Context**: 使用者回報實作已全綠、程式與測試未變，紧接 Project merge 仍常重跑全套。PR #259 前本 agent 曾安排未受觸發的 clean-clone 全套，經使用者插問才取消；當前 shared Log 沒有明確的本機測試證據沿用步驟。既有 kernel 只要求混檔拆分後 clean clone，不要求每次 shipping 全套重驗。
- **Goal**: 兩端 Log 沿用可查證且仍適用的結果，按實際變更補驗；不靠使用者提醒，不以新 receipt／cache 制度製造額外負擔。
- **Acceptance Criteria**:
  1. 已有命令、exit、coverage／tested inputs 與可核對輸出的成功結果，在輸入與相關環境不變時沿用；commit／branch／stage／session 改變本身不使測試失效，dirty/untracked 實際內容亦需覆蓋。
  2. 原紀錄可來自当前對話的工具 trace 或既有 repo／CI evidence；不強制新格式。程式／測試／設定／依賴／fixture 或已知環境改變、失敗／未知證據時補最小受影響檢查；不能以「程式沒改」掩蓋其他測試輸入改變。
  3. 結案文件只觸發受影響 docs checks；保留 target repo 更嚴契約、混檔拆分的 clean-clone 驗證與必要 CI／fresh shipping gates，不以本機結果取代 provider checks。
  4. 以實際 command trace 驗收兩端 normal reuse 與 changed/missing evidence controls；只測固定小矩陣，不追加 prose 審查。共享語意只改一份，現有 topology／metadata／endpoint 授權不變。
- **Constraints**: 本次授權改善 skill 及必要驗證，未授權 commit／push／PR／merge／部署；不沿用 #259 endpoint。沿用必讀 references（當前 context 已完整載入且 hashes 不變），不重做 portable migration，不建立通用測試快取或新 dossier store。
- **進度**: 本機實作與驗收完成。共同 Log 已接唯讀 helper，13 個機械 tests 在 Python 3.14／3.9 通過。新六次 native 均實際執行 helper：unchanged 雙端零重跑，changed／unknown 各補一次；四份 EOF、HEAD／working tree／origin 均驗過，前次摘要冒充證據的失敗已修正。完整 source／trace 與恢復細節見 Scenario 38；沒有永久 cache 或新 dossier store。Codex validator、portable linkage、doc audit 通過；合併 output 相容性補正後完整 parallel suite exit 0、1567／0（`/tmp/project-test-reuse-mechanical-final-suite-20261004.log`），有效 native 結果未重跑。
- **下一步**: 待使用者明確指定 commit／shipping endpoint；目前未 commit／push。收尾沿用已驗結果，僅按實際後續變更補驗。另已只讀量測 20 個入口及十種行為的必讀載入量，Project Log 約 1,400 行；後續若精簡，以相同 behavior oracle 驗分流／下沉，不全面刪字或重做無關審查。
- **關聯**: D-20261003-project-test-evidence-reuse;D-20260822-portable-project-skill;D-20261003-deep-plan-runner-python-compat

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

- 決策：`docs/archive/decisions-2026-10.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-10.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
