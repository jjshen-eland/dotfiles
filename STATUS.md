<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-12)

---

## 進行中

### 2. Runtime 目錄收斂與 legacy 遷移 🆕

- **Context**：同一版 dotfiles 的新裝與既有主機升級尚未收斂：setup 與 dotsync 的 runtime 部署涵蓋不同，本機 Claude skills 曾需手動補入口；Codex rules 有整目錄連結與保留本機授權紀錄的共存形式；handoff 仍依 canonical／legacy 目錄存在情況選擇 store。使用者要求把歷史差異集中遷移，減少各腳本與 skill 的永久相容分支。
- **Goal**：同一版 dotfiles 在 macOS／Linux 的乾淨新裝、既有環境升級與重跑部署後，得到相同的受管理 runtime 結構、資料位置與可觀察行為；保留原生／第三方內容與明示 override，完成納管主機遷移後清理本項可移除的 legacy 執行分支。
- **Acceptance Criteria**：
  1. 在 repo 的既有權威文件定義唯一正式結構與管理邊界：Claude skills 採實體 discovery root、repo entries 逐項連結並保留第三方內容；依使用者本輪澄清，權威 `claude/settings.json` 停用雲端 skills 同步，eagle08 已識別的 synced cache 移出 repo／discovery 並留備份，settings.json 檔案 symlink 保持。Codex entries 位於 `~/.agents/skills`，system／第三方入口保留其原生位置；Codex rules 採實體 root、repo 規則獨立連結、runtime 授權紀錄可寫；handoff 預設 store 固定為 `~/.agents/handoffs`。Codex config 維持既有三層合併契約。使用者續指定兩端 repo 模型採 default／等效 default：兩端都省略 model；Claude 隔離原生選單只列一個推薦 Default，不新增 literal default 的 Custom model。本項不清除機器／session 的模型覆寫，不新增 per-model effort 設定。
  2. macOS／Linux setup、dotsync 的本機與遠端流程、brewup／sysup 的適用入口共用同一組部署 helper；CLI 未安裝時也能準備正確結構並明示能力缺項，不因新裝／升級分成不同 layout。
  3. 遷移工具可盤點、預演、備份、執行、驗證與安全重跑；涵蓋舊實體副本、整目錄連結、逐項連結、缺少新入口及部分完成／中斷狀態。備份留在 discovery root 外，來源 ownership 不明、同名內容衝突、外部 writer 或無法取得一致 snapshot 時停止該目標，不覆蓋或自行選邊。
  4. handoff 舊 store 的 active／archive 與相關檔案完整遷移到正式 store；驗證內容、checksum／錨點、survey／predecessor／verify／consume 行為，不因搬移宣稱舊 claims 已重新授權。canonical 與 legacy 同時存在時，依逐檔盤點處理；有衝突即保留來源並回報。
  5. 盤點本項的 legacy 相容分支與仍存續的資料契約。store 路徑 fallback 在遷移驗收後移除，正常 skill 固定使用正式位置；未遷移環境明確回報需要升級。舊 archive 命名／metadata 格式須另有無歧義轉換與行為證據才移除 reader 相容；仍需保留者逐項記錄原因與移除條件。
  6. 以隔離環境比較乾淨新裝、各受支援舊結構升級與部署重跑的受管理路徑種類、link identity、設定層級、可寫資料位置及載入結果；確認第二次執行不再改動。覆蓋衝突、並行 writer、失敗／中斷恢復與回滾，證明登入／hook trust／個人規則／第三方內容未遺失或意外進入 repo；明示停用且已識別的雲端 cache 清理由本輪具名範圍處理，不擴成刪除其他未知 skills。
  7. 修正合併至 `origin/main` 且取得當批部署授權後，盤點並驗收現行 inventory 的 14 個目標（本機 macs 計一次）：revision、正式結構、共用資源、舊入口殘留與資料保全皆有逐台證據；有原生 CLI 的端驗證實際載入，缺 CLI／連線／信任者明示能力邊界，不以設定檔已存在冒充功能可用或全機隊完成。
  8. 實作前建立可重現的新裝／升級差異 fixture；必要的 handoff behavior eval 與雙端驗證、`./tests/run.sh`、文件與交叉引用檢查通過。涉及既有相容契約的變更，以新 event-time record 明確取代相關舊決策的對應部分，保留歷史證據。
  9. 日常共用部署入口成功且未變更時只印一行 layout 摘要；有遷移時列出變更 root、transaction、receipt 與保留備份。失敗保留完整 JSON 診斷與原 exit 語意；直接 inventory／dry-run／apply／verify 預設仍提供 JSON，不更動 migration 安全判準。
