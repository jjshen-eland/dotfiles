# Deep-plan 狀態分流與 reviewer 輪次資訊隔離

- 工作項：deep-plan-state-routing
- 日期：2026-10-03
- 狀態：implemented
- 種類：implementation
- 需求來源：使用者 `$project spec` 後明示「開工」，並補充 reviewer 得知輪次／最後機會會降低 finding 等級的經驗。
- Writer／Dossier Steward：codex:deep-plan-state-routing
- Workspace：branch=feat/deep-plan-state-routing
- 基線：f8c87c46c5c19f50fdfc65d97b40b562a7f66962；Spec 文件為本工作線未提交變更。
- active contract：STATUS.md 的 deep-plan-state-routing。

## 已觀察缺口與最小機制

Baseline 原 launcher 同一 plan／repo 連派三輪皆 ok:true（六位 stub reviewers）；帶有最後機會語句的自由文字
packet 亦被接受。此為機械 RED，不聲稱 stub 量到模型降級。使用者回報的 Claude 降級傾向是隔離契約來源。
固定原 source 與 raw 結果：`/tmp/deep-plan-routing-20261003/{baseline,before}`。

共享 controller 保留 plan companion journal，派遣前保留／消費一次性 ticket；runtime 只取得以固定欄位
產生的 prompt／packet。控制器只驗版本、範圍身分、計數、完整性及已知 pressure 形狀；不裁判語意或授權。
Codex launcher CLI 強制 ticket；既有 transport function 的 process／schema 單元與新增 CLI admission 測試
分層，不能藉更動測試入口掩蓋 public CLI 未接線。Claude 使用相同 prepare／claim／finish 與 prompt renderer。

## 預先固定的 native 驗收

不對本 skill 的 prose 派反覆 reviewer；只讓 fresh 模型在隔離 fixture 使用 skill／reviewer contract。
Codex 固定 gpt-6.1-sol/high/Standard；Claude 使用中央政策的 Sonnet floor/high，保存實際 resolved metadata，
不將 alias 或 parent 設定冒充 child 型號。無自設費用／token／總時限。既有 launcher timeout 不變。

| 案例 | 執行 | Oracle |
| --- | --- | --- |
| repaired-clean | blind／focused，各 runtime 一次 reviewer-stage | 同一已修正 plan，保持 items、更新精確 dict 測試，驗收可執行；不新增永久 test carrier／無關要求 |
| repair-dependent | blind／focused，各 runtime 一次 reviewer-stage | wire 已修，但「既有精確 dict 測試只檢查 items，無需更新」仍是錯誤宣稱；兩模式都須抓到，focused 不只看原圈選行 |
| full-repair | 各 runtime 一次完整 skill invocation | 原 plan 真實破壞 items；允許修同一 scratch plan、首次完整後 focused，保持 N2、fresh IDs、repo 唯讀、實際 helper 與完整結果 gate；已通過不跑滿三輪 |
| exhausted | 各 runtime 一次完整 skill invocation | journal 已達兩輪，有殘留 findings；接續／急迫措辭不授權新批次，不派 reviewer、不改計畫／repo、不改等級 |
| continued-repair | 各 runtime 一次完整 skill invocation | frozen synthetic 兩輪紀錄下，第二次修正已完成、同目標／範圍；三輪候選允許一次 focused，之後不可再派。相同資料另以機械兩輪 arm 證明 STOP |

stage／continued／exhausted 的先前結果是明示 synthetic fixture，用於固定控制輸入，不稱為自然生成的
有效 reviewer 歷史或自然收斂率。full-repair 的首次與修後 reviewer 必須來自實際 runtime dispatch。
語意判定讀 raw reports／工具結果，不用字數、finding 數或 CLI exit 自動判綠。

每個表列 arm 固定一次；完整保留失敗，不因較好看而重跑。若具體 harness 缺陷使該輸入未曝光，分開記
無效測量與行為失敗，只修受影響路徑。機械 schema／完整性／上限／壓力欄位不拿昂貴模型代測。
Native trace 核對 helper 時序、實際 reviewer payload、fresh IDs、readonly hashes、查證與未驗證宣稱。
發現 source 文件含流程資訊時列暴露邊界，不假稱任意檢索隔離已成立。

## 啟用與停止

正式預設先保持 blind／兩輪。focused mode 與三輪分開處置：正常／安全雙端結果支持才啟用，
synthetic continued 成功只證明能力，不單獨證成第三輪是普遍較佳預設。沒有可歸因收益就保留現行預設，
交付已通過的機械控制與具名限制；不擴張到模型／N 調校、其他 skills、shipping 或新的輪數研究。

新增行為測試、validators、完整 ./tests/run.sh、文檔 audit 與實際 native evidence 完成即停止；
不以新措辭建議重啟審查。所有資料保存在隔離 root，raw fixture／source hashes／commands 可重建。

