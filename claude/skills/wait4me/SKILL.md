---
name: wait4me
description: "Enables, disables, or reports session-scoped NC notifications when the current main agent needs the user to reply. Use for $wait4me, waiting-for-input alerts, or 等我回應時通知我. Do not use for background-job completion or progress notifications."
allowed-tools: Read, Bash
---

# Wait4me — Claude Code entry

This is the Claude Code adapter for the portable session notification workflow.

1. Treat the invocation argument and hook-provided control result as the workflow input.
2. Use `${CLAUDE_SKILL_DIR}` as the skill directory.
3. Read `${CLAUDE_SKILL_DIR}/references/workflow.md` completely and follow it. The shared workflow is the sole authority for switch semantics, response-marker behavior, notification scope, and failure handling.
