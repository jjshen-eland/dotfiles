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
