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
- **D-20261010-ci-controller-platform-evidence · 2026-10-10 review-controller、turbo、ship-state 在 CI 只跑 Ubuntu，deep-plan 保留雙平台**:依 test workflow 近 149 次 run 中 17 次單平台失敗逐一歸因：deep-plan 有 6 次只在 macOS 失敗，根因是 `launch-reviewers.py` 的 process-group 權限與 signal 重入缺陷（M-20260915-b07-timeout-zombie-oracle-fixed、M-20260917-deep-plan-signal-single-cleanup、M-20260918-deep-plan-timeout-cleanup），屬真實平台差異，不移。ship-state 的 3 次只在 Ubuntu 失敗都是測試 harness 的 `echo | grep -q` SIGPIPE 偽紅，與受測程式無關；review-controller、turbo 無單平台失敗。靜態掃描這三個模組實際執行的程式：僅 `fcntl.flock`（兩平台語意相同）與 ship-state.sh review-terminal 時間的 BSD／GNU `date` 雙路 fallback，後者輸出沒有任何測試斷言，移出 macOS 不減少斷言。PR #301 實測 macOS 全套 166 秒、Ubuntu 87 秒；依各模組秒數估算移出後 macOS 約 112 秒。限制只作用於 `tests/run-ci.py`，本地 runner 照跑全部選定模組。
  - 日期來源:direct
  - 放棄:四個 controller 全移（deep-plan 有 macOS 專屬真實缺陷）；以 workflow `if` 或拆 job 實作（會改 required check 形狀）；以環境變數覆寫平台（多一個可繞過的旋鈕）
  - 重議:移出的模組出現只在 macOS 主機重現的缺陷；或 macOS CI 的 Python 版本差異（現為 Homebrew 3.14、Ubuntu 3.12）造成這些模組行為分歧
  - 關聯:Issue#285;D-20261010-delivery-overhead-spec;D-20261010-ci-route-deletion-evidence;PR#301
- **D-20261011-record-volume-plan-choices · 2026-10-11 紀錄減量規劃的四項取捨**:使用者核定：部署後結案是否併入下一個 PR，先以服務型 repo 情境驗證再定；dotfiles milestone 上限 1,500 B；testing-contract 既有事件證據本批清除並整份機檢；實作前以 deep-plan 審查計畫。依據為 12 個 KB platform repo 的唯讀盤點（本項計畫 Phase 0）。
  - 日期來源:direct
  - 放棄:上限 1,200 B（dotfiles 現有僅 7% 符合，其他 repo p90 亦多超過）；只檢查 testing-contract 新增內容
  - 重議:Phase 2 證明部署後結案的取捨不可接受，或上限造成必要證據被移出紀錄
  - 關聯:Issue#285;D-20261010-delivery-overhead-spec
- **D-20261011-record-volume-scope-narrowed · 2026-10-11 #285 第 3 項縮小為 dotfiles 專屬兩條，排在 turbo 移除之後**:deep-plan 第一輪 NO-GO，兩位 reviewer 獨立判阻斷：dotfiles 的結案 commit 都隨程式 PR 送出、沒有多跑 CI，純紀錄 PR 是部署結果、本機量測與 backlog 更正，全機隊條文 1、2 幾乎沒有可量收益，還會牽動 log-prepare 提交規則、authority 與 turbo 停止條件。使用者選擇只保留 milestone 1,500 B 上限與 testing-contract 只寫規則，撤下 merge／CI／fleet 不補記與 Workspace 同步兩項驗收，並等 item 5 移除 turbo 後再修訂計畫重審。
  - 日期來源:direct
  - 放棄:重新設計全機隊條文（收益未量到、衝突多）；第 3 項整個不做
  - 重議:端到端量測顯示紀錄撰寫或純紀錄 PR 是交付時間的主要成本
  - 關聯:Issue#285;D-20261011-record-volume-plan-choices;supersedes:D-20261010-delivery-overhead-spec 的第 3 項驗收
- **D-20261011-turbo-retirement-choices · 2026-10-11 turbo 移除計畫的三項取捨**:deep-plan 第一輪兩位 reviewer 實測部署腳本不會移除已刪 skill 的殘留連結，並指出 native-review 只服務 turbo。使用者核定：殘留的 `~/.claude/skills/turbo`、`~/.agents/skills/turbo` 在獲授權的散佈步驟逐台刪除，不改 item 2 的 ensure-runtime-layout 契約；native-review 子命令、schema 與相關測試一併移除，eval 的 Codex 臂改用一般收集流程；第二批以 inventory 14 台確認為準，兩台 inventory 外 MacBook 依既有 pull＋brewup 路徑收斂。
  - 日期來源:direct
  - 放棄:在 ensure-runtime-layout 加入懸空連結清理（屬 item 2 範圍且受 writer gate 阻擋）；接受殘留連結（CLI 行為未驗證）；保留 native-review（無一般流程使用且文件只綁 turbo）；等兩台 MacBook 確認才刪腳本（可能無限期延後）
  - 重議:有主機在第二批後只 git pull 就啟動 Codex 而出現 hook 錯誤；或需要原生 review 程序證明的新需求出現
  - 關聯:D-20261005-turbo-delegated-controller;D-20261006-turbo-native-evidence-transitions;D-20260917-terminal-macbooks-outside-inventory;STATUS item 5
- **D-20261011-turbo-direct-deletion · 2026-10-11 turbo 一批直接刪除，不留過渡空殼**:deep-plan 第二輪指出刪除空殼後，仍持有舊 hooks 的 session 與只 pull 的主機會執行不存在的腳本（實測 exit 2，Claude Code 視為阻擋）。使用者認為空殼與等待期都會被遺忘，選擇一批刪除 turbo-state.py，空窗期改由散佈步驟處理：dotsync 後重開各主機的 Claude Code／Codex session，本機合併時先清 branch、最後 pull 再重開，inventory 外 MacBook 恢復時跑 brewup 並重開。
  - 日期來源:direct
  - 放棄:永久保留空殼（留下無主檔與永久例外）；等待期後刪除（會被遺忘）
  - 重議:散佈後仍出現未重開 session 卡在 hook 錯誤且難以辨識的情況
  - 關聯:supersedes:D-20261011-turbo-retirement-choices 的兩階段散佈;STATUS item 5
- **D-20261011-primary-scope-eval-cross-runtime · 2026-10-11 primary-scope eval 保留 Codex 臂，收集方式移入 eval**:使用者指出工作流跨 Claude Code 與 Codex 使用，退役 Codex 臂會失去 deep-review 在 Codex 端的行為證據。改把 native-review.py 的 Codex 收集（codex exec 隔離旗標、子行程環境清除、快照與獨立性檢查）移入 tests/review-primary-native-eval.py，schema 搬到 tests/fixtures 供兩臂使用；controller 的 native-review 子命令與 proof 檢查照 D-20261011-turbo-retirement-choices 移除，並以假 codex transport 測試守住 incomplete report 保留。
  - 日期來源:direct
  - 放棄:退役 Codex 臂（失去跨 runtime 證據）；改用 deep-plan 的 launch-reviewers.py（綁定計畫審查參數且屬 codex tree）
  - 重議:deep-review 在 Codex 端有正式的 reviewer 收集路徑時，改用它
  - 關聯:supersedes:D-20261011-turbo-retirement-choices 的 schema 移除;STATUS item 5
