# #229 修後審查範圍設計

- 工作項：229-review-followup-design
- 日期：2026-09-24
- 狀態：implemented
- 種類：audit
- 需求來源：使用者要求接續完成能做的 #229 工作；本檔不重開既有已驗證改善。
- 結案邊界：本檔是已執行完的有界 audit／candidate attempt，不表示候選已採用或 #229 完成。
- Writer／Dossier Steward：codex:229-review-followup-design；workspace：branch=docs/229-review-followup-design。

## Execution record and scope

Read-only baseline：dotfiles `fecb12692c10c4c1ec78ad6077bbef278c985f12`，main clean；
krepo-common `25c25355c0686144f3f5907d2222581f60224583`，main clean。
後者只讀，不執行 production 查詢、測試、部署或修改其文件。
本輪僅建立本設計與 STATUS 工作項；未修改 skill、未執行新模型 eval。

作者設定依使用者要求為 Astra／medium；不將無法在此獨立確認的 host model identity 冒稱 runtime attestation。
下一次行為驗收沿用 GPT-5.6 Sol/high 與 Claude Opus 5；啟動時記錄 exact CLI／resolved model，
不能把前批版本視為新的已核對值。沒有 high escalation。

已合併的風險路由、同 session 接續、跨 runtime 本地改派、handoff 授權辨識及 terminal 顯示修正均保留，
不重新驗收。Reviewer 污染／transport 不在本候選修復範圍。

## Real-case evidence and causal limits

Evidence source 為 krepo-common 的既有權威 history，非目前重新執行 migration 的結果：

| Record / surface | 可支持的結論 | 不能據此宣稱 |
|---|---|---|
| `docs/archive/decisions-2026-09.md`：D-20260911-writer-runtime-scope-reset-review-no-go | 兩輪審查後，缺陷完整母體 roster 仍被列為 migration 前置；也發現 Judicial 人工匯入／撤下能力遺漏 | 第二輪 findings 全是無效或多餘 |
| 同檔：D-20260911-writer-runtime-defect-roster-not-a-migration-gate | 完整 roster 需要新增 crawl／host-state／telemetry，將明示移出的資料治理重新帶回；有直接 scope drift 證據 | 所有 current-population 證據都不需要；既有資料已健康 |
| 同檔：D-20260911-writer-runtime-scope-reset-corrected-review-go | 後續審查仍發現 exact identity DML proof、manual fence／retirement 順序等實質安全問題 | 可以刪掉獨立審查或只相信作者說已修好 |
| `docs/archive/decisions-2026-08.md`：D-20260827-migration-evidence-does-not-reopen-plan-gate | 已有先例：補 operational evidence 只決定直接相依 slice；契約／判準變更才重審對應範圍 | 任意縮小初次完整審查，或把 unknown 當通過 |
| dotfiles `shared/skills/deep-plan/references/workflow.md` §5；`shared/skills/deep-review/references/workflow.md` §6 | 修後要求 fresh reviewers 再讀相同 artifact／partition，排除前輪 findings 與 repair summary | 重掃一定是所有不收斂的根因，或已有量化節省比例 |

Disposition：scope drift **accept**；修後完整重掃的額外成本是 **待測機制假說**。
不能用「兩位 reviewer 都說要做」取代與本次契約的因果連結；也不能因為發現得晚就忽略真實 blocker。
本輪沒有取得 verification 重跑的新增規則根因；維持
`B-20260924-workflow-verification-economy`，不靠再加 always-on 停止口號修補。

## Candidate and decision boundary

2026-09-24使用者已明選建議方案，不再等待政策確認。先只處理 deep-review／repo-review 的 autofix
修後驗證，deep-plan 與初次／明確要求的第二獨立盲審不變。Write manifest 見 STATUS；正式 behavior
檔限 shared workflow 與 portable reviewer brief，兩 runtime entry、metadata、helpers、topology 不變。
已查 D-20260823-portable-deep-review、P5／P10／P15 與雙端實際 symlink：是已 portable skill，
canonical copy 在 shared/skills/deep-review；不是重新移植。P5／P15 的盲審 oracle 仍適用初次審查，
修後例外另由新增 P20 定義，不改寫歷史 live evidence。CLI 本輪核對為 Codex 0.155.1／Claude 2.1.280。

