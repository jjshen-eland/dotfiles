# /project 流程減量：依風險分層重訂驗證與交付流程（#285）

- 日期：2026-10-12
- 工作項：issue-285-project-process-reduction
- 狀態：approved
- 種類：implementation plan
- Writer／Dossier Steward：`claude:delivery-overhead`（前任 session 已停止，使用者依序指派本 session 接續）
- Workspace：`branch=docs/process-redesign-assessment`（本計畫與決策紀錄）；各步實作另開 branch
- 基線：origin/main `8c31ebd`
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
  路徑與觸發詞分類；誤差 ±5–10 個百分點，Claude 10-10 前無本機 transcript。
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
    10 次 merge 中 8 次 false STOP。
  - wait-required-enrollment：0 次攔截、3 次誤擋已授權 merge。
  - branch-first.sh：未找到實地攔截。
  - test-evidence：2 次 NEED_TEST，均未抓到失敗測試；1 次以新 snapshot 配舊 log 判 REUSE 後撤回。
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
2. **移除 test-evidence 沿用協定**：`/project` 改為一律重跑選中模組（小改動約 19 秒），移除 REUSE／NEED_TEST
   判定與 snapshot 核對步驟及其專屬測試。驗收：同一固定小改動的 Log 耗時與 reader bytes 下降，測試仍以 exit code
   判綠紅、選測錯誤或空集合不得假綠。
3. **ship-state STOP 與 enrollment 逐條清點**：列出每個 STOP 的實地攔截／誤擋紀錄；0 攔截且有其他機制涵蓋者移除。
   `wait-required-enrollment.sh` 先實測 GitHub 在 required checks 未回報前是否拒絕 merge（需另經具名授權開測試
   PR）；拒絕則移除 helper。保留 default branch、protection、doc audit、trusted core mismatch。驗收：每個移除項
   附攔截紀錄與涵蓋機制；ship-state 測試對保留的 STOP 仍有 RED。
4. **紀錄減量**：PR 已承載的實作結果不另寫 M；merge 後的結案不另開補記 PR（併入下一個 PR 或省略）；D／X 照舊。
   同步調整 `log-prepare.md`、`dossier.md` 與流程規定的紀錄（endpoint 未達成的 milestone、移交 conditional owner）。
   驗收：固定小改動的 Log 不再產生紀錄專屬 commit／PR；`find` 對既有主題的命中不退步。
5. **縮減 reference**：依前四步移除的分支縮減 `/project` 必讀 reference（現為 92–108 KB，`log-prepare.md`
   49,941 B 最大）。驗收：以評估同一回溯方法量改善前後的讀取量與耗時。
6. **端到端量測**：沿用原第 4 項方法，取改善後一筆真實小改動交付（不為量測製造交付），與 51 次基線比較。

## 不做

- 不新增 gate 或機檢；分批部署照現行做法進行。
- 不改受信任 scanner（fleet byte-identical）與 kernel managed block；budget 維持現行「觸發即升級距」。
- controller 測試不單獨刪，隨所測腳本一起移除；對當下語料判定的 gate 型測試依攔截與誤擋紀錄個案決定
  （D-20261012-title-free-recall-ratchet-retired、D-20261012-live-corpus-ranking-tests-kept）。
- 不做紀錄撰寫規則與 Phase 3 觀察（D-20261012-record-rules-dropped），不清理 `docs/testing-contract.md` 的事件敘述。
- Claude 端沒有 push／merge 機械攔截是已知缺口；2026-09 起無實地事故，本計畫不補。

## 審查路由

步驟 2–4 會改變 `/project` 的放行／攔下行為，符合 deep-plan §1a，實作前各跑一批；NO-GO 若是文件措辭或細節，
修進計畫後直接實作，以 RED 測試加 deep-review 審實際 diff 承接，不 restart（D-20261012-deep-plan-full-review-routing）。
步驟 1、5、6 不需完整審查。

## 寫入範圍

`.doc-governance.json`、`shared/skills/project/`、`claude/skills/project/`、`codex/skills/project/`、`tests/`、
`docs/testing-contract.md`、本計畫、STATUS.md 第 3 項、`docs/archive/`。`tests/` 與 `docs/testing-contract.md` 與
STATUS 工作項「Setup 工具與 agent shell 環境對齊」重疊，同一 steward 依序進行。
