# 決策歸檔 — 2026-10

## 事件記錄（event-time）

- **D-20261002-project-model-bootstrap · 2026-10-02 #246 固定新版模型並只修有行為證據的首段 reader 提示**：依使用者指定，以 Codex 0.160.0 的 gpt-6.1-sol/high/Standard 為 target，與 gpt-5.6-sol 同 fixture/prompt 對照；Claude Code 2.1.287 的 native default 是 Opus 5.5，使用者選擇採該預設。固定入口 first/reuse 正常終態相同，Standard credit 等價合計 7.19165 vs 17.81768；不能據此推導訂閱內含 quota 優勢或速度優勢。內容品質以正常完成、false STOP、scope/authority 與錯誤操作為判準，不以 tokens 下降為成功。只有雙入口的 Python/basename 範例、禁止首段合併其他命令及缺 footer 的續讀提示取得 observed gap 與正向證據：舊 native Claude 首段漏 11..139，最終 matched native arm 完整恢復；兩端受控 MCP 截斷從 L11 續讀、必讀 EOF 後才寫規格，normal Log 四份 EOF 且不 mutation。保留 shared core、12000-byte chunk、authorities 與安全反例。詳見本工作項 plan 的原始 packet、限制與可重建 runner；本筆為本地決策，未發佈。
  - 日期來源:direct
  - 放棄:把通用新版模型 guidance 當 gpt-6.1-sol 的實測；用 credit 代替 subscription quota；為縮字刪除 domain/safety contracts
  - 重議:固定 workload 的訂閱 dashboard 取得可歸因 model 用量，或新的完成品質/授權失敗 trace 支持單一候選改動時
  - 關聯:Issue#246;D-20260925-instruction-quality-scope;X-20261002-project-loading-candidates;docs/plans/2026-10-02-project-model-behavior.md;claude/skills/project/SKILL.md;codex/skills/project/SKILL.md

- **D-20261002-ready4quit-contract-first · 2026-10-02 新版模型 flush 在 sink lookup 前先取得 contract output**：gpt-6.1-sol/high/Standard 與 Claude Opus 5.5/high/Standard 的固定 native corpus 中，Claude 原文 q-flush 將 contract read 與禁止的私人路徑 probe 合併；fresh guarded 原文 control 重現，blocked attempt 仍計 RED。單一順序候選把既有 contract/schema 段落移到 flush 開頭，要求讀完 output 後才查 instruction/cache sink。雙端 q-flush 正確 additive／promotion／Git residue，broader q-clean／q-residue／q-owner 保持無私人 probe、無越權 mutation/shipping；fresh blind Codex q-owner 維持另一 steward 的 dossier 不動。只採這個查證時序修正，不以 prose 變短或 native exit=0 作收益。q-owner 的 Claude Async evidence label 仍另列 RED，不能據本項外推已修好。變更仍在本機 branch，未 commit／發佈。
  - 日期來源:direct
  - 放棄:把 containment 擋住 query 冒充遵守；查完私人 path 才補讀 contract；以一次整案 terminal success 代替 mutation/evidence oracle
  - 重議:同條 contract timing 仍產生先探查後讀取，或正常 flush 因此產生 false STOP 時，保留該 native trace 再判因果
  - 關聯:Q8;docs/plans/2026-10-02-session-skills-model-behavior.md;shared/skills/ready4quit/references/workflow.md

- **D-20261002-ready4quit-evidence-rollup · 2026-10-02 最終 Async/schedule 列採各子面向最弱證據**：原文 q-flush 與 contract-first q-owner 的兩個 Claude native sessions 將 unavailable background/CronList 的整列標 RECALLED；現行 domain 句只定義子面向 PARTIAL，沒有 aggregate evidence 規則。保留其定義並在同一 canonical 句明定整列採最弱證據，完整對話回溯不能覆蓋缺 listing 的 PARTIAL。雙端 q-clean/q-residue/q-flush/q-owner 八個 fresh native fixtures 的整列均正確 PARTIAL；零候選仍 ✓ 且無 false NOT READY，具體 unknown task、未升格規則與無 legal steward 的 project fact 各維持 ⚠。Actual files/HEAD/mock remote 與 raw tool inputs 無越權 mutation/shipping/private probe；獨立 fresh Codex forward q-clean 亦保留盲區而不製造殘留。這個採用是獨立於 D-20261002-ready4quit-contract-first 的 evidence 改善，未改證據定義、ownership 或任何 action endpoint；不保證模型永不違約。本機候選未 commit／發佈。
  - 日期來源:direct
  - 放棄:把 whole-axis RECALLED 誤當 partial 子面向已保留；以成功退出或正確 NOT READY 掩蓋 evidence 欄錯誤；為 completeness 新增無 RED 的提醒
  - 重議:有 authoritative listing 時被錯降 PARTIAL，或 unavailable surface 再被 RECALLED/VERIFIED 掩蓋時，保留對应 native trace 再測單一原因
  - 關聯:Q9;D-20261002-ready4quit-contract-first;docs/plans/2026-10-02-session-skills-model-behavior.md;shared/skills/ready4quit/references/workflow.md

- **D-20261003-review-skills-retain-core · 2026-10-03 新版模型 review skills 評估保留正式核心**：固定 gpt-6.1-sol／high／Standard 設定與 Claude Opus 5.5 [1m]／high／Standard，以 28 次 fresh native invocations 檢查兩個已 portable 的入口、reviewer-stage 內容控制與普通／full／ownership 實態。移除七類通用 checklist 無可歸因完成品質收益，搬動 risk selector 也未解釋 cutover fixture 的歧義，兩候選均不採用。Compatible normal 雙端各一位 reviewer 後由作者驗證實際跨庫修復，owner 雙端 BLOCKED 且全樹含 .git 不變；明確 permission boundary 雙端採 full 並修復 viewer 權限回歸，獨立 probe 通過。保留所有 runtime entries／shared instructions／helpers／既有 oracle，不因新版模型通用能力、字數、單次去重或較多 reviewer 而改規則。新增 opt-in 可重建 runner 與 audit facts，保留輸出過度宣稱及 Codex native dispatch body 加密的證據界限；不宣稱完整 isolation oracle 或所有既有 gap 已結案。本機交付，未 commit／發佈。
  - 日期來源:direct
  - 放棄:為 token reduction 刪指令；未證明 cutover 條件就加風險反制句；把 green unit tests、model terminal success 或完整自述當 oracle
  - 重議:新的實際完成品質／scope／authority／isolation failure 能支持單一 source 因果對照時
  - 關聯:D-20260925-instruction-quality-scope;X-20261003-review-checklist-ablation;X-20261003-review-route-position;docs/plans/2026-10-03-review-skills-model-behavior.md;tests/review-skills-model-eval.py

- **D-20261003-deep-plan-retain-core · 2026-10-03 Deep-plan 新版模型評估保留正式核心**：原文與只刪 §4 的 reviewer-stage 共十二份未支持可歸因品質收益；完整 ordinary／decision／full-wire／alert 路徑另驗，不以 token 省字、finding 數或 CLI exit 判成功。保留兩薄入口、shared workflow／brief、criteria、classification、fresh N2／两輪、typed complete-set／disposition 與授權契約，不重做已完成 portable migration、未啟用 focused transport。十二份 stage 之外，雙端 ordinary ready／decision 分流正確；wire 同 canonical scratch plan 修復後兩輪 GO、不改 repo、不強制永久 carrier；Sol alert 有真 blocking 停待處置；Opus alert 缺 severity／混層，主代理 fail-closed，沒有 gate。Opus 告警時間、未來恢復與通知出口的過度外推仍是 reporting boundary，沒有證據將其歸因為通用列表或支持增刪指令。
  - 日期來源:direct
  - 理由:把模型通用能力當刪文理由，或為單次波動加規則，不能證明完成品質；保留實際安全契約，誠實列出未通過之處
  - 證據:docs/plans/2026-10-03-deep-plan-model-behavior.md;tests/deep-plan-model-eval.py;`/tmp/deep-plan-{baseline,ablation,child-capture}-20261003`
  - 限制:首批 Sol full child 被 login shell 繞過 capture，六個 child 僅流程證據；另兩個 Codex full parent 用既有 --codex-bin 補驗六個 gpt-6.1-sol 明示 pin 子程序。Ephemeral raw JSONL 不提供獨立 API resolved／帳單證據，不把配置當 billing。小 fixtures 不結案 B-20260924-workflow-review-residuals
  - 關聯:X-20261003-deep-plan-checklist-ablation;D-20260925-instruction-quality-scope;D-20260825-deep-plan-empty-wait;M-20260825-portable-deep-plan-revalidation;X-20260825-deep-plan-duplicate-port

- **D-20261003-deep-plan-runner-python-compat · 2026-10-03 Clean clone 揭露 runner 的 tarfile API 相容性缺口**：ROOT CAUSE CONFIRMED。相同 runner 在原 workspace 的 Homebrew Python 3.14 可 setup，但 --no-local clone 由 macOS CLT Python 3.9 執行，TarFile.extractall signature 沒有 filter，setup 拋 TypeError，尚未派任何模型。凍結 failing trace 與兩端 interpreter／signature control；修正目標是新 runner 對 extractall 的 keyword 能力假設，保持 fixed-BASE Git archive 的 trusted extraction policy，無 filter API 時使用舊版等價預設，支援時保留原 explicit fully_trusted。不是改模型、fixture oracle 或正式 skill。依同一次 --merge 的 bounded repair 授權，在已通過 parent authority 的 candidate 上恢復原 exact assignment 以修同工作項，另建修復後 completion candidate，不改寫既有 commit／frozen plan／history、不把首次 clean-clone suite 綠當 setup 綠。
  - 日期來源:direct
  - 證據:clean clone `/var/folders/t5/4b3mtjj52fvdplz5f15mf_ym0000gp/T/deep-plan-ship-clean-ygqk6eoj/repo`；3.9.6 /Library/Developer/CommandLineTools/usr/bin/python3 的 extractall 無 filter，3.14.8 /opt/homebrew/opt/python@3.14/bin/python3.14 有 filter；first setup TypeError 留當次 trace
  - 放棄:只換 interpreter 後宣稱已修；更動舊 review runner；重跑 native模型洗結果；改寫已凍結 audit plan 或首次 completion 事件
  - 重議:兩 interpreter 的 setup／ablation／restart／drift guards 或必要 suite 仍失敗時，不送出
  - 關聯:M-20261003-deep-plan-completion-candidate;tests/deep-plan-model-eval.py

