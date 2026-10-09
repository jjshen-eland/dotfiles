<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-10)

---

## 進行中

### 2. Runtime 目錄收斂與 legacy 遷移 🆕

- **Writer**：`codex:runtime-deployment-output`
- **Workspace**：`branch=fix/runtime-deployment-output`
- **Write Scope**：scripts/ensure-runtime-layout.py, scripts/ensure-runtime.sh, scripts/ensure-codex-config.py, scripts/ensure-codex-guidance.sh, claude/settings.json, codex/config.toml, shared/skills/handoff/, claude/skills/handoff/, codex/skills/handoff/, codex/README.md, docs/add-new-host.md, docs/skill-portability.md
- **Dossier Steward**：`codex:brewup-bun-global-update`
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
- **下一步**：輸出摘要來源依本批 `$project --merge` 交付；fleet 同步須另取得當批部署授權，且來源已進 origin/main 才散佈。現行 inventory 的 layout 遷移驗收已完成，本輪 fresh 檢查亦排除這 14 台對預設 legacy store 的依賴；Claude Default 表示修正已由 9d31d8b 進 origin/main，fleet 模型設定同步仍待當批部署授權與逐端核對。inventory 外兩部 MacBook 依 D-20260917-terminal-macbooks-outside-inventory 維持自主更新，已提供各自執行的離線 rollout 指令；本輪一部回報 layout／重跑通過，但識別／revision／原生載入仍缺，不視為全體追加驗收。先釐清額外終端是否仍依賴舊 store，再依原 plan 處理 legacy fallback cleanup 與定向行為驗證。原生 .trash 依 runtime retention 管理，不當作永久備份；本機 handoff 原備份仍保留。本項仍 in-progress。
- **關聯**：#271; D-20260823-portable-handoff-skill; D-20260912-neutral-portable-skill-core; D-20260912-codex-config-three-layer-merge; M-20260912-codex-config-and-dotsync-exit; M-20261001-handoff-frontmatter-anchor-verify; D-20261007-claude-model-default-unset; M-20261007-claude-native-default-verified; M-20261007-macs-runtime-layout-accepted

### 3. 小幅變更的驗證與交付成本改善（#285）

- **Writer**：`codex:brewup-bun-global-update`
- **Workspace**：`branch=perf/delivery-cause-diagnosis`
- **Write Scope**：tests/, shared/skills/project/, shared/skills/deep-review/scripts/review-control.py, shared/skills/deep-plan/scripts/review-state.py, AGENTS.md, docs/testing-contract.md, .github/workflows/test.yml
- **Dossier Steward**：`codex:brewup-bun-global-update`
- **Context**：#285 第一批由 PR #289 完整退版；#279 紀錄 CI 選測再由 PR #290 合併為 `1f0d967`，雙 OS required checks 通過。使用者懷疑 10 月初 skill 改動造成交付耗時跳升，授權以固定歷史版本分開量 Project 收尾與 CI。PR #288 的 1244.449 秒事故仍是完整交付未驗收的證據，不以本地局部收益結案。
- **Goal**：以整體重構或重寫重新設計 repo 的本地驗證與 CI，讓測試成本對應實際變更風險，降低交付指令到最終回報的完整耗時；既有測試、分片、觸發規則與驗證流程都可重設，不以保留既有數量或架構為前提。
- **Acceptance Criteria**：
  1. 依實際失敗風險盤點測試群組，對保留／合併／分層／改寫／移除給出理由與新承接位置；不把歷史存在當必要性的證明。
  2. 模組有獨立入口，本地與 CI 使用一致的測試宣告；靜態內容、單元行為、真實整合與原生模型 eval 分層，消除重複 fixture 與無必要的跨模組全套成本。
  3. 按整批差異與實際相依選測，平台矩陣及 full regression 觸發重新設計。未知範圍、工具失敗、漏跑／假成功、取消清理及必要 OS 反例有行為驗證；不靠降低錯誤攔截取得 GREEN。
  4. 純紀錄、普通腳本、共用依賴及 CI 自身修改均有代表案例；固定來源／環境比較完整耗時，選測與證據成本納入。local、hosted、真實交付分開報告，未量到指令至最終回報不宣稱整體完成。
  5. 舊 runner／重複規則隨新架構退出；testing contract 與 agent 驗證指引一致，不永久疊新包裝。產品 helper 的必要改動另核對 scope／ownership，skill authoring 依既有規則。
