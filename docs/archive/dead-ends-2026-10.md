# 死路歸檔 — 2026-10

## 事件記錄（event-time）

- **X-20261002-project-loading-candidates · 2026-10-02 #246 不採用 mode split、較小 chunk 或安全反例刪除**：Spec/Transfer 原樣按需拆分的 v1 在 Claude noop 漏 ship-paths；v2 加 route guard 後讀齊，但 Claude input 823860/65.56s 高於舊版 776994/54.41s，跨 runtime 收益不足。8000-byte 單一改法令 reader 從14增至20、兩端 input 上升，維持12000。獨立移除 Rationalization table/Red Flags 的已 commit normal Log，兩端都與舊版同樣正確確認終點、不 push/merge，未顯示完成品質改善，保留。無 skill 6.1 Sol 控制能守兩個局部授權/STOP 案例，但不是 domain contract 可刪的證據。fixture 舊 dirty prepare 未明示來源，不能把 STOP 算 false STOP；Python hook 可被 Codex -S 避開、PATH shim 被 login shell 改寫、MCP 的 auto/未設定 approval 被拒，都保存為無效材料，不計通過。改用官方設定的 local MCP 工具與 fresh fixture 才得到有效截斷對照。候選 patches、有效/無效 roots 與再議條件均在 plan；production shared core 無改動。
  - 日期來源:direct
  - 放棄:以少 bytes/少 tokens 冒充品質改善；用較快的一臂掩蓋漏讀或較慢的一臂；重跑相同材料洗綠
  - 重議:同 normal/safety oracle 下能穩定改善雙 runtime 完成行為或載入成本，且完整必讀與授權不退步時；需保存新 trace 與根因變因
  - 關聯:Issue#246;D-20261002-project-model-bootstrap;docs/plans/2026-10-02-project-model-behavior.md;tests/fixtures/project-reference-candidates/;tests/project-reference-eval.py

- **X-20261002-session-skill-reminder-ablation · 2026-10-02 不以新版模型名義刪除無品質收益的重述**：handoff 移除 Red Flags 但保留 Critical/W/R 的局部控制，以及 ready4quit 移除 sync 比喻/催促重述的控制，沒有可歸因的正常完成、scope 或安全收益。Handoff 的 active/archive 接續、只讀、未決產品選擇、直接 policy drift、write-side carry-forward 維持既有分流；transport stand-in 的 drift case 不能用來要求停止獨立 timeout tests。Ready4quit 控制並未證明 generic prose 造成私人 probe/證據彙總錯誤，Codex q-residue 還多跑一次 hygiene helper。保留原文，不以字數/token 下降採用候選。fixture 異常、原始 RED、分支差異都保留，沒有反覆跑同 packet 洗綠。
  - 日期來源:direct
  - 證據:`/tmp/session-skills-{baseline,ablation}-20261002` 的 native traces/source hashes/actual artifacts；可重建 runner 與限制見 plan
  - 放棄:文字看似重複就認定新版模型已內建；用 CLI exit=0 或更短 output 宣稱品質改善
  - 重議:新的真實 false STOP／scope/safety failure 能支持一個具體 source ablation 時
  - 關聯:D-20261002-ready4quit-contract-first;D-20260925-instruction-quality-scope;docs/plans/2026-10-02-session-skills-model-behavior.md

- **X-20261002-session-eval-command-count · 2026-10-02 更正 helper 字樣計數，不把讀腳本算重跑**：前筆 X-20261002-session-skill-reminder-ablation 所述 Codex q-residue「多跑一次 hygiene helper」不正確；raw trace 的兩次 path 字樣分別是 execute 與 `cat`，只有一次真實 helper execution。原 audit 用 command substring 計數造成 false positive，已改由實際 helper verdict schema 核對，並提供可重建的 `audit` action。其他 ablation 無可歸因品質收益的結論不靠此計數成立；不把讀腳本算品質回歸。
  - 日期來源:direct
  - 證據:`/tmp/session-skills-ablation-20261002/gpt-6.1-sol/q-residue/host-transport.jsonl`；一份 RESIDUE output，另一份是 shell source
  - 放棄:把 command string 出現 helper 路徑當 execution evidence
  - 重議:helper output schema 改變，或出現不具 schema 的實際執行時，人工核對 raw trace，不猜 call count
  - 關聯:X-20261002-session-skill-reminder-ablation;tests/session-skills-model-eval.py;docs/plans/2026-10-02-session-skills-model-behavior.md

- **X-20261002-session-close-placeholder · 2026-10-02 STATUS 收尾沿用 scanner 接受的既有 no-active 文字**：收尾暫以「(無)」代替 active item，觸發 `STATUS active content outside H3 item`。已還原原 repo 的「目前無進行中項目。」並直接 audit exit 0；第二輪 full suite 的背景 governance scan 在修正前已取得舊內容，因此保留該 1563/1、exit 1 結果，不能改標通過。後續在固定 final tree 重跑 suite，這是文件 schema 修正後驗證，不是重跑模型洗綠。
  - 日期來源:direct
  - 證據:`/tmp/session-skills-suite-final-20261002.log` 的 test_current_repo_ship_audit_is_clean、STATUS.md:15；修正後 direct audit 無 findings
  - 放棄:用任意 no-active placeholder 取代已採用 schema；在背景 scanner 執行期間改狀態後把它的舊輸出當 final snapshot
  - 重議:repo scanner 或 adopted no-active schema 明確改變時
  - 關聯:M-20261002-session-skills-model-review;docs/plans/2026-10-02-session-skills-model-behavior.md

- **X-20261003-session-skills-premature-active-removal · 2026-10-03 本機交付不能先移除尚未 commit 的唯一 assignment**：前輪本機評估完成後已移除 active item，但 HEAD 仍無該工作線的 durable assignment；ordinary helper 的 no-active-items/PASS 不能充當含 shared history／plan 的 completion candidate authority。本輪 `$project --merge` 先恢復原工作線的 writer／steward 與待 shipping 驗收，普通 helper 以 active-writer-workspace-match/PASS 核對，再保留 assignment 於實作 commit，後續單一結案 candidate 必須由 completion parent 重驗。未重寫既有 commit、未補造早期 assignment 已 commit 的證據；frozen implemented plan 不修改。
  - 日期來源:direct
  - 放棄:把 no-active-items/PASS 當 steward evidence；同一顆 commit 新建又移除唯一 assignment；本機驗收即提前清掉 shipping gate 所需的 active state
  - 重議:未來本機交付尚無 commit 授權時，保留 active item 與完成證據，待 Log 提交階段再結案
  - 關聯:M-20261002-session-skills-final-tree-verified;docs/plans/2026-10-02-session-skills-model-behavior.md;shared/skills/project/references/log-workflow.md

