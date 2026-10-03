---
name: repo-review
description: Deeply reviews local repository changes with independent fresh-context reviewers, immutable scope checks, historical guidance, cross-repository coverage, concrete findings, and an explicitly authorized bounded autofix option. Use for low-bias code review, multi-repo or explicit commit-range review, review this branch or PR checkout, findings with file references, or repo-review autofix. Do not use for code explanation, implementation, test-only work, ordinary debugging, plan review, or remote PR checkout by itself.
---

# Repo Review

Runtime strategy: `review_strategy=single-pass-v1`. Accept `--full` as the
shared workflow's explicit full-review selector; it does not authorize autofix.
Accept explicit `--focused` and `--repair-limit <1..5>` selections through the
shared [controller protocol](references/control.md); defaults remain unchanged.

This is the Codex public entry for the portable deep-review workflow. Keep the
public skill name `$repo-review`; do not redirect the user to another skill name.

Resolve `<skill-root>` as the directory containing this `SKILL.md`. Read
[references/workflow.md](references/workflow.md) completely and follow it. When
starting any reviewer, require that reviewer to read
[references/portable-reviewer-brief.md](references/portable-reviewer-brief.md)
completely before inspecting the target.
Before any reviewer dispatch or repair, use
[scripts/review-control.py](scripts/review-control.py) as specified by that protocol.

Use [scripts/review-scope.sh](scripts/review-scope.sh) to capture and re-verify
every repository's review subject. Preserve an explicitly supplied two-endpoint
range exactly until the helper resolves it to immutable object IDs; never replace
it with a last-commit or branch default.

Use exactly one top-level verdict: `PASS`, `FAIL`, or `BLOCKED`. Never claim
review, tests, autofix, or cross-repository coverage that did not complete.