- **Constraints**：使用者已以「開工」授權本項本地實作與驗證；前輪 `$project --merge` 將既有規劃文件與 active assignment 隨 #271 修復提交保存，不代表本項 implementation 或 fleet migration 已完成。本項後續實作的 shipping／部署仍依當批具名授權與 repo 規則。CLI 安裝／更新、套件升級、SSH／inventory 改版及其他 skill 的獨立 legacy 契約不納入本項。保留 config.local.toml 與合法 HANDOFF_DIR override、雙薄入口／單一 neutral core、handoff claims／frontmatter gate；不關閉安全檢查或代為信任 hooks。修改 skill 前依 AGENTS.md 的 authoring route；移除舊 store resolver 前須以安全 migration／locking 的行為證據滿足既有重議條件。
- **本輪接續**：2026-10-07 使用者選擇原 writer 已停止、由本輪接續；本批來源交付包括日常部署輸出摘要與 inventory 檢查紀錄，使用者續以 `$project --merge` 指定本批 PR／rebase merge 終點，不含 live apply、套件更新或 legacy fallback cleanup。已用真實共用 entry 隔離重現：全 roots unchanged、exit 0、home 不變，仍輸出 36 行 apply／guard-config-home JSON；證據在同機暫存 runtime-output-red-s0ow1w1b。本輪 MacBook 的使用者回報顯示四個 transaction committed、兩次 verify unchanged、重跑不新增 transaction；缺主機識別／revision／原生載入結果，不冒稱新增完整 fleet 驗收。
- **本輪驗收**：輸出摘要已完成本地驗收，33 個 runtime isolation tests 通過；最終 serial／parallel 各 exit 0、1575 PASS／0 FAIL，349 個 tracked 檔案內容在測試前後及兩 runner 間一致。新增測試的無 CLI 環境誤紅已以隔離 PATH 重現後修正，能力缺項仍須同一行可見；formatter／migration 程式未因此修改。交付前完整 parallel 補驗同為 1575／0、exit 0，383 個 tracked input paths 含 link targets 前後一致、test-evidence 回 REUSE；詳見 M-20261007-runtime-output-shipping-candidate。來源交付以本批 PR provider 結果為準，fleet 部署與原 legacy cleanup 另待。
- **本輪 inventory 檢查**：依使用者指定唯讀核對現行 14 台；全部正式 handoff store 為實體目錄、legacy store absent、layout handoff plan unchanged，無 handoff lock／stage，handoff receipts 均 committed。四台保留備份與 receipt before 指紋一致；canonical 在檢查前後相同。雙 runtime 的實際 adapter helper 皆解析到 repo shared helper 並與各自 HEAD 相同。PR #275 signed UID 修正在 14 台的 real ps／負 UID／writer blocking／malformed UID controls 通過，本機 dhcp6d UID -2 正常解析、仍列 14 個 writers。此為 inventory 內 default-path cleanup 的遷移前提證據，不含 inventory 外終端、native discovery 或 cleanup 實作／部署；詳見 M-20261007-inventory-handoff-cleanup-ready。
- **進度**：來源修正已由 PR #276 rebase merge 至 origin/main `b6299f5`，required macOS／Ubuntu CI 通過；14 台已核對當時的 Claude literal default／cloud false／settings symlink 與 Codex repo 不固定 model。十三台遠端先通過；2026-10-07 macs 從普通 terminal 停止 native daemon 與核身 updater 後，common entry／verify／rerun／verify-rerun 均通過，layout 正式結構驗收達 14／14（缺 CLI 的既有能力邊界沿 plan 表）。18 個 handoff 檔移至正式 store，checksum／mode／mtime 完整、原備份含 inode 保留、無 stage 殘留；雙端原生 metadata-only discovery 各載入 11 repo adapters。Claude 依已部署 user settings 的 opt-out 在啟動時把 215 個雲端 skill 檔移到原生 .trash、保留內容／mode／mtime／inode，移除 3 個同步索引檔；runtime 與 repo 的 synced／syncd 四路徑均 absent。受管理 entries／handoff／receipts／backups／source 在 native startup 保留，僅原生 cache 與 .claude.json 有預期變化。另已重現 literal default 產生額外 Custom model，依使用者選擇備份 UI 回寫後只收省略 model；來源原生選單驗證只有一個推薦 Default，其他設定與 local 模型覆寫保留。證據見 M-20261007-macs-runtime-layout-accepted／M-20261007-claude-native-default-verified；省略 model 的修正尚未交付 fleet，不宣稱 model turn、背景週期或全專案完成。
- **下一步**：定位 D-20260917-terminal-macbooks-outside-inventory 及 STATUS 的未完成驗收；先取得兩部額外 MacBook 的識別／revision／legacy store 依賴事實，再決定原 plan 的 cleanup 前提，不能直接部署或刪除。
- **關聯**：#271; D-20260823-portable-handoff-skill; D-20260912-neutral-portable-skill-core; D-20260912-codex-config-three-layer-merge; M-20260912-codex-config-and-dotsync-exit; M-20261001-handoff-frontmatter-anchor-verify; D-20261007-claude-model-default-unset; M-20261007-claude-native-default-verified; M-20261007-macs-runtime-layout-accepted

