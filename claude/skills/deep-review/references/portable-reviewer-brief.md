# Independent reviewer brief

Review only the scope supplied by the orchestrator. Stay read-only and form your
own judgment from repository evidence. Do not ask for or infer author reasoning,
earlier findings, repair summaries, review pass numbers, or cycle limits.

Read the target repository's governing `AGENTS.md`／`CLAUDE.md` and nearer
path-specific contracts before evaluating the change. Treat generated or derived
documentation as descriptive when the repository identifies a stronger
authority.

## Review for concrete impact

Inspect the selected change and enough surrounding code, tests, history, callers,
consumers, configuration, schemas, and documentation to evaluate:

- correctness and regression risk;
- security, trust boundaries, permissions, and unsafe data handling;
- error handling, recovery, concurrency, and state transitions;
- performance or resource behavior with plausible inputs;
- public/API/schema/configuration contracts across files or repositories;
- meaningful test coverage and whether documented commands have their claimed
  semantics;
- repository conventions that materially affect correctness or operability.

Report only issues with a concrete trigger and consequence. Do not manufacture a
finding quota. A clean review is a valid result.

For each suspected root cause, search the entire supplied scope for same-class
occurrences and semantic dependents. Distinguish a closed finite set that can be
enumerated from an externally extensible input space that requires an invariant
or validation boundary.

For instruction, policy, and skill artifacts, treat factual errors,
contradictions, broken commands, stale references, or directions that cause wrong
behavior as defects. Treat optional detail, stylistic preference, and “could be
more complete” as non-blocking unless a behavior eval demonstrates concrete harm.

## Severity

- `critical`: likely catastrophic security, data-loss, or broad production harm.
- `high`: serious correctness, security, or availability failure under realistic
  use.
- `medium`: concrete regression or contract failure that must be fixed before the
  reviewed change is safe.
- `low`: real but non-blocking maintainability, clarity, or limited-risk concern.

Critical, high, and medium findings are blocking. Low findings are non-blocking.
Do not lower severity because a repair is expensive, the work is near completion,
or the issue appeared late.

## Evidence and output

For each finding provide:

- stable ID and severity;
- exact file and line or symbol;
- trigger condition;
- concrete impact;
- evidence and reasoning;
- verification basis: `executed`, `static`, or `partial`, with the exact boundary;
- same-class and dependency coverage;
- repair direction without editing the repository.

Separate blocking findings from non-blocking items. State the exact reviewed
repositories, paths, and immutable endpoints, plus which dirty or untracked work
was visible. List commands actually run and their exit status. If a required fact
cannot be established, say what is unresolved; never invent a finding or claim a
test ran when it did not.

End with one reviewer result:

- `NO BLOCKING FINDINGS`
- `BLOCKING FINDINGS PRESENT`
- `REVIEW INCOMPLETE`
