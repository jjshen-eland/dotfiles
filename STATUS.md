<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260819-debt-01：重驗決策／死路的機械召回 ⏳

- **Writer**：`codex:reassess-b01-history-recall`
- **Workspace**：`branch=docs/reassess-b01-history-recall`
- **Write Scope**：`STATUS.md`, `.doc-governance.json`, `AGENTS.md`, `claude/settings.json`, `codex/config.toml`, `scripts/**`, `tests/**`, `claude/evals/**`, `docs/document-governance.md`, `docs/testing-contract.md`, `docs/backlog.md`, `docs/archive/decisions-2026-09.md`, `docs/archive/dead-ends-2026-09.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：`codex:reassess-b01-history-recall`
- **Context**：B01 的 2026-08 前提是 repo 只有靠人自覺觸發的歷史檢索，並預想以 PreToolUse deny＋路徑倒排索引阻止第一次工具呼叫；現行 repo 已有 `doc-governance.py find`、always-on 可執行路由、跨 runtime portable contract，以及分離的 Claude Auto／Codex outward-action 控制面。歷史 `X-20260825-deep-plan-duplicate-port` 證明曾發生「查得到，但開工前沒有觸發查詢」的 dispatch failure，仍需確認現行環境能否重現。
- **Goal**：以現行 Claude Code／Codex 的實際 always-on 與 hook 行為，分開重驗「相關歷史能否被 find 找到」及「agent 是否會在需要時主動觸發 find」；只為仍可重現、會導致錯誤實作或重走死路的 trigger miss 建立最小機械防線。
- **Acceptance Criteria**：選用不洩漏 stable ID／標題的真實歷史案例，固定目標 task、可觀察的首次查詢／工具行為與正確處置；先證明手動 `find` 可召回相關 record，再以 current Claude Code 與 Codex baseline 判定是否存在「未查即動手」且會改變結果的 observed miss；若有缺口，先取得可重跑 RED，並證明最小修正不增加 Claude Auto approval UI、不改寫 Project `--merge` 零重問契約、不中斷 Codex 既有 outward gate，且 Bash／非 Bash 寫入旁路有明確處置；若無現行 observed failure，或 history lookup 不會改變行為，則不新增 hook／index，移除 B01 並記錄結案 milestone；最終通過相關 behavior eval、deterministic gates、doc-governance ship audit 與完整 suite。
- **Constraints**：不直接沿用舊 PreToolUse deny＋倒排索引方案；先區分 retrieval miss、trigger miss 與單純缺少文字提示，不以更長 prose 冒充機械召回；不引入 embedding／本地向量庫，除非現行 lexical find 已被證明無法召回目標；不得新增 Claude outward approval prompt 或與 `D-20260912-cross-runtime-outward-gate`、`D-20260913-project-merge-authorization-ci` 衝突；`claude/settings.json` 現有未提交內容仍屬使用者指定的 runtime drift，不得覆寫或納入本 work item，若實作確實需要改同檔，先停止並重新核對 ownership／hunks。
- **進度**：已確認 adopted config＋scanner 完整、trusted core 相同，並由現行 `find` 定位 B01、`D-20260811-symmetric-rules-as-signal`、`X-20260825-deep-plan-duplicate-port`、`D-20260912-cross-runtime-outward-gate` 與 `D-20260913-project-merge-authorization-ci`；尚未執行 behavior baseline、取得 RED 或修改任何實作。
- **下一步**：盤點 tracked 與 live 可驗證的雙 runtime hook surface，從既有真實失敗建立不洩漏答案的最小 baseline，先判定目前是否仍會「未查歷史即動手」。
- **關聯**：`B-20260819-debt-01`, `D-20260811-symmetric-rules-as-signal`, `X-20260825-deep-plan-duplicate-port`, `D-20260912-cross-runtime-outward-gate`, `D-20260913-project-merge-authorization-ci`

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