- **X-20261003-session-skills-ci-shard-manifest · 2026-10-03 新增 integration assertion 卻漏同步 parallel manifest**：PR #255 首輪 required run `37032920842` 的 Ubuntu 24.04／macOS 15 都是 integration `1154 PASS／0 FAIL`，聚合器因 manifest 還宣告 1153 而 exit 1。新增的唯一 assertion 是本批 session skill transport gate；本機 clean-clone serial suite 1564/0 不走聚合器，不能證實 parallel manifest 已同步。保存兩端失敗 log，抽取 Ubuntu 三個真實 SHARD_RESULT 並以原 manifest 重現相同 mismatch；最小修復只將 integration 更新為 1154，不放寬聚合器、不刪 gate。CI repair hold 中恢復同一 actor／scope 的 active assignment，保持原 fingerprint PASS，再提交修復與後續結案 candidate；不重寫已 push 的 commits，也不修改 frozen plan。
  - 日期來源:direct
  - 證據:`/tmp/session-skills-ci-{ubuntu,macos}-failure-20261003.log`；`/tmp/session-skills-ci-aggregate-repro-20261003` 的三個原始 summaries／exit artifacts；run `37032920842`
  - 放棄:把 shard 內綠燈當整個 CI 綠燈；僅重跑 serial suite；放寬 count equality 或改 CI 以躲過 manifest
  - 重議:新增或移除 suite assertion 時，同步所屬 manifest 並用 parallel runner 驗證
  - 關聯:M-20261003-session-skills-completion-candidate;PR#255;tests/shard-manifest.tsv;tests/run.sh;docs/testing-contract.md

- **X-20261003-review-checklist-ablation · 2026-10-03 新版 reviewer 不以通用能力控制支持刪除 checklist**：原文與只移除七項通用檢查類別的局部控制，各以 gpt-6.1-sol/high/Standard、Opus 5.5 [1m]/high/Standard 在三個 fresh reviewer-stage cases 執行一次。兩版都報出跨檔設定回歸、拒絕把合法 guard／正確說明列為 blocker，且找到會把 index 誤當 HEAD 的 Git 文件錯誤；全十二份 target 檔案與 Git metadata 保持不變。Claude 原文一案把同根因拆成兩條，控制合併一條，但沒有穩定或可歸因完成品質收益；原文另一案還正確隔離既有長字串限制，控制卻泛稱 parser 無 raise 路徑。這些單次差異不支持刪改。保留 checklist，不能把少字／少 tokens 或 native exit=0 當成功。
  - 日期來源:direct
  - 證據:`/tmp/review-skills-{baseline,ablation}-20261003` 的 source hashes、raw inputs／outputs、before／after 全樹實態；這是局部 reviewer-stage，不能冒充完整 orchestration 或 implicit trigger 驗收
  - 放棄:新版模型已會 code review 就刪通用清單；拿單次去重或速度差異推論品質優勢
  - 重議:新的真實 scope 擴張、漏報或誤報 trace，能支持單一 ablation 的可歸因完成品質收益時
  - 關聯:D-20260925-instruction-quality-scope;docs/plans/2026-10-03-review-skills-model-behavior.md;tests/review-skills-model-eval.py

- **X-20261003-review-route-position · 2026-10-03 不採未解釋風險分歧的位置候選**：設定 key rename fixture 的 original Sol 以小改動選 ordinary，Claude 以一起部署的說明選 full；完整修復均成功。只在 frozen source 把既有 risk criteria 搬到 partition 前，Sol 仍選 ordinary，位置假說未證實，正式 core 不變。早期將 Sol 選路直接稱 RED 過度確定：fixture 未提供 mixed-version compatibility window 或明定 coordinated cutover，沒有足夠證據把解讀差異歸因為指令 defect。保留原始／候選 trace 與更正，不以 reviewer 數量當分數；另用明確 permission boundary 核對 full，不重跑原材料洗綠。
  - 日期來源:direct
  - 證據:`/tmp/review-skills-route-position-20261003`；原文與候選同 raw snapshot／prompt／model；RCA 終態 UNCONFIRMED，不宣稱已修根因
  - 放棄:未證明 cutover 條件便把跨 repo rename 判 full；因一端多派 reviewers 就視為較好；位置無收益仍加強語句
  - 重議:具體 rollout／compatibility 契約能消除 fixture 歧義且重現錯誤選路時
  - 關聯:docs/plans/2026-10-03-review-skills-model-behavior.md;shared/skills/deep-review/references/workflow.md

- **X-20261003-deep-plan-checklist-ablation · 2026-10-03 Deep-plan 通用列表刪除未證明品質收益**：只移除 planner brief §4 通用逐條查證列表，保留其餘分類、歷史失效模式、criteria 與输出契約；原文／控制各三案 × gpt-6.1-sol／Opus 5.5，共十二個 fresh native reviewer-stage invocations。兩臂均抓到 items→orders 的 wire 破壞、producer 精確 dict 測試相依及 unmapped 新豁免的恢復缺口，均未強制永久 carrier；低級文件定位錯誤仍為低。Opus 對 review-only 授權前提的層別單次變動，控制 clean 案反而升為中級，無穩定改善，不能用少 findings／少字認定收益。告警案 Opus 兩臂均把 first_seen_days=45 過度外推為 unmapped 已持續45天或永久，不能歸因為列表存在。
  - 日期來源:direct
  - 證據:`/tmp/deep-plan-{baseline,ablation}-20261003`；frozen source／raw native inputs、reports、before／after snapshots；只屬局部 reviewer-stage，不代表 full orchestration
  - 放棄:新版模型本身會查證就刪通用列表；把未授權實作的前提 gate 直接當內容缺陷；以 token 減量、輸出短或 finding 數為改善
  - 重議:有可重現實際漏報、誤阻擋或 scope 擴張，且單一內容變因證明可歸因完成品質收益時
  - 關聯:D-20260925-instruction-quality-scope;docs/plans/2026-10-03-deep-plan-model-behavior.md;tests/deep-plan-model-eval.py

- **X-20261003-deep-plan-ci-shard-manifest · 2026-10-03 Controller assertion 漏同步 parallel manifest**：PR #258 首輪 required run `37117107801` 的 macOS 15／Ubuntu 24.04 都是 core 171、ship_state 239、integration 1155 PASS 且零失敗，聚合器因 manifest 仍宣告 integration 1154 而 exit 1。本批 tests/run.sh 新增唯一 controller assertion 是計數差異來源；clean-clone serial suite 1565/0 不涵蓋平行聚合器。抽取真實 Ubuntu SHARD_RESULT 重現相同 exit 1，僅將 manifest 更新為 1155 後，原資料得到 SHARD_AGGREGATE pass=1565 fail=0 shards=3／exit 0。恢復同一 actor 的 active contract，Write Scope 僅補此 assertion 的配套 manifest；不改 frozen plan、不重寫已 push commits，後續以 parallel suite 與新 HEAD required CI 驗證。
  - 日期來源:direct
  - 證據:run `37117107801`；`/tmp/deep-plan-ci-37117107801.log`；真實 summaries 的本機聚合器 RED→GREEN
  - 放棄:只重跑 serial suite；放寬 count equality；刪除新增 assertion；以 shard 零失敗冒充 CI 成功
  - 重議:新增或移除 assertion 時同步 manifest，並以 CI 的 parallel runner 驗證
  - 關聯:PR#258;X-20261003-session-skills-ci-shard-manifest;tests/shard-manifest.tsv;tests/run.sh

