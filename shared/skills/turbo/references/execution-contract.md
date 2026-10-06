# Turbo execution contract

Keep the target's existing Markdown spec/plan and adopted authority. In a mutable
draft, add a `Turbo Execution Contract` fenced YAML block linking to real facts:

```yaml
schema: turbo-execution/v1
goal_ref: "#goal"
scope_ref: "STATUS.md#active-work"
acceptance_ref: "#acceptance"
decisions:
  policy: best-fit-within-fixed-goal
  defaults: {}
checkpoints:
  - id: plan-review
    complete_when_ref: "#plan-review-evidence"
  - id: implement-and-verify
    complete_when_ref: "#checks"
  - id: code-review
    complete_when_ref: "#review-evidence"
  - id: deliver
    complete_when_ref: "#delivery-evidence"
reviews:
  reentry: agent-recommended-within-current-user-delegation
delivery:
  endpoint: agent-recommended
  allowed_actions_ref: "current actual user instruction"
stopping:
  policy: evidence-backed-infeasibility-or-no-progress-or-material-restructure
resources:
  limits: user-or-workflow-or-runtime
completion: all-acceptance-and-delivery-evidence
```

Resolve references to the target's real sections; do not copy the example's
placeholder anchors into a plan. Existing equivalent information is sufficient.
Readiness concerns executable intent and verification, not template completeness.
Frozen implemented/superseded plans stay frozen. Plan mode uses the same contract
but cannot authorize mutation. Never store action authorization solely in this
block, a session file or agent memory; revalidate it from the current user's input.

Each checkpoint needs an observable result and failure strategy. Repair within
scope, verify the changed bytes and review semantic dependents. Use Project's
authority for endpoint normalization, and the selected review controller for its
admission, dispositions, limits and receipts. Missing facts are investigated;
missing target intent is a real decision. Record durable facts in the target's
adopted lifecycle, not a new turbo dossier.

Before completion, verify each acceptance criterion against the actual public
input, output and failure contract, separately from reviewer verdict. Record the
criterion's evidence and unresolved boundary in the target's existing task state
or final report. Exercise normal cases and meaningful invalid/boundary cases on
the supported runtime; a green suite covering only convenient examples is not
evidence for omitted contractual cases.

For extensible input interfaces, establish an invariant over the exact snapshot
the consumer uses or emits. Validation of one representation followed by conversion
or rereading through another representation does not establish that invariant.
Also verify promised identity or round-trip behavior against the source's declared
logical contents: an internally consistent converted view may still omit or hide
data. A subtype's overridden convenience view does not redefine those contents.
Alternative interface implementations remain in the declared domain unless the
actual contract excludes them; neither author nor reviewer may invent an exclusion
to accept a counterexample. Check the promised exception boundary as well as
successful return values, including concrete parser/runtime failures reachable
from contractual inputs. Reproduce a contradiction, repair its root and dependents,
and use the existing review transitions on current bytes. Report unverified or
unmet criteria truthfully; do not infer acceptance from PASS or CLI exit alone.
