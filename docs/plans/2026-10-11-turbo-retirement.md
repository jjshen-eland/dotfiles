# 移除 turbo skill 與其他 skill 的耦合

- 工作項：STATUS item 5「移除 turbo skill 與其他 skill 的耦合」
- 日期：2026-10-11
- 狀態：draft
- 種類：implementation plan
- Writer／Dossier Steward：`claude:delivery-overhead`
- Workspace：實作時建立 `refactor/turbo-retirement`，在 scratchpad 的獨立 git worktree 進行，見「提交與分支」
- 基線：`9f24f9646d77cd522be279942adcaa9dd49f1437`（origin/main）；item 5 的 Spec、本計畫與相關決策目前只在
  `perf/delivery-overhead-verification` 的未提交工作樹，提交方式見「提交與分支」。
- 需求來源：使用者 2026-10-11 判斷 turbo 的配合讓其他 skill 變複雜，要求移除並處理相關 skill 的關聯（`/project spec`）；
  取捨見 D-20261011-turbo-retirement-choices、D-20261011-turbo-direct-deletion、
  D-20261011-primary-scope-eval-cross-runtime；計畫審查兩批 NO-GO 後依 D-20261011-turbo-plan-nogo-proceed 修正並實作，
  以 deep-review 審查實際 diff。

## 背景與證據

turbo 於 2026-10-06 由 `acfc037` 加入（D-20261005-turbo-delegated-controller、docs/plans/2026-10-05-turbo-skill.md）。
本機 session 紀錄中，使用者訊息真的下 `$turbo on|off|status` 的情形：Codex 6 個 session，5 個的 cwd 在
`/private/tmp/turbo-*` 測試沙盒，真實使用 1 次（`~/Projects/kapi-nc-v2`，2026-10-06）；Claude Code 6 個 session，
全部在測試沙盒，真實使用 0 次。其他主機未量，結論只代表本機。

## 目標與非目標

目標：一批移除 turbo skill 與只服務它的 deep-review `native-review`；deep-plan、deep-review、project、hooks、
全域指令與測試不再依賴或提及 turbo。依散佈步驟執行 `ensure-runtime.sh` 並重開 session 的主機不再有 turbo
hooks 或 skill；未重開或只 pull 的主機會遇到 hook 錯誤，修復方式在「散佈」明列（D-20261011-turbo-direct-deletion）。

非目標：

- 不改 deep-plan、deep-review、project 的一般流程行為；被移除的只有 turbo 專用分支、API 與 `native-review`。
- 不改 `scripts/ensure-runtime-layout.py`（item 2 範圍）、kernel managed block、受信任 scanner、歷史紀錄與其他
  docs/plans 檔；本計畫自身只依生命週期更新狀態。
- 不縮減跨 runtime 證據：primary-scope eval 保留 Codex 與 Claude 兩臂。
- 不保留過渡空殼，也不設等待期（D-20261011-turbo-direct-deletion）。
- 不處理 #285 第 3 項；它排在本項之後（D-20261011-record-volume-scope-narrowed）。

## 盤點

`git grep -il turbo HEAD -- ':!docs/archive' ':!docs/plans'` 命中 31 個檔；另加入只服務 turbo 的 `native-review`。