- **D-20261011-turbo-plan-nogo-proceed · 2026-10-11 turbo 移除計畫在 NO-GO 下修正後直接實作，改以 code review 把關**:deep-plan 兩批四輪都是 NO-GO，第 2 批最後一輪的新 finding 集中在前一輪修正新增的段落（eval 搬遷、本機合併序列、決策鏈），屬修 A 引入 B，且多為只能對實際程式查證的細節。使用者選擇把該輪 findings 修進計畫後直接實作，以 RED 測試與 deep-review 審查實際 diff 承接殘留風險，不再開第 3 批計畫審查。
  - 日期來源:direct
  - 放棄:第 3 批計畫審查（預期繼續在新增細節上產生同型 finding）
  - 重議:deep-review 在實作 diff 上發現計畫層級的設計錯誤
  - 關聯:D-20261011-turbo-retirement-choices;D-20261011-turbo-direct-deletion;D-20261011-primary-scope-eval-cross-runtime;STATUS item 5
- **D-20261011-turbo-retired · 2026-10-11 移除 turbo skill 與只服務它的 native-review**:turbo 與 deep-plan／deep-review／project 的耦合、7＋7 個 hooks、兩份全域指令行與 README 節一併移除；deep-review controller 不再有 delegated-reentry／refresh-subject／native-review，primary-scope eval 的 Codex 收集移入 eval。被刪的 skill prose 只在已啟用 turbo 委任時生效，移除後該前提不存在；一般流程的行為不變，由 controller 機械測試守住，因此不重跑 behavior eval。
  - 日期來源:direct
  - 放棄:保留 turbo 但拆出耦合（使用者判斷其配合本身即增加複雜度）
  - 重議:出現需要跨回合自主續跑到交付的明確需求
  - 關聯:supersedes:D-20261005-turbo-delegated-controller;supersedes:D-20261006-turbo-native-evidence-transitions;supersedes:D-20261006-turbo-native-report-collection;supersedes:D-20261006-turbo-public-help;supersedes:D-20261010-ci-controller-platform-evidence 中 turbo 只跑 Ubuntu 的部分;D-20261011-turbo-retirement-choices;D-20261011-primary-scope-eval-cross-runtime;STATUS item 5
- **D-20261011-recall-alias-canonical · 2026-10-11 title-free recall 以實體路徑判命中**:「開工前的計畫審查什麼時候值得跑」的前 5 名中，canonical `shared/skills/deep-plan/evals.md` 被新決策紀錄擠出，只剩指向同檔的 `claude/skills/deep-plan/evals.md`，ratchet 由 6/10 退到 5/10。使用者選擇讓測試把 compatibility link 解析成實體檔再判定；字面路徑命中仍照算。只有這一題改判，其餘 9 題不變；拿掉解析即回到 5/10。
  - 日期來源:direct
  - 放棄:改 `find` 去重別名（需改受信任 scanner 並對全機隊 rollout）;改寫決策紀錄措辭（違反 append-only，且是為過測試調內容）
  - 重議:出現別名與 canonical 內容不同的 compatibility link
  - 關聯:D-20261011-turbo-plan-nogo-proceed;STATUS item 5
- **D-20261011-out-of-inventory-reminder-only · 2026-10-11 inventory 外終端只提醒、不列結案條件**:turbo 退役散佈時，原計畫把兩台 inventory 外 MacBook 的 brewup 與重開 session 列進 STATUS item 5 的 Acceptance Criteria，使該項須等常離線的筆電恢復使用才能結案。使用者指示 inventory 外的機器（現為兩台，日後可能更多）只要提醒、不列為結案對象。散佈類工作的結案以 `scripts/inventory.conf` 內主機（本機計一次）的逐台證據為準；inventory 外終端在結案回報中提醒其本機更新路徑（`docs/repo-guide.md`），不阻擋結案，也不宣稱已驗證。這延續 D-20260917-terminal-macbooks-outside-inventory 的自主更新模型。
  - 日期來源:direct
  - 放棄:等 inventory 外終端恢復並回報後才結案（結案時點取決於筆電何時開機，與變更本身無關）
  - 重議:inventory 外終端改為受 fan-out 管理，或某項變更沒有本機收斂就會破壞那些終端的資料或安全
  - 關聯:D-20260917-terminal-macbooks-outside-inventory;D-20261011-turbo-direct-deletion;STATUS item 5
- **D-20261011-record-rules-before-size-cap · 2026-10-11 紀錄改以內容規則定義，撤下由分布推出的長度上限**:#285 第 3 項的 milestone 1,500 B 上限，是從無限制時期寫成的長度分布反推（1,200 B 只有 7% 合規故放寬）。這是循環論證：樣本正是被懷疑過長的寫法，分布推不出應有長度，也分不出被刪的是冗詞還是可追溯資訊；以 10 月資料為例，標題行中位約 890 B，超出部分多在重議與關聯子項。使用者指示先做端到端量測，並改為定義紀錄的規則、內容格式、必要資訊與書寫原則。長度若仍需要，應由必要內容的重寫範例推出，統計只用於估影響與反證。
  - 日期來源:direct
  - 放棄:以中位數／p90／合規比例選上限（無判準、循環）；不先量測就實作上限
  - 重議:端到端量測顯示紀錄撰寫不是交付時間的明顯成本時，重新評估是否仍需要規則
  - 關聯:supersedes:D-20261011-record-volume-plan-choices 的 milestone 1,500 B 上限;D-20261011-record-volume-scope-narrowed;Issue#285;STATUS item 3
- **D-20261011-delivery-measurement-next-targets · 2026-10-11 量測後第 3 項改為紀錄品質，讀規則與狀態偵測列為後續縮時目標**:回溯 dotfiles 51 次真實交付，寫紀錄中位 73 秒、佔扣等待後時間約 9–11%，96% 是模型生成；讀流程 reference（94 秒，約 14%）與狀態偵測（86 秒，約 13%）合計比它大兩倍以上。使用者同意：第 3 項保留，目標改為紀錄的規則、格式、必要資訊與書寫原則（品質與可追溯性），不以省時間為理由、不設長度上限；讀 reference 與狀態偵測的縮時列為 #285 後續項目。
  - 日期來源:direct
  - 放棄:以時間為由撤下第 3 項（紀錄品質的需要與時間無關）；繼續以寫紀錄為主要縮時對象（佔比小）
  - 重議:新量測顯示寫紀錄佔扣等待後時間持續超過 25%
  - 關聯:D-20261011-record-rules-before-size-cap;Issue#285;STATUS item 3
- **D-20261011-protocol-records-to-workflow-simplification · 2026-10-11 流程規定的紀錄內容留待 steward／transfer 流程簡化處理**:紀錄撰寫規則的計畫與兩種流程規定的紀錄衝突：endpoint 未達成時的 milestone（log-prepare 結案規則）與移交時的 conditional owner decision（transfer-workflow）。兩者都是把流程狀態寫進 append-only 歷史：前者因 milestone 與實作同 commit、早於 merge，後者的狀態原有 `docs/transfer.md` 可放。使用量顯示這套機制比實際工作模式重：自 2026-09-01，有 Writer 欄位的 106 個 STATUS 版本中 17 個同時有 2 個 writer，steward 始終只有 1 個；正式移交只發生 1 次（D-20261010-transfer-delivery-overhead），移交指南當天退役；約半數使用權限檢查的互動 session 遇到確認題（含開發該機制的 session，偏高）。使用者決定：紀錄規則不改這兩種紀錄的現行要求，另列 #285 的流程簡化工作項，依使用狀況改善 steward、writer、transfer 與 dossier 流程的工作體驗。
  - 日期來源:direct
  - 放棄:在紀錄規則中為流程紀錄設永久例外（兩套判準並存）；在紀錄規則工作中一併改 log-prepare 與 transfer（牽動 authority 檢查，需獨立規劃與審查）
  - 重議:流程簡化工作項決定保留這兩種紀錄的現行寫法
  - 關聯:D-20261011-record-volume-scope-narrowed;D-20261011-delivery-measurement-next-targets;D-20261010-transfer-delivery-overhead;Issue#285
