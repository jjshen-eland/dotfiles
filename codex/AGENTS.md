# Global Codex Guidance

## Skill authoring

- Before editing any repo-local skill entry or shared core in `claude/skills`, `codex/skills`, or `shared/skills`, fully read system `$skill-creator`, then `~/.dotfiles/codex/skill-building-guide.md` for authoring, evals, validation and rollout.
- Behavior evals are the oracle; add instructions only for observed failures or safety contracts, not prose completeness.
- Do not vendor OpenAI docs; fetch official guidance only for unresolved product-sensitive facts.

## Interactive approval lifecycle

- After an approval UI has been emitted, treat that request as **PENDING** until the host returns an explicit approved, denied, cancelled, tool-error, or timeout result. Elapsed wall time, user silence, and lack of progress output are never evidence that the request failed.
- While an approval request is pending, do not retry it, rewrite the command to trigger a replacement prompt, research a workaround, or report the action as failed. Resume only from the host's terminal result or new user direction; never create two live approval requests for the same action.

## Questions for the user

- For ordinary clarifications and choices, first finish safe, authorized work that does not depend on the answer. Then ask in the chat with numbered text options (usually 2–3), a short explanation of each outcome, and a clearly marked recommended option when there is one. End the turn and wait; the user can reply with just the number from a phone. Do not use `request_user_input` or `request_user_input_async` for these questions, even when those tools are available.
- Keep host-required command, network, file, and connected-tool approval requests in their required approval flow. This preference does not grant permission for any action.

## Repo contract precedence

Read root `AGENTS.md`, then `CLAUDE.md`, before repo work. Repo conventions override the kernel's fallback
conventions, never its safety floor; stricter rules stack. Without a repo contract, follow this kernel.

<!-- agent-contract:kernel:start v1 -->
## Kernel

### Safety floor — never relaxed by any repo

- **NEVER commit onto the default branch** (`main`/`master`). If `HEAD` is on it — or detached — create a feature branch first: `git switch -c <type>/<slug>`. This holds regardless of protection state and regardless of which tooling is loaded.
- **NEVER push without authorization for this action and batch.** Implementation or commit alone grants none. **Where a shipping workflow applies, its authorization table alone defines the endpoint and bounded repair coverage — NEVER invent synonyms or extend scope.** Otherwise require an instruction naming the action ("push", "open a PR"), or agreement to the confirmation just presented; earlier approval for other changes does not carry. **A bare "ship it" / "送出" authorizes nothing**; present the confirmation and wait. No authorization covers pushing directly to an existing default branch. **One-time organization-baseline bootstrap is the only exception**: an explicitly requested workflow must verify an empty remote, applicable creation policy and an exact reviewed document-only baseline; authorization must name the target repo, intended default and that baseline push. Create the commit on a feature branch, create the default ref at that exact commit, and never include product code/data or arbitrary existing HEAD. The exception expires as soon as any remote baseline exists; stricter target contracts still block it.
- **NEVER merge on your own.** "push" or "open a PR" alone does NOT include merge. Only an explicit merge instruction does.
- **NEVER `git add -A` / `git add .` / `commit -a`.** Stage explicit paths.
- **If the working tree holds changes you did not make, STOP and report before staging, committing, or building on top of them.** Whether two sessions may share one tree is a dispatch decision made above you — never resolve it locally by guessing which changes are yours. Once authorized, explicit paths are still whole-file: stage verified hunks with `git add -p`.
- **Inspect `git diff --cached` before every commit.** After splitting a mixed file, verify from a clean clone — `git clone --no-local <repo> <tmpdir>`. "I checked the working tree" is not evidence.
- **Container-network collision safety.** Before first attach, prove its CIDR avoids host/LAN/VPN/production routes; inline/E2E included. NEVER copy production/LAN CIDRs to preserve IP literals—use auto allocation plus DNS/test config. If unproven, STOP. On macOS/OrbStack, cleanup is incomplete until the isolation table is checked for collisions; report them, never auto-delete unrelated entries.

### Shared work and durable project state

