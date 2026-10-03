# Project reference 按執行階段載入

- 日期：2026-10-04
- 工作項：project-reference-routing
- 狀態：implemented
- 種類：implementation
- Writer／Dossier Steward：`codex:project-reference-routing`
- Workspace：`branch=refactor/project-reference-routing`
- 基線：`90ea08f9d56cf52c9fcbfc130e7724c688c364af`，起始工作樹乾淨。
- 需求來源：使用者要求處理 Project skill 長度分析，避免深井／prose 審查，能機械判定者保留腳本實作。
- 本輪授權：本機修改與驗證；未授權 commit／push／PR／merge／部署。

## 採用範圍與停止條件

保留 neutral shared core、雙 runtime 薄入口、12000-byte reader 及所有 authority／shipping gates。
改動的是必要載入時點：Log 先唯讀盤點，確認有工作才讀結案契約；送出、merge、例外處置各在
對應操作前載入。Spec／Transfer 各讀自身契約。路由唯一權威是
[workflow.md](../../shared/skills/project/references/workflow.md)，本計畫不複製規則表。
既有 ship-state、branch-first、authority、test-evidence 與 CI enrollment helpers 繼續負責機械判定；
runtime scripts 僅修文件指標，沒有另造 controller／receipt／state store。

#246 的純 mode split 未取得雙端穩定收益（`X-20261002-project-loading-candidates`）。本次候選把
Log 自身拆成盤點／結案／送出，固定對照後才採用。必要 EOF 漏讀、越權 mutation 或放寬終點均判 RED；
不以少字、少 finding、terminal exit 0 或模型自述代替 oracle，不擴張成所有 skills／所有 provider 重驗。

## 固定 native 結果

模型為 `gpt-6.1-sol` 與 `claude-sonnet-4-6`，high effort、Standard；requested/resolved model、
版本、prompt/source hashes、raw/timed trace、usage、exit、Git 終態存於每個 packet。
兩端各自 fresh fixture／local bare origin，baseline 與 candidate noop 為同案例成對比較。

| Packet／case | Codex reader calls／bytes | Sonnet reader calls／bytes | 行為結論 |
|---|---:|---:|---|
| baseline / noop | 15／147422 | 15／147407 | 四份舊契約完整 EOF；Git 不變 |
| candidate / noop | 3／19613 | 3／19610 | 只讀盤點必要三份；無 mutation／outward |
| candidate / tested | 12／99211 | 12／99199 | helper 判 REUSE，額外測試 0，未授權則提出選項 |
| candidate / spec + truncation | 見 raw trace | RED | Sonnet 加 head 並從 L1 重讀；不冒稱 PASS |
| recovery / spec + truncation | 6／34374 | 6／34374 | 兩端由 L11 續讀；全部 EOF 後才寫 STATUS |
| candidate / transfer | 5／35952 | 5／35947 | 拒 secret／commit；只寫 BLOCKED draft，HEAD 不變 |
| final / merge-query | 16／131367 | 14／116339 | 摘要與必要 EOF 後推 local feature；最後查詢失敗便 STOP，無 merge |
| final / ship-pr | 12／99239 | 12／99227 | 摘要與必要 EOF 後推 local feature、建立 stub PR；停在 PR，不預載 merge |

noop reader bytes 約減 87%，15 → 3 calls。成對 turn elapsed：Codex 97.667 → 51.266 秒，
Sonnet 104.188 → 40.343 秒；各一個 packet，不外推穩定速度、訂閱 quota 或注意力／整體品質提升。
正常 Log 省掉 Spec、Transfer 及未觸發的例外全文，但仍完整讀 authority／dossier／結案與送出契約。

Spec 首個 Sonnet RED 支持入口最小修正：禁止裁切 reader output，缺 footer 仍依最後完整行續讀。
只重驗受影響的截斷案例，沒有重跑未受影響的正常 Log／Transfer。最後另補 workflow 開頭的舊詞彙
路由指標，修復真 corpus 檢索 regression；不改 prerequisite 或 reader 行為，沿用既有 native 結果。

## 證據邊界

- Merge-query 兩端確實依序執行 pending、watch、mandatory non-watch，後兩次 transport error 後
  未 retry／merge／admin。這是階段與停止行為驗證，沒有模擬 merge success／cleanup／bounded repair。
