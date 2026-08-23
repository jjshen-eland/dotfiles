# Portable deep-review workflow

Use this workflow from either Claude Code or Codex. Resolve `<skill-root>` as the
directory containing the invoking `SKILL.md`; all resource paths below are
relative to it.

## 1. Interpret the request

Treat review as read-only unless the user explicitly asks to fix confirmed
findings. Phrases such as “before I push”, “make sure it is safe”, or “review
this” do not authorize edits, staging, commits, pushes, or merges.

Track these independent choices:

- **Scope:** repositories, commit range, paths, or explicit full-repository audit.
- **Mode:** read-only review or explicitly authorized autofix.
- **Verification:** primary independent review only, or a requested second
  independent review after the primary result.

Normalize the legacy public spellings without importing their old mechanics:
`autofix` explicitly selects autofix; `autocodex` explicitly requests Codex as a
second independent reviewer; using both requests both behaviors.

Do not turn an explanation, implementation, test-only, or debugging request into
a deep review unless the user also asks for review.

## 2. Resolve an exact scope

For every candidate repository, read its root contract (`AGENTS.md`, then
`CLAUDE.md`) and any nearer contract that governs a selected path. Follow the
repository's own documentation lookup route when it defines one.

User-specified repositories, paths, and two-endpoint commit ranges win. Do not
silently expand or shrink them. This workflow reviews local repositories and
already checked-out changes; a remote PR URL alone does not authorize fetching,
checkout, or creating a worktree.

When the user did not give a range:

1. On a feature branch with an identifiable upstream/default-branch base, use
   the merge base through current `HEAD`, plus staged, unstaged, and untracked
   work in the selected paths.
2. With no cumulative branch commits but a dirty tree, review `HEAD` plus all
   staged, unstaged, and untracked work in the selected paths.
3. If the repository is clean and has no uniquely implied branch diff, stop and
   offer concrete choices: a range, named paths, or a full-repository audit.
   Never substitute the last commit, an arbitrary ancestor, an empty diff, or a
   whole-repository audit.

If more than one repository may belong to the workline and the user did not
name them, list the candidates and their apparent change counts, then wait for
confirmation. Never scan broad project directories or infer repositories from
stale session memory. A user-named repository remains in scope even when its
diff is empty, because its side of a cross-repository contract may still matter.

Create one immutable scope manifest per confirmed repository:

```text
<skill-root>/scripts/review-scope.sh capture --repo <repo> --mode branch --base <base-ref>
<skill-root>/scripts/review-scope.sh capture --repo <repo> --mode working-tree
<skill-root>/scripts/review-scope.sh capture --repo <repo> --mode range --range <base>..<head>
<skill-root>/scripts/review-scope.sh capture --repo <repo> --mode audit
```

Append `--path <repo-relative-path>` for each selected path. Keep the returned
manifest paths until the terminal report. If capture rejects the scope, fix the
ambiguity rather than replacing it with a guessed range.

Immediately inspect each manifest with `review-scope.sh show`. For an explicit
committed range, the manifest's applicable guidance comes from the resolved head
tree, including guidance that exists only at that historical revision. Read those
files with `git show <resolved-head>:<path>` and verify the object IDs printed by
the manifest; never substitute current-worktree guidance. Branch, working-tree,
and audit manifests use checked-out guidance and include its content identity in
the scope fingerprint.

The canonical empty-tree object is a valid explicit baseline. Other tree objects
and non-ancestor commit pairs are valid only as explicit read-only endpoint
comparisons; warn that a divergent two-point comparison can include reverse-side
deletions. Never describe either shape as an ancestor range or use it for
autofix. If the user wants branch-introduced changes instead, offer the reported
merge base as a new scope and wait for confirmation.

## 3. Partition and start isolated reviewers

Choose non-overlapping primary assignments before delegation. Respect an explicit
reviewer limit and the runtime's actual concurrency cap:

- A small coherent change uses one or two reviewers split by distinct concerns.
- A medium change uses up to three or four reviewers with module or concern
  ownership.
