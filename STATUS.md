<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-11)

---

## 進行中

### 2. Runtime 目錄收斂與 legacy 遷移 🆕

- **Writer**：`claude:delivery-overhead`
- **Workspace**：`branch=fix/delivery-overhead-runtime-layout`
- **Write Scope**：scripts/ensure-runtime-layout.py, scripts/ensure-runtime.sh, scripts/ensure-codex-config.py, scripts/ensure-codex-guidance.sh, claude/settings.json, codex/config.toml, shared/skills/handoff/, claude/skills/handoff/, codex/skills/handoff/, codex/README.md, docs/add-new-host.md, docs/skill-portability.md
- **Dossier Steward**：`claude:delivery-overhead`
- **寫入協調**：2026-10-07 使用者確認原 writer 已停止，將 macOS 打包預設這一批的重疊檔案寫入權與 dossier 維護交由 `codex:macos-archive-metadata`。本項原 runtime 遷移工作不在本批續作；打包預設的本地驗收已完成，見 M-20261007-macos-archive-metadata-local，後續 runtime 寫入仍依原範圍與 reassignment 規則。2026-10-08 使用者將 CI 候選三檔 tests/run.sh、tests/shard-manifest.tsv、docs/testing-contract.md 的本批寫入交由同一 steward，已完成本地採用驗收，見 M-20261008-ci-controller-core-local；Runtime 其餘實作不接續，後續寫入仍須依 reassignment 規則。
- **本批寫入交接**：2026-10-08 使用者確認原 writer／steward 已停止，將 brewup bun 全域更新這一批的 scripts/brewup.sh、tests/run.sh、tests/shard-manifest.tsv、README.md、docs/repo-guide.md、docs/testing-contract.md 與 dossier／history 維護交由 `codex:brewup-bun-global-update`。本批本地修改與完整驗收已完成，見 M-20261008-brewup-bun-global-update-local。原 Runtime 工作不接續；原 writer／workspace 僅保留既有項目的歷史 assignment，後續另依 reassignment 規則。
- **#285 寫入交接**：2026-10-08 使用者確認原 Runtime writer 保持停止，將本批必要 tests/ 與 docs/testing-contract.md 寫入交由 #285 的 `codex:brewup-bun-global-update`。本項 Write Scope 暫移除這兩個共享範圍；原 Runtime writer／workspace 與產品目標保留，原遷移不續作，後續需要這些路徑時另依 assignment 規則協調。
- **Setup 本批協調**：2026-10-09 使用者將 setup 工具分層、shell 環境、npm 措辭與既有主機對齊實作交由現任 steward；原 Runtime writer 仍停止。本項暫收窄 Write Scope，setup／一般部署清單與相關文件由下方 item 4 接續；其餘 Runtime 目標不變，恢復寫入前重新協調。
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

### 3. 小幅變更的驗證與交付成本改善（#285）

- **Writer**：`claude:delivery-overhead`
- **Workspace**：`branch=perf/delivery-overhead-verification`
- **Write Scope**：tests/, shared/skills/project/, shared/skills/deep-review/scripts/review-control.py, shared/skills/deep-plan/scripts/review-state.py, AGENTS.md, docs/testing-contract.md, docs/document-governance.md, .github/workflows/test.yml
- **Dossier Steward**：`claude:delivery-overhead`
- **Context**：2026-10-10 唯讀診斷：小改動交付的最大段是指令到開 PR（#286／#288 約 590 秒），PR 到 merge 約 3–7 分鐘。CI 近 8 次有 7 次退回全套，其中 5 次因 `docs/testing-contract.md` 未路由；414 個 tracked 檔有 201 個未路由，含模組自己的測試檔。macOS 全套的關鍵路徑是平台無關的 deep-plan／review-controller／ship-state／turbo（各 91–116 秒）。紀錄成本：兩週內 STATUS.md 改 111 次，近 40 個 commit 有 15 個只改紀錄，包含獨立補記 PR（#288、#298）。模組化選測的前段成果見 M-20261009-ci-modular-redesign-local。
- **Goal**：降低小幅變更從交付指令到最終回報的完整耗時：CI 只跑受影響且必要的模組與平台，交付流程不再為紀錄本身多產生 commit、PR 或長篇文字。
- **Acceptance Criteria**：
  1. CI 路由：`docs/testing-contract.md` 等說明文件走 content；`tests/<x>.py` 與 `scripts/*` 對應到擁有它的模組；只有 runner／workflow／共用 lib 或無法解析的路徑才跑全套。漏選、未知路徑、新增／刪除／rename 先有 RED controls 再 GREEN；以近 8 次 PR 的實際 diff 重放，列出每次選中的模組，非 runner 類改動不再全套。
  2. 平台矩陣：以行為證據（例如兩平台結果一致、程式沒有平台分支）證明上述 controller 模組平台無關後，只在 Ubuntu 跑；macOS 保留平台敏感模組，required check 名稱不變。普通腳本改動的最慢 job 有 hosted before／after。
  3. 紀錄減量（dotfiles 專屬，D-20261011-record-volume-scope-narrowed）：milestone 每筆不超過 1,500 B，由 repo 測試檢查生效後的新紀錄；docs/testing-contract.md 只寫規則與一句理由，既有事件證據移入 D／M 紀錄（缺的先補）並整份機檢。生效判定方式與 decision 是否納入在計畫定義。不改全機隊共用的 skill 條文。
  4. 端到端：固定一個同規模的小改動（普通腳本加測試），量改善前後「交付指令→最終回報」的總時間與分段（開 PR 前／CI／merge／回報）；local、hosted、真實交付分開報告。
