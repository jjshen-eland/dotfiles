# /project 流程減量：依風險分層重訂驗證與交付流程（#285）

- 日期：2026-10-12
- 工作項：issue-285-project-process-reduction
- 狀態：implemented
- 種類：implementation plan
- Writer／Dossier Steward：`claude:delivery-overhead`（前任 session 已停止，使用者依序指派本 session 接續）
- Workspace：各步實作各開 branch，現行 branch 以 STATUS.md 第 3 項為準
- 基線：評估於 origin/main `8c31ebd`；第 1 步合併後為 `362db97`
- 需求來源：使用者 2026-10-12 要求以資深工程師從頭設計的角度評估本 repo 的提交、驗證與 CI 流程（依風險分層），
  並決定 #285 第 3、5、6 項去留；評估後選定 D-20261012-record-rules-dropped、
  D-20261012-dotfiles-active-item-contract-off、D-20261012-project-reduction-scope、
  D-20261012-deep-plan-full-review-routing。取代 `docs/plans/2026-10-08-workflow-verification-economy.md`。

## 目標

gate 只放在「錯了代價高、實際發生過、能機械判定」的地方；流程本身（L5）壓到足以支撐部署腳本、agent 契約、
受信任 scanner 的最小量。以真實交付的「交付指令→最終回報」耗時與讀取量驗收，不以文件字數或測試數驗收。

## 評估摘要（2026-10-12，唯讀）

分析腳本與原始輸出在評估 session 的 scratchpad，不入庫；下列數字附重現方法，暫存遺失時以方法重算，不補造。

| 層 | 實際發生過 | 真正抓到問題的機制 | 這層需要的 |
|---|---|---|---|
| L1 部署腳本（→14 台） | 約 17 件逃到主機，發現者都是部署輸出、canary 或使用者；實質受損為 4 台少裝工具（setup stdin）與 14 台 UI 重複列 | 隔離 HOME 行為測試、雙 OS CI、canary 與分批部署、fail-closed 預檢 | 模組行為測試、平台敏感部分雙 OS、分批部署＋冪等 check |
| L2 agent 契約與 skill | 2026-07～08 實地違反 kernel 約 6–8 件，09 月起實地 0 件（只在 eval） | 機械 hook（pre-commit guard、Codex outward gate）、opt-in native eval | 安全底線靠機械 hook；prose 規則以 native eval 驗行為 |
| L3 受信任 scanner | 其他 repo 誤擋／漏放約 8–10 件 | scanner 確定性回歸測試 | 保留回歸；少改、批次改 |
| L4 文件與紀錄 | 有實際後果的都來自規則文件或 skill 寫錯；未找到 D／X／M 格式缺陷導致做錯事的實例 | xref、append-only、`find` | 便宜的 xref 與 append-only 檢查 |
| L5 流程本身 | 2026-09-01 起約 176 小時中流程相關約 53%、送出 24%、產品＋機隊約 12% | — | 壓到最小 |

主要證據（重現方法）：

- 工作量：2026-07-01 起 first-parent 614 顆 commit，動到部署產品 51 顆（churn 3.8%）、只改紀錄 239 顆；131 顆
  fix 有 112 顆修流程；281 個 merged PR 中 46 個只改紀錄。方法：`git log --first-parent --numstat origin/main`
  依路徑分類；`gh pr list --state merged --json files`。
- 工時：Codex／Claude 本機 transcript 以「user 訊息到下一則 user 訊息」分段（959 段），扣 >30 分鐘間隔，依修改
  路徑與觸發詞分類；誤差 ±5–10 個百分點；cwd 為 dotfiles 的 Claude session 在 2026-10-10 以前本機只有零星空 session。
- 送出成本：51 次真實 `/project`／`$project` 送出，扣 CI 與使用者等待後中位 760 秒；讀 reference 87 秒
  （14.7%）、狀態偵測 96 秒（11.7%）、寫紀錄 47 秒（5.7–8.9%）、本地測試與證據 179 秒（27%）；每次實讀流程
  reference 中位 142 KB、16 次 reader call。10-08 後 Codex 送出中位 338 秒，讀 reference 75 秒成為最大固定成本。
