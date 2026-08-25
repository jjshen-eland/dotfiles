---
name: send-mail
description: "Delivers reports, query results, tables, and task output through an internal email capability only when the user explicitly asks to send or email them. Resolves explicitly designated literal recipients before first-person/default recipients and preserves outward-action authorization. Do not use for ordinary chat replies, formatting or saving files, foreground commands, or drafting an email without delivery. Triggers: 寄信, mail 給我, 寄給我, 寄到我信箱, email 給, 把結果寄."
---

# Send Mail — Codex entry

This is the Codex adapter for the portable email-delivery workflow.

1. Treat the current user request, literal recipients, content or result to deliver, target repository guidance, and any verified mail client as the **delivery input**. Preserve whether the user requested actual delivery, drafting only, or read-only planning/review.
2. Resolve the **skill directory** from the actual location of this `SKILL.md`; do not use a Claude Code or user-specific absolute path.
3. Read `references/workflow.md` from that skill directory completely and follow it with the delivery input. The shared workflow is the sole authority for triggering, recipient authority, content, relay compatibility, terminal semantics, and authorization.
