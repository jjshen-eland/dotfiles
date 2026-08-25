---
name: check-crawl-quality
description: "Assesses cleaned crawl corpora for residual noise and RAG suitability with reproducible evidence. Use for crawl quality checks, RAG readiness, 檢查爬蟲品質, 清理後品質, or RAG 適用性. Do not use to build or debug a crawler, review a database schema, or design a RAG system without an existing corpus to assess."
---

# Check Crawl Quality — Codex entry

This is the Codex adapter for the portable crawl-quality workflow.

1. Preserve the source path, optional dataset context, and explicit overrides from the current user request as the **invocation input**. Do not invent a path or rewrite the context.
2. Resolve the **skill directory** from the actual location of this `SKILL.md`; do not use a Claude Code or user-specific absolute path.
3. Read `references/workflow.md` from that skill directory completely and follow it with the invocation input and skill directory. The shared workflow and deterministic engine are the only authority for assessment behavior, evidence, and reporting.