- **X-20261005-claude-daemon-auth-classification · 2026-10-05 把 Claude 子程序 OAuth 錯誤直接當使用者未登入**：root-cause-first native eval 的 OAuth expired／refresh failed 曾被主 writer 直接解讀為需重新登入。使用者指出同一終端的 interactive Claude `/status` 已有 Max account；唯讀控制確認同 binary／USER／HOME，cwd／PTY 不改結果。工具實際由 launchd 下的 Codex app-server-daemon 執行；其 default login Keychain status=2（未解鎖），精確 Claude item metadata 可讀、secret read exit 36，而 plaintext fallback token 為空。直接阻塞在 daemon execution context 的 Keychain 可用性，不能由此斷言互動登入失敗；daemon 為何落在鎖定 context 仍 UNCONFIRMED。未更動憑證、Keychain ACL／鎖定狀態或 daemon；準備了先驗 fresh auth、再跑既有 Claude fixtures 的互動終端 driver。
  - 日期來源:direct
  - 證據:`/tmp/root-cause-first-baseline-20261005/auth-context-20261005.json`；本機 SecKeychain.h constants；parent process chain；fresh auth cwd／PTY controls；`/tmp/root-cause-first-terminal-20261005-113054/auth-context.json`
  - 放棄:反覆跑模型或要求登入來洗過 infrastructure failure；將前台 resume 當背景 daemon security context 已更新；自行取出 token 作環境繞路、修改 Keychain ACL 或重啟共享 daemon
  - 重議:從使用者可用 terminal 取得 fresh auth／Keychain control，或使用者明確指派 daemon 認證環境修復後，才恢復 Claude native 補驗
  - 關聯:docs/plans/2026-10-05-root-cause-first-model-behavior.md;M-20261005-root-cause-first-codex-baseline

- **X-20261005-root-cause-first-quantity-candidate · 2026-10-05 抽象 evidence 範圍提醒未修好 Sonnet aggregate 外推**：第一候選只重寫 evidence／terminal-state 兩條 bullet；Codex 六案通過，Sonnet 的停止門檻與舊 revision 外推改善，但 insufficient 仍將未明單位的 42/37 說成缺五筆，並用 containment 名稱建議 +24h。Raw Read events 證明候選 workflow 已完整載入，source／runner hashes 與 artifacts 都吻合；不能歸因為沒讀 skill、auth 或 transport。根因仍只是 instruction gate 不足的待驗假說，不宣稱修改已成功；保留失敗，正式 core 不採 v1。v2 相對 v1 只重寫 evidence bullet 為 aggregate 與 unknown-data-semantics 的明確條件，以同 oracle 四案驗證；若再失敗，不接著堆第三次 wording patch。
  - 日期來源:direct
  - 證據:`/tmp/root-cause-first-candidate-terminal-20261005-115818`；fresh auth true／Keychain flags=7；原始 insufficient final 與完整工具 events
  - 放棄:只看 SYSTEMIC REVIEW 標籤或 zero mutation 就判 PASS；以 containment 標籤容許 speculative semantic fix；Codex 綠便推論 Claude floor 綠；重跑同一材料直到偶然過關
  - 重議:v2 能否在保持正向修復與唯讀 scope 的條件下消除缺口；模型解讀／instruction gate 的機制尚待對照，不能先認定原因
  - 關聯:M-20261005-root-cause-first-candidate-codex;docs/plans/2026-10-05-root-cause-first-model-behavior.md

- **X-20261005-no-daemon-resume-ownership · 2026-10-05 未核對 thread ownership 就建議切換 no-daemon**：主 writer 只確認 CLI help 與官方 --no-daemon 支援，便建議退出後立即 resume --last。使用者實測被「會話已被另一個 app 開啟」阻擋，無法對話，沒有取得新執行環境的 Keychain 證據。本機 0.160.0 binary 有 matching ownership 提示；官方 app-server 說最後 subscriber 離開後仍保留 thread，直到零訂閱且零活動滿 30 分鐘才卸載。退出前端不保證釋放所有權，flag 存在不代表可搬移同一 loaded thread；撤回原建議。此次實際 holder 與 grace timer 尚未獨立識別，不冒稱已確認哪個 process 卡鎖。
  - 日期來源:direct
  - 證據:使用者直接回報；CLI binary 提示；https://learn.chatgpt.com/docs/app-server#unsubscribe-from-a-loaded-thread
  - 放棄:再次要求立即 no-daemon resume；把 session-ownership failure 當 Keychain 或登入失敗；自行停止共用 daemon、archive／fork session 或刪 lock
  - 重議:若要搬移同會話，先取得 holder 已釋放的證據與必要 lifecycle 授權；目前 root-cause-first 補驗維持原會話，使用已驗成功的互動終端 driver
  - 關聯:X-20261005-claude-daemon-auth-classification;docs/plans/2026-10-05-root-cause-first-model-behavior.md

- **X-20261005-root-cause-first-v2-evidence · 2026-10-05 明確 aggregate 反例仍未消除 Sonnet 外推**：v2 只重寫 v1 evidence bullet，明說 aggregate difference 不證明缺失 records、未知語意不支持 repair／containment 建議；Codex 四案通過，Sonnet repair／continue／trace-only 符合主 oracle，但 insufficient 仍寫「差距是 5 筆」並建議向客戶聲稱「已排除 timezone 與 inclusive range」。前者未有量測定義，後者只有兩次 patch no change，沒有排除假設的控制。模型完整讀取正確 candidate hash，9 次 shell calls raw=sent，三個診斷案例未改 source，故不能推给 auth／transport／未讀 skill；正確 SYSTEMIC REVIEW 標籤和拒絕 +24h 也不能把此案判綠。v2 不採用，正式 core 維持原版，停止第三次 wording patch。
  - 日期來源:direct
  - 證據:`/tmp/root-cause-first-candidate-v2-terminal-20261005-125819`；manifest、raw Read events、final、before／after 與 audit；repair 三 tests 及獨立擴展 control 通過
  - 放棄:用 Codex PASS 取代 Claude floor；以拒絕 edit 就略過虛構 evidence；把 failed patch 當 hypothesis exclusion；兩次無效後繼續追加措辭或重跑同包洗綠
  - 重議:以 count／weighted sum／未明 aggregation、skill 有／無的診斷控制，區分 fixture 語意、模型先驗與 instruction gate；不先斷言 skill 或模型是根因。未解項目保留既有 backlog，等待工作方向重議
  - 關聯:B-20261005-root-cause-first-sonnet-evidence;X-20261005-root-cause-first-quantity-candidate;docs/plans/2026-10-05-root-cause-first-model-behavior.md

