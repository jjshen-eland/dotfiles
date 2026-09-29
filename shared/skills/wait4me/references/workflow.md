# Portable Wait4me workflow

`wait4me` is a foreground-session switch. It does not monitor background jobs and it does not replace an approval or answer on the user's behalf.

## Control contract

- Bare `$wait4me` and `$wait4me on` enable response-needed NC notifications only for the current foreground session.
- `$wait4me off` disables them immediately and idempotently.
- `$wait4me status` reports the current session state without changing it.
- Enabling is the user's bounded authorization to send these notifications until `off` or this session lifecycle ends. It authorizes no other outward action.

The `UserPromptSubmit` hook performs the state change before the agent runs and supplies a `wait4me-control:` result in additional context. Report that observed result concisely. For a paraphrased request with no control result, direct the user to submit the exact `$wait4me`, `$wait4me on`, `$wait4me off`, or `$wait4me status` command and do not claim the state changed. If an exact command has no result, explain that the lifecycle hooks are not active in this process and that a new session is required after installation or hook trust changes.

Treat new, clear, resume, ownership transfer, and session end as authorization boundaries. They require a fresh `on`; compact within the same live session may preserve the switch. Never infer an enabled state from conversation history or runtime memory.

## When a reply is required

While the hook-provided context says wait4me is enabled, follow its response-marker contract exactly. Add the marker only when the main agent cannot safely continue without a user reply, such as a required choice, missing information, approval, or an external action the user must perform.

Do not add it for a completed answer, optional next step, progress update, rhetorical question, or subagent completion. Do not use punctuation or natural-language guessing as a substitute for the marker.

The marker reason must be a single short, actionable, non-sensitive summary. Do not include commands, prompts, transcript excerpts, credentials, tokens, private paths, raw tool input, or unbounded error text. The hook sends the notification; the agent must not call Notification Center directly.

If work ownership transfers while enabled, disable the current authorization before transfer completion and tell the user that the new actor needs a fresh `$wait4me on`.

## Failure semantics

Notification delivery is always a side channel. Missing NC configuration, timeout, non-success response, serialization failure, or any other notification error must not change the agent's result, approval decision, or ability to continue. Do not retry without a separately verified bounded retry contract.

The switch does not make approval implicit. After receiving a notification, the user must still return to the terminal and answer the actual prompt.
