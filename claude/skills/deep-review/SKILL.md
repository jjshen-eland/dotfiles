---
name: deep-review
description: Deeply reviews local repository changes with independent fresh-context reviewers, immutable scope and historical-guidance checks, scale-aware or cross-repository coverage, concrete findings, and an explicitly authorized bounded autofix option. Use for deep code review, review this branch or PR checkout, 審查這批改動, 幫我看 code, cross-repository contract review, or a requested second independent review. Do not use for code explanation, implementation, test-only work, ordinary debugging, plan review, or remote PR checkout by itself.
---

# Deep Review

Review a precisely bounded local change set without inheriting the author's
conclusions. Default to read-only reporting; modify files only when the user
explicitly requests autofix.

Resolve `<skill-root>` as the directory containing this `SKILL.md`. Read
[references/workflow.md](references/workflow.md) completely and follow it. When
starting any reviewer, require that reviewer to read
[references/portable-reviewer-brief.md](references/portable-reviewer-brief.md)
completely before inspecting the target.

Use [scripts/review-scope.sh](scripts/review-scope.sh) to capture and re-verify
each repository's review subject. Treat a failed scope check as `BLOCKED`; never
repair it by guessing another range.

The terminal response must contain exactly one top-level verdict: `PASS`, `FAIL`,
or `BLOCKED`. Never claim review, tests, autofix, or a second independent opinion
that did not complete.