### 3. /project 流程減量與驗證成本（#285）

- **Context**：2026-10-12 依風險分層的唯讀評估顯示，2026-09-01 起工時約 53% 在流程本身、產品與機隊部署約 12%；逃到機隊的事故都由部署輸出、canary 或使用者發現，沒有被流程 gate 攔下；多數流程 gate 的實地紀錄誤擋多於攔截。證據與方法見計畫「評估摘要」。
- **Goal**：gate 只放在錯了代價高、實際發生過、能機械判定之處，把 `/project` 流程壓到支撐部署腳本、agent 契約與受信任 scanner 的最小量，降低小幅變更「交付指令→最終回報」的耗時與讀取量。
- **Acceptance Criteria**：
  1. dotfiles 關閉 active-item contract：`audit --ship` OK、`steward-authority.py` 回 `NOT_APPLICABLE`、`./tests/run.sh --base origin/main` 通過。
  2. 移除 test-evidence 沿用協定：Log 在最終 commit set 執行 repo 宣告的測試與檢查（有選測時涵蓋整批），以 exit code 判定、非零不送出；選測錯誤或空集合不得假綠；改判準後的 tested 類 native case 依計畫判準通過。
  3. ship-state 每個 STOP 與 wait-required-enrollment 附實地攔截／誤擋紀錄與涵蓋機制，0 攔截且已涵蓋者移除；保留項仍有 RED。（已完成：清點後全部保留，D-20261012-ship-state-stops-kept）
  4. PR 已承載的實作結果不另寫 milestone、merge 後不另開補記 PR，D／X 照舊；`find` 命中不退步。（不做：D-20261012-record-reduction-dropped）
  5. 依前述移除縮減 `/project` 必讀 reference，以同一回溯方法量讀取量與耗時改善前後。
  6. 改善後一筆真實小改動交付與 51 次基線（扣等待中位 760 秒）比較。
  7. 會改共用 skill 的第 2–5 項重跑受影響 eval，Claude Code 與 Codex 各實跑一次 Log 比對行為、reader bytes 與耗時。
- **Constraints**：不新增 gate 或機檢；不改 `scripts/doc-governance.py` 受信任 scanner（fleet byte-identical）與 kernel managed block；controller 測試隨所測腳本移除，不單獨刪；branch protection 與 required checks 調整需另經具名授權。claude/settings.json 的 runtime drift 不帶進 commit（dotsync／brewup 會丟棄）。item 2／4 不在本項範圍。本 Spec 未授權任何 commit、push、PR、merge 或部署。
- **進度**：原計畫第 1、2 項已合併（M-20261011-ci-platform-matrix-merged）；第 3 項不實作（D-20261012-record-rules-dropped）；第 5、6 項合併為本版驗收（D-20261012-project-reduction-scope）；deep-plan 路由見 D-20261012-deep-plan-full-review-routing。第 1 項已合併（PR #310，關閉 active-item contract；四個 coordination 欄位其後由 #309 P2 移除，見 D-20261012-steward-identity-removed）；第 2 項已合併（PR #312，收尾改為在最終 commit set 執行測試，D-20261012-test-evidence-removal）；第 3 項清點後全部保留（D-20261012-ship-state-stops-kept）；第 4 項不做（D-20261012-record-reduction-dropped）。另已退役 title-free 召回 ratchet（D-20261012-title-free-recall-ratchet-retired），真實語料排名測試維持現狀（D-20261012-live-corpus-ranking-tests-kept）。
- **下一步**：第 2 項已合併（PR #312）；第 3 項清點後不移除（D-20261012-ship-state-stops-kept）。第 4 項不做（D-20261012-record-reduction-dropped）；第 5 項（縮減必讀 reference）的主要部分是 steward 文字，依使用者選擇先做 #309（item 5）再處理。
- **關聯**：[本項計畫](docs/plans/2026-10-12-project-process-reduction.md); [前一版計畫](docs/plans/2026-10-08-workflow-verification-economy.md); GitHub #285; D-20261012-dotfiles-active-item-contract-off; D-20261010-delivery-overhead-spec; M-20261009-ci-modular-redesign-local; B-20260924-workflow-verification-economy