驗收預算：scratch `/tmp/issue-229-followup.BcfqNG`；同一 runtime-migration 多步驟 task，兩 primary
各 before／after 一次，各 600 秒、Claude 每次 USD 4；一個 reviewer／階段以免重複分工成本。
安全對照用同 task 的 faulty-repair snapshot，只測修後獨立驗證：兩 primary 與 Sonnet5 各一次，
各 240 秒、Claude USD 2。若 baseline 發現 harness capability 阻塞，記錄並不冒稱完整行為驗收；
不無限制追加重跑。衡量 native trace 的初次 coverage、修後 dispatch scope、實際讀取與修復、
終態／wall-time／tokens、repo diff／HEAD／index、無關工作追加與安全對照。

建議候選：保留初次完整獨立審查；修後用 fresh reviewer 驗修復、實際 delta、same-class occurrences
與跨 repo semantic dependents。提供可查證的 finding／修復位置作為檢索入口，不提供預定 PASS verdict；
reviewer 必須自行讀原始證據。發現新的具體契約／安全風險才擴大對應部分，不重新抽樣全部未變 scope。
未變既有債不自動成為修復工作，但新改動使其影響、可見性或恢復能力改變時，仍可成為本次 blocker。

這會改變既有「修後仍盲審」的 bias／cost 取捨，不能當作純措辭修正。
使用者已選上述機制；不再等待原本的選項回答。正式採用仍須通過本候選的行為驗收。

本候選只選 code review lifecycle，不同時改 plan 與 code 兩套流程。
確切 write manifest、原生 runtime entry、既有 eval 衝突與安全 oracle 必須在該候選啟動前記錄；
本設計不預先授權所有 shared review 檔案，也不重啟 P18／P19 措辭候選。

## Bounded acceptance design

Baseline 發現獨立 prerequisite：Sol 在 scope capture 的 append_paths 重新開啟 /dev/stdout 時遭
sandbox 拒絕，原樣 PTY 亦失敗，未到 reviewer。非 sandbox control 同 repo capture 成功。
用 macOS sandbox-exec deny /dev write、只允許 /dev/null 重現同一 line 72／exit 1；只拒 literal
/dev/stdout 不足以重現，不能用該 control 冒充 RED。先修成 inherited stdout 寫出、不重開 device，
保留 byte-for-byte fingerprint；不改 sandbox 權限。增補 tests/run.sh 的 sandbox capture／identity／
verify regression，scope 僅增 helper 與此 gate。與 review 策略分開歸因。
原 Sol before 留作 capability baseline；helper 修復後用同 helper 重新建立 before／after 配對，
不是重跑已確認的 review 行為失敗。Opus 原 before 可用於 helper-independent 觀察，但配對亦用
相同 helper，避免混淆因果。只補此一次有修復證據的環境控制，不追加候選或擴張 transport 調查。

只用一個取材自上述案例的多步驟、跨契約 task，固定初始缺陷、非目標舊債及驗收條件。
初次審查應發現實質能力／介面遺漏；修後驗證同時檢查其 semantic dependents，並保留一個修復引入的
安全回歸對照，避免「少看一些所以更快」冒充改善。不是重播已完成的小型 continuation fixture。

正常 arm：完成已授權修復，沒有證據時不追加 roster／無關治理；既定 evidence 通過即停止。
安全 arm：修復破壞 manual capability 或 fence／retirement 順序時仍擋下；必要事實未知不可 PASS。
作者宣告、fixture suite 綠燈及 reviewer 字數都不能取代這兩項行為證據。

同一來源隔離複本、同 query／raw artifacts、同 model settings、每 primary 每 before／after 各一次；
在啟動前固定 wall-time／費用上限及實際 oracle，不在看結果後重設。記錄完成／未完成、成本、
dispatch／repair 次數、新 findings 的契約關聯、無必要 STOP、scope additions 與實際檔案差異。
一次觀察不能宣稱大型專案統計改善；若任一 primary 或必要安全 arm 未通過，不安裝候選，
保留限制與重議條件，不追加第二串措辭或 probe 洗綠。

## Completion and next action

過程證據：Sol 的 JSONL stdout 未列 spawn 明細，但其 exact session rollout 有
collaboration.spawn_agent、fork_turns=none 與返回 task name；不能把 stdout 的 wait 空 receiver list
解讀為沒有 spawn。Rollout 的 message arguments 加密，無法據此逐字 attestation reviewer prompt；
此限制如實保留，不擴張調查既有 transport root。

