<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-06)

---

## 進行中

### 1. #271 deep-plan 合法文件續審與輸入隔離 🆕

- **Writer**：`codex:runtime-layout-convergence`
- **Workspace**：`branch=fix/deep-plan-repair-evidence`
- **Write Scope**：shared/skills/deep-plan/, claude/skills/deep-plan/, codex/skills/deep-plan/, tests/, docs/testing-contract.md
- **Dossier Steward**：`codex:runtime-layout-convergence`
- **Context**：[#271](https://github.com/jjshen-eland/dotfiles/issues/271) 與其補充已指出：合法 plan／SPEC／STATUS 修正通過 #264 的文件基線核對後，完整文件 delta 進入 `render_packet`，其中歷史「第二輪」被 `no_pressure` 當成 reviewer 控制壓力而拒絕。本 session 的 runtime 收斂在使用者選擇新批盲審後，同樣因 STATUS 差異中的「第一輪／第二輪」失敗；原 journal 保留，新批零 reserved tickets、零 reviewers。兩條工作線支持相同直接根因，但完整 repair 生命週期是否另有缺口仍待查證。
- **Goal**：使 deep-plan 的合法作者修正、文件／Git 證據與 reviewer 輸入隔離形成一致且可驗證的續審流程；保留 canonical 歷史與 provenance，使合法 focused repair 和 blind restart 能沿原 journal 完成派遣／admission，同時維持真正控制壓力及非法漂移的拒絕行為。
- **Acceptance Criteria**：
  1. 先以隔離 Git fixture 執行現行 controller，重現含真實審查歷史的 STATUS delta 被 `review-pressure-in-input` 拒絕；涵蓋 #271 的 focused repair 與本 session 的 blind restart。RED 是現行行為的 assertion failure，不是缺少新 API 的 import error；保留原輸入、journal 與結果。文件 delta 省略的診斷 control 只定位原因，不用來取得 ticket。
  2. 釐清並驗證 orchestrator 控制輸入與 canonical 文件資料的投影邊界：必要 worktree／index／HEAD 差異完整、來源與 hash 可核對，不要求刪改歷史、不省去相依文件；不能把任意輸入包進文件欄位就免除 guard。prepare、launcher、finish／admission 對同一合法 snapshot 使用一致契約。
  3. 矩陣涵蓋同批剩餘額度內 repair、明示授權的新批 focused repair，以及明示新批 blind review；合法 plan／SPEC／STATUS 修正分別處於 unstaged、staged、單親 committed checkpoint，均保留原非文件 dirty baseline、findings／dispositions、IDs、policy／count／上限及完整 journal 歷史。blind 投影不額外加入原 reviewer results 或 controller 狀態；來源文件／Git 歷史仍可含歷史 findings 或進度文字，依第 6 項揭露 exposure／validity 限制，資料不成為指令或授權。
  4. 以原生全新 reviewers 驗證完整流程：有效 review → blocking finding → 合法作者修正與歷史記錄 → 文件 checkpoint → 有效 ticket → 全部 fresh reviewers → typed complete set → 有效 admission → 依 findings 判定 gate。Synthetic fixtures 只證明狀態／拒絕矩陣，不能取代 native lifecycle；結果有效不強求 GO，新 blocking finding 正常判 NO-GO。兩個 runtime 的實際接線及受測模型／限制各自留證，不用單一端成功外推另一端。
  5. 每個正向路徑配反向 controls：未宣告文件、程式／其他 repo 漂移、非法 ancestry／程式修改後 revert、執行期間文件／index／HEAD／artifact 變動、journal／ticket／packet tampering、重用 reviewer IDs／不完整結果、未處置 finding、額度耗盡及缺 restart 授權，均維持 fail closed；#264 的文件基線與 checkpoint 回歸、既有 v1 可證明／不可證明基線處理保持。
  6. 真正由 orchestrator 注入的輪次、剩餘額度或預定 verdict 指令仍被拒絕；不整體停用壓力防護、不以刪詞或換模式代替修復。Reviewer 若從 canonical 文件／Git history 讀到歷史結論，明列實際 exposure／validity 限制；packet admission 成功不宣稱完全盲審，文件資料也不授予執行指令或行為授權。
  7. Claude／Codex 薄入口沿用同一 neutral core；既有 deterministic tests、必要 fresh behavior eval、雙端 validator 與完整 `./tests/run.sh`／`./tests/run-parallel.sh` 通過。新增 assertion 同步 `tests/shard-manifest.tsv`，不放寬 aggregator；文件／xref audit 與 diff check 通過，記錄實際輸入 fingerprint、exit 與未驗證項。
  8. 修復證據同時涵蓋原 #271 RED 轉綠、#264 回歸、完整 native lifecycle 與反向 controls；若 prepare、launcher 或 admission 仍有相關失敗，明列未完成。原 NC／runtime 收斂 journal 不重設、不改 findings、不捏造授權；真實工作線接續前重新核對 ownership、授權與最新基線。
- **Constraints**：Spec invocation arguments 為 `spec #271`；其後使用者「開工」授權本項本地實作與驗證；本輪 `$project --merge` 授權本批 commit／push／PR／rebase merge，未授權部署。由現有 writer／steward 依序處理 #271，runtime 收斂的 implementation 等待本項修復；本項使用獨立 feature branch，保留已核對的既有文件修改。只修改與本項因果鏈、接線及驗收直接相依的 scope；不 fork 整套 skill、不改預設 reviewer 數／mode／額度、不重開 #264 或移除其保護。修改 skill 前完整走 AGENTS.md authoring route；native eval 不向受測者洩漏 oracle。任何擴大核心判準或 scope 的新需求先回規格決策，外向動作另依當批具名授權。
- **進度**：2026-10-06 使用者選項 `1` 的 bootstrap 已完成：41 routing tests、repair-context、雙入口 validator 及 serial／parallel 各 1570 PASS／0 FAIL。獨立 code review 的 bytecode source drift 有 assertion RED／GREEN 修復，consumer suite 缺漏已補；這是作者修正驗證，沒有第二份獨立 code-review PASS。改版 source 的兩端 native lifecycle、focused repair 與授權新批 blind 共 14 有效 sets／28 不同 IDs，來源 identity 不變；canonical GO／降級指令案例四位均保留可查證 blocker。Claude focused 曾正常判新 NO-GO，合法作者修正後新批無 blocking；原 invalid typed output 與歷史未改。固定反例不外推通用抗注入；canonical history exposure、一位 Claude control 的局部 baseline metadata exposure、directive 文件 checkpoint 的額外澄清均留證。Bootstrap suite 的 source snapshot 在執行中取得，至完成未改動；證據入口見 M-20261006-deep-plan-bootstrap-verified。原 #271 journal 保留前批 NO-GO，使用者明示新批 focused 續審已取得 GO，剩餘契約同步及最終驗收已完成，詳見下一步。
- **下一步**：本地驗收已完成，原 journal 的 focused 新批兩輪／四位 fresh reviewers 無 findings、gate GO；前批 NO-GO／IDs／原始分類仍保留。Workflow／現行 eval oracle 已同步；最終 serial／parallel 各 exit 0、1570 PASS／0 FAIL，373 輸入的啟動前／完成後 snapshot 相同，雙入口 validator 與文件／xref 檢查通過。Native 證據仍綁 bootstrap source，最終純措辭同步未改 code／reviewer prompt hashes，不外推通用抗注入或 NC 已恢復。計畫標記 implemented，詳見 M-20261006-deep-plan-repair-local-completion；本輪已取得 `$project --merge` 授權；先提交實作與 active assignment，再以結案 candidate 保留 parent authority，通過 gates 後送出。本項未部署。
- **關聯**：#271; #264; #268; D-20261003-deep-plan-controller-adoption; D-20261005-deep-plan-document-repair-baseline; D-20261006-deep-plan-evidence-control-boundary; M-20261005-deep-plan-document-repair-local; M-20261005-deep-plan-document-repair-completion; M-20261006-runtime-layout-plan-preflight

### 2. Runtime 目錄收斂與 legacy 遷移 🆕

- **Writer**：`codex:runtime-layout-convergence`
- **Workspace**：`branch=refactor/runtime-layout-convergence`
- **Write Scope**：scripts/, setup-mac-env.sh, setup-linux-env.sh, shared/skills/handoff/, claude/skills/handoff/, codex/skills/handoff/, tests/, README.md, codex/README.md, docs/repo-guide.md, docs/add-new-host.md, docs/skill-portability.md, docs/testing-contract.md
- **Dossier Steward**：`codex:runtime-layout-convergence`
- **Context**：同一版 dotfiles 的新裝與既有主機升級尚未收斂：setup 與 dotsync 的 runtime 部署涵蓋不同，本機 Claude skills 曾需手動補入口；Codex rules 有整目錄連結與保留本機授權紀錄的共存形式；handoff 仍依 canonical／legacy 目錄存在情況選擇 store。使用者要求把歷史差異集中遷移，減少各腳本與 skill 的永久相容分支。
- **Goal**：同一版 dotfiles 在 macOS／Linux 的乾淨新裝、既有環境升級與重跑部署後，得到相同的受管理 runtime 結構、資料位置與可觀察行為；保留原生／第三方內容與明示 override，完成納管主機遷移後清理本項可移除的 legacy 執行分支。
- **Acceptance Criteria**：
  1. 在 repo 的既有權威文件定義唯一正式結構與管理邊界：Claude skills 採實體 discovery root、repo entries 逐項連結並保留同步內容；Codex entries 位於 `~/.agents/skills`，system／第三方入口保留其原生位置；Codex rules 採實體 root、repo 規則獨立連結、runtime 授權紀錄可寫；handoff 預設 store 固定為 `~/.agents/handoffs`。Codex config 維持既有三層合併契約。
  2. macOS／Linux setup、dotsync 的本機與遠端流程、brewup／sysup 的適用入口共用同一組部署 helper；CLI 未安裝時也能準備正確結構並明示能力缺項，不因新裝／升級分成不同 layout。
  3. 遷移工具可盤點、預演、備份、執行、驗證與安全重跑；涵蓋舊實體副本、整目錄連結、逐項連結、缺少新入口及部分完成／中斷狀態。備份留在 discovery root 外，來源 ownership 不明、同名內容衝突、外部 writer 或無法取得一致 snapshot 時停止該目標，不覆蓋或自行選邊。
  4. handoff 舊 store 的 active／archive 與相關檔案完整遷移到正式 store；驗證內容、checksum／錨點、survey／predecessor／verify／consume 行為，不因搬移宣稱舊 claims 已重新授權。canonical 與 legacy 同時存在時，依逐檔盤點處理；有衝突即保留來源並回報。
  5. 盤點本項的 legacy 相容分支與仍存續的資料契約。store 路徑 fallback 在遷移驗收後移除，正常 skill 固定使用正式位置；未遷移環境明確回報需要升級。舊 archive 命名／metadata 格式須另有無歧義轉換與行為證據才移除 reader 相容；仍需保留者逐項記錄原因與移除條件。
  6. 以隔離環境比較乾淨新裝、各受支援舊結構升級與部署重跑的受管理路徑種類、link identity、設定層級、可寫資料位置及載入結果；確認第二次執行不再改動。覆蓋衝突、並行 writer、失敗／中斷恢復與回滾，證明登入／hook trust／個人規則／同步 skills／第三方內容未遺失或意外進入 repo。
  7. 修正合併至 `origin/main` 且取得當批部署授權後，盤點並驗收現行 inventory 的 14 個目標（本機 macs 計一次）：revision、正式結構、共用資源、舊入口殘留與資料保全皆有逐台證據；有原生 CLI 的端驗證實際載入，缺 CLI／連線／信任者明示能力邊界，不以設定檔已存在冒充功能可用或全機隊完成。
  8. 實作前建立可重現的新裝／升級差異 fixture；必要的 handoff behavior eval 與雙端驗證、`./tests/run.sh`、文件與交叉引用檢查通過。涉及既有相容契約的變更，以新 event-time record 明確取代相關舊決策的對應部分，保留歷史證據。
- **Constraints**：使用者已以「開工」授權本項本地實作與驗證；本輪 `$project --merge` 將既有規劃文件與 active assignment 隨 #271 修復提交保存，不代表本項 implementation 或 fleet migration 已完成。本項後續實作的 shipping／部署仍依當批具名授權與 repo 規則。CLI 安裝／更新、套件升級、SSH／inventory 改版及其他 skill 的獨立 legacy 契約不納入本項。保留 config.local.toml 與合法 HANDOFF_DIR override、雙薄入口／單一 neutral core、handoff claims／frontmatter gate；不關閉安全檢查或代為信任 hooks。修改 skill 前依 AGENTS.md 的 authoring route；移除舊 store resolver 前須以安全 migration／locking 的行為證據滿足既有重議條件。
- **進度**：2026-10-06 Spec 已建立；起點 `338da91fc3a2ba6ce2487e63d0f8ab4b6c527ab1`，功能分支 `refactor/runtime-layout-convergence`。implementation plan、14 目標唯讀盤點與原行為隔離重現已完成。deep-plan 第一批完整兩輪均有有效獨立結果；第一輪的集合證據與跨 active/archive 生命週期衝突、第二輪新增的 CI assertion manifest／parallel runner 相依已補正。使用者已選擇新批盲審，原 journal restart 成功；prepare 因 STATUS 差異中的「第一輪／第二輪」觸發 #271 的 `review-pressure-in-input`，新批零 reserved tickets、零 reviewers，尚無新 gate 結果。先前完整 serial／parallel 各 1570 PASS、0 FAIL 是當時快照，不涵蓋其後 Spec 文件更新。尚無程式實作或主機遷移，先前 Turbo 部署手動修補不算本項驗收。
- **下一步**：#271 本地修復及原 journal 續審驗收已完成；接續本項前核對原 journal／findings、授權與最新文件／程式基線，再依合法 controller 路徑審查，GO 後實作共用 helper。固定 repair_documents 外的 milestone 與 #271 程式改動不能冒充同批 focused 文件修正；保留證據、不重設 journal。#271 尚未 shipping，fleet 散佈仍須當批授權與 `origin/main` 前提；fleet 驗收後才移除 handoff legacy fallback。
- **關聯**：#271; D-20260823-portable-handoff-skill; D-20260912-neutral-portable-skill-core; D-20260912-codex-config-three-layer-merge; M-20260912-codex-config-and-dotsync-exit; M-20261001-handoff-frontmatter-anchor-verify

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
