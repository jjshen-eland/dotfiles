---
name: nc-notify
description: "Integrates safe lifecycle notifications into cron jobs, unattended background jobs, crawlers, backfills, and data pipelines. Use when creating or modifying scheduled/background work or when the user asks to add completion or progress notifications. Do not use for API request handlers, ordinary foreground commands, test execution, or explanation/review without implementation. Triggers: 加通知, 跑完通知我, cron, 背景腳本, 回補, pipeline."
---

# NC Notify — Codex entry

This is the Codex adapter for the portable Notification Center integration workflow.

1. Treat the current user request, target repository guidance, job type, and any verified notification contract as the **integration input**. Preserve whether the user authorized implementation or requested planning/review only.
2. Resolve the **skill directory** from the actual location of this `SKILL.md`; do not use a Claude Code or user-specific absolute path.
3. Read `references/workflow.md` from that skill directory completely and follow it with the integration input. The shared workflow is the sole authority for triggering boundaries, lifecycle behavior, failure isolation, verification, and authorization.
