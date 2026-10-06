<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-06)

---

## 進行中

### 2. Runtime 目錄收斂與 legacy 遷移 🆕

- **Writer**：`codex:runtime-layout-convergence`
- **Workspace**：`branch=refactor/runtime-layout-convergence`
- **Write Scope**：scripts/, setup-mac-env.sh, setup-linux-env.sh, claude/settings.json, shared/skills/handoff/, claude/skills/handoff/, codex/skills/handoff/, tests/, README.md, codex/README.md, docs/repo-guide.md, docs/add-new-host.md, docs/skill-portability.md, docs/testing-contract.md
- **Dossier Steward**：`codex:runtime-layout-convergence`
- **Context**：同一版 dotfiles 的新裝與既有主機升級尚未收斂：setup 與 dotsync 的 runtime 部署涵蓋不同，本機 Claude skills 曾需手動補入口；Codex rules 有整目錄連結與保留本機授權紀錄的共存形式；handoff 仍依 canonical／legacy 目錄存在情況選擇 store。使用者要求把歷史差異集中遷移，減少各腳本與 skill 的永久相容分支。
- **Goal**：同一版 dotfiles 在 macOS／Linux 的乾淨新裝、既有環境升級與重跑部署後，得到相同的受管理 runtime 結構、資料位置與可觀察行為；保留原生／第三方內容與明示 override，完成納管主機遷移後清理本項可移除的 legacy 執行分支。
- **Acceptance Criteria**：
  1. 在 repo 的既有權威文件定義唯一正式結構與管理邊界：Claude skills 採實體 discovery root、repo entries 逐項連結並保留第三方內容；依使用者本輪澄清，權威 `claude/settings.json` 停用雲端 skills 同步，eagle08 已識別的 synced cache 移出 repo／discovery 並留備份，settings.json 檔案 symlink 保持。Codex entries 位於 `~/.agents/skills`，system／第三方入口保留其原生位置；Codex rules 採實體 root、repo 規則獨立連結、runtime 授權紀錄可寫；handoff 預設 store 固定為 `~/.agents/handoffs`。Codex config 維持既有三層合併契約。
  2. macOS／Linux setup、dotsync 的本機與遠端流程、brewup／sysup 的適用入口共用同一組部署 helper；CLI 未安裝時也能準備正確結構並明示能力缺項，不因新裝／升級分成不同 layout。
  3. 遷移工具可盤點、預演、備份、執行、驗證與安全重跑；涵蓋舊實體副本、整目錄連結、逐項連結、缺少新入口及部分完成／中斷狀態。備份留在 discovery root 外，來源 ownership 不明、同名內容衝突、外部 writer 或無法取得一致 snapshot 時停止該目標，不覆蓋或自行選邊。
  4. handoff 舊 store 的 active／archive 與相關檔案完整遷移到正式 store；驗證內容、checksum／錨點、survey／predecessor／verify／consume 行為，不因搬移宣稱舊 claims 已重新授權。canonical 與 legacy 同時存在時，依逐檔盤點處理；有衝突即保留來源並回報。
  5. 盤點本項的 legacy 相容分支與仍存續的資料契約。store 路徑 fallback 在遷移驗收後移除，正常 skill 固定使用正式位置；未遷移環境明確回報需要升級。舊 archive 命名／metadata 格式須另有無歧義轉換與行為證據才移除 reader 相容；仍需保留者逐項記錄原因與移除條件。
  6. 以隔離環境比較乾淨新裝、各受支援舊結構升級與部署重跑的受管理路徑種類、link identity、設定層級、可寫資料位置及載入結果；確認第二次執行不再改動。覆蓋衝突、並行 writer、失敗／中斷恢復與回滾，證明登入／hook trust／個人規則／第三方內容未遺失或意外進入 repo；明示停用且已識別的雲端 cache 清理由本輪具名範圍處理，不擴成刪除其他未知 skills。
  7. 修正合併至 `origin/main` 且取得當批部署授權後，盤點並驗收現行 inventory 的 14 個目標（本機 macs 計一次）：revision、正式結構、共用資源、舊入口殘留與資料保全皆有逐台證據；有原生 CLI 的端驗證實際載入，缺 CLI／連線／信任者明示能力邊界，不以設定檔已存在冒充功能可用或全機隊完成。
  8. 實作前建立可重現的新裝／升級差異 fixture；必要的 handoff behavior eval 與雙端驗證、`./tests/run.sh`、文件與交叉引用檢查通過。涉及既有相容契約的變更，以新 event-time record 明確取代相關舊決策的對應部分，保留歷史證據。