- **D-20261003-deep-plan-state-routing-direction · 2026-10-03 Deep-plan 以狀態分流及機械上限建立新 spec**：使用者明示 `$project spec`，要求避免深井／prose 審查，能機械下沉者須實際接線。工作方向是保留普通風險分流，對獨立審查依有效首次基線、再審原因、實際變更與本批輪次選擇全面盲審或 focused；模式與能否 dispatch 分開判斷，兩 runtime 共用產品語意。使用者另指出兩輪通常只有一次審查間修正；因此將「首次盲審加最多兩次 focused、總計最多三輪」列為待驗候選，與現行兩輪基線分離比較，不宣稱使用者已選定新正式預設或候選已有品質收益。驗收契約位於 STATUS.md 的 deep-plan-state-routing；本次僅建立文件。
  - 日期來源:direct
  - 證據邊界:使用者回報過往 Claude Code reviewer 知道已審次數、最後一輪或不再有修正機會時傾向降低 finding 等級；本次未重現，不外推成模型普遍結論。此回報支持將 controller 輪次資訊與 reviewer 輸入機械分離；固定允許欄位產生輸入，核對實際傳遞及來源文件暴露，不能只用「不要受影響」的 prose 提醒。
  - 放棄:按第幾輪機械地盲審／focused 交替；因 NO-GO 自動全審或重開批次；只加提示文而無 helper／dispatch 接線；用字數、零 finding 或重複全文 review 當完成品質
  - 重議:固定行為案例顯示 focused 漏掉同類／相依真 blocker、第三輪擴張目標或沒有完成品質收益、跨 session／runtime 可繞過輪次上限，或兩端無法產生相同可觀察 gate 時；不以新 prose 建議擴大案例
  - 關聯:deep-plan-state-routing;D-20261003-deep-plan-retain-core;D-20260924-review-repair-verification-choice;M-20260915-b06-deep-plan-reviewer-count-reassessed;M-20260915-b07-deep-plan-eval-review-reassessed;B-20260924-workflow-review-residuals

- **D-20261003-deep-plan-controller-adoption · 2026-10-03 Deep-plan 採機械審查控制，保留共同盲審／兩輪預設**：以同一 plan companion journal 綁 scope／版本、typed complete set、fresh IDs、一次性 ticket 與本批上限，雙 runtime 必須在 dispatch 前接線；repair packet 由固定允許欄位及實際 diff 產生，不帶 controller budget／預定 verdict。模式只有盲審与 focused；missing facts、needs decision、cap stop 是流程狀態。使用者明示的新批次可沿用有效基線查證修正，不把批次重置誤當證據消失，也不因換模式／session／runtime 自動重開。Focused／三輪保留明示 opt-in，正式共同預設仍盲審／兩輪。
  - 日期來源:direct
  - 理由:兩端 focused 都命中修後語意相依，cap pressure 均零派遣；但單次成對輸出沒有可歸因品質優勢，synthetic continued 成功不證明第三輪普遍需要。兩輪可作成本邊界，不能被解讀為 reviewer 的最後修正機會或降低 severity 的理由
  - 限制:Codex reviewer 主動讀取含預設輪次的 workflow，受控 payload 無 budget 不等於全域資訊隔離；Claude 原始分類／查證與 parent 正規化仍有不足。保留原始失敗、機械 admission 成功与內容品質分開，不宣稱 P10/P14 全綠
  - 放棄:因 NO-GO 自動升到盲審／第三輪；用新批次丟棄既有證據；根據少 finding、GO、exit 0、單次速度或合成歷史直接改預設；為補 prose 繼續追加 review
  - 重議:新的自然工作線實際證明預設模式／上限妨礙完成品質，或出現具體 cap bypass／budget 暴露／漏掉相依真 blocker 的 trace 時，再固定單一受影響案例；不自動展開下一輪研究
  - 關聯:D-20261003-deep-plan-state-routing-direction;docs/plans/2026-10-03-deep-plan-state-routing.md;B-20260924-workflow-review-residuals

- **D-20261003-review-repair-controller-direction · 2026-10-03 Code review 以修復復發證據與有界派遣建立 spec**：使用者明示 `$project spec`，將 deep-review／repo-review 的同根因漏修、修復引入問題、模式分流與上限收斂成 STATUS.md 的 review-repair-controller active contract。方向是保留 ordinary 一次審查，對需要獨立複審的工作落實 code-review 專用 controller、scope／repair lineage、派遣前驗證及有效 receipt 才能清除 terminal signal；不直接複製 deep-plan 的 plan carrier 或固定 reviewer 數。先驗修復完整性，再消耗 reviewer；復發須診斷修法與相依覆蓋，不能只升輪次或推論架構錯誤。模式與預算獨立比較，「首次盲審＋最多兩次 focused」仍是候選，未改正式預設。本次僅建立 spec，尚未實作或啟動新 native eval。
  - 日期來源:direct
  - 證據邊界:基線 a94a8efa8ee64e1054831e55c6c5fb87627360ec 的 portable workflow 已有同類掃描與修後驗證；legacy 修復軌跡模板不代表當前入口已接線。合成 helper probe 重現反覆 capture／autofix-check 及僅 ancestry 即可 clear terminal 的介面缺口，不宣稱已觀察 native reviewer 違約。使用者的兩種修復浪費與輪次壓力回報作驗收案例來源，語意根因判定仍受既有不可機檢限制約束。
  - 放棄:重做無收益的 prose／checklist ablation；只提高上限或靠提示自律；沒有有效基線就 focused；把首次晚發現等同修復引入；藉漏修／partial result 退票或重開批次；復活 legacy commit-count loop；以填表完整度或自然語言評分器保證同根因全修
  - 重議:固定案例顯示 controller 阻擋正常可完成工作、focused 漏掉真相依問題、候選上限無品質收益，或真實工作線提供新的 scope／cap／terminal／severity failure 時，保留原始證據並只重測受影響原因
  - 關聯:review-repair-controller;D-20261003-review-skills-retain-core;D-20261003-deep-plan-controller-adoption;D-20260924-review-repair-verification-choice;D-20260916-deep-review-self-report-accepted-limit;B-20260924-workflow-review-residuals;shared/skills/deep-review/references/workflow.md

- **D-20261003-review-repair-controller-adoption · 2026-10-03 Code review 落實有界派遣與修復證據，保留共同盲審／三次修復預設**：兩入口接到同一 controller，先消耗一次性派遣與修復額度、驗完整結果與 fresh identities，再接獨立處置。修復驗證執行真實檢查並綁 snapshot，保留同根因／引入／揭露／獨立新 finding 的來源；已知失敗不得再花 reviewer。Terminal clear 改需當前完整 PASS receipt，legacy ancestry-only signal 保留。Ordinary 仍一次 reviewer 加作者驗證；full 預設盲審、三次修復（可明選一至五次），focused 明示 opt-in。達上限為 FAIL／BLOCKED 控制狀態，只有新使用者指示才能開新批次，保留證據；有效基線加局部修正可建議 focused，scope／契約改變先重新確認盲審範圍。這是本機實作決策，未 commit／發佈。
  - 日期來源:direct
  - 理由:baseline 與修正後候選在同一自然 fixture 都一次修好同根因兩處與 consumer；blind／focused 均兩組 reviewer 後實際 probe 通過，不能聲稱 controller 新增了模型的修復能力，也不能以此支持縮到兩次修復、提高上限或更改模式預設。機械收益是實測的 cap／ticket／scope／check／receipt 缺口被攔下；兩種 reviewer-stage 回歸與獨立 finding 均能發現，clean 不製造 blocker
  - 限制:Codex native task payload 加密，不能逐字證明 isolation；Sonnet 改寫 packet、用 path 代替內容，Sonnet 與 Opus 均有摘要替代原報告，transport／receipt 未通過，保留原始 RED。Controller 可保留提交的原 severity，但不能證明提交內容忠於 native report 或 free-text 根因證據完整；不宣稱全域隔離或 B-20260924-workflow-review-residuals 整筆結案。Dirty packet 與 content-hash 的 observed failures 各只重測受影響案例，結果留 plan
  - 放棄:用少 finding／PASS／速度改預設；因到頂推論架構必錯；修復失敗退票、换 runtime 清零、借第二意見額度；以增加 prose 或自然語言評分器掩飾 transport／語意證據缺口
  - 重議:新的實際工作線證明預設妨礙完成品質，或發現具體機械旁路／packet 暴露／同根因漏修時，只固定該原因做對照；不自動追加審查輪或擴大模型矩陣
  - 關聯:D-20261003-review-repair-controller-direction;docs/plans/2026-10-03-review-repair-controller.md;shared/skills/deep-review/references/control.md;D-20260916-deep-review-self-report-accepted-limit;B-20260924-workflow-review-residuals


- **D-20261003-project-test-evidence-reuse · 2026-10-03 Project 收尾先沿用測試證據，再按變更補驗**：使用者要求修正實作全綠後、相同程式與測試仍被 Log 重跑的浪費。ROOT CAUSE CONFIRMED 的範圍是本次 #259 前的 agent 計畫：把 kernel「混檔拆分後 clean clone」泛化為一般收尾；current shared Log 沒有明確的 evidence-first 步驟。使用者插問是取消重複計畫的 intervention，不能靠此維持未來正確性。兩端已 portable、共同 core 在 shared/skills/project，不改 topology；採最小共同 Log 修正，現有 Git diff／檔案 hash 足以核對，不另建 cache／receipt framework。
  - 日期來源:direct
  - 證據邊界:本批 production trace 是錯誤安排而非已重跑的 suite；其他歷史重跑不逐一推論。D-20261003-deep-plan-runner-python-compat 曾因 interpreter 3.14 → 3.9 發現真缺陷，是「相關環境改變需補驗」的有效反例，不可用此次節省取消該類檢查
  - 放棄:每個 Log 一律重跑 full suite／native eval；用 commit SHA 作唯一失效條件；只看程式檔未變就忽略測試／依賴／fixture／環境；強迫補新格式 proof 才承認既有真實結果；把本機綠代替 required CI
  - 重議:固定正常／stale／unknown native controls 若顯示新流程仍浪費或錯用證據，只修該具體原因；本次不改 provider／安全契約或引進全域测试快取
  - 關聯:project-test-evidence-reuse;D-20260822-portable-project-skill;D-20261003-deep-plan-runner-python-compat;shared/skills/project/references/pressure-tests.md

