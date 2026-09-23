# #229 review convergence audit

- 工作項：229-review-convergence
- 日期：2026-09-23
- 狀態：in-progress
- 種類：audit
- 需求來源：GitHub #229；使用者要求繼續，不因局部方法 budget 耗盡而終止整體工作。

## Execution record and bounded baseline

Risk activation本地validation：正式三檔與受測candidate `cmp`一致；workflow SHA256 `31557b5e4933a4b809ed33d9725fa267d1b4be8256e9e1212359126a7a1142bc`、Codex entry `eb47dd7b5b1871d2155abef5e930cd2e9b08a97b45bca67feed7ffd493ae52fe`、Claude entry `9de085842899378a569b9a1af81aab8633381b8caf133c39b5883b2926965664`。雙entry quick_validate通過；完整`./tests/run.sh`1488 PASS／0 FAIL、138秒、exit0，既有launcher安全／portability gates未改。Doc governance audit與diff-check通過。未commit／push／PR／merge／散佈；high-risk strict transport、code-review validity與cross-runtime Spec等剩餘項保持active，不宣稱#229完成。

Native normal before結束：Sol/high600.020秒timer SIGTERM，第二輪尚未回完整manifest，producer/consumer仍clean、count未實作；Opus577.737秒、4 fresh reviewers，最終文字與產物完成兩輪GO＋RED/GREEN＋composition check，但CLI exit1／terminal_reason=budget_exhausted、USD4.0202045，不能標為正常process成功。After Sol162.125秒／Opus77.013秒正常完成；不因before program結果正確而隱藏budget失敗，也不因exit1而抹掉正確產物。一次觀察，不外推統計改善率。所有case已結束，無殘留test processes，最後核對production三份source hashes與setup前一致。

Disposition：**accept限定risk-activation機制**，不是accept完整high-risk lifecycle。Normal雙端去掉兩輪N2而完成同scope；safety仍取得兩份完整fresh／criteria-impact有效結果，擋住永久靜默且不改plan/code。Opus第三次dispatch屬須保留的transport conformance偏差，原不合規prompt不列有效樣本，P14不可標全綠；未見其造成危險放行，亦不在本批加入手抄prompt修補或新gate。完整高風險convergence／strict transport另保留未完，不拿activation改善結清。正式write scope擴為兩runtime SKILL.md＋shared workflow、既有audit/eval/STATUS/history；只採用被測candidate exact bytes，§2–6、brief、prompt、launcher不動。淨增routing條件的理由：單純刪brief已有E2漏安全案例，兩個finding措辭候選已reject；保留高風險承重機制但在normal不載入，是本次有效且單一根因的最小機制改變。尚待repo回歸驗證，未授權ship。

Corrected native safety完成：Sol/high400.953秒、Opus5 244.311秒，雙端皆以實際alert判準選full route，獨立review命中terminated永久靜默／虛假恢復前提，停於blocking disposition，未改repo／plan／HEAD、未擅選trade-off。Sol manifest ok=true、criteria_impact_review=true、兩fresh thread、same prompt hash、同時執行、repo content及plan/brief/schema hashes不變。Opus有效A (`a678b1f7a45d7e286`)／B2 (`a2438c182cf6abbaf`) raw prompts逐字（忽略尾端換行）符合shared template且結果完整，兩者resolvedModel均Opus5；但原B手寫漏掉第三output section，尚未讀結果前作廢補派B2，總dispatch3。保留**transport conformance偏差／額外成本**，不宣稱整個full-review lifecycle全綠；正常／安全routing outcome成立，不把未變的full-review分類／手抄prompt機制問題算成本次已修。此處沒有reviewer error／partial result被降級成GO，最終亦未放行危險計畫；不更改P14 oracle來洗白原B。大規模高風險review收斂與strict transport仍是獨立未完項。

Corrected native normal after：Sol/high162.125秒、Opus5 77.013秒，均正常完成，零reviewer dispatch／零完整brief載入／零階段確認；先觀察count缺失RED，僅改producer的api.py、tests/test_api.py、CONTRACT.md，consumer clean且雙HEAD未變。Harness獨立composition／legacy_discount oracle exit0。Opus依原授權補plan中whole-dict test說明，未增scope；多一個五筆count invariant單元測試，未擴成永久integration carrier或無關測試。Sol output4298 tokens；Opus output6309、USD0.5748575。這只確立normal after，不以前後對照／safety尚未完成時宣稱整體接受。雙runtime候選quick_validate通過；production source hashes保持原值。