- **Constraints**：本版驗收取代 2026-10-09 版（D-20261010-delivery-overhead-spec）。不靠降低錯誤攔截取得 GREEN；選測錯誤或空集合不得假綠。不改 `scripts/doc-governance.py` 受信任 scanner（fleet byte-identical 契約）；branch protection 與 required checks 調整需另經具名授權。claude/settings.json 的 runtime drift 不帶進 commit（dotsync／brewup 會丟棄）。item 2／4 不在本項範圍。本 Spec 未授權任何 commit、push、PR、merge 或部署。
- **進度**：第 1、2 項已合併（M-20261011-ci-platform-matrix-merged）：全套觸發檔 201→50，controller 三模組只跑 Ubuntu，全套 PR 的 macOS job 3 分 02 秒→2 分 28 秒。測試模組 pipe-to-grep 早退偽紅已清零並合併（M-20261011-pipe-grep-herestring-local）。
- **下一步**：等 item 5 移除 turbo 後，依 D-20261011-record-volume-scope-narrowed 修訂第 3 項計畫並重跑 deep-plan；最後量端到端。
- **關聯**：[本項計畫](docs/plans/2026-10-08-workflow-verification-economy.md); GitHub #285; GitHub #279; PR #288; PR #298; PR #299; D-20261010-delivery-overhead-spec; D-20261010-transfer-delivery-overhead; D-20261009-ci-system-redesign; M-20261009-ci-modular-redesign-local; B-20260924-workflow-verification-economy

### 4. Setup 工具與 agent shell 環境對齊

- **Writer**：`claude:delivery-overhead`
- **Workspace**：`branch=chore/delivery-overhead-setup`
- **Write Scope**：setup-mac-env.sh, setup-linux-env.sh, scripts/dev-tools.sh, scripts/dev-tools.tsv, scripts/dev-env.sh, scripts/align-dev-environment.sh, scripts/ensure-shell-env.py, scripts/dotfiles-sync.sh, scripts/brewup.sh, shell/, tests/, README.md, docs/repo-guide.md, docs/testing-contract.md, claude/CLAUDE.md, codex/AGENTS.md
- **Dossier Steward**：`claude:delivery-overhead`
- **Context**：現有 setup 混合必要與互動便利工具，brew 失敗被吞掉；環境依賴各平台生成的 shell 設定。使用者要求按 Codex／Claude Code 需求改版，統一 npm 措辭，提供 14 台既有主機免重跑 setup 的對齊方式。
- **Goal**：新裝與增量更新共用工具宣告及受管理 shell 環境，必要工具失敗可見，保留個人設定與既有額外工具；使用者追加要求明確區分 setup 納管與主機自行安裝，只有前者依新定義新增／移除，後者不升級、不移除、不接管。
- **Acceptance Criteria**：core／workstation 分層、新增 actionlint／ast-grep；plan／apply／check 可觀察且重跑收斂；必要安裝及驗證失敗回非零；雙 shell 無互動命令可讀相同環境，保留專案／個人 PATH 優先權與覆寫；npm／bun 以專案 lockfile 為準；隔離新裝／升級／失敗／重跑測試與完整 suite 通過；14 台 rollout 有逐台預演、revision、驗收與回復路徑。2026-10-10 使用者接受兩端全域工具指引精簡化：只保留高價值工具與適用任務、可用性與按需安裝原則，不複製完整安裝清單；兩端短段落需機檢一致。
- **Constraints**：本批使用者選擇 `$project --merge` 交付修正、七台僅更新 ca-certificates 並續部署；已依此完成 PR #297 與下列驗收。既有工具未經確認不 adopt／移除／升級，除本批具名憑證更新外保持原版本；settings runtime drift 不帶進 commit（dotsync／brewup 會丟棄），不重跑 setup 覆寫 rc，不放行 direnv trust。使用者完成 macmini Xcode license 處理後，本輪依原部署範圍續作該台；後續外向動作依新批指令，歷史紀錄不是授權來源。
- **進度**：PR #297 已 rebase merge 至 `792f154`（修復 manifest stdin 消耗與未使用的 build dependencies 誤擋）；新 HEAD macOS／Ubuntu CI 3m29s／2m04s 全綠，39 個工具／shell 隔離測試通過。14 台 source 與雙端全域指引均同步此版本，core check 掃足 22 項全過。eagle03／db01／ap01／ap02／m4mini／fe01／be01 已完成 plan、限定憑證更新、apply／check／apply／check、原內容保全及 CLI probes；m4mini／be01 新增 Claude Code 2.1.295。七台 ca-certificates 活躍 opt target 均為 2026-09-25，其餘既有套件版本不變、舊憑證 keg 留存；shell 原內容／mode 與 settings hash 保留。macmini 已完成 fresh inventory、plan、apply／check／apply／check，新增 actionlint 1.7.12／ast-grep 0.50.0；92 個既有 Homebrew 套件（含 ca-certificates 2026-08-13）版本不變，雙 shell CLI probes 通過，第二次完整 snapshot 相同。
- **下一步**：先讀 M-20261010-setup-fleet-complete，將待辦限制在歷史工具歸屬／用途核對；依已有 plan／ledger 的非秘密事實列出需使用者判定的 adopt／keep，沒有當批授權不做 SSH／更新／移除。
- **關聯**：item 2 Runtime 目錄收斂；item 3 #285；[環境使用說明](docs/repo-guide.md)