- **D-20261003-project-reuse-evidence-boundary · 2026-10-03 停止對測試證據判斷追加 prose patch**：固定十二次 native parent traces 顯示，正常沿用與 changed-input 分支可通過，但 Sonnet 在原 unknown case 與有界修正後仍錯把作者「All tests passed」摘要當可用證據。後次完整讀到四份 required reference，排除單纯漏讀為充分根因；既有成功是 model inference，不是可靠的 evidence gate。停止再疊文字與同 packet 抽樣，保留 draft candidate，未宣稱安全驗收／發佈完成。
  - 日期來源:direct
  - 放棄:再加禁止句洗綠；以 Codex 成功代替雙端完成；把 failed safety control 改成 non-blocking oracle；為已綠且無關的 checks 再跑全套
  - 重議:使用者決定證據判斷的實作邊界後，再以已固定 unknown fixture 驗窄幅機械判定，或明確收窄本批目標並保留缺口；沒有決定前不自動引進 proof/cache framework
  - 關聯:project-test-evidence-reuse;D-20261003-project-test-evidence-reuse;shared/skills/project/references/pressure-tests.md

- **D-20261004-project-reuse-mechanical-check · 2026-10-04 採小型唯讀測試證據判定器**：使用者選定選項 1，解除前次停止追加 prose 的決策點。將結果欄位與精確輸入比對下沉腳本，輸出沿用／補驗／錯誤；既有 artifact 可直接讀，原 tool trace 可暫時正規化，不要求永久 receipt 或 cache。摘要不能補造命令、exit 或受測內容。Helper 不執行測試，不證明 artifact 真實性，也不自行推測完整相依與環境；這些依 target repo 與原執行證據核對。
  - 日期來源:direct
  - 驗收:先固定 summary-only、unchanged、changed 與 dirty/untracked 反例，再跑原 native 三案例；保留 required CI、條件式 clean clone 與 fresh shipping gates，不重跑無關矩陣
  - 放棄:繼續增加禁止句、為每次收尾強制新快取制度、以相同 HEAD 保證所有輸入相同
  - 關聯:project-test-evidence-reuse;D-20261003-project-reuse-evidence-boundary

- **D-20261004-project-reuse-mechanical-adoption · 2026-10-04 Project 測試沿用完成機械與雙端行為驗收**：小型唯讀 helper 接到共同 Log，既有 JSON 直接檢查、原工具結果可暫時正規化，無永久 store。13 個真 Git／filesystem tests 在 Python 3.14／3.9 通過；新六次 native 均呼叫 helper，正常案例不重跑，changed／summary-only 各補一次，四份 reference EOF 與 Git／origin 不變均查證。保留先前十二次 prose 候選 trace，不能歸因為單純漏讀或直接推論 skill 長度造成失敗。
  - 日期來源:direct
  - 驗證:最後完整 parallel suite exit 0、1567／0，Codex validator、portable linkage、doc audit 通過。合併 output 相容性曾有 deterministic RED，修後補機械 checks 與 repo 必要全套，未重跑 schema／判定未受影響的六次 native。原始結果與範圍見 Scenario 38
  - 邊界:helper 比對已聲明輸入，不能認證作者提交結果的真實性、自行推導完整相依或證明未記錄環境；symlink／submodule 不能只靠 Git anchor。Native 僅驗送出確認前 Log，不覆蓋 provider CI／merge；本批未 commit／push／部署
  - 重議:有新真實 trace 顯示錯用／重跑時固定該原因，優先補機械 oracle；skill 載入量另以按模式實測與行為對照評估，不以固定行數刪規則
  - 關聯:project-test-evidence-reuse;D-20261004-project-reuse-mechanical-check;shared/skills/project/references/pressure-tests.md

- **D-20261004-project-stage-routing · 2026-10-04 Project 改為按執行階段載入必要契約**：使用者要求處理 skill 長度分析；保留 shared core、雙薄入口與完整 domain／authority／shipping 契約，改以唯讀盤點、結案、送出／merge、條件例外逐階段載入。沿用既有 helpers，不新增模型判斷的機械替代品或持久 store。固定雙端 noop packet 從 15 次 reader、約 147 KB 降至 3 次、約 19.6 KB，Git 不變；正常 Log 仍呼叫 test-evidence 並零重跑。Spec 首次 Sonnet 自加 head 後重讀為 RED，入口最小修正後雙端 fresh footer-loss 從 L11 續讀、全部 EOF 後才寫入。Transfer 壓力拒 secret／commit；local provider PR 停在 PR，merge-query 在最後 non-watch query failure 後 STOP，無 merge。
  - 日期來源:direct
  - 邊界:載入收益不是注意力或整體品質的保證；provider stub、Codex 本地 tracking sandbox、兩個缺 governance 文件的 forward fixtures 均有實測限制，未宣稱真 GitHub E2E 或全部輸出品質已驗。保留原始 RED 與未通過的 fixture；不重跑同材料洗綠
  - 放棄:再做 #246 純 mode split；只縮薄入口或按固定字數刪安全契約；將 normalizer／terminal success 視為 authority 或 mutation oracle；另建無必要的 controller／receipt
  - 重議:實際新 trace 顯示 stage 漏讀、越權、false noop、輸出品質回歸或收益不成立時，固定該原因只驗受影響路徑；不追加全面 prose 審查
  - 關聯:project-reference-routing;X-20261002-project-loading-candidates;D-20261004-project-reuse-mechanical-adoption;docs/plans/2026-10-04-project-reference-routing.md;shared/skills/project/references/pressure-tests.md

- **D-20261005-claude-target-model-roles · 2026-10-05 雙平台正式驗收採各端 production target，Claude 以 Opus、Sonnet 作規則詮釋輔助**：舊中央政策把 Sonnet 一律列為紀律型 skill 發布門，但 repo 自 2026-07-07 已以 `opus[1m]` 為 Claude Code default，使用者也明確表示平常工作通常不採用 Opus 以下模型。portable skill 以同一 fixture／oracle 在兩端各自的實際 production target 驗收：Claude Code 以 Opus 為基準，Codex 以 repo 設定或當次明選的 Codex model 為基準，單端 GREEN 不得冒充雙端完成，Claude 模型階層也不映射到 Codex。各端保存 alias、resolved model、effort、service tier 與 CLI。Sonnet 只作規則詮釋、邊際承重與 robustness 輔助；其 RED 必須保留，可支持保留規則或設計新實驗，但只有交付明確承諾支援 Sonnet 或預先將它列為 target 時才阻擋。G1a／G2 的舊證據仍有效：Opus 兩臂皆綠不能支持刪規則，規則刪改仍需 Sonnet 成對比較或同等直接證據。此決策不把任何歷史 Sonnet RED 重判為 PASS。
  - 日期來源:direct
  - 證據:`claude/settings.json` 的 `opus[1m]`；M-20260915-b05-deep-plan-model-policy-reassessed；D-20261002-project-model-bootstrap；D-20261003-review-skills-retain-core；本輪 `/tmp/root-cause-first-opus-{completion,v2-insufficient,v2-controls}-20261005`
  - 放棄:用 Sonnet robustness 失敗否定未承諾的模型範圍；只看 Opus 綠燈刪除承重規則；把 alias 當成固定 snapshot；品質未過就以成本或速度選模
  - 重議:repo default／明選 target 改變；resolved model 漂移造成行為差異；明確增加 Sonnet 支援承諾；或 target 與 probe 在相同 oracle 的分歧改變發布風險
  - 關聯:M-20260915-b23-model-floor-policy-reconciled;M-20260915-b05-deep-plan-model-policy-reassessed;D-20261002-project-model-bootstrap;claude/evals/README.md;docs/plans/2026-10-05-root-cause-first-model-behavior.md

- **D-20261005-project-canonical-push · 2026-10-05 Project 的 repo 綁定移到執行工具工作目錄，保留 outward gate**：修正生成端與既有 gate 的衝突；共同 `ship-paths.md` 單點定義 push 執行形式，exceptions 引用同一來源，bootstrap helper 分開輸出 `bootstrap-workdir` 和 direct `bootstrap-cmd`。保持 explicit remote／branch 與錨定 expected SHA，不能因移除 `-C` 而倚賴未知 cwd。雙端 native acceptance 使用隔離本機 repo／bare remotes，含空白路徑與不同初始 cwd；它驗 command／Git 結果與 gate composition，不冒稱真 GitHub shipping 或 native approval UI 驗收。
  - 日期來源:direct
  - 放棄:複製規則到兩份薄入口；對 opaque 指令新增 hook allow exception；只移除 `-C` 而未綁定 repo；加入會執行 push 的 shell wrapper 使 policy 再次看不到 direct argv
  - 重議:執行工具無法可靠綁定 repo；或 Codex gate／rules 語意改變時，以 fresh trace 重新驗收
  - 關聯:project-canonical-push;X-20261005-project-opaque-push;D-20260912-cross-runtime-outward-gate;D-20261005-claude-target-model-roles;shared/skills/project/references/ship-paths.md