- **D-20261011-record-rules-fleet-wide · 2026-10-11 紀錄撰寫規則改回全機隊，理由由省時改為品質**:使用者指示 D／X／M 紀錄規則寫進全機隊共用的 project skill，取代「只做 dotfiles 專屬兩條」的範圍。原縮小理由有二：收益未量到、牽動 log-prepare 與 authority。前者原指交付時間，量測後已改以紀錄品質為目標（dotfiles 抽樣無實質缺陷 M 4/16、D 5/15）；後者由 D-20261011-protocol-records-to-workflow-simplification 移到流程簡化工作項。其他 repo 是否有同樣缺陷尚未量測，於規則計畫 Phase 0 補抽其他 adopted repo。
  - 日期來源:direct
  - 放棄:只寫 dotfiles 專屬位置（其他 repo 用同一 skill 寫紀錄，缺陷來源相同）
  - 重議:其他 adopted repo 抽樣顯示缺陷率明顯低於 dotfiles
  - 關聯:supersedes:D-20261011-record-volume-scope-narrowed 的範圍限制;D-20261011-protocol-records-to-workflow-simplification;D-20261011-delivery-measurement-next-targets;Issue#285
- **D-20261011-positional-refs-resolution · 2026-10-11 STATUS item 與 #285 項次引用的解讀對照**:下列紀錄以 STATUS 或計畫的項次指向工作項目，且未附計畫路徑；項次會隨 STATUS 增刪而懸空，故以本紀錄固定解讀。「STATUS item 5」與「item 5」指「移除 turbo skill 與其他 skill 的耦合」，計畫 docs/plans/2026-10-11-turbo-retirement.md，已由 M-20261011-turbo-retired 結案。「STATUS item 3」「第 3 項」「#285 第 3 項」指 docs/plans/2026-10-08-workflow-verification-economy.md「第 3 項：D／X／M 紀錄撰寫規則（全機隊，2026-10-11 修訂）」。「#285 第 1、2 項」指 D-20261010-delivery-overhead-spec 定義的 CI 路由補齊與平台無關 controller 只跑 Ubuntu。「#285 第 N 項」的編號屬該計畫，不是 Issue#285 本文「工作範圍」的條列編號。D-20261011-turbo-retirement-choices 的「item 2」指 STATUS 工作項「Runtime 目錄收斂與 legacy 遷移」。D-20261011-record-volume-plan-choices 的「本批」「本項」指上述計畫第 3 項的前一版草稿。
  - 日期來源:direct
  - 放棄:改寫原紀錄（已 commit 紀錄不改不刪）
  - 重議:none
  - 關聯:D-20261011-record-volume-plan-choices;D-20261011-record-volume-scope-narrowed;D-20261011-turbo-retirement-choices;D-20261011-turbo-direct-deletion;D-20261011-primary-scope-eval-cross-runtime;D-20261011-turbo-plan-nogo-proceed;D-20261011-turbo-retired;D-20261011-recall-alias-canonical;D-20261011-out-of-inventory-reminder-only;D-20261011-record-rules-before-size-cap;D-20261011-delivery-measurement-next-targets;M-20261011-ci-platform-matrix-merged
- **D-20261011-record-rules-no-record-check · 2026-10-11 紀錄撰寫規則不做 dotfiles 新增紀錄機檢**:使用者決定 #285 紀錄撰寫規則只寫在 project skill 的 dossier.md，以成對實驗逐條決定是否採用、送出後以實際新紀錄的缺陷率判斷是否有效；dotfiles 不另對新增紀錄做撰寫規則機檢。原設計（自創欄位、位置式引用、四子項、commit 標記、疑似 SHA）經 deep-plan 審查，每補一個例外就出現新的旁路或誤擋：全數字 CI run ID 與跨 repo commit 被判成 SHA、搬移標記可自我宣告繞過、未採用的規則仍由機檢擋人。機隊其他 repo 本來就只有 dossier.md 的規則。保留 testing-contract 整份事件字樣檢查與紀錄 ID 存在檢查，範圍是單一檔案、判準已在該檔逐行查核。
  - 日期來源:direct
  - 放棄:dotfiles 新增紀錄撰寫規則機檢（例外與旁路持續增加，且只保護 dotfiles）
  - 重議:送出後觀察的新紀錄中，某條可機械判定的規則缺陷率未低於規則前，且該缺陷能以不誤擋合法證據的判準辨識
  - 關聯:D-20261011-record-rules-fleet-wide;D-20261011-record-volume-plan-choices;docs/plans/2026-10-08-workflow-verification-economy.md;Issue#285
- **D-20261012-record-checks-two-precise · 2026-10-12 紀錄機檢恢復缺子項與引用本 branch commit 兩項**:使用者選定 #285 紀錄撰寫規則恢復兩項 dotfiles 新增紀錄機檢，判準是寫錯會永久損害（紀錄 append-only）且能精確判定。缺子項（放棄、重議、關聯，無則 none）是現行規則，2026 年 26 筆缺漏、24 筆在 10 月。引用本 branch commit 只比對 merge-base..HEAD 的 commit 前綴，CI run ID 與其他 repo 的 SHA 不會命中；2026 年紀錄引用的 SHA 有 20% 已在 GitHub 查不到；這項只在該規則經成對實驗採用後啟用。其餘不機檢：暫存路徑當唯一證據在 108 筆含暫存路徑的紀錄中只命中 1 筆，機器分不出關鍵證據；位置式引用會誤擋解讀它的更正紀錄；自創欄位與 #數字 標題不造成永久損害。
  - 日期來源:direct
  - 放棄:全部不機檢（缺子項與本 branch commit 的損害永久且可精確判定）；恢復暫存路徑唯一證據機檢（幾乎抓不到）
  - 重議:Phase 3 觀察中暫存路徑或位置式引用的缺陷未低於規則前，且出現不誤擋的判準
  - 關聯:supersedes:D-20261011-record-rules-no-record-check 的「不做任何新增紀錄機檢」;docs/plans/2026-10-08-workflow-verification-economy.md;Issue#285
- **D-20261012-record-checks-reverted · 2026-10-12 紀錄撰寫規則回到不做 dotfiles 新增紀錄機檢**:使用者決定撤回缺子項與引用本 branch commit 兩項機檢，#285 紀錄撰寫規則不做任何新增紀錄機檢。「本 branch commit」只涵蓋仍在 merge-base..HEAD 的 commit，amend／rebase 後的舊 SHA 與 cherry-pick 整合時 worker 的原 SHA 會放行，「可精確判定」的前提不成立；以 merge-base 為基準的機檢在 commit 後才變紅時與「已 commit 不改不刪」衝突，fixture 也缺 default branch 基準，缺子項機檢同樣受影響。規則本身與 Phase 3 的生效前後各 15 筆比較承擔這些缺陷。
  - 日期來源:direct
  - 放棄:保留兩項機檢（覆蓋不完整且帶出新例外）
  - 重議:Phase 3 比較中缺子項或失效 commit 引用的缺陷未低於生效前，且出現不依 merge-base、不與 append-only 衝突的判準
  - 關聯:supersedes:D-20261012-record-checks-two-precise;D-20261011-record-rules-no-record-check;docs/plans/2026-10-08-workflow-verification-economy.md;Issue#285