- CI：2026-09-12～10-11 共 155 個 run、38 次失敗 attempt；本地綠而 CI 紅的產品 bug 3 個（PR #222：Ubuntu GNU
  `stat`、macOS deep-plan launcher 兩個 cleanup 缺陷），其餘 35 次是測試自身（計數 manifest、SIGPIPE、macOS
  時序 fixture），主因已在 PR #291 與 M-20261011-pipe-grep-herestring-local 移除。PR 建立到 merge 中位 4.5 分。
  branch protection 只要求兩個 suite check、enforce_admins，不要求 review。
- gate 攔截紀錄（archive、issue／PR、transcript）：
  - 全域 pre-commit guard：transcript 中至少 2 次實地擋下在 main commit（2026-09-14 kgi-judicial、10-09 kapi-infra）。
  - steward-authority：實地 3 次，都是自家漏建 active steward；M-20260928-project-merge-production-red-captured 記錄
    10 次 `$project --merge` 中 8 次在 shipping 前停下，來源是 3 個 repo-set 與 7 個 actor／workline／resume 問題（不全是 steward-authority）。
  - wait-required-enrollment：archive 記錄 3 次誤擋已授權 merge；它是等待工具而非攔截 gate，2026-10-12 補量實際
    執行時 ENROLLED 33 次（見第 3 步），先前「0 次攔截」的說法用錯衡量方式。
  - branch-first.sh：未找到實地攔截。
  - test-evidence：archive 記錄的 2 次 NEED_TEST 均未抓到失敗測試；1 次以新 snapshot 配舊 log 判 REUSE 後撤回（全部
    verdict 次數見「第 2 步細節」，兩者範圍不同：此處是攔下失敗，彼處是判定次數）。
  - loaded／surface budget：0 次攔截，3 次觸發都調高上限。
  - deep-review 審實際 diff：有真實程式 bug（測試會 `rm -rf` repo、secret 洩漏、handoff 整檔覆寫）。
  - deep-plan：文件型計畫不收斂（第 3 項 6 批 8 輪全 NO-GO，約 4.5 小時 active，reviewer 只佔約 1.1 小時）。
- STATUS：2026-09-01 起 261 個版本，17 版同時有兩位 Writer（全在 2026-10-08～10 同一對 session），單一版本的
  steward 恆為一位、共出現 76 個 session 代號，正式移交 1 次（D-20261010-transfer-delivery-overhead）。方法：
  `git log --since=2026-09-01 -- STATUS.md` 逐版抽欄位。
- active-item contract 關閉實測：`git clone --no-local` 後刪除 `.doc-governance.json` 的
  `status_schema.active_item_contract`，`audit --ship` OK、`steward-authority.py` 回 `NOT_APPLICABLE`（authority.md
  規定可繼續），content／project／document-contract 模組 exit 0。

## 步驟

每步各自開 branch、各自驗收、可單獨回退；前一步合併後再開始下一步。會改全機隊共用 skill 的步驟（2–5）依
`claude/skill-building-guide.md` 與 `docs/skill-portability.md` 重跑受影響的 eval 情境，另以同一個固定小改動在
Claude Code 與 Codex 各實跑一次 Log，比對改前改後的行為、reader bytes 與耗時。

1. **dotfiles 關閉 active-item contract**：刪除 `.doc-governance.json` 的 `status_schema.active_item_contract`。
   驗收：`audit --ship` OK、`steward-authority.py` 回 `NOT_APPLICABLE`、`./tests/run.sh --base origin/main` 通過。
   STATUS 現有四欄位暫保留（無害），第 4 步調整 dossier 規定時一併決定。回退：還原該行。
2. **移除 test-evidence 沿用協定**（D-20261012-test-evidence-removal）：Log 收尾一律在最終 commit set 上執行
   target repo 的測試指令，不沿用先前結果；細節見下節「第 2 步細節」。