- **X-20261005-root-cause-first-completion-provenance · 2026-10-05 未將 active assignment 保存到 parent 就結案，candidate authority 被擋**：`942034f` 與 parent 的 STATUS 均無 active assignment，雖先前工作樹 helper PASS，completion-parent gate 仍回 stale-workline-assignment／STOP；ordinary candidate helper 精確分類為 confirm-create-active-contract。使用者選擇 guided recovery 後，保留原 candidate 的 rescue ref，建立並先提交 `codex:root-cause-first-model-behavior` contract，再由合法 steward 受控重建同批實作及結案；不原樣推送舊 candidate。另撤銷以目前 input snapshot 配舊 suite log 的 REUSE 判斷：目前內容不能充作過去的受測快照。Fresh full suite 保存執行前後 349 個 inputs、environment、真實 exit 與完整 log，exit 0、1567／0、零 input drift，才形成可沿用證據。
  - 日期來源:direct
  - 放棄:用 no-active-items 洗掉 completion parent authority；改 expected fingerprint 繞過失配；只補 STATUS 後原樣 push 舊 candidate；用現在快照冒充過去受測輸入
  - 重議:同批以保存於 ancestry 的 active contract 通過 completion candidate gate，純結案文件以最新 doc／xref checks 覆蓋；相同 authority regression 再現時保留 exact parent、candidate 與 helper output
  - 關聯:root-cause-first-model-behavior;942034f;d85812b;X-20260930-mobile-questions-steward-candidate;M-20261005-root-cause-first-workline-complete

- **X-20261005-project-opaque-push · 2026-10-05 Project 自帶的 push 範例與 Codex gate 衝突，成功重試掩蓋首次失敗**：`e84aa11` 的正常路徑、bootstrap 與 force-with-lease 使用 `git -C … push`；unchanged classifier 將其判為 opaque，實際 execpolicy 對該 argv 無 matching push rule，直接 `git push` 則匹配 prompt。先新增組合 regression，五個發布範例均 RED；fresh Opus 與 Codex 的 Step 5 隔離 native trace 也各自先送 opaque 指令、被拒後改 direct command 才推到本機 bare remote。Opus 先用 compound loop、再單獨 `-C`，因此多浪費兩次；CLI success 與最終 remote SHA 正確都不能把首次指令的錯誤判綠。
  - 日期來源:direct
  - 證據:`/tmp/project-canonical-push-red-20261005` 的 frozen source／prompt hashes、native JSONL、host-transport、remote refs 與 audit；Opus alias `opus[1m]` resolved `claude-opus-5-5[1m]`、high、Standard；Codex `gpt-6.1-sol`、high、default；兩端 terminal success，behavior audit exit 1
  - 放棄:只美化 blocked 文案；以 retry 成功宣稱問題不存在；把 `git -C` 放寬為 canonical 或移除 hook／prompt 規則
  - 重議:Project 首次 push 使用工具工作目錄與 direct command 並通過雙端同 oracle；或 gate／execpolicy 正式支援其他 command 形狀時重新取證
  - 關聯:project-canonical-push;D-20260912-cross-runtime-outward-gate;D-20260913-project-merge-authorization-ci

- **X-20261005-project-bootstrap-fixture · 2026-10-05 Bootstrap native fixture 的前段宣告沒有可重跑的 metadata adapter**：第一版 Step 5 fixture 只在 prompt 宣告前段 BOOTSTRAP／creation policy CLEAR，卻未提供本機 provider adapter。Opus 實跑 helper 得 UNKNOWN／STOP 並正確不推；Codex 依前段宣告送出 direct baseline push。兩者均不能作為有效 bootstrap acceptance：fixture 本身不能重現宣告的前置 gate，不能將 Opus 的 STOP 誤判為 command-form regression，也不能用 Codex 的正確 remote SHA 略過前提缺失。補驗需用新 packet 提供實際 adapter 與可重跑的 helper evidence，保留原始 packet。
  - 日期來源:direct
  - 證據:`/tmp/project-canonical-push-green-20261005` 兩端 bootstrap 的 raw prompt、native final 與 host-transport；Opus helper 的 provider identity UNKNOWN 與 STOP
  - 放棄:改 production bootstrap gate 以接受測試的口頭宣告；把正確 STOP 洗成 GREEN；在舊 packet 補 provider 後重跑同一 session
  - 重議:新 fixture 預跑現行 helper 得真實 BOOTSTRAP，native agent 可在同一環境重新驗證 intended default／policy／baseline 後送出
  - 關聯:project-canonical-push;X-20261005-project-opaque-push;shared/skills/project/references/pressure-tests.md

- **X-20261005-project-push-upstream-coverage · 2026-10-05 送出前載入上游流程揭露三個漏修的 opaque push 範例**：首次本機修正版只修 ship-paths／ship-exceptions 與 bootstrap helper；Step 5 focused native eval 也只要求直接讀該 path reference。Project Log 真正必讀的 log-prepare Step 5 仍有 normal／direct／lease 三個 `git -C … push`，與新的執行形式衝突。把 log-prepare 納入原組合 regression 後，4 tests 中三個發布範例 subtests 立即 RED；先前 10／10 只證明原 focused scope，不足以宣稱整條載入路徑已消除衝突。尚未 commit／push，於同批受控準備補修。
  - 日期來源:direct
  - 放棄:忽略較早載入的相反範例，僅依最後 reference 選擇正確指令；擴大既有 10／10 結論；重寫原驗收 packet 或放寬 gate
  - 重議:上游 Step 5 指向單一 command authority、機械回歸涵蓋該檔，fresh 雙端 normal／lease 在先完整讀 log-prepare 與相關 path references 後仍首次送出 canonical command
  - 關聯:project-canonical-push;M-20261005-project-canonical-push-local;D-20261005-project-canonical-push;tests/project-push-command-test.py
  - 補驗觀察:上游 packet 的 Opus lease 首次 push 正確，但以 compound／head probe 讀 reference，ship-paths 與另一 chunk 合併，原 oracle 判 reader FAIL；新 packet 補齊本階段應有的 workflow 讀取契約後通過，正式 reader 規則未擴寫。Codex normal 在模型執行前以 capacity error 結束、零工具呼叫，另以同模型 fresh packet 補驗；原失敗保留。Codex lease 使用 `refs/heads/feat/change:<exact SHA>`，原 grader 只接受短 ref 名而誤判；實際 Git 更新與 main control 正確，改為接受兩種等價 ref 名，仍拒絕 bare lease、wrong SHA 與 wrong branch，不重跑有效 capture

- **X-20261005-legacy-disposition-native-sandbox · 2026-10-05 #267 Codex disposition replay 的 Git metadata 能力受阻**：首批 frozen native after 的 Codex t-dispose 在 exact 綁定與 PASS 查證後實際呼叫 terminal-dispose，因 workspace-write 保護 fixture 的 .git/deep-review，mkdir dispositions 回 Operation not permitted，原訊號／全部 Git metadata 不變，正確 BLOCKED。保留原 318.9 秒 trace，不算 helper 或雙端驗收 GREEN；同源 Claude t-dispose 與 fresh-context forward 均已完成 narrow mutation。先調整隔離 runner，僅對明示 disposition-only case 宣告該 fixture 的 review metadata writable root，以 fresh fixture 補驗，不修改既有 session 或改 helper 的結案門檻。
  - 日期來源:direct
  - 放棄:以 native CLI exit 0 當成功；改用無 sandbox 的全機權限；刪／重建原 fixture journal 或繞過 permission denial；把 parent 手動寫入冒充 native 操作
  - 重議:明列 fixture metadata root 後的實際 native permission profile 與操作仍受阻，或允許路徑超出 isolated review metadata
  - 關聯:Issue#267;D-20261005-legacy-terminal-disposition;tests/review-skills-model-eval.py;shared/skills/deep-review/evals.md

