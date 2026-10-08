<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-09)

---

## 進行中

### 2. Runtime 目錄收斂與 legacy 遷移 🆕

- **Writer**：`codex:runtime-deployment-output`
- **Workspace**：`branch=fix/runtime-deployment-output`
- **Write Scope**：scripts/, setup-mac-env.sh, setup-linux-env.sh, claude/settings.json, codex/config.toml, shared/skills/handoff/, claude/skills/handoff/, codex/skills/handoff/, README.md, codex/README.md, docs/repo-guide.md, docs/add-new-host.md, docs/skill-portability.md
- **Dossier Steward**：`codex:brewup-bun-global-update`
- **寫入協調**：2026-10-07 使用者確認原 writer 已停止，將 macOS 打包預設這一批的重疊檔案寫入權與 dossier 維護交由 `codex:macos-archive-metadata`。本項原 runtime 遷移工作不在本批續作；打包預設的本地驗收已完成，見 M-20261007-macos-archive-metadata-local，後續 runtime 寫入仍依原範圍與 reassignment 規則。2026-10-08 使用者將 CI 候選三檔 tests/run.sh、tests/shard-manifest.tsv、docs/testing-contract.md 的本批寫入交由同一 steward，已完成本地採用驗收，見 M-20261008-ci-controller-core-local；Runtime 其餘實作不接續，後續寫入仍須依 reassignment 規則。
- **本批寫入交接**：2026-10-08 使用者確認原 writer／steward 已停止，將 brewup bun 全域更新這一批的 scripts/brewup.sh、tests/run.sh、tests/shard-manifest.tsv、README.md、docs/repo-guide.md、docs/testing-contract.md 與 dossier／history 維護交由 `codex:brewup-bun-global-update`。本批本地修改與完整驗收已完成，見 M-20261008-brewup-bun-global-update-local。原 Runtime 工作不接續；原 writer／workspace 僅保留既有項目的歷史 assignment，後續另依 reassignment 規則。
- **#285 寫入交接**：2026-10-08 使用者確認原 Runtime writer 保持停止，將本批必要 tests/ 與 docs/testing-contract.md 寫入交由 #285 的 `codex:brewup-bun-global-update`。本項 Write Scope 暫移除這兩個共享範圍；原 Runtime writer／workspace 與產品目標保留，原遷移不續作，後續需要這些路徑時另依 assignment 規則協調。
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
- **Workspace**：`branch=perf/workflow-verification-economy`
- **Write Scope**：tests/, shared/skills/project/, AGENTS.md, docs/testing-contract.md
- **Dossier Steward**：`codex:brewup-bun-global-update`
- **Context**：#285 原以縮短一般小改動的驗證與交付時間為目標。PR #287 的局部機制通過驗證，但普通腳本 native 案例 Codex 86.313 → 190.082 秒、Opus 34.961 → 67.141 秒；整段交付收益未證明。2026-10-09 使用者明示完整退版，不為保留局部收益再拆分修改。
- **Goal**：完整撤回 #285 的流程與測試實作，還原至 `92dc1b9c6e6a836146606d3cee12edd2505ecef6` 的對應內容；保留 bun 全域更新、#279、原始量測及退版原因。
- **Acceptance Criteria**：
  1. PR #287 的十二個非紀錄路徑與固定基線一致，新增的三個測試檔消失；不保留 compact、新測試入口或新增快照要求。
  2. 原本 brewup bun 全域更新與 #279 改動不受影響；既有完整測試、分片聚合與必要治理／xref 驗證通過。
  3. 保留原有 history 與量測，追加退版原因；不宣稱原效能目標已達成，亦不從過去已完成的 merge／dotsync 授權推導本批送出或部署授權。
- **Constraints**：使用者本輪「退版吧，有做比沒做還糟」授權完整本地退版。既有 Runtime writer 保持停止，原工作不接續；不修改 CI、branch protection 或採用新流程。新批 push／PR／merge 與 dotsync 仍依具名授權處理。
- **進度**：整批本地退版候選已完成驗收：十二個路徑的內容與 mode 和固定基線一致，新增三個測試檔已移除；serial／parallel 各 1577 PASS／0 FAIL、exit 0，測試期間來源未變。治理／xref 與 Codex validator 通過；尚未 push／PR／merge／部署。見 M-20261009-workflow-verification-economy-revert-local。
- **下一步**：取得本批新的具名送出／合併授權後交付退版；dotsync 仍須另行授權。保留 active assignment，不自行重啟原優化或 #279。
- **關聯**：[本項診斷與驗證計畫](docs/plans/2026-10-08-workflow-verification-economy.md); GitHub #285（https://github.com/jjshen-eland/dotfiles/issues/285）; PR #287; PR #288; X-20261009-workflow-verification-economy-revert; B-20260924-workflow-verification-economy

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