| 類別 | 檔案 | 處置 |
|---|---|---|
| turbo 本體 | `shared/skills/turbo/`（references、evals.md、scripts/turbo-state.py）、`claude/skills/turbo/`、`codex/skills/turbo/` | 全部刪除 |
| 專屬測試 | `tests/turbo-mode.py`、`tests/turbo-native-eval.py` | 刪除；涵蓋非 turbo 行為的案例處置見下 |
| deep-plan 程式 | `shared/skills/deep-plan/scripts/review-state.py`：`turbo_module` 與只供它使用的 importlib、三處選用 checkpoint、`delegated_reentry`、`delegated-reentry` 子命令與只供它使用的 `--input` | 刪除 |
| deep-review 程式 | `shared/skills/deep-review/scripts/review-control.py`：`turbo_module`、dispatch 的 `live_context`／checkpoint 與 `native_required`／`native_claude` 設定、finish 的 `native_proof` 檢查與 `native_report`、`new_batch` 的 delegated 分支與只供它使用的 `before_subject`、`refresh_subject`、只被這兩條路徑呼叫的 `invalidate_open_dispositions`、只由它們寫入的 `next_initial_mode` 讀取與 delegation 欄位、`delegated-reentry`／`refresh-subject`／`native-review` 子命令，以及只供這些路徑使用的 `--expected-state-sha`、`--review-model` 參數，以及只供 `turbo_module`／`native-review` 使用的 importlib；`native-review.py`（Codex 收集邏輯先移入 eval） | 刪除；`new_batch` 的一般（明示授權）路徑保留 |
| deep-review schema | `shared/skills/deep-review/assets/native-review.schema.json`：`native-review.py` 與 eval 兩臂都讀它 | 移到 `tests/fixtures/review-report.schema.json`，只供 eval 使用 |
| primary-scope eval | `tests/review-primary-native-eval.py`：Claude 臂以 `claude -p --json-schema` 收集；Codex 臂經 `native-review`；`TURBO_RUNTIME` 清除與 docstring | 兩臂保留並改讀搬移後的 schema；Codex 臂改用從 `native-review.py` 移入的收集函式，沿用其 `codex exec` 參數（`-a never`、`-s read-only`、`--ephemeral`、`--ignore-user-config`、`--ignore-rules`、停用 hooks／plugins／multi_agent／skill_search、`--output-schema`）、`DEEP_REVIEW_REVIEWER_PROCESS`、子行程環境清除、執行前快照與獨立 thread 檢查，收集在 eval 自己的行程進行，報告與 raw log 存於 eval 目錄，再以一般 `finish` 提交，不寫 controller journal 的 native 欄位；搬移的環境清除清單去掉 `TURBO_RUNTIME`；schema 一併複製進 eval 的 source bundle 並納入 source hash；evals.md 註明 c1–c6 歷史矩陣取自已移除的 native-review transport |
| skill references | deep-plan `workflow.md`（§5 turbo 續批）、`controller.md`（turbo 續批段）；deep-review `workflow.md`（turbo 委任兩段）、`control.md`（native dispatch、`delegated-reentry`、`refresh-subject` 段）、`evals.md`（primary-scope 一節：fake transport 機械重建描述與「Codex 用正式 native-review」說明）；project `ship-policy.md`（說法表 turbo 列與 Turbo action delegation 段）、`spec-workflow.md` 第 5 點 | 刪除 turbo 與 native-review 分支；evals.md 改寫為搬移後的 schema 與兩臂收集方式 |
| Claude hooks | `claude/settings.json`：SessionStart、UserPromptSubmit、PermissionRequest、Stop、SessionEnd、SubagentStop、PreToolUse(Bash) 各一個獨立 turbo group | 刪除這 7 組；既有 runtime drift 不得一起 stage |
| Codex hooks | `codex/config.toml`：SessionStart、UserPromptSubmit、PermissionRequest、Stop、Interrupt、SessionEnd、PreToolUse 各一個 turbo hook | 刪除這 7 個 |
| 全域指令 | `claude/CLAUDE.md` 的 turbo 委任行（PR／Git 節，非 kernel）、`codex/AGENTS.md` 的 turbo 委任行（Explicit workflow pointers） | 刪除該行 |
| 共用腳本 | `scripts/agent-turn-end-timestamp.sh` 的 codex／claude 分支以 `turbo-state.py notice` 讀 stdin 並產生 label | 改為 `cat >/dev/null` 讀掉輸入並用固定 `等待輸入起點`；turbo 關閉時 `notice` 本來只回傳這個值 |
| 測試與路由 | `tests/suites.json`（turbo 模組、7 條含 turbo 的路由、`name_only_mentions` 的 session.sh 項、schema 搬移後的新路徑）、`tests/test_suite.py`（heavy 集合、ci_platforms 期望）、`tests/modules/guidance.sh`（portable skill 清單）、`tests/modules/session.sh`（hook 組合測試）、`tests/review-primary-scope.py`（`TURBO_RUNTIME` 清除與 native-review incomplete 案例） | 同步更新；native-review incomplete 案例改為以假 `codex` 執行 eval 的 Codex 收集，斷言 eval 目錄保留 incomplete structured report 與 raw log、收集失敗；`shared/skills/turbo/*` 路由隨目錄刪除；eval 與 schema 新路徑路由到 review-skill（`tests/review-primary-scope.py` 會執行 eval 並讀 schema），並以刪除實驗確認 consumer；route drift 須通過 |
| 文件 | `README.md`「Turbo 自主執行」節；`STATUS.md` 的 item 3 Context 與 item 5 | README 節刪除；STATUS 為例外 |

