---
name: wait4me
description: "Enables, disables, or reports session-scoped NC notifications when the current main agent needs the user to reply. Use for $wait4me, waiting-for-input alerts, or 等我回應時通知我. Do not use for background-job completion or progress notifications."
---

# Wait4me — Codex entry

This is the Codex adapter for the portable session notification workflow.

1. Treat the invocation argument and hook-provided control result as the workflow input.
2. Resolve this skill directory from the actual `SKILL.md` location; do not assume a private install path.
3. Read `references/workflow.md` completely and follow it. The shared workflow is the sole authority for switch semantics, response-marker behavior, notification scope, and failure handling.