### 4. Setup 工具與 agent shell 環境對齊

- **Context**：現有 setup 混合必要與互動便利工具，brew 失敗被吞掉；環境依賴各平台生成的 shell 設定。使用者要求按 Codex／Claude Code 需求改版，統一 npm 措辭，提供 14 台既有主機免重跑 setup 的對齊方式。
- **Goal**：新裝與增量更新共用工具宣告及受管理 shell 環境，必要工具失敗可見，保留個人設定與既有額外工具；使用者追加要求明確區分 setup 納管與主機自行安裝，只有前者依新定義新增／移除，後者不升級、不移除、不接管。
- **Acceptance Criteria**：core／workstation 分層、新增 actionlint／ast-grep；plan／apply／check 可觀察且重跑收斂；必要安裝及驗證失敗回非零；雙 shell 無互動命令可讀相同環境，保留專案／個人 PATH 優先權與覆寫；npm／bun 以專案 lockfile 為準；隔離新裝／升級／失敗／重跑測試與完整 suite 通過；14 台 rollout 有逐台預演、revision、驗收與回復路徑。2026-10-10 使用者接受兩端全域工具指引精簡化：只保留高價值工具與適用任務、可用性與按需安裝原則，不複製完整安裝清單；兩端短段落需機檢一致。
- **Constraints**：本批使用者選擇 `$project --merge` 交付修正、七台僅更新 ca-certificates 並續部署；已依此完成 PR #297 與下列驗收。既有工具未經確認不 adopt／移除／升級，除本批具名憑證更新外保持原版本；settings runtime drift 不帶進 commit（dotsync／brewup 會丟棄），不重跑 setup 覆寫 rc，不放行 direnv trust。使用者完成 macmini Xcode license 處理後，本輪依原部署範圍續作該台；後續外向動作依新批指令，歷史紀錄不是授權來源。
- **進度**：PR #297 已 rebase merge 至 `792f154`（修復 manifest stdin 消耗與未使用的 build dependencies 誤擋）；新 HEAD macOS／Ubuntu CI 3m29s／2m04s 全綠，39 個工具／shell 隔離測試通過。14 台 source 與雙端全域指引均同步此版本，core check 掃足 22 項全過。eagle03／db01／ap01／ap02／m4mini／fe01／be01 已完成 plan、限定憑證更新、apply／check／apply／check、原內容保全及 CLI probes；m4mini／be01 新增 Claude Code 2.1.295。七台 ca-certificates 活躍 opt target 均為 2026-09-25，其餘既有套件版本不變、舊憑證 keg 留存；shell 原內容／mode 與 settings hash 保留。macmini 已完成 fresh inventory、plan、apply／check／apply／check，新增 actionlint 1.7.12／ast-grep 0.50.0；92 個既有 Homebrew 套件（含 ca-certificates 2026-08-13）版本不變，雙 shell CLI probes 通過，第二次完整 snapshot 相同。
- **下一步**：先讀 M-20261010-setup-fleet-complete，將待辦限制在歷史工具歸屬／用途核對；依已有 plan／ledger 的非秘密事實列出需使用者判定的 adopt／keep，沒有當批授權不做 SSH／更新／移除。
- **關聯**：item 2 Runtime 目錄收斂；item 3 #285；[環境使用說明](docs/repo-guide.md)

### 5. steward 機制改為內容契約；transfer 模式改以移交給同事為重點（#309）

