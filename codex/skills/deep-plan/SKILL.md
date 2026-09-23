---
name: deep-plan
description: Assesses an existing implementation plan before coding. Uses acceptance-driven small increments for ordinary work and independent fresh multi-round review for concrete high risk or an explicit full-review request. Use for 計畫審查, 開工前檢查, plan review, pre-implementation approval, or asking whether an existing plan is safe to start. Do not use to create a plan or review code already written.
---

# Deep Plan — Codex entry

## Codex runtime contract

Apply the shared workflow's risk route first. The reviewer lifecycle below applies only when that route selects full review.

- For every round, run `scripts/launch-reviewers.py` once with the absolute plan path, every absolute repo path, the absolute `references/planner-brief.md` path, the absolute `assets/reviewer-output.schema.json` path, and the requested reviewer count. When shared workflow §2 classifies the plan as changing a gate or pass/block criterion, also pass `--criteria-impact-review`; omit it for other plans. This launcher is the only reviewer-dispatch path; do not call collaboration spawn, follow-up, or wait tools.
- Treat a launcher result as valid only when it exits zero and its stdout manifest says `ok: true`, its `criteria_impact_review` value matches the classification used for launch, all reviewers share one prompt hash, all were simultaneously running after dispatch, each has a distinct non-empty thread ID and schema-valid `review`, every repo's before/after HEAD, status, and content fingerprint match, and the plan, brief, and schema hashes are unchanged.
- Read and synthesize every `review` in that manifest. Do not consume a partial result set.
- If the launcher is unavailable, returns nonzero, or any manifest invariant fails, STOP and report orchestration failure. Never replace missing reviewers with the orchestrator's own review.
- Run the launcher again for the second round; its ephemeral child processes provide new contexts. Never reuse a prior manifest, thread, or result.
- Do not put runtime names, tool details, IDs, or orchestration progress in reviewer prompts.

After preserving the user's artifact and repository scope, completely read [references/workflow.md](references/workflow.md); load the reviewer brief only when that workflow routes to full review. The shared workflow controls routing, findings, dispositions, the second round, and the final gate; this entry controls only Codex reviewer lifecycle.