tests/turbo-mode.py 中與非 turbo 行為相關的案例及處置：

- `test_native_lifecycle_hooks_are_synchronous_and_keep_other_hooks`：wait4me 與 timestamp hook 的接線另由
  `tests/modules/session.sh` 覆蓋，刪除後以該模組為準。
- `test_timestamp_does_not_call_autonomous_continuation_waiting` 斷言的是 turbo 專屬 label，不搬移；改在
  session.sh 新增案例（見「執行順序」第 2 步）。
- `test_local_heredoc_*`、`test_outward_*` 測的是 turbo 的 summary guard；`scripts/outward-action-gate.py` 本身
  由 hooks 模組與 `tests/project-push-command-test.py` 覆蓋，不搬移。
- CodeReentry 的 native-review 成功與失敗保留案例：`native-review` 一併移除，不搬移。

## 殘留檢查

實作完成時執行一次 `git grep -il turbo -- ':!docs/archive'`（只看 tracked 檔，不掃未追蹤的 deep-plan journal），
結果附在 PR 說明；不做成常駐測試，避免永久禁止這個字串。允許的命中只有：

1. `STATUS.md`：item 5 本身與 item 3 Context 的歷史量測；item 5 結案時移除。
2. `docs/plans/` 下所有檔：已凍結計畫不得修改，進行中的計畫引用歷史量測。

## 提交與分支

1. 在主 checkout 的目前分支 `perf/delivery-overhead-verification` 先提交 item 3 與 item 5 的 dossier 變更（STATUS、兩份計畫、
   D-20261011 的六筆決策：record-volume-plan-choices、record-volume-scope-narrowed、turbo-retirement-choices、
   turbo-direct-deletion、primary-scope-eval-cross-runtime、turbo-plan-nogo-proceed）。
2. 以 `git worktree add <scratchpad>/turbo-retirement -b refactor/turbo-retirement <第 1 步 commit>` 建立獨立 worktree，
   全部實作與測試在其中進行；主 checkout 與本機 hooks 在合併前不受影響。第一顆 commit 更新 STATUS item 5 的 Workspace。
   兩個 branch 的 PR 順序與合併方式在送出時依使用者授權決定。
3. worktree 是新的 checkout，不含主 checkout 的 runtime drift；commit 後以 `git clone --no-local` 乾淨 clone 確認
   settings JSON 合法、7 組 turbo hook 已移除、沒有其他 settings 變更。

## 執行順序

1. 動 skill 前先讀 `claude/skill-building-guide.md` 與 `docs/skill-portability.md`，判定 deep-plan、deep-review、
   project 的移植狀態與 eval oracle；只刪 turbo 分支是否需要重跑 behavior eval，結論寫進第 6 步的紀錄。
2. 先寫會紅的檢查，並確認在現行程式下紅：
   - deep-plan `delegated-reentry` 經 argparse 判為 invalid choice（exit 2、stderr 含 `invalid choice`），放在
     `tests/deep-plan-routing.py`（deep-plan 模組）；deep-review `delegated-reentry`／`refresh-subject`／
     `native-review` 同樣斷言，放在 `tests/review-repair-controller.py`（review-controller 模組）。現行程式在應用層
     失敗（exit 1），所以會紅。
   - timestamp 腳本帶 codex／claude 參數時讀掉 stdin、輸出固定 label，且不呼叫 python3：放在
     `tests/modules/session.sh`，以會記錄呼叫的 python3 PATH stub 驗證。
   回歸護欄（改動前後都應為綠）：`tests/review-primary-scope.py` 以假 `codex` 驅動 primary-scope eval 的 Codex
   收集，斷言 incomplete structured report 與 raw log 保留、批次失敗；改動前經 native-review，改動後經 eval 內的收集函式。
3. 依盤點表刪除程式分支、子命令、死碼、references、hooks、全域指令行、README 節與 turbo 目錄；搬移 schema 並
   改寫 eval 兩臂；更新 timestamp 腳本、tests/suites.json 與相關測試。