- **Constraints**：使用者已以「開工」授權本項本地實作與驗證；前輪 `$project --merge` 將既有規劃文件與 active assignment 隨 #271 修復提交保存，不代表本項 implementation 或 fleet migration 已完成。本項後續實作的 shipping／部署仍依當批具名授權與 repo 規則。CLI 安裝／更新、套件升級、SSH／inventory 改版及其他 skill 的獨立 legacy 契約不納入本項。保留 config.local.toml 與合法 HANDOFF_DIR override、雙薄入口／單一 neutral core、handoff claims／frontmatter gate；不關閉安全檢查或代為信任 hooks。修改 skill 前依 AGENTS.md 的 authoring route；移除舊 store resolver 前須以安全 migration／locking 的行為證據滿足既有重議條件。
- **進度**：PR #273 已合併 `744356df`，負 UID 修正已由 PR #275 合併 `ee9312d`。首批 12 目標已通過 common entry apply／verify／rerun、source／個人資料保全與 retained receipts 核對；七檔 handoff 與 db01 空 archive 保留 content／mode／mtime。eagle08 本輪依明示授權終止兩個測試 daemon（TERM，未用 SIGKILL）、還原 settings runtime drift，將 284 entries 的 synced cache 移出 repo／discovery 至私有備份；其後更新至 `ee9312d`，apply／verify／rerun 與雙端原生 discovery 全通過。因此 layout 已驗收 13／14。eagle08 的 Codex config 首次由既有 helper 重新序列化，managed／unmanaged 語意均相同，重跑 roots／設定／receipts 含 inode 相同；native initialize 後僅 .claude.json cache 改變。登入、個人設定、第三方、repo source 保留，settings.json 檔案 symlink 保持。9 台 Codex／11 台 Claude metadata-only discovery 驗出全部 11 repo adapters（macmini 額外四個 plugins 保留）；無 CLI 明列能力缺項，未驗 model turn 或自動 rules enforcement。證據見 plan、M-20261006-runtime-layout-fleet-twelve-accepted 與 M-20261006-eagle08-runtime-accepted。macs 尚未 apply，原觀測 13 writers／18 檔 legacy handoff，須 fresh 重驗。權威設定原缺雲端 opt-out，本輪補 syncClaudeAiSkills=false；新設定尚未交付，不把 cache 清理或 temporary native probe 冒稱永久停用。先前 signed UID 修正的完整 serial／parallel 各 1576 PASS／0 FAIL；本輪新設定的完整 serial 亦 exit 0、1576 PASS／0 FAIL，376 tracked inputs 前後相同；測試後補驗收紀錄，再另驗文件。
- **下一步**：權威同步 opt-out 與 13／14 驗收紀錄已完成本地驗證，另外十二台 repo／runtime 的 synced／syncd 四個路徑全部不存在，工作樹乾淨（M-20261006-runtime-cloud-sync-validated）。使用者本輪明示先驗證、再提交及 dotsync；先建立本地 commit，待本批具名 shipping endpoint 將修正交付至 origin/main，才執行已授權的 dotsync。macs 待 runtime／daemon 正常停止後，由普通 terminal 重新盤點並執行 common entry；eagle08 具名處置與 layout 驗收已完成，不擴成其他主機的 kill／刪除授權。inventory 外兩部 MacBook 依 D-20260917-terminal-macbooks-outside-inventory 維持本機自主更新，runtime 尚未量測，流程見原 plan；不計入 14 台已驗數，追加驗收範圍尚待確認。14 目標遷移驗收前保留 handoff legacy fallback；移除前亦須釐清額外終端的相容影響。本項仍 in-progress。
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