- **D-20261005-deep-plan-document-repair-baseline · 2026-10-05 Deep-plan 以宣告文件集合與三層實際基線續審**：#264 的舊 controller 已以 canonical plan staged fixture 重現 `repo-baseline-drift`，11 個新增行為案例 exit 1，raw `/tmp/issue-264-red-xubq8191.log`；相依文件案例另暴露尚無宣告 API。修復採同一 shared controller：先宣告固定 Markdown 相依文件集合，保存 worktree／index／HEAD 文件基線；只允許該集合及 canonical plan 的內容修正，未允許範圍維持完整 fingerprint，HEAD checkpoint 逐顆核對單親 ancestry 與實際改動。盲審只公開實際文件 delta，focused 另保留原 finding 處置；不靠 contracts 名稱、檔案副檔名或重開批次豁免漂移。舊 journal 不丟棄：只有以原 HEAD 文件重建出的完整 index／worktree hash 精確吻合既存受審 snapshot，才可附加可驗證文件基線；無法證明則停止，不猜原 dirty 文件內容。
  - 日期來源:direct
  - 放棄:全 Markdown／STATUS 排除；只更新 repo baseline hash；忽略 index／HEAD；restart 自動採用當前狀態；重建 journal 或改 blind 迴避 drift；以 checkpoint 最終 tree 相同放過中途程式提交
  - 重議:固定 fixture 證明合法文件狀態仍被阻擋、未宣告變動可取得 ticket，或既有 journal 無損續審存在可證明但未支援的基線
  - 關聯:#264;deep-plan-document-repair;D-20261003-deep-plan-controller-adoption;tests/deep-plan-routing.py

- **D-20261005-legacy-terminal-disposition · 2026-10-05 #267 legacy review-terminal 採 exact signal 的明示結案**：隔離跨工具 fixture 已證實 default branch 承接舊 terminal commit 後，下一批 controller 唯讀 PASS 仍被 ship-state ancestry 攔截，terminal-clear 拒絕且原 metadata 不變；新結案 oracle 在現行 controller 缺少介面時 RED。採既有 shared controller 的獨立 explicit disposition：要求當前完整、fresh、非 historical-range PASS 與當次具名 legacy 處置，綁定 repo／原訊號 hash／HEAD／scope／endpoint。原 coverage 不足不推論已覆核，須由使用者明示結案該原訊號；receipt 保存在既有 .git/deep-review operational evidence，原 anchor、controller、findings、已用額度與歷史保留。Shipping 只辨識同一舊訊號已結案，不把 receipt 當新批 review PASS 或外向授權；新的 marker 與無法驗證的 receipt 仍 STOP。
  - 日期來源:direct
  - 放棄:因 terminal commit 已進 default 即靜默忽略；沿用舊批照送或普通 merge 當結案；刪整份 anchor／重設 controller；以無關 autofix 取得 mutation 資格；讓唯讀 review 自動寫 Git metadata
  - 重議:隔離案例顯示合法 exact disposition 仍攔截無關新批、新訊號能借舊 receipt 放行，或未授權 disposition／shipping 被執行
  - 關聯:Issue#267;D-20260823-portable-deep-review;D-20261003-review-repair-controller-adoption;M-20260923-review-terminal-display-local;tests/review-repair-controller.py

- **D-20261005-turbo-delegated-controller · 2026-10-05 Turbo 採新 orchestration skill 與既有 controller 的 opt-in 續批**：使用者同意以新 shared turbo core＋雙端薄入口實作，不 fork deep-plan／code review／Project。新增單次 delegated request，綁當前 session generation／Goal／完整 repo 集合／controller bytes／修正證據；舊批次、findings、上限與 receipts 保留，普通 restart／new-batch 仍要求原本的當次明示授權。已有效審過的內容不能重複當續批進展；測試先重現 permission mode 未保存、已審內容重用與目錄誤作 goal，再修正。交付 action 由 Project 唯一授權表正規化；on 與 launch-time permission profile 分開，沒有全域降權或自動 host approval。
  - 日期來源:direct
  - 證據:tests/turbo-mode.py；raw `/tmp/turbo-{mode-red,binding-checkpoint-red,integration-red,baseline-red,timestamp-red}-20261005.log`；第一輪 native `/tmp/turbo-{codex,claude}-complete-20261005-a`。這輪只證明機械控制及阻擋路徑，portable/native 完成驗收仍在進行。
  - 放棄:永久 fork 三套 workflow；把 agent 建議偽裝成新 user restart 指令；重設 review journal；讓 YAML／private cache 自行授權；以只改 permission mode 就宣稱 unattended ready
  - 重議:新的實際 fixture 顯示 delegated request 可錯綁、洗掉已用額度／finding、取消後續行，或 native hooks／權限 composition 與目前證據不符
  - 關聯:turbo-skill;D-20261003-deep-plan-controller-adoption;D-20261003-review-repair-controller-adoption;D-20261005-project-canonical-push;docs/plans/2026-10-05-turbo-skill.md


- **D-20261006-turbo-native-evidence-transitions · 2026-10-06 Turbo 補入原生審查證據與同批範圍更新**：依 X-20261006-turbo-prose-only-gates 的 observed failures，active Codex turbo dispatch 改由既有 controller 的 opt-in `native-review` 啟動真實 fresh read-only CLI processes，保留 process／thread／raw output／report／subject bindings，拒絕 main 自寫 report。新增 single-use `refresh-subject`，僅對已授權作者驗收修正、同 roots／paths／原 baseline、剩餘 primary capacity 且無 pending work 更新 subject；撤銷舊 receipt、完整保留次數與歷史。active turbo 的 PreToolUse 依唯一 Project Step 4／5 gate 讀真正 native transcript 的當前可見 Ship 摘要，綁 commit 集合；不是第二份交付授權表。
  - 日期來源:direct
  - 取捨:真實 process evidence 只能證明來源與 binding，不能保證 reviewer 語意正確；作者仍獨立查證 findings／Goal。未啟用 turbo 的原 collection／caps 保留。Native transcript 缺席的 ephemeral／no-session-persistence profile 對 delivery fail closed，普通無外向任務仍可執行；不改 global permissions、trust 或 provider policy。
  - 證據:mechanical counterfeit／refresh／summary RED 與修後 controller tests；callback observer `/tmp/turbo-delivery-forward/observe-{claude,codex}-{off,default}` 實證持久化開關對 transcript 可用性的差異。fresh native 全流程補驗中，尚不外推 GitHub／desktop／app-server。
  - 關聯:turbo-skill;D-20261005-turbo-delegated-controller;X-20261006-turbo-prose-only-gates

- **D-20261006-turbo-native-report-collection · 2026-10-06 Claude 由原生完成事件保存 review 原文**：依 G 的實際收集失敗，active Claude turbo 保留 native fresh Agent，增加同步 SubagentStop collector，直接保存完整 final text，綁 session／generation／dispatched target 與 ticket／agent ID。Controller finish 以該 capture 保留 raw_report，作者另交的摘要標記 author_summary，不取代原文；capture 缺席或 binding 不符時保留 spent attempt／BLOCKED，不退款、不改 verdict 或 severity。普通 off-mode collection 不變，collector 不續跑或阻擋 reviewer。
  - 日期來源:direct
  - 證據:官方 hook schema 與本機 CLI 能力查證；三項先 RED 後 GREEN `/tmp/turbo-original-report-capture-{red-fixed-oracle,green}-20261006.log`。實際 native 支援及逐份保真由 fresh H 補驗，當下未提前判成功。
  - 取捨:改收集 source 而非增加作者抄錄指令；不擴充 Codex transport 成 Claude process，避免改變 reviewer 的既有診斷工具及權限。Private native artifacts 是來源 evidence，不是語意 grader／user authority；findings extraction 與 Goal AC 仍須作者独立查證。
  - 關聯:turbo-skill;X-20261006-turbo-author-report-rewrite;D-20261006-turbo-native-evidence-transitions

- **D-20261006-turbo-public-help · 2026-10-06 保留額外交付授權，補上可發現的使用介面**：使用者接受目前 `--allow` 多一層確認，指出無法知道有哪些參數可用。保留 on／off／status 與交付 authority；新增 agent-level help／--help 的唯讀路由、on／status 的目前授權及 help 提示，README 直接列可用語法與範例。Help 不交給 internal helper argparse，也不啟用、bind 或擴權；bare 維持 status。雙端薄入口宣告 help，Codex UI 提供 help 起始 prompt；不宣稱宿主會自動列出 flags。
  - 日期來源:direct
  - 證據:本輪使用者「現在這樣設計也不錯，多一層確認，只是要怎麼知道有這些參數可以打呢」；前版 README 只有一個 on 範例、入口只有 workflow 路由，沒有正式 help 或人用參數表；雙端唯讀 help 與啟用提示待驗
  - 取捨:補可見說明而非改 on 的交付語意；沿用 README 人用權威與 shared workflow，不新增重複 quick-reference store，不改 controller／hook／permission／Project gates。原 implemented plan 保持凍結，新增介面 delta 由既有 active state／history 追蹤
  - 關聯:turbo-skill;M-20261006-turbo-skill-local;README.md;shared/skills/turbo/references/workflow.md

- **D-20261006-deep-plan-evidence-control-boundary · 2026-10-06 #271 以来源可核對的文件資料區分 reviewer 控制輸入**：ROOT CAUSE CONFIRMED。現行 controller 的合法歷史矩陣有 12 assertion failures；Turbo 前 #268 合併版 `8c5bf05` 同樣 12 failures、0 errors。Git blame 顯示 `no_pressure(payload)` 來自 10/3 controller，10/5 #268 將完整 document delta 納入該 payload，Turbo 未改此拒絕位置。實作方向為保留 caller schema／處置／壓力檢查，canonical 文件／原 reviewer evidence 以可核對的來源資料角色傳遞，不把歷史當控制指令；資料 delta 必須由既有基線與 exact 宣告 snapshot 重建，不能以 caller 任意 document 包裝免檢。原始歷史、完整差異、journal／checkpoint／admission 防護與 defaults 保留，先審查未實作的計畫再驗最小修法。
  - 日期來源:direct
  - 證據:tests/deep-plan-routing.py 的 #271 RED；`/tmp/issue-271-red-20261006.log`；`/tmp/issue-271-red-source-20261006/manifest.json`；pre-Turbo source／raw log 位於 `/var/folders/t5/4b3mtjj52fvdplz5f15mf_ym0000gp/T/issue-271-pre-turbo-qydtp5mv`；#268／#270 merge metadata
  - 放棄:將此次拒絕歸因 Turbo；整體停用壓力防護；刪改來源歷史／省去必要文件；任意 caller document data 豁免；synthetic prepare 成功冒充完整 native lifecycle
  - 重議:來源綁定、原 RED、#264 regression 或 native reviewer／admission 任一步仍失敗時不宣告完成；新證據才調整最小修法
  - 關聯:#271;#264;#268;#270;deep-plan-repair-evidence;docs/plans/2026-10-06-deep-plan-repair-evidence.md;D-20261003-deep-plan-controller-adoption;D-20261005-deep-plan-document-repair-baseline