3. **ship-state STOP 與 enrollment 逐條清點（已完成，不移除；D-20261012-ship-state-stops-kept）**：2026-10-12 以
   transcript 統計實際執行 `ship-state.sh`／`wait-required-enrollment.sh` 的輸出（排除 eval sandbox；dotfiles 數字含開發
   fixture 雜訊，以其他 repo 為準）。doc-governance STOP 在 krepo-common 18 次、ais-infra 5 次；bootstrap 類只在新 repo
   出現少數幾次，防的是首推把錯的 branch 當 default 的不可逆後果；review-terminal 在其他 repo 11 次，含 krepo-common
   在審查以 blocking-findings／blocked-review 收場後的攔截，以及 krepo-mops-disclosure、kapi-infra 的 legacy 訊號
   （已有 #267 結案路徑）；enrollment helper 回 ENROLLED 33 次（成功等到 required check 後才 merge）、UNOBSERVED 5、
   QUERY_ERROR 12、HEAD_CHANGED 4。各組都有實際功能，狀態偵測的時間主要在讀取與解讀輸出而非 STOP 本身，故不移除；
   讀取量改由第 5 步處理。
4. **紀錄減量（不做；D-20261012-record-reduction-dropped）**：2026-07 起 46 個只改紀錄的 PR 多為獨立的 backlog 結案、
   機隊部署結果（git 以外的事件）與早期 STATUS 整理；「merge 後另開 PR 補 milestone」在 2026-10 只有 #305 一次，因現行
   log-prepare 已要求 milestone 隨實作 PR 寫成 endpoint pending。收益小且會牽動 kernel「milestones at event time」與
   `AGENTS.md` portable managed block，不做；STATUS 的四個 coordination 欄位照舊保留。
5. **縮減 reference**：依前四步移除的分支縮減 `/project` 必讀 reference（現為 92–108 KB，`log-prepare.md`
   49,941 B 最大）。驗收：以評估同一回溯方法量改善前後的讀取量與耗時。
6. **端到端量測**：沿用原第 4 項方法，取改善後一筆真實小改動交付（不為量測製造交付），與 51 次基線比較。

## 第 2 步細節：移除 test-evidence 沿用協定

### 依據（2026-10-12 量測，唯讀、啟發式）

2026-10-04 起真實 repo 的 Codex／Claude session（排除 eval sandbox 與 `codex exec`；兩個 runtime 都自 2026-10-04 起
納入，含 kapi-infra 的 Claude session）中，9 個 repo 的 96 個 Log run 有 38 個使用協定。協定成本約 76.6 分鐘（其中
約 72 分鐘是組指令與 evidence JSON 的模型生成時間，helper 執行每次約 0.2–1 秒）；64 次 REUSE 中 34 次發生在剛跑完
同一測試之後，扣除後實際省下約 10.0 分鐘；73 次 NEED_TEST 協定照付、測試照跑。

改為一律執行後新增的成本：48 個沒用協定、run 內也沒跑測試的 Log run，以各 repo 全套測試耗時中位數計約 19.5 分鐘
（dotfiles 20 個約 10.7 分鐘，含刪除 `AGENTS.md` 收尾不重跑句的影響；noop／spec 類 run 也計入，屬高估）。合計淨效益
約 −47 分鐘（前置間隔上限 120 秒時約 −37 分鐘）；9 個 repo 中 8 個為負，krepo-judicial 約 +0.4 分鐘、接近打平。
各 repo 全套測試耗時中位數 11–62 秒，dotfiles 32 秒。

64 次 REUSE 中有 31 次沿用的結果無法對應到可估耗時的測試：doc-governance `audit --ship`（收尾本來就重跑）、ruff、
actionlint、`bash -n`、`uv sync`、docker compose config、deploy `--dry-run`、clean-clone suite、dotfiles 的 native
probe（`/tmp` 下的 clone-native-probe 與 runtime model defaults validation），另約 12 次無法辨識被沿用的指令。

方法：run 起點為含 `$project`／`/project` 的短 user 訊息、終點為下一則真正 user 訊息；協定成本＝helper 呼叫與組
evidence 指令的前置間隔（上限 600 秒）加執行時間；REUSE 省下的時間取同 repo 同一測試指令的實測耗時中位數，同 run
內已跑過者計 0。分析腳本與逐筆輸出在評估 session scratchpad，不入庫；暫存遺失時以此方法重算，不補造。

