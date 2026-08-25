---
name: deep-plan
description: Reviews an implementation plan before coding by sending it to independent fresh reviewers, verifying its claims against the target repository, and gating work on explicit finding dispositions plus a second review round. Use for 計畫審查, 開工前檢查, plan review, pre-implementation approval, or asking whether an existing plan is safe to start. Do not use to create a plan or review code already written.
---

# Deep Plan — Claude Code entry

先確認輸入是一份尚未實作的既有計畫，並保留使用者指定的 artifact 與 repo scope。接著完整讀取本 skill 目錄下的 [references/workflow.md](references/workflow.md) 與其中指定的 reviewer brief，再依該 workflow 執行。

## Claude Code runtime contract

- 每一輪為每個 reviewer slot 建立新的 background `Agent`；不得 resume、SendMessage、follow up 或重用舊 reviewer。
- 同一輪預設兩位 reviewer。先 dispatch 全部 reviewer，取得每個成功建立的非空 Agent ID，才可 monitor、wait 或收取任何 reviewer 結果。
- 宣告「reviewers 正在執行」、todo 或打算 dispatch 都不是建立證據；不得以空 ID 集合開始等待或用 wait 發現 reviewer。
- 若建立第一位 reviewer 前就無法取得成功的 Agent ID，停止並回報 orchestration failure；不得改由 orchestrator 自審。
- 只有 runtime 明確拒絕第二個並行 Agent 時，才可保留 refusal evidence、先收完第一位，再建立另一個全新 Agent。第二位仍必須是 fresh context。
- 本輪只有在恰好收到 N 份可歸因於已建立 Agent ID 的完整結果時才有效；任一 Agent error、partial result、缺少四個輸出 sections，或 finding 缺少問題／層別／嚴重度／證據任一欄，都停止並回報 orchestration failure，不得進入 synthesis。
- reviewer prompt 不得包含 runtime 名稱、tool 細節或 orchestration 狀態。

這個入口只負責 Claude Code 的 fresh-context lifecycle；finding 分類、處置、第二輪與最終 gate 一律以 shared workflow 為準。