4. 臨時 HOME 驗證：以含 manifest 與 7 個 turbo hook 的舊版 `~/.codex/config.toml` 為起點，執行
   `ensure-codex-config.py`，確認不再含 turbo 腳本路徑、`hooks.Interrupt` 已移除、wait4me／timestamp／
   outward-action-gate hooks 保留。
5. eval 改寫的可執行性：上述假 `codex` 測試走過 Codex 臂的收集、報告解析與 finish；Claude 臂以假 `claude`
   在同一支測試驗證讀到搬移後的 schema 並傳入 `--json-schema`。完整 opt-in eval 由使用者另行決定是否執行。
6. 寫退役決策紀錄，`關聯` 以 `supersedes:` 列出 D-20261005-turbo-delegated-controller、
   D-20261006-turbo-native-evidence-transitions、D-20261006-turbo-native-report-collection、
   D-20261006-turbo-public-help，以及 D-20261010-ci-controller-platform-evidence 中 turbo 只跑 Ubuntu 的部分；
   D-20261011-turbo-retirement-choices 的 schema 部分已由 D-20261011-primary-scope-eval-cross-runtime 取代。
7. 全套測試、`doc-governance audit --ship`，以及「殘留檢查」的一次性指令。

## 散佈（需使用者另行授權）

本項 PR 合併時，agent 只執行 `gh pr merge` 與刪除 remote branch，不在本機 pull。之後由使用者關閉本機所有
Claude Code／Codex session，在一般終端機於主 checkout 依序執行：移除實作用 worktree、`git checkout -- claude/settings.json`
（依 dotsync／brewup 做法丟棄 runtime drift）、切回 main、`git pull`、`bash scripts/ensure-runtime.sh`、刪除本機
`~/.claude/skills/turbo` 與 `~/.agents/skills/turbo`，再開新 session。沒有執行中的 session，layout 的 writer gate 不會阻擋，
也沒有 session 持有舊 hooks。合併後在同一授權批次立即執行下列散佈，縮短其他主機的 agent 依 session-pull-check 提示
在 session 中途 pull 的空窗。經使用者授權：

1. dotsync 讓 inventory 14 台主機 pull 並執行 `ensure-runtime.sh`。
2. 逐台刪除 `~/.claude/skills/turbo` 與 `~/.agents/skills/turbo`，只在它們是指向 dotfiles 的 symlink 時刪除。
3. 逐台確認 `~/.codex/config.toml` 不含 turbo 腳本路徑、兩個連結不存在。
4. 使用者重開各主機上執行中的 Claude Code／Codex session，並在本機 Codex CLI 以 `/hooks` 確認保留的 hooks 仍受信任。

兩台 inventory 外的 MacBook（D-20260917-terminal-macbooks-outside-inventory）恢復使用時跑 brewup（含
`ensure-runtime.sh`）、刪除兩個連結並重開 session。任何主機出現 hook 找不到腳本的錯誤時，修復方式相同：
跑 `ensure-runtime.sh` 後重開 session。

## 驗證與完成條件

- STATUS item 5 的 6 條 Acceptance Criteria。
- deep-plan、review-controller、review-skill、review-runtime、review-scope、project、hooks、session、guidance、
  content 模組全綠。
- 第 2 步的三項檢查在改動前紅、改動後綠。
- 散佈步驟逐台完成後寫完成 milestone 並移除 item 5。

## 回復方式

`git revert` 該 PR；比照合併後的本機序列，關閉所有 session 後在一般終端機 pull、跑 `ensure-runtime.sh`，再開新 session：`claude/settings.json` 是 symlink，hooks 隨
revert 恢復；Codex 設定由 `ensure-runtime.sh` 重新生成；skill 連結依 source 重建。

## 風險

- 未重開的 session 持有舊 hooks：腳本已刪除，python3 回 exit 2。Claude Code 端 7 個事件都受影響：
  PreToolUse(Bash) 擋下工具、UserPromptSubmit 擋下使用者輸入、Stop／SubagentStop 阻止結束，直到重開；
  Codex 對 exit 2 的處理未驗證。修復方式見「散佈」。
- 只 `git pull`、沒跑 `ensure-runtime.sh` 的主機：Codex 設定仍有 turbo hooks，症狀同上。
- 其他主機若有使用中的 turbo goal，合併後即停止；本機只有一次真實使用，其他主機未量。
- Claude Code／Codex 遇到懸空的 skill 連結時的行為未驗證；合併到逐台刪除之間會短暫存在。