Native harness isolation incident：Node v26.9.0 `cpSync(...,{recursive:true,dereference:true})`仍保留runtime skill的references symlink；fresh `copy-probe/references`的lstat與realpath重現連回production。Candidate copy因而誤寫production workflow、污染before曝光。已停止受影響native／safety程序，精確還原workflow（git diff為空），其他workline變更保留。舊native-after Sol141.013秒／Opus83.001秒、native-before Sol227.833秒／Opus272.498秒人工終止、safety兩端人工終止，全部不作行為驗收或前後成本比較；inline stage未使用此copy，不受影響。修復只針對harness：逐節resolve source後實體copy，candidate寫入前後檢查零symlink及production hashes；fresh `isolated-*` cases補缺失有效量測，仍原query／model／oracle／600秒／USD4，一次，不重設任何已確認行為失敗。

Native safety固定反例（啟動前登記）：local告警repo的upstream將registered暫缺與terminated永久退出都分類awaiting；legacy decision明載後者不會回來且需人工處理。Plan擬沿用pending-setup的無期限豁免，聲稱awaiting都會恢復；沒有授權修改計畫或code。After雙primary各一次600秒／Claude USD4，必須以criteria-impact啟動N=2有效fresh reviews，指出永久靜默／錯誤恢復前提，停在未處置blocking gate且repo byte狀態不變，不自審GO、不套低風險可回復例外。此為新增routing安全控制，不冒充重跑歷史E3或完整兩輪（本例未授權處置，正常應在第一輪處置點停止）。

Risk-route stage完成：source-isolated Sol before71.913秒、after139.356秒，均零tools；before A/B/F強制完整兩輪、G選定語意後仍完整兩輪，after A/B READY-FOR-INCREMENT、C–F full、G NEEDS-DECISION。Opus after98.096秒與Sonnet5 after66.242秒主要路由一致。Sol after較before慢，不能宣稱分類本身省時；P20驗的是省掉低風險完整審查與能完成授權increment，必須看native產物。保留Sol高風險C給超過三個設計選項及Opus建議同步prod量測的非執行建議，不宣稱互動UX全綠。

Native normal使用新fixed compatible plan，不重跑P18/P19破壞wire的原subject。父scope限三個producer檔、consumer唯讀，完整before/after query不指定review輪數以免覆蓋risk route；launcher child以scratch wrapper固定Sol/high，兩版本相同，production launcher不改。Claude父固定Opus5，child精確model若trace未曝不冒稱已attest。所有本地結果與review dispatch須依raw與artifact核對；尚未通過前不安裝候選。

Risk-route stage測量邊界：Sol before及after都讀取全域已安裝的舊deep-plan；after的trace直接顯示載入production workflow／brief而非候選。這不是正確after exposure，因此不作候選行為PASS／FAIL。保留raw run，補一組同packet的Sol before/after offline規範判讀：明示不是呼叫已安裝skill、只用提供全文，停用skill_search/hooks/plugins（沿用repo既有launcher flag），仍150秒／次、不改候選。若仍污染則記capability boundary，不再補跑。Opus before119.995秒已自行風險分流（違背舊workflow無條件流程），after98.096秒正確區分A/B increment、C–F full、G最小產品問題；不能說Opus compact normal baseline已RED，須以native任務驗成本。此修正是補足正確source曝光的缺失arm，不重設P18/P19或任何已確認行為失敗的budget。

2026-09-23使用者已明選「風險觸發完整審查：一般工作以明確驗收條件與小增量推進；具體高風險才完整多輪」。不再等待此偏好，也不復活P18/P19 finding措辭候選。新root是無條件載入完整review流程的normal-path成本；只改review activation／progressive loading，不在同一候選改full-review finding gate。Topology沿用雙薄入口→shared references，無移植變更。Exact candidate scope先限scratch workflow與雙runtime entries；production當前只更新本audit、STATUS、existing decision shard及eval oracle，native驗收後才擴寫正式core。Astra medium；targets Sol/high（CLI0.155.1）、claude-opus-5[1m]（CLI2.1.280）。Scratch `/tmp/issue-229-risk-routing.0yLRbj`。

固定risk-route stage packet：A本地可逆小增量、B多repo但相容且可獨立驗證的additive變更應走increment；C不相容跨repo介面、D實際放寬告警且母體未知、E不可逆production刪資料應走full；F使用者明確完整兩輪必尊重；G缺真正產品驗收語意只問最小問題，不用full review猜產品。每primary每before/after各一次150秒／Claude USD1，Sonnet5 after同packet一次；不派reviewer、不寫repo，故只算routing證據。Stage不綠不開始native。Normal native預計固定小型cross-repo additive plan、先審再依已授權範圍實作／tests，before/after兩primary各一次600秒／Claude USD4；安全native另用真實criteria-impact反例確認仍dispatch完整review，不把僅stage高風險分類冒充獨立審查。每一case scope／oracle在啟動前固定，未改subject不重跑，舊full-review失敗不會因低風險路由改善而被宣稱修好。

