# 小幅變更的驗證與交付成本改善（#285）

- 日期：2026-10-08
- 工作項：issue-285-workflow-verification-economy
- 狀態：in-progress
- 種類：implementation
- Writer／Dossier Steward：`codex:brewup-bun-global-update`
- Workspace：`branch=perf/workflow-verification-economy`
- 基線：`92dc1b9c6e6a836146606d3cee12edd2505ecef6`；起始唯一未提交變更為本 session 建立的 #285 spec。
- 需求來源：[GitHub #285](https://github.com/jjshen-eland/dotfiles/issues/285)。使用者已授權開工；2026-10-08 續以 `$project --merge` 授權本次 invocation 的候選交付，部署不在範圍內。

## 診斷與證據邊界

1. 原事件的 bun RED 跑整個 runtime shard，664 PASS／5 FAIL、108 秒。
   從固定 `92dc1b9` 的 `tests/run.sh` 原樣取出 18d 的 fixture 與 assertions，沒有改 oracle，
   對 `27fc2ad` 的舊 brewup 得到 29 PASS／5 FAIL、exit 1、6.895 秒；
   對 `92dc1b9` 的 brewup 得到 34 PASS／0 FAIL、exit 0、5.828 秒。
   這證明同一組失敗與成功 controls 可有界驗證；現行正式入口只有 shard，無獨立 18d 入口。
   新入口只能用來快速取得受影響行為的 RED／GREEN，不能冒充全套、xref 或部署驗收。
2. 本批真實 serial evidence 的 helper check 輸出 19,475 bytes，其中重複列出 443 個已在 record 的 inputs。
   保留 command、verdict、完整 changed_inputs、reason、environment，加 input_count 的摘要為 228 bytes。
   原 verdict 為 NEED_TEST，差異為 STATUS 與 milestone 文件；此判定不得因輸出縮小而改變。
   機械控制可量測冗餘輸出；尚不能把整段 9 分 46 秒歸因於輸出量或預估等額 wall-time 收益。
3. 原始來源只保存 frozen patch／raw logs，shipping 需從固定 base＋patch 還原。
   原工具 trace 同時保存 exit 0 與測試期間 patch 未變的核對，是該次還原的 provenance；
   日後應在實際執行時保留完整原結果與必要來源快照，避免再重建，不補造過去 snapshot。
   Directory symlink 展開後的 __pycache__ 差異來自呼叫端過寬的輸入選擇，並非 helper 忽略來源變更的 bug。
   不直接排除所有 ignored 檔；來源、fixtures、相關環境與 link topology 仍由呼叫端查證。

原始 artifacts：`/tmp/workflow-285-diagnosis-sno29yxk/{before.log,current.log,brewup-group.sh,diagnosis.json,helper-check-full.json}`。
重建 18d control 使用上述 immutable Git blobs 的 `ok`／`bad`／assert helpers，及 18d 開頭到 all-up 執行位 assertions 前的原樣區段；
只將 BUP 指向指定 immutable brewup 副本。HOME、DOTFILES_DIR、PATH 與所有套件指令維持原 fixture 隔離。

## 最小修正順序

1. 把既有 18d fixture／assertions 抽成單一 canonical 測試入口，完整 runtime 繼續呼叫同一份，
   提供明確的本地獨立 invocation。先保留舊實作 RED、目前實作 GREEN，再驗全套集合與結果計數不漂移。
   不建立依賴 selector、不根據 diff 自動略測、不修改 hosted CI 或 branch protection。
2. 為既有 read-only evidence checker 增加有界的摘要輸出選項，Log 使用該選項；
   保留既有完整輸出相容性、原始 evidence、完整 changed_inputs 與 exit／verdict 語意。
   Snapshot 輸出不得被摘要裁掉。先固定 large-input、unchanged、changed、unknown、error controls。
3. 針對實作階段缺乏原始 evidence 的 observed gap，先用既有 snapshot primitive 保存實際驗證前後來源，
   原 command／exit／output 保留於當次 artifact；用 native ordinary-script／docs-closeout／reuse controls
   判斷最少需要修改的 always-on 指引，不先建立 cache、receipt framework 或新的永久 store。
   任何新指引須有 before failure／after behavior 證據，不以文字完整性或縮短字數驗收。

每個因果修正分別固定 RED、驗 GREEN，再做下一個；只調整該修正影響的案例。
最終因涉及 runner 抽取，依既有契約做一次 serial／parallel 對照；此目的不可泛化為普通腳本變更的雙重驗收。
固定最後程式／測試輸入後保存證據，收尾文件按實際差異補治理／xref，不再無條件重跑兩套。

## 寫入協調與預定路徑

2026-10-08 使用者選擇將本批必要 tests/ 與 testing contract 寫入交由 #285；原 Runtime writer 保持停止。已於 STATUS 更新兩項的 scope，沒有接續 Runtime 產品目標。
最小修正將涉及 `tests/run.sh`、`tests/project-test-evidence-test.py`、必要的新 18d 測試入口，
以及 `docs/testing-contract.md`；若實際 aggregation accounting 改變才動 `tests/shard-manifest.tsv`。
這些路徑的本批寫入已交給 #285；原 Runtime scope 暫移除共享 tests/ 與 testing contract，後續另依 assignment 協調。

其餘可能改動限於 `shared/skills/project/scripts/test-evidence.py`、受影響的 Project references／behavior oracle，
及經 native RED 證實必要的 root `AGENTS.md` 驗證指引。兩 runtime 的既有 entry／shared linkage 保持。
無關 skill、Runtime 產品契約、機隊部署與 #279 selector 不納入。

## 驗證與完成條件

2026-10-08 事件：抽取入口的兩個 reproducing tests 先以缺入口 exit 127 失敗，修後兩例 PASS（11.444 秒）；
新 evidence controls 在缺 `--compact` 時 RED，實作後 15 tests PASS（6.168 秒）。
對實際 443-input record，完整／compact 都為 exit 1 NEED_TEST、changed_inputs 完全一致，輸出 19,894 → 648 bytes；
目前變更多於初始診斷，不能拿這筆 648 冒充最初未改動時的 228-byte projection。

Project 為已 portable：雙入口／references／templates／test-evidence helper 都解析到既有 shared core；
Claude scripts 逐檔 link、Codex scripts 目錄 link，拓樸不變。沿用 D-20260825-portable-skill-authoring-default、
M-20260822-portable-project-skill 的 baseline，無 migration 或 ownership 變更。

Native before：`ordinary-script` 的 Codex gpt-6.1-sol 真實執行 focused RED、serial GREEN、parallel GREEN、doc；
兩個完整入口跑同一集合，該批沒有 runner 變更，故冗餘完整執行 RED 已重現。Opus 同 fixture 只跑一次完整測試，
不把其 baseline 成功當新增收益。兩端都沒有保存綁定 dirty 測試來源的前後 snapshot，原 tool results 保留在 trace。
`docs-closeout` baseline 兩端都能沿用既有證據，不重跑完整測試；Codex 跑兩次 doc gate、Opus 一次，
此正常控制不宣稱有新的 native wall-time 收益。原始 roots `/tmp/workflow-285-before-{ordinary,docs}`。

Native v1 ordinary 的 Opus RED 保留：先用 zsh scalar 組 input argv，snapshot 失敗仍繼續跑完整測試；
其後改 array 重做快照又重跑 suite，原 trace 為 2 focused／2 serial／1 doc，final 卻稱完整一次。
另一次 rm 變數清理被 host 拒絕後改用 fresh temp，沒有在真 repo 重試拒絕指令。
根因為保存階段未 fail fast；最小修正要求測前 snapshot 成功且 JSON 有效才啟動完整測試。
只重測受影響 ordinary 分支，其他 controls 用原 v1 實態驗收；不把新結果覆蓋 v1 RED。

Native v2 ordinary 雙端 PASS：完整測試各 1 次，真正受測的 dirty 來源前後一致，原 result 經 helper 重查為 REUSE。
Codex 190.082 秒／Opus 67.141 秒；before 86.313／34.961 秒。小 fixture 的完整測試近乎即時，新增來源保存
增加模型成本，因此只證明重複全套消除與 provenance，**未證明 native wall-time 改善**。
docs-closeout 兩端零新完整、各 1 doc；Log reuse／changed／unknown 新測試次數為 0／1／1，各端實際 compact check，
12 reader calls／七份 refs 完整、normalizer errors=[]。這些必要 refs 不縮減；Codex reference_s 為 59.764／83.670／93.045，
Opus 為 46.688／50.776／65.216 秒，仍為可觀固定成本，沒有新的 RED 證明可刪除 required 讀取。
本批不用假定的 shipping／CI 時間宣称解決整段 15 分鐘；後續需要真實交付分段再量。

Canonical linkage／兩 native entries 通過实际 CLI 使用；Codex quick validator PASS。相同 Codex validator
仍拒絕未修改的 Claude-native `argument-hint`／`disable-model-invocation`／`user-invocable` frontmatter，
這是既有適用範圍差異；Claude entry 以原生 CLI 與 repo packaging gate 驗證，不刪掉 native metadata 冒充 validator PASS。
Python 3.14／3.9 的 evidence 15 tests PASS；ShellCheck、CI confidence 11 tests 與 metrics 7 tests PASS。

- 同一組 18d assertions 對舊實作維持 5 FAIL，對目前實作維持 34 PASS；真實 HOME／套件未受影響。
- Evidence 摘要模式與完整模式的判定及 changed_inputs 一致；large-input 輸出省掉重複 scope。
- 未知／失敗結果、source／fixture／mode／必要 link target／環境漂移維持拒用；ignored input 仍受測。
- 必要 Claude Code／Codex production-target behavior controls、validator、完整 runner 對照及治理／xref 通過。
- 記錄各階段實際命令、來源 revision、輸入、exit、操作次數與 wall time，分開報告機械收益、native 收益與未驗邊界。
- 不自行 push／開 PR／merge／部署；本地完成依 repo 與 skill authoring 授權邊界回報。

2026-10-08 最終本地驗收：一次 serial／parallel 對照各 exit 0、1578 PASS／0 FAIL；
wall time 分別 453.544499／137.808644 秒（同機有重疊執行，不相加也不用於前後效能結論）。
各 run 前後 695 個來源與 environment facts 一致。Runtime 保留 669、core 175（新增一個入口控制），其餘 shards 不變。
Artifacts `/tmp/workflow-285-final-verification/` 保存各自 before／after、原 log、exit／wall summary、完整 evidence、
code-input projection 與 environment；另保存與實際受測內容一致的 candidate-tested.patch、四個新檔的 content／mode。
Code projection 不涵蓋 STATUS／docs，不能冒充全部文件也已驗；結果補記後另補 fresh 治理／xref。
這批必做 runner parity，不能用本批兩套完整執行反過來要求未改 runner 的普通變更也跑兩套。

本地候選的程式與受測指引固定；無 commit／push／PR／merge／部署。保留 STATUS active contract，
plan 維持 in-progress，待本批具名交付後以真實分階段時間完成 #285 的交付成本驗收，不先關 issue 或移除 assignment。

2026-10-08 交付準備：使用者明示 `$project --merge`；沿用原 serial／parallel 的 code-input projection，
fresh helper 各 exit 0 REUSE、environment matched；完整 inputs 的差異僅 STATUS、本 plan 與本地 milestone，
這三份結果補記改以 fresh 治理／xref 驗證。保留 active contract 與未結案 backlog，PR 使用 Refs #285；
必要 reference 讀取與 native wall-time 未改善的限制仍有效，尚未發生的 endpoint／效能不寫成已完成。

交付實測與接續驗收（2026-10-08）：

第一批已由 PR #287 rebase merge 到 origin/main，commit 112d37de7bdc2854f6a7d49e6e20a17bb4be3f57。
Required CI Ubuntu 116 秒／macOS 197 秒，均一次成功；本地全套新增 0 次、CI 修復提交 0 次。
本機 main 同步與本支清理完成，續行 dotsync 為 local=ok、remote_ok=14、remote_failed=0、exit 0。

原始 session 現可核對完整邊界，取代先前只能提供的時間下界：使用者 merge 指令
2026-10-08 18:03:11.481 → 最終回報 18:23:29.878（Asia/Taipei），1218.397 秒。
ContextCompaction host event 的 started_at_ms／completed_at_ms 為 1791453866460／1791454252835，
直接 duration 386.375 秒；不是把沒有工具輸出的空檔猜成 compaction。

| 階段 | wall seconds |
|---|---:|
| 指令到 compaction 開始 | 74.979 |
| ContextCompaction | 386.375 |
| 恢復到建立 PR | 400.165 |
| PR 到 merge（含 CI） | 256.000 |
| merge 到本地同步與清支觀測 | 25.000 |
| 同步後補量測紀錄到最終回報 | 75.878 |

直接扣除 compaction 為 832.022 秒，只是算術分解，不是無 compaction 的對照。
恢復段有 10 次 reader calls（包含一次錯誤 argv）；六份先前已讀 refs 因內容只剩摘要而重讀，
另外 ship-paths／merge-workflow 首次載入。整段 reader／entry 恢復約 43 秒，不能把 400.165 秒全歸讀取。
其餘 trace 包含檔案／原證據查證、文件更新與 staged diff、尾端空白修正與受影響驗證、錯誤 OID 的
authority 重查、PR body／Ship 摘要及 push。這些區間包含模型決策與工具往返，不當作單一腳本執行時間。

已確認的執行缺陷為 staged check 非零後仍 commit、dependent HEAD 查詢與 gate 被併入同一平行群組，
其中 gate 使用了並非 Git 輸出的 OID。既有 exit／先決條件與相依操作紀律已能禁止這兩種行為；
不能僅凭單次 primary 的偏離就堆疊新 prose。下一項驗收先用隔離的已驗收／待本地提交案例，
在固定 92dc1b9 與 112d37d 的 source 上比較真實 preflight／commit、證據沿用及 wall time。
Prompt 只給 task-local scope、原始結果與 repo 先決條件；不給期望策略。若 native controls 已遵守規範，
保留 production 失敗與正常對照，不為無 RED 的路徑改 skill。

原始 session：/Users/jjshen/.codex/sessions/2026/10/08/rollout-2026-10-08T15-08-21-01a11a57-75bb-7da1-b85e-9714aaa2952f.jsonl。
Normalized timestamps／host event：/tmp/workflow-285-final-verification/shipping-session-measurement.json；
GitHub PR #287／Actions run 37762509491 保留 remote-visible 交付與 CI 證據。
這是已發生的里程碑補記；#285 保持 in-progress，不能以平台等待或新的單次 sample 宣稱 latency 已修好。

接續控制結果（2026-10-08）：原生 gpt-6.1-sol 在固定 before=92dc1b9／after=112d37d 的
Project source 上完成同一個已驗收、只待 README 結果補記的本地提交案例。兩端保留原始結果與
interpreter 適用性，helper 實際 exit 0 REUSE、新測試 0 次、feature branch 一個 README commit、
working tree clean、遠端 refs 未變；source hashes 無漂移。各有 12 reader calls／七份 refs，行號、
固定 SHA 與完整 EOF 正常，未縮減必要讀取。Before 工具呼叫 22 次、耗時 130.384 秒；after 19 次、
103.022 秒。兩輪同機並行且只有一組小型 legacy fixture，不包含真實 PR／CI／compaction，
不能把這筆 27.362 秒差額外推成生產交付收益。

Before 在工作樹發現檔尾空白、先修正再 stage，cached check exit 0 後才 commit；after 的首次
cached check exit 2，修正後 exit 0，再以成功先決條件才 commit。兩端都沒有重現原 merge 的
忽略失敗提交，這個控制僅證明具名先決條件能正常遵守，不證明所有場景皆安全。根因狀態為：
原 production 的執行紀律偏離已確認；剩餘 400.165 秒全部成本與可泛化的 latency 修復仍未確認。
因此本輪未修改 skill、runner 或新增規則，也未重跑完整 suite；issue 驗收條件 1 保持未完成。

先前 workspace-write fixture 阻止 Codex 寫入 .git，不能比較正常提交耗時；保留失效樣本而不計入
有效對照。該輪 Opus 同時有 stdin 額外內容污染，不當作正式 wall-time 比較。有效 Codex 對照改由
isolated fixture-shell 提供正常 Git metadata 寫入、完整 stdout，driver stdin=/dev/null；沒有放寬
真 repo 的 permission 或 shipping 授權。原始 runs：
/var/folders/t5/4b3mtjj52fvdplz5f15mf_ym0000gp/T/workflow-285-prepared-git-m0lufq12；
normalized grade：/tmp/workflow-285-final-verification/prepared-closeout-grade.json。
本輪 issue／STATUS 已回填第一批交付事實；本地三份結果補記尚未 commit／push／PR／merge／部署。

2026-10-09 接續量測：以原始 session 的 custom_tool_call／output 與 CommandExecution 時間戳，
核對恢復 18:10:52.835 到 PR createdAt 18:17:33.000 的 400.165 秒。

| 操作區段（依事件邊界） | wall seconds |
|---|---:|
| Entry／references 恢復 | 42.822 |
| 盤點、證據查證、文件更新與 staged 檢視，到首次 commit | 169.738 |
| 檔尾空白修正、受影響驗證與第二次 commit | 111.412 |
| HEAD／authority 修正與 PR 準備 | 43.311 |
| Push 與 PR 建立 | 32.882 |

區段總和 400.165 秒；只描述執行順序，不能當作各項都可消除的成本。30 次 tool call 的
call 到 return 合計 13.324 秒；背景命令會跨越 return，因此合併去重可見 call／背景區間後為
21.235 秒，剩餘 378.930 秒位於區間外。區間外包含指令準備、結果處理、回報及 host／模型排程，
不能冒稱純模型思考，也不能把只有零寬記錄的命令當成已量得完整 subprocess 時間。
PR createdAt 為秒級精度；所有區間在該邊界截斷，不把建立 PR 後的時間混入前段。

可核對的額外往返包括：盤點整批權威文件與完整 evidence 的輸出截斷（call index 11），
首次大份 staged diff 輸出截斷（index 17）；其後各有局部重讀。一次空白修正與第二次 commit、
錯誤 HEAD 的 authority 重查保留原失敗。這支持縮小輸出及正確處理相依／失敗結果的執行安排，
但既有規範已涵蓋，正常 native 控制未提供新增 prose 的 RED；本輪無程式或 skill 修改。

量測終態為 UNCONFIRMED：剩餘區間內的成本來源仍不足以完整歸因，未證明 latency 已修好。
下一個可核對證據為新批真實交付的 tool／背景區間與 PR／CI／merge／回報時間戳；若只交付
這三份結果文件，scope 與先前 15-file 實作不同，不能用整段差額冒充同規模改善或直接關閉 #285。
目前只有本地續作授權，push／PR／merge 需新批具名授權；過去 PR #287 的 merge 授權已完成。
Artifact：/tmp/workflow-285-20261009-call-timeline/timeline.json，包含原 source SHA、精確區間、
操作命令、exit、output bytes／截斷標記與合併區間；未建立永久快取或新治理 store。

2026-10-09 交付準備：使用者明示新的 `$project --merge`，本批僅三份結果文件，Refs #285、
保留 active／backlog。原 serial／parallel 環境與當前一致；helper 判定唯一 code 差異為
tests/lib/assertions.sh 檔尾一個 newline，原 affected record 的 34 PASS 經 helper 重查為 REUSE、
environment matched，舊 full 結果不冒稱來源完全相同。前批 required CI run 37762509491 在
557bae361df6275686674f8d0d57e599b7c95cbc 已雙 OS success；本批仍需自身 PR HEAD 的 required CI。
結果補記只補 fresh 治理／xref；當前 endpoint pending、不宣稱已 merge 或 latency 已改善。

## 完整退版（2026-10-09）

使用者明示：「退版吧，有做比沒做還糟。所謂有收益的部分，為了僅留下他，又要跑一大串測試，沒什麼意義」。
本批完整撤回 PR #287 的實作與後續空白修正，不再切分保留局部功能。
固定還原基線為 `92dc1b9c6e6a836146606d3cee12edd2505ecef6`；十二個非紀錄路徑逐一比對內容與 mode，
其中三個新增測試檔應消失。保留 `bun update -g`、#279 與已提交的所有 history／量測。
退版驗收是完整還原及必要測試通過，不宣稱已證明生產端到端耗時改善。

原新增流程的普通腳本控制 Codex 86.313 → 190.082 秒、Opus 34.961 → 67.141 秒；
局部測試／输出收益不能取代總耗時驗收。最新 PR #288 只交付三份結果文件，
merge 指令到同步清理觀測為 1244.449 秒（20 分 44 秒，未含最後回報），建立 PR 前 593.629 秒且沒有 compaction；
詳見 PR #288 的已核對量測，保留不同 scope 與非因果控制的限制。

本輪只獲本地退版授權，新的 push／PR／merge／dotsync 未獲授權；active assignment 保留到具名交付。
本地退版驗收完成：十二個路徑內容／mode 與固定基線完全一致，三個新增測試檔 absent，brewup 未變。
`./tests/run.sh` 與 `./tests/run-parallel.sh` 各 exit 0、1577 PASS／0 FAIL；core 還原為 174，runtime 保留 669。
兩 runner 同機並行，wall time 各 414.585／126.955 秒，不相加也不當作效能改善對照。
原 command／exit／完整 logs 與測前 patch 保存在 `/tmp/workflow-285-revert-o4xlch4g/`，測試前後 patch／status 一致。
已通過治理／xref 與 Codex validator；結果補記後只補文件檢查，不重跑未變的程式測試。
尚未 push／PR／merge／dotsync，不先記為已退到 origin/main。
