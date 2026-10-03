# Project shared workflow — 模式與階段路由

本檔是 Claude Code `/project` 與 Codex `$project` 的跨 harness 收尾載入路由；Log 的 Critical／Step 0–5 依下表分階段載入。入口會提供 **normalized invocation
arguments** 與它自己的 skill directory；先把該目錄下的 `scripts/`、`templates/` 解析成絕對路徑
`<project-scripts>`、`<project-templates>`。任一資源不存在就 STOP；NEVER 假設私人 checkout 或 runtime
安裝路徑。

## 必讀 reference 的有界讀取協定

薄入口已先用 `<project-scripts>/read-reference.py` 讀取本檔；本節也 governs 下表各階段的必讀 reference。
每次 tool call 只讀一個檔案的一個 chunk，不得把多檔、多段或其他命令合併／平行塞進同一份回傳。
從 `--start 1` 開始，逐段核對 `REFERENCE`、固定不變的 `SHA256`、連續且不重複的 `Lnnnnnn` 行號，並依
`NEXT` 接續；只有看見該檔的 `EOF` 才算完整讀取。若同一檔的 SHA 改變，從 line 1 重新讀取。

每個階段只讀下表所列 prerequisite；條件分支只在觸發時讀取。
同session已完整收到EOF、內容仍在
可用context且實際檔案SHA256未變時沿用，不因內部stage切換、插問或重驗從頭再讀。
新session、只剩摘要／memory、內容遺失或SHA改變才重讀；搜尋命中不算完整讀取。
典型呼叫如下，`NEXT` 的值成為下一次 `--start`：

```sh
python3 "<project-scripts>/read-reference.py" dossier.md --start 1
```

若 host 在 `NEXT`／`EOF` 前截斷輸出，該 chunk 不完整：從最後一個**完整收到**的 `Lnnnnnn` 下一行恢復；
半行不算。若連一個完整編號行都沒有，降低 `--max-bytes` 並以同一 cursor 重試。正常分段不需向使用者報告；
只有實際發生 host 截斷才簡短說明恢復。目前階段的全部 prerequisite 都出現 `EOF` 前，不得執行該階段的修改 repo、commit、push、
開 PR、merge 或 cleanup；read-only 盤點可以繼續。這個 transport 協定不放寬任何 mode、授權、STOP 或
shipping 規則。

## 模式分派

normalized invocation arguments 的第一個 token 分派模式，其餘 token 傳給該模式：

- `spec`／`--spec` → Spec 模式。
- `log`／`--log` → Log 模式。
- `transfer`／`--transfer` → Transfer 模式。
- 其他或無模式引數 → 預設 Log；與舊 `/uap` 相容。
- mode flag 可出現在任意位置；spec／transfer 的 repo token 沿用 Log Step 0 的 path resolver。

模式確定後依下表載入。**No mutation before its stage prerequisites reach EOF.**
Log 的盤點是唯讀；即使引數是 `--merge`，也先盤點，不預載未進入的阶段。
各 reference 只有一份 canonical source；路由不授權任何原本未授權的動作。

| 階段／觸發 | 先完整讀取 | 接著做 |
|---|---|---|
| Log 盤點 | [log-workflow.md](log-workflow.md)、[ship-policy.md](ship-policy.md) | Step 0/1 唯讀偵測；真的無工作就結束 |
| Log 有變更或 docs-only 工作 | [authority.md](authority.md)、[dossier.md](dossier.md)、[log-prepare.md](log-prepare.md) | branch-first、authority、文件、測試證據、commit、摘要準備 |
| Log 準備送出摘要 | [ship-paths.md](ship-paths.md) | 讀完再印 Step 4 Ship 摘要，依授權終點執行 Step 5 |
| Log 的終點含 merge | 另讀 [merge-workflow.md](merge-workflow.md) | CI、merge、自己分支 cleanup；在第一個 outward call 前讀完 |
| Spec／Log 的合法 Spec subflow | [authority.md](authority.md)、[dossier.md](dossier.md)、[spec-workflow.md](spec-workflow.md) | 只寫 active contract，不 commit |
| Transfer／任何模式發現 pending transfer 或 conditional owner | [authority.md](authority.md)、[dossier.md](dossier.md)、[transfer-workflow.md](transfer-workflow.md) | 先判 effective steward，再做合法操作 |
| bootstrap、fork／身分分離、branch rescue fallback、review squash、push failure | [ship-exceptions.md](ship-exceptions.md) | 在對應處置之前讀取；STOP 不授權 workaround |

Spec／Transfer 的 repo token 交 `<project-scripts>/ship-state.sh resolve <token>`；REPO 鎖定、MODULE 是
path scope、UNKNOWN 只可匹配已知 repo basename，仍有歧義就問，不靜默忽略或當成 module。
Read-only diagnosis 才按需讀 [ship-diagnostics.md](ship-diagnostics.md)；正常流程用既有 helpers，
不重組它們已負責的 Git／provider 偵測。

## Runtime adapter

- 需要使用者回答時，Codex 直接在聊天中輸出 2–3 個精簡文字編號選項並暫停當前 turn，
  不呼叫 `request_user_input`／`request_user_input_async`；Claude Code 使用 `AskUserQuestion`，
  該工具不可用時同樣改用文字編號選項並暫停。以下 references 的「依 Runtime adapter 提問」均指此規則。
  每個選項本身必須寫出完整動作與後果；有建議項時將它放在第一項並標示「建議」，取消項明述不修改。
  不得只要求使用者回覆「確認」／「停止」、「是」／「否」或其他須回讀前文才知道後果的短 token；請其回覆編號或完整選項。
  使用者緊接著的直接選項回答延續同一 logical Project invocation；自由文字身分宣稱或其他工作後的回答不算，必須重新偵測。
  這是已經需要詢問時的呈現契約；不新增 branch／PR 預檢、工具呼叫或詢問點，不改變原有詢問時機與 authority／scope／shipping 邊界。
- Claude Code 的顯式形式是 `/project ...`；Codex 是 `$project ...`。說法表只解讀 invocation arguments
  與本輪使用者明說的 endpoint，不把 runtime 的 skill sigil 當授權。
- Shell、git 與 gh 行為完全相同。可照抄 helper command 必須由 scripts 自己輸出其實際絕對路徑。
- Commit trailer 與 PR attribution 只遵循目前 runtime／repo 已載入的規則；沒有規則就不自行加產品標記。