- **Constraints**：2026-10-09 使用者要求本項以重構或重寫處理，解除前輪僅診斷、單一有界候選、保留所有既有測試／分片的限制。沿用同一 writer／steward 與 worktree；原 Runtime 項目不接續，claude/settings.json runtime drift 保留。PR #292 已依後續 merge 指令完成。使用者續以「繼續」授權 deep-plan 耗時診斷、本地實作與驗證；使用者隨後以 `$project --pr` 授權本批提交、push feature branch 與開 PR；終點不含 merge／部署。
- **進度**：模組化與選測重構已完成本地驗收：29 個獨立模組、本地／CI 共用 catalog 與 executor，舊歷史分片及固定計數聚合退役。凍結來源全套 exit 0、127.666 秒；相同 brewup 小修改的兩輪 CI 入口對照平均 119.680 → 14.713 秒（87.71%），純紀錄 13.406 秒。選測／失敗／取消 controls 通過，詳細來源與限制見 M-20261009-ci-modular-redesign-local。後續 controller 分層與重複驗證去重已完成本地全套，見下一步及 M-20261009-ci-controller-test-layers-local；本機收益不代表雙 OS 或完整交付已驗收。
- **下一步**：PR #292 已合併至 17efb21，macOS／Ubuntu 全套 167.092／85.024 秒，兩邊通過。本批 deep-plan 單次文件 snapshot 改批次 metadata／blob 讀取，保留原三層資料與跨操作漂移拒絕；同 clone 全套 120.051→111.604 秒（7.0%），deep-plan 74.459→58.304 秒（21.7%），29 模組通過，雙端獨立 CLI 行為驗證通過。本批依 `$project --pr` 交付候選，hosted 結果待 PR CI；完整交付與其他模組成本仍 active。詳見 M-20261009-deep-plan-batched-snapshot-local。
- **關聯**：[本項診斷與驗證計畫](docs/plans/2026-10-08-workflow-verification-economy.md); GitHub #285（https://github.com/jjshen-eland/dotfiles/issues/285）; GitHub #279（https://github.com/jjshen-eland/dotfiles/issues/279）; PR #288; PR #289; D-20261009-small-change-delivery-spec; D-20261008-ci-critical-path-before-selection; D-20261008-ci-core-controller-recommendation; X-20261009-workflow-verification-economy-revert; B-20260924-workflow-verification-economy

### 4. Setup 工具與 agent shell 環境對齊

- **Writer**：`codex:brewup-bun-global-update`
- **Workspace**：`branch=docs/setup-canary-results`
- **Write Scope**：setup-mac-env.sh, setup-linux-env.sh, scripts/dev-tools.sh, scripts/dev-tools.tsv, scripts/dev-env.sh, scripts/align-dev-environment.sh, scripts/ensure-shell-env.py, scripts/dotfiles-sync.sh, scripts/brewup.sh, shell/, tests/, README.md, docs/repo-guide.md, docs/testing-contract.md, claude/CLAUDE.md, codex/AGENTS.md
- **Dossier Steward**：`codex:brewup-bun-global-update`
- **Context**：現有 setup 混合必要與互動便利工具，brew 失敗被吞掉；環境依賴各平台生成的 shell 設定。使用者要求按 Codex／Claude Code 需求改版，統一 npm 措辭，提供 14 台既有主機免重跑 setup 的對齊方式。
- **Goal**：新裝與增量更新共用工具宣告及受管理 shell 環境，必要工具失敗可見，保留個人設定與既有額外工具；使用者追加要求明確區分 setup 納管與主機自行安裝，只有前者依新定義新增／移除，後者不升級、不移除、不接管。
- **Acceptance Criteria**：core／workstation 分層、新增 actionlint／ast-grep；plan／apply／check 可觀察且重跑收斂；必要安裝及驗證失敗回非零；雙 shell 無互動命令可讀相同環境，保留專案／個人 PATH 優先權與覆寫；npm／bun 以專案 lockfile 為準；隔離新裝／升級／失敗／重跑測試與完整 suite 通過；14 台 rollout 有逐台預演、revision、驗收與回復路徑。2026-10-10 使用者接受兩端全域工具指引精簡化：只保留高價值工具與適用任務、可用性與按需安裝原則，不複製完整安裝清單；兩端短段落需機檢一致。
- **Constraints**：本批來源已由 PR #294 rebase merge 至 origin/main `4f9d8c2`。2026-10-10 使用者在雙平台試跑建議後以「繼續」授權本批 macOS／Linux canary 對齊；選本機 macs 與 agent01。既有工具歸屬未確認前不 adopt／移除／升級，只補 core 缺項與接上 shell 環境；其餘 12 台保持盤點範圍。主目錄 settings.json runtime drift 保留。#285 與原 Runtime writer 無並行寫入；不安裝全機隊 mise／語言套件／瀏覽器，不自動卸載未納管／本機保留工具或放行 direnv trust，不執行新 setup 覆寫既有主機 rc。
- **進度**：共用清單、ownership ledger、plan／apply／check 與 shell helper 已實作；原 setup 吞失敗已重現並修正。29 項隔離行為測試與 30 模組完整 suite 通過（114.485 秒）；macOS 系統 Python 3.9 的 tomllib 缺項已重現，共用 PATH 改用本機 Homebrew Python 3.14.8。PR #294 已合併；agent01 canary 已新增 actionlint 1.7.12／ast-grep 0.45.3，兩次 apply／check 全部 exit 0，85 個既有 Homebrew 套件版本與個人 bashrc 原內容不變。
- **下一步**：PR #295 已 rebase merge 至 `bbf4f98`，必要 macOS／Ubuntu CI 3m11s／1m43s 全綠。macs 已新增 ast-grep 0.45.3，原 183 個 Homebrew 套件版本、shell 內容及 settings runtime drift 保留；apply／check 重跑通過。雙平台 canary 安裝與 shell 驗收完成，Codex／Claude Code 版本命令可用，未跑模型回合或代表專案測試。其餘 12 台僅 inventory，仍在 `112d37d`；下批部署與舊工具納管／退役須核對用途後進行。本輪 macs 事後驗收紀錄與兩端全域 CLI preferences 精簡指引留本地 docs 分支，尚未送出；工具提示採同一 46 個英文單字短段，由 content gate 檢查一致性。見 M-20261010-macs-setup-canary、M-20261010-agent01-setup-canary。
- **關聯**：item 2 Runtime 目錄收斂；item 3 #285；[環境使用說明](docs/repo-guide.md)

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