### 5. 移除 turbo skill 與其他 skill 的耦合

- **Writer**：`claude:delivery-overhead`
- **Workspace**：`branch=refactor/turbo-retirement`
- **Write Scope**：shared/skills/turbo/, claude/skills/turbo/, codex/skills/turbo/, shared/skills/deep-plan/, shared/skills/deep-review/, shared/skills/project/references/ship-policy.md, shared/skills/project/references/spec-workflow.md, claude/settings.json（僅 turbo hooks）, codex/config.toml, claude/CLAUDE.md, codex/AGENTS.md, scripts/agent-turn-end-timestamp.sh, README.md, tests/, docs/plans/
- **Dossier Steward**：`claude:delivery-overhead`
- **寫入協調**：claude/settings.json 與 codex/config.toml 也在 item 2 的 Write Scope；item 2 的遷移目前停止且同一 writer，本項只改 turbo hooks。tests/、shared/skills/project/、review-control.py、review-state.py 也在 item 3 的 Write Scope；item 3 排在本項之後（D-20261011-record-volume-scope-narrowed）。claude/CLAUDE.md、codex/AGENTS.md、README.md、tests/ 也在 item 4 的 Write Scope，item 4 目前只剩工具歸屬核對、不改這些檔。三項依序進行，不平行寫入。
- **Context**：turbo（2026-10-06 加入，D-20261005-turbo-delegated-controller）以 session 為單位自主跑完審查到交付。本機 session 紀錄只有 1 次真實使用（Codex，2026-10-06），Claude Code 為 0；其他主機未量。它滲進 31 個檔：deep-plan／deep-review 的 controller 程式與 references、project 的 ship-policy 與 spec-workflow、Claude／Codex 各 7 個 hooks、兩份全域指令。使用者判斷這些配合讓其他 skill 變複雜，決定移除。
- **Goal**：移除 turbo skill，其他 skill、hooks、全域指令與測試不再依賴或提及 turbo；依散佈步驟執行 ensure-runtime 並重開 session 的主機不再有 turbo hooks 或 skill；未重開或只 pull 的主機的修復方式明列（D-20261011-turbo-direct-deletion）。
- **Acceptance Criteria**：
  1. 三棵樹的 turbo skill 與其專屬測試移除；以 `git grep -il turbo` 檢查 tracked 檔，排除 docs/archive 後只剩 STATUS.md 與 docs/plans/。
  2. deep-plan `review-state.py` 與 deep-review `review-control.py` 移除 turbo checkpoint、`consume_request`、`delegated-reentry`、`refresh-subject`；`native-review` 子命令與 `native-review.py` 移除（D-20261011-turbo-retirement-choices）；primary-scope eval 保留 Codex 與 Claude 兩臂，Codex 收集移入 eval、schema 搬到 tests/fixtures，假 codex transport 測試守住 incomplete report 保留。對應 references 與 project 的 ship-policy、spec-workflow 移除 turbo 分支。非 turbo 路徑的既有測試全數照過；被移除的子命令經 argparse 判為 invalid choice（exit 2）。
  3. claude/settings.json 與 codex/config.toml 移除 turbo hooks；實作在獨立 worktree 進行，commit 不含主 checkout 的 runtime drift，並以乾淨 clone 驗證 settings JSON 合法、7 組 turbo hook 已移除。以臨時 HOME 證明 `ensure-codex-config.py` 會清掉既有主機設定中的 turbo hooks 並保留其他 hooks。`~/.claude/skills/turbo`、`~/.agents/skills/turbo` 殘留連結在獲授權的散佈步驟逐台刪除，只刪指向 dotfiles 的 symlink。
  4. 一批刪除，含 turbo-state.py（D-20261011-turbo-direct-deletion）。散佈經授權：dotsync、逐台刪殘留連結、確認 Codex 設定不含 turbo 腳本路徑、重開各主機 session；agent 只 merge 與刪 remote branch，使用者關閉本機所有 session 後於終端機丟棄 settings drift、pull、跑 ensure-runtime.sh、刪殘留連結再開新 session；兩台 inventory 外 MacBook 恢復時跑 brewup 並重開。
  5. claude/CLAUDE.md 與 codex/AGENTS.md 的 turbo 委任行移除，kernel managed block 不變；README、tests/suites.json 路由與 guidance／session 測試同步。
  6. 全套測試與 `doc-governance audit --ship` 通過。