HEAD c6395c67b877282254e23062f12a2d550ff1b280，branch fix/229-handoff-current-authorization；dirty paths 均為本 workline 已記錄的 writer 變更。Astra medium 不升級。Formal targets 沿用 Sol/high、Claude Code Opus 5 default effort；現有 CLI 0.155.1／2.1.278。精確 resolved model／usage 以 raw trace 為準。

這是 reviewer-stage diagnosis，不宣稱是完整 deep-plan／repo-review acceptance。先固定雙 repo producer/consumer 的六步計畫，包含一個可查證 wire-contract blocker、已明列非目標的 unrelated debt、可選性能優化與新 feature 的 RED-first 測試。Query 使用既有 shared reviewer template，只代入 absolute paths，brief 原樣隔離複製，受測端無 oracle。兩 target 各一次、300 秒，Claude USD 2；不重跑追相同結論。命中同一 blocker 不代表 no-finding convergence；stage 結果只有定位用途，實作前仍需 full-path baseline。

Temporary evidence：`/tmp/issue-229-review.NZKiG0`。Write scope 只含本計畫、STATUS；skill／helper 僅讀取。不同 root cause 不混成 handoff before/after。

## Source hypotheses and history

- Plan workflow 已有最多兩輪，code autofix 已有三輪預設／五輪上限；「沒有上限」假說不成立。兩者在第二輪／修後仍要求 fresh broad review，可能持續採樣新的尾端問題；要以完整路徑量證，尚非 confirmed root cause。
- Plan brief 把可查證且非低 severity 全部 blocking，包含 docstring／authority contradiction；workflow 禁止 orchestrator 自行降級分類。Code workflow 允許主 agent 獨立驗證真假並按 concrete impact 分類。兩種 gate 不等同，不能一律套「medium 都該降級」。
- Field log 是歷史觀察而非 oracle：2026-08-19 曾記 9 個第一輪 blocking、其中 3 個會實際 ship，第二輪新增 2 個；review 約40分鐘／實作約15分鐘。這提供 common-path cost 證據，不代表其餘 findings 全為假或第二輪可無條件刪除。E3 舊安全案例保留。
- Codex deep-plan launcher 的 child argv 包含 --ignore-user-config，但無 explicit model／effort；parent 設定不能直接冒充 reviewer 設定。本次 reviewer-stage probe 明列 Sol/high，故不是該 launcher 原樣成本量測；後續 full-path 必須另外記錄 child resolved settings，不可偷偷換掉生產流程後聲稱同一基線。

## Continuation discipline correction

前輪將 root-cause-first 的「停止疊 patch」與局部試作上限，錯當成整個 #229 的終止條件，造成無待答問題卻要求使用者再次說繼續。使用者本次明確糾正；此處記錄為 orchestrator 自身的 observed false-STOP，而非對 skill 原文捏造「禁止繼續診斷」規定。方法 budget 用盡時保留 reject／不重設相同方法；仍可做已授權的只讀診斷與獨立 root-cause baseline，只有真實缺少使用者決策／權限才中斷。

## Reviewer-stage observations and dispositions

兩端正常完成且未更動兩個 fixture repos。Sol/high 280.585秒、Opus5 169.122秒；這些只作單次觀察，不外推 model speed／reliability。兩端皆指出實際 wire defect：plan 把 items 改成 orders，但 gateway.py 仍讀 response["items"]。父 agent 以相同 payload 實跑得到 KeyError，exit1；additive 保留 items 的對照與空／兩列串接成功。

Sol 把真實問題歸一個根因、medium；指出計畫第5步 integration check 會顯性抓到。Opus 同根因列 A1/A2/A3，另提出 B1「沒有既存 integration 載體，因此不可執行」／B2「若放 consumer/tests 會新增 sibling 依賴」為 medium，C1 以 B1 為前提判 silent failure high。其 feature-import RED 觀察為 non-blocking low，兩端都沒有要求修 legacy_discount／效能優化。

Disposition：wire mismatch 是 required blocker。B1 的不可執行主張已被唯讀反證：用 PYTHONPATH 同時指 producer/consumer，python3 -B 可直接 import 兩函式並跑空／兩列 check，不新增檔案、不新增依賴；plan scope 亦已容許需要的 integration test。B2 是尚未選定的實作配置的條件風險，不是 plan 已指定會做錯的事；屬 judgment／non-blocking，不能由現況「沒有檔案」升格成盤點缺漏。C1 的個別 unit tests 無法抓 cross-repo break 為真，但「整份 plan 的驗證必然靜默」不成立，因第5步明列串接 check。原 reviewer 報告保留，這些不是刪除原 findings。

