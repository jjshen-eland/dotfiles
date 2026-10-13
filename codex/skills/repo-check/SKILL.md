---
name: repo-check
description: "Checks repository structure, ignore rules, Git state, remotes, identities and effective organization requirements. Uses built-in elandcomtw standards unless the user explicitly selects another policy. Use for repo health checks, repo 狀態檢查, 公司規範, remote／ignore 稽核, or explicitly requested organization-baseline initialization. Not for code review, session-exit audits or ordinary product shipping."
---

# Repo Check — Codex entry

1. Preserve the target path, explicitly selected policy and requested action from the current user request, including invocation arguments. Resolve the skill directory from the actual location of this file.
2. Read [references/workflow.md](references/workflow.md) completely and follow it. The shared workflow selects [references/elandcomtw.md](references/elandcomtw.md) by default; read [references/initialize.md](references/initialize.md) only for an explicit initialization request.
3. Use native file, Git and provider tools. Shared references own the policy selection, assessment and initialization boundaries; this adapter does not redefine them.
