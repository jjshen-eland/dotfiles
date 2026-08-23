---
name: handoff
description: "Preserves and resumes temporary same-machine task state as a verifiable checkpoint. Use when the user wants to clear or replace a session but continue later, asks to write a handoff/checkpoint, or wants to resume/reconcile a prior workline. Triggers: handoff, checkpoint, resume, 交接, 接手, 接續上次, clear 前保存. Not for progress summaries, shipping, durable project documentation, cross-host transfer, or native conversation history alone."
---

# Handoff — Codex entry

這是 Codex 的薄 adapter。

1. 先處理一個可選 adapter control token：`$handoff` 後面若含獨立的 `HANDOFF_DIR=<path>`，取其值作為
   使用者明確指定的 handoff directory，並從 workflow arguments 移除這個 token。不得把它當 slug。
   其餘文字保持原順序與原文，記為 **normalized invocation arguments**；不要補字、改寫 slug 或猜漏掉的 token。
   若 skill 是 implicit invocation，從使用者本輪明說的 checkpoint／resume 意圖取得等價參數。
2. 以本 `SKILL.md` 的實際位置解析 **handoff skill directory**。先執行
   `<handoff-skill-directory>/scripts/handoff-anchor.sh store`；只有上一步取到 control token 時，才以
   `HANDOFF_DIR=<path>` 傳給 helper，否則必須移除 ambient `HANDOFF_DIR` 後執行。非零即 STOP，不可自行挑另一個 store。
3. 完整讀取 [references/workflow.md](references/workflow.md)，把 normalized arguments、skill directory 與
   `store` 輸出的 handoff directory 帶入共同流程。核心 lifecycle、claims 信任邊界與 mutation contract
   只在 shared workflow/scripts，本入口不得另建一套。