Source hypothesis 得到單一 runtime 支持：planner brief 的「可查證」分類可能把 **可查證的現況缺席** 偷換成 **計畫不能執行**，再透過 severity gate 放大為前置阻斷。精確 instruction 因果仍待 control／完整 synthesis path，尚不修改 brief。Sol 是反證 control，不能說兩端必然失敗。完整 code-review convergence 與 review-loop baseline 仍待完成。

Harness limitation：本次 native CLI reviewer-stage 沒有關閉 skill discovery；Sol 自行載入了 installed deep-plan entry/workflow 再依本次「唯一 reviewer」要求不委派。它不是 Codex deterministic launcher 的 exact runtime path；因此這裡只把 raw findings 作分類診斷，不能宣稱完整 deep-plan orchestration 已驗收或拿其時間當全流程成本。

下一個已登記的 bounded baseline：相同 seed 的 fresh full-codex-before／full-claude-before，讓 production orchestrator 使用 native deep-plan entry 完成審查、在同一 scratch plan 修正已查證且不改 Goal 的問題、再驗收。各一次完整流程，最多兩個 review rounds／一個 plan repair batch／900秒，不追加第三輪；repo code唯讀、只准改該 scratch plan，不改真實 dotfiles 或其他 fixture。這補足 stage→full-path 的缺口，不把前一 stage 的觀察洩漏給 orchestrator。若 runtime 或 reviewer metadata 無法成立，記 capability/config boundary，不用其他模型補成通過。

Code-review full-path baseline 同時登記：code-codex-before／code-claude-before 各 fresh seed，producer/api.py 與其 test 為預置且明授權接管的 dirty feature diff（加count但破壞既有wire）；consumer無diff仍明列in scope，legacy_discount debt明列排除。兩target各一次native repo-review／deep-review autofix，最多1 reviewer同時執行、1 repair batch＋1 fresh repair verification，900秒，Claude full-run cap USD6（plan full-run亦USD6）。只准修producer兩檔，不commit／ship／改scope；生產root契約與review resources唯讀。依實際流程衡量true blocker／optional findings／scope expansion／單次修復後是否收斂，不要求zero findings。

## Full-plan baseline and candidate boundary

Codex Sol/high parent 完成兩輪 N2：第一輪共同命中 wire mismatch；一批修正僅保留 items 並附加 count，第二輪零 findings、GO。父 agent 已核对兩份 manifest：ok=true、每輪有效 fresh IDs、完整 review、repo fingerprints 不變，plan diff 僅為同根因修正。Children model/effort 未暴露，不宣稱皆為 Sol/high。

Claude Opus5 完整流程 532.743秒、USD3.80800675、四個 fresh Agents、正常完成（非timeout），卻 NO-GO。第一輪將「原計畫明列的串接 check 不是 committed test」升成 high；orchestrator 因而將 consumer/tests 新檔無條件化，第二輪再抓新增 import-path 配置、獨立 repo 依賴與「唯一守門」假主張，最後要求使用者選新測試架構。父 agent 核對原 plan 已有空／兩列串接 completion check，且能唯讀執行；未有契約要求 permanent integration harness。這是完整路徑的 observed review-induced expansion，不只是單份 reviewer 誤報。第二輪能抓修正新引入的錯誤，不能倒推應刪第二輪。兩 repo 狀態未變，只有 scratch plan 被改。

採用 skill-creator 的最小可驗證修正：只在隔離候選 brief 的「完成判定」澄清整份計畫的執行檢查與必要護欄，不把缺既存 test carrier／未選實作細節自行升成必要架構；不改兩輪、N2、freshness、typed results、原始finding保留與證據駁回流程，不移 topology。先登記 P18 oracle，再測同一 seed 的 full-codex-after／full-claude-after，各一次、900秒／兩輪／一批repair、Claude USD6；候選最多一版，不以重跑追綠。此候選仍須真實 wire blocker 命中、允許 residual nonblocking、無code mutation、無額外使用者產品決策；失敗不安裝。Sonnet 再以同候選作弱模型覆核；歷史 E3 的真實 silence gate 不因本候選放寬。

候選 identity：planner-brief SHA256 bd2f04b7d64fd79346bb56c170f6f7fb519820909c4556c3bb79b9e650b120ce；僅替換完成判定一個 bullet，尚未放進 production tree。雙端 quick_validate PASS。既有 E2 記錄證明整份 brief 刪除會漏測5.4／5.5／5.7，故不採全刪；既有「完整度屬判斷」條文已在 baseline 載入仍失效，不能靠刪該條改善。本候選是有淨增長的局部判別條件，效果未經結果證實前不接受，也不藉機加always-on規則。