- A large change is partitioned by repository, coherent module, or roughly 8–12
  changed files per assignment.
- A multi-repository change assigns at least one reviewer per repository when
  capacity permits. When contracts, schemas, release order, or shared
  configuration interact, reserve capacity for a cross-repository contract pass.

Do not give the complete broad scope to every reviewer. If capacity cannot cover
the confirmed scope, narrow assignments honestly and report the unreviewed
portion as `BLOCKED`; never imply full coverage.

Use a new reviewer with no parent conversation history for every assignment:

- **Claude Code:** create a new independent Agent. Do not resume or reuse an
  earlier reviewer.
- **Codex:** call `spawn_agent` with `fork_turns: "none"`, then collect it with
  `wait_agent`. Do not delegate from a fork that inherited this conversation.

If the user explicitly names a reviewer product or model, preserve that choice.
Use a fresh process or agent from the named runtime when it is available; if it
is unavailable, return `BLOCKED` rather than substituting another reviewer.

If the active runtime cannot provide a fresh-context reviewer, return
`BLOCKED`. The primary agent must not impersonate an independent reviewer or
quietly downgrade the isolation claim.

Give each reviewer only:

- the absolute repository roots and the exact scope described by each manifest;
- the selected paths and immutable base/head object IDs;
- the governing repository-contract paths;
- the absolute path to `<skill-root>/references/portable-reviewer-brief.md` and an
  instruction to read it completely before reviewing;
- the user's requested output language.

Also provide that reviewer's bounded repositories, paths, modules, or concerns.
For a cross-repository pass, include only the relevant interfaces and both
immutable endpoint sets. Do not send one reviewer's output to another reviewer.

Do not include author hypotheses, prior findings, prior repair summaries, review
pass numbers, remaining cycle budget, desired verdict, or statements that a
particular area is probably correct. Do not expose this skill's eval oracle.
Task names, role labels, and checkpoint text must also remain neutral.

Every reviewer is read-only. It may inspect files, history, tests, and local
contracts, and may run safe read-only diagnostics. It must not edit, stage,
commit, switch branches, push, merge, or mutate external systems.

## 4. Verify the review result

External reports are evidence, not authority. For every proposed finding:

1. Re-open the cited source and governing contract.
2. Reproduce the trigger or verify the control/data flow far enough to establish
   the concrete impact.
3. Search the whole confirmed scope for same-class occurrences and semantic
   dependents; do not stop at the cited location.
4. Classify the claim as true positive, false positive, or unresolved. A
   reviewer's `executed`, `verified`, or confidence label never waives this step.

Group true positives by root cause. Keep critical, high, and medium correctness,
security, regression, or broken-contract findings blocking. Keep low-risk style,
wording, and optional completeness suggestions non-blocking. A missing fact,
contradiction, stale command, or broken reference in an instruction artifact is
blocking only when following it can cause wrong behavior. “Could say more” is
not a blocking defect.

After all assignments return, compare the planned partition with the returned
reports. Deduplicate overlapping findings and state any missing assignment or
cross-repository pass; an absent result is incomplete coverage, not a clean pass.

Run the target repository's authoritative relevant checks. Preserve their exit
codes. If no meaningful check exists, report `UNVERIFIED`; do not invent a
project-specific command or call a green unrelated test proof of correctness.

Before accepting the review, verify every manifest:

```text
<skill-root>/scripts/review-scope.sh verify --manifest <manifest-directory>
```

Unexpected drift makes the result `BLOCKED`. Do not guess a new base or silently
restart against a different subject.

## 5. Finish read-only mode

Return a terminal report using the contract below. Do not modify the repository
to demonstrate a suggested fix. `FAIL` in read-only mode includes an ordered
repair plan, not an implementation.

## 6. Autofix confirmed blocking findings

Enter this section only after explicit user authorization to fix findings.

Before the first edit:

- Re-verify every scope manifest.
- Run `<skill-root>/scripts/review-scope.sh autofix-check --manifest <manifest>`
  for every repository and require `autofix-safe: yes`. This rejects detached or
  non-current heads, arbitrary tree bases, divergent commit ranges, and drift.