- **D-20261006-runtime-cloud-sync-disposition · 2026-10-06 Eagle08 的測試 daemon、runtime drift 與雲端 skill cache 明示處置**：使用者指出 eagle08 Codex processes 是已完成測試、明示可 kill；synced 是 Claude 雲端同步 skills cache，要求權威 settings.json 停用同步並刪除該目錄；model 修改為 runtime drift。Fresh 唯讀查證為 PID 18379／18483 的 0.160.1 app-server daemon，settings model opus[1m] → opus（其他為格式變化），synced 位於 legacy whole-root link 指向的 repo；root 與設定檔尚未變更。決定只終止這兩個已核身程序、備份後還原該 drift，將具名 synced cache 移出 repo／discovery；不把此授權擴成 kill 其他主機或刪除未知第三方。權威設定實際缺 syncClaudeAiSkills，官方支援 false；因此補來源設定，cache 清理僅為處置，不冒稱永久停用。settings.json 檔案 symlink 保持，skills root 按已合併的實體 discovery／逐項 symlink 設計。新設定的 shipping 授權另取當批明示 endpoint，origin/main 前不散佈。
  - 日期來源:direct
  - 放棄:把 runtime model drift 誤留為個人覆寫；將已識別 cloud cache 視為需保留的未知作者作品；只刪 cache 而不修補同步來源；恢復 skills whole-root link 再讓 cache 寫入 repo；把兩個測試程序的 kill 授權擴到其他 writers
  - 重議:程序 PID／exe／owner／啟動身分不符、source 有新修改、cache 出現追蹤檔或其他 provenance、設定不能由當前 CLI 原生解析，停止對應處置並保留現場；新設定合併前不宣稱遠端永久停用完成
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-fleet-twelve-accepted;docs/plans/2026-10-06-runtime-layout-convergence.md;claude/settings.json

- **D-20261006-runtime-model-defaults · 2026-10-06 雙端 repo 模型設定改採 default**：使用者在確認 Claude model=opus[1m] 與 Codex repo 未指定 model、本機保存 gpt-6.1-sol 後，指定 repo 的兩端模型值都改為 default／等效 default。Claude 官方 model configuration 支援 default 作為清除模型指定、回到帳號 runtime default 的特殊值，因此來源改為 model=default；Codex 官方 config basics 列 built-in defaults 為最後 fallback，repo 繼續省略 model，補一行註解表明策略。授權範圍是 repo 設定，不改 Codex 既有 base→runtime-only→local merge，也不清除本機／session 選擇；實際模型仍受各 runtime 的覆寫與帳號設定影響。先前雲端 syncClaudeAiSkills=false 保留，當批 origin/main／dotsync gate 仍有效。
  - 日期來源:direct
  - 放棄:為 Codex 寫入未獲官方文件支持的 model=default 字串；把使用者的 repo 模型政策擴成清除所有 runtime／local 覆寫；調整其他推理或權限設定
  - 重議:官方模型解析契約改變或隔離 native 初始化不接受 default，才調整來源表示方式；需要統一 runtime 保存的模型時另以具名範圍處置
  - 關聯:runtime-layout-convergence;D-20260912-codex-config-three-layer-merge;D-20261006-runtime-cloud-sync-disposition;claude/settings.json;codex/config.toml

- **D-20261007-claude-model-default-unset · 2026-10-07 Claude 原生 Default 改以省略 model 表示**：supersedes:D-20261006-runtime-model-defaults，僅取代 Claude 來源的 literal model=default 表示方式。使用者回報原生選單新增「default／Custom model」；本機 Claude 2.1.289 的原生推薦 Default 內部值為 null，settings 字串 default 被當成額外自訂選項。SDK 將兩者都序列化成 default，前輪只驗 initialize 成功，漏掉選單唯一性。隔離 metadata-only literal RED 有兩個 default rows、一個 Custom model；省略欄位 control GREEN 只有推薦 Default。原生 schema 的 model 是可選字串，來源採省略欄位，不寫 null 或固定模型 ID；無模型 turn，未證明 literal default 的實際推論失敗。
  - 日期來源:direct
  - 證據:使用者選擇第 1 項，只收省略 model；外部 UI 同時回寫 modelSettings.claude-opus-5-5.effortLevel=high 與鍵排序，原檔備份 /tmp/claude-default-fix-20261007.88lvqtc4/settings-ui-before.json，SHA256 3b82aa2d4f441a498da159d8b683fdfee71f9cb1c75bd6165a19358ecd63f77c。先前原始 initialize response 已含重複列，保留不覆寫；fresh literal RED /tmp/claude-default-literal-red-20261007.json，SHA256 d11c59f5ad436e7e6de368af6b730314d72cb1b1e26b745e970bff90c48cec5b，實際 exit 1；unset control exit 0。修後須用來源 model 表示再驗唯一推薦列。
  - 放棄:將 literal default 的自訂列當成推薦 Default；只用 initialize 成功判設定符合需求；將 native UI 的 high effort 回寫納為 repo 政策；清除本機 settings.local.json 或 session 模型選擇；把 metadata-only 當成模型推論證據
  - 重議:來源原生選單仍重複或 runtime 的清除覆寫契約變動時，以 fresh native evidence 調整表示方式；實際模型與 effort 的政策變更另取得具名範圍
  - 關聯:runtime-layout-convergence;D-20261006-runtime-model-defaults;M-20261006-runtime-model-defaults-validated;claude/settings.json;docs/repo-guide.md

- **D-20261007-ci-confidence-regression-first · 2026-10-07 CI 缺口先固化隔離反例，精簡僅限已證明重複的掃描**：CI 工作契約的七項問題由 tests/test_ci_confidence.py 固化為九組行為測試；原版執行 exit 1，30 個失敗子案例與一個 child 中斷不收斂的逾時重現內容遺失、錯誤聚合與 gate 假綠，合法輸入 controls 同批執行。修復對準 marker 狀態機、各階段結果、結構化 workflow 與程序樹生命週期。保留既有安全／授權／雙 OS／結果聚合防線；只有 canonical 實體檔重複 lint 取得直接盤點證據，其他字句 gate 未取得等價覆蓋證據，不先刪除。新 regression 無實際主機連線或真實 CA；runner 反例測實際 entry，故 child 逾時屬生命週期 RED，不是模型或 provider 行為。
  - 日期來源:direct
  - 放棄:以全套原有 1576 PASS 證明沒有缺口；先改程式再改 expected；只抽 cleanup function 或用字數／測試數下降當品質改善
  - 重議:新的 gate 仍有可重現假綠／誤紅，或另一形式檢查取得可證偽的等價替代覆蓋時
  - 關聯:CI 測試可信度與必要覆蓋;M-20260916-ci-test-sharding;tests/test_ci_confidence.py

- **D-20261007-ci-supervisor-signal-flag · 2026-10-07 shard supervisor 的 signal handler 只記旗標**：實作中的初版 handler 直接 raise，隔離 fixture 在 OS 已建立 child、Popen 尚未回傳登記前送 TERM，重現 supervisor 非零但 shard 繼續存活。改成 handler 記中斷旗標，完成 spawn 的 ownership 登記後才停止 launch／poll，finally 清理專屬 process groups；同一 fixture GREEN，既有實際 runner 的 INT／TERM／child 中斷 controls 仍 GREEN。此為本次候選實作的啟動邊界缺口，與原始 runner 的 descendant 清理缺口分開記錄。
  - 日期來源:direct
  - 放棄:在 handler raise exception，將尚未登記 child 的啟動窗口留給 finally 猜測；用全機 process-name 掃描補清理
  - 重議:process spawn 或 signal 模型改變時，以啟動邊界和實際 runner fixtures 重驗所有權與清理
  - 關聯:D-20261007-ci-confidence-regression-first;tests/shard-supervisor.py;tests/test_ci_confidence.py

- **D-20261007-ci-measured-integration-split · 2026-10-07 依 section 時間把 integration 分成三個獨立區段**：使用者在外部 observer 基線完成後以「繼續」授權本地優化。採 plan（9b–12b）／review（12bb–16）／runtime（turbo–結尾）的連續切分，不拆單一行為 suite 或移除 timeout／signal controls；加上 core／ship_state，保留同一 OS job 內五 shard。跨段盤點找出 plan 的 gh-local、runtime 的 section 19 ship-state baseline，以及 review-state script 路徑：獨立 shard 自建必要 Git／provider stub fixtures，路徑提升至共同前置。原五段 assertion body bytes 保持（只移出該路徑宣告），新三段實際 assertion 順序與舊 integration raw log 分別精確相同（112／383／668）；manifest 合計仍為 1574，integration 聚合入口保留。首次本地 parallel exit 0、136.994s；新三段 104／137／116s，對照本項上一版最長 shard 332s。實際 runner 清理測試改從 manifest 取得完整 shard 名集合，INT／TERM／child 中斷及 spawn race 的 11 組 controls 在 Bash 5.3 與 3.2 均 GREEN。
  - 日期來源:direct
  - 放棄:按 assertion 數平均切分、依賴其他 shard 的 tmp 副作用、增加 OS matrix jobs、刪掉慢的安全反例；以單次本機改善當作 hosted CI 保證
  - 重議:完整 serial／parallel 結果不一致、新跨段依賴、hosted CPU／I/O 成本或 section 排名改變時，依原始結果重新配平；雙 OS PR CI 仍待當批具名 delivery 授權
  - 關聯:M-20261007-ci-section-profile;D-20261007-ci-supervisor-signal-flag;CI 測試可信度與必要覆蓋;docs/testing-contract.md

