# Deep-plan 新版模型內容品質評估

- 工作項：deep-plan-model-behavior
- 日期：2026-10-03
- 狀態：implemented
- 種類：audit
- Writer／Dossier Steward：`codex:deep-plan-model-behavior`
- Workspace：`branch=refactor/deep-plan-model-behavior`
- 需求來源：使用者「接著看deep-plan」，延續 #246 與 review skills 新版模型內容品質判準。
- 基線：`04fc6027b5293f42a67266c34a9111251ec23f37`；開始前 main 乾淨。
- 範圍：本機內容與行為評估；未授權 commit、push、merge 或部署。

## Baseline 與判準

現行雙薄入口、neutral shared references、Codex deterministic launcher 已 portable；D-20260825-deep-plan-empty-wait／M-20260825-portable-deep-plan-revalidation 與 X-20260825-deep-plan-duplicate-port 不支持再次移植或重寫。Focused transport 尚未在入口啟用，不用新評估默默切換策略。固定 gpt-6.1-sol/high/Standard 與 Opus 5.5 [1m]/high/Standard；模型認定必須以實際 capture 為準。無自行設定費用、tokens 或總時限；原 launcher 的既有 timeout 不改，不外推 CLI exit 為完成品質。

Reviewer-stage 單一控制：只移除 brief §4 的通用逐條查證列表，保留其餘目的、嚴重度、歷史失效模式、語意相依、criteria grid、只讀與輸出契約。原文／控制各以三案 × 雙 runtime 比較：可執行跨 repo 驗收（wire 設計仍有真破壞）、正確 plan／低級行號漂移、告警豁免的不同成因與集合。觀察真漏報、誤阻擋、同類／相依覆蓋與額外架構擴張，不以省字或 finding 數評分；direct reviewer 不冒充 full orchestration。

原文完整路徑：相容可回復 increment → READY-FOR-INCREMENT、真正產品歧義 → NEEDS-DECISION，均不派 reviewer 或偷改 code；explicit full wire plan 允許作者只改同一 scratch plan、修復真實 wire 破壞、跑兩轮 N2，不能強制未要求的永久 carrier；實際 permission／alert 判準 → full 並停在未授權的 disposition gate。Target repos 及 source 前後比對含 Git metadata；plan edit 僅在明示授權的 full case 允許。

只有實測可歸因收益才採指令修改；觀察失敗先保留 raw evidence 並區分 fixture／runtime／skill 根因。若沒有收益，保留正式 source，交付 disposition、限制與可重建 runner。Substantial／高風險正式 delta 才做 fresh blind forward；不以 deep-plan 審本評估計畫自行追求收斂。

## 內容盤點與待驗假說

| 內容 | 判準與目前處置 |
| --- | --- |
| §4 通用逐條查證列表 | 單一 ablation；比較品質，尚無收益證據前保留 |
| 可查證／判斷層、severity 與 no-quota | Domain oracle；不能用模型通用能力替代 |
| 5.1–5.7、criteria impact 與實際成員 | 歷史 failure contracts；用告警集合及理由不對稱案例核對，未預先刪除 |
| 普通風險分流與小增量驗收 | 防止無關探索／架構擴張；查是否真有产品歧義或高風險，不以 repo 數判定 |
| 完整審查 N2、fresh contexts、兩輪、typed complete set | Runtime lifecycle／安全契約；不以多派或少派人當品質收益 |
| 同 canonical plan 與每條 blocking disposition | 核對真 wire 修復、建議升格與原 Goal；不採假 green light |
| Focused repair packet | 目前僅 transport capability，入口未啟用；不將本批 ordinary 成功外推為策略驗收 |
| Field log／legacy 降本研究 | 歷史非 authority；不拿舊模型成本或偏好決定本次內容 |

有效 native packets 固定在 `/tmp/deep-plan-baseline-20261003` 與 `/tmp/deep-plan-ablation-20261003`，source 由 baseline Git archive 凍結並排除 eval／field-log。Parent Codex unrestricted 僅服務隔離 fixture 的既有 nested launcher；children 保留 launcher read-only、ephemeral、schema 與 timeout，native capture wrapper 只固定 Sol 模型與保存原始 child commands／prompts／outputs，不改 prompt 內容或 reviewer 機制。不得由 wrapper 配置單獨推定實際 resolved metadata 或完整 isolation 已通過。

## 2026-10-03 局部控制觀察