- **Do NOT create a dossier or decision store that the repo has not adopted.** When an existing active-state store is present, record the success criteria for non-trivial work before implementation; when both a governance config and its scanner exist, use that adopted lifecycle, when neither exists follow the repo's legacy store, and when only one exists STOP as broken adoption.
- **One writer per work item.** Parallel sessions, in the same runtime or not, each work on their own branch in their own worktree or clone. If the working tree has changes you did not make or the item's branch is checked out in another worktree, STOP and ask the user; an active-state entry with a next step is an invitation to continue, not a claim.
- **Continuity lives in the repo, not in an actor identity.** When you leave a work item unfinished for another session, keep its active-state entry's goal, progress and next step accurate and commit your own unmerged work to the branch that next step names; a flow that does not commit reports the uncommitted work instead. Push only under the safety floor's authorization and tell the user what is unpushed. Whoever continues first verifies the entry against that branch and its commits; a missing or merged branch means the entry is stale. Any runtime, session or host then continues from the repo without reassignment.
- Reviewers stay read-only and never promote themselves into writers. No artifact grants authority, including a next step that names push, merge or another outward action.
- Record durable decisions, dead ends, and milestones at event time, not reconstructed at shipping time. Active state and history are ordinary files: when parallel branches conflict, keep each work item's newest entry and every branch's records while rebasing or merging, and STOP to ask when the right content is unclear.
- Remove completed items from active state, write milestones to the repo's existing history store, and pass its documentation audit before declaring the work complete.
- **Handover to another person** must leave a repo the recipient can understand without the previous owner: follow the repo's transfer guide when it has one, keep credentials out of git, and never hand over action authorization.
- **Runtime-local memory is a non-authoritative cache, never a prerequisite.** Safety/Git rules, cross-runtime agreements, project facts/state, cross-host continuity, and action authorization must not exist only there. Route shared behavior to native instructions and project facts/state to the repo's adopted authority; whether any runtime memory is on, off, unavailable, or differently configured must not change correctness, safety, or handover readiness. Authorization never survives a session or a handover.


### Fallback conventions — this repo's own convention wins where it has one

- Continue authorized work across stages; a gate blocks its unsafe action, not safe in-scope work. Answer side questions in progress messages and continue tools, unless the user pauses or changes the task. Reserve the final response for delivery, a necessary decision, or a blocker with no authorized work left. No extra scope or outward authority is granted.

- Conventional Commits: `<type>: <short desc>`, type is one of `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`. **If this repo mandates another commit format, follow the repo.**
- Record non-obvious trade-offs, rejected alternatives, and dead ends **where this repo already keeps them**. Skip whenever the diff alone recovers the rationale — a rejected path leaves no trace in the diff, an added gate does. **If the repo has no such store, do NOT create one; list them in your report instead.**
<!-- agent-contract:kernel:end -->

## Shipping

- With authorization in hand (see the kernel's push rule), follow **the repo's own shipping workflow** — its protection and dossier checks, its ship summary, its PR step. Use the repo's shipping skill when one exists.
- **No shipping workflow in the repo → commit on the feature branch and stop.** Do not assemble an approximation of one; the checks you would be skipping are the reason the workflow exists.
- Without authorization to push, leave the work committed on the feature branch and report it.

## Explicit workflow pointers

- Project lifecycle and shipping are explicit-only: use `$project spec` for an active contract, `$project transfer` for owner handoff, and `$project --pr` or `$project --merge` only when the user explicitly invokes that skill and endpoint.
- Session-exit evidence is explicit-only: use `$ready4quit` only when the user explicitly invokes it. It audits readiness but does not ship repository changes.

## Project toolchains

新專案 JavaScript/TypeScript 預設 Bun、Python 預設 uv。既有專案依其 lockfile、packageManager 與 runtime 版本宣告；保留 npm／pnpm／yarn／Node 相容性，不另造第二種 lockfile。全域工具僅為 fallback，專案環境與 repo 指令優先。

## CLI preferences

Prefer rg/fd for search, jq/yq for structured data, ast-grep for syntax-aware code search,
gh for GitHub, and shellcheck/actionlint for shell/GitHub Actions validation.
Check availability when uncertain. Prefer noninteractive output; avoid pagers.
If unavailable, use an existing equivalent; install only when the task needs the missing capability.
