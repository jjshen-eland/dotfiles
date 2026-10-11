# 小幅變更的驗證與交付成本改善（#285）

- 日期：2026-10-08
- 工作項：issue-285-workflow-verification-economy
- 狀態：in-progress
- 種類：implementation
- Writer／Dossier Steward：`claude:delivery-overhead`（2026-10-10 經 PR #299 移交生效，見 D-20261010-transfer-delivery-overhead）
- Workspace：`branch=perf/delivery-overhead-verification`
- 當前工作基線：`1f0d96729dc7d9769b9f356245408393b0e4e649`（PR #290 合併後）；重啟 spec 基線為 `d0a4624`（PR #289 完整退版後），原始基線 `92dc1b9c6e6a836146606d3cee12edd2505ecef6` 僅供歷史重現。
- 需求來源：[GitHub #285](https://github.com/jjshen-eland/dotfiles/issues/285)、[GitHub #279](https://github.com/jjshen-eland/dotfiles/issues/279)。2026-10-09 使用者重新要求診斷並明示 `$project spec`，確認前任停止，由本 session 接續 `codex:brewup-bun-global-update`；本輪只寫 spec，過去交付授權不沿用。

**目前有效規格（2026-10-10）**：驗收改為 CI 路由補齊、平台無關 controller 只跑 Ubuntu、
紀錄撰寫規則、端到端交付量測四項，條文以 STATUS.md item 3 為準，決策見
D-20261010-delivery-overhead-spec。下方 2026-10-09 版規格與後續段落保留為歷史追溯。
第 1、2 項已合併（M-20261011-ci-platform-matrix-merged）；第 3、4 項見下兩節。

## 第 3 項：D／X／M 紀錄撰寫規則（全機隊，2026-10-11 修訂）

狀態：draft，deep-plan 審查通過前不改任何規則檔。取代本節 2026-10-11 稍早的「紀錄減量契約」草稿與 1,500 B
上限（D-20261011-record-volume-scope-narrowed、D-20261011-record-rules-before-size-cap、
D-20261011-delivery-measurement-next-targets）。第 4 項量測顯示寫紀錄約佔扣等待後交付時間 9–11%，本項目標因此是
紀錄品質與可追溯性，不以省時間為驗收，也不設長度上限。

### 目標

定義 D／X／M 紀錄的四類規則，讓沒有原對話的讀者（另一主機、另一 runtime 或人）只靠紀錄與其指標就能還原：
發生或決定了什麼、為什麼、如何查證、何時不再適用、與哪些紀錄相依。

1. **必寫**：每類紀錄必須帶的資訊。
2. **不用寫**：可由 git／PR／CI、計畫或其他紀錄取得的內容，改以指標引用。
3. **不要寫**：不屬於歷史事件結果的內容。
4. **不使用的寫法**：讓冷讀者無法解讀或會隨時間腐爛的寫法。

每條規則必須對應 Phase 0 觀察到的缺陷；沒有觀察到的不寫。

### 範圍與放置

- 規則寫在 `shared/skills/project/references/dossier.md`「記錄時機與 record schema」，改寫該節既有內容，不另開
  平行章節或新 reference；Claude 與 Codex 的 project skill 都連到 shared core，dotsync 後所有使用 `/project`／
  `$project` 的 repo 同時生效，其他 repo 沒有檔案變更。
- dossier.md 在 Log 結案階段必讀（目前 10,900 B），讀規則文件已佔交付時間約 14%（第 4 項）；本項新增內容以
  表格精簡呈現，並在 Phase 2 量測增加的讀取 bytes。
- 寫前重讀：`claude/CLAUDE.md` 與 `codex/AGENTS.md` 的非 kernel 區各加一行「寫 D／X／M 紀錄前，重讀
  `shared/skills/project/references/dossier.md`「記錄時機與 record schema」的部署路徑」。兩檔部署為全機隊全域指令，路徑寫部署後位置：Claude 寫
  `~/.claude/skills/project/references/dossier.md`、Codex 寫 `~/.agents/skills/project/references/dossier.md`，
  與既有全域指標（`claude/CLAUDE.md`「PR / Git」）同形；repo 相對路徑在 dotfiles 以外解析不到，而 dotfiles 的
  xref gate 仍會綠。依據是 Phase 0「寫入當下的脈絡」：寫入者幾乎都讀過 dossier.md，
  缺口是讀完後經 compaction 才寫；always-on 指令在 compaction 後仍載入。每次寫紀錄多讀一次規則段，規則段須
  精簡並計入讀取 bytes。是否加入由 Phase 2 情境 e 決定。
- 不改：kernel managed block；受信任 scanner（fleet 逐 byte 相同）；各 repo 的 `docs/document-governance.md`
  （各 repo 自有、不逐 byte，寫入者實測經 dossier.md，不加指標）；既有紀錄（append-only，已知缺陷不回改；
  斷鏈與懸空引用如需更正，以新紀錄說明）；`steward-authority.py`。
- 不採用：把規則做成逐 byte 複製進各受治理 repo 的檔案並在送出時比對。它讓沒有 skill 的寫入者也讀得到，但
  Phase 0 沒有這種寫入者，成本卻是新比對機制與每次修訂逐 repo 同步。重議：任一受治理 repo 的 archive 出現
  非使用者身分的作者，或 repo 移交給同事。
- 流程規定的紀錄內容維持現行要求（D-20261011-protocol-records-to-workflow-simplification）：endpoint 未達成時
  milestone 的「implementation 已完成、endpoint pending」（`log-prepare.md` Step 2 第 3 點、`pressure-tests.md`
  對應情境）與移交時的 conditional owner decision（`transfer-workflow.md`、`dossier.md`「平行協作與
  stewardship」、`templates/transfer-guide-template.md`）。規則寫明以這些流程為準，並列為第 6 項流程簡化的相依，
  不是永久例外；實作時核對這些檔與規則段沒有互相矛盾，成對實驗不以相反的 oracle 判分。
- 寫入協調：`shared/skills/project/`、`tests/`、`docs/testing-contract.md`、`claude/CLAUDE.md`、`codex/AGENTS.md`
  在本項 Write Scope；item 4 的 Write Scope 也含這些路徑中的後四者，但其現行下一步只做工具歸屬核對、不改這些檔，
  兩項依序進行。

### Phase 0：缺陷證據（2026-10-11，唯讀）

dotfiles 2026-08～10 的 443 筆紀錄（a60d20d），依檔內位置等距抽 M 16、D 15、X 8 筆，另加 2026-10 最長的 M 5 筆、D 3 筆；
人工判讀，另以 regex 統計全語料趨勢（只能看趨勢）。無實質缺陷：M 4/16、D 5/15、X 5/8；缺陷集中在 2026-10 與
2026-09 下旬。M 篇幅中位 08→10 月為 1,477→1,713 B，p90 1,921→2,895 B；10 月出現約 20 種自創欄位名，08 月只有
規定的四種。範例良好紀錄：M-20260822-retrieval-source-diversity、D-20260822-portable-project-skill、
D-20260917-terminal-macbooks-outside-inventory、X-20260823-retrieval-idf-and-h3-chunking。

| 缺陷 | 抽樣 M／D／X | 全語料趨勢 | 對應規則類 |
|---|---|---|---|
| 證據只指向 `/tmp` 等暫存 | 8／1／2 | M-10 61/108、08 月 0 | 必寫：可持久查證的指標 |
| 授權／endpoint 狀態與否定式聲明 | 8／3／1 | M-10 66/108、M-08 3/33 | 不要寫 |
| 原始量測、版本、完整 hash 傾倒 | 7／1／0 | M-10 58/108 帶 40/64 位 hex | 不用寫（放計畫或 artifact） |
| 重議寫成下一步或現況 | 6／0／0 | M-10 約 15 筆 | 必寫：可觀察條件 |
| 標題以 #issue 或階段詞開頭、缺主題詞 | 5／3／1 | 74 筆以 #數字開頭 | 必寫：主題詞標題 |
| session 過程敘事（使用者選項、上一輪） | 4／3／2 | 使用者選擇類 D-10 11、M-10 10 | 不要寫 |
| active-state／ownership 內容 | 4／1／0 | M-10 16 筆 | 不要寫 |
| 位置式或相對引用（`STATUS item N`） | 3／3／1 | 11 處，8 處已懸空 | 不使用的寫法 |
| 未定義術語或代碼 | 3／4／1 | — | 不使用的寫法 |
| 一筆多事件 | 3／1／0 | —（單一 issue 一日 10 筆 M 是拆得過碎，方向相反，不作本列證據） | 不要寫 |
| 缺放棄／重議欄 | 2／1／0 | 10 月 M＋D 缺放棄 23、缺重議 19 | 必寫（無則 none） |
| 與其他紀錄重複 | 2／2／0 | — | 不立規則（見 Phase 1） |
| 類型錯置 | 2／1／1 | — | 由必寫的 D／X／M 內容定義涵蓋 |
| 關聯 ≥8 項 | 4／0／0 | M-09 23 筆 | 不立規則（見 Phase 1） |

限制：單一評分者、39 筆；regex 數字含誤報。分析腳本與抽樣原文在 session scratchpad，不入庫；持久證據是下列
逐筆判定（ID | 缺陷編號；編號同下方其他 repo 補抽，另加 12 重複、14 關聯 ≥8、15 遷移佔位或非標準 label、
16 斷鏈或會腐爛的引用、17 缺可驗證指標、18 缺理由；「長尾」為只在長尾組）：

- M：M-20260815-project-blocked-routing 15,17；M-20260822-retrieval-source-diversity 無；
  M-20260825-project-multi-repo-scope 8（輕微）；M-20260826-project-retired-steward-gate 9；
  M-20260912-ci-run-34676591841-repair 無；M-20260915-b05-deep-plan-model-policy-reassessed 13,14；
  M-20260918-antigravity-cli-provisioning 無；M-20260928-project-merge-production-red-captured 2,4,5,9；
  M-20261002-session-skills-final-tree-verified 1,5,8,11,13,18；M-20261006-turbo-native-delivery-local 1,2,3,9,11；
  M-20261006-runtime-cloud-sync-validated 1,2,3,4,6,10；M-20261009-ci-controller-test-layers-local 1,2,3,4,6,7,8,10,14；
  長尾 M-20261008-ci-critical-path-measurement-complete 1,2,3,4,5,7,12；長尾 M-20261008-ci-controller-core-local 1,2,3,4,7,12,14；
  長尾 M-20261008-workflow-verification-economy-local 1,2,3,5,6,7,14；長尾 M-20261008-workflow-verification-economy-delivery-measured 1,2,3,4,5,6,10。
- D：D-20260819-dead-end-exit-modes 15,17；D-20260809-generated-docs-no-churn 9,15,17；D-20260822-portable-project-skill 無；
  D-20260825-portable-root-cause-first 無；D-20260909-dossier-byte-budget-cjk 16（輕微）；
  D-20260917-terminal-macbooks-outside-inventory 無；D-20260924-workflow-bounded-delivery 5,6,8；
  D-20260925-instruction-quality-scope 9,10；D-20261003-deep-plan-controller-adoption 2,9；D-20261006-turbo-public-help 6,11；
  D-20261008-ci-controller-adoption-local 2,5,6,7,8,12,13；D-20261011-turbo-direct-deletion 8,16（輕微）；
  長尾 D-20261008-ci-core-controller-recommendation 1,3,5,12；長尾 D-20261010-transfer-delivery-overhead 8；
  長尾 D-20261003-review-repair-controller-adoption 2,9。
- X：X-20260815-backlog-archive-without-split 15；X-20260820-global-routing-tree 15；X-20260823-retrieval-idf-and-h3-chunking 無；
  X-20260907-unreadable-tool-exclusion-argument 無；X-20260917-contract-eval-cwd-leak 16（輕微）；
  X-20261003-review-checklist-ablation 1,2；X-20261005-legacy-disposition-native-sandbox 5,6,8,9,13；
  X-20261006-turbo-help-copyable-commands 1,6。

上方缺陷表的計數為初次彙總；與逐筆判定不一致處（例如 D-20261010-transfer-delivery-overhead 的位置式引用漏計）
以逐筆判定為準。

**其他 repo 補抽**（D-20261011-record-rules-fleet-wide）：以同一抽樣規則與缺陷標籤，抽兩個其他 adopted repo
（營運型 kapi-infra、服務型 krepo-judicial）2026-09～10 的紀錄，判定全機隊是否有同樣缺陷；缺陷率明顯低於
dotfiles 時依該決策的重議條件重新評估範圍。

結果（2026-10-11；kapi-infra `46d176c`、krepo-judicial `03087fb`；單一判讀者，每格樣本小）：缺陷型態與 dotfiles
相同，不低於 dotfiles，重議條件未成立。無實質缺陷：kapi-infra M 0/8、D 3/8、X 1/4；krepo-judicial M 0/8、D 4/8、
X 0/2（dotfiles M 4/16、D 5/15、X 5/8）。授權／否定式聲明在 M 為 6/8、7/8，原始量測／hash 兩邊 M 皆 5/8，
krepo-judicial M 的 active-state 內容 5/8；暫存路徑與重議寫成下一步較少（kapi-infra M 幾乎不寫放棄／重議，
293/300）。兩邊都有非標準子欄位（理由、邊界、採用、下一步、診斷、適用條件）。逐筆判定（ID | 缺陷編號，編號依
上表列序：1 暫存路徑、2 授權聲明、3 原始量測、4 重議、5 標題、6 過程敘事、7 active-state、8 位置式引用、
9 未定義術語、10 一筆多事件、11 缺子項、13 類型錯置）：

- kapi-infra：M-20260913-shared-repository-role-contract 2,9,11；M-20260915-papp01-filesystem-permanent-convergence-complete 2,3,11；
  M-20260916-pops01-reboot-preflight 2,3,8,11；M-20260928-kapi-infra-repository-rename 2,7,11；
  M-20261002-kapi-entry-approval-candidate 2,3,6,11；M-20261004-judicial-runtime-installed-disabled 3,9,11；
  M-20261005-issue113-tools-review-candidate 2,3,5,7,8,9,11；M-20261009-notification-center-kapi-deploy 6,11；
  D-20260910-automate-host-certificate-renewal 無；D-20260913-use-shared-organization-role-teams 2；
  D-20260915-expand-governance-surface-budget 無；D-20260928-kapi-repository-scope-boundary 無；
  D-20261003-kapi-controller-plan-no-go 2,4,5,6,8,9；D-20261005-repair-infra-plan-approved 2,6,7；
  D-20261007-infra113-golive-split 4,6,8,9；D-20261010-deprecation-window-tracking 6；
  X-20260914-filesystem-dry-run-handoff-gate 1,2,3,11；X-20260917-ghcr-broker-macos-xattr-bundle 無；
  X-20261003-review-admission-defect-classification 2,3,6,8,11,13；X-20261005-service-routing-review-retry 2,3,4,6。
- krepo-judicial：M-20260912-judicial-writer-g2-preflight-blocked 2,3,9,11；M-20260918-judicial-final-cutoff-preflight-ready 2,3,11；
  M-20260926-judicial-production-schedules-complete 11；M-20260929-judicial-four-repo-admission-local-complete 2,3,7,11；
  M-20261003-judicial-audit-remediation-local-complete 2,3,6,7,9；M-20261004-judicial-adapter-integration-local 2,6,7,8；
  M-20261004-formal-sdk-cancel-adoption 2,7,8；M-20261005-judicial-release-preparation-complete 2,3,5,6,7,8,9；
  D-20260918-judicial-final-cutoff-updates-forward-only 無；D-20260929-judicial-g3-final-cutoff-indexable-key-joins 無；
  D-20260929-kgi-retrieval-v1-operations 無；D-20260929-separate-publisher-first-run-followup 2；
  D-20261002-judicial-case-strings-cursor-index 2,6,10；D-20261003-judicial-audit-isolated-repair 2,4,10；
  D-20261009-judicial-gateway-leftovers-removed 7；D-20261009-domain-rest-removed 無；
  X-20260923-judicial-g3-evidence-public-schema 2,3,11；X-20260929-kgi-party-pagination-id-tiebreaker 11。

**寫入當下的脈絡**（2026-10-11，本機 Claude／Codex transcript）：只計寫入真實 repo 且紀錄存在於該 repo HEAD
的首次寫入，共 879 次寫入、1,023 筆紀錄、11 個 repo、81 個 session。分類：A 讀過 dossier.md 且之後未 compaction；
B 讀過但之後 compaction；C 只讀過 `document-governance.md`；D 兩者皆無。

| 月份 | A | B | C | D |
|---|---|---|---|---|
| 08 | 36% | 11% | 51% | 0% |
| 09 | 47% | 27% | 23% | 1% |
| 10 | 38% | 54% | 5% | 1% |

與上方逐筆判定交叉：現行 schema 已規定的四子項，A 組缺漏 1/23、B 組 7/24（只看 10 月 1/9 對 7/22）；無缺陷
A 7/23、B 1/24。dotfiles 2026-08 起改 archive 的 252 個 commit 作者都是使用者本人的身分。限制：只有本機
transcript，Claude 舊 transcript 有缺；compaction 標記不等於規則內容遺失；B 組多為 10 月長 session，可能混雜；
單一判讀者、樣本小，只作方向證據。

### Phase 1：規則（候選）

| 類 | 內容 |
|---|---|
| 必寫 | 標題含主題詞，不以 issue 號或階段詞開頭。D：選了什麼、為什麼、適用範圍；X：試了什麼、為何放棄、證據；M：現在成立的結果與驗收證據。結果不完整時寫明範圍邊界，以肯定句描述（「只驗 Claude 端」），不用「不宣稱…」句型。決定來自使用者核定時寫明核定出處與核定的內容。證據指標須可持久查證（repo 路徑、commit、PR／issue、CI run）；暫存路徑只能附註，不能是唯一證據。四個子項都寫，無則 `none`；重議是可觀察的觸發條件。流程規定的內容（endpoint 未達成的 milestone、移交的 conditional owner decision）依該流程現行要求。 |
| 不用寫 | 原始量測：逐次樣本、中間拆解與完整分項表；不影響結論的環境版本；40／64 位完整 hash（commit 指標用短 SHA）；只是過程描述的 CI 耗時。這些放計畫、artifact 或 PR，紀錄只寫結論數字並指向原始資料。結論數字指判斷所依據的指標值（改前／改後或門檻判定，帶單位與量測條件）；判準是拿掉該數字結論是否仍成立，仍成立就不寫。CI 耗時本身是量測指標時屬結論；會限制結論成立範圍的版本屬必寫的範圍邊界。 |
| 不要寫 | Writer／Steward／branch／Write Scope 等 active-state；授權過程與 session 狀態（「已具名授權」「未 push」「尚未 commit」）；session 過程敘事（使用者選了選項幾、上一輪、本批如何進行）；下一步與待辦（屬 STATUS／backlog）；同一筆塞多個獨立事件。流程規定的內容不受此列限制。 |
| 不使用的寫法 | 位置式或相對引用（`STATUS item N`、上一輪、本批、今天）；未定義的縮寫與代碼；四個子項以外的自創欄位。 |

每條規則都要有成對實驗情境涵蓋，否則不進 dossier.md。dotfiles 機檢擋不住機隊其他 repo，所以只是 dotfiles
的額外防線，不能取代情境；重寫範例是教材，不算驗證。情境代號見 Phase 2 第 2 點。

| 規則 | 情境 | dotfiles 機檢 |
|---|---|---|
| 主題詞標題 | a–d（fixture 帶 #issue 脈絡） | `#數字` 開頭 |
| D／X／M 內容（含類型判準） | b（D）、d（X）、a／c（M） | — |
| 範圍邊界用肯定句 | a | — |
| 核定出處與內容 | b | — |
| 可持久查證的證據 | a | 暫存路徑為唯一證據 |
| 四子項（無則 none） | a–d | 放棄／重議／關聯缺漏（日期來源已由 scanner 檢查） |
| 重議為可觀察條件 | a、c | — |
| 原始量測不用寫 | c（fixture 帶逐次樣本與改前／改後值；盲評依「拿掉後結論是否仍成立」） | — |
| active-state 不要寫 | a（fixture 帶 STATUS Writer／branch） | — |
| 授權過程與 session 狀態不要寫 | a | — |
| session 敘事不要寫 | b | — |
| 下一步不要寫 | d | — |
| 一筆多事件不要寫 | d（fixture 另含一個獨立結果） | — |
| 位置式引用 | b | 有 |
| 未定義縮寫 | b（fixture 帶內部代碼） | — |
| 自創欄位 | a–d | 有 |
| 寫前重讀規則段（always-on 指令） | e | — |

考慮過但不立規則（每條規則都由機隊每次讀 dossier.md 永久付閱讀成本，沒有必要性的不加）：

- supersedes：同一節已規定「翻案另寫新 record，`關聯` 加 `supersedes:<old-id>`」，scanner 也檢查目標存在；
  Phase 0 沒有這類缺陷。
- git／GitHub 已保存的事實：Phase 0 沒有獨立缺陷；其中作為過程描述的 CI 耗時已併入不用寫的原始量測。
- 類型錯置：抽樣 4 筆；必寫的 D／X／M 內容定義就是類型判準，不另立規則或情境。
- 與其他紀錄重複：抽樣 4 筆、無全語料趨勢，代價只是篇幅。
- 長串關聯：4 筆全在 dotfiles，不是機隊缺陷；「無直接相依」無法機判，也不從現況統計推數量門檻。

### Phase 2：驗證

1. **重寫範例**：取 Phase 0 長尾 5 筆 M 與 3 筆 D，依規則重寫（不入庫）。逐筆核對 Phase 0 的五項可還原資訊
   是否保留，並以暫存語料比較原文與重寫版在 `doc-governance.py find` 對該主題查詢的命中名次。
2. **成對實驗**：依 `claude/skill-building-guide.md` 與 `docs/skill-portability.md`。情境取 Phase 0 的實際形狀：
   (a) 本地完成但 endpoint 未達、證據在暫存目錄的 milestone；(b) 使用者在編號選項中選定後的 decision；
   (c) 量測型 milestone；(d) 帶下一步的 dead end；(e) 脈絡中沒有規則段（模擬 compaction 後）時寫一筆 milestone，
   兩臂只差 always-on 指令有無寫前重讀那一行，看是否重讀並遵守；fixture 是 dotfiles 以外、不含 `shared/` 的暫存
   repo，指標只能經部署路徑解析。各情境 fixture 須含 Phase 1 對照表列出的脈絡。
   a–d 兩臂 query 與 fixture 逐字相同，只差 dossier.md 規則段；fixture 不含規則或答案。oracle 列出每情境的必寫項與
   禁止項，沒有語意歧義的（暫存路徑為唯一證據、位置式引用、自創欄位、缺子項、`#數字` 開頭標題）以腳本判，其餘
   以盲評。授權過程與 session 狀態只用盲評：現有 90 筆紀錄含「授權」，許多以授權規則為主題；情境 a 依流程必須
   寫 endpoint pending，字樣比對會把遵守流程判錯。盲評判準寫明流程規定的 endpoint 狀態不算違規。先在 Sonnet 上取得改前分歧（RED）；任一情境改前無分歧，對應規則不加。
   之後在 Claude Code `opus[1m]` 與 Codex production model 正式驗收，記錄 alias、resolved model、effort 與 CLI 版本。
   情境寫進 `shared/skills/project/references/pressure-tests.md`。
3. **dotfiles 機檢**：`tests/content-checks.py` 對新增紀錄檢查可機械判定的規則。新增的判定沿用
   `scripts/doc-governance.py` 的 git 基準：取當前 branch 與 default branch 的 merge-base，基準時不存在的紀錄才
   檢查；不依 ID 日期，補寫的舊日期紀錄同樣受檢，也不維護 ID 清單（清單本身會成為旁路）。CI 為完整歷史
   （`.github/workflows/test.yml` 的 `fetch-depth: 0`）；找不到基準時本機印出跳過說明，CI 上判失敗，不靜默
   通過。main 上跳過可接受，因為變更都經 PR，PR 一定有基準。先以暫存 repo 的 RED 對照取得證據：feature
   branch 新增違規紀錄為紅；同一筆違規紀錄在基準時已存在為綠；CI 環境無基準為紅。
4. **testing-contract**：事件證據指敘述特定一次發生的事（日期、PR／issue、run、commit、主機、該次實測結果），
   規則、指向計畫的路徑與作為規則識別的 stable ID 不算。以 a60d20d 的行號，Phase 0 判讀的位置為：
   - 已有 D／X／M 紀錄：131、165、171、359、477、566、584、911。
   - 只在 2026-08 legacy 區段或 milestones 前言、不是 D／X／M：16、21、74、94、280、296、300–301、335–339、744。
   - 部分對應：553。
   - 沒有任何紀錄：224、373、592、595、754、764、776。
   - 含證據 token 的標題：874（H2，#246）、921（H2，2026-10-02）、748（H3）。

   實作時先以同一判準重掃確認清單（token 掃描會漏掉不帶日期或數字的敘述），再把這些位置改為規則加一句理由並以
   ID 指向紀錄。沒有任何紀錄的位置逐處搬成一筆紀錄，依 `docs/doc-governance-rollout.md`「2. history 遷移」：原文
   帶日期的（595、776）以原文日期標 `日期來源:migration-entry`；無日期的（224、373、592、754、764）以搬遷當天
   日期寫進標題，標 `migration-cutover`。只在 2026-08 legacy 區段或 milestones 前言的位置已在 history store、
   `find` 查得到，改指向該處，不另建紀錄。重掃確認後的位置清單（含新發現位置）寫回本點。搬移時逐處列對照表：
   原文、去處（紀錄 ID 或 legacy 位置）、去處中對應的文字；對照表放在實作 PR 描述（GitHub 持久保存，不增加
   repo 閱讀量）。搬完再刪原文。兩個 H2
   改為主題標題，跑 title-free recall ratchet 與 xref audit。
5. **testing-contract 機檢**（依 D-20261011-record-volume-plan-choices 整份機檢）：`tests/content-checks.py` 整份
   掃描 ISO 日期、`#數字`／`PR #數字` 的 PR／issue 號、run ID 與 commit SHA，排除 `docs/plans/`、`docs/archive/`
   路徑內的字樣；清理完成後必須零命中。a60d20d 版以此規則命中 16 行，全在上列事件證據清單內，沒有命中規則行；
   其中 477、892 行以 issue 號作規則識別、874 行為 H2，清理時改為 stable ID 或主題標題。先以含各類字樣的 fixture
   取得 RED。同一測試另驗 testing-contract 中每個 D／X／M ID 都對應到既有紀錄（`xref_scan` 只驗檔案＋節名引用，
   不驗 ID；原型掃 444 筆紀錄約 4.4 ms），以打錯的 ID fixture 取得 RED。不帶字樣的事件敘述（如 224 行）沒有
   機檢；本次清理以重掃後的清單為準，之後新增的這類敘述不受機檢保護。
6. 全套測試與 `doc-governance audit --ship`。

### Phase 3：送出與觀察

一個 PR；合併後經授權 dotsync。觀察 dotfiles 之後 15 筆新紀錄，並抽查一個其他 adopted repo 的新紀錄，以
Phase 0 同一標籤判讀缺陷率。

### 驗收

1. dossier.md 的規則段含四類規則，每條對應 Phase 0 的缺陷並有 Phase 1 對照表的情境涵蓋；Phase 2 成對實驗改前有分歧、改後兩端正式驗收通過。
2. 重寫範例保留五項可還原資訊，`find` 命中名次不退步。
3. dotfiles 機檢的三個 RED 對照（新增違規紅、基準已存在綠、CI 無基準紅）先紅後綠。
4. testing-contract 機檢（字樣與 ID 存在）先紅後綠、清理後零命中；重掃確認後清單的每個位置都已改為規則加理由並
   指向紀錄；實作 PR 的搬移對照表逐處核對，非預期遺失為 0；recall ratchet 與 xref 通過。
5. 全套測試、`doc-governance audit --ship` 通過；dossier.md 增加的 bytes 與讀取成本列入報告。

## 第 4 項：端到端量測（2026-10-11，進行中）

**回溯：真實交付的分段**（唯讀，Codex／Claude 本機 session 紀錄，2026-09-26 起）。每個 tool call 與結果
都有時間戳；上一結果到下一呼叫的生成時間歸給下一呼叫的類別，執行時間另計，平行重疊不重複計。起點為帶
`$project`／`/project` 的 user 訊息，終點為下一則真正 user 訊息前的最後回報；問題回覆的等待另記。
排除 exec session 84、eval sandbox 22、spec 27、transfer 2 個 run；不經 `/project` 的裸 merge 指令未計入。

dotfiles 有實際送出的 51 個 run（Codex 46、Claude 5；merged 42、只開 PR 9）：總時間中位 1,138 秒、
p90 2,045 秒；扣掉 CI 與使用者等待後中位 770 秒。

| 類別 | 中位秒數 | p90 秒數 | 佔扣等待後時間（中位／合併） |
|---|---|---|---|
| 讀流程 reference | 94 | 290 | 14.1%／16.8% |
| 狀態偵測 | 86 | 247 | 12.7%／13.9% |
| 寫紀錄 | 73 | 183 | 9.4%／11.1% |
| 本地測試與證據核對 | 124 | 369 | 20.6%／22.8% |
| commit | 43 | 93 | 4.6%／5.9% |
| push／PR | 64 | 134 | 9.4%／9.6% |
| CI 等待 | 271 | 522 | 佔總時間 24.9% |
| merge 與清理 | 34 | 77 | 4.4%／5.2% |

寫紀錄時間 96% 是模型生成，工具執行約 4%；41 個 run 有寫紀錄，中位 2 檔、新增約 2.4 KB。寫紀錄佔扣等待後
時間超過 25% 的 dotfiles run 只有 1 個。其他 repo 54 個 run 的寫紀錄佔比（11.1%）與 dotfiles 相當。
限制：分類為啟發式；寫入前讀紀錄檔的時間併入寫紀錄（偏高）；一般句子回答會切斷 run；Claude 樣本只有 5 個。
分析腳本與逐 run CSV 在本 session scratchpad（`e2e-retro/`），不入庫，session 結束後不保證存在。

**本地：固定小改動**（`scripts/agent-turn-end-timestamp.sh` 的提示文字改一詞，`tests/modules/session.sh`
同步預期值；兩個 detached worktree 套同一改動、`./tests/run.sh --base <base>` 各兩次）：

| 基線 | 選中模組 | wall |
|---|---|---|
| `c465732`（#301 前） | 全套 30 個 | 122.2／128.7 秒 |
| `0333be3`（現行 main） | content、session、lint、platform、shell-contract | 18.6／18.8 秒 |

`c465732` 兩次的 turbo 模組因本機 turbo 連結已移除而 0.06 秒失敗；它在正常情況下與 deep-plan（75 秒）平行，
改前 wall 可能略被低估。

**Hosted**（Actions job 執行時間，不含排隊）：改前一般程式 PR macOS 144–221 秒、Ubuntu 103–125 秒，純紀錄
PR 42／56 秒；改後 #304（大型重構）151／105 秒、#305（純紀錄）34／42 秒。改後的固定小改動經使用者同意以
draft PR #306 量測（量完關閉、刪 branch）：macOS 40 秒、Ubuntu 64 秒，run 全程 67 秒。

**待補**：改後真實交付一筆，於下次真實小改動送出時順便量，不為量測製造交付。

**結果與後續**（D-20261011-delivery-measurement-next-targets）：寫紀錄不是主要成本，第 3 項改以紀錄品質為
目標、不設長度上限；讀流程 reference 與狀態偵測合計約 27%，列為 STATUS item 3 第 5 項。

**2026-10-09 版規格（整體重構，已由上段取代）**：使用者要求把本項當成重構或重寫，
不預設逐年累積的測試、gate、分片、觸發條件或驗證流程不可改。本節與 STATUS 的新契約
取代先前「保留所有現有案例、只做單一有界候選」的實作限制；下方歷史對照與已退版實作
只供追溯，不限制新設計。決策見 D-20261009-ci-system-redesign。原 checkout 的
claude/settings.json 為確認的 runtime drift，保持原樣；Runtime 遷移產品工作不接續。

目標是以 repo 實際需要的保障，重新設計從本地驗證到 PR gate 的最小合理流程，
降低小幅腳本／純紀錄變更從交付指令到最終回報的實際耗時。CI、測試實作與交付流程
一起檢視；測試數量、既有檔案結構、全量執行或每項雙 OS 執行都不是驗收目標。
授權、資料保全與正確失敗回報仍是必要結果；達成它們的機制可重設。

固定證據與未確認部分：

| 案例／階段 | 秒 | 邊界 |
|---|---:|---|
| PR #288 指令到開 PR | 593.629 | 24 次 tool call；9 次 reference reader、6 次含臨時 Python |
| 可見 tool／background 區間 union | 20.362 | 是上列子集；區間外 573.267 秒含生成、處理與排程，不能全稱模型思考 |
| PR #288 PR 到 merge | 435.000 | macOS job 329 秒、Ubuntu 157 秒，並行且一次成功 |
| PR #288 merge 到同步清理觀測 | 215.820 | 不包含最終回報 |
| PR #288 指令到同步清理觀測 | 1244.449 | 純紀錄三檔；無 compaction、無新增本地全套 |

PR #288 的原始 trace 顯示重建舊環境／snapshot、核對已修正的 EOF newline、
誤用普通 SHA256 後再讀 canonical helper 的額外往返；證據是流程行為，不把整段差額
當作某個 helper 的執行時間。Workflow 無差異分類，每個 PR 都跑雙 OS 全套。
最近五輪 macOS 最慢均為 core；退版後 run 37874093903 的 core／runtime／plan／review／ship_state
分別 294／263／235／199／107 秒，suite step 296 秒、依賴安裝 6 秒。
Hosted core 子項與資源競爭仍未知；runner 先緩衝各 shard log 再輸出，不能用輸出時間戳
推算子項執行時間。歷史不同來源／環境的快慢不是固定條件的因果對照。

重構順序與驗收：

1. **由失敗風險建立測試清單。** 以具體錯誤與對外行為分類現有 tests，逐組決定保留、合併、
   下移到單元層、改寫或移除，列出理由及新承接位置。歷史事故是需求證據，不能自動變成
   永久全域 gate；只檢查實作字樣、重複覆蓋或已退役功能的測試須重新證明價值。
2. **定義一套一致的測試架構。** 模組各有可獨立執行的入口；廉價靜態檢查、純邏輯行為、
   Git／程序／檔案系統整合、原生模型 eval 分層。大量狀態組合優先在低成本層驗證，
   真實邊界保留代表流程及各自獨立的失敗 controls，不讓每個組合重建整條整合鏈。
   全套是這些模組的組合，不再以 monolithic shell 的歷史節號或固定 PASS 數定義完整性。
3. **重新安排觸發及平台。** 依實際依賴建立可理解的模組對應，同一份宣告服務本地與 CI。
   內容檢查與檢查工具自身回歸分開；平台敏感路徑在各適用 OS 驗，平台無關邏輯評估單平台。
   決定 full regression 的必要觸發，不預設每個 PR 全套，也不把必要的合併前保障移到事後
   才發現。未知影響／選擇器錯誤不得空集合成功；fallback 與 required checks 接線以新設計
   一起驗證。遠端 protection 調整仍須當批具名授權。
4. **依新架構分段替換。** 先選成本高且有明確邊界的模組驗證設計，再遷移其餘群組；
   不把第一段的局部收益冒充整體完成。舊 runner／分片／selector 若無必要即退役，
   不在舊架構外永久疊另一層。測試規範與 agent 的本地驗證指引同步更新，避免 CI
   已變快但每次交付仍重跑舊全套。需要修改產品 helper 才能建立測試邊界時，再具體
   核對其 writer／scope 與行為契約，不把 skill 產品功能全部順帶重寫。
5. **以有效攔截及實際時間驗收。** 代表純紀錄、普通單模組腳本、共用依賴及 CI 自身修改，
   核對選到的 checks、失敗注入、未知輸入、程序取消與必要平台反例；不能靠少報測試數
   或放行錯誤取得 GREEN。凍結來源與環境，記錄各模組時間與總 wall time；先一組判斷
   方向，有收益再做有限交錯對照，總計納入選測及證據準備成本。真實 hosted job 與
   指令至最終回報分開驗；本地收益不外推成 20 分鐘交付問題已解決。

初始架構盤點（按當前來源，處置仍需行為驗證）：

| 現有群組 | 重構方向 | 必須說明的保障 |
|---|---|---|
| shell／kernel／xref／當前文件 corpus | 獨立內容檢查，與 scanner synthetic regressions 分開 | 真實壞檔與工具失敗都會阻止通過 |
| deep-plan／review controller | 分開狀態決策、snapshot adapter 與端到端生命週期 | 授權、restart、dirty／stage／commit、mode／衝突各在哪層驗 |
| ship-state／Project／handoff | 依功能邊界獨立入口，合併重複 Git/provider fixture | scope、ownership、來源失效及外部失敗不能被沿用證據遮蔽 |
| runtime／setup／brewup／同步 | 模組測試與部署邊界測試分層，按平台選擇 | 使用者資料保全、冪等、失敗傳播及真實 entry 接線 |
| skill prose／packaging／native eval | 區分安裝接線、機械契約與模型行為；淘汰無獨立價值字樣 gate | 文字匹配不得被當成模型遵從；昂貴 native eval 維持有目的執行 |
| runner／CI／shard accounting | 重新設計集合選擇與完成證據，舊分片可取消 | 漏跑、重複、失敗、取消與錯誤接線可被識別，名稱相同不等於真的執行 |

2026-10-09 使用者「開始」後實作：先以獨立功能模組取代 shell 歷史分片，將內容掃描、
scanner regression 與 controller suites 拆開，以單一宣告提供本地／CI 選測、執行與逐組計時。
執行器按選定模組的完成及 exit 判定，不再維護固定 assertion 計數；舊分片聚合器隨替換退役。
第一段保留仍有效的行為 oracle 作搬移對照，這不是永久保留全部測試的限制；高成本整合矩陣
再按獨立風險拆層。平台敏感 shell／Git 模組先保留雙 OS，未取得平台獨立證據前不直接刪平台。
本次先在隔離 worktree 完成本地實作與驗證，不改遠端設定。

本輪具體處置：原 9,644 行 shell 入口拆為功能模組與共用 fixture harness；獨立 Python
suites 由同一 catalog 直接編排。舊 core／ship_state／plan／review／runtime 分片、固定斷言數
manifest、分片 supervisor／aggregate 及只服務它們的測試退役；取消與啟動 race 改由新 runner
實際程序 controls 承接。真實文件 corpus 只在 content 跑一次，document-regression 排除該類；
heading 變更由當前 xref／corpus 守，不再觸發無關 scanner regression。
共用 skill 相依尚未能可靠縮到單一 workflow，因此採全部 workflow consumers 的保守聯集；
少數已盤點的運維腳本與 crawl-quality 可獨立選測，未知路徑全套。這是具體的已知相依表，
不把任意同副檔名視為獨立。每模組 wall time 直接回報；普通交付只跑一次相同 runner。

本地實作沿用使用者的開工方向；新批次 push／PR／merge／部署仍無授權。

2026-10-09 PR #291 已完成 rebase merge（c2e0a0f），hosted 全套 Ubuntu 72.180 秒、macOS
238.847 秒（job 99／255 秒）。使用者回報 macOS 仍慢並要求繼續；本段驗收改追各
controller 的實際重複程序成本，再以 state-policy 與真實 Git／CLI 邊界分層減少重複。
保留所有獨立錯誤攔截、以相同來源環境量 before／after；不預設並行數或刪 OS 是修法。
macOS 歷史 job 的不同來源／runner 只作定位，不當成受控因果比較；新批送出另需授權。

同機 profile 先重現第二意見額度單例 4.198 秒，其中 28 次 scope verify 3.209 秒（巢狀
時間不相加）。Review controller 分為 15 個 CLI／Git 整合與 8 個 scope 已驗證的 Policy
案例；所有 23 個原測試 body AST 相同，只有呼叫邊界改變。完整該檔 before 69.617 秒、
after 46.239 秒；故意放行 reserved capacity、recurrence diagnosis、partial result 三個
缺陷時，三個新 Policy cases 均以 assertion failure 攔下。最初 partial-result 注入改在
未被該錯誤分支呼叫的 result_verdict，屬無效 mutation，改成移除確切 result-set guard
後才列入證據。

Deep-plan 合併重疊的 6 格文件狀態矩陣至 12 格歷史矩陣，保留原 delta／輪次／歷史／
髒 code 保全斷言；所有 12 格仍走真 Git 的 prepare／claim／finish，2 格另走真 launcher，
既有 public launcher 與雙 runtime CLI cases 保留。全檔 41→40 個方法，唯一移除方法
的斷言已併入矩陣；before 70.660 秒、after 56.400 秒，均 exit 0。舊 history 矩陣
25.727 秒＋重複矩陣 8.177 秒，合併後 19.757 秒。此段只改測試組織與文件，未改
產品 controller、平台、selector 或並行數；後續全套及 hosted 結果分開記錄。
原始逐案例時間／log：/tmp/ci-controller-{before,after}.log、/tmp/ci-deep-plan-{before,after}.log；
程序 trace 與 mutation logs：/tmp/ci-controller-profile。暫存失效時不可補造。

續查整套：同一個乾淨 clone 先跑基線 c2e0a0f，再套用上述測試分層，完整 wall
128.207→122.680 秒，29 模組均 exit 0、測後 clean；只有 4.3% 收益，不作整體已解。
接著定位 production fresh 先 scope_check，再 load_scope 內重做 scope_check；兩次之間
沒有 mutation，移除外層一次仍保留 load_scope 的外部 verifier 與完整 identity 比較。
新增真 verifier control 先以 2 != 1 得 RED；去重後每 scope 一次、實際檔案漂移與偽造
identity 都有 GREEN。測試曾嘗試還原檔案 bytes 後沿用舊 manifest，但 capture 的狀態仍
判 drift；改為重新 capture 建立有效基準才驗 identity 分支，不放寬 verifier。
這是共享 skill script 的有界實作去重，雙 runtime adapter topology、prompt、policy 未變；
兩入口 quick_validate 通過，不宣稱新增 native model eval。
同 clone 最終候選 fixture da656df9a75dabb54241222297cc777812491760 全套 29 模組 exit 0、
測後 clean，wall 118.704 秒；對基線 128.207 秒縮短 7.4%，對分層候選 122.680 秒再省
3.2%。同次全套 review-controller 82.269→45.884 秒、turbo 48.278→39.525 秒，最終
deep-plan 77.570 秒仍最長。模組時間受同時執行的其他模組影響，不把逐項差額加總作
wall-time 因果；單輪循序比較尚非統計穩定性或 hosted macOS 承諾。原始三輪 log、
JSON、fixture patches 在 /tmp/ci-controller-layers-final；baseline-full、candidate-clone-full、
fresh-clone-full 分別對應基線／分層／去重，不與工作樹開發中的樣本混用。
本批程式／測試到此凍結，收尾只驗當前文件；hosted 與完整交付待新 endpoint 授權。
使用者隨後明示 `$project --pr`，本輪送出候選至 PR；不合併，hosted 實測未完成前不追加效能結論。

2026-10-09 PR #292 合併 17efb21204576b13ba0725ca2be1a3a0a6545f21 後，使用者授權接續
處理 deep-plan：hosted macOS suite 167.092 秒（deep-plan 117.131），Ubuntu 85.024 秒；
不同 run 的時間只是觀察，不能當受控因果。這批先固定該基線，量 controller 每個操作的 Git
查詢與文件快照成本；成功條件是相同三層資料、錯誤拒絕、journal 相容與跨操作 freshness
保持，降低已定位的重複程序成本，並在完整 suite 取得 before／after。只做本地驗證；
沒有新 commit／push／PR／merge／部署授權。必要產品範圍新增 exact review-state.py，
其餘 Runtime writer 保持停止，未接續原工作。
已量得 routing 40 tests 57.943 秒；十二格歷史矩陣 20.189 秒，直接 controller Git
2859 次／14.351 秒，其中 git_document 1788 次／9.156 秒（894 cat-file、456 ls-tree、
438 ls-files）。146 次 document_snapshot 分布於 open／prepare／render／check_ticket；
函式 inclusive 計時不相加，launcher child 未納入該程序 trace。根因是單次 snapshot 按
每份文件分別查 metadata／blob；先以相同三層資料與固定程序上限建立 RED，再合併單次
snapshot 的查詢，保留操作間 freshness 與前後核對。Canonical copy 仍為 neutral shared
review-state.py，雙 runtime 連結相同，既有 #264／#271 oracle 與 prompts 保留。
原始 profile／固定 clone 全套證據放 /tmp/deep-plan-snapshot-perf，暫存遺失不得補造。
新反例先以 17 > 5 Git 程序 RED；一次 snapshot 改為整份 index、選定 HEAD entries 與一個
cat-file --batch，OID 在該次去重，以長度 framing 解碼並驗 object 身分、型別及完整回應。
索引 listing 同時作 protected fingerprint；操作前後與下一次 snapshot 全部照常重讀。
三個新測試 GREEN，雙入口 validator 通過；批次 framing 的缺漏／截斷／額外 bytes 明確拒絕。
原先 prototype RED 的三個 batch corruption failures 是舊程式未使用 batch，僅程序數反例
證明既有重複成本；不能把預先新增的 protocol guard 測試宣稱成舊版安全缺陷。
依 authoring guide 做 fresh-context public CLI forward check，evaluator 未讀 implementation diff。
主 writer 已核對 /private/tmp/deep-plan-forward.DlrGUD/commands.jsonl、summary.json：雙端
controller 交接完成合法三層文件修正且既存 dirty code 保留；prepare 後 code／document drift
在 claim 拒絕，claim 後 drift 在 finish 拒絕並保留 invalid round，無效 UTF-8 拒絕。
評估中 synthetic result schema／ID 重用錯誤亦被拒絕，另建獨立 fixture 後才列正向結果；
不清舊 journal 洗綠。這是 synthetic CLI 行為驗證，不是 native reviewer 品質或新模型 eval。
最終相同 clone／Python 3.14.8／PATH 的完整 29 模組皆 exit 0；基線 wall 120.051 秒，
候選 111.604 秒（縮短 7.0%），deep-plan 74.459→58.304 秒（21.7%）。新增 3 個 routing
測試，原 40 個保留；整套受測前後 full input_snapshot 一致，包含 symlink targets。
最終程式／測試 bytes 與 active worktree 相同；收尾文件只補當前 content／governance，
不為文件重跑同份程式全套。這是一輪受控順序比較，hosted macOS、Ubuntu 與指令到 merge
全程未量，不承諾相同降幅，也不關閉 #285。原始 baseline-full／candidate-full-evidence.json
記錄 command、exit、stdout、inputs、快照與環境，可供後續 Project 核對沿用。
使用者隨後以 `$project --pr` 授權本批提交與 PR 交付；保留既有完整程式驗收證據，
收尾只補當前文件檢查，hosted 結果以本批 PR CI 為準，終點不含 merge／部署。

上一批模組化本地驗收（2026-10-09）：29 個模組在凍結來源串行、並行各 exit 0；串行
465.552 秒僅作一次遷移獨立性檢查，並行 wall 127.666 秒。相同 brewup 註解修改透過
真實 `run-ci.py` 入口，以舊→新、新→舊交錯比較：舊 120.332／119.028 秒，新
14.701／14.725 秒；平均 119.680 → 14.713 秒（87.71%），含 scope 選擇與所有
所選模組。純紀錄 13.406 秒。每輪 exit 0，測前／測後來源 hash 一致；Python 3.14.8、
同機循序執行，不混用開發中被修改來源的無效樣本。完整 suite 未宣稱加速。

選測保留整批 committed／staged／unstaged 範圍、symlink consumers、未知及 topology
變動全套 fallback；腳本＋所屬 shell 測試＋README 可維持有界集合。13 個 runner controls
及 15 個 PR scope controls 通過，含非空完成訊號、失敗 exit、漏跑、取消 descendants、
Popen 啟動 signal race 與已結束 group 不重複發訊號。後者先有 RED 才修正 ownership
移除時機。完整並行驗證後只加 README route 與 shell completion control，定向 13 tests
另通過；17 個新 shell 模組只修檔尾空行並驗語法，結果文件另跑當前內容檢查。

原始 before／after clean clones、fixture patches、完整 logs、measurements.json 在
`/private/var/folders/t5/4b3mtjj52fvdplz5f15mf_ym0000gp/T/ci-redesign-7aqkqpkv`；
來源基線 `ab9efedcdb97a3c3e1f976749081d0ace2ed485c`。暫存遺失時不得補造原始證據。
本段完成測試編排與已知路徑選測；controller 內部真 Git 矩陣尚未下移、共同 workflow
仍選保守 consumer 聯集、平台仍雙 OS。GitHub 實跑及完整交付尚未量到，總 work item
保持 in-progress，不以局部收益關閉 #285。下一步先讓本批 PR 提供雙平台模組計時，
再以真實小修改交付驗整段結果。


量測來源：PR #288 body、Actions runs 37824528246／37874093903；同機原始 session
`/Users/jjshen/.codex/sessions/2026/10/08/rollout-2026-10-08T15-08-21-01a11a57-75bb-7da1-b85e-9714aaa2952f.jsonl`，
normalized measurement `/tmp/workflow-285-20261009-call-timeline/shipping-session-measurement.json`。
暫存不存在時明示不可重查的部分，不能補造結果；remote-visible timestamps 可另由 API 核對。
Spec 完成不代表優化或交付完成。使用者續以「開工」授權本地實作與驗證；
首個候選先固定完整 candidate diff 的驗證範圍：docs-merged 的舊程式測試與已合入 base
不同，但本批只有 prose；docs-mixed 的最後一個 commit 同為 prose，前一個 pending commit
卻有 code。兩者都須先查整批差異與 repo contract，不能用最後一顆 commit 或舊紀錄
決定本批範圍。候選尚未採用；此步不授權 commit／push／PR／merge／部署。

實作進度：第一個 Log 指引候選的 Opus before／after 為 73.9496／74.2011 秒，無淨收益，
已撤回指引並保留 fixtures／raw trace（X-20261009-log-scope-latency）；Codex host negotiation
timeout 發生在 skill 讀取前，屬無效能力樣本。#279 有界紀錄 CI 候選已完成本地驗證，實際規則
與測試入口見 docs/testing-contract.md 第 25 節及 D-20261009-ci-record-selection-candidate。
完整 serial 1577 PASS／0 FAIL；固定來源的兩組交錯對照：

| 同機 suite 執行 | 第一組（全套→紀錄） | 第二組（紀錄→全套） |
|---|---:|---:|
| 全套 parallel | 120.591 秒 | 116.515 秒 |
| records（含分類） | 13.135 秒 | 13.111 秒 |

中位數由 118.553 秒降至 13.123 秒（88.93%），每次 exit 0、checkout 乾淨；全套原 manifest
計數保持 1577／0。真實 xref／缺 Writer 文件故障皆在 records 路徑 exit 1；scope 與取消清理
controls 通過。完整來源、環境、raw logs 與失敗樣本邊界見 M-20261009-ci-record-selection-local。
本地收益支持保留候選；不包含 checkout／安裝或完整交付時間。普通程式修改仍跑全套，新增
selector tests 的 hosted 成本尚待觀察。使用者續選 `$project --pr`，本批開 PR 驗雙 OS；
merge 與後續同類真實交付仍另待當批授權與證據。
不宣稱 #285 的完整交付耗時已改善，work item 保持 in-progress。

2026-10-09 接續診斷：PR #290 已以 rebase 合併至 `1f0d96729dc7d9769b9f356245408393b0e4e649`，
雙 OS 全套各 1577／0。使用者懷疑 10 月初 skill 變更造成非線性延遲，並以「go」授權固定
案例的隔離對照。驗收是辨認新增成本與適用範圍，不以歷史時間相關宣稱因果或正式修復。
Project 固定同一已驗證實作＋README 補記案例，比對 evidence helper 前、加入後及分階段載入後；
CI 固定本機環境，量新增 controller 測試與相鄰版本全套 critical path。保留原始來源、命令、
exit、完整 log／native trace、模型與測試環境；一輪判斷方向，有明確收益才有限重複。
本輪不改正式 skill／runner，不開空 PR、不送出或部署；runtime drift 保留。

本輪歷史對照初步結果（2026-10-09）：固定 `tested` fixture、Opus `claude-opus-5-5[1m]`、
high／standard，三個來源依序為 `cbd4dd2`（helper 前）、`3d675bf`（helper 後）、`4048952`
（分階段載入後），完整本地 Log 120.149／103.385／85.077 秒。原始 trace 與機械核對顯示
必要 EOF 無缺漏、來源 hashes／fixture HEAD／工作樹不變、額外測試皆 0；reader calls
14／15／12，bytes 145047／147407／99302。單組順序樣本不證明穩定加速；只能說這個正常
沿用案例未重現退化，不能外推成 Codex xhigh 的 PR #288、真實 provider shipping 或治理 repo
的全部收尾成本。原事故仍有大段可見工具區間外耗時，不能稱為純模型思考。

同機 Python 3.14.8 的原樣歷史 controller 測試以 unittest result observer 計時，全部 exit 0、
來源 checkout 前後乾淨。deep-plan 的 `03b79e1`：20 cases／10.801 秒；`9bd2397`：36 cases／
64.454 秒；`b1abf9b`：41 cases／122.996 秒。最後一版的 Routing 約 11.966 秒，
DocumentRepair 109.569 秒，NativeDocumentFixture 1.350 秒；主程序直接啟動 8386 個
subprocess（不含子程序再派生者），其中 DocumentRepair 占 7532。最大單一方法為
`test_review_history_checkpoint_to_launcher_and_admission`，12 個 policy×restart×Git state
組合、44.65 秒／2608 個直接 subprocess。review controller 的 `df6086a`：67.356 秒；
`b1abf9b`：94.890 秒。這些整組 unittest 各只占外層 suite 一個 PASS，不能用外層 assertion
數量推論工作量。完整 parallel 對照：`f8c87c46c5c19f50fdfc65d97b40b562a7f66962` 為 117.905 秒、
1564／0；`b1abf9b4abfd83b1fdd9887274ab4ab5b3f9c92d` 為 409.247 秒、1570／0，皆 exit 0。
三分片 core／ship_state／integration 分別為 45／64／116 秒與 49／62／409 秒；增幅集中在
integration。這是歷史版本比較，不能當作目前五分片 main 的速度；兩端之間還有其他變更，
不能把完整 291.342 秒差額全歸給 controller，也不能相加獨立 profile 秒數當作 parallel 的歸因。
同一新版以原入口只選 Routing 的控制為 12.287 秒、20 cases PASS、exit 0、checkout 乾淨，
支持主要 deep-plan 增量來自新增的 DocumentRepair 群組，而非原 routing 全面退化。

診斷終態分開記錄：CI 新增工作量來源為 ROOT CAUSE CONFIRMED（限定上述具名測試群組）；
PR #288 完整交付的所有額外成本仍 UNCONFIRMED。各 gate 的錯誤攔截目的存在，不代表
每個小改動都必須付出相同讀取／真 Git 組合成本。下一個有根據的候選是驗證同一次
`document_snapshot` 的 Git 查詢能否合併，保留所有現有案例與 mode／stage／scope 反例；
先不刪測試或直接退版 skill。此項會觸及 deep-plan implementation，屬後續 scope，沒有在本輪
正式 source 實作或宣稱修好。沒有對本輪未重現的 Project 正常分支追加新規則。

原始 artifacts 位於同機暫存 `/tmp` 對應的 `delivery-cause-20261009-icnwhwm_` 目錄；
`manifest.json`／各 native raw/timed trace／`native-grade.json`／`ci-results.json`／各
`*-profile.json` 保存來源與命令。歷史原來源透過 clean no-local clones 固定；instrumentation
僅存在暫存 observer，不修改 skill 原碼。暫存遺失時須明示原 trace 無法重查；不能以本文摘要
補造受測結果。本輪不追加全面 native 矩陣或以 benchmark 代替真實交付驗收。

## 診斷與證據邊界

1. 原事件的 bun RED 跑整個 runtime shard，664 PASS／5 FAIL、108 秒。
   從固定 `92dc1b9` 的 `tests/run.sh` 原樣取出 18d 的 fixture 與 assertions，沒有改 oracle，
   對 `27fc2ad` 的舊 brewup 得到 29 PASS／5 FAIL、exit 1、6.895 秒；
   對 `92dc1b9` 的 brewup 得到 34 PASS／0 FAIL、exit 0、5.828 秒。
   這證明同一組失敗與成功 controls 可有界驗證；現行正式入口只有 shard，無獨立 18d 入口。
   新入口只能用來快速取得受影響行為的 RED／GREEN，不能冒充全套、xref 或部署驗收。
2. 本批真實 serial evidence 的 helper check 輸出 19,475 bytes，其中重複列出 443 個已在 record 的 inputs。
   保留 command、verdict、完整 changed_inputs、reason、environment，加 input_count 的摘要為 228 bytes。
   原 verdict 為 NEED_TEST，差異為 STATUS 與 milestone 文件；此判定不得因輸出縮小而改變。
   機械控制可量測冗餘輸出；尚不能把整段 9 分 46 秒歸因於輸出量或預估等額 wall-time 收益。
3. 原始來源只保存 frozen patch／raw logs，shipping 需從固定 base＋patch 還原。
   原工具 trace 同時保存 exit 0 與測試期間 patch 未變的核對，是該次還原的 provenance；
   日後應在實際執行時保留完整原結果與必要來源快照，避免再重建，不補造過去 snapshot。
   Directory symlink 展開後的 __pycache__ 差異來自呼叫端過寬的輸入選擇，並非 helper 忽略來源變更的 bug。
   不直接排除所有 ignored 檔；來源、fixtures、相關環境與 link topology 仍由呼叫端查證。

原始 artifacts：`/tmp/workflow-285-diagnosis-sno29yxk/{before.log,current.log,brewup-group.sh,diagnosis.json,helper-check-full.json}`。
重建 18d control 使用上述 immutable Git blobs 的 `ok`／`bad`／assert helpers，及 18d 開頭到 all-up 執行位 assertions 前的原樣區段；
只將 BUP 指向指定 immutable brewup 副本。HOME、DOTFILES_DIR、PATH 與所有套件指令維持原 fixture 隔離。

## 最小修正順序

1. 把既有 18d fixture／assertions 抽成單一 canonical 測試入口，完整 runtime 繼續呼叫同一份，
   提供明確的本地獨立 invocation。先保留舊實作 RED、目前實作 GREEN，再驗全套集合與結果計數不漂移。
   不建立依賴 selector、不根據 diff 自動略測、不修改 hosted CI 或 branch protection。
2. 為既有 read-only evidence checker 增加有界的摘要輸出選項，Log 使用該選項；
   保留既有完整輸出相容性、原始 evidence、完整 changed_inputs 與 exit／verdict 語意。
   Snapshot 輸出不得被摘要裁掉。先固定 large-input、unchanged、changed、unknown、error controls。
3. 針對實作階段缺乏原始 evidence 的 observed gap，先用既有 snapshot primitive 保存實際驗證前後來源，
   原 command／exit／output 保留於當次 artifact；用 native ordinary-script／docs-closeout／reuse controls
   判斷最少需要修改的 always-on 指引，不先建立 cache、receipt framework 或新的永久 store。
   任何新指引須有 before failure／after behavior 證據，不以文字完整性或縮短字數驗收。

每個因果修正分別固定 RED、驗 GREEN，再做下一個；只調整該修正影響的案例。
最終因涉及 runner 抽取，依既有契約做一次 serial／parallel 對照；此目的不可泛化為普通腳本變更的雙重驗收。
固定最後程式／測試輸入後保存證據，收尾文件按實際差異補治理／xref，不再無條件重跑兩套。

## 寫入協調與預定路徑

2026-10-08 使用者選擇將本批必要 tests/ 與 testing contract 寫入交由 #285；原 Runtime writer 保持停止。已於 STATUS 更新兩項的 scope，沒有接續 Runtime 產品目標。
最小修正將涉及 `tests/run.sh`、`tests/project-test-evidence-test.py`、必要的新 18d 測試入口，
以及 `docs/testing-contract.md`；若實際 aggregation accounting 改變才動 `tests/shard-manifest.tsv`。
這些路徑的本批寫入已交給 #285；原 Runtime scope 暫移除共享 tests/ 與 testing contract，後續另依 assignment 協調。

其餘可能改動限於 `shared/skills/project/scripts/test-evidence.py`、受影響的 Project references／behavior oracle，
及經 native RED 證實必要的 root `AGENTS.md` 驗證指引。兩 runtime 的既有 entry／shared linkage 保持。
無關 skill、Runtime 產品契約、機隊部署與 #279 selector 不納入。

## 驗證與完成條件

2026-10-08 事件：抽取入口的兩個 reproducing tests 先以缺入口 exit 127 失敗，修後兩例 PASS（11.444 秒）；
新 evidence controls 在缺 `--compact` 時 RED，實作後 15 tests PASS（6.168 秒）。
對實際 443-input record，完整／compact 都為 exit 1 NEED_TEST、changed_inputs 完全一致，輸出 19,894 → 648 bytes；
目前變更多於初始診斷，不能拿這筆 648 冒充最初未改動時的 228-byte projection。

Project 為已 portable：雙入口／references／templates／test-evidence helper 都解析到既有 shared core；
Claude scripts 逐檔 link、Codex scripts 目錄 link，拓樸不變。沿用 D-20260825-portable-skill-authoring-default、
M-20260822-portable-project-skill 的 baseline，無 migration 或 ownership 變更。

Native before：`ordinary-script` 的 Codex gpt-6.1-sol 真實執行 focused RED、serial GREEN、parallel GREEN、doc；
兩個完整入口跑同一集合，該批沒有 runner 變更，故冗餘完整執行 RED 已重現。Opus 同 fixture 只跑一次完整測試，
不把其 baseline 成功當新增收益。兩端都沒有保存綁定 dirty 測試來源的前後 snapshot，原 tool results 保留在 trace。
`docs-closeout` baseline 兩端都能沿用既有證據，不重跑完整測試；Codex 跑兩次 doc gate、Opus 一次，
此正常控制不宣稱有新的 native wall-time 收益。原始 roots `/tmp/workflow-285-before-{ordinary,docs}`。

Native v1 ordinary 的 Opus RED 保留：先用 zsh scalar 組 input argv，snapshot 失敗仍繼續跑完整測試；
其後改 array 重做快照又重跑 suite，原 trace 為 2 focused／2 serial／1 doc，final 卻稱完整一次。
另一次 rm 變數清理被 host 拒絕後改用 fresh temp，沒有在真 repo 重試拒絕指令。
根因為保存階段未 fail fast；最小修正要求測前 snapshot 成功且 JSON 有效才啟動完整測試。
只重測受影響 ordinary 分支，其他 controls 用原 v1 實態驗收；不把新結果覆蓋 v1 RED。

Native v2 ordinary 雙端 PASS：完整測試各 1 次，真正受測的 dirty 來源前後一致，原 result 經 helper 重查為 REUSE。
Codex 190.082 秒／Opus 67.141 秒；before 86.313／34.961 秒。小 fixture 的完整測試近乎即時，新增來源保存
增加模型成本，因此只證明重複全套消除與 provenance，**未證明 native wall-time 改善**。
docs-closeout 兩端零新完整、各 1 doc；Log reuse／changed／unknown 新測試次數為 0／1／1，各端實際 compact check，
12 reader calls／七份 refs 完整、normalizer errors=[]。這些必要 refs 不縮減；Codex reference_s 為 59.764／83.670／93.045，
Opus 為 46.688／50.776／65.216 秒，仍為可觀固定成本，沒有新的 RED 證明可刪除 required 讀取。
本批不用假定的 shipping／CI 時間宣称解決整段 15 分鐘；後續需要真實交付分段再量。

Canonical linkage／兩 native entries 通過实际 CLI 使用；Codex quick validator PASS。相同 Codex validator
仍拒絕未修改的 Claude-native `argument-hint`／`disable-model-invocation`／`user-invocable` frontmatter，
這是既有適用範圍差異；Claude entry 以原生 CLI 與 repo packaging gate 驗證，不刪掉 native metadata 冒充 validator PASS。
Python 3.14／3.9 的 evidence 15 tests PASS；ShellCheck、CI confidence 11 tests 與 metrics 7 tests PASS。

- 同一組 18d assertions 對舊實作維持 5 FAIL，對目前實作維持 34 PASS；真實 HOME／套件未受影響。
- Evidence 摘要模式與完整模式的判定及 changed_inputs 一致；large-input 輸出省掉重複 scope。
- 未知／失敗結果、source／fixture／mode／必要 link target／環境漂移維持拒用；ignored input 仍受測。
- 必要 Claude Code／Codex production-target behavior controls、validator、完整 runner 對照及治理／xref 通過。
- 記錄各階段實際命令、來源 revision、輸入、exit、操作次數與 wall time，分開報告機械收益、native 收益與未驗邊界。
- 不自行 push／開 PR／merge／部署；本地完成依 repo 與 skill authoring 授權邊界回報。

2026-10-08 最終本地驗收：一次 serial／parallel 對照各 exit 0、1578 PASS／0 FAIL；
wall time 分別 453.544499／137.808644 秒（同機有重疊執行，不相加也不用於前後效能結論）。
各 run 前後 695 個來源與 environment facts 一致。Runtime 保留 669、core 175（新增一個入口控制），其餘 shards 不變。
Artifacts `/tmp/workflow-285-final-verification/` 保存各自 before／after、原 log、exit／wall summary、完整 evidence、
code-input projection 與 environment；另保存與實際受測內容一致的 candidate-tested.patch、四個新檔的 content／mode。
Code projection 不涵蓋 STATUS／docs，不能冒充全部文件也已驗；結果補記後另補 fresh 治理／xref。
這批必做 runner parity，不能用本批兩套完整執行反過來要求未改 runner 的普通變更也跑兩套。

本地候選的程式與受測指引固定；無 commit／push／PR／merge／部署。保留 STATUS active contract，
plan 維持 in-progress，待本批具名交付後以真實分階段時間完成 #285 的交付成本驗收，不先關 issue 或移除 assignment。

2026-10-08 交付準備：使用者明示 `$project --merge`；沿用原 serial／parallel 的 code-input projection，
fresh helper 各 exit 0 REUSE、environment matched；完整 inputs 的差異僅 STATUS、本 plan 與本地 milestone，
這三份結果補記改以 fresh 治理／xref 驗證。保留 active contract 與未結案 backlog，PR 使用 Refs #285；
必要 reference 讀取與 native wall-time 未改善的限制仍有效，尚未發生的 endpoint／效能不寫成已完成。

交付實測與接續驗收（2026-10-08）：

第一批已由 PR #287 rebase merge 到 origin/main，commit 112d37de7bdc2854f6a7d49e6e20a17bb4be3f57。
Required CI Ubuntu 116 秒／macOS 197 秒，均一次成功；本地全套新增 0 次、CI 修復提交 0 次。
本機 main 同步與本支清理完成，續行 dotsync 為 local=ok、remote_ok=14、remote_failed=0、exit 0。

原始 session 現可核對完整邊界，取代先前只能提供的時間下界：使用者 merge 指令
2026-10-08 18:03:11.481 → 最終回報 18:23:29.878（Asia/Taipei），1218.397 秒。
ContextCompaction host event 的 started_at_ms／completed_at_ms 為 1791453866460／1791454252835，
直接 duration 386.375 秒；不是把沒有工具輸出的空檔猜成 compaction。

| 階段 | wall seconds |
|---|---:|
| 指令到 compaction 開始 | 74.979 |
| ContextCompaction | 386.375 |
| 恢復到建立 PR | 400.165 |
| PR 到 merge（含 CI） | 256.000 |
| merge 到本地同步與清支觀測 | 25.000 |
| 同步後補量測紀錄到最終回報 | 75.878 |

直接扣除 compaction 為 832.022 秒，只是算術分解，不是無 compaction 的對照。
恢復段有 10 次 reader calls（包含一次錯誤 argv）；六份先前已讀 refs 因內容只剩摘要而重讀，
另外 ship-paths／merge-workflow 首次載入。整段 reader／entry 恢復約 43 秒，不能把 400.165 秒全歸讀取。
其餘 trace 包含檔案／原證據查證、文件更新與 staged diff、尾端空白修正與受影響驗證、錯誤 OID 的
authority 重查、PR body／Ship 摘要及 push。這些區間包含模型決策與工具往返，不當作單一腳本執行時間。

已確認的執行缺陷為 staged check 非零後仍 commit、dependent HEAD 查詢與 gate 被併入同一平行群組，
其中 gate 使用了並非 Git 輸出的 OID。既有 exit／先決條件與相依操作紀律已能禁止這兩種行為；
不能僅凭單次 primary 的偏離就堆疊新 prose。下一項驗收先用隔離的已驗收／待本地提交案例，
在固定 92dc1b9 與 112d37d 的 source 上比較真實 preflight／commit、證據沿用及 wall time。
Prompt 只給 task-local scope、原始結果與 repo 先決條件；不給期望策略。若 native controls 已遵守規範，
保留 production 失敗與正常對照，不為無 RED 的路徑改 skill。

原始 session：/Users/jjshen/.codex/sessions/2026/10/08/rollout-2026-10-08T15-08-21-01a11a57-75bb-7da1-b85e-9714aaa2952f.jsonl。
Normalized timestamps／host event：/tmp/workflow-285-final-verification/shipping-session-measurement.json；
GitHub PR #287／Actions run 37762509491 保留 remote-visible 交付與 CI 證據。
這是已發生的里程碑補記；#285 保持 in-progress，不能以平台等待或新的單次 sample 宣稱 latency 已修好。

接續控制結果（2026-10-08）：原生 gpt-6.1-sol 在固定 before=92dc1b9／after=112d37d 的
Project source 上完成同一個已驗收、只待 README 結果補記的本地提交案例。兩端保留原始結果與
interpreter 適用性，helper 實際 exit 0 REUSE、新測試 0 次、feature branch 一個 README commit、
working tree clean、遠端 refs 未變；source hashes 無漂移。各有 12 reader calls／七份 refs，行號、
固定 SHA 與完整 EOF 正常，未縮減必要讀取。Before 工具呼叫 22 次、耗時 130.384 秒；after 19 次、
103.022 秒。兩輪同機並行且只有一組小型 legacy fixture，不包含真實 PR／CI／compaction，
不能把這筆 27.362 秒差額外推成生產交付收益。

Before 在工作樹發現檔尾空白、先修正再 stage，cached check exit 0 後才 commit；after 的首次
cached check exit 2，修正後 exit 0，再以成功先決條件才 commit。兩端都沒有重現原 merge 的
忽略失敗提交，這個控制僅證明具名先決條件能正常遵守，不證明所有場景皆安全。根因狀態為：
原 production 的執行紀律偏離已確認；剩餘 400.165 秒全部成本與可泛化的 latency 修復仍未確認。
因此本輪未修改 skill、runner 或新增規則，也未重跑完整 suite；issue 驗收條件 1 保持未完成。

先前 workspace-write fixture 阻止 Codex 寫入 .git，不能比較正常提交耗時；保留失效樣本而不計入
有效對照。該輪 Opus 同時有 stdin 額外內容污染，不當作正式 wall-time 比較。有效 Codex 對照改由
isolated fixture-shell 提供正常 Git metadata 寫入、完整 stdout，driver stdin=/dev/null；沒有放寬
真 repo 的 permission 或 shipping 授權。原始 runs：
/var/folders/t5/4b3mtjj52fvdplz5f15mf_ym0000gp/T/workflow-285-prepared-git-m0lufq12；
normalized grade：/tmp/workflow-285-final-verification/prepared-closeout-grade.json。
本輪 issue／STATUS 已回填第一批交付事實；本地三份結果補記尚未 commit／push／PR／merge／部署。

2026-10-09 接續量測：以原始 session 的 custom_tool_call／output 與 CommandExecution 時間戳，
核對恢復 18:10:52.835 到 PR createdAt 18:17:33.000 的 400.165 秒。

| 操作區段（依事件邊界） | wall seconds |
|---|---:|
| Entry／references 恢復 | 42.822 |
| 盤點、證據查證、文件更新與 staged 檢視，到首次 commit | 169.738 |
| 檔尾空白修正、受影響驗證與第二次 commit | 111.412 |
| HEAD／authority 修正與 PR 準備 | 43.311 |
| Push 與 PR 建立 | 32.882 |

區段總和 400.165 秒；只描述執行順序，不能當作各項都可消除的成本。30 次 tool call 的
call 到 return 合計 13.324 秒；背景命令會跨越 return，因此合併去重可見 call／背景區間後為
21.235 秒，剩餘 378.930 秒位於區間外。區間外包含指令準備、結果處理、回報及 host／模型排程，
不能冒稱純模型思考，也不能把只有零寬記錄的命令當成已量得完整 subprocess 時間。
PR createdAt 為秒級精度；所有區間在該邊界截斷，不把建立 PR 後的時間混入前段。

可核對的額外往返包括：盤點整批權威文件與完整 evidence 的輸出截斷（call index 11），
首次大份 staged diff 輸出截斷（index 17）；其後各有局部重讀。一次空白修正與第二次 commit、
錯誤 HEAD 的 authority 重查保留原失敗。這支持縮小輸出及正確處理相依／失敗結果的執行安排，
但既有規範已涵蓋，正常 native 控制未提供新增 prose 的 RED；本輪無程式或 skill 修改。

量測終態為 UNCONFIRMED：剩餘區間內的成本來源仍不足以完整歸因，未證明 latency 已修好。
下一個可核對證據為新批真實交付的 tool／背景區間與 PR／CI／merge／回報時間戳；若只交付
這三份結果文件，scope 與先前 15-file 實作不同，不能用整段差額冒充同規模改善或直接關閉 #285。
目前只有本地續作授權，push／PR／merge 需新批具名授權；過去 PR #287 的 merge 授權已完成。
Artifact：/tmp/workflow-285-20261009-call-timeline/timeline.json，包含原 source SHA、精確區間、
操作命令、exit、output bytes／截斷標記與合併區間；未建立永久快取或新治理 store。

2026-10-09 交付準備：使用者明示新的 `$project --merge`，本批僅三份結果文件，Refs #285、
保留 active／backlog。原 serial／parallel 環境與當前一致；helper 判定唯一 code 差異為
tests/lib/assertions.sh 檔尾一個 newline，原 affected record 的 34 PASS 經 helper 重查為 REUSE、
environment matched，舊 full 結果不冒稱來源完全相同。前批 required CI run 37762509491 在
557bae361df6275686674f8d0d57e599b7c95cbc 已雙 OS success；本批仍需自身 PR HEAD 的 required CI。
結果補記只補 fresh 治理／xref；當前 endpoint pending、不宣稱已 merge 或 latency 已改善。

## 完整退版（2026-10-09）

使用者明示：「退版吧，有做比沒做還糟。所謂有收益的部分，為了僅留下他，又要跑一大串測試，沒什麼意義」。
本批完整撤回 PR #287 的實作與後續空白修正，不再切分保留局部功能。
固定還原基線為 `92dc1b9c6e6a836146606d3cee12edd2505ecef6`；十二個非紀錄路徑逐一比對內容與 mode，
其中三個新增測試檔應消失。保留 `bun update -g`、#279 與已提交的所有 history／量測。
退版驗收是完整還原及必要測試通過，不宣稱已證明生產端到端耗時改善。

原新增流程的普通腳本控制 Codex 86.313 → 190.082 秒、Opus 34.961 → 67.141 秒；
局部測試／输出收益不能取代總耗時驗收。最新 PR #288 只交付三份結果文件，
merge 指令到同步清理觀測為 1244.449 秒（20 分 44 秒，未含最後回報），建立 PR 前 593.629 秒且沒有 compaction；
詳見 PR #288 的已核對量測，保留不同 scope 與非因果控制的限制。

本輪只獲本地退版授權，新的 push／PR／merge／dotsync 未獲授權；active assignment 保留到具名交付。
本地退版驗收完成：十二個路徑內容／mode 與固定基線完全一致，三個新增測試檔 absent，brewup 未變。
`./tests/run.sh` 與 `./tests/run-parallel.sh` 各 exit 0、1577 PASS／0 FAIL；core 還原為 174，runtime 保留 669。
兩 runner 同機並行，wall time 各 414.585／126.955 秒，不相加也不當作效能改善對照。
原 command／exit／完整 logs 與測前 patch 保存在 `/tmp/workflow-285-revert-o4xlch4g/`，測試前後 patch／status 一致。
已通過治理／xref 與 Codex validator；結果補記後只補文件檢查，不重跑未變的程式測試。
尚未 push／PR／merge／dotsync，不先記為已退到 origin/main。