- **D-20261012-record-rules-dropped · 2026-10-12 D／X／M 紀錄撰寫規則不實作，紀錄缺陷不再監測**:使用者依風險分層評估選定結束 #285 第 3 項，不新增撰寫規則、不做成對實驗與 Phase 3 觀察、不清理 `docs/testing-contract.md` 的事件敘述。評估找到的實際後果都來自規則文件或 skill 寫錯，沒有 D／X／M 格式缺陷導致做錯事的實例；計畫經 deep-plan 6 批 8 輪全 NO-GO（約 4.5 小時 active）。Phase 3 以 15 筆人工判讀比較，統計上無法判定規則有效，先前「不做機檢」所依賴的補償並不存在；使用者在此前提下接受紀錄缺陷不被監測的取捨。
  - 日期來源:direct
  - 放棄:照原計畫的成對實驗與 Phase 3 觀察（成本高且無法判定）；只寫一條持久指標指引而不跑成對實驗（不符 skill 規則變更的證據門檻）
  - 重議:出現因 D／X／M 紀錄缺陷而做錯事的具體事件
  - 關聯:supersedes:D-20261011-record-rules-fleet-wide;D-20261012-record-checks-reverted;D-20261011-record-rules-no-record-check;docs/plans/2026-10-12-project-process-reduction.md;Issue#285
- **D-20261012-dotfiles-active-item-contract-off · 2026-10-12 dotfiles 關閉 STATUS active-item contract**:使用者選定刪除 dotfiles `.doc-governance.json` 的 `status_schema.active_item_contract`，讓 steward-authority 回 `NOT_APPLICABLE`、scanner 不再要求 Writer／Workspace／Write Scope／Dossier Steward。2026-09-01 起 261 個 STATUS 版本只有 17 版同時有兩位 Writer、steward 都是同一使用者的 session 代號、正式移交 1 次；steward-authority 實地攔下 3 次（皆為漏建 active steward），另有 10 次 merge 中 8 次 false STOP 的紀錄。實際發生過的平行寫入事故（`git add -A` 誤收他線工作）由 kernel 安全底線的 foreign changes STOP 接住，不依賴這些欄位。不改 scanner、skill 或 kernel；其他受治理 repo 各自決定。
  - 日期來源:direct
  - 放棄:維持現行四欄位與 steward 授權檢查（成本集中在確認題與欄位維護，攔截都是自身簿記）
  - 重議:dotfiles 出現第二位真人 contributor、正式移交，或平行 session 造成 STATUS／history 寫入衝突
  - 關聯:D-20261011-protocol-records-to-workflow-simplification;D-20261010-transfer-delivery-overhead;M-20260928-project-merge-production-red-captured;docs/plans/2026-10-12-project-process-reduction.md
- **D-20261012-project-reduction-scope · 2026-10-12 #285 第 5、6 項合併為 /project 流程減量**:使用者選定把流程開銷與流程簡化合併成一項，依序移除 test-evidence 沿用協定、逐條清點 ship-state STOP 與 wait-required-enrollment、PR 已承載的實作結果不另寫 milestone 也不另開補記 PR、最後縮減必讀 reference，每步量測且可回退；不新增 gate、不改受信任 scanner 與 kernel。依據是 51 次真實送出扣等待後中位 760 秒，其中讀 reference 約 15%、狀態偵測約 12%、本地測試與證據約 27%；test-evidence 與 enrollment 沒有攔下過失敗，enrollment 有 3 次誤擋已授權 merge。
  - 日期來源:direct
  - 放棄:只做零／低風險三步其餘暫停；兩項都終止
  - 重議:任一步改後的真實交付耗時或讀取量沒有下降，或移除的 gate 所防風險實際發生
  - 關聯:supersedes:D-20261011-delivery-measurement-next-targets 的「第 5 項另列」;D-20261011-protocol-records-to-workflow-simplification;docs/plans/2026-10-12-project-process-reduction.md;Issue#285
- **D-20261012-deep-plan-full-review-routing · 2026-10-12 deep-plan 完整審查限高風險計畫，NO-GO 後不 restart**:使用者同意 agent 給 deep-plan 路由建議時，只在計畫含不可逆步驟、機隊部署或符合 deep-plan workflow §1a 時建議完整審查。一批 NO-GO 後，findings 是文件措辭或細節就修進計畫直接實作，以 RED 測試加 deep-review 審實際 diff 承接；顯示設計不成立就請使用者縮小或放棄；只有指向未查明事實時才查明後再審。#285 第 3 項 6 批 8 輪全 NO-GO，每批多在修上一批新增的機制；turbo 移除計畫 4 輪 NO-GO 後改由 code review 承接，code review 實際找到需修正的問題。不改 deep-plan skill 本體。
  - 日期來源:direct
  - 放棄:計畫連帶權威檔就建議完整審查、猶豫就跑（成本主要是使用者時間而非 token）；把 NO-GO 後的預設寫進 skill（缺成對實驗證據）
  - 重議:依此路由略過或提前結束審查的計畫，在實作或部署後出現審查本可攔下的設計錯誤；或再次出現連續 restart
  - 關聯:D-20261011-turbo-plan-nogo-proceed;D-20261012-record-rules-dropped;shared/skills/deep-plan/references/workflow.md
- **D-20261012-title-free-recall-ratchet-retired · 2026-10-12 退役 title-free 召回 ratchet，題組改為手動量測工具**:使用者選定刪除 `tests/test_doc_governance.py` 中對當下語料量 hit@5 與單檔佔位的 ratchet；`tests/fixtures/doc-governance/title-free-recall.tsv` 改標為改 `find` 排序時在同一 commit 語料上手動量改前改後的工具，保留題目不洩漏標題的檢查。逐題檢討：10 題中 5 題的預期不再適用（前提已被模組化選測改變、已決定不修的跨語言落差、同一規則另有 kernel 權威檔、前綴涵蓋整個 `shared/skills` 造成假命中、主題已有直接回答的決策紀錄），原門檻 6 含 1 題假命中；門檻是 2026-08-22 當時的命中數，原服務的 B-20260821-debt-27 已於 2026-09-15 結案。兩天內兩次變紅都是合法、正好回答該題的新紀錄擠掉唯一正解，未找到攔下 scanner 退步的實例；討論該測試的紀錄引用題目原文而排到第 1，污染量測。scanner 的排序行為由 synthetic 測試承接（標題自查第 1、每檔佔位上限與回填、history 標題邊界、reason boost）。
  - 日期來源:direct
  - 放棄:門檻降到 5（未檢討題目、結構誤擋仍在）；改寫新紀錄措辭以過測試；重寫題組後續當 gate（單一正解與自我污染仍在）；替判準加入決策紀錄命中等機制
  - 重議:`find` 的排序在真實語料上出現 synthetic 測試未攔下、且影響實際查找的退步
  - 關聯:supersedes:D-20261011-recall-alias-canonical;M-20260915-b27-title-free-recall-revalidated;D-20260915-b27-cross-language-boundary;tests/test_doc_governance.py;tests/fixtures/doc-governance/title-free-recall.tsv
- **D-20261012-live-corpus-ranking-tests-kept · 2026-10-12 真實語料排名測試維持在 content 模組**:檢討 `retrieval.tsv` 的 top-5 命中與 unique title 第 1 名兩項後，使用者選擇維持現狀。兩項目前未找到攔截也未誤擋，每次 content 約 10 秒；結構上同樣是單一正解對當下語料，有 3 題排在第 3–4 名。移到 `document-regression` 不適合：該模組也由 project／deep-plan／deep-review／handoff skill 變動與全套選到，#301–#307 重放仍有 3／7 會執行；scanner 本身是全套觸發檔，content 已涵蓋 scanner 變動；且違反 `docs/testing-contract.md` 中 document-regression 只跑 synthetic、不重跑 corpus 的設計。
  - 日期來源:direct
  - 放棄:移到 document-regression（減量有限、無新增保護、推翻 synthetic／corpus 分工）；比照 title-free 立即退役（尚無誤擋，沒有實際痛點）
  - 重議:任一項因語料變動而非 scanner 退步變紅，即比照 D-20261012-title-free-recall-ratchet-retired 退役
  - 關聯:D-20261012-title-free-recall-ratchet-retired;tests/fixtures/doc-governance/retrieval.tsv;docs/testing-contract.md