- **D-20261007-deep-review-primary-responsibility · 2026-10-07 Deep-review 分離 aggregate subject 與 reviewer primary responsibility**：#274 的原始三份 packets checksum 一致且都含完整 39-file subject；controller 的 assignment schema 只有 repo／concern，無法驗證同 repo 的 12／14／13 path ownership。修復前新增的真實 controller CLI regression 已取得 RED：共用 repo 的自由文字分工仍被接受。採結構化 canonical repo → exact subject paths，先驗 primary 完整聯集、互斥性與合法邊界；packet 另列 primary_scope，aggregate immutable scope 保持完整，必要 semantic dependents 不限於 primary ownership。Single reviewer／互斥 whole-repo 舊輸入可無歧義展開；同 repo 的多 reviewer 缺少 primary 則在 dispatch 前停止，不從 concern 猜邊界。保留 ordinary 完整責任、fresh identity、完整結果集合、drift／attempt history gates 與既有 topology；readonly execution 限制另按 required facts 判斷，不用忽略錯誤或 desired-verdict prompt 洗成 complete。
  - 日期來源:direct
  - 放棄:把 aggregate scope 改成每位的 path 子集而失去完整 fingerprint 錨點；只改 prompt 卻讓 controller 仍接受漏檔／重複 primary；從自由文字猜 paths；讓所有 reviewer 繼續承擔整份 broad subject
  - 重議:exact subject paths 無法表達實際必要 responsibility 時，先保留新的 failing fixture，再擴充有界 representation；不可省略 aggregate coverage 或把 required evidence 缺失改標 complete
  - 關聯:#274;D-20260823-portable-deep-review;docs/plans/2026-10-07-deep-review-primary-responsibility.md;tests/review-primary-scope.py

- **D-20261007-runtime-deployment-summary · 2026-10-07 日常 runtime 部署摘要保留遷移與失敗診斷**：使用者回報 brewup 每次先印完整 JSON，並授權採成功摘要／遷移明細／失敗完整診斷。基線 6ddb7a5 的真實共用 entry 在隔離 canonical fixture 全 roots unchanged、exit 0、home 不變時仍印 36 行 apply／guard-config-home JSON；修復前新增回歸的 unchanged、migration 明細、缺 CLI 摘要三案 RED，原 JSON 與部分失敗 controls GREEN。採 layout CLI 明示 --summary、共用 entry 啟用該旗標；直接 CLI 保留預設 JSON。formatter 僅處理已成功的 apply／guard，失敗 report 不摘要，不改 migration／ownership／writer／transaction 判準或各部署 caller 的 exit 契約。
  - 日期來源:direct
  - 放棄:把 stdout 全重導到 /dev/null（失去 partial success／writer／receipt 診斷）；只改 brewup 而讓共用入口其他 caller 持續印相同雜訊；將工具的預設 JSON 改為人類摘要而破壞既有驗收 reader
  - 重議:caller 需要完整 machine-readable deployment report 時，以直接 CLI 取得；摘要出現不可辨識的失敗或能力缺項時，先補真實 failing fixture 再調整 formatter
  - 關聯:runtime-layout-convergence;scripts/ensure-runtime.sh;scripts/ensure-runtime-layout.py;tests/runtime-layout.py;docs/repo-guide.md

- **D-20261007-macos-archive-metadata · 2026-10-07 macOS 打包預設抑制 AppleDouble，完整 metadata 明示單次取消**：使用者要求 dotfiles 預設 COPYFILE_DISABLE=1；先以真實 macOS tar、xattr 與 resource fork 重現自動 AppleDouble，再在 setup 產出的 .zshenv 設預設。實測環境變數空字串仍啟用抑制，使用者同意將原提議的空值覆寫改成 env -u COPYFILE_DISABLE tar；父 shell 預設保留。變數不去除 PAX xattr 或現成 .DS_Store／._*，嚴格打包以 macOS tar 的 --no-mac-metadata --no-xattrs 加 exclude 處理，地雷入口與細節按既有分工記錄。Git 忽略只補缺少的 ._*；既有 write-mac-defaults.sh 納入網路磁碟 DSDontWriteNetworkStores，維持 Darwin guard 與獨立套用。Bash 設定只由 Linux setup 管理，GNU/Linux tar 不使用此變數，macOS zsh 的 bash child 已繼承，故不新增 BASH_ENV 或改 Linux shell 初始化。使用者確認原 writer 停止並移交本批重疊範圍與 dossier stewardship；原 Runtime 工作不續作，也不宣告其結案。
  - 日期來源:direct
  - 證據:tests/test_mac_metadata.py 修前 exit 1；本機 bsdtar 3.5.3／libarchive 3.7.4 的 raw archive 對照；macOS tar -tf 會隱藏 AppleDouble，改以 Python tarfile 驗證
  - 放棄:以 COPYFILE_DISABLE= 空值當成恢復 metadata；以 Git ignore 或 tar -tf 證明 tar 產物乾淨；新增 bash 非互動初始化機制；對 live preferences、setup 或主機執行部署
  - 重議:需要預設移除所有 xattr 或其他打包工具產生 metadata 時，先重現該工具再調整範圍；Linux 實際 tar control 保留於既有 Ubuntu CI，不用 macOS stub 冒稱已在 Linux 執行
  - 關聯:setup-mac-env.sh;git/gitignore_global;write-mac-defaults.sh;claude/CLAUDE.md;claude/known-hazards.md;tests/test_mac_metadata.py

- **D-20261008-ci-critical-path-before-selection · 2026-10-08 #279 先量測最慢分片，延後完整依賴選測**：使用者認可成本評估並以 `$project spec` 建立較小的工作契約。近期 20 個已合併 PR 按 #279 的 runner／部署／全域設定 fallback 規則估算，至少 14 個仍須全跑；此為累積 PR diff 的抽樣推論，不是 selector 執行結果或所有 CI 輪次的比例。PR #283 macOS run 37625167880 的 core／review elapsed 分別為 269／459s，顯示必跑 core 與最慢分片均須先定位；不能直接把原始耗時當成選測後的下限或效能承諾。PR #278 最後一顆只改結案文件，但累積 PR diff 仍包含 runner，普通 PR 差異選測無法直接省掉這輪。先以有界量測與隔離試驗判斷保留完整覆蓋的縮時機會，具體驗收以 active contract 為準；未有穩定收益時維持現狀。
  - 日期來源:direct
  - 放棄:立即實作完整依賴選測並持續維護跨 skill 圖；把最後一顆 commit 的文件差異當成整個 PR 的影響範圍；把 core 當成幾秒鐘的全域 gate；以刪除安全反例換取省時
  - 重議:小範圍、可獨立選測的實際 CI 輪次比例提高，且保守原型在多輪同環境對照中有穩定收益、維護成本可接受時，再評估依賴選測
  - 關聯:#279;#278;#283;M-20261007-ci-section-profile;M-20261007-ci-shards-local-validated;M-20261007-ci-required-accepted;https://github.com/jjshen-eland/dotfiles/actions/runs/37625167880/job/112804967002

- **D-20261008-ci-controller-shard-trials · 2026-10-08 以同一獨立 controller suite 的兩種分片位置試驗縮時**：完整基線確認本機 parallel 的 review 156s，其他 shards 為 core 41／ship_state 55／plan 101／runtime 109s；serial 的 review-repair-controller.py 單獨占 77.183s。該 suite 自建 TemporaryDirectory、Git 與 state，只讀 ROOT 的 shared scripts，不使用 shell runner 的其他 fixture。選擇兩個獨立候選：初版將原執行 block 原封移至 ship_state 或 core，同步各自 manifest 的一個 assertion 及 testing contract 描述；不改 controller／測試案例／timeout，不新增分片或依賴選測。Block SHA256 e4fb0404c419efd17d55ceaf134770dfd85b645d8f94ec86edb959cc2bc529de 兩候選相同。初版漏掉 legacy integration，已先取得實際 RED，見 X-20261008-ci-shard-move-integration-coverage；修正版以同一 helper 保留 integration 原呼叫位置，body 去除函式縮排後與原 block 的 SHA 相同。這是使用者「開工」範圍內的 repo 外試驗，正式 repo code 保持唯讀；改善仍待交錯對照，不能以估計的分片加總當實測。
  - 日期來源:direct
  - 放棄:先拆 controller 本體／更改安全等待或刪測試；增加新 background worker 與清理責任；靠 skill 名稱建立新的選測圖
  - 重議:候選無穩定收益、fixture 或環境受移位影響、assertions 不完整，或 hosted 分片成本與本機不同時，保留原分配；不新增第三個候選
  - 關聯:#279;M-20261008-ci-critical-path-baseline;D-20261008-ci-critical-path-before-selection;tests/review-repair-controller.py;tests/run.sh;tests/shard-manifest.tsv;X-20261008-ci-shard-move-integration-coverage

- **D-20261008-ci-core-controller-recommendation · 2026-10-08 #279 推薦 core 靜態重分配，仍不建立依賴選測**：修正版三組固定來源、交錯順序對照為 baseline/core 164.3495/116.8221、core/baseline 118.0903/181.6935、baseline/core 190.4371/117.6620s。基線中位數 181.6935s（範圍 164.3495–190.4371），候選 117.6620s（116.8221–118.0903），中位數差 64.0315s／35.241%；配對分別省 47.5274／63.6032／72.7751s，最小收益大於基線範圍差 26.0876s。六次 captured environment 相同、來源前後一致、1576 個具名 assertions 多重集合相同。已確認本機 review 長工作集中是可改善的關鍵路徑，推薦 controller 在 core 呼叫的候選；正式採用仍須 serial／integration／失敗控制及後續 hosted 雙 OS 驗收。ship_state 初版 pilot 137.9383s 比 core 初版 121.9351s 慢，兩者均完整覆蓋但 legacy integration 不完整，僅作初選資料；不推薦 ship，不混入修正版穩定性數據，也不增加第三候選。
  - 日期來源:direct
  - 成本:本次由首輪完整基線到最後正式 repo suite 共 89.47 分鐘（含自動等待與分析，不等同人工作業時間，未含前置 spec／準備），屬一次性量測；原始時間與定義見暫存 measurement-elapsed.json。正式候選只涉及 tests/run.sh、tests/shard-manifest.tsv、docs/testing-contract.md；controller body／cases／supervisor／聚合器不改，不新增 worker、selector、skill 內容或日常 benchmark。預估本地採用加既有驗證需 30–60 分鐘，不含 PR review／排隊；後續維護仍是既有 manifest 漂移檢查及 integration 相容呼叫。若 hosted 每輪也至少省本機最小值 47.5s，約 38–76 輪有等價等待時間回收；此回收估計只計後續採用成本，未含上述既有量測投入；若合計量測與預估採用，約 151–189 輪。這是有條件的量級估計，並非已證明的 hosted 收益。使用頻率低或 hosted 不改善時應保留／回復原分配，停止擴張調查。
  - 證據:/tmp/dotfiles-ci-profile.a7iOFZ/paired-v2-{1,2,3}-{baseline,core}/{raw.log,result.json}、paired-v2-summary.json；trial-core-v2.patch SHA256 13e923525d9061dda376fa3c1f327356bbc068e8b324059fb8919dd1e4c65a14。由 baseline-overlay.patch 的 frozen baseline 重建：原 controller block 抽成單一 run_review_controller helper，在 core 尾端呼叫；review 原位置只在 integration 呼叫；manifest core 173→174、review 384→383；testing contract 說明歸屬與相容性。不要以不同版本／環境的 hosted logs 宣稱加速已落地。
  - 放棄:建立完整依賴圖以跳測；只以較快單次或估算分片加總決策；將一次性 benchmark 加入平常 CI
  - 重議:hosted 雙 OS 出現回退／未改善、測試負載後續顯著變動，或受支援入口覆蓋不一致時，重新核對實際最慢分片；未有新證據不擴成選測系統
  - 關聯:#279;D-20261008-ci-critical-path-before-selection;D-20261008-ci-controller-shard-trials;X-20261008-ci-shard-move-integration-coverage;M-20261008-ci-critical-path-baseline