Reviewer-stage 原文與 §4 ablation 共十二個 invocations 已完成。四份 wire reports 均重現 items→orders 的 KeyError 與 producer exact-dict test 相依，均查證 standalone 驗收可執行，不強制永久 carrier；clean plan 的低級文件定位錯誤均被保留為低。Opus 原文 wire 將「本次未授權實作」列為可查證中級，而原文 clean 留在判斷層；ablation clean 反而把它升為中級阻擋。此差異沒有穩定支持删除 generic list，不能用一案的較短輸出或 fewer findings 當品質收益。此 gate 同時可能只是嚴守本次 review-only contract，不能僅憑建議不開工判權限流程 defect；完整流程另核對實際處置。

告警四份 reports 都對照既有 waiting 理由、實算 A1 從告警變為靜默並找到不寫 mapping 的恢復缺口與假綠測試。Sol 原文與控制都指出 first_seen_days=45 不證明 unmapped 持續 45 天，也不證明未來 vendor 永不改 feed；Opus 兩臂都有「已卡住45天／永久」的過度外推。這是本次 reporting boundary，不把全部正確核心結論當全部宣稱已驗綠，不由這個控制推導 generic列表為根因。

普通 ready 雙端均 READY-FOR-INCREMENT，無獨立 reviewer、未載入完整 brief、沒有新 spec／carrier、未改 code／plan；明說非完整 GO／release approval，實際已跑檢查僅屬現況與記憶體相容性。此時產品歧義與 full native paths 仍在執行，當時尚不能據此結案 full-review gaps；後續結果見下表。

## 2026-10-03 Child capture 修正

首批 Codex full-wire 的原 launcher manifest 證明 N2 各兩輪、四個不同 thread、同輪 prompt digest、完整 typed 結果與 repo 不變；但 login shell 重設 PATH，使 capture wrapper 沒有被調用，不能認定這四個 child 的模型。此批只保留流程證據，不納入固定新版模型的 full 結論。不是 skill failure，也不重啟原 session。

量測 runner 改用 launcher 既有 `--codex-bin` 明示 capture executable；僅對 Codex full case 的 parent 增加量測參數，不改 child prompt／source／readonly／schema／timeout。另建 `/tmp/deep-plan-child-capture-20261003`，只補測 Sol full-wire/full-alert，保留原兩端其餘 trace。父／子模型、命令與原始結果分別驗，不以 parent 設定代替子模型。

## 已核實結果與限制

| 路徑 | 實際結果 | 判定邊界 |
| --- | --- | --- |
| 原文／§4 控制 reviewer-stage | 十二份均找到核心 wire／告警問題，低級定位不阻擋；控制沒有穩定改善 | 單次各一、不衡量 tokens；不等同完整流程 |
| ordinary-ready（雙端） | READY-FOR-INCREMENT；現況診斷有區分未實作；無 reviewer／完整 brief／repo 或 plan edit | 非完整 GO、非發布授權 |
| ordinary-decision（雙端） | NEEDS-DECISION；只問本頁筆數或總筆數；未自行選擇、未派 reviewer | 真正產品歧義仍由產品方決定 |
| full-wire（Opus） | N2 × 兩輪，四個 fresh background agents；同輪完整派出才取結果，第二輪 blind；修同一 scratch plan 後 GO | 只修已授權的 plan、repo 不變；非實作完成；額外永久回歸建議留判斷／低 |
| full-alert（Opus） | N2 第一輪完成，某 finding 補充缺 severity、另有混層；主代理停止且不輸出 gate | 正確 fail-closed，不是完整 valid findings／GO，不能洗成全綠 |
| 首批 Sol full | wire N2 × 兩輪／alert N2 一輪的原 launcher evidence 留存 | child capture 被 shell 繞過，模型無法認定；固定模型結論使用另建 root 的補驗 |
| 明示 child capture 的 Sol full | wire N2 × 兩輪第二輪無 findings、修同一 scratch plan 後 GO；alert N2 一輪 typed findings 有兩項 blocking 待處置，NO-GO 且未改 plan | 四／兩個不同 thread，原 prompt digest 與 captured stdin 一致；命令明示 Sol/high，read-only／ephemeral；不聲稱 API resolved |

所有已完成案例的 target 檔案與 Git metadata hashes／HEAD／branch／status 前後一致，formal source 沒有修改，三組 frozen source hashes 均維持；唯明示允許的 full-wire 修改 repo 外 scratch plan。另查 fixture 無 pyc／__pycache__、skill symlinks 仍指向 frozen source，以補足共用 hash helper 不納入 bytecode／symlink 的限制。Codex parent 為 fixture-only unrestricted，不能宣稱 OS sandbox 限制 parent；children 的 read-only 契約由原 launcher args／manifest 與 repo 指紋驗。

