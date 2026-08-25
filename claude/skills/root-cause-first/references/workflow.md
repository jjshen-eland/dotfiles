# Portable root-cause diagnosis discipline

目的：對具體 failure 建立可被反駁的因果解釋；只有在 evidence 支持 root cause、scope 也授權修復時，才修改造成 failure 的來源。

## Critical contract

**Violating the letter of these rules is violating their spirit.**

- **Evidence before fix.** Do not propose or implement a fix until observed evidence supports why the claimed cause produces the failure and why it is upstream of the symptom.
- **Never turn a hypothesis into a fact.** Separate observed facts, hypotheses, supporting or contradicting evidence, and unknowns.
- **A containment is not a repair.** Retry, cache clearing, fallback, suppression, broad permission, or boundary guards may reduce impact, but they do not count as root-cause repair unless evidence shows they remove the cause.
- **No false completion.** If the original failure evidence or a relevant broader check still fails, the work is not complete. Do not relabel the failure as unrelated without evidence.
- **One causal change at a time.** Do not bundle speculative fixes; preserve attribution.
- **This skill grants no authority.** Diagnosis-only requests remain read-only. Editing, destructive actions, commit, push, PR, merge, deployment, or external communication still require their existing authorization and repository contracts.

Time pressure, seniority, sunk cost, fatigue, and an apparently obvious one-line patch do not lower these gates.

## 1. Establish the failure evidence

先確認 expected 與 actual、觸發條件、受影響範圍，以及可比較的正常案例。優先取得可重跑的 failing test；若環境或外部系統使自動重現不可行，保留具體的手動重現、trace、log 或量測作為等價 evidence。

沒有足夠的 failure evidence，或現有 evidence 仍無法區分主要假設時，不要假裝已定位。把終態標為 `UNCONFIRMED`，列出下一個能區分主要假設的事實。不可重播的 production incident 仍可由充分、可驗證的 trace／control evidence 建立因果鏈。

## 2. Locate the first causal divergence

沿實際 data／control flow 比較 failure 與正常 control，找出兩者第一次產生有意義差異的 boundary。錯誤被拋出、畫面顯示異常或測試 assertion 所在處只是 symptom location，除非 evidence 證明它同時是差異來源。

每項驗證都要能獨立歸因，並主動尋找能推翻假設的 control。近期變更、輸入差異、共享狀態、cache、順序與元件邊界都是待驗方向，不是預設答案。外部服務、環境與 timing 也必須由 evidence 支持，不能作為提早停止調查的出口。

## 3. Choose an honest terminal state

只能使用符合 evidence 的終態：

- `ROOT CAUSE CONFIRMED`：因果來源有具體支持與反證 control，可說明 symptom 如何由它產生。
- `UNCONFIRMED`：證據不足或現有 evidence 無法區分主要假設；列出下一個可證偽的 evidence，不給猜測修法。
- `CONTAINMENT ONLY`：已降低影響但原因仍存在；保留仍失敗的 evidence、residual risk、撤除條件及 permanent repair 的 owner／授權缺口。
- `BLOCKED`：root cause 已定位，但 scope、ownership、依賴或 authorization 不允許修復；不要在別的 boundary 繞過原因後宣稱完成。
- `SYSTEMIC REVIEW NEEDED`：兩次以上獨立 patch attempt 未解決 failure，或修補持續把問題移到別處；停止再疊 patch，與使用者重議 shared state、coupling 或 abstraction。

若同時需要 emergency containment 與 permanent repair，分成兩個可驗證工作，不讓前者冒充後者。

## 4. Repair only when authorized

使用者只要求 diagnose／explain 時，回報 evidence 與終態，不改檔。若已授權修復：

1. 在修改前保留能暴露問題的 failing evidence。
2. 做對準 root cause 的最小單一變更；若只能做 containment，使用上節的誠實終態。
3. 先讓原 failure evidence 轉綠，再跑受影響範圍的 broader checks。
4. 回報變更如何移除原因、哪些 controls 排除了 symptom patch、驗證結果與仍未知之處。

任何 relevant check 仍失敗時，不得宣稱 repair complete。若 failure 真屬不可控或非決定性外部因素，結論仍需 evidence，並清楚區分 resilience improvement 與 root-cause removal。

## Pressure red flags — STOP

- "The incident path passes, so the remaining failing root-cause test can wait."
- "The owner said not to touch the causal component, so a workaround is the fix."
- "We found the cause; clearing its state on every request is equivalent to removing it."
- "One more unverified patch is faster than revisiting the model."
- "The error is raised here, therefore the cause is here."

Each means: stop, restore the evidence/terminal-state distinction, and do not claim completion.