協定的採用依據是 D-20261003-project-test-evidence-reuse、D-20261003-project-reuse-evidence-boundary、
D-20261004-project-reuse-mechanical-check 與 D-20261004-project-reuse-mechanical-adoption，要解決兩件事：實作已全綠後
Log 又重跑同一測試，以及模型把作者的「All tests passed」摘要當證據（Sonnet 在 prose 修正後仍犯，見
`pressure-tests.md` Scenario 38）。後者在新規則下仍是 prose；改判準後的 native case 只是驗收當下的一次性檢查（opt-in，不會持續執行），不宣稱已消除。

使用者核定接受的殘留風險（2026-10-12）：(1) agent 未實際執行就以摘要宣稱通過——舊 helper 只在 agent 主動送證據時才作用，
不是新增風險；受影響的 9 個 repo 中 8 個有 required status checks（dotfiles 為 classic protection，其餘 7 個為 ruleset），
未執行的測試在 merge 前由 CI 攔下，僅 kapi-nc-v2 沒有 ruleset 與 workflow；CI 內容與本機測試是否相同未逐一核對。
(2) 未在本次 Log 重跑的非測試結果被當成驗收引用——影響紀錄與摘要而非送出的程式；規則要求附當時 commit，讀者可以
`git diff` 核對，但沒有機械檢查。兩者要機械消除都需新增機制（Log 由腳本執行各 repo 測試，或恢復 helper），不採用。

### 變更

1. 刪除 `shared/skills/project/scripts/test-evidence.py`、`claude/skills/project/scripts/test-evidence.py`（逐檔連結；
   Codex 端是整目錄連結，隨之消失）、`tests/project-test-evidence-test.py`，以及 `tests/modules/project.sh` 的對應
   檢查與共用腳本清單項、`tests/suites.json` route 中的該路徑。
2. `shared/skills/project/references/log-prepare.md` Step 3 的「先沿用可用的測試證據，再補驗」段改為：
   - 在送出的最終 commit set 上執行 target repo contract 宣告的測試與檢查指令（repo 提供選測時依其規則涵蓋整批
     變更，不只最後一顆 commit），以 exit code 判定；不沿用先前結果，也不以作者摘要代替執行。
   - repo 沒有宣告時依專案既有測試入口；都沒有就在摘要寫明未驗。
   - 任一指令非零：不進 Step 4，先修正本批引入的問題並重跑；超出本批範圍則停下回報。
   - 未在本次 Log 重跑的結果（opt-in native eval／probe、部署 dry-run、clean clone 等）只能附上當時執行的 commit
     引用，不寫成本批驗收。opt-in native eval 不在 Log 重跑，除非 repo contract 要求。
   - 保留 kernel「混檔拆分後 clean clone」的條件式驗證與當前 PR HEAD 的 required CI。
   同步修改：同一 Step 的「核對／補驗完成後……摘要仍交代沿用或補驗的結果」改為交代本次執行的指令與結果；
   `workflow.md` 階段表 Log 列的「測試證據」改為「測試」。
3. `shared/skills/project/references/pressure-tests.md`：Scenario 38 改寫為「收尾在最終 commit set 實際執行測試，
   不以摘要或先前結果代替」，舊判分保留為歷史段並指向 D-20261012-test-evidence-removal；Scenario 39 中「既有有效
   測試須呼叫 evidence helper 並沿用」與 `tested` 對照句改為新判準。
4. `tests/project-reference-eval.py` 的 `tested`／`test-changed`／`test-unknown`／`docs-merged`／`docs-mixed` 五個 case
   保留 fixture（含 `verification-runs.log` 觀察器），只更新判準：模型階段在最終 tree 上實際執行 repo 測試指令至少
   一次（`verification-runs.log` 比 setup 結束時的筆數至少多一筆——tested 類 1 筆、docs 類 2 筆——多於一筆記為成本，`docs-merged` 另看 `doc-runs.log`，與原始 tool trace 交叉核對）、沒有呼叫 test-evidence、
   `test-unknown` 不採信摘要、`docs-mixed` 的執行涵蓋前面的程式 commit。`docs/testing-contract.md`「Project reference
   native eval」中描述這組 case（tested 類、docs 類）與 `project-test-evidence-test.py` 的三段同步改寫，後者刪除。