- **D-20261012-test-evidence-removal · 2026-10-12 Project 收尾改為在最終 commit set 一律執行測試，移除 test-evidence 沿用協定**:使用者在量測後選定移除。2026-10-04 起 9 個 repo、96 個 Log run 中 38 個使用協定：協定成本約 76.6 分鐘，主要是組指令與 evidence JSON 的模型生成時間；REUSE 扣除剛跑完同一測試的情形後實際省下約 10.0 分鐘；NEED_TEST 73 次協定照付、測試照跑。改為一律執行後，48 個原本沒跑測試的 run 估計新增約 19.5 分鐘；合計淨效益約 −47 分鐘，9 個 repo 中 8 個為負，krepo-judicial 約 +0.4 分鐘、接近打平。各 repo 全套測試耗時中位數 11–62 秒。D-20261004-project-reuse-mechanical-adoption 的重議條件要求遇到錯用或重跑時優先補機械 oracle；本次量測顯示成本來自協定本身而非錯用，故改為移除而非加強。作者摘要冒充證據與引用未重跑的非測試結果，在新規則下都只靠 prose；使用者接受這兩項殘留風險，依據是 9 個 repo 中 8 個有 required status checks 會在 merge 前攔下未執行的測試，改判準後的 native case 只是驗收當下的一次性檢查。量測方法、非測試沿用的成員與變更範圍見 `docs/plans/2026-10-12-project-process-reduction.md`「第 2 步細節」。
  - 日期來源:direct
  - 放棄:保留協定（9 個 repo 中 8 個淨效益為負）；只在 dotfiles 移除（協定位於全機隊共用 skill）；量測前照原計畫移除（前提只在 dotfiles 驗證過）；移除 tested 類 native case（會失去觀察摘要冒充證據的唯一入口）
  - 重議:出現全套測試耗時遠高於協定成本的受治理 repo，且收尾重跑成為該 repo 交付的主要成本；或改判準後的 native case 顯示模型以摘要或先前結果代替執行
  - 關聯:supersedes:D-20261003-project-test-evidence-reuse;supersedes:D-20261004-project-reuse-mechanical-check;supersedes:D-20261004-project-reuse-mechanical-adoption;D-20261003-project-reuse-evidence-boundary;M-20261004-project-test-evidence-reuse;docs/plans/2026-10-12-project-process-reduction.md
- **D-20261012-test-evidence-ci-backstop-caveat · 2026-10-12 test-evidence 移除的 CI 攔截依據限縮為「設有 required status checks」**:更正 D-20261012-test-evidence-removal 中「9 個 repo 中 8 個有 required status checks 會在 merge 前攔下未執行的測試」的表述：已查證的是 8 個 repo 設有 required status checks（dotfiles 為 classic protection，其餘 7 個為 ruleset），各 repo CI 執行的內容是否與本機測試相同未逐一核對，因此 CI 能否攔下 Log 未執行的那些測試屬推論。使用者接受殘留風險的決定不變，依據以本筆為準。
  - 日期來源:direct
  - 放棄:直接修改原紀錄（已 commit 的紀錄不可改）
  - 重議:核對各 repo CI workflow 後發現 required checks 未涵蓋本機測試
  - 關聯:supersedes:D-20261012-test-evidence-removal 的「會在 merge 前攔下未執行的測試」;docs/plans/2026-10-12-project-process-reduction.md
- **D-20261012-ship-state-stops-kept · 2026-10-12 ship-state 的 STOP 與 wait-required-enrollment 清點後全部保留**:使用者選定 #285 第 3 步不移除任何 STOP。依 transcript 統計實際執行輸出，其他受治理 repo 中 doc-governance STOP 是常用的文件 gate；bootstrap 類罕見但防的是新 repo 首推把錯的 branch 當 default 的不可逆後果；review-terminal 兼有真攔截（審查以 blocking-findings／blocked-review 收場後又送出）與已有結案路徑的 legacy 訊號；`wait-required-enrollment.sh` 是等待 required check 出現的工具，實際回 ENROLLED 33 次，評估時記為「0 次攔截」是用錯衡量方式。狀態偵測的耗時主要在讀取與解讀輸出，移除 STOP 省時有限，改由縮減 reference 處理。
  - 日期來源:direct
  - 放棄:移除 enrollment helper（會讓等待 CI 啟動回到 prose 判斷）；開測試 PR 實測 GitHub 行為（helper 的功能不依賴該結果）；逐筆判讀 review-terminal 的實地 STOP 再決定（現有分類已足以判定保留）
  - 重議:某一 STOP 的實地誤擋明顯多於攔截且有其他機制涵蓋同一風險；或 enrollment helper 的 UNOBSERVED／QUERY_ERROR 成為 merge 的主要阻礙
  - 關聯:D-20261012-project-reduction-scope;docs/plans/2026-10-12-project-process-reduction.md;shared/skills/project/scripts/ship-state.sh;shared/skills/project/scripts/wait-required-enrollment.sh
- **D-20261012-record-reduction-dropped · 2026-10-12 #285 第 4 步紀錄減量不做**:使用者選定不做「PR 已承載的實作結果不另寫 milestone、merge 後不另開補記 PR」。依 PR 標題與檔案分類，2026-07 起 46 個只改紀錄的 PR 多為獨立的 backlog 結案、機隊部署結果與早期 STATUS 整理；merge 後另開 PR 補 milestone 在 2026-10 只有 #305 一次，因 log-prepare 已要求 milestone 隨實作 PR 寫成 endpoint pending。這一步會牽動 kernel「milestones at event time」與由工具維護的 `AGENTS.md` portable managed block，代價高於收益。STATUS 的 Writer／Workspace／Write Scope／Dossier Steward 欄位照舊保留。
  - 日期來源:direct
  - 放棄:照原計畫規劃並跑 deep-plan（收益小、牽動 kernel 與 managed block）；只刪 dotfiles STATUS 的四個 coordination 欄位（無機械後果，也無實際成本）
  - 重議:merge 後另開的紀錄專屬 PR 再次成為常態，或 steward 機制重設計（GitHub #309）改變 STATUS 欄位
  - 關聯:D-20261012-project-reduction-scope;D-20261012-dotfiles-active-item-contract-off;docs/plans/2026-10-12-project-process-reduction.md
- **D-20261012-content-continuity-model · 2026-10-12 跨 runtime 與跨 session 的接續改以內容契約承擔，移除 steward 身分授權**:使用者選定把 `/project` 的 steward／writer 機制改為內容契約：停手時 STATUS 工作項的目標、驗收、進度、下一步正確，未合併的工作已 commit 並 push；任何 runtime、session、主機都可接手，不需要 actor 身分、改派或 Transfer 狀態機。依據是 2026-08-25 起 179 件授權確認題中使用者直接同意 92%、選停止 0 件，112 件是同一 session 對同一 steward 重複提問，量不到任何擋下不該寫入的案例，且 helper 只認 workline 名稱、分不出兩個 session 同時工作；11 個受治理 repo 177 個工作項中跨 runtime 接續 5 項，Workspace 指向的 branch 289／299 已不存在。遷移順序：先在各受治理 repo 以 config 關閉 `active_item_contract`，再改 shared skill，最後處理移交與 kernel。量測方法與範圍見 `docs/plans/2026-10-12-content-continuity-redesign.md`。
  - 日期來源:direct
  - 放棄:保留身分模型、只把確認題改為提示（仍保留每次 Log 約 28 KB 的讀取量與名稱對不上的簿記）；先改 skill 再關各 repo config（期間 scanner 仍要求四欄）
  - 重議:出現兩個以上真人同時寫同一 repo 的共享紀錄；或內容契約下的接手實測出現 STATUS 與 git 都找不到的必要狀態
  - 關聯:GitHub#309;D-20260824-cross-runtime-dossier-stewardship;D-20260824-project-steward-authority;D-20261012-dotfiles-active-item-contract-off;docs/plans/2026-10-12-content-continuity-redesign.md