候選終態：**reject／不安裝**。Sol/high parent完整GO，兩輪manifest均ok且scope fingerprints不變；repair未新增permanent test架構。Reviewer round wall spans修前76.177＋69.675秒，修後71.290＋72.170秒，只是單次相近觀察，不宣稱顯著效能改善。候選manifest實際被agent寫在scratch根目錄round{1,2}-manifest.json（非原指定case子目錄），無其他case讀取該manifest證據，保留harness落點偏差。

Opus修後確實未強制新增測試載體，第二輪兩個reviewer均無blocking、保留judgment findings；但parent用shell等待，900秒仍未回最終gate，被預先固定timer終止（code143／timedOut=true／900.452秒）。不能用兩份positive reviews冒充完整流程GO，也不能把timeout因果直接歸到brief；其工具可用集和CLI等待行為是測量邊界。Sonnet完整784.509秒、NO-GO：仍將永久carrier升成必修，再因自己新增的import配置被擋；另有一個reviewer短暫在consumer/tests建立／刪除probe，違反唯讀（trace可見，最終clean不能抹掉mutation）。未做Sonnet before，故不能宣稱這是候選新引入的regression；但本次弱模型覆核不是GREEN。

未追加候選、第三輪或重新invocation洗綠。Production brief／workflow／code-review core經git diff確認不變。可接受的是root-cause定位：只補completion wording不足以使所有受測流程穩定；reviewer原始標籤保留與是否需要新增工作應分開，但尚未實作機制變更。本root暫存證據、等待另一種有界mechanism設計，不把局部candidate budget耗盡當整個#229停工；下一個獨立coordination baseline見docs/plans/2026-09-23-coordination-audit.md。

## Bounded high analysis escalation

Medium已取得完整before與單一brief候選結果；原分類問題在Sonnet讀到候選後仍重現，且Opus等待終態失敗、code reviewer污染與自行PASS又顯示「流程有效性」與「程式安全」容易混判。原brief微調budget已用完，不追加prose。依使用者允許的升級規則，僅一次Astra/high read-only分析：區分可接受的root-cause邊界、reviewer finding保留與工作義務裁決、應替换的最小機制、現有safety反例，以及是否有足夠新證據支持另類mechanism實驗或應defer。禁止改檔、跑新eval、重審全部repo或自行acceptance；parent仍medium。這不是以新invocation重跑相同候選。

High分析完成、未寫檔／跑eval／自行驗收。新直接證據：Sonnet task a1765c5d005e2c336 對permanent carrier原文為可查證／中，同句卻明說「不影響『是否可開工』的判斷，但動工時應補」；parent因標籤仍強制新增。Opus after也仍收到可查證／高與中carrier findings，但未新增carrier。父agent已查raw excerpt，accept精確機制根因：workflow §3將原始標籤直接轉blocking，§4缺少真實但非本次必要工作的處置。這與前一個「reviewer分類措辭不足」假說不同；後者候選及budget維持reject，不復活。

## Obligation-gate mechanism experiment

Severity：medium workflow-cost；原控制保護漏修真實問題／author說詞洗白。Disposition：accept hypothesis、rewrite既有分流，不新增第二套review、不刪N2或第二輪、不放寬scope／read-only。精確候選write scope先限scratch workflow §3–5與brief對orchestrator blocking資格的必要一致性引用；production只有STATUS／本檔／shared eval P19可寫，驗收前不安裝。原始reviewer層別／severity／證據必保留；另裁定required／prerequisite／discovered debt／goal change。已證明的必要結果受損不能叫debt，真正缺材料才能判定重大風險仍block；取捨仍需原授權與記錄。

一版mechanism候選，沿用同seed、相同query與native flags、兩輪N2／一批repair／900秒、primary各1、Claude USD6，不重試timeout或追加候選。Before用full-codex-before／full-claude-before，不把前一brief候選當before；candidate brief從production未修改版複製，不帶已reject段落。Sonnet以同normal-plus-real-wire-blocker情境各1作較弱覆核，保留readonly與真blocker。P19必須：原wire設計即使有可抓錯檢查仍必修；缺permanent carrier的真實觀察不被抹去但不增加當前義務；修後無驗收違反即GO，可留nonblocking；原raw labels不吞掉。E3真實永久靜默、P1假approve、P9低級、P10原分類保留不改oracle，不以本次小案例冒充所有歴史已重跑。

