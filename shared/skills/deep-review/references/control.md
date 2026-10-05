# Review controller protocol

Use `python3 <skill-root>/scripts/review-control.py`. Python 3 stdlib and Git are
required. All commands emit JSON; nonzero means the requested transition did not
succeed. `status --state <file>` reports counters, findings and unfinished work.
This is an operational review journal, not ownership or action authorization.

## Open and resume

After confirming the complete repo set and capturing its manifests, run:

```text
review-control.py open --manifest <manifest> [--manifest <other-manifest>] --route <ordinary|full> [--autofix] [--followup focused] [--repair-limit 2] [--second-opinion]
```

The default remains blind follow-up and three repair attempts (maximum five).
`--followup focused` and a different limit require the user's explicit selection;
do not enable them because the current batch is difficult. Ordinary still uses
one independent primary review plus author verification. A requested second
opinion reserves one additional set, not an unlimited repair route.

The returned `state` is shared by both runtime entries. `open` locates an existing
batch by canonical target roots, rejects omitted repos or changed scope/policy,
and never resets counters. Use `status` on that state when resuming after edits;
do not recapture to replace its baseline. Store the path with the existing task's
evidence when continuity is needed. Default artifacts are under the same user's
fixed system-temp `deep-review-<uid>` directory, outside every target and `.git`.
`DEEP_REVIEW_STATE_DIR` is an isolated-fixture override, never a way to resume or
reset a live batch. Do not delete/relocate journals to evade limits. Missing or
unavailable evidence is BLOCKED, not permission to reconstruct a PASS from memory.
Artifacts are local review evidence; they do not carry action authority to another
session, runtime or host, and are not a new project dossier.

## Dispatch and collect

Write assignment JSON outside targets:

```json
[{"id":"source","repos":["/absolute/repo"],"concern":"changed behavior and affected contracts"}]
```

Use neutral IDs/concerns. Cover all confirmed repos; full-route partitioning and
cross-repo responsibilities still follow the workflow. The controller validates
repo coverage, not the semantic completeness of a concern description.

```text
review-control.py admit --state <file> --assignments <json> --reason <initial|repair|second> --language <language>
review-control.py dispatch --state <file> --ticket <returned-ticket>
```

`admit` spends one set attempt before producing packet files. `dispatch` consumes
the ticket once, revalidates subjects and packet hashes, and returns those paths.
Only then start the fresh reviewers using exactly the generated packet content,
with no parent conclusions or extra lifecycle commentary. Keep ticket/state paths,
counts, policies and this protocol out of reviewer inputs. Never launch after a
failed gate. A partial or invalid result consumes its attempt; it is not a refund.

Save original reports and native reviewer identities, then submit a complete set:

```json
[{"assignment":"source","reviewer":"native-unique-id","result":"complete","report":"/outside/target/report.txt","findings":[{"id":"F1","severity":"medium","location":"a.py:12","trigger":"concrete input","impact":"wrong output","evidence":"source or executed probe"}]}]
```

```text
review-control.py finish --state <file> --ticket <ticket> --input <results-json>
```

Use `result: incomplete` for incomplete work, not `complete` with empty findings.
Malformed/partial sets, reused identities, packet mutation or subject drift yield
BLOCKED and no valid receipt. Original report text and raw severities are retained;
structured extraction must faithfully match them. The helper cannot certify a
model's claim that it inspected a file or reported every finding.

