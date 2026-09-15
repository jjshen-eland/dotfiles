<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260820-debt-25：重驗 doc-governance Round 2 非阻斷後續 ⏳

- **Writer**：`codex:reassess-b25-doc-governance-round2`
- **Workspace**：`branch=docs/reassess-b25-doc-governance-round2`
- **Write Scope**：`STATUS.md`, `.doc-governance.json`, `scripts/doc-governance.py`, `tests/run.sh`, `tests/fixtures/doc-governance/**`, `docs/document-governance.md`, `docs/testing-contract.md`, `docs/backlog.md`, `docs/archive/decisions-2026-09.md`, `docs/archive/dead-ends-2026-09.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:reassess-b25-doc-governance-round2`
- **Context**：B25 是 2026-08-20 pilot 後留下的五項非阻斷候選：`supersedes` 反向邊的搜尋呈現、glob class 的 `requires_inbound` 語意、`mode: governance` 去留、worktree trusted-core mismatch 操作指引，以及 canonical-title 檢索測試的成長成本。後續 Round、rollout 與 2026-09-07 trusted-core 事故已大幅改變現行實作與文件，不能把舊清單直接當成今日待寫功能。
- **Goal**：以現行 scanner、config、human guide、regression gate 與可重現成本，將五項分別判定為已解決、已淘汰或仍有影響行為的缺口；只對最後一類進行最小修正。
- **Acceptance Criteria**：逐項完成可重現盤點：（1）對有 `supersedes:<ID>` 的當代 fixture 分別查新、舊 ID，確認反向關係是否會影響使用者找到現行結論；（2）對照 `requires_inbound` 的文件定義、parser／audit 行為與正反 fixture，判定舊的未定語意是否已關閉；（3）查明 `mode: governance` 是現行可用模式、歷史候選或已無 consumer，不為已退役設計補實作；（4）在 linked worktree 重現 trusted-core match／mismatch 路徑，驗證現行訊息或指引能否給出正確處置，且不重蹈 `X-20260907-stale-core-scan-false-baseline`；（5）量測 canonical-title 檢索 regression fixture 的現行規模、新增一案所需重複與執行成本，只有存在可觀察維護或時間問題才改寫。任一仍有效的缺口必須先有失敗的最小 regression fixture，再做最小修正並取得 GREEN；五項若均已解決或不再具決策價值，不改 scanner／gate，移除 B25 並記錄結案 milestone。
- **Constraints**：behavior 與 deterministic regression gate 是 oracle；不把「現在有相關文字」當成行為已解決，也不把一個 aggregate B25 當成五項都要做的批次。不回寫已歸檔紀錄；新決策、死路與 milestone 依事件日期另寫。不調整與五項無關的 ranking、rollout 或 governance budget。若實證指向 repo-local Project skill surface 需修改，先停下重新界定 write scope，並在實作前完整執行 system `$skill-creator`、`codex/skill-building-guide.md` 與 `docs/skill-portability.md` preflight。
- **進度**：已建立 feature branch，準備逐項重驗五個 Round 2 非阻斷候選。
- **下一步**：執行現行實作、文件與 regression gate 的重現盤點；只有 observed behavior gap 才先取得 RED。
- **關聯**：`B-20260820-debt-25`, `M-20260820-doc-governance-pilot`, `D-20260822-rollout-gate-replacement`, `X-20260907-stale-core-scan-false-baseline`, `X-20260907-unreadable-tool-exclusion-argument`

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
