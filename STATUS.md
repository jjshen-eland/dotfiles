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

### 3. CI 測試可信度與必要覆蓋

- **Writer**：`codex:runtime-layout-convergence`
- **Workspace**：`branch=fix/ci-test-confidence`
- **Write Scope**：tests/, .github/workflows/test.yml, scripts/render-etc-hosts.sh, scripts/all-up.sh, scripts/sign-host-keys.sh, scripts/sign-user-key.sh, docs/testing-contract.md
- **Dossier Steward**：`codex:runtime-layout-convergence`
- **Context**：使用者要求審查 CI 測試的必要性、缺少的必要測試與內容正確性。2026-10-07 本機完整 parallel suite exit 0，頂層斷言 core 171／ship_state 239／integration 1166，共 1576 全綠；隔離 fixture 仍重現 hosts 異常 marker 刪除非管理內容、all-up 吞掉 brewup 失敗、兩支 SSH 簽署腳本失敗卻 exit 0，以及 CI matrix 字串假綠、heredoc scanner exit 被忽略／delimiter 誤判、parallel cleanup 留下 descendant。使用者以 `$project spec` 及 recovery 選項明確確認前任已停止，由本 session 接續既有工作線與 dossier 維護並新增本契約。
- **Goal**：讓必要 CI 測試可證偽地攔截已確認的錯誤與漏跑，補齊高風險運維腳本的失敗／內容保全覆蓋；在不減少有效防線的前提下去除已證明的重複檢查。
- **Acceptance Criteria**：
  1. 實作前把七項審查發現各自固化為隔離、自動、可重現的 RED fixture；先保存現行失敗結果，再修實作或 gate，修後同一 fixture GREEN，並保留相鄰合法輸入的正向 control。測試不得讀取真實 CA、更新本機或連線實際主機；SSH／SCP／sudo／套件更新使用隔離替身。
  2. hosts renderer 對缺少／逆序／巢狀等無法無歧義辨識的 marker 拒絕寫入，原檔保持；正常完整區塊替換仍保留非管理內容且冪等。遠端處理採同樣的內容保全判準，以捕獲的真實遠端 payload 在隔離 target 驗證，不接觸 `/etc/hosts`。
  3. all-up 將 brewup 與適用 sysup 的結果共同納入主機與全程終判，後段成功或 sudo 略過不得掩蓋前段失敗；任一必要階段失敗最終非零，其他指定主機仍被處理。覆蓋 macOS／Linux、全成功／部分失敗、sudo 略過與 SSH 失敗，核對 exit、逐台結果與總計。
  4. sign-host-keys／sign-user-key 的全成功、部分失敗與全失敗皆有行為測試；任一主機失敗最終非零，其他指定主機仍被處理，計數與實際替身呼叫一致。涵蓋取 key、簽署、上傳與必要部署步驟失敗，不以成功文案代替完成證據。
  5. CI contract gate 解析實際 YAML 結構，驗證 PR trigger、雙 OS matrix、唯讀權限、dependencies 與完整 suite 執行 step；註解或不執行區段中的相同文字不得滿足契約。固定 Ubuntu-only 加 macOS comment 的 RED，並保留正常雙 OS workflow GREEN；不新增未授權 provider 設定或 branch protection mutation。
  6. heredoc gate 在 scanner 自身失敗時 fail closed，不把空 stdout 當零 findings；delimiter 比對遵守普通 heredoc 與 `<<-` 的 tab 語意。固定縮排 delimiter 提早關閉造成的漏報，保留 quoted heredoc、herestring、註解與安全內容注入的正向 controls。Scanner 的 RED／GREEN 與 scanner-error 各自核對 exit／findings；這個漏報 fixture 現行 ShellCheck 另可攔截，不將它描述為整套 CI 的漏判。
  7. parallel runner 遇 SIGINT／SIGTERM 或 child 中斷時，最終非零且停止仍活躍的 shard／descendant，沒有可繼續寫入或持有輸出 pipe 的殘留程序；cleanup 保留 Bash 3.2 空 array 相容性。以實際 runner 與隔離 child tree 驗證，不只抽取 cleanup function，也不只核對目錄消失；result aggregator 的缺件／錯誤／重複 summary controls 持續通過。
  8. 盤點每個 gate 的風險、oracle 與覆蓋範圍。ShellCheck／bash -n 對同一 canonical 實體檔只掃一次，仍涵蓋 runtime-specific wrappers 且 symlink 接線有獨立驗證；現行 76 個輸入／53 個實體檔只作事前基線，不把這兩個數字固定成永久門檻。其他形式或字句檢查只有在可證明重複或替代測試能攔同一失敗時才精簡；保留 kernel 複本一致性、授權／資料保全、雙 OS 與 shard 完整性防線。
  9. `./tests/run.sh` 與 `./tests/run-parallel.sh` 均以實際 exit 0 驗收，assertion 變更同步 shard manifest，serial／parallel 執行集合與結果一致；macOS／Ubuntu PR CI、doc-governance audit 與 xref 均通過。文件區分 wiring 檢查、確定性行為測試與 opt-in native/model eval 的證據邊界，不宣稱未執行環境或未驗模型行為已通過。
  10. 使用者以「開始，先量測」追加本地 macOS section 耗時量測：保留現行三個 shards 與全部 assertions，以原 runner 的 stdout section 邊界記錄 foreground wall time、原始 log、exit、來源 fingerprint 與環境；先量測 integration，區分本機與 GitHub runner，量測前不刪測試或實作重新分片。
  11. 使用者量測後以「繼續」授權本地分片優化：先清查候選連續區段的跨段變數／functions／fixtures；新 shard 必須獨立初始化必要依賴，保持原 integration assertions 的互斥完整聯集及原 serial 順序。同步 manifest，保留 integration 聚合入口，實跑完整 serial／parallel 比對逐條 assertions 與 exit，signal／child failure cleanup controls 持續通過；以本機前後 wall time 評估改善，不冒充 GitHub runner 或雙 OS 的驗收。
