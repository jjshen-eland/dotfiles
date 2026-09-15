<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-15)

---

## 進行中

### B-20260819-debt-05：重驗 deep-plan 模型層級政策 ⏳

- **Writer**：`codex:reassess-b05-deep-plan-model-policy`
- **Workspace**：`branch=test/reassess-b05-deep-plan-model-policy`
- **Write Scope**：`STATUS.md`, `shared/skills/deep-plan/**`, `claude/skills/deep-plan/**`, `codex/skills/deep-plan/**`, `claude/evals/**`, `claude/skill-building-guide.md`, `codex/skill-building-guide.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`, `docs/testing-contract.md`, `tests/**`
- **Dossier Steward**：`codex:reassess-b05-deep-plan-model-policy`
- **Context**：B05 建立時，deep-plan 真實執行沿用 session 的 Opus，而規則作用 eval 以 Sonnet 為樓層，因而同時留下成本與可比性疑問。其後 `M-20260915-b23-model-floor-policy-reconciled` 已將全 repo 指引收斂為 Sonnet 是 PASS 樓層、Haiku 是加分、Opus／更強模型只診斷過度解釋；仍需核對現行 deep-plan 的實際 model dispatch、成本槓桿與 eval 決策是否已被該政策涵蓋。
- **Goal**：以現行 deep-plan 雙 runtime 實作、模型樓層權威、eval oracle 與可取得的實際執行能力，判定 deep-plan 是否仍需自己的模型選擇規則；不沿用「預設釘 Sonnet」與「維持 session 模型」的舊二選一。
- **Acceptance Criteria**：分開盤點 Claude／Codex deep-plan 的 reviewer 建立路徑、可觀察 model selection、現行成本與樓層模型可比性要求，不把 Claude 的 Sonnet／Opus 名稱直接映射到 Codex；建立明確決策矩陣，說明每種可能結果會改變哪一條驗收或設計規則。只有模型或 reasoning effort 仍會改變具體決策時，才預註冊最小、當代且可判定的實驗並先取得 RED；若 B23 後已無獨立決策價值，則不新增模型 override、skill prose、eval 或 gate，移除 B05、記錄結案 milestone，並通過必要 behavior eval、deterministic gates、doc-governance ship audit與完整 suite。
- **Constraints**：審查品質是 hard acceptance gate：先守住 verdict、阻斷缺陷召回與 finding correctness，再只在全綠候選中以成本／延遲排序；修改任何 repo-local skill 前先完成 system skill-creator、repo authoring guide 與 portability preflight；behavior eval 是 oracle，無 observed failure 不補規則；產品敏感的模型能力或選擇介面若無法由 repo 現況確定，只查當前官方文件；不重跑舊 Sonnet／Opus 樣本、不把歷史模型名稱或成本假設當現行事實；不與 `M-20260915-b23-model-floor-policy-reconciled` 建立第二份模型政策；`claude/settings.json` 的未提交 runtime drift 不屬本項範圍。
- **進度**：已完成 skill-creator、repo authoring guide 與 portability preflight；逐一核對 shared workflow、Claude Agent、Codex deterministic launcher、中央模型樓層、歷史 eval／field log 與當前官方 model-selection surface。決策矩陣確認 production review 與規則作用 eval 必須分流，Claude／Codex 模型不可互相映射，品質先於成本；現況沒有 lower-cost 候選通過同一品質 oracle 的證據，也沒有 model／effort 造成錯誤 gate 或顯著成本的 observed failure，因此不預註冊付費 A/B、不修改 skill、launcher、config、eval 或 gate。Spec 基線與完成版完整 suite 均為 `PASS=1419 FAIL=0`，doc-governance ship audit 通過。
- **下一步**：記錄 `M-20260915-b05-deep-plan-model-policy-reassessed`、移除 B05 與本 active item，再由 `$project --merge` 完成 PR 與 merge。
- **關聯**：`B-20260819-debt-05`, `M-20260915-b23-model-floor-policy-reconciled`, `M-20260915-b22-old-round-ab-no-decision-value`, `D-20260825-portable-skill-authoring-default`, `shared/skills/deep-plan/evals.md`, `shared/skills/deep-plan/field-log.md`, `claude/evals/README.md`

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
