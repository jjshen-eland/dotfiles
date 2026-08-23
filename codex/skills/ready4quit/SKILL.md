---
name: ready4quit
description: "End-of-session pre-quit flush for Codex. Use only when the user explicitly invokes $ready4quit before quitting to inspect unshipped Git state, persist durable session knowledge, reconcile async work, and list loose ends. Not for shipping, checkpoint/resume, progress summaries, or tests."
---

# Ready4Quit — Codex entry

這是 Codex 的薄入口。只有使用者明確提及 `$ready4quit` 才執行；一般對話中的「收尾」不是叫用。

1. 以本 `SKILL.md` 的實際位置解析 **ready4quit skill directory**；`references/` 與 `scripts/` 是
   canonical Claude tree 的 shared links。從 worktree 測試時必須使用 worktree 這份，不得跳去全域安裝副本。
2. 使用以下 Codex adapter facts：
   - runtime label：`Codex`；exit wording：結束目前 session。
   - durable user memory：只在目前 runtime 明確提供 durable-memory facility 時使用；不要假設 Claude 的
     private memory path，也不要自行建立一套。
   - background/subagent：用目前可用的 authoritative agent status、已知 yielded exec session 與完成通知；
     不掃 OS process table，也不把 log/output artifact 當 liveness oracle。沒有可枚舉介面就標 `PARTIAL`。
   - schedule/automation：只用目前 runtime 實際提供的 authoritative listing；沒有就標 `PARTIAL`，
     conversation 中提過的 loop／scheduled work 仍須逐項回溯。
3. **完整讀取 [references/workflow.md](references/workflow.md) 並執行。** 把本 adapter facts 與
   `<ready4quit-skill-directory>/scripts/git-hygiene.sh` 帶入共同流程；核心 evidence、mutation 與 verdict
   contract 只在 shared workflow，不得在入口另建一套。