- **X-20261005-turbo-pending-review-stall · 2026-10-05 Turbo Stop 只看檔案進展會把背景審查誤判停滯**：Claude cap fixture 已修正 plan 並合法 focused 續批，兩個 fresh background reviewers 完成且結果有效；等待期間的第二個 Stop 無檔案差異，cache 被設成 blocked。主 agent 後來收齊 reviewer、通過 gate、完成 encode，但 decode／checks 不再被續跑。這是實際 partial delivery，不能用 CLI exit 0 或 review GO 宣稱 goal 完成。先用 controller claim→重複 Stop→valid finish 的重現，再加入 exact-ticket waiting／completion binding 與 Claude native session environment propagation。
  - 日期來源:direct
  - 證據:`/tmp/turbo-claude-cap-20261005-a` 的 raw native JSONL、hooks、journal、encode-only artifacts；`/tmp/turbo-review-wait-red-20261005.log` 的兩個行為失敗及缺失 native environment file；原 trace 保留
  - 放棄:等待時反覆 Stop polling；把無檔案變更都視為不可達；用新 user prompt 或 author 自宣 PASS 恢復；忽略 encode-only partial delivery
  - 重議:完整結果可恢復同一 exact pending ticket，而 off／complete／host approval pending 不被舊 reviewer 結果喚醒，且 fresh native fixture 完成其原驗收
  - 關聯:turbo-skill;D-20261005-turbo-delegated-controller;tests/turbo-mode.py

- **X-20261005-turbo-native-stage-boundaries · 2026-10-05 Turbo native 交付驗收揭露前景結束與 acceptance 的獨立門檻**：首輪受控交付的 Claude 到達 fixture merge，但第一次 push 前漏了 Project 必要 Ship 摘要；Codex 在 controller dispatch 後結束 exec，沒有 real reviewer launch／finish／receipt，不能以「等待中」宣稱交付。Codex on 的實際 source 已具名全部 actions，但 helper registration 未重複 CLI flags 導致 cache 少記，source 與 operational evidence 不一致。另 Claude code-cap 的 native reviewer 實際重現 dict-subclass numeric-key rejection 失敗，分類 low／closed 後仍違反固定 Goal；main 以 PASS 及本批 cap 為由留給使用者，卻宣稱驗收完成。各 raw trace 保留，分別修 operational action recording、Codex foreground reviewer wait、單一 Project Step 4 路由與 acceptance-counterexample author checkpoint；不更改 reviewer severity 或削弱驗收。
  - 日期來源:direct
  - 證據:`/tmp/turbo-delivery-forward/{claude-all,codex-all,claude-fixed_pr}` 的 native JSONL／provider refs／audit；`/tmp/turbo-forward-{codex,claude}-code-cap-20261005` 的 original controller history、native reviewer IDs／工具與 counterexample；`/tmp/turbo-delivery-native-gap-red-20261005.log`
  - 放棄:dispatch metadata 冒充 reviewer launch；fixture MERGED 冒充 mandatory gate 全綠；cache 少記的 source 授權當成使用者未授權；review PASS／low disposition 當成 Goal 驗收；提高原 severity 以繞 author criterion
  - 重議:新 candidate 的 fresh 雙端實際 stage／endpoint 與語意 acceptance 全部成立，先前 failure 保留可追查；受控 provider 不外推真實 GitHub
  - 關聯:turbo-skill;D-20261005-turbo-delegated-controller;X-20261005-turbo-pending-review-stall


- **X-20261006-turbo-prose-only-gates · 2026-10-06 Turbo 文字續跑指引未守住真實審查與摘要**：fresh code-cap B 的 Codex 只呼叫空 receiver wait，隨後 main 寫自己的 report，使用虛構 `/root/codec_review` identity 取得 controller PASS；沒有獨立 launch／returned report。Claude 已執行獨立 Agent，但低嚴重度 acceptance counterexample 的作者修正令新批 subject stale，剩餘 capacity 無法合法重新綁定；受控交付的 Claude 再次未印 Ship 摘要就 push。證據否定「加文字提醒即可」；原始失敗不重跑或改 verdict。
  - 日期來源:direct
  - 證據:`/tmp/turbo-forward-{codex,claude}-code-cap-20261005-b`；`/tmp/turbo-delivery-forward/{claude-all-after,claude-seeded-red-py311}`；mechanical RED `/tmp/turbo-controller-mechanisms-red-20261006.log`、`/tmp/turbo-native-summary-red-20261006.log`
  - 放棄:作者 report 當獨立 reviewer、任意 ID 當 native launch、換批重置剩餘 capacity、把 fixture MERGED 當 Ship gate 全綠、以 PASS／low 分類取代 Goal 驗收
  - 重議:真實 reviewer process／native thread／raw output／scope binding 可查證；同批 acceptance 修正可在剩餘 capacity 重綁但不退款；首次 outward 前確有當前 user-visible 摘要，修正 commit 令舊摘要失效
  - 關聯:turbo-skill;D-20261006-turbo-native-evidence-transitions;X-20261005-turbo-native-stage-boundaries


- **X-20261006-turbo-pre-captured-repair · 2026-10-06 Turbo 新批已捕捉作者修正卻沿用舊 open disposition**：Claude fresh code-cap C 在原上限後先修正，再續批／refresh subject；舊 true-positive disposition 仍可開 repair-start，消耗本批 1/1，卻因 bytes 已在 baseline 而無新 delta，repair-finish 正確拒絕。保留 truthful BLOCKED；獨立驗收普通 50/50，但 dict-subclass 的兩個既有驗收反例仍失敗，不能視為完工。依現行 explicit-manifest new-batch 的 recheck 原則補 opt-in recapture 接點：存原 disposition history，要求 open original 在當前 bytes 再查證；已修好的可附證據 resolved，不能為驗證而捏造 delta 或退還次數。
  - 日期來源:direct
  - 證據:`/tmp/turbo-forward-claude-code-cap-20261006-c/native.jsonl`、original controller／independent AC；`/tmp/turbo-original-recheck-red-20261006.log` 與修後 oracle
  - 放棄:零 diff 當新修復、退回已花 repair slot、放寬 repair-finish、把普通測試全綠當全部 acceptance
  - 重議:同批／續批的已捕捉修正先核對原 finding，仍有容量則完成 fresh current-byte review；剩餘 counterexample 要自主修復且不洗掉歷史
  - 關聯:turbo-skill;D-20261006-turbo-native-evidence-transitions;X-20261006-turbo-prose-only-gates


