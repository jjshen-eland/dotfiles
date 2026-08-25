---
name: root-cause-first
description: "Enforces evidence-backed root-cause diagnosis before fixes. Use for bugs, failing tests or builds, regressions, wrong output, performance or integration failures, repeated failed fixes, debugging, 根因分析, or 修了又壞. Do not use for feature implementation, ordinary refactoring, code explanation, code review, or plan review without a concrete failure."
---

# Root Cause First — Codex entry

This is the Codex adapter for the portable diagnosis discipline.

1. Treat the current user request and available failure context as the **diagnosis input**. Preserve whether the user requested explanation only or also authorized a fix.
2. Resolve the **skill directory** from the actual location of this `SKILL.md`; do not use a Claude Code or user-specific absolute path.
3. Read `references/workflow.md` from that skill directory completely and follow it with the diagnosis input. The shared workflow is the sole authority for evidence gates, terminal states, pressure resistance, and completion claims.
