# Deep-review primary responsibility 與 aggregate subject 投影修復

- 日期：2026-10-07
- 狀態：implemented
- 種類：implementation plan
- 需求來源：[STATUS.md](../../STATUS.md) 的 #274 active contract
- 工作項：#274；驗收權威：`STATUS.md`「3. Deep-review reviewer 分工投影修復（#274）」
- Writer／Dossier Steward：`codex:runtime-layout-convergence`
- Workspace：`branch=fix/deep-review-primary-responsibility`
- 授權：使用者「開工」允許本地實作與驗證；外向 endpoint 未授權。

## Primary responsibility 的 root-cause baseline

既有雙薄入口已 portable：兩端 references／scripts 的逐檔 links 都解析到
`shared/skills/deep-review/`，eval oracle 只有 neutral core 一份。維持 topology、ordinary defaults、
immutable manifests、一次性 ticket、fresh identity 與 attempt history，不重寫這些已驗契約。

#274 的三份原始 packet checksum 已核對；各自 scope 都有相同 39 subjects、paths=[]。
現行 admit 的分工 schema 只有 id／repos／concern，第一個資料缺口發生在 path responsibilities
無法進入 controller 驗證的 boundary；renderer 接著按 repo 複製 broad subjects。
`tests/review-primary-scope.py` 的原始重現已取得 RED（exit 1）：含 12／14／13 paths 的 concern
自由文字仍被當成有效 full-route 分工，沒有機器可驗的 bounded ownership。
原始 RED log：`/tmp/project-274-primary-red.glt0dE`；可重建命令：

```text
python3 -B tests/review-primary-scope.py <repo-root> PrimaryScope.test_shared_repo_free_text_partition_is_rejected_before_spending
```

此命令在修復後應轉 GREEN；同機舊 NC controller、nonce、journal、attempts 保持唯讀。

## Controller admission 與 packet projection

1. Assignment 的 primary 以 canonical repo → exact subject paths 表示；只接受 manifest 內的 paths。
   完整聯集、同 repo primary 互斥、型別、重複與 repo 邊界在消耗 ticket 前驗證。
   單 reviewer／互斥 whole-repo 舊分工可無歧義展開；共用 repo 的多 reviewer 必須明示 primary，
   不從 concern 猜 paths。Ordinary 仍只有一位 reviewer 且涵蓋整個 subject。
2. Packet 的 aggregate scope 保留全部 manifests 的 immutable facts；primary_scope 單獨列責任 paths。
   semantic dependents 可跨 primary 邊界讀取，不把其他 assignments 的未查區域當成自身 coverage 缺口。
   cross-repo interface assignment 可明示兩 repo 的 primary paths，其他 primary 分工仍互斥。
3. Renderer／brief／native prompt 共用 responsibility 語意；result set 仍必須完整當前 set。
   Subject／packet drift、partial／duplicate／incomplete／reused result 維持 fail closed，失敗不退票。

## Readonly diagnostics 與 native evidence

Canonical brief 說明 static、可安全執行的 readonly probes、原始 execution artifacts 的證據邊界。
診斷命令必須保持 target／Git metadata 唯讀；read-only sandbox 的 scratch 或 socket denial 保留原狀與
實際 status。必要 facts 已由 static／原始 artifacts 查明時可完成；required execution fact 仍缺時 incomplete。
不給 reviewer desired verdict、不隱藏 permission errors，也不放寬 sandbox 或把 author tests 當 independent PASS。

Native transport 保留真正 process／thread IDs、raw logs、原始 structured reports 與 hashes；本身啟動的
native dispatch 必須用相同 proof gate 收集，不能在 off-mode 被作者拼裝 finish 替代。
原始 incomplete structured report 在 admission 前也要落盤保存，避免只留下 trace 而遺失可直接檢查的 report。

## Validation 與 blind forward testing

- Deterministic：39-file 12／14／13、2-way、跨 repo interface 正向；missing／overlap／outside／wrong-type
  primary 的派遣前拒絕；ordinary whole subject；subject／input drift、partial、incomplete、duplicate／reused IDs。
- Native：在全新 isolated fixtures 走 admit → dispatch → 原生 reviewer → result／aggregate admission。
  覆蓋 2-way、3-way、cross-repo responsibilities，以及 required fact 缺失的反向；保留每次 failed attempts，
  不重建同一 live batch 來洗綠。兩端按 repo production-target policy 驗同一 raw fixture／oracle。
- Fresh forward test 只供 runtime entry、raw fixture 與使用者請求，不提供 bug、候選修法、expected result 或 eval oracle。
- 實跑 controller／transport regressions、兩入口 skill validator、doc-governance／xref 與 `./tests/run.sh`。
  有真實新 failure 才修正並重跑受影響檢查；既有 unrelated fixtures 不改成適應新答案。

## 進度與完成條件