- **D-20261008-ci-controller-adoption-local · 2026-10-08 #279 使用者授權三檔候選正式採用與本地 commit**：使用者選擇上一輪選項 1「正式採用，完成本地修改、驗證與 commit」。本批由 codex:macos-archive-metadata 接手 tests/run.sh、tests/shard-manifest.tsv、docs/testing-contract.md，原 Runtime writer 已停止的事實沿 STATUS；其他 Runtime 工作不續作，四份自有量測文件一併保存。採用既有 checksum 的 core 候選，不重新量測三組 benchmark；相同 runner／manifest 及 controller／supervisor bytes 使先前 integration／失敗控制證據仍適用，正式 checkout 與 clean clone 全套驗證另做。Testing contract 將 all 的順序明確寫成 runner 分片順序，避免搬移後仍稱 testcase 原位置。Endpoint 僅本地 commit；push／PR／merge／部署及 hosted 效能驗收另待具名授權。
  - 日期來源:direct
  - 放棄:擴大接手整個 Runtime item；以測量證據取代正式 repo 的完整驗證；把此選項當作 shipping 授權
  - 重議:來源 bytes 不同、未知 working-tree 修改或 active writer 恢復並行時停止該寫入並重新協調
  - 關聯:#279;D-20261008-ci-core-controller-recommendation;M-20261008-ci-critical-path-measurement-complete;tests/run.sh;tests/shard-manifest.tsv;docs/testing-contract.md

- **D-20261008-brewup-bun-global-update · 2026-10-08 brewup 納入 bun 全域套件自動更新**：使用者明確要求加入 `bun update -g`，取代 2026-08-11 的只提示設計。已安裝 bun 時直接執行一次、保留 stdout／stderr；無 bun 時略過；失敗另外警告並保留 brewup 既有 exit 0。依本機 bun CLI help 保留 package.json 版本範圍，不加 `--latest`。`allup` 呼叫同一 brewup 腳本，後續採用也會涵蓋此步驟。舊 legacy milestone 沒有 stable ID，本筆以檔案與日期明確取代其 bun 提示政策，保留原歷史。
  - 日期來源:direct
  - 放棄:保留 outdated 表格解析作為更新前置；附加 --latest 跨越原生版本範圍；吞掉更新失敗診斷
  - 重議:使用者另指定版本策略或 brewup 失敗 exit 契約時，以當批需求調整；本批只完成本地來源，不執行真實套件更新或部署
  - 關聯:docs/archive/milestones-2026-08.md（2026-08-11 brewup bun 提示）;scripts/brewup.sh;docs/repo-guide.md;docs/testing-contract.md;tests/run.sh

- **D-20261009-small-change-delivery-spec · 2026-10-09 #285／#279 以完整交付耗時重新建立改善規格**：使用者在唯讀診斷後明示 `$project spec`，並以選項 1 確認前任停止、由本 session 接續 exact workline `codex:brewup-bun-global-update`；本輪只寫規格。PR #289 已將第一批完整退版至 main `d0a4624820b9c462d9a9bb14764164c22cdb3384`。新規格先處理 #285 可歸因的證據重建與流程往返，再評估 #279 的紀錄文件 CI 路徑，將新增保存／核對成本與最終回報一起納入驗收。PR #288 的 1244.449 秒只到同步清理觀測，macOS job 329 秒；其餘不全稱模型思考。最新 macOS core 294 秒，hosted 子項尚未歸因；不把整個 core 當廉價全域 gate。使用獨立 worktree、branch `docs/workflow-delivery-spec`；原 checkout 的 claude/settings.json 是使用者確認的 runtime drift，不納入、不改動。原 Runtime writer／scope 與 work item 保留，不接續該產品目標；四個 coordination fields 以 STATUS 為準。
  - 日期來源:direct
  - 放棄:原樣恢復退版功能；只憑測試次數、輸出 bytes 或局部 benchmark 建議採用；先建完整依賴圖、永久快取或另一層治理；以歷史交付授權開新 PR
  - 重議:固定 scope 的完整操作成本穩定下降且必要失敗 controls 通過才考慮候選採用；收益被波動或新增成本抵銷時保留未驗收並停止追加機制。實作及任何交付仍待當批授權
  - 關聯:Issue#285;Issue#279;PR#288;PR#289;X-20261009-workflow-verification-economy-revert;D-20261008-ci-critical-path-before-selection;D-20261008-ci-core-controller-recommendation;docs/plans/2026-10-08-workflow-verification-economy.md

- **D-20261009-ci-record-selection-candidate · 2026-10-09 #279 為既有紀錄文字建立有界 CI 候選**：使用者「開工」授權本地實作與驗證。第一個 #285 指引候選無淨收益而撤回後，依既有規格處理每個 PR 無條件執行全套的成本。只允許整個 PR 修改既有 STATUS／backlog／history／plan 一般檔案且 heading 未變；實際必要集合為 kernel、xref、RealRetrievalCorpusTests（含當前 corpus 的 audit --ship）。其餘 scope、未知差異、merge tree 不符及 symlink 別名均全套 fallback，保留雙 OS job 與既有 runner。先前 code commit 不得被最後的 docs commit 掩蓋；選擇器的 Git fixtures、故障傳播與外層取消控制已通過。補充檢查重現縮排／空 heading 被誤判 records，先加 RED 後補足 ATX／Setext 判定；完整驗證及固定來源效能比較仍進行中。
  - 日期來源:direct
  - 放棄:一般 Markdown 一律略過全套；只看最新 commit；整個 core 必跑；新依賴圖或持久 cache；修改 required check 名稱；把本地結果當 hosted／完整交付驗收
  - 重議:必要 gate 漏失、scope 誤分類、取消清理失敗或固定條件無時間收益時撤回／修正候選；hosted 與真實交付仍待當批具名授權
  - 關聯:Issue#279;Issue#285;D-20261009-small-change-delivery-spec;X-20261009-log-scope-latency;tests/run-ci.py;tests/test_ci_selection.py;docs/testing-contract.md


- **D-20261009-ci-system-redesign · 2026-10-09 #285／#279 改以整體 CI 與驗證流程重構**：使用者明示把本項當成重構或重寫，既有項目逐漸堆積，不能預設不能動。新有效規格 supersedes:D-20261009-small-change-delivery-spec 的有界候選限制，以及 supersedes:D-20261009-ci-record-selection-candidate 作為後續設計上限的限制；已合併來源及歷史證據保持可追溯。驗收改以失敗攔截、測試分層、變更影響、平台必要性與完整交付成本，不要求保留既有測試數、分片或逐項雙 OS 全套。可合併、下移、重寫或移除測試，但須說明原保障的承接或退役理由。先作整體設計、分段驗證與替換；同一次 snapshot 的 Git 查詢批次化不再預定為主方案。更新同一 STATUS／plan，不建立另一份平行工作契約；本次只修改規格，執行中的 CI 尚未變更。
  - 日期來源:direct
  - 放棄:把既有測試與分片當不可改的前提；用不斷增加 wrapper／gate 處理架構問題；只以測試數下降、局部 wall time 或歷史相關性宣稱整體修好
  - 重議:新架構以具名反例、模組／整合行為與固定條件耗時驗證後採用；不得為速度遮蔽必要的合併前失敗。遠端設定、送出及部署仍依當批具名授權
  - 關聯:Issue#285;Issue#279;D-20261009-small-change-delivery-spec;D-20261009-ci-record-selection-candidate;M-20261009-delivery-cost-historical-controls;docs/plans/2026-10-08-workflow-verification-economy.md

- **D-20261009-setup-tool-ownership · 2026-10-09 Setup 共用工具清單與逐台歸屬對齊**：使用者授權 setup 改版、shell 環境與 npm 措辭一致，續指定只調整 setup 定義工具，不更動每台自行安裝工具。採 core／workstation 共用清單；新增 actionlint、ast-grep，shfmt 選配；git-delta 因 Git 設定依賴保留 core。Antigravity 改專案選配，supersedes:M-20260918-antigravity-cli-provisioning 的新機必裝契約，既有安裝依 ownership 保留；舊必裝測試退役，Codex cask 控制由新模組承接。新安裝與明示 adoption 留逐台 ownership ledger，沒有舊安裝收據時一律不由 command 存在推定歸屬；--keep 保存本機用途。只對已納管且不再選用的直接套件做移除，停用自動清理／全面升級；僅納管且能力不足者可具名升級，過期相依項目阻擋安裝／升級。原 setup 的 brew exit 42 被 pipeline 吞掉已用隔離替身重現；新入口傳播失敗。shell fallback 共用 Bash／Zsh，不設定全域 BASH_ENV；既有 shell 只加入管理區塊並保留原內容。既有專案依 lockfile／packageManager／runtime，不禁止 npm 或強制 Bun。
  - 日期來源:direct
  - 放棄:依舊清單一律接管並刪除；以 brewup 全面升級達成有界對齊；重跑整份 setup；自動清掉相依套件；將本地 fixture 當 14 台已完成證據
  - 重議:新來源進 origin/main 且獲當批部署授權後，逐台核對 adoption／keep，再 macOS 與 Linux 各一台試跑；需要共享相依升級或解除本機保留時另行核對，不擴大本次 apply 邊界
  - 關聯:scripts/dev-tools.tsv;scripts/dev-tools.sh;scripts/align-dev-environment.sh;shell/environment.sh;tests/test_dev_environment.py;README.md

