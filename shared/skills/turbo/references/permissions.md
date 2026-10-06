# Permission readiness

On changes delegation and continuation, not the host's approval/sandbox profile.
Select a launch profile before entering an unattended run:

| Runtime | Profile | Invocation |
| --- | --- | --- |
| Codex | Sandbox, no prompts | `codex -a never -s workspace-write` |
| Codex | Automatic approval review | `codex --approve-for-me` |
| Codex | Bypass approvals and sandbox | `codex --dangerously-bypass-approvals-and-sandbox` |
| Claude | No prompts, refusals possible | `claude --permission-mode dontAsk` |
| Claude | Bypass ordinary permissions | `claude --permission-mode bypassPermissions` |

Check installed CLI help and report the actual effective profile.
Native hook `permission_mode` is the host's coarse label, not proof of the launch
approval policy, sandbox or readiness. Verify those from the actual invocation.
Managed policy, hook trust, login and service authorization remain independent. Codex custom hooks
must be trusted through the supported host flow; do not mistake silent skipped
hooks for readiness. A user-selected one-off trust-bypass flag is separate
authorization, never an implicit side effect of on.

Off revokes delegated work but cannot restore a launch-time bypass profile. State
this distinction in status. Never permanently alter global config to avoid prompts.
Native approval requests remain pending until the host's terminal result.

Outward evidence also needs the runtime's actual persisted transcript, as required
by [delivery ordering](workflow.md#delivery-completion-and-stopping). Native CLI
default persistence supplies it; Codex `--ephemeral` and Claude
`--no-session-persistence` do not. Those profiles remain usable for ordinary
non-outward goals but cannot claim unattended delivery readiness. Do not fabricate
a transcript, globally enable storage or relaunch a pending action to replace it.

Before claiming unattended outward delivery, verify current user action authority
and test canonical/opaque commands with each profile against actual outward rules
and hooks. A bypass flag grants no push/PR/merge authority. Preserve gates; opaque
deny, sandbox deny or automatic-review deny remain real results. Use isolated
local remotes for composition; that evidence does not prove GitHub provider E2E
or all UI approval paths. New surface claims require native traces.
