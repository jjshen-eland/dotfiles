# Portable crawl-quality workflow

心智模型：在 corpus 進入 RAG 之前，先產生可重現的清潔度與 RAG 適用性證據，再將證據組成可操作的品質報告。

## Hard contract

- **READ-ONLY. NEVER modify, move, rewrite, or clean the source corpus.**
- **Run the bundled engine. NEVER recreate detectors, thresholds, sampling, counts, deductions, or scores in the model.**
- **Quantitative claims come verbatim from the final successful engine run. NEVER hand-adjust or recompute them.**
- **No engine example, no finding.** Every reported problem must carry a verbatim sample emitted by the deterministic engine. A source spot-check may resolve classification context, but it never creates or substitutes evidence for a finding.
- **A classification or exemption that affects scoring requires an explicit engine rerun.** Natural-language reasoning alone never changes a number.
- This workflow does not authorize cleaning the corpus, changing a pipeline, committing, pushing, opening a PR, or distributing results externally.

## 1. Resolve the assessment input

Use the invocation input as the source plus optional dataset context.

- An explicit file, directory, glob, or SQLite path is the source. Preserve it as one argument; do not let the shell expand a glob into multiple positional arguments.
- If no explicit source is supplied, ask for one instead of searching or scanning a broad directory.
- Preserve context such as site type, intentional content prefixes, known parser behavior, or autonomous/non-interactive execution. It informs later classification review.
- Accept an explicit content or source field when supplied. Do not guess around a rejected override.

## 2. Produce deterministic evidence

Resolve the engine as `<skill-directory>/scripts/crawl-quality-scan.py` and execute it with the available Python 3 runtime. Pass the resolved source as one argument. Add only user-supplied field overrides or classification/exemption overrides justified in Step 3.

The portable command interface is:

- `--content-field FIELD` and `--source-field FIELD` for explicit field selection.
- `--sample-seed INTEGER` only when the user requests a particular deterministic sample rotation.
- `--classify pN=noise|metadata|artifact|false-positive` after reviewing a reported prefix cluster; repeat the option for multiple clusters.
- `--exempt CHECK-ID` when corpus context makes a supported check inapplicable; repeat the option for multiple checks.

Keep the source as the single positional argument. If the engine rejects an option or identity, report that failure; do not infer a replacement.

Treat the engine as executable evidence, not a reference to read during an assessment. It owns input loading, bounded sampling, per-source measurement, detectors, score arithmetic, examples, output ordering, and validation.

Interpret its terminal state exactly:

- exit 0: evidence was produced; corpus quality may still be poor.
- exit 1: the corpus could not be evaluated. Report the diagnostic and stop without a score.
- exit 2: the invocation or override is invalid. Correct an objective argument error when possible; otherwise ask for the missing input. Do not weaken or omit the rejected option.
- Any `check-error:` evidence means the assessment is partial. Keep that check unknown, state that scores may be optimistic, and never infer cleanliness from its absence.

Do not bulk-load the corpus into context. The engine scans records. Read at most two or three source records only when the engine sample cannot resolve a material classification ambiguity. Never quote a spot-check as finding evidence or use it to derive a metric.

## 3. Review the judgment surface

Review every reported shared-prefix cluster and any context-sensitive residue hit.

Classify a prefix by its observed role:

- `noise`: navigation, sharing controls, or unrelated boilerplate; recommend removal in the extraction/cleaning stage.
- `metadata`: intentional key/value context embedded in content; recommend moving it to structured metadata.
- `artifact`: content repeats values already stored in separate fields; recommend fixing parsing or upload preparation.
- `false-positive`: legitimate document text; do not deduct.

When the engine heuristic conflicts with the dataset context, rerun with the explicit cluster classification. When a whole check is invalid for the corpus context, such as markup discussed as legitimate technical content, rerun with the supported exemption. Keep exempt evidence visible and record the override plus reason.

If an interactive classification remains materially ambiguous, ask the user. In autonomous execution, retain the deterministic heuristic, label the classification unconfirmed, and include the exact rerun option that would change it. Never silently pick a more favorable score.

The last successful rerun is the sole quantitative evidence for the report.

## 4. Report for the pipeline owner

Match the user's language. Include:

1. Source, total records, sampled records, source count, and whether sampling makes results estimates.
2. The engine's cleanliness, RAG suitability, composite score, and verdict without recomputation.
3. Findings ordered by scored impact, then material unscored observations. For each: dimension/check identity, affected global or per-source scope, verbatim example, and a concrete pipeline-stage correction direction.
4. A per-source summary covering every source and preserving its identity. Mark each source as having findings, no findings, or unknown/partial evidence; compact identical statuses without dropping source identities.
5. Prioritized cleaning recommendations. Keep assessment separate from implementation; do not edit the source or pipeline.
6. Every classification/exemption used, its reason, and any unconfirmed judgment or failed check.

Do not add quality dimensions, score components, thresholds, or acceptance gates that the engine did not produce. Clearly separate user-provided context from measured facts.