- Stop if the working tree contains changes whose ownership is mixed or unknown.
- If a commit will be needed, ensure `HEAD` is on a non-default feature branch
  first. Never commit from detached `HEAD` or onto the default branch.
- Read and obey the target repository's mutation, testing, and commit rules.
- Set a finite repair limit before starting: default three repair cycles, never
  more than five. Never raise or reset it after the first reviewer starts.

Fix only independently verified blocking findings. Before editing, search for
all same-class occurrences and semantic dependents: callers and callees,
producers and consumers, schema/wire-format peers, configuration/documentation
contracts, and tests. For finite closed sets, cover every member; for externally
extensible or unbounded inputs, repair the invariant rather than enumerate known
values.

After each repair batch:

1. Inspect the actual diff and confirm it contains only authorized, owned work.
2. Run the relevant authoritative checks. A failed or unavailable required check
   stops the loop; preserve an understandable working state and report it rather
   than expanding scope to repair the environment.
3. Capture a new manifest for the repaired subject.
4. Start a new fresh-context reviewer set under the same partition and isolation
   contract. Do not send it earlier findings, repair summaries, pass numbers, or
   remaining budget.
5. Independently verify its findings again.

Stop with `PASS` when no blocking findings remain. Stop with `FAIL` when verified
blocking findings remain at the repair limit. Stop with `BLOCKED` when scope,
ownership, reviewer validity, or required verification cannot be established.
Do not open a new cycle, rename the pass, invoke this skill recursively, or use a
second-review request to evade the limit.

If autofix ends in `FAIL` or `BLOCKED` after editing, persist a shipping-visible
terminal signal without touching worktree or history:

```text
<skill-root>/scripts/review-terminal.sh record --repo <repo> --reason <blocking-findings|blocked-review> --head <current-head>
```

After an autofix `PASS`, clear an older compatible signal only when the reviewed
base/head prove that this review covered it:

```text
<skill-root>/scripts/review-terminal.sh clear --repo <repo> --base <review-base> --head <review-head>
```

Autofix authorization alone does not authorize commit, push, PR creation, merge,
history rewrite, or destructive cleanup. Perform those only when separately
authorized and permitted by the target repository contract.

For skills, agent instructions, policies, and other self-governing artifacts,
use a reproducing behavior eval as the repair oracle. Run one diagnostic review,
then fix and forward-test the observed behavior. Do not repeatedly review prose
until reviewers stop suggesting additions. If no reliable behavior oracle can
be built, stop autofix and report the blocking claim as unresolved.

## 7. Optional second independent review

Run a second independent reviewer only when the user requested it. Start it from
fresh context with the same raw scope and brief, not the primary verdict or
findings. Independently verify its output and report it as a separate component.

If the primary review passed but the requested second reviewer produced no valid
result, retain `Primary: PASS`, mark `Second review: BLOCKED`, and use top-level
`BLOCKED`. Never claim that both reviewers passed and never rewrite the primary
result as `FAIL`.

## Terminal report contract

Use exactly one top-level verdict:

- `PASS`: review completed and no verified blocking finding remains.
- `FAIL`: review completed and at least one verified blocking finding remains.
- `BLOCKED`: exact scope, independent review, ownership, or required verification
  could not be established.

Always include:

1. Repositories, mode, paths, immutable commit endpoints, and whether dirty and
   untracked work were included.
2. Primary and optional second-review status.
3. Blocking findings first, grouped by root cause. Each finding includes severity,
   exact location, trigger condition, concrete impact, evidence, verification
   basis, same-class coverage, and an actionable repair direction.
4. Non-blocking items separately; zero findings is valid.
5. Checks actually run, their result, and anything unverified.
6. In autofix mode, changed files, validation after each repair batch, remaining
   issues, cycle-limit status, and why the loop stopped.
7. Any scope drift or incomplete stage without disguising it as a code defect.

When `PASS` covers committed changes, include immutable `base..<head>` endpoints
that another reviewer can reuse. For multiple repositories, list each range and
the dependency order separately.
