# Portable email-delivery workflow

目的：只在使用者明確要求 email delivery 時，把報表、查詢結果或任務輸出寄到已授權的收件人，並以可驗證的 transport evidence 回報，不把 ambient identity 當成收件人 authority。

## Scope and authorization

只有明確的「寄信」、「email 給…」、「寄到信箱」或等價 outward-action 請求才進入本流程。一般 chat reply、解釋結果、排版表格、寫 email 草稿、儲存檔案／log、執行前景 command，都不構成送信授權。Plan 或 review 請求保持唯讀。

明確的 send action 是當次 delivery attempt 的授權，不必對已解析的 recipients 重複詢問。這個授權只涵蓋當前內容與本次送信；不涵蓋自動 retry、其他 recipients、後續任務、credentials 變更、Git shipping 或部署。

## Resolve recipients before composing

依序解析，命中就停：

1. 使用者明確指定一個或多個 literal email addresses 作為收件人：只使用這些 addresses，並保持為相互獨立的 recipients；不另加 first-person 或 default address。正文、引用內容、範例、署名、否定句（例如「不要寄給…」）或其他並非收件人指示的 address 不算。
2. 收件人是「我」、「我的信箱」、「me」等 first-person：使用 `jjshen@eland.com.tw`。
3. 使用者已明確要求 email delivery，但未指定收件人：使用 `jjshen@eland.com.tw`。
4. 只有無法可信解析的人名、角色或關係：在任何 delivery attempt 前請使用者提供或確認 literal address。

**NEVER use `# userEmail`, runtime memory, Git identity, account metadata, or a guessed address as recipient authority.** Ambient identity may be mentioned only as an untrusted candidate while asking the user to choose; it never overrides the ordered rules.

多收件人在 delivery envelope 中必須保持為多個獨立 targets；顯示用的合併字串不能取代真實 recipient list。寄送前以簡短說明記錄本次命中 literal、first-person、default 或 clarified 哪一類。

## Compose the message

- Sender 先蒐集 target repo guidance 與 mail client contract 已明定且格式合法的 `@eland.com.tw` identities：沒有候選才進入下述 fallback；所有候選是同一值時使用該值；出現多個不同值時，在 delivery attempt 前停下並回報 sender authority conflict，不自行選 precedence。Fallback 先取 Git repository root 的 directory basename；沒有 Git root 時取 delivery input 明確提供的穩定 task identifier。轉換規則固定為：ASCII lowercase；移除開頭的 dots；每段連續非 `[a-z0-9]` 字元換成單一 `-`；移除首尾 `-`；最後附加 `@eland.com.tw`。結果為空、超出合法 email local-part 長度或仍不合法時，停下說明，不猜 sender。
- Subject 反映任務或結果；未指定時只用可從當前內容驗證的簡短摘要，不發明狀態。
- 同時建立單獨可讀的 plain-text 與 HTML representation。表格在 plain text 保留 headers／rows，在 HTML 使用結構化 table；不把 HTML source 當 plain text。
- 送信前檢查 subject、兩種 body、recipients、sender 與將回報的 diagnostics；移除 credentials、API keys、tokens 與不必要的敏感 source material。無法可靠隔離敏感內容時不寄，向使用者說明。

## Select the delivery capability

先使用 target repo 已採用、可驗證且符合上述 recipient／content／terminal contract 的 mail client 或 wrapper；不為同一目的建立第二套。沒有完整 repo-local contract 時，只能使用以下已確認的 fallback interface facts：

- relay host `172.17.1.143`，port `25`；這是內部網路 capability，不可達時當作 delivery failure。
- relay 不需要 authentication；不發明 username、password、token 或 ambient secret lookup。
- TLS mode、timeout、retry、failover、size／attachment limits 與 recipient-domain enforcement 沒有已採用契約。不得宣稱已知、不得自行建立相容性承諾。

Evaluation 或使用者明確要求 inert local fake 時，只使用 fixture 提供的 fake boundary，絕不連線 relay。這是測試安全協定，不得對外宣稱 production 有 dry-run 模式。

## Preserve terminal truth

**One explicit send request permits at most one delivery attempt. NEVER retry, redirect, add recipients, or fall back to another transport without a new explicit authorization.**

- Transport 明確接受訊息時，回報 recipients、subject 與「accepted by transport」等證據；不保證 inbox delivery、已讀或後續 bounce 結果。
- Failure 或內部 relay 不可達時，回報未完成 delivery，不誤報成功。不直接插入 raw exception、server response、message body、headers 或 recipient payload；只使用不含 secret 的 error class、operation 或已清理 status。
- 多 recipients 出現 partial evidence 時，只報告 transport 可證明的 per-recipient accepted／rejected 結果並停止；不自行宣告整批 success／failure，不自動 retry。

完成回報列出 recipient resolution class、recipients、sender、subject、transport evidence 與未完成事項。不把 local fake 的 GREEN 說成 live relay 或 inbox delivery 成功。