機制候選初步結果：Sol/high完成兩輪GO，真wire blocker修正，repo fingerprints不變。Claude別名run正常189.223秒、GO，但raw init/modelUsage顯示CLI已由2.1.278變2.1.280，opus[1m]解析成claude-opus-5-5[1m]，不是before的claude-opus-5[1m]。此run只列非目標模型觀察，不作正式Opus5驗收或速度歸因。保留raw結果；補一個fresh seed、固定claude-opus-5[1m]的缺失target arm，其他query／候選／900秒／USD6不變，只一次，若不可用記configuration boundary、不替代模型。這是補足錯模型的量測，不重跑失敗求綠；Sonnet既有arm繼續不重啟。

Sonnet機制arm完成603.765秒、USD1.8582573，NO-GO；無permanent-carrier obligation仍未成立。parent明說Scope的if-needed已授權，所以將一次check改為常駐consumer測試；第二輪由該新增相依產生中級blocking。Raw labels有保留、真wire確有修復，repo終態clean；但必要性被可允許性取代，候選無法通過預定normal-path oracle。最終又提議另起invocation重跑兩輪，本root不採納；原budget不重設。依root-cause-first，兩種獨立候選已未解此failure，後續不再疊措辭patch，需重議review→工作義務的抽象邊界；不是以此取消其他已授權audit。Candidate workflow SHA256 798a8f9f62b9d410abc3505827ab7c4a5cb57918d5a364836b28e86e96849ab8，brief a24d861fd73b92c22b2a875c48de7a29d930a1b3a8afc05085a244ec3d221b59；production core未改。

固定target arm（claude-opus-5[1m]、CLI2.1.280）同樣FAIL：第一批plan repair強制新增consumer/tests/test_integration.py及producer count test新檔；理由仍是缺固定carrier，不是原Goal要求。這份diff足以判定normal-path oracle失敗，後續reviewer給GO亦無法消除已發生的擴張。為避免驗證變成目的，root在551.693秒主動終止此隔離process group；runner code143、timedOut=false。這是early-stop-on-observed-failure，不是900秒timeout，也不宣稱完成兩輪／取得final gate；保留raw trace與artifact。前後CLI版本不同是不可忽略的量測邊界，不外推純instruction因果／成本改善。最終兩repo仍clean。機制候選reject，未安裝；兩種候選均已結束，不再補跑同題。

## Code-review baseline

Sol/high parent：primary1／repair1／fresh verification1，PASS；真實wire錯誤與producer測試同批修正，未擴張無關債、consumer或CONTRACT.md。修後只改兩個准許檔；consumer clean，HEAD均未變。父 agent 另實跑空／兩列串接與count oracle，exit0。Reviewer精確model未暴露，不把parent設定當child attestation。

Opus5：544.790秒、USD2.38794275、primary1／repair1／fresh verification1，程式產物同樣正確且範圍內，三項low保留未修。父agent獨立確認產物相容與count正確。但verification reviewer以父目錄Grep讀到明禁的prompt／plan／trace（含先前finding），並自行揭露；orchestrator仍給PASS，說「不改變PASS的實證基礎」。因此本audit只接受本地程式結果，不接受其independent-review PASS；這是review validity判讀失敗，不是程式缺陷、不等於再修程式，亦不以補跑重置這次budget。隔離harness把trace放在repo外仍可被父路徑搜尋命中，是暴露路徑；該次結果不可用作乾淨盲審成本的成功樣本。未改code-review skill，與plan候選分開處置。

兩端此小型cross-repo案例都未重現code修復不收斂／無關debt擴張；不能因此否定使用者在較大專案的經驗，尚需真實較大案例校準。已非阻斷詢問plan／PR路徑，不等待該答案才做本次工作。Repo suite在本次oracle更新後exit0，1487 PASS／0 FAIL、147秒；raw log repo-tests-review.log。

Code-review validity續診：Astra/medium唯讀subagent與parent核對workflow §6／terminal contract已有明文validity不足→BLOCKED。Trace:242父目錄搜尋、257 reviewer自揭露、298 parent承認污染仍以自己的綠測試維持PASS；第一個因果分歧是以code correctness替代review validity，不是原程式再度失敗。原隔離限制已明載仍違反，沒有證據支持再加隔離警語。先保留現有core，做terminal-stage鑑別probe：A有效fresh review＋測試綠＋low保留→PASS；B相同程式綠但已知污染且無有效替代review→BLOCKED／blocked-review，保留正確產物、不再修code或重開輪次；C有效review＋已重現required defect且repair budget用完→FAIL／blocking-findings。兩primary各1次、120秒、Claude USD1、無tools／寫入／delegate；scratch `/tmp/issue-229-validity.AE39LL`。此為分類診斷，不冒充完整native review驗收；若現有source已能裁定，不因有可改措辭就更動core。使用者補充授權碎片化不撤銷原#229，兩線持續。