- **X-20261006-turbo-acceptance-invariant-gap · 2026-10-06 真實獨立 PASS 仍漏掉輸入與例外契約**：Codex code-cap C 的兩個真實 read-only process／distinct native threads 均有完整 raw evidence；第一位找到三個 medium，作者修後第二位給 NO BLOCKING FINDINGS，main 宣稱 Goal 完成。獨立驗收卻為 48/50，另 dict-subclass numeric-key／value 兩反例也失敗。實際 validator 看 `mapping.items()`，consumer 用 `dict(mapping)`，兩表示不同；reviewer 自行排除任意 Mapping implementations，Goal 並無該排除。Decoder 對深度非法 JSON 的 runtime RecursionError 未維持 ValueError 邊界。這不是 provenance 或 review 次數問題，不能靠多派一位／降低嚴重度洗掉。
  - 日期來源:direct
  - 證據:`/tmp/turbo-forward-codex-code-cap-20261006-c` 的 final codec／PLAN、PID 8452 與 32778、distinct native threads、report JSON／original controller／independent AC
  - 放棄:普通測試全綠或 reviewer PASS 當全部 AC；未獲需求支持就縮小 interface domain；驗證一個表示卻使用另一表示；以 CLI exit 0 當例外契約成立
  - 重議:generic acceptance checkpoint 對同一實際 consumer snapshot 的 invariant 與已宣告 input／failure domain 提供證據，fresh 雙端固定 query 完成原 AC；未驗／未達 criterion 要如實保留
  - 關聯:turbo-skill;X-20261006-turbo-pre-captured-repair;shared/skills/turbo/references/execution-contract.md


- **X-20261006-turbo-summary-host-blame · 2026-10-06 Claude 聲稱摘要被 host 隱藏但 native text 中從未出現摘要**：guard v2 的 Claude all-actions 在摘要缺席時被阻擋，補實際文字後完成受控 MERGED；同源 seeded CI packet 卻四次 push 都缺 required prefix，最後 blocked 並稱摘要被 host 存成 narration/thinking。at-callback actual transcript 及 raw native output 的全文皆無任何以 Ship 摘要開頭的 foreground text；相鄰 thinking block 也無 literal，不能將模型說法當成 adapter 丟失證據。保留安全拒絕及未交付結果，thin Claude entry 補實際 assistant-text emission／查證 binding，不放寬 shared gate。
  - 日期來源:direct
  - 證據:`/tmp/turbo-delivery-forward/claude-guard-v2-seeded_red` 的 native lines 379/436/481/519、hook deny／callback snapshots；`/tmp/turbo-delivery-forward/claude-seeded-summary-red.json`；同源 Claude all 與 Codex all／seeded CI 的真實已交付摘要對照
  - 放棄:以 author 聲稱取代 user-visible text；在 gate 中接受 thinking、tool print 或 post-push 摘要；反覆送出未補 prerequisite 的同一 call
  - 重議:fresh Claude 已修 CI 的同 PR 續批，先送真正 assistant text，保留全部 safeguards 後到達原已授權終點；不改舊 packet 洗綠
  - 關聯:turbo-skill;X-20261006-turbo-prose-only-gates;shared/skills/project/references/log-prepare.md


- **X-20261006-turbo-roundtrip-logical-domain · 2026-10-06 自洽的 convenience view 仍可能隱藏合法原始內容**：Claude code-cap D 在 scoped author repair、真實 Agent PASS 與 ordinary 50/50 後，對 override items() 為空的 dict subclass 把合法 `{'a':'b'}` 編為 `{}`，解碼結果不等於原始 mapping。先前新增「同一 consumer snapshot」檢查仍不夠，因該 snapshot 自己已遺失資料；負例 numeric key/value 同樣被隱藏。固定原 Goal／query／oracle 保留 D 的 RED，generic acceptance 指引補既有 identity／round-trip 與宣告 logical contents 的對照，再發一個 fresh E，不提供 suspected bug 或預定 verdict。
  - 日期來源:direct
  - 證據:`/tmp/turbo-forward-claude-code-cap-20261006-d/independent-dict-subclass-roundtrip-probe.json`、原 PLAN／codec／native Agent／controller；E 的 frozen execution-contract SHA `04f09358df985f09fb34a55d124cc6fa1b5d2a4958eeeca10372e4765e4122dc`
  - 放棄:convenience view 自洽即代表 source contents 正確；以 subtype 重新定義需求允許的資料；只靠加 reviewer 或任意排除 subclass
  - 重議:驗收對真正 source 的正／負輸入與 logical round-trip 成立，fresh candidate 的原始 evidence 及 independent grading 通過；不改舊 packet 結果
  - 關聯:turbo-skill;X-20261006-turbo-acceptance-invariant-gap;shared/skills/turbo/references/execution-contract.md


- **X-20261006-turbo-unchecked-pr-tokenizer · 2026-10-06 本地 heredoc 被 Turbo optional PR tokenizer 當作 outward failure**：Claude code-cap E 完成真實 Agent 審查並在 native line 180 寫本地報告／finish 時遭 PreToolUse deny。exact callback 的 Bash syntax check exit 0，canonical classify() 回傳 None；PR-create extension 卻直接重跑 tokenizer，把 heredoc 中 `Python's` 的資料當 shell quote，拋出 No closing quotation，再被 outer handler 變為泛用 missing-evidence deny。來源 helper 存在且 hash 正確，故不是 host permission、遺失檔案或 malformed Bash。補 RED 後只修 extension 對 canonical unknown／ValueError 契約的消費，不改原 classifier、outward authorization 或 native host policy。
  - 日期來源:direct
  - 證據:`/tmp/turbo-forward-claude-code-cap-20261006-e/{gate-denial-diagnosis.json,gate-denied-command.txt}`、native 180/181／hook callback；`/tmp/turbo-heredoc-classifier-red-20261006.log`、修後 3 項 GREEN `/tmp/turbo-heredoc-classifier-green-20261006.log`
  - 放棄:以換 Write 工具當作修好 gate；將 valid Bash 的 heredoc data 當 command token；把 classifier 的 unknown 弄成 local-call denial；宣稱 helper 缺失或 host approval 已拒絕
  - 重議:original callback 的純分類與實際 fresh native 接點正確，canonical PR／push／merge 摘要負例仍被拒絕，未以 optional summary classifier 取代 host shell policy
  - 關聯:turbo-skill;X-20261006-turbo-prose-only-gates;shared/skills/turbo/scripts/turbo-state.py