- **Constraints**：本 Spec 只授權寫 active contract，不授權 commit、push、PR、merge、dotsync 或任何主機操作。歷史紀錄 append-only 不改；docs/plans/2026-10-05-turbo-skill.md 已凍結不改，退役以新紀錄說明。claude/settings.json 的 runtime drift 不帶進 commit；未經權威 repo 修改並 push 的 drift 會在 dotsync／brewup 時丟棄，本機合併前依同樣做法丟棄。實作前先寫計畫並以 deep-plan 審查。
- **進度**：2026-10-11 於 worktree 完成實作（D-20261011-turbo-retired）：三組 RED 轉綠、eval 兩臂與 schema 搬移、臨時 HOME 驗證 Codex 設定清除 7 個 turbo hook 且保留其他 hooks 與專案信任、刪除實驗確認 eval／schema 只由 review-skill 讀取。title-free recall ratchet 一度 6→5（本批決策紀錄把 canonical evals 擠出前 5 名、只剩 symlink 別名），改為以實體路徑判命中後回到 6/10（D-20261011-recall-alias-canonical）。
- **審查**：deep-review full（3 位 fresh reviewer）PASS，0 阻斷；4 條 low 依使用者指示全修，各有先紅後綠測試與突變驗證：升級前以 native transport 派出的 ticket 在 `finish` 拒收、eval 移除無讀取者的 reviewer 標記並改斷言 `-a never`／`-s read-only`、eval 中斷時停止 reviewer process group 並關閉 attempt、evals.md 措辭。
- **下一步**：依授權送出（本 branch 含 dossier 兩顆，一個 PR 即可），合併後依計畫「散佈」節切換本機與機隊。
- **關聯**：D-20261005-turbo-delegated-controller；D-20261010-ci-controller-platform-evidence；item 2；item 3

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。
- **B-20260824-remote-human-contributor-path**：pending；現行 feature branch／PR 可作為 Git 傳遞媒介，
  Project authority gate 也能在 steward 評估 candidate commit 時列出 shared-surface 越界；但既有 worker
  契約仍不允許自行 push，PR CI 亦不依 contributor 身分判斷 stewardship。可取得的 dotfiles 與三個已 rollout
  repo 的 PR／commit 紀錄沒有 remote-human contributor 實例，未觀察到傳遞阻塞或 authority drift，故不新增
  程序、eval 或 provider gate。**恢復條件**：第一位具名、跨主機真人 contributor 需要交付 commit，或首次出現
  非 steward PR；保留其 exact SHA、declared scope 與 Dossier delta，實測 steward fetch／shared-surface 檢查／
  cherry-pick。任一步受阻，或越權 shared dossier mutation 未被攔下，才以該事件取得 RED 並做最小修正。

## 歷史入口

- 決策：`docs/archive/decisions-2026-10.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-10.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- 「3. Deep-review reviewer 分工投影修復（#274）」的結案契約入口：[M-20261007-deep-review-primary-contract](docs/archive/milestones-2026-10.md)；原 spec 保存在 implementation commit `d36d2b7ea5f22d4196d964423844d29074b1eb9e`。
- 「CI 最慢分片量測與保守縮時驗證（#279）」的結案契約與後續正式採用邊界：[M-20261008-ci-critical-path-measurement-complete](docs/archive/milestones-2026-10.md)。
- 「CI controller 靜態重分配本地採用（#279）」的結案契約與驗收：[M-20261008-ci-controller-core-local](docs/archive/milestones-2026-10.md)；hosted 效能仍待具名交付授權後驗證。
- 「brewup 自動更新 bun 全域套件」的本地結案契約與驗收：[M-20261008-brewup-bun-global-update-local](docs/archive/milestones-2026-10.md)；已完成本批本地來源，尚未取得 push／PR／merge／部署授權。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