Independently verify every new finding, then submit dispositions using controller
finding IDs from `status` (not the reviewer's local `F1`):

```json
[{"id":"controller-finding-id","status":"true-positive","evidence":"source flow and reproducer result","relation":"independent"}]
```

```text
review-control.py assess --state <file> --input <dispositions-json>
```

Status is `true-positive`, `false-positive` or `unresolved`. An open earlier finding
rechecked after an explicitly changed subject may use `resolved` with evidence;
the original disposition remains in history. Relation is
`independent`, `unresolved-original`, `repair-introduced`, `repair-exposed` or
`unknown`. The three repair-related relations require `parent` (earlier finding
ID) and `diagnosis` explaining the before/after evidence, repair method, invariant
and dependents. Late discovery alone does not prove introduction. Preserve raw
severity; a false-positive disposition needs independent evidence. Unknowns block
acceptance. No text similarity classifier or mandatory architecture rewrite.

## Repair and preflight

Re-establish current authorization and ownership under the target contract first.
For each bounded attempt:

```text
review-control.py repair-start --state <file> [--editable-repo <owned-repo>]
```

This verifies scope/autofix safety and spends a repair slot before edits. Inspect
same-class occurrences and semantic dependents before fixing the verified root.
Repeat `--editable-repo` when only part of the confirmed repo set is independently
safe and authorized to change. Other repos retain their manifests and stay read-only;
include an exact `repo` in findings when a multi-repo assignment found a local defect.
Cross-repo findings remain shared until independently verified otherwise. Actual
changes outside the editable repos or selected paths block repair acceptance.
After edits, inspect the actual diff. Run relevant checks through the controller
using a JSON argv array, for example `["python3","-B","-m","unittest","discover","-s","tests"]`:

```text
review-control.py check --state <file> --repo <repo> --input <argv-json>
```

It executes the command once and binds exit/output to actual selected file bytes.
A failing/interrupted/mutating check cannot become evidence for another snapshot.
A failed preflight consumes this repair attempt; diagnose before `repair-start`
spends the next slot. Never keep editing/retrying inside a failed attempt.
Do not route unrelated environment fixes through this authorization.

Submit repair completeness evidence for every open original finding:

```json
{"checks":["returned-check-id"],"findings":[{"id":"controller-finding-id","outcome":"addressed","trigger":"original reproducer and result","same_class":"searched set and each disposition","invariant":"input boundary or invariant verified","dependents":"callers/consumers and evidence"}]}
```

```text
review-control.py repair-finish --state <file> --input <proof-json>
```

If no meaningful executable check exists, use an empty check list plus
`static_evidence` describing the actual verification and its boundary. Do not use
it to bypass a failed, incomplete or stale executed check. An unresolved original
finding, missing evidence or known check failure prevents reviewer dispatch.
The helper captures actual repair deltas and fresh manifests, but does not grade
the truth or completeness of free-text evidence. Verify that evidence yourself.

Ordinary author verification may now finish PASS; it is not another independent
review. Full route uses `admit --reason repair`: focused receives original claims,
actual deltas and evidence; blind receives only the current subjects. Freshness,
complete results and subsequent independent verification apply to both. A new
concrete risk changing the route/scope is a decision, not permission to reset the
existing batch or raise its budget.

## Exhaustion and terminal evidence

Counts are independent: set attempts, valid sets, reviewer count, repair attempts
and check executions. Full primary capacity is initial plus the frozen repair
limit; optional second opinion adds one set. Both failed checks and failed review
attempts remain spent. Stop early when complete; caps are ceilings, not targets.

At a limit, retain FAIL for verified blockers or BLOCKED for missing valid evidence.
Do not start another reviewer. After a new explicit user instruction, record its
exact text in an external artifact and run `new-batch --state <file> --authorization
<text-file>`. The text records provenance, not a machine-issued permission token.
The journal retains findings, history and valid baseline. A verified local repair
can use focused again; an invalid baseline or changed scope needs a newly confirmed
blind scope: pass every new manifest to `new-batch` with the explicit scope-change
instruction, then use `admit --reason initial`. Open earlier findings require
revalidation and cannot silently disappear. A mode recommendation is separate
from authorization to dispatch.

After editing an authorized target, persist a stopped review with
`terminal-record --state <file> --repo <repo> --reason blocking-findings` (or
`blocked-review`). After PASS, `terminal-clear --state <file> --repo <repo>` requires
a valid receipt for current bytes, original paths and covering endpoints. Read-only
or unedited targets reject both mutations. Legacy ancestry-only signals remain
preserved because their path/content coverage is unknown; report that limitation
for explicit disposition, never clear them opportunistically.

## Explicit legacy terminal disposition

This is a separate user-directed Git-metadata operation, never a side effect of
read-only review or ordinary shipping approval. Re-establish ownership and obtain
the user's current instruction to close the named original legacy signal despite
its unknown coverage. Old batch "ship anyway", ordinary merge, autofix permission
and a new PASS alone do not authorize it. The helper records provenance; it cannot
certify that an agent's quotation faithfully represents the user's instruction.

Inspect without mutation:

```text
review-control.py terminal-status --repo <repo>
```

For `kind: legacy`, require a completed controller PASS that still matches the
current complete subject (no path restriction, no historical range), with no
pending review or repair. Reuse valid evidence; do not rerun review to manufacture
mutation authority. A legacy PASS does not establish the missing original
coverage; the explicit disposition must acknowledge that uncertainty. Bind the
decision to the returned signal identity, current HEAD, controller receipt scope
and the named endpoint. Keep these implementation fields out of the user prompt;
explain the old signal, uncertainty, affected batch and consequences plainly.

Only after that exact current instruction, create an external JSON artifact:

```json
{"action":"close-legacy-review-terminal","repo":"/canonical/repo","signal":"returned-signal-hash","head":"current-full-oid","scope":"current-controller-receipt-scope","endpoint":"merge","user_instruction":"exact current user instruction accepting closure of this original legacy signal with unknown coverage"}
```

Endpoint is `branch`, `pr`, `merge` or `disposition-only`; it bounds this closure
decision and grants no outward authority. Signal/HEAD/scope drift requires a fresh
decision, never rewriting the binding to fit an old approval. Then run:

```text
review-control.py terminal-dispose --state <file> --repo <repo> --input <json>
```

The controller archives the original anchor, exact instruction and PASS identity
under the existing Git metadata's `deep-review/dispositions/`, then appends its
receipt ID to the anchor. It preserves counters, findings, review verdict and
original terminal fields. `terminal-status` and Project validate that archive
against the exact legacy signal and its lineage. Missing/malformed history or a
new/scoped signal stays blocked; do not delete, reconstruct or retry around it.
Only this old signal retires. The receipt is neither a current-batch review PASS
nor push/PR/merge/CI/production authorization. Subsequent review signals retain
their own gates. Scoped signals continue to use compatible `terminal-clear` and
its existing autofix mutation boundary.
