---
name: nc-notify
description: "Integrates safe lifecycle notifications into cron jobs, unattended background jobs, crawlers, backfills, and data pipelines. Use when creating or modifying scheduled/background work or when the user asks to add completion or progress notifications. Do not use for API request handlers, ordinary foreground commands, test execution, or explanation/review without implementation. Triggers: 加通知, 跑完通知我, cron, 背景腳本, 回補, pipeline."
allowed-tools: Read, Bash, Edit, Write, Glob, Grep
---

# NC Notify — Claude Code entry

這是 Claude Code 的薄 adapter。

1. 將當前使用者請求、target repo 規範、工作類型與可得的通知契約視為 **integration input**；保留使用者授權是實作、規劃或只讀 review。
2. 以 `${CLAUDE_SKILL_DIR}` 作為 **skill directory**。
3. 完整讀取 `${CLAUDE_SKILL_DIR}/references/workflow.md`，把 integration input 與 skill directory 帶入共同流程。觸發邊界、通知生命週期、failure isolation、驗證與授權規則只存在 shared workflow，本入口不重述。