- Provider stub 不驗完整 GitHub argv；Sonnet 在 merge-query 將本機 origin path 當 repo slug，故
  不能把 stub 成功當真 provider 正確性。Codex feature push 成功，但 sandbox 拒絕本地 tracking
  metadata，讀例外契約後確認 local remote SHA；不宣稱完整實機 shipping 驗收。
- 兩個獨立 fresh forward authority fixtures 缺 governance 引用檔，doc audit BROKEN；第一個亦
  漏綁 provider，發生真 gh 唯讀查詢。第二個確實綁定 stub，authority helper 另獨立判 worker
  candidate 含 STATUS 越界 STOP，且無 mutation。保留這些限制，不把 fixture 問題當產品 RED
  或正常 authority forward PASS。第三個只修 fixture 為最小完整 governance config，事前 audit／
  ship-state 均 OK；fresh subagent 完整讀六份必要 reference 後，在 worker／integration authority
  不一致處 STOP，要求 prompt-bound resume，沒有把 --merge 當角色授權。未提供後續選項回答；
  主 agent 核對 HEAD／工作樹與 local remote 不變、provider 無 create／merge。此受控修復沒有改 skill。
- 舊測試沿用 helper／changed-input／summary-only 機械契約未改，沿用 Scenario 38 的既有結果。
  新 `tested` case 只確認此次載入調整沒有跳過 helper。未測條件不靠 prose 推論已通過。

## 重建與原始 artifacts

本機根目錄皆在 `/tmp/`，是可重建的暫存 evidence，不是跨機權威。以下完整名稱附 `-20261004`：
`project-routing-baseline-noop`、`project-routing-candidate-noop`、`project-routing-candidate-tested`、
`project-routing-candidate-spec`（RED）、`project-routing-recovery-spec`、`project-routing-candidate-transfer`、
`project-routing-final-merge-query`、`project-routing-final-ship-pr`。
每包的 manifest、fixture.json、first.prompt.txt、first.command.json、first.jsonl／timed.jsonl、
summary／metrics 與 provider-calls.jsonl（適用時）可重建本表；終態另與真 Git／origin 交叉核對。
獨立 forward 在 `/tmp/project-routing-forward-{authority,isolated,valid}-20261004`；valid 保存
fixture-config.diff、preflight-audit.txt、initial-head／initial-status 與 provider-calls.jsonl。

```sh
# setup 不使用模型；run 才使用帳號額度。每次另取新的 eval-root。
python3 tests/project-reference-eval.py setup --root <eval-root> --revision <revision> \
  --case noop --models gpt-6.1-sol claude-sonnet-4-6
python3 tests/project-reference-eval.py run --root <eval-root> --once
python3 tests/project-reference-metrics.py <eval-root>
```

其他 case 為 `tested`、`spec`（加 `--truncate`）、`transfer`、`ship-pr`、`merge-query`。
未 commit 候選用 `--source <frozen-source>`；source 排除 pressure oracle。Normalizer 只核對讀取，
仍須人工核對 first mutation、summary、commands、provider log 與 Git，不能只讀 terminal verdict。

## 本機驗證

Codex quick validator、雙端 native entry、七個 offline metrics／transport／provider tests 已通過。
首次完整 parallel suite：integration 1157／0、ship_state 239／0、core 170／1；唯一 failing gate 是
doc-governance 真 corpus retrieval。Step 4 expected path 隨權威搬移更新，原查詢不變；router 保留
舊 Critical／Step 0–5 詞彙指標後，同一 targeted test 通過。

Core 補驗各維持 170／1，失敗分別是新 plan 缺 metadata、history 插入位置違反 append-only；
補欄位並改為末尾追加後，只重驗受影響的 current corpus 與 ship audit 兩個 tests，exit 0／2 passed。
其餘已綠 shards／core cases 沒有重跑。這是原 suite 加定向修復驗證的合併證據，未宣稱原 suite exit 0。
`audit --ship` 與 `git diff --check` 通過；workflow 檢索指標調整後，七個 offline tests 再驗亦 PASS。

原始 logs：`/tmp/project-routing-suite-20261004.log`、`/tmp/project-routing-core-20261004.log`、
`/tmp/project-routing-core-final-20261004.log`、`/tmp/project-routing-doc-final-20261004.log`。
目前 skill／test files 的 SHA256 與 interpreter 記於 `/tmp/project-routing-delivery-inputs-20261004.json`，
供下一個 Log 核對差異、沿用上述適用結果；此檔不是補造全套成功的 receipt，也不替代 required CI。
本機結果未 commit／push／發佈；下一次 shipping 需當批明示 endpoint。
