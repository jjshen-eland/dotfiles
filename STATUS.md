<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-07)

---

## 進行中

### 2. Runtime 目錄收斂與 legacy 遷移 🆕

- **Writer**：`codex:runtime-layout-convergence`
- **Workspace**：`branch=refactor/runtime-layout-convergence`
- **Write Scope**：scripts/, setup-mac-env.sh, setup-linux-env.sh, claude/settings.json, codex/config.toml, shared/skills/handoff/, claude/skills/handoff/, codex/skills/handoff/, tests/, README.md, codex/README.md, docs/repo-guide.md, docs/add-new-host.md, docs/skill-portability.md, docs/testing-contract.md
- **Dossier Steward**：`codex:runtime-layout-convergence`
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
- **Constraints**：使用者已以「開工」授權本項本地實作與驗證；前輪 `$project --merge` 將既有規劃文件與 active assignment 隨 #271 修復提交保存，不代表本項 implementation 或 fleet migration 已完成。本項後續實作的 shipping／部署仍依當批具名授權與 repo 規則。CLI 安裝／更新、套件升級、SSH／inventory 改版及其他 skill 的獨立 legacy 契約不納入本項。保留 config.local.toml 與合法 HANDOFF_DIR override、雙薄入口／單一 neutral core、handoff claims／frontmatter gate；不關閉安全檢查或代為信任 hooks。修改 skill 前依 AGENTS.md 的 authoring route；移除舊 store resolver 前須以安全 migration／locking 的行為證據滿足既有重議條件。
- **進度**：來源修正已由 PR #276 rebase merge 至 origin/main `b6299f5`，required macOS／Ubuntu CI 通過；14 台已核對當時的 Claude literal default／cloud false／settings symlink 與 Codex repo 不固定 model。十三台遠端先通過；2026-10-07 macs 從普通 terminal 停止 native daemon 與核身 updater 後，common entry／verify／rerun／verify-rerun 均通過，layout 正式結構驗收達 14／14（缺 CLI 的既有能力邊界沿 plan 表）。18 個 handoff 檔移至正式 store，checksum／mode／mtime 完整、原備份含 inode 保留、無 stage 殘留；雙端原生 metadata-only discovery 各載入 11 repo adapters。Claude 依已部署 user settings 的 opt-out 在啟動時把 215 個雲端 skill 檔移到原生 .trash、保留內容／mode／mtime／inode，移除 3 個同步索引檔；runtime 與 repo 的 synced／syncd 四路徑均 absent。受管理 entries／handoff／receipts／backups／source 在 native startup 保留，僅原生 cache 與 .claude.json 有預期變化。另已重現 literal default 產生額外 Custom model，依使用者選擇備份 UI 回寫後只收省略 model；來源原生選單驗證只有一個推薦 Default，其他設定與 local 模型覆寫保留。證據見 M-20261007-macs-runtime-layout-accepted／M-20261007-claude-native-default-verified；省略 model 的修正尚未交付 fleet，不宣稱 model turn、背景週期或全專案完成。
- **下一步**：現行 inventory 的 layout 遷移驗收已完成；Claude Default 表示修正進入 origin/main 後，須依當批部署授權同步並核對各端來源設定，本次 merge 不代表 fleet 模型設定已同步。inventory 外兩部 MacBook 依 D-20260917-terminal-macbooks-outside-inventory 維持自主更新，已提供各自執行的離線 rollout 指令，尚無 runtime 驗收結果；先釐清這兩部終端是否仍依賴舊 store，再依原 plan 處理 legacy fallback cleanup 與定向行為驗證。原生 .trash 依 runtime retention 管理，不當作永久備份；本機 handoff 原備份仍保留。本項仍 in-progress。
- **關聯**：#271; D-20260823-portable-handoff-skill; D-20260912-neutral-portable-skill-core; D-20260912-codex-config-three-layer-merge; M-20260912-codex-config-and-dotsync-exit; M-20261001-handoff-frontmatter-anchor-verify; D-20261007-claude-model-default-unset; M-20261007-claude-native-default-verified; M-20261007-macs-runtime-layout-accepted

### 3. Deep-review reviewer 分工投影修復（#274）