5. `AGENTS.md`「Repo specifics」測試項中「同一份程式／測試輸入已驗過，不因收尾紀錄文字變更再重跑程式全套；文件
   仍驗當前內容。」一句刪除（需使用者核定此處措辭；以 Edit 修改，不動 managed blocks）。刪除後收尾依同項既有規則
   以 `./tests/run.sh --base <本批基線>` 驗整批差異。

### 驗收

- `rg -n 'test-evidence|REUSE|NEED_TEST|input_snapshot|tested_commit|evidence helper|沿用或補驗|測試證據'`（排除
  `docs/archive/`、`docs/plans/`）只剩：Scenario 38 歷史段與 `pressure-tests.md` 其他場景既有的驗收歷史敘述、
  STATUS.md 第 2 項的歷史敘述，以及 `project-reference-eval.py` fixture 中作為誘餌的舊格式先前結果（`prior-verification.json` 欄位）；逐筆列入報告。
- `./tests/run.sh --base origin/main` 通過、`audit --ship` OK；`log-prepare.md` 改前改後 bytes 列入報告。
- 行為：改後以 `tests/project-reference-eval.py` 的 `tested`、`test-unknown`、`docs-mixed` 三個 case，各跑 Claude Code
  樓層模型（Sonnet，依 `claude/evals/README.md` 模型樓層政策）與 Codex production model 一次，依上列判準判分；
  改前行為以 Scenario 38 既有紀錄為對照（`tested` 額外執行 0 次）。記錄 alias、resolved model、effort、CLI 版本、
  reader bytes 與耗時。
- 散佈：本機 `~/.claude/skills`、`~/.agents/skills` 連到主 checkout，實作 branch 在主 checkout checkout 時即對本機
  所有 session 生效；其他主機於合併並 dotsync 後生效。生效前已載入舊指令的 session 呼叫不存在的 helper 會得到
  exit 2，舊文字會解讀成檢查錯誤而停下，屬暫時、會自行消失的影響，不另做相容殼。

### 回退

revert 該 PR 即恢復 helper、測試與指令；無資料遷移。

## 不做

- 不新增 gate 或機檢；分批部署照現行做法進行。
- 不改受信任 scanner（fleet byte-identical）與 kernel managed block；budget 維持現行「觸發即升級距」。
- controller 測試不單獨刪，隨所測腳本一起移除；對當下語料判定的 gate 型測試依攔截與誤擋紀錄個案決定
  （D-20261012-title-free-recall-ratchet-retired、D-20261012-live-corpus-ranking-tests-kept）。
- 不做紀錄撰寫規則與 Phase 3 觀察（D-20261012-record-rules-dropped），不清理 `docs/testing-contract.md` 的事件敘述。
- Claude 端沒有 push／merge 機械攔截是已知缺口；2026-09 起無實地事故，本計畫不補。

## 審查路由

步驟 2 會改變 `/project` 的放行／攔下行為，符合 deep-plan §1a，實作前跑一批（第 3 步清點後不改程式，第 4 步不做）；NO-GO 若是文件措辭或細節，
修進計畫後直接實作，以 RED 測試加 deep-review 審實際 diff 承接，不 restart（D-20261012-deep-plan-full-review-routing）。
步驟 1、5、6 不需完整審查。

## 寫入範圍

`.doc-governance.json`、`shared/skills/project/`、`claude/skills/project/`、`codex/skills/project/`、`tests/`、
`docs/testing-contract.md`、`AGENTS.md`（僅第 2 步細節第 5 點那一句，需使用者核定）、本計畫、STATUS.md 第 3 項、
`docs/archive/`。`tests/` 與 `docs/testing-contract.md` 與
STATUS 工作項「Setup 工具與 agent shell 環境對齊」重疊，同一 steward 依序進行。