- **Context**：使用者同時用 Codex 與 Claude，現行 steward 機制以 actor 身分授權，造成大量無判斷價值的確認題，卻不檢查接手真正需要的內容；移交給同事的需求即將出現。評估見計畫「評估摘要」。
- **Goal**：任何 runtime、session、主機只靠 repo 接續進行中的工作；移交給新同事後，repo 足以讓接手者掌握全貌並通過可機械判定的接手驗收。
- **Acceptance Criteria**：
  1. P1：各啟用 contract 的受治理 repo 關閉 `active_item_contract`，`steward-authority.py` 回 `NOT_APPLICABLE`、`audit --ship` OK、該 repo 測試通過。
  2. P2：移除身分授權層（含移交的 actor 狀態機），接續改為內容契約；kernel「Shared work」段依使用者核定的逐字內容改寫、`kernel-gate.py` 先紅後綠；全套測試通過；native case 不出授權確認題且到達原終點；Writer 為其他 runtime 的 fixture 不阻擋 Log。
  3. P3：移交指南改為讓接手者掌握全貌，含接手驗收題組；fixture repo 實跑一次移交，題組由 fresh-context agent 作答並以腳本判分全數通過。
  4. P5：必讀 reference 讀取量與一筆真實交付耗時改善前後已量測。
- **Constraints**：不新增接續相關的機檢或 gate；不改受信任 scanner；kernel 安全底線不動；各 repo 的 push／PR／merge 須另經具名批次授權；P2 實作前跑一批 deep-plan。claude/settings.json 的 runtime drift 不帶進 commit。本 Spec 未授權任何 commit、push、PR、merge 或部署。
- **進度**：評估完成，使用者選定 D-20261012-content-continuity-model、D-20261012-handover-to-colleague-focus、D-20261012-kernel-shared-work-rewrite；計畫為 in-progress。P1 已合併 9 個 repo（kapi-infra #179、kapi-protocol #36、krepo-common #85、krepo-company #61、krepo-judicial #139、krepo-mops-disclosure #115、krepo-mops-major-news #98、krepo-tej-export #11、krepo #192），各 repo authority 回 `NOT_APPLICABLE`、`audit --ship` OK、`unit-tests` 通過；krepo-mops-disclosure 的 ruleset 要求 1 個核准，依使用者指示以 bypass merge（`--admin`）合併。krepo-mops-financial-statements 因工作樹有未 commit 的他人工作未處理。P2 已合併（PR #316，main `3fb6fd8`..`838f654`；D-20261012-steward-identity-removed，驗證與 review 結果見計畫 P2「實作結果」）。P2b 已在 9 個 repo 的 branch `chore/content-continuity-kernel` 完成本地 commit、未 push：kernel 與 dotfiles 逐字相同、Goal contract 啟用、STATUS 四欄刪除、各 repo 測試與 `audit --ship` 通過（見計畫 P2b「實作結果」）。
- **下一步**：取得使用者對 9 個 repo 的 push／PR／merge 批次授權後送出 P2b（各 repo branch `chore/content-continuity-kernel`）；krepo-mops-financial-statements 待其工作樹淨空後補做；之後做 P3；P3 一併處理 transfer 對在途工作判定不穩的觀察（見計畫 P2「實作結果」）。
- **關聯**：[本項計畫](docs/plans/2026-10-12-content-continuity-redesign.md); GitHub #309; item 3 #285 第 5 步依賴 P2

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。

## 歷史入口

- 決策：`docs/archive/decisions-2026-10.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-10.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- 「3. Deep-review reviewer 分工投影修復（#274）」的結案契約入口：[M-20261007-deep-review-primary-contract](docs/archive/milestones-2026-10.md)；原 spec 保存在 implementation commit `d36d2b7ea5f22d4196d964423844d29074b1eb9e`。
- 「CI 最慢分片量測與保守縮時驗證（#279）」的結案契約與後續正式採用邊界：[M-20261008-ci-critical-path-measurement-complete](docs/archive/milestones-2026-10.md)。
- 「CI controller 靜態重分配本地採用（#279）」的結案契約與驗收：[M-20261008-ci-controller-core-local](docs/archive/milestones-2026-10.md)；hosted 效能仍待具名交付授權後驗證。
- 「brewup 自動更新 bun 全域套件」的本地結案契約與驗收：[M-20261008-brewup-bun-global-update-local](docs/archive/milestones-2026-10.md)；已完成本批本地來源，尚未取得 push／PR／merge／部署授權。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 「移除 turbo skill 與其他 skill 的耦合」的結案與散佈結果：[M-20261011-turbo-retired](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-11-turbo-retirement.md` 已凍結。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