- **D-20261012-handover-to-colleague-focus · 2026-10-12 移交改為讓接手同事掌握全貌的流程，列為重點**:使用者選定保留並強化「移交給新同事」：移交處理後的 repo 要讓接收者只靠 repo 掌握系統組成、環境建置與驗證、部署排程與維運、外部帳號與 credential 存放位置、進行中的工作、決策與死路入口、已知風險與支援期限；並以移交人列出的接手驗收題組在 fresh clone 環境中由接手者或 fresh-context agent 作答、以腳本判分。移除 actor 狀態機（BLOCKED／PREPARED／TRANSFERRED、conditional owner、active-item mapping、remote ancestry），保留 portable-knowledge audit、credential 分離與 metadata helper，authorization 不隨移交。
  - 日期來源:direct
  - 放棄:完全移除移交流程（已有移交給同事的規劃）；維持現行狀態機（為多方擁有權設計，實際兩次都是 agent 對 agent，其中一次約 5.6 小時）；以人工主觀檢查判定接手者是否掌握全貌
  - 重議:第一次實際移交給同事後，接手者仍需移交人口頭補充 repo 未記載的必要資訊
  - 關聯:GitHub#309;D-20260824-memory-independent-transfer;D-20261010-transfer-delivery-overhead;docs/plans/2026-10-12-content-continuity-redesign.md
- **D-20261012-kernel-shared-work-rewrite · 2026-10-12 kernel「Shared work」段隨內容契約改寫**:使用者選定在移除 steward 身分授權時一併改寫三份 kernel 的「Shared work and durable project state」段：保留一個工作項一個 writer、平行 writer 用不同 branch／worktree 與既有安全底線，移除 Dossier Steward、Dossier delta、cherry-pick 整合與 steward 移交相關句。三份 kernel 是手動逐字維護、由 `tests/kernel-gate.py` 驗漂移，並無同步工具；`AGENTS.md` 中「由工具維護」的說明不實，一併更正。逐字內容由使用者核定後才修改。
  - 日期來源:direct
  - 放棄:先不動 kernel、接受與新流程暫時矛盾
  - 重議:none
  - 關聯:GitHub#309;D-20261012-content-continuity-model;tests/kernel-gate.py;docs/plans/2026-10-12-content-continuity-redesign.md
- **D-20261012-steward-identity-removed · 2026-10-12 移除 steward 身分授權層與 Transfer 狀態機，接續改為內容契約**:使用者核定 #309 P2：刪除 `steward-authority.py`、`authority.md` 與其測試，`/project` 的 Log、Spec、Transfer 不再解析 actor、`resume=`／`as=`、binding packet 或 conditional owner；STATUS 範本與 dotfiles STATUS 刪除 Writer／Workspace／Write Scope／Dossier Steward，dotfiles 以只要求 `Goal` 的 `active_item_contract` 重新啟用「進行中項目標題帶完成標記」與「進行中區段有 H3 以外內容」兩項檢查；三份 kernel 的「Shared work」段依核定逐字改寫。Transfer 改為產出草稿與缺項，未指名接手者、credential helper 非 PASS、仍有只存在對話或私人記憶的專案事實、在途工作未合併也未明確放棄，任一成立即維持草稿；Transfer 本身不 commit。更正 D-20261012-content-continuity-model 的「未合併的工作已 commit 並 push」：push 仍只依安全底線取得授權，未 push 的部分告知使用者，本身不 commit 的流程（ready4quit、handoff）改為回報未 commit 的內容。B-20260928-project-merge-continuation（steward／resume 誤擋）與 B-20260824-remote-human-contributor-path（非 steward 的 commit 傳遞路徑）隨機制移除而結案。受信任 scanner 不變，仍會驗證帶有 `Writer`／`Dossier Steward` 欄位的工作項，其他受治理 repo 的欄位由 P2b 移除。
  - 日期來源:direct
  - 放棄:保留 helper、只把 STOP 改為提示（仍需維護 actor 名稱與每次 Log 的讀取量）；Transfer 保留 PREPARED／TRANSFERRED（為多方擁有權設計，接手者需要的是內容而非狀態名）
  - 重議:出現兩個以上真人同時寫同一 repo 的共享紀錄；或內容契約下的接手實測出現 STATUS 與 git 都找不到的必要狀態
  - 關聯:supersedes:D-20260824-cross-runtime-dossier-stewardship;supersedes:D-20260824-project-steward-authority;supersedes:D-20260825-project-prompt-bound-authority-recovery;supersedes:D-20260923-project-session-workline-binding;supersedes:D-20260923-project-local-reassignment;supersedes:D-20260824-memory-independent-transfer 的 Transfer 狀態機部分;supersedes:D-20261012-content-continuity-model 的「commit 並 push」措辭;B-20260928-project-merge-continuation;B-20260824-remote-human-contributor-path;GitHub#309;docs/plans/2026-10-12-content-continuity-redesign.md
- **D-20261012-goal-contract-reenabled · 2026-10-12 dotfiles 以只要求 Goal 的 active-item contract 重新啟用**:#309 P2 刪除 steward 身分授權後，dotfiles `.doc-governance.json` 以 `{"required_fields":["Goal"],"uniform_fields":[]}` 重新啟用 `status_schema.active_item_contract`，恢復「進行中項目標題帶完成標記」與「進行中區段有 H3 以外內容」兩項 scanner 檢查；不再要求 Writer／Workspace／Write Scope／Dossier Steward。這推翻 D-20261012-dotfiles-active-item-contract-off 的關閉部分；該決策的理由（四欄與 steward 授權的成本）仍成立，已由欄位刪除處理。本紀錄補上 D-20261012-steward-identity-removed 漏寫的 supersedes，由 deep-review 指出。
  - 日期來源:direct
  - 放棄:維持關閉（失去兩項完成狀態檢查，而它們不依賴身分欄位）
  - 重議:Goal 必填在其他受治理 repo 造成誤擋，或需要更多必填欄位
  - 關聯:supersedes:D-20261012-dotfiles-active-item-contract-off 的關閉部分;D-20261012-steward-identity-removed;GitHub#309;docs/plans/2026-10-12-content-continuity-redesign.md
- **D-20261012-setup-adopt-review-dropped · 2026-10-12 Setup 工具對齊結案，不做既有自裝工具的 adopt／keep 整理**:使用者選定 STATUS「Setup 工具與 agent shell 環境對齊」以 M-20261010-setup-fleet-complete 結案（14／14 主機部署與重跑驗收、PR #297 合併），原列為下一步的「歷史工具歸屬／用途核對，列出需使用者判定的 adopt／keep」不做。該項不屬原驗收條件，且 Constraints 已定預設：未經確認的既有工具不納管、不移除、不升級，不整理時現狀仍安全。
  - 日期來源:direct
  - 放棄:改成 backlog 等觸發（使用者選擇不保留）；逐台列出自裝工具交使用者判定（需 SSH 盤點，無對應痛點）
  - 重議:有主機需要把自裝工具納入 setup 管理，或自裝工具與 setup 納管工具發生衝突
  - 關聯:M-20261010-setup-fleet-complete;docs/repo-guide.md
