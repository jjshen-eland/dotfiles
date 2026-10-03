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
