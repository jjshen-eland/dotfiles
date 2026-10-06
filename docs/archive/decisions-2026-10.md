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