Opus 告警報告重複把 item 的 first_seen_days 當 unmapped 停留時間，固定輸入下的不恢復當成永久，以及 repo 找不到替代通知當成真實環境唯一出口；主代理報告仍帶部分外推。保留原始錯誤，不宣稱全部內容正確，也不把 §4 控制無效果當根因已定位。這次沒有證據支持以加長規則或刪規則修復這些宣稱。

本批小型 fixtures 不結案 B-20260924-workflow-review-residuals 的大型專案、production／外部來源或完整 shipping coverage；未驗證 focused transport、不改 N／兩輪／schema／授權 gate，也未將現行 portable 架構再次移植。正式 core／薄入口／metadata／eval oracle 保留原文。

## 重建與證據

共完成 22 次頂層 native invocations（十二份 reviewer-stage、十次含補验的 author flow），另實際派出 18 個獨立 child reviews。首批 Sol 的六個 child 不作固定模型證據；有效補驗六個明示 pin Sol 子程序及原生 Claude 六個 Opus 子代理結果均留 raw capture，Claude alert 的格式缺漏照實計入限制。CLI 為 codex-cli 0.160.0／Claude Code 2.1.287。

Runner 為 opt-in，不加入一般 CI 也不自動判 natural-language findings。須使用不存在的絕對 root；run 拒絕 source drift 或既有 session trace，audit 僅產生事實，需人工核 raw trace／命令結果／typed set／disposition 與 snapshots。模型與 CLI 版本保存在各 root 的 manifest／native summary；Claude child 原生 message model 為 claude-opus-5-5，Standard usage；Codex parent session contexts 為 gpt-6.1-sol／high，ephemeral child 模型依實際 command 的明示 pin 認定，不聲稱擁有 API resolved 或帳單證據。

```sh
python3 -B tests/deep-plan-model-eval.py setup --root /tmp/deep-plan-original-new
python3 -B tests/deep-plan-model-eval.py run --root /tmp/deep-plan-original-new
python3 -B tests/deep-plan-model-eval.py audit --root /tmp/deep-plan-original-new
python3 -B tests/deep-plan-model-eval.py setup --root /tmp/deep-plan-control-new --variant ablation --cases r-wire r-clean r-alert
python3 -B tests/deep-plan-model-eval.py run --root /tmp/deep-plan-control-new
python3 -B tests/deep-plan-model-eval.py audit --root /tmp/deep-plan-control-new
python3 -B tests/deep-plan-model-eval.py setup --root /tmp/deep-plan-child-new --cases f-wire f-alert --models gpt-6.1-sol
python3 -B tests/deep-plan-model-eval.py run --root /tmp/deep-plan-child-new
python3 -B tests/deep-plan-model-eval.py audit --root /tmp/deep-plan-child-new
```

現在的 runner 以明示 --codex-bin 重建完整案例；首批 root 保留修正前 parent prompt 的原始 trace，不宣稱重建會重現那個 shell capture 缺口。保留 `/tmp/deep-plan-{baseline,ablation,child-capture}-20261003` 的 source.tar／source-hashes、first.prompt／command／jsonl／stderr／summary、before／after／audit、plan.before 與 plan，及有效捕捉的 launcher child 原始命令／prompt／JSONL；本機 /tmp 是當次證據而非跨主機 authority，durable 處置與限制以本檔及 D/X/M records 為準。

## 驗收

兩入口 quick_validate：Skill is valid；repair-context focused tests：2/2；runner AST、三組 source hashes、native freshness／stdin digest／typed complete sets、repo／Git snapshots、bytecode／symlink 補核通過（Opus alert invalid findings 照實記限制，不列全部內容綠）。完整 ./tests/run.sh exit=0，PASS=1564 FAIL=0；doc-governance audit --ship、tracked／untracked whitespace、history append-only 與正式 source 不變核對通過。無正式內容 delta，故不啟用 substantial-delta 的額外 forward reviewers，既有 oracle 不改以適配模型輸出。

處置記錄：D-20261003-deep-plan-retain-core／X-20261003-deep-plan-checklist-ablation／M-20261003-deep-plan-model-audit。本機評估完成，feature branch 未 commit／push／merge／deploy。