Safety harness correction：原 Claude permission-mode=plan 會觸發計畫產物流程，與唯讀 reviewer
測試不相容。Sonnet 原 run 正確識別未修 fence，卻以 Bash 寫 runtime plan；該 run 作廢為
模式污染證據，不當成安全 GREEN。唯一產物已從 runtime plans 移至 scratch 的
sonnet-safety/invalid-plan-mode-output.md 保存；同模式 Opus 在 66.421 秒停止、未完成，不算行為失敗。
改用 default permission mode 與相同 read-only query／工具、fresh fixture，只補正常 reviewer 模式的
Opus／Sonnet arm；不改候選 prose。兩者 133.061／134.471 秒、exit 0，均獨立執行並擋下未修 fence，
repo diff／HEAD 未變。Opus 另列非法 operation 的 low 建議；契約輸入已限定枚舉，該建議不支持
擴充本次實作，且 reviewer 未將其 blocking 或修改 repo。

Sol safety 240.021 秒 timeout／SIGTERM：已用 python -c 重現 manual fence 缺陷，最後 commentary
明確說未修；但未產生完成的 terminal report，故不能標整個 arm PASS，也不加時或重新啟動洗綠。

同 helper 的正常路徑：Opus control 414.243 秒、after 353.528 秒，均正常 exit 0、一批修復、兩次
fresh dispatch、沒有額外授權問題或非目標修復；CLI cumulative cost USD 2.473603／2.0124495，
modelUsage outputTokens 31697／30203（含 nested activity，不加總重複的 session 累積值）。
初次 scope 都涵蓋全部 changes；after 有來源快照及 repair-verification dispatch，final 誠實區分
discovery／repair verification。Root 獨立語意矩陣、suite（9／8 tests）、HEAD／index／scope check
均通過。不能由單次、極小規模 fixture 宣稱大型工程效率提升；after packet 仍把 legacy.py／ui.py
列成待查 dependents，未嚴格證明所有未變無關區域都免於重看。沒有把該 low input-validation 建議納入修復。
Sol 同 helper control 600.077 秒 timeout，已修復且 root 語意／suite（5 tests）通過，但流程未完成；
原 helper before 600.076 秒 timeout 留作混有 I/O recovery 成本的觀察，不用來量化候選收益。

正式 helper 已通過 sandbox RED→GREEN、相同 fingerprint 與 FRESH verify；兩 runtime entry validators
通過，完整 tests/run.sh 1494 PASS／0 FAIL、139秒、exit 0。保留這個獨立已驗證修復。
審查 workflow／brief 候選仍只在 scratch：雙primary完成門檻尚未成立，不因 Opus 的 PASS 安裝。
Sol after 最終 600.026 秒 timeout／SIGTERM，已建立來源快照、修復後 manifest 並進入 fresh repair
verification，但未收到可完成流程的終態。Root 語意矩陣／suite（5 tests）exit 0、HEAD／index 與
未授權檔案邊界通過；這些正確產物不能替代未完成的獨立複核。原始記錄都留在 scratch，沒有 retry。
最終 disposition：helper **accept**；修後審查候選 **not adopted / incomplete**，不否定使用者選定方向，
也不宣稱策略造成 timeout。正式 workflow／brief 無 diff；既有 P5 隔離規則不改。
control／after 四份 helper 實體副本與正式 source SHA256 均為
`6327c0ade87e708623e39d37909cbfab5bf246686b88c53672ebb614a6820aa1`。
剩餘工作回到 B-20260924-workflow-review-residuals；須有日常實例或新的可檢驗機制／runtime completion
證據才重新進入驗收，不對同一 packet 加時／重試。沒有新的必要使用者決策，不要求再次「繼續」。

本輪準備完成不等於 #229 完成，也不代表新機制已驗收。
文件驗證：初次 audit 指出缺少「種類」metadata，補為 audit 後通過；doc-governance audit --ship、
git diff --check 均 exit 0。新增 Markdown 後依 repo 契約執行一次完整 tests/run.sh：1491 PASS／0 FAIL，
138 秒、exit 0；這是文件／repo 回歸檢查，不是新候選的行為或效率驗收。
本輪已依選項直接接續，沒有再次要求同 scope 授權。commit、push、merge、部署不包含在此工作中。
既有 backlog 兩項均保持未結案；本檔於 bounded delivery 後凍結。