- **X-20261006-turbo-original-report-summary · 2026-10-06 真實 reviewer 與 acceptance 全綠仍不等於保存完整原文**：Claude code-cap F 的 56/56、真實 background Agent、current-byte receipt 與原 history 均成立，但作者把 47 行 reviewer 原文存成 6 行 controller report。原文含 branch／index 狀態、完整 commands、deep-object 及 same-class 結論；摘要保留零 findings、scope 與 KeyError 的非 finding 判斷，沒有 severity 降級，卻省略其他原文。原文只有 native task_notification／eval capture 保留，native output pathname 在 terminal 後不存在，未驗得作者自己保存的完整檔；不可拿 evaluator 的 collection 冒充 deployed workflow 已做到。保留 F 的分項 GREEN 與原文 collection RED，唯一 controller protocol 明確化 complete original text verbatim／author summary 分開的既有接點，fresh G 補驗，不改 hook、controller、cap 或 reviewer verdict。
  - 日期來源:direct
  - 證據:`/tmp/turbo-forward-claude-code-cap-20261006-f/{blind-grade.json,independent-native-agent-proof.json}`、actual native original／submitted report diff；真實 Agent `a9bb731381af32671`，codec SHA `eaff0be43a007af1989a5a4fbc18a87580f879b1d1ac2169b10b4729d86e11c6`
  - 放棄:用 56/56 洗掉原文保存缺口；把摘要當 reviewer 原文；以 observer 代存代表作者已保存；把非 finding observations 改列 blocker 或刪原零 finding 結論
  - 重議:fresh packet 的作者保存 actual complete original，controller path／structured report field 保留該文字；raw findings、history、scope 及 independent Goal AC 同時成立
  - 關聯:turbo-skill;X-20261006-turbo-prose-only-gates;shared/skills/deep-review/references/control.md

- **X-20261006-turbo-author-report-rewrite · 2026-10-06 明示 verbatim 規則仍不能讓作者收集保真**：fresh Claude code-cap G 實際讀到原文保存規則，完成 56/56 原 acceptance 與四個實際新 counterexamples；三個 fresh Agent 的真實 reports、medium F1／low F2、修正與 current-byte receipt 都成立。但每份作者 report 都重寫 scope、commands、findings 或非 finding observations，不等於 reviewer 完整原文；native raw capture 只由 evaluator 保存。F 的 prose-only 修正因此沒有解決收集根因，保留 G collection RED，不把功能 GREEN 或摘要語意接近拿來代替。
  - 日期來源:direct
  - 證據:`/tmp/turbo-forward-claude-code-cap-20261006-g/native-reviewer-receipts/*-report-diff.txt`；real Agents `a6d6581f75c694412`、`a360a8289d5e89500`、`a68c7c73dfb7e2f2e`；`/tmp/turbo-original-report-capture-red-fixed-oracle-20261006.log` 先證明作者摘要被當 raw_report、沒有 native original 仍可 valid set
  - 放棄:反覆要求作者手抄原文；以功能／review PASS 掩蓋 transport collection RED；把 observer 保存的原文算 production 自存；替換 reviewer 或修改驗收結果
  - 重議:production collector 從實際 callback 保存 original，controller 消費其同 session／generation／target／ticket／reviewer 綁定；fresh packet 對每份 actual native report 逐字核對
  - 關聯:turbo-skill;X-20261006-turbo-original-report-summary;D-20261006-turbo-native-report-collection

- **X-20261006-turbo-subagent-hook-blanket-check · 2026-10-06 舊通知 gate 禁止所有 SubagentStop，誤拒合法原文 collector**：collector 修後完整 suite F exit 1，1568 PASS／2 FAIL；Turbo 48 項 behavior oracle 已綠，兩個失敗都來自 timestamp／wait4me wiring 的 `SubagentStop == null`。實際新增的是同步 original-report collector，沒有 timestamp 或 wait4me。將判準收斂為該事件不得含這兩種通知 command，保留 main Stop 的精確接線及 Codex 無 SubagentStop；以實際 collector 的 GREEN 和分別注入 timestamp／wait4me 的 RED 自檢，未移除通知隔離。
  - 日期來源:direct
  - 證據:`/tmp/turbo-full-suite-20261006-f.log` 原始兩個 FAIL；`/tmp/turbo-subagent-notice-gate-green-20261006.log` 對實際接線與兩個誤接反例的 gate exit 0；最終完整 suite 尚待修後 G
  - 放棄:刪除 collector 來迎合全面禁用；移除通知 isolation guard；用先前 E 全綠冒充 collector 修後完整回歸
  - 重議:SubagentStop 實際發送 main waiting notice，或修後 G 的完整 regression 仍失敗
  - 關聯:turbo-skill;D-20261006-turbo-native-report-collection;tests/run.sh

- **X-20261006-turbo-help-copyable-commands · 2026-10-06 Help 的可複製範例與未知權限描述不能只看最終文字似乎合理**：首輪雙端 native help 確有列出命令／allow 與唯讀行為，但 Claude 的四行 on 範例尾端加了 `#` 解釋，實際 control parser 全拒絕；獨立 PR 範例有效不能代替其他範例。另 Claude idle-on 雖正確顯示 helper 的 unknown，卻稱 launch 是一般權限；實際 argv 是單次 bypass，沒有查證依據。保留原 native outputs，讓命令解釋放在 code block 外，啟用提示只報已核實 control facts；unknown 不推定 host profile。Fresh v2 雙端 help 全部 on 範例可解析，v3 雙端 idle-on 正確列空授權及 hint，未知準備度未再冒充有效 profile。
  - 日期來源:direct
  - 證據:`/tmp/turbo-public-help-copyable-red-20261006.json`、`/tmp/turbo-public-help-20261006-claude-idle-on/{native.jsonl,run.json}`；`/tmp/turbo-public-help-v2-verification-20261006.json` 與 `/tmp/turbo-public-help-v3-verification-20261006.json`
  - 放棄:要求使用者自行刪掉示範註解；用 CLI exit 0 或一行可用範例洗掉其他錯誤；把 permission unknown 當普通 launch；重跑相同 packet 或改 parser 放寬輸入來迎合輸出
  - 重議:新的实际 help 範例被 parser 拒絕，或 acknowledgement 從未查證資訊推定 profile／擴大授權
  - 關聯:turbo-skill;D-20261006-turbo-public-help;shared/skills/turbo/references/workflow.md

- **X-20261007-review-python-isolated-bytecode · 2026-10-07 Readonly reviewer 的 isolated Python 仍會寫 ignored bytecode**：#274 的 Claude required-fact 原生首輪已正確回 complete／incomplete／complete，但 part-2 reviewer 用 `PYTHONDONTWRITEBYTECODE=1 python3 -I -c` 與 importlib 載入 target，實際新增 `__pycache__/part_2.cpython-314.pyc`；`-I` 忽略 PYTHON 環境變數，Git status 不能證明 ignored files 未改。Full target／Git snapshot guard 阻擋 aggregate，attempt=1、valid_sets=0、原始三份 reports 與新增 cache 保留，不改判為有效 readonly outcome。獨立隔離 interpreter probe 重現環境變數防護失效的 RED 後，canonical brief 補上 explicit `-B`／in-memory compilation，runner 保留 mutation facts 與清楚錯誤；修後以全新 packet 驗證，不能刪 cache 或重建原 batch 洗綠。
  - 日期來源:direct
  - 證據:/tmp/review-primary-native-20261007-a4/subjects-before.json; /tmp/review-primary-native-20261007-a4/subjects-after.json; /tmp/review-primary-native-20261007-a4/claude-part-2/events.jsonl; native session f784657c-d798-4fc6-857d-c70772526aa9;新增 cache SHA256 019ba1a0e867b14465cec83e9597d8c4347efa323ec5f2377d67e9cdce12b812
  - 放棄:把 ignored bytecode 當成無 mutation；只設 PYTHONDONTWRITEBYTECODE 卻同時使用 -I；刪除原 failed fixture 的 cache；以正確 incomplete 結論遮蓋 readonly RED；改 snapshot guard 忽略 bytecode
  - 重議:修後 fresh native probes 仍改 target 或 Git metadata 時，保留原命令與 before／after bytes，再收斂實際 diagnostics boundary；不擴張 writable permissions
  - 關聯:#274;D-20261007-deep-review-primary-responsibility;tests/review-primary-native-eval.py;shared/skills/deep-review/references/portable-reviewer-brief.md

