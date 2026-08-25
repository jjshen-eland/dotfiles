---
name: send-mail
description: "Delivers reports, query results, tables, and task output through an internal email capability only when the user explicitly asks to send or email them. Resolves explicitly designated literal recipients before first-person/default recipients and preserves outward-action authorization. Do not use for ordinary chat replies, formatting or saving files, foreground commands, or drafting an email without delivery. Triggers: 寄信, mail 給我, 寄給我, 寄到我信箱, email 給, 把結果寄."
allowed-tools: Bash, Read, Write, Edit
---

# Send Mail — Claude Code entry

這是 Claude Code 的薄 adapter。

1. 將當前使用者請求、明文 recipients、要寄送的內容或結果、target repo 規範與可得的 mail client 視為 **delivery input**；保留使用者是要求實際寄送、只寫草稿，或只讀規劃／review。
2. 以 `${CLAUDE_SKILL_DIR}` 作為 **skill directory**。
3. 完整讀取 `${CLAUDE_SKILL_DIR}/references/workflow.md`，把 delivery input 與 skill directory 帶入共同流程。觸發、收件人 authority、內容、relay compatibility、成功／失敗與授權邊界只存在 shared workflow，本入口不重述。