| Active contract AC | 已保存的驗收證據 |
|---|---|
| 1 | 原始 39-file／12–14–13 projection RED exit 1；原 NC packet digests 核對，舊 batch 未消耗新輪次 |
| 2 | 11 項真 controller regression；disjoint complete primary 聯集、漏／重複／越界／錯型拒絕；每 packet full aggregate 一致 |
| 3 | 雙端 two／three／interface 原始 reports 與 valid global sets；c4/c5/a5 只有缺 own ABI evidence 的 child incomplete |
| 4 | 既有 controller／turbo 回歸與新 primary gates；12 組 fresh native process／session inputs、reports、trace、journal audit；failed attempts 不重設 |
| 5 | Actual denied commands／status、write-free／static facts；a4 bytecode RED、f0–f3 metadata RED 保留；f4 完整 pre-first-call target／Git snapshot 一致 |
| 6 | 8 positive native sets、3 expected required-fact BLOCKED、1 preserved readonly RED；f4 blind fresh orchestrator 與兩位 reviewers 的完整流程 |
| 7 | 雙入口 validator、單一 shared core／ordinary defaults 不變；11／23／48 定向 checks 通過；最後完整 suite exit 0、1575／0；治理／xref 通過 |

2026-10-07：原始 projection RED 與 incomplete structured report 遺失的 RED 均已保存後修復。
11 個 primary regression、23 個既有 controller regression、48 個 turbo checks、雙入口 validator 已通過。
雙端原生 2-way／3-way／cross-repo 六個 positive cases 通過；Codex required-fact c4 正確保留
complete／incomplete／complete，attempt=1、valid_sets=0、BLOCKED。Claude a4 同樣分出必要
facts 缺口，但 isolated Python 忽略環境變數防護而寫 ignored bytecode；snapshot guard 已阻擋，
原 cache／reports／failed set 保留。獨立 interpreter probe 取得 RED 後收斂 explicit -B／in-memory
probe boundary，fresh c5/a5 的 required-fact cases 正確 BLOCKED，content／mode snapshots 一致。

Blind forward f0/f1 的後補 metadata 檢查另發現 index mtime 變更，隔離 Git probe 重現 RED。
f2 顯示 brief 載入晚於首次 Git inspection；f3 顯示 reviewer 在讀 brief 的同一 tool call 就執行
Git commands。各批原始 identities、reports、attempts 與 drift 原狀保存，未重建同批來洗綠。
Canonical brief 要求第一個 Git inspection 起停用 optional locks；adapter／workflow 與
renderer／native prompt 先獨立讀完整 references，返回後才開始 target inspection。
Fresh c6/a6 原生雙端 2-way 各有完整當前 set、valid_sets=1、PASS。Fresh blind f4 的
orchestrator 與兩個 reviewers 完成完整流程，parent 的 pre-first-call 全 entries snapshot
(content／mode／size／mtime_ns，含 Git files／dirs) 逐項一致，原始 reports／journal 已核對。

Native parent audit 共 12 cases／32 fresh native identities，8 positive PASS、3 expected
required-fact BLOCKED、1 preserved readonly RED；各版 frozen source 沒有回寫。
Facts：`/tmp/project-274-native-acceptance.json`，SHA256
`5179ade2e378e99528745503615a58b93132dc7db80b312e8cd4d13bee4f19b5`。
Blind f4：`/tmp/review-primary-forward-20261007-f4/parent-preservation.json`，SHA256
`f0dce3064f1da98b90916bb9ce84d9a46f58edaec7d7cef232d303b7fef9bf9a`。
Raw roots、重建命令、model metadata 與判準見 canonical P23 eval；Codex native default 的
resolved model／effort／service tier 未曝，記 not exposed，不猜具名模型。Claude 實際
claude-opus-5-5[1m]／high(argv)／standard(usage)，CLI 2.1.291。

完整 suite 已曾通過 1575／0；最後 loading 版 suite 取得 1574／1（exit 1），唯一失敗為
thin adapter 32 行超過既有 30 行 gate。雙入口只調整換行，逐 token／mode 與 native-tested
source 相同，回到 29／30 行；isolated gate 與雙入口 validator 通過，未放寬判準。
修後完整 suite `/tmp/project-274-packaging-final-suite.log` terminal exit 0、1575 PASS／0 FAIL，426s。
Python AST 4／4、雙入口 validator、doc-governance ship audit 與 xref 均通過；unrelated runtime-layout
active item 與 HEAD 的對應區塊逐字相同。7 項 AC 的本地驗收證據齊備，本 plan 標 implemented 並凍結。
Authority：executor／durable steward／authority actor 均為 `codex:runtime-layout-convergence`，
source `active-writer-workspace-match`、verdict PASS，fingerprint
`94fa4251025f212125f69be135a3594d8e989ed7b584aae491158a59cea433a5`。
里程碑 M-20261007-deep-review-primary-local；仍留 active delivery pending，尚未 commit／push／PR／merge／部署。
原 NC live batch 未重跑；未執行本批 GitHub 雙 OS PR CI，不將本地驗收冒稱外部交付。