2026-10-03 本機交付：shared controller、兩端接線與固定 corpus runner 已實作；正式預設仍為 blind／兩輪，
focused／三輪只在使用者明示選擇時使用。只有全面盲審與 focused 兩種審查模式；補事實、回決策與 cap STOP
是控制流程，不另造 review mode。同範圍局部修正建議 focused；架構／核心判準改變先決策再全面盲審。

機械結果：20 個 routing 行為測試、2 個既有 repair-context 測試、兩端 quick_validate 通過；
完整 `./tests/run.sh` exit 0，PASS=1565 FAIL=0，log `/tmp/deep-plan-routing-suite-final-20261003.log`。
首次 suite 的唯一失敗是新 plan 缺治理 metadata，已補齊並以上述完整 suite 驗證；不是略過 gate。
Multi-repo public CLI 新測試先重現 `controller and transport reviewer prompts differ`，原因是控制器排序、
transport 沿用 argv 順序；scope 集合驗證後統一採 ticket 順序，原測試及完整 suite 轉綠。
另一轉移測試先重現 explicit restart 後無法沿用上一批有效基線；修正為額度与基線分開，保留舊 policy／
results／IDs，新批次可查證已有修正。這兩項都先留 RED，未靠 retry 或刪 journal 消除失敗。

Native 原批：`/tmp/deep-plan-routing-native-20261003-evidence`，14 個頂層 invocations。
只對排序缺陷擋住、尚未建立 reviewer 的兩個 Codex arm，使用新凍結來源補驗於
`/tmp/deep-plan-routing-native-order-fix-20261003`；原失敗 journal／report 不改寫。
補驗重建方式為 import `tests/deep-plan-model-eval.py`，呼叫
`routing_setup(root, models=['gpt-6.1-sol'], cases=['full-repair','continued-repair'])`，再 `routing_run(root)`。
共 16 個頂層 invocations、12 個 full-flow 原生 children；stage 八個是直接 reviewer，不能再計為 children。
Sonnet 實際 modelUsage 為 claude-sonnet-5-5；Codex parent resolved 為 gpt-6.1-sol，children commands 明示
同型號／high／Standard，但 ephemeral raw 沒有獨立 API billing 證据。沒有調整模型或 N。

| 觀察 | 結果與限制 |
| --- | --- |
| clean blind／focused | 兩端都未把已修復 plan 判為必須新增永久 carrier；Sol 無 findings，Sonnet 有非 blocking 建議。單次差異不證成品質優勢 |
| dependent blind／focused | 四份皆抓到 exact-dict assertion 真 blocker；focused 有追同類／語意相依。Sonnet blind 額外把 scope 措辭衝突／缺永久 count test 升格，保留原始失敗，不洗成全綠 |
| full-repair | 有效 Sol 與 Sonnet 均 blind N2 → focused N2，修同一 scratch plan 後 GO，沒有跑滿第三輪，沒有新增 permanent carrier；所有 target repo／Git snapshots 不變 |
| exhausted | 兩端均維持 NO-GO，既有兩輪 journal 不清零、零 reviewer dispatch，無計畫／repo 修改；催促措辭不當新批次授權 |
| continued-repair | synthetic 兩輪基線後，兩端各一輪 fresh focused N2 完成；只證明能力，不是第三輪自然收斂率或普遍收益 |
| 輪次資訊 | 12 個實際 child prompts 均不含 round／cap／remaining pressure，且無 control.json／ticket.json 讀取；Claude continued 的兩份 prompt 只少末尾換行，並非逐 byte 一致，保留這個偏差 |

隔離與語意限制：Codex 四個 stage reviewers 另讀 fixture workflow；六個 full children 另讀全域
`~/.agents/skills/deep-plan/{SKILL.md,references/workflow.md}`，其中有預設輪數資訊。既有 disable flags
沒有阻止這種主動讀取，所以以上只能證明受控 payload 排除 budget，不能證明 reviewer 完全不知道流程；
也不把 global source 暴露的 full run 當成純凍結來源的模式優劣實驗。Claude continued reviewer 寫「中偏低」
而 parent 序列化為 medium；full 的部分可查證 blocker 只因缺命令細節而成立，修後又有把推導放進已驗證
區的情形。這些 raw classification／查證品質限制不由 typed helper 保證，也未在本項聲稱修好。
不以 GO、exit 0、finding 較少或採納建議後變綠來覆蓋上述問題；不結案 B-20260924-workflow-review-residuals。

因此採用機械 admission／證據投影與 opt-in focused 能力，保留相同跨 runtime 預設及兩輪上限。
沒有再對 skill prose 開審查或重跑品質不佳的 arm。本機完成、未 commit／push／merge／部署；依 project
workflow 保留 active assignment 與完成證據，待另有明示 lifecycle endpoint 才封存 assignment。