- **D-20261010-global-cli-preferences · 2026-10-10 全域工具提示採短任務映射**：使用者確認完整工具清單在 always-on 的成本與兩端可見性問題，接受以 rg／fd、jq／yq、ast-grep、gh、shellcheck／actionlint 的任務映射取代 Claude 舊清單，同段加入 Codex 全域入口。只在不確定時查可用性，偏好非互動輸出，缺工具先考慮既有等效工具，只有任務需要缺少的能力才安裝。移除「缺了就 brew install」；不改專案套件管理原則與 Homebrew ownership 邊界。
  - 日期來源:direct
  - 驗證:完整 suite 120.970 秒，29 模組通過、selection 因縮小 fixture 缺兩端文件而失敗；已以 FileNotFoundError 重現提前退出，補齊 fixture 並新增 missing／empty／duplicate／drift 拒絕控制，selection 定向重驗 exit 0、11.006 秒，原失敗傳播與取消清理案例均恢復通過。文件 audit 通過；完整首次執行證據保存在同機 `/tmp/global-cli-guidance-evidence`，不把失敗結果稱為全套單次全綠。
  - 放棄:在全域逐一列全部安裝／選配工具；每次強制讀 manifest；為簡短提示引入新共用載入檔；把安裝清單等同每台工具現況
  - 重議:兩端原生入口各保留同一短段，既有 content gate 比對缺失／重複／漂移。完整安裝定義仍在 scripts/dev-tools.tsv，人用工具表仍在 docs/repo-guide.md；未做模型行為 eval，不宣稱提示一定改變選用率。新增工具只有可證明需要常駐提醒時才加入，本批尚未 push／部署。
  - 關聯:D-20261009-setup-tool-ownership;claude/CLAUDE.md;codex/AGENTS.md;tests/content-checks.py;STATUS.md

- **D-20261010-setup-bottle-dependency-guard · 2026-10-10 Setup bottle 安裝不要求更新未使用的編譯依賴**：fleet 續跑預檢證明只更新 ca-certificates 後仍會被 curl／libgit2 等 build tree 的舊版本阻擋。eagle03 的 Homebrew dry-run --force-bottle 只計畫安裝 actionlint／ast-grep；正常 runtime deps 為 actionlint 的 gmp／libffi／shellcheck 與 ast-grep 的空集合，均已安裝，不需要實際更新整棵編譯依賴。既有 guard 不分 source／bottle 是第一個因果差異。
  - 日期來源:direct
  - 決定:formula 宣告提供 bottle 且執行期依賴全部已安裝時，以 --force-bottle 安裝或修復 owned tool，只檢查 runtime deps 的 outdated 狀態；不存在可用 bottle 時由 Homebrew 非零退出，禁止 source fallback。原本不提供 bottle 的配方（如 Bun）、任何 runtime 缺項及 cask 維持原完整 build／implicit 依賴檢查；不放寬既有個人工具保全與 ownership。使用者本批已核准七台 ca-certificates 限定更新，其他既有套件仍不得升級。
  - 證據:真實 dry-run 及 brew deps；本機 Homebrew formula_installer.rb check_install_sanity 明確拒絕 force_bottle 且不可 pour 的情況。三個反例在 3f64eaa helper 上 RED（過期未使用 build dependency、無 bottle 不得退回 source、已安裝 runtime 仍被 compiler 阻擋），修正後 39 個隔離測試通過；新增 outdated runtime 與 missing runtime 保護 controls；Bun 真實 metadata 顯示 bottle=false，追加兩個先 RED 後 GREEN 的相容控制。首版整批 30 模組通過 116.726 秒，metadata 相容調整後定向補驗。原 force removal assertion 誤把 --force-bottle substring 當 --force，改按 exact argv token 檢查，仍拒絕強制移除。
  - 放棄:逐顆放行不會用到的 compiler tree 更新；全面 brew upgrade；直接跳過所有依賴檢查；只刪 include-build 卻允許 source fallback；對尚有缺項的 runtime tree 套用例外
  - 重議:本地修正待更新同一 PR #297、必要 CI 與實機驗收；如 Homebrew bottle runtime 與宣告相依出現可觀察差異，先停下該目標核對實際安裝計畫，不擴大升級範圍。
  - 關聯:D-20261009-setup-tool-ownership;M-20261010-setup-fleet-partial;STATUS.md;docs/testing-contract.md

- **D-20261010-transfer-delivery-overhead · 2026-10-10 Dotfiles 準備原子移交至 Claude delivery-overhead**：使用者先明確叫用 Transfer，指定 current steward `codex:brewup-bun-global-update` 與 recipient `claude:delivery-overhead`，再明確叫用本 worktree 的 Project Log merge endpoint。Portable-knowledge、三項 active mapping、獨立 next workspace、credential separation 與 fresh clone QA 已驗證；settings 新增欄位由使用者確認為 runtime drift，原 checkout 保留並排除於移交。本 record 與所有 active items 的 Steward／assigned Writer／Workspace／第一個 next step 收在同一顆 transfer commit，Write Scope 與未完成目標保留。
  - 日期來源:direct
  - Current steward:`codex:brewup-bun-global-update`
  - Next steward:`claude:delivery-overhead`
  - Canonical handover endpoint:`git@github.com:jjshen-eland/dotfiles.git` 的 `main`
  - Effective condition:包含本 decision、docs/transfer.md 與全部 active-item 原子切換的 transfer commit 已 merged 至上述 canonical endpoint，且 remote-visible ancestry 證明該 commit 可達。條件未成立時，STATUS／active plan 的 next actor coordination fields 只是 conditional pending values，effective steward／writer 依指南的 transfer 前 mapping；條件成立才是 TRANSFERRED。
  - Parent evidence:準備基線 `e8e226dbe8b9818ad9123ac85ec6f25797d3def3` 保留三項原 assignment；指南列完整 current／next mapping。Runtime、#285、Setup 的 next workspace 分別為 `branch=fix/delivery-overhead-runtime-layout`、`branch=perf/delivery-overhead-verification`、`branch=chore/delivery-overhead-setup`；均不沿用舊 workspace 或 transfer branch。
  - 驗證:準備時 fresh no-local clone 全套 30 模組 exit 0／111.672 秒，415 個 inputs 前後無漂移；原失敗 Python 3.9 與 dev-env 的 Python 3.14 controls 見指南。Log 只補當前 lifecycle 文件檢查；本 record 寫入時 PR／CI／merge／endpoint 尚待，不宣稱移交生效。
  - 放棄:只改部分 active items；以 local commit、feature push 或 open PR 宣稱 TRANSFERRED；讓 next steward 自行撿回未整合工作；把 runtime drift、credentials 或前批外向授權混入移交
  - 重議:recipient、mapping、endpoint、原 assignment 或已知 in-flight 工作改變時重跑 Transfer gates；無法取得 remote-visible ancestry 時停止 authority 切換。原 work items 保持 active，不因換 steward 結案。
  - 關聯:STATUS.md item 2／3／4;Issue#285;docs/transfer.md;docs/plans/2026-10-06-runtime-layout-convergence.md;docs/plans/2026-10-08-workflow-verification-economy.md
- **D-20261010-delivery-overhead-spec · 2026-10-10 #285 改以 CI 路由、平台矩陣、紀錄減量與端到端量測為驗收**:唯讀診斷顯示小改動交付時間以開 PR 前的 agent 收尾為最大段，CI 次之；CI 多數退回全套是因為路由覆蓋不足，而不是選測設計本身。使用者選定四項：補齊 CI 路由、平台無關 controller 只跑 Ubuntu、紀錄減量契約、端到端交付量測，取代 2026-10-09 版的五項驗收。
  - 日期來源:direct
  - 放棄:縮減 Project reference 載入（#246 已量過收益不足）；把 Ubuntu 的 brew 安裝改走 apt（不在關鍵路徑）；修改受信任 doc-governance scanner 來機檢紀錄長度（會牽動 fleet byte-identical 契約，改由 repo 測試承接）
  - 重議:端到端量測顯示開 PR 前的耗時不隨紀錄量下降時，重新定位主因
  - 關聯:Issue#285;Issue#279;supersedes:D-20261009-ci-system-redesign 的驗收條件;D-20261010-transfer-delivery-overhead
- **D-20261010-ci-route-deletion-evidence · 2026-10-10 CI 路由以刪除實驗定 consumer，新增／刪除一般檔依路徑選測**:測試原始碼的文字參照分不出「讀取」與「只提到名稱」，遞移推斷會把多數檔案推回全套，也會漏掉 Python 路徑組合與動態呼叫（如 content 呼叫 `{scanner}-gate.py`）。改以乾淨 clone 刪除整組路徑後跑全套，失敗模組即該組路由；再由 content 的 route drift 檢查守住日後新增的完整路徑讀取。一般檔的新增／刪除與修改同樣依路徑選測，mode／symlink 變動與未知路徑仍回全套。
  - 日期來源:direct
  - 放棄:純文字遞移 oracle（過寬且仍漏動態路徑）；Linux 容器 strace 追蹤（需先證明容器網段安全，且需另維護生成產物）；`push: main` 事後全套（第 25 節禁止以合併後重驗取代 PR gate）
  - 重議:出現路由內模組以外的失敗被合併後才發現，或 route drift 例外清單持續增長時
  - 關聯:Issue#285;Issue#279;D-20261010-delivery-overhead-spec;M-20261010-ci-route-coverage-local