- **Writer**：`codex:runtime-layout-convergence`
- **Workspace**：`branch=fix/deep-review-primary-responsibility`
- **Write Scope**：shared/skills/deep-review/, claude/skills/deep-review/, codex/skills/repo-review/, tests/
- **Dossier Steward**：`codex:runtime-layout-convergence`
- **Context**：[Issue #274](https://github.com/jjshen-eland/dotfiles/issues/274) 記錄 full route 的分工與 packet 投影不一致：三份 primary concerns 已分配互斥的 12／14／13 個 paths，但生成的 packets 都含相同 39 個 subject_files、paths 為空；native prompt 又要求審查 exact subjects，兩份原始 reports 因其他 assignment 的檔案未完成而回 incomplete。修復前 controller 的 assignment 僅有 id／repos／concern，coverage 只核對 repo 聯集，packet 依 repo 複製 aggregate scope。Readonly scratch／Docker socket denial 是另有觀察的 execution-evidence 邊界，不能把 scope 投影認定為所有 incomplete 的唯一原因。
- **Goal**：讓 full-route reviewer responsibility 從分工資料模型、controller admission、packet、native prompt 到 result／aggregate admission 一致且可驗證。每位 reviewer 完成自己的 bounded primary responsibility 與必要 semantic dependents 後，完整當前 reviewer set 可形成有效 global result；保留 aggregate immutable subject、真正的必要證據缺口與獨立審查可信度。
- **Acceptance Criteria**：
  1. 修復前先建立能重現 #274 投影缺口的 regression fixture：原始 39-file subject 與 12／14／13 分工生成相同 broad packets 的現象須取得 RED，保留原始 packets／digests 與 failed attempts。重現資料可從 issue 與原始證據整理，不依賴重新派 reviewer 或消耗原 NC batch 的新輪次。
  2. 分工以機器可驗證的結構表示各 reviewer 的 primary repos／paths 或等效 bounded responsibility，不再只靠 concern 自由文字。Aggregate repo／base／head／guidance／working-tree subject／fingerprint 保持完整且 immutable；controller 在 dispatch 前驗證 primary scopes 的完整聯集、互斥性與合法邊界。漏 primary path、未知 repo 或越界 responsibility 必須阻擋；必要相依與 cross-repo interface pass 可以查閱其他分工的相關內容，不把它們重算為重複 primary ownership。
  3. Packet、canonical reviewer brief、native prompt 及結果的 coverage 語意一致：complete 指已完成本 assignment 的 primary responsibility 與必要 semantic dependents。未查遍其他 assignments 不自動造成 incomplete；自身必要 facts、受影響 interface 或必要 execution evidence 缺失時仍為 incomplete，不以縮窄 aggregate subject 或省略 required facts 取得 complete。
  4. Aggregate admission 仍要求完整當前 assignment set、所有 confirmed repos／primary subjects 的 coverage、fresh native reviewer identities，以及未變的 subjects／inputs／packets／原始報告。作者拼接、partial／duplicate sets、fake／reused reviewer、任一 incomplete child、subject 或 input drift 均阻擋；attempt consumption、history、原始失敗報告與證據不得重設、刪除或強制改標 complete。
  5. 明確區分 readonly runtime 可執行的 diagnostics、static evidence 與原始 execution artifacts，保留實際 command／status、inputs 與環境限制。Readonly scratch 或 Docker denial 不可一律忽略；若 static evidence 足以查明本 assignment 的 required facts，須能據此完成，若必要 execution fact 仍不可取得則維持 incomplete。Author tests 不冒充 independent execution／PASS；不得以 desired-verdict prompt 或放寬 readonly／identity gate 換取結果。
  6. Behavior eval 至少涵蓋單 repo 的 2-way／3-way path partitions、跨 repo interface responsibilities，以及每位只完成 assigned primary＋必要 dependents 的正向 global set；反向覆蓋漏 primary path、缺少自身 required fact、subject／input drift、fake／reused reviewer 與 incomplete child。正向證據須走完 admit → dispatch → 真實 native review → result／aggregate admission，保留 raw reports、native identities 與 failed attempts；controller fixtures 或 mock results 不能替代真實 native workflow。
  7. Claude Code／Codex 薄入口維持單一 neutral core 與相同 responsibility／evidence 契約；驗證實際支援的 native transport 與 readonly 限制，環境不可用或 coverage 未完成時明列缺項，不宣稱雙端或 global PASS。定向 regression／behavior eval、必要的 skill validation、`./tests/run.sh`、doc-governance 與交叉引用檢查通過；本項不改 ordinary route 的既有完整 subject 責任或 reviewer 輪次／修復預算。
- **Constraints**：使用者於 spec 建立後明示「開工」，授權本項本地規劃、實作與驗證，並在同 session 接續已識別的 `codex:runtime-layout-convergence` 工作線；本輪另明示 `$project --merge`，授權本批 feature commits／push／同 PR 的 required checks 與 rebase merge，依 project 的 bounded repair 規則接續；部署未授權。原 runtime-layout 項的 assignment／進度保持；本項 workspace 獨立於舊工作，不啟動重疊 scope 的並行 writer。未來修改任何 skill 前依 AGENTS.md 的 authoring route，以 observed failure／safety contract 與 behavior eval 為依據。NC integration repo、原 controller batch／nonce／journal 與任何外部系統不在 write scope；原始同機證據不提供 action authority。
- **進度**：2026-10-07 保存 projection／incomplete report RED 後，完成 structured primary admission、完整 aggregate context／bounded primary packet、brief／native prompt 與原始 failed-set evidence 修復。11 個新 regression、23 個既有 controller regression、48 個 turbo checks 通過。雙端原生矩陣共 12 cases／32 fresh identities：8 positive PASS、3 own-required-fact BLOCKED、1 Python mutation RED 原狀保留。Blind f0–f3 的初始 Git metadata RED 已促成首次獨立載入 references 的修復；fresh f4 的兩位 reviewers 與 aggregate PASS，parent pre-first-call 全 entries content／mode／size／mtime snapshots 一致。原始 reports／trace／journal 保留；authority 為 active-writer-workspace-match／PASS，原 NC live batch 未改動。 最後完整 suite exit 0、1575 PASS／0 FAIL（426s），雙入口 validator、治理／xref 通過；本地 implementation plan 已凍結為 implemented，交付 pending。
- **下一步**：本地實作與 7 項 AC 驗收證據見 [implementation plan](docs/plans/2026-10-07-deep-review-primary-responsibility.md)、canonical P23 eval 與 M-20261007-deep-review-primary-local。本輪 `$project --merge` 正在驗證 shipping test evidence，先以 implementation commit 保存 active assignment，再形成結案文件 candidate；所有 required gates 通過後走 PR／rebase merge。Runtime 目錄收斂項保持，原 NC batch 與部署不在本批。
- **關聯**：#274; D-20261007-deep-review-primary-responsibility; X-20261007-review-python-isolated-bytecode; X-20261007-review-git-status-index-mtime; D-20260823-portable-deep-review; M-20260823-portable-deep-review; M-20261007-deep-review-primary-local

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
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