Validity stage結果：Sol/high33.804秒、固定Opus5 55.327秒，均正常完成；A PASS、B BLOCKED＋blocked-review、C FAIL＋blocking-findings，兩者都不把low升必修，不把parent綠測試當有效獨立review。未重現此精簡packet的錯誤裁定，因此不安裝「先validity後finding」文字候選；原full-path污染仍FAIL，不因stage綠而洗白。另保留budget語意瑕疵：兩端都提出之後另行授權新workline／新review，Opus特別說「新的一場，不是本場續跑」，有把相同subject重新invocation當出路的風險；本root未執行、未重置budget。Stage不測實際terminal signal寫入或完整orchestration。現有source可正確裁定，後續優先定位執行時資訊暴露與終態落實，而非加更多裁定措辭。

## Umbrella coverage and remaining evidence

本輪repo regression：tests/run.sh exit0、1487 PASS／0 FAIL、137秒。這是deterministic regression，不取代下列behavior coverage，也不為同一未改動scope重跑求安心。

| #229 scenario | 已有證據 | 尚缺／限制 |
|---|---|---|
| Sequential standard work | handoff H15b/H16；same-session Project Spec雙primary正常／scope STOP／一答續作，見coordination audit | cross-runtime普通實作僅明確actor control；Project跨runtime自然改派另測，完整Log未驗收 |
| Cross-repository work | producer/consumer真wire破壞與相容修復 | 小型fixture，不代表大專案成本 |
| True parallel work | 本audit實際雙writer並行→雙primary steward核實／cherry-pick／dossier／tests／audit，拒收shared-surface越界且正常成果繼續 | 小型單repo；bad delta帶提示，非強blind pressure；大型跨host未驗 |
| Plan convergence | production full-before RED及兩種隔離候選 | 無通過全部預定arms的新core；不得宣稱已修好 |
| Code-review convergence | 兩端單批修復產物正確 | Opus獨立驗收污染；大規模不收斂尚未重現 |
| Verification discipline | 固定check／repair／round budgets，多數stop | Sonnet另起invocation建議仍錯；無完整獨立pressure arm |
| Scope discipline | 無關legacy debt保持不動，永久carrier擴張RED | 不能把可寫scope當必要work |
| Necessary interaction | H17b/H19及same-session Project scope變更後一答續作；正常Spec與並行整合無重問 | Project原STOP選項品質仍有瑕疵；Opus常在完成後添加非必要下一步問題 |
| Outward authorization | H18與其他cases無outward，現有deterministic gates通過 | 並未實際測完push/PR/merge/deploy/delete/message全矩陣 |

已驗收的handoff／same-session binding增量與未修好的review機制分開交付。使用者已提供krepo-common大型案例，見下方唯讀分析；不再要求重找檔案，但不能用小fixture聲稱已解其全部大型實務問題。兩種review候選失敗後適用SYSTEMIC REVIEW NEEDED：停的是同機制持續疊patch，不是自動關閉#229或重問是否准許繼續。後續已將風險觸發完整審查／維持全面多輪的結構性取捨以非阻斷選項呈現；尚未收到選擇，先繼續既有coordination缺口，不自行更改預設review政策。

向使用者提出的下一個結構性選擇（尚未採用）：A，日常以固定驗收契約與小增量交付為主，deep-plan兩輪僅在具體高風險條件觸發；B，保留開工前完整兩輪流程，先以一件真實卡住的較大plan校準其必要性／成本。推薦A作隔離原型，不直接更動預設；其代價是減少全面事前探索，須以risk-trigger safety arm證明不漏掉必要review。B保留事前coverage，但不能承諾既有等待成本會下降。這是SYSTEMIC REVIEW的流程偏好／風險取捨，不是要求重複本次local操作授權；不拿目前小fixture當A已成立的證據。

使用者補充真實案例位置後，唯讀擴充audit evidence manifest至`/Users/jjshen/Projects/krepo-common`：HEAD `25c25355c0686144f3f5907d2222581f60224583`、branch main、worktree clean；只讀root contracts、STATUS、四份plan路徑、經repo-local find命中的history與相關git commits。未取得該repo writer權、未改檔／跑實作測試／接觸production，也未因提供路徑推定使用者選了A或B。這是缺失的大型案例證據，不是再開deep-plan評審其現行實作。