- **D-20261012-handoff-store-fallback-removed · 2026-10-12 handoff 預設 store 固定為正式位置，移除舊 store fallback**:inventory 14 台的正式 store 已驗收（M-20261007-inventory-handoff-cleanup-ready、M-20261007-macs-runtime-layout-accepted），使用者 2026-10-12 告知 inventory 外兩部 MacBook 也已手動完成，`handoff-anchor.sh store` 不再沿用 `~/.claude/handoffs`：它仍以獨立實體存在（只有舊 store，或與正式 store 同時存在）時回報 `NEEDS_UPGRADE`、exit 1，指引執行 `scripts/ensure-runtime.sh` 遷移，不自行搬移或選邊；舊路徑只是指向正式 store 的 alias 時照常使用（SHARED），`HANDOFF_DIR` override 不變。取代 D-20260823-portable-handoff-skill 中「既有 ~/.claude/handoffs 沿用」的預設 store fallback 部分，claims／authorization／archive provenance／consume-once 不變。保留項：舊 archive 命名（`YYYYMMDD-<slug>` 與秒級前綴並存）的 reader，在有無歧義的轉換方法與行為證據前不移除；`ensure-runtime-layout.py` 的 handoff 遷移與 `ensure-codex-skills.sh` 的舊 Codex skills root 清理，是殘留機器的升級路徑，保留到不再有需要升級的機器。
  - 日期來源:direct
  - 放棄:繼續沿用舊 store（兩個 runtime 可能各讀一邊）；偵測到舊 store 時自動搬移（搬移應交給有 transaction 與備份的遷移工具）
  - 重議:出現無法執行共用部署入口、只能沿用舊 store 的機器；或舊 archive 命名有了無歧義轉換方法
  - 關聯:supersedes:D-20260823-portable-handoff-skill 的預設 store fallback 部分;D-20260917-terminal-macbooks-outside-inventory;M-20261007-inventory-handoff-cleanup-ready;M-20261007-macs-runtime-layout-accepted;docs/plans/2026-10-06-runtime-layout-convergence.md;shared/skills/handoff/scripts/handoff-anchor.sh
- **D-20261012-repo-ignore-baseline · 2026-10-12 暫存目錄與工具快取由全域與各 repo 兩層都忽略**:使用者定下原則：慣例上沒有人會 commit 的位置（暫存目錄、工具快取），全域 gitignore 必須守住，各 repo 的 `.gitignore` 也預設加入。基線為 `tmp/`、`__pycache__/`、`*.py[cod]`、`.pytest_cache/`、`.ruff_cache/`、`.mypy_cache/`、`.venv/`、`.DS_Store`、`.env`；`git/gitignore_global` 補上原本沒有的 `tmp/` 與三個測試／lint 快取。各 repo 只補缺項、不改既有規則；krepo 已全數涵蓋。起因是盤點時發現 12 個 repo 只有 2 個忽略 `tmp/`：transfer 的判分檔與 credential 檔放在 `tmp/` 時會變成 untracked，造成 `--base` 選測退回全套、移交判不過，也有隨 Log 被 commit 的風險；只靠全域規則時，沒有這份全域設定的同事 clone 會重新暴露同樣問題。兩層都設之後，transfer 現有的「必須被忽略且未 tracked」檢查在各 repo 可以通過，判分檔與 credential 檔不必搬出 repo。探測缺項時只看 root `.gitignore`：pytest 與 ruff 會在快取目錄裡放自己的 `.gitignore`，直接在工作樹探測會誤判為已忽略。
  - 日期來源:direct
  - 放棄:只靠全域 gitignore（移交給同事或新主機時失效）；把 transfer 判分檔與 credential 檔搬到 repo 外（`tmp/` 被忽略後不再需要）；把 `node_modules/` 等語言專屬項目放進基線（各 repo 依語言自行加入，全域已涵蓋）
  - 重議:出現需要 commit 到 `tmp/` 或上述快取路徑的正當用途
  - 關聯:git/gitignore_global;.gitignore;docs/plans/2026-10-12-content-continuity-redesign.md;shared/skills/project/references/transfer-workflow.md
- **D-20261012-agents-state-registry · 2026-10-12 工具的跨 session 本機狀態集中到登記過的 `~/.agents/<skill>/`，由寫入工具自行清理**:使用者選定把 deep-plan 審查 journal 搬出 repo，並追問 deep-review 是否與 handoff 一樣統一到 `~/.agents`，以及 `~/.agents` 底下檔案的生命週期規則。盤點發現：deep-plan journal 寫在 plan 旁的 `docs/plans/.<plan>.review/`，是 untracked 又未忽略的位置，今天 12 次 `--base` 選測全部因此退回全套，krepo-mops-financial-statements 也留有一份；deep-review 控制紀錄放 `/tmp/deep-review-<uid>/`，但它的作用是限制審查與修復次數，`/tmp` 被系統清掉時上限會悄悄歸零（本機 10/2 開機，最舊的紀錄只到 10/10）；Codex 審查工作放在 Claude 專屬的 `~/.claude/deep-review/codex/`，127 個工作、35 MB 從未清理；`~/.agents` 本身沒有任何生命週期規則。決定：三者改放 `~/.agents/deep-plan/`、`~/.agents/deep-review/control/`、`~/.agents/deep-review/codex/`；`docs/repo-guide.md` 新增 `~/.agents` 登記表，每個子目錄寫明寫入者、內容、結束條件、保留期與清理者，未登記不得新增；清理由寫入工具在下次呼叫時執行並回報，三處都清最後更新超過 30 天的紀錄（deep-plan 另跳過被鎖住的 journal，deep-review 同步移除 index 項目）。repo 綁定的 deep-review anchor 留在 `.git/`，單次暫存檔留在 `$TMPDIR`。舊位置不寫相容程式碼：deep-plan 遇到 plan 旁舊 journal 停下並印出路徑，deep-review 舊目錄不再讀取、留給使用者刪除；代價是進行中的審查批次無法跨這次升級續跑。
  - 日期來源:direct
  - 放棄:deep-plan 改放系統暫存目錄比照舊 deep-review（同樣會被系統清掉而重置輪數上限）；在 repo `.gitignore` 忽略 `docs/plans/.*.review/`（不是慣例位置，每個 repo 都得加，且 journal 仍在工作樹）；偵測到舊位置時自動搬移或繼續沿用（ticket 內含絕對路徑，搬移不是單純 rename；沿用會留下永久相容分支）；另排 cron 統一清理（沒在用的機器不需要清，寫入工具自己清即可）
  - 重議:正常審查的實際時長接近 30 天，或有工具需要在 `~/.agents` 存放不屬於登記表任何一類的資料
  - 關聯:docs/repo-guide.md;D-20261012-repo-ignore-baseline;D-20261012-handoff-store-fallback-removed;shared/skills/deep-plan/scripts/review-state.py;shared/skills/deep-review/scripts/review-control.py;claude/skills/deep-review/scripts/codex-exec-review.sh
