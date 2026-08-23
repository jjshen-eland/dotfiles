---
name: ready4quit
description: "End-of-session pre-quit flush for Claude Code. Use only when the user explicitly invokes /ready4quit before quitting to inspect unshipped Git state, persist durable session knowledge, reconcile async work, and list loose ends. Not for shipping, checkpoint/resume, progress summaries, or tests."
user-invocable: true
disable-model-invocation: true
---

# Ready4Quit — Claude Code entry

這是 Claude Code 的薄入口。只有使用者明確輸入 `/ready4quit` 才執行；一般對話中的「收尾」只提示
使用者叫用，不得自行啟動會寫入 memory／repo 的 flush。

1. 以 `${CLAUDE_SKILL_DIR}` 作為 **ready4quit skill directory**；helper 與 reference 一律由此解析，
   不得跳去另一個 checkout 或 Codex 的安裝路徑。
2. 使用以下 Claude Code adapter facts：
   - runtime label：`Claude Code`；exit wording：`/quit`。
   - durable user memory：只用本 session 實際提供的 memory facility 與格式；沒有就回報無合法 sink。
   - background/subagent：優先用 runtime 的 authoritative task status／完成通知；scratchpad 同層
     `tasks/` 只能枚舉 candidate，不能判 liveness；`TaskList` 不是 background-task list。
   - cron/routine：有 `CronList` 才算可枚舉；`/loop` 與 `ScheduleWakeup` 沒有列表工具時只靠對話回溯。
3. **完整讀取 `${CLAUDE_SKILL_DIR}/references/workflow.md` 並執行。** 把本 adapter facts 與
   `${CLAUDE_SKILL_DIR}/scripts/git-hygiene.sh` 帶入共同流程；核心 evidence、mutation 與 verdict contract
   只在 shared workflow，不得在入口另建一套。