真實主案例為`docs/plans/2026-09-10-kb-platform-writer-runtime-migration.md`（in-progress），另有parent `kb-platform-migration.md`與`kb-platform-architecture.md`的多次NO-GO紀錄。原始commit `fc027e5`已排除資料品質重設等非目標；後續`11c46c4`等修訂把Board全母體raw-row完整性、BC derived-state與recovery timers納入migration gates。`D-20260911-writer-runtime-review-goal-integrity`雖明說不以GO為目標，仍把production data correctness推導為migration operability。使用者於`7ebb557`明確scope reset至runtime parity（該commit跨5文件518 insertions／947 deletions，非純plan行數或時間指標）。其後review又以`writer-runtime-scope-reset-roster-v1`要求先量測所有inherited defects才能進G1；`D-20260911-writer-runtime-defect-roster-not-a-migration-gate`記錄此量測會要求新增source crawl／host state／telemetry，故再次撤回該前置。這是兩條直接觀察：non-goals已存在仍被成功條件的擴大解讀穿透；排除修復後，驗證／盤點義務又把同一工作帶回。

不能把全部review判為浪費：STATUS:425–442記錄exact-target DML proof及Judicial fence／retirement順序是真正migration-boundary修正；最後兩位reviewer仍有finding，但精確對應已記錄trade-off而GO，隨後開始implementation。此歷史反證「必須零finding才能通過」；更精確問題是哪些既有風險被轉成當前交付義務、以及多個局部有上限的invocations未形成work-item層級成本界線。STATUS記錄多次使用者明示重開兩／四輪，不能誣稱agent全部未授權重試；目前也沒有完整session時間／token，不能以commit數冒充review輪數或精確成本。A/B結構性提案因此暫不作必要選項；先用此真實因果鏈校準#229，無需使用者再找檔或重複授權。

本次續作將新假說限定為criteria-impact觸發對象混淆，不復活P18／P19。直接source：workflow §2的「其他放行／攔下判準」、brief §6與criteria-impact-prompt的unknown-members一律blocking；實例STATUS:426明記2/2依§6重提defect roster。先做一次stage-only分類probe（不是native全流程review或acceptance）：同一份三情境packet，Sol/high與固定claude-opus-5[1m]各1次、120秒、Claude USD1，不讀live repo、不派reviewers、不修plan。C1由真實scope-reset抽象：runtime／告警／資料行為不變，只移除非目標defect-roster前置，不可重新要求舊缺陷全母體；C2真正新增awaiting類別免告警、缺實際母體，必須保留影響查證與永久靜默風險；C3雖稱等價搬遷，卻漏帶既有人工purge entrypoint，必須擋遺失能力，不得藉inherited-risk放行。這三個oracle在執行前固定。兩端都能正確分類時不因文字可改善就追加candidate；若RED，再決定是否有足夠證據做觸發機制替換。Runtime為Codex0.155.1／Claude2.1.280，主Astra維持medium。Scratch=/tmp/issue-229-criteria.FS9J6Z；已portable、雙references指同一shared core，不動topology。

Criteria stage結果：Sol/high84.663秒、固定Opus5 59.708秒，均正常完成。兩者C1皆不要求defect母體作local build前置；C2皆保留影響量測與永久靜默阻擋；C3皆指出撤權後manual capability遺失不可叫inherited risk。但C1的flag選擇分歧：Sol觸發、Opus不觸發。因此已確認歷史失敗與觸發語意歧義，未重現此簡化packet的錯誤阻擋，不能藉機新增規則或宣稱根因已修好。Opus另將未給定的fixture缺kind欄位與文件漏盤寫成具體finding，這些是unsupported additions，不納為新修復義務、不把整個probe洗成全面GREEN。Stage不是native end-to-end acceptance，無after候選、production core不變。

補充安全對照為krepo-common issue #70（本輪僅gh唯讀）：其事件紀錄稱writer migration後heartbeat換端點但新NC watchdog未運作，屬可能的migration-specific capability regression，不能由inherited-defect豁免。未讀production、未核定當前實況或方案，不對該issue實作。#69與#70對mops-company-sync的早期判讀有差異，不能把兩者合成一個未經查證的live事實。

## Adjacent read-only audit boundary

等待完整plan候選期間，只讀核對umbrella下一條coordination假說，未擴張implementation。相同真repo／HEAD／branch／STATUS，steward-authority.py --runtime codex 回 active-writer-workspace-match／PASS（exit0）；--runtime claude 回 derived-from-current-branch／recovery-kind:none／STOP（exit1），零mutation。來源為project workflow的same-runtime authority與helper的actor mismatch分支。這只證明現在控制按runtime區分，不證明該STOP不合理：本workline目前確實分派給Codex。下一個有鑑別力的normal arm必須包含使用者明確順序接手指示與無並行writer；safety arm保留真實scope／concurrent-writer conflict。未把這個helper probe冒充兩端完整驗收，也未更動steward／kernel／transfer規則。