- **D-20261013-review-execution-snapshot · 2026-10-13 唯讀審查要執行 target 程式碼時，一律在 scope 重建出的外部快照執行**:#315。`review-scope.sh materialize --manifest <m> --dest <新路徑>` 先驗 scope FRESH，用私有 index（`GIT_INDEX_FILE` 指向暫存檔）`read-tree`＋`checkout-index` 取出 head tree，非 range 模式再疊上所選路徑的 worktree 變更（含刪除與未追蹤檔），完成後再驗一次 FRESH；`--dest` 必須是新路徑，且不在 target 根目錄或其 Git common dir 內。Controller packet 對每個 repo 附 `validation_snapshot` 指令；brief 改為「不在 target 內執行 target 程式碼，必要時在快照內執行並記錄排除項，快照做不到就回報邊界、不退回 target」，取代原本只針對 Python 的 `-B` 句；workflow 讓唯讀模式下 orchestrator 自己跑的 authoritative checks 也走快照。修後 native eval 同一 fixture：Codex（workspace-write）absent／present 各 2 次、Claude 各 1 次，target 含 ignored 與 Git metadata 全部零變動，reviewer 都先 materialize 再於快照內跑測試；純靜態對照 `two`（Codex read-only）仍 PASS。
  - 日期來源:direct
  - 放棄:runtime 層的檔案系統保護（Claude subagent 沒有逐 agent 的寫入 sandbox，Codex `spawn_agent` 繼承上層 sandbox，兩邊都無法只對 reviewer 鎖 target）；controller 在派遣前後對 target 全量 stat 比對（大 repo 的 ignored 依賴目錄成本高，且只能事後發現、擋不住）；reviewer 自行 `cp`／`git ls-files` 複製（實測 Claude 會這樣做，但 `git ls-files` 漏掉未追蹤的 subject 檔，dirty 範圍也各自解讀）；`git archive`（會套用 export-ignore／export-subst，內容可能和 head tree 不同）
  - 重議:快照排除的內容（ignored 依賴、submodule）讓必要檢查普遍無法執行；或修後任一 runtime 再次在 target 內執行
  - 關聯:Issue#315;X-20261013-review-import-write-in-target;X-20261007-review-python-isolated-bytecode;shared/skills/deep-review/scripts/review-scope.sh;shared/skills/deep-review/scripts/review-control.py;shared/skills/deep-review/references/portable-reviewer-brief.md;tests/review-readonly.py;tests/review-primary-native-eval.py

- **D-20261013-repo-check-org-default · 2026-10-13 Repo 檢查預設 elandcomtw 與一次文件基線初始化**：依使用者選定，新增 portable repo-check 的內建公司 profile，只有當輪明示替代規範才替換，不依 remote owner 或 API 權限猜規範。Profile 是 skill 的可檢查標準，與當輪 GitHub 強制政策、repo 契約分開；不把 snapshot 的 unit-tests／approval 要求硬套全部 repo。使用者要 agent 建 README／CONTRIBUTING 等初始 main 基線，因此三份 kernel 同步加入有界 document-only bootstrap 例外：feature 上 commit，verified empty remote／creation policy／exact reviewed baseline 及具名 push 授權，首推後失效；既有 default、產品 code/data 與後續直推仍禁止。Project 的 bootstrap 入口先驗上層 document-only 邊界，不再把任意 HEAD/ancestor 當可推基線。本筆只記本地 authoring，未改組織設定、未首推公司 repo、未部署。
  - 日期來源:direct
  - 放棄:所有 repo 共用固定目錄樹；由 personal remote 自動換個人規範；403/404 當無保護；空 repo 首推任意產品 HEAD；init 與一般 audit 共用 mutation 授權
  - 重議:公司正式 org-governance 發布新規範、provider creation policy 能力變更，或 frozen behavior oracle 出現新錯誤時；以來源 revision 與 observed failure 更新，不抄多份組織文件
  - 關聯:shared/skills/repo-check/references/workflow.md;shared/skills/repo-check/evals.md;shared/skills/project/references/ship-exceptions.md;AGENTS.md

- **D-20261013-project-shipping-latency-local · 2026-10-13 Project 短命令等待與本地收尾連續執行**：依使用者「開工」實作 STATUS 的 project-shipping-latency 首批。Codex 的等待工具 binding 留在薄入口，正常短命令採工具預設等待、長任務仍可 yield 並取得終態；共享 merge reference 將 outward merge 與本地收尾分開，後者以明確 `&&` 成功鏈接續，不增加另一支 helper。既有 cleanup-stale-branch.sh 承接執行當下 tip 重驗與本地刪除；push canonical cwd／獨立 call、merge exact-head、required non-watch check 與摘要契約保持原有規範。雙入口／canonical core／links topology 沿用 D-20260822-portable-project-skill 與 D-20260912-neutral-portable-skill-core。
  - 日期來源:direct
  - 證據:3 秒本地命令以 1 秒 yield 回 session 並需一次 poll，預設等待同次取得 exit 0。舊本地收尾範例正常控制通過、8 個失敗控制為 RED；第一候選增加 guards 後，fresh Claude 的條件式 shell 包裝仍令 `set -e` 失效，pull exit 42 後繼續刪 branch。deterministic conditional-context RED 重現後改為成功鏈；本地 ref query failure 另由 RED 修正為可區分不存在與查詢失敗的讀取。最終 14 個執行案例通過，並非靠 static 文字比對。
  - 放棄:只將舊範例多行一起執行；只靠 set -e 保證條件式呼叫中的停止；新增 merge／push wrapper 省略 gate；更動 CI／模型／摘要政策以試圖回收全部非命令秒數
  - 重議:下一筆真實交付仍有短命令額外 poll、連續收尾無淨收益，或新執行環境未遵守失敗停止；先保留 exact trace 與因果證據，不追加泛用規則
  - 關聯:project-shipping-latency;B-20260924-workflow-verification-economy;M-20261013-pr329-latency-root-cause;shared/skills/project/references/pressure-tests.md;tests/project-local-finish-test.py

- **D-20261013-review-fixture-maintenance-isolation · 2026-10-13 PR #330 的既有 review fixture 自動 maintenance 納入同批修復**：使用者直接選擇上一輪選項 1，接受新增 tests/review-primary-native-eval.py 的 fixture 隔離範圍，並接續同 PR 的 required checks／merge 終點。只在自建 fixture 第一顆 baseline commit 前設 repo-local maintenance.auto=false、gc.auto=0，阻止 creator 的 Git 背景 maintenance 改動 metadata；不改使用者 repo、全域 Git 或 snapshot oracle。既有本批兩次 job 執行沒有 source 修復，此處開始第 1 次 CI 修復提交，最多兩次的界線不重設。
  - 日期來源:direct
  - 證據:兩次 hosted CI 的 .git/objects/maintenance.lock 遍歷／lstat 競態；隔離 GIT_TRACE 顯示 baseline commit 啟動 maintenance --auto --quiet --detach。新增真 Git regression 在 global maintenance.auto=true／gc.auto=1 下，舊 prepare() 因缺 repo-local 隔離為 RED；修後需在 baseline commit trace 無 maintenance run、local 配置正確、read-only status 前後全 metadata snapshot 相同。原 import 寫入偵測與中斷清理測試仍保留。
  - 放棄:忽略消失的 lock 或修改 snapshot 範圍；全域關閉 Git maintenance；增加 blind CI rerun；以新增 fixture 配置代替 required CI 通過
  - 重議:修後 hosted CI 仍失敗或其他 fixture 另有背景寫入時，按具體因果處理，不擴成全 repo 配置變更
  - 關聯:M-20261013-pr330-shipping-ci-blocked;B-20260924-workflow-verification-economy;PR#330;tests/review-primary-native-eval.py;tests/review-primary-scope.py
  - 本地驗證:新增 RED 修後通過，review-primary-scope 的 17 個案例 exit 0／25.646 秒（/tmp/pr330-fixture-repair-focused.log），未重跑模型 eval；整批與 hosted 驗證接續於本輪 Log。