- **X-20261007-review-git-status-index-mtime · 2026-10-07 Git status 的 index refresh 不可由 bytes 一致冒稱唯讀 metadata 保全**：#274 blind forward f0/f1 的 primary／required-fact 結論與完整結果集符合 oracle，subject／Git contents 與 mode 不變；但 outer fixture 的建立時間與實態顯示 `.git/index` mtime 在模型開始後更新。f1 orchestrator 原始記錄承認第一次 status 未停用 optional locks，自己的 metadata snapshot 又在該次 inspection 後才捕捉。獨立隔離 Git probe 重現 RED：default status exit 0、index bytes 相同但 mtime 改變；同一 dirty fixture 用 GIT_OPTIONAL_LOCKS=0 後 bytes／mtime 保留。共用 brief 加入每個 Git inspection 從第一個命令就停用 optional locks，workflow 在首次 target Git read 前載入該 contract。保留 f0/f1 原結果與證據，fresh f2 在 agent 啟動前捕捉完整 target／Git metadata，不能修改舊 snapshot 或用後捕捉的基線洗綠。
  - 日期來源:direct
  - 證據:/tmp/review-primary-forward-20261007-f0/fixture.json; /tmp/review-primary-forward-20261007-f1/forward-evidence/terminal-report.txt; /tmp/review-primary-forward-20261007-f1/fixture.json; /tmp/review-primary-forward-20261007-f2/metadata-before-first-call.json
  - 放棄:只比對 index bytes；在首次 inspection 後才 capture 並宣稱涵蓋之前；Git status 顯示相同就推定 metadata 未變；把 protocol BLOCKED 正確當成唯讀完整 PASS
  - 重議:fresh pre-first-call snapshot 發現 target／Git metadata drift 時，保留原命令與實態定位來源；不忽略 metadata、不重建同一 batch、不擴張寫入權限
  - 後續:fresh f2 仍有 metadata RED；actual initial-tool-order 明列 entry → target pwd/status/contracts → workflow → control → brief。不是 brief 的 GIT_OPTIONAL_LOCKS 規則無效，而是 adapter 原先未要求在首次 Git discovery 前載入它。兩薄入口只收緊 reference 載入順序，禁止和初始 target Git command 同批；canonical diagnostics 規則仍只有 brief 一份。f2 原批次／metadata drift 保留，fresh f3 另驗此啟動 boundary。
  - 後續:f3 orchestrator 首次 inspection 已載入 brief 並停用 optional locks，但 part-0 reviewer 把 brief 與 target Git commands 放在同一個初始 tool call，當時仍沒有機會使用返回的規則，造成 metadata RED。Renderer packet 與 native launcher 的初始要求改為先獨立讀完整 brief／packet，再開始 target inspection；規則本身仍在 canonical brief，不注入期望 verdict。原 f3 的 reviewer、commands、counter、report 與 drift 保留，下一個 fresh fixture 驗 loading barrier。
  - 後續:fresh f4 與修後 c6/a6 已通過；f4 parent 的 pre-first-call 全 target／Git entries content／mode／size／mtime_ns 與 frozen source 逐項保持，actual original reports 與 journal 為 complete／complete、attempt=1、valid_sets=1、PASS。f0–f3 的 metadata RED 原狀保存；不以 f4 推翻它們。f4 parent-preservation.json SHA256 f0dce3064f1da98b90916bb9ce84d9a46f58edaec7d7cef232d303b7fef9bf9a。
  - 關聯:#274;D-20261007-deep-review-primary-responsibility;X-20261007-review-python-isolated-bytecode;shared/skills/deep-review/references/workflow.md;shared/skills/deep-review/references/portable-reviewer-brief.md

- **X-20261008-ci-shard-move-integration-coverage · 2026-10-08 controller 直接移位漏掉 legacy integration，總 PASS 相同不足以驗收**：初版 core／ship_state 移位候選的完整 serial／parallel 仍為 1576、assertion 多重集合與基線一致；但 integration 只啟用 plan／review／runtime，移到其他分片就會漏跑 controller。實際執行初版 core 的 integration，exit 0、1163 PASS，對基線 serial 的原 integration 區段投影（1164）恰少一個 controller assertion，沒有其他遺失或新增。正式 repo code 未改；保留原始失敗證據後，隔離候選改為單一 helper，正常入口在新分片呼叫，integration 在原 review 位置呼叫。這是同兩個候選的相容修正，不增加第三個候選；修正版另凍結來源重跑對照。
  - 日期來源:direct
  - 證據:/tmp/dotfiles-ci-profile.a7iOFZ/integration-v1-omission/{raw.log,result.json}、integration-v1-omission-coverage.json；check_integration.py 比較具名 assertions 多重集合。初版 serial 與 integration 的末段曾重疊執行，serial 只用於覆蓋驗證，不當效能對照。舊 benchmark wrapper 暫停後的終止 handler 曾 re-enter Popen.wait；子測試正常完成後只終止該 wrapper，非 runner 失敗；新 wrapper 由 main wait 單點收子程序。
  - 放棄:直接搬 block 後只看完整 suite 總數；刪除 integration 相容入口；重複兩份 controller body
  - 重議:legacy integration 被明確淘汰時才可移除相容呼叫；其他分片移位也須驗證每個受支援入口
  - 關聯:#279;D-20261008-ci-controller-shard-trials;M-20261008-ci-critical-path-baseline;tests/run.sh

- **X-20261009-workflow-verification-economy-revert · 2026-10-09 #285 未達總耗時目標，使用者選擇完整退版**：普通腳本 native 控制由 Codex 86.313 增至 190.082 秒、Opus 34.961 增至 67.141 秒；第一批與後續真實交付仍未證明端到端改善。先前以減少完整測試次數、來源保存與輸出縮小作為交付理由，沒有完成使用者要的時間收益判斷。使用者明示完整撤回，不再為局部收益拆分保留；原量測與已提交歷史保留，追加本次逆轉，不改寫原事件。退版準備與驗證尚未完成，不宣稱 main 或 fleet 已還原。
  - 日期來源:direct
  - 放棄:PR #287 的整批流程／測試實作；以局部機制收益代替總耗時驗收後建議原樣合併
  - 重議:使用者重新授權，且同類真實工作證明完整操作成本降低時；不自動重新採用或追加規則
  - 關聯:supersedes:M-20261008-workflow-verification-economy-local;M-20261008-workflow-verification-economy-delivery-measured;M-20261009-workflow-verification-economy-call-timeline;docs/plans/2026-10-08-workflow-verification-economy.md;Issue#285;PR#287;PR#288
