---
name: check-crawl-quality
description: "Assesses cleaned crawl corpora for residual noise and RAG suitability with reproducible evidence. Use for crawl quality checks, RAG readiness, 檢查爬蟲品質, 清理後品質, or RAG 適用性. Do not use to build or debug a crawler, review a database schema, or design a RAG system without an existing corpus to assess."
user-invocable: true
argument-hint: "<path_or_source> [context_description]"
allowed-tools: Bash, Read, Glob, Grep
---

# Check Crawl Quality — Claude Code entry

這是 Claude Code 的薄 adapter。

1. 將 `$ARGUMENTS` 保持原順序與原意，連同當前使用者請求視為 **invocation input**；不補路徑、不改寫資料集 context。
2. 以 `${CLAUDE_SKILL_DIR}` 作為 **skill directory**。
3. 完整讀取 `${CLAUDE_SKILL_DIR}/references/workflow.md`，把 invocation input 與 skill directory 帶入共同流程。品質契約、證據邊界與報告要求只存在 shared workflow 與 deterministic engine，本入口不重述。