- **Constraints**：使用者以「開工」授權本項本地實作與驗證；本輪另明示 `$project --merge`，依該 invocation 的 shipping policy 執行本批 feature branch／PR／required CI／rebase merge 與必要同 PR 修復，不含部署，授權不跨 session／批次。保留既有 runtime 遷移工作，不把本項當成其驗收或結案。沿用同一 Dossier Steward，兩項 scripts／tests scope 相交，須由同一 writer 順序處理，禁止平行 writer。實作前遵守先 RED 再修；不因測試數變少、跑得更快或文件措辭改變而宣稱品質改善。不擴成套件升級、SSH／CA 架構改版、模型 eval 自動化或治理重設計；若需修改 skill entry／shared core，先依 authoring route，並另核對 scope。
- **進度**：本地可信度修正與分片優化均完成驗證：七項原始 RED 已修正，11 組隔離測試 GREEN；額外固定 lint 重複、dependency continue-on-error、matrix 順序誤紅、custom shell 假綠與 supervisor spawn signal race 的 controls。新版完整 serial／parallel 均 exit 0、1574 PASS／0 FAIL；逐段 assertion 順序與完整多重集合相同，只正規化成功 local-fetch 文案的實測耗秒（原始值保留於 log）。五段測試內容保持，manifest 為 172／239／112／383／668；獨立分片的 Git fixtures／路徑自行初始化，Bash 5.3／3.2 的 runner 清理 controls 通過。必要性與 oracle 邊界已記於 testing contract，canonical 檔案聯集及 wrappers／接線 gates 保留。雙 OS PR CI 與 native/model eval 尚未執行，未達 AC9 的結案條件；本項與 runtime 工作均維持 active。
- **量測**：本地 macOS 26.7.1／32 logical CPUs 的 section 基線見 M-20261007-ci-section-profile（原 integration 322.540s）；依實測切為 plan（9b–12b）／review（12bb–16）／runtime（turbo–結尾）。新版完整 parallel wall time 136.994s，core／ship_state／plan／review／runtime 為 42／56／104／137／116s；最長 shard 較前版 integration 的 332s 約縮短 59%。新版 serial wall time 414.120s；來源 fingerprints 前後相同，raw／timings／rebuild script 與逐條集合比對位於 /tmp/ci-shard-optimization.s1bblvei/。此為單次本機驗證，不把比例當 GitHub runner 保證。
- **下一步**：依本輪 `$project --merge` 準備語意提交與 PR，執行雙 OS required CI 並讀取 GitHub macOS 實際 wall time；CI 通過後結案本項、驗完成紀錄並依授權合併與清理自身分支。仍未 commit／push，不宣稱 Ubuntu／provider 或 native/model 已驗證；runtime 工作維持 active。
- **關聯**：M-20260916-ci-test-sharding; docs/testing-contract.md

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
