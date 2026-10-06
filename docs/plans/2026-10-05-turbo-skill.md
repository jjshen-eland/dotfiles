# Turbo skill：依 spec／計畫自主執行到完工

- 工作項：turbo-skill
- 日期：2026-10-05
- 狀態：implemented
- 種類：implementation plan
- Writer／Dossier Steward：`codex:turbo-skill-plan`
- Workspace：`branch=docs/turbo-skill-plan`
- 基線：`2d6b898cbf2317a069f8857c20fcf5d40f61dbdd`；寫計畫前 main 工作樹乾淨，已先建立 feature branch。
- 需求來源：使用者研究 `$turbo on|off|status`，要求同 session 內自行選擇當時最佳方案、持續做到計畫／專案目標完成；包含 permission 的執行時接點，並明確要求 spec／計畫格式配合。
- 2026-10-05 需求補充：可從 deep-plan 開始；deep-plan／deep-review／repo-review 達本批上限時，自主採取最佳建議修正並選 blind／focused 續審；自主選擇及執行適當的 commit／push／PR／merge；判斷無法達標、無法完成或需要重大重構時，可停止並說明原因。
- 本輪交付：使用者於 2026-10-05 同意整合架構並指示開始實作；交付 portable skill 與必要既有 workflow 接點。不啟用本 session 的 turbo，不變更全域 permission；本批尚無 shipping 或部署授權。

## Turbo 目標與完工定義

建立 Claude Code／Codex 共用的 turbo skill。啟用後，在使用者已委派的目標與範圍內，agent 自行處理原本會要求使用者選擇的日常決策，可從既有計畫的 deep-plan 開始，接續計畫修正、重審、實作、code review、修復及交付，直到驗收條件與合適且已授權的終點成立。

本功能包含三件可分別驗收的事：自主決策、跨回合續跑、執行權限準備。只做到「不要問問題」不能宣稱一路完工；跳過 runtime permission 也不能代替交付授權或驗收。

完工以產物、檢查結果及交付狀態判斷。Agent 說「完成」、一次 CLI exit 0、一次沒有提問，都不算完整證據。若客觀條件無法滿足，回報未完成的具體原因與已完成部分；不得改寫驗收條件來結案。

Review 的局部上限是切換到下一個修正／審查決策的 checkpoint，不是 turbo 必然停下等人的終點。Agent 需查證阻擋原因、先補事實或修正，再在有效委派下續批；是否 blind／focused 依變更與風險判斷。這需要同步擴充既有 review workflows／controllers，不能只在 turbo prose 宣稱原上限已解除。

## Turbo baseline 與已知 runtime 能力

- 寫本計畫時尚無此 skill。實作前保存無 turbo 的 realistic fixtures 與原始軌跡，區分既有 agent 已能自行完成的工作和確有增益的項目；本計畫不把尚未實測的情境標成 observed RED。
- `wait4me` 已採 portable core、雙端薄入口與 session lifecycle hooks。其 canonical core 是 `shared/skills/wait4me`；既有開關由 session ID 隔離，通知不改 approval 決策。可參考控制及 lifecycle 分層，不將通知 hook 直接改成代答機制。依據：D-20260929-wait4me-session-hook-boundary，以及 [既有 workflow](../../shared/skills/wait4me/references/workflow.md)。
- Project spec 現有 Context／Goal／Acceptance Criteria／Constraints 與協作欄位；Spec 本身只寫文檔。接續 Log 及交付終點由當次明確要求決定。整合依 [Spec workflow](../../shared/skills/project/references/spec-workflow.md) 與 [shipping authority](../../shared/skills/project/references/ship-policy.md)，不另設一份說法表。
- 本機 2026-10-05 查證：Codex CLI `0.160.0`，Claude Code `2.1.289`。下列能力是候選實作接點，仍須以 native live eval 證明 turbo 的端到端語意。

| 接點 | 查證結果與設計用途 |
| --- | --- |
| Codex Stop hook | 官方支援阻止結束並送入 continuation prompt；可用於未完成目標的續跑。其他 hook 的 `continue: false` 優先，不能把所有停止都當成應續跑。[官方文件](https://learn.chatgpt.com/docs/hooks#stop) |
| Claude Stop／goal | 官方提供 Stop 續跑與 session `/goal`；Stop 不處理使用者 interrupt，另有連續續跑保護。需驗證正常長任務、無進展及取消行為。[官方文件](https://code.claude.com/docs/en/hooks#stop) |
| Codex goal／app-server | 官方提供 thread goal、turn start／steer／interrupt 等 API。Goal 會持久化且替換目標可能重置計量；resume 仍須撤銷 turbo 的舊 session 委派。[官方文件](https://learn.chatgpt.com/docs/app-server#manage-a-thread-goal) |
| Runtime permissions | Approval 與 sandbox 分別控制是否詢問及可存取範圍；CLI、desktop、web 的控制面不同。[官方文件](https://learn.chatgpt.com/docs/sandboxing#how-permissions-work) |

2026-10-05 草稿文件驗證：首輪 repo suite 為 1567 PASS／1 FAIL，失敗是文件檢索 ratchet。
同一 corpus 排除本檔為 6/10，加入本檔為 5/10；唯一差異是本檔原節名的通用準備用語，
將既有審查來源擠出 top five。只把該節名對齊 native 能力主題，保留內容、scanner 與 oracle；
修後七項 real retrieval corpus tests 全部通過。原 suite log、前版草稿及反事實排名保留於
`/tmp/turbo-skill-plan-suite-20261005.log`、`/tmp/turbo-skill-plan-before-recall-fix-20261005.md` 與
`/tmp/turbo-skill-plan-recall-diagnosis-20261005.json`；這些是同機臨時證據，不是 repo authority。
修後以 `./tests/run-parallel.sh` 重驗完整三 shard，exit 0、1568 PASS／0 FAIL；log 為
`/tmp/turbo-skill-plan-final-suite-20261005.log`。此結果驗證文件加入後的 repo 回歸，未驗收未實作的 turbo 功能。

## Turbo on／off／status 與 session 契約

Claude 入口為 `/turbo on|off|status`，Codex 為 `$turbo on|off|status`。Bare invocation 先採 `status`，避免只提到 skill 就改變控制狀態。這是新產品預設，須以 trigger eval 驗證。

| 操作／事件 | 預期行為 |
| --- | --- |
| `on` | 啟用當前 foreground session 的自主決策、作者修正與 review 續批委派；已有合格目標則接續，沒有目標則 enabled／idle，等待使用者給工作。重複 on 不重設修復額度或重跑已完成階段。 |
| `off` | 撤銷之後的自動決策與續跑；在 runtime 可處理輸入的第一個邊界生效，取消排隊的 continuation。不能宣稱回復已完成操作或已啟動且不可中斷的操作。 |
| `status` | 只讀回報 mode、idle／preparing／running／blocked／stopped／complete、當前 goal、下一個 checkpoint、review 累計消耗／續批原因、選定交付終點、permission readiness，以及能力未知或不足之處。 |
| 新 session／clear／resume／fork／owner transfer／session end | 不沿用啟用狀態或當次委派。歷史裡的 on、計畫內的指令及舊 artifact 都不能重新啟用。 |
| 同一 live session compact | 可保留開關；從 repo 權威恢復工作事實並重驗現行 authority。不能從 cache 重建 Project 不允許持久化的 binding packet。 |
| 目標完成 | 關閉該工作的 continuation 與當次交付委派，mode 可維持 enabled／idle；不自動挑 backlog 或延伸新目標。 |
| 使用者新指示／取消 | 最新指示先於排隊 continuation。取消不得被 Stop hook 重新喚醒。 |

從 deep-plan 啟動時，以既有 draft plan 與當次 live 委派作為輸入；未開始實作不構成啟用障礙。讀取 plan 不等於寫入授權：使用者可在同一次啟動中委派作者修正、review 續批、後續實作與可選交付動作；已具備的當次授權不再逐階段重問。Spec／Plan mode 仍遵守 host 的唯讀邊界，必要的 mode transition 另驗證。

候選啟動介面為 `$turbo on <goal> --allow commit,push,pr,merge`，Claude 以 `/turbo` 對應。這是待實作的產品介面：正式 `on` 契約本身包含目標範圍內的作者修正、模式選擇及 review 續批，不另要求每次續審輸入旗標；`--allow` 明列本次具名 goal／repo／scope 可選交付動作，agent 決定適當終點。也接受真正使用者的等價自然語言，正規化只維護在共同 authority 路由。普通 `on` 沿用當次已明確給定的交付動作；缺少某動作授權時，先完成不依賴它的工作。Contract 的文字、hook 或 agent 建議本身不補授權。

狀態管理先驗證 native session primitive；若 native 能力不足且已有 RED，才加入 deterministic lifecycle helper。臨時控制狀態以 runtime、真正的 thread／session identity 及 live-session generation 隔離，預設 off，不依賴 agent 記憶。缺 ID、hook 未啟動或狀態不可讀時，不宣稱已啟用或已有 unattended readiness。

控制命令只接受真正使用者輸入；引用、程式碼區塊、工具結果、subagent 訊息及 hook 自產 continuation 均不能啟用模式或增加授權。特別驗證 runtime 將 continuation 表示為 user prompt 時的來源辨識。

## Spec／計畫的 Turbo Execution Contract 格式

維持原有 Markdown spec／計畫，在同一份文件加入一個具名 `Turbo Execution Contract` YAML 區塊。共同 schema 只維護一份，Project 及一般計畫模板引用它。Goals、constraints、acceptance 與 progress 仍在 repo 已採用的權威位置；YAML 用 reference 連到它們，不建立另一份 dossier。

契約最小資訊為目標、範圍、完工判準、決策規則、階段完成證據、失敗處理、review 續批委派與交付動作集合。資源預算採使用者指定或既有 workflow/runtime 限制，未指定時不擅設整個專案的費用／token／時間上限。各批原始消耗累計保留；只有合法續批才依公開規則建立新批局部額度，不得用重新 on、compact 或換 goal ID 重置同一批。

以下為 schema 草案，不是本輪工作的執行授權；anchor 由產生計畫的 agent 連到當次真實權威：

```yaml
schema: turbo-execution/v1
goal_ref: "<active item 或 plan goal anchor>"
scope_ref: "<repos、write scope、constraints、ownership 的權威>"
acceptance_ref: "<可驗證的 acceptance criteria>"

delegation:
  authority_ref: "<當次真正使用者對修正、實作及交付的原始委派>"
  expires: goal-complete-or-off-or-session-end-or-ownership-change

decisions:
  policy: best-fit-within-contract
  priority:
    - explicit-user-preferences-and-constraints
    - satisfy-acceptance
    - existing-repo-conventions
    - verifiable-and-reversible
    - lower-maintenance-cost
  uncertainty: investigate-then-decide-within-fixed-goal
  defaults: {} # 僅放會影響結果且需事先決定的 task-specific 預設

checkpoints:
  - id: plan-review
    workflow: deep-plan
    complete_when_ref: "<GO 或 READY-FOR-INCREMENT，符合實際風險路徑>"
    on_failure: diagnose-repair-and-reenter-authorized-review
  - id: implement
    complete_when_ref: "<實作階段可觀察結果>"
    on_failure: diagnose-and-repair-within-scope
  - id: verify
    complete_when_ref: "<必要檢查、exit code 與產物>"
    on_failure: diagnose-and-repair-within-scope
  - id: code-review
    workflow: runtime-code-review # Claude deep-review；Codex repo-review
    complete_when_ref: "<實際 scope／版本的有效 review 與 disposition>"
    on_failure: diagnose-repair-and-reenter-authorized-review
  - id: deliver
    complete_when_ref: "<指定終點的實際狀態>"
    on_failure: follow-authorized-workflow

reviews:
  reentry: agent-recommended-within-delegation
  authority_ref: "<當次使用者允許修正、blind／focused 選擇及續批的指令>"
  progress: require-new-facts-or-verified-repair
  limits: preserve-local-caps-and-cumulative-history

delivery:
  endpoint: agent-recommended # 或使用者已指定 result | commit | branch | pr | merge
  allowed_actions_ref: "<當次明列 commit／push／PR／merge 等可選動作的授權>"
  workflow_ref: "<repo shipping workflow；如適用>"

resources:
  limits: inherited # 可另附使用者限制；review 續批另走具名委派接點

stopping:
  policy: evidence-backed-infeasibility-or-no-progress-or-material-restructure
  result: stopped-with-reason-and-current-artifacts

permissions:
  required_profile: "<host 可辨識的執行需求>"

completion: all-acceptance-and-delivery-evidence
```

`result` 表示交付要求的結果；`branch` 對應 repo workflow 的只推 feature branch。`agent-recommended` 讓 agent 在已明列的動作集合內選 endpoint；使用者已指定固定終點時就遵守它。需要擴充 Project 的唯一 shipping authority 表以辨識具名 turbo 委派，不能只讓 turbo 私自加入一份說法表。契約不能替自己授予 push／PR／merge 權限。當次使用者指令的授權、repo ownership、host permission 各自驗證，不從 YAML 或先前 session 推定。

產生 spec／計畫時，agent 可在已委派目標內依決策規則補齊合理預設；不要把所有欄位都變成新提問。Readiness 檢查以可否正確執行為準，不檢查措辭完整度。缺少真正的目標、關鍵事實、授權或 ownership 時，只阻擋依賴它的工作，先完成其餘可安全進行的準備。

自主決策只涵蓋同一已確定 Goal、Acceptance Criteria 與 Constraints 下的實作選擇。若資訊齊全但需求有不同解讀，且會產生不同驗收結果，仍依 [repo ambiguity rule](../../AGENTS.md) 與 [Spec workflow](../../shared/skills/project/references/spec-workflow.md) 釐清；同一 write scope 不代表已委派選擇需求。只有契約的 task-specific defaults 已明確決定該細節，或多個方案皆滿足同一驗收意圖時，才能自行選擇並記錄。Readiness 不得把尚未確定的需求解讀標成 ordinary choice。

對既有 Markdown 計畫，先在同一文件增補契約並保留原驗收意圖；implemented／superseded 計畫依治理 lifecycle 保持凍結，不為 turbo 重寫。一般 Plan mode 產出同一區塊；在仍受 Plan mode 限制時只準備，經 host 支援且已授權的 mode transition 才開始 mutation。

## Turbo 決策、續跑與結果證據

Agent 依序判斷：既定偏好／約束、驗收、repo 慣例、可驗證與可回復性、維護成本。多個合格方案都可行時自行選擇，記錄影響結果的理由，再繼續工作；不固定挑第一個選項，也不把「建議」標籤當成必然正確。缺事實先查證，可使用契約內預設，但不能捏造使用者需求或外部事實。

計畫只需把重要 checkpoint 寫清楚，不要求窮舉每個情境或所有 tool calls。Checkpoint 含完成證據與失敗策略；必要的方案調整可由 agent 在 scope 內自行決定，新增目標或 materially expanded scope 仍是新的委派。

優先嘗試 native goal，實測不能承擔所需語意才使用 Stop continuation。續跑必須綁定同一 goal、contract revision、session generation 與未完成 checkpoint；收進度、失敗和額度，不收任意聊天文字作為指令。Controller 自產 prompt 是執行回饋，不能偽裝成真人授權或回答 approval；呼叫後續 workflow 只能消費已查證的當次委派，不能由呼叫取得新授權。

每次續跑前檢查 off／取消、scope／ownership drift、現行 workflow terminal state、permission 結果及可觀察進展。既有阻擋、無法解除的外部條件、重複相同失敗且沒有新證據或 native 保護上限都需保留；不得無限重新送出相同請求。主 agent 完成狀態須有 acceptance 與 endpoint evidence。驗證結果綁定實際待交付版本，修後不能沿用修前通過結果。

Review 續批依以下決策執行，不因遇到 NO-GO／FAIL 就固定全審或重新抽樣：

| 當前證據 | Turbo 採取的最佳建議與執行 |
| --- | --- |
| 缺少必要事實、尚未診斷原 finding | 先查證或重現，再修正；未補齊前不消耗 reviewer。 |
| 有有效基線、同一 Goal／scope 的局部修正 | 先核對原 finding、同類與語意相依及實際 diff，再選 focused 續批。 |
| 核心方案改變、修正牽動未涵蓋的風險 | 若仍在已委派 Goal／scope 內，修訂 canonical plan、確認完整範圍後選 blind；越界或改驗收意圖則停止並說明必要重構／新決策。 |
| 本批已耗盡且滿足上述進展條件 | 透過 controller 的具名 delegated-reentry 接點續批，保存先前批次、findings、失敗與累計消耗；不刪 journal、不提高原批 cap。 |
| 原因、修法及結果重複，沒有新事實或有效修正 | 停止該工作並回報；不換 reviewer、換模式或換 goal ID 洗出 PASS。 |

`deep-plan` 現行 [workflow](../../shared/skills/deep-plan/references/workflow.md)／[controller](../../shared/skills/deep-plan/references/controller.md) 只允許新的使用者指示 restart；`deep-review`／`repo-review` 的 [control protocol](../../shared/skills/deep-review/references/control.md) 亦同。實作需在兩個既有 controller 增加分開的 delegated-reentry admission：綁定原始使用者委派、goal／scope／actor／session generation、原 state hash、前批已終止且無 pending dispatch／repair、實際進展與所選 mode。機械檢查能核對 binding、diff 與計數，不能證明自由文字的診斷為真，orchestrator 仍須查證。不能把 agent 建議寫成「新使用者指示」餵入現行 restart／new-batch。

每批仍使用該 review skill 的 reviewer 數量、immutable scope、fresh context、結果完整性、原始 severity／disposition 與 receipt 規則。Reviewer 不取得 turbo 累計額度、最後一輪壓力或預定 verdict。Failed／partial review 不退還消耗，先診斷 orchestration failure；缺有效證據時保留 BLOCKED。續批不清 review-terminal；只有 covering receipt 與原有權限才能處理，legacy signal 仍須原訊號的明示處置。Code review 的 ordinary／full 分流保持依風險判斷，不能為 turbo 固定提高審查強度。

Agent 可在測試與 gates 成立時，依 repo 工作流做有意義的 feature-branch commit，再選已授權的 branch／PR／merge 終點並執行。應用既有 staging、cached diff、CI／protection 與同批修復邊界；必要檢查失敗就先修，不以交付最佳建議取代 gate。固定終點、不同 PR、新目標與 materially expanded scope 不由 agent 改寫；bypass、force-push、production、永久刪除等不自動包含在普通交付委派。

停止是正式結果：證據顯示目標在現行約束內不可達成、外部依賴無法取得、修法反覆無進展，或需要超出委派的重大重構時，agent 可停止而不等使用者催停。報告包含未達標條件、觀察與已嘗試方法、剩餘假設、已完成產物／commit、目前外部狀態及推薦下一步；標成 `stopped`／`blocked`，不標完工。可回復且 scope 內的重構可自行進行；範圍擴大或驗收變更先保留工作並說明。只有 cap hit 或仍有 finding，不足以宣稱專案不可能完成。

Compact 的驗收分為兩格：packet 缺席但 ordinary gate 能依唯一 Workspace／Writer match 得到 PASS 時，重驗後繼續；若 ordinary gate 仍是 actor mismatch 或要求當次真人確認，保留具體 blocker 並停止該工作的自動續跑。依 [Log authority 路徑](../../shared/skills/project/references/log-prepare.md) 判讀，不把後者算成多跑一次即可恢復的日常決策。

決策、死路、進度與里程碑依 target repo 的 adopted lifecycle 記錄。Session cache 只管控制與去重等 operational 狀態；不成為工作事實、授權或跨 host continuity 的新權威。

## Permission 啟動接點與 off 語意

Permission 納入正式 scope。以 launcher/profile 或受支援的 host API 在啟動前準備，並回報 effective mode；`$turbo on` 不自行永久修改全域 permissions。Desktop／IDE／web 必須分別列能力，不將 CLI flags 冒充當前 UI 已切換。

| 路徑 | 初始候選與驗收 |
| --- | --- |
| Codex 保留 sandbox 的無提示執行 | 本機 help 支援 `codex -a never -s workspace-write`；不詢問但仍可能被 sandbox 拒絕。另有 `--approve-for-me` 自動審核，可拒絕，不能宣稱全部放行。 |
| Codex 跳過執行核准與 sandbox | 本機 help 支援 `codex --dangerously-bypass-approvals-and-sandbox`。由使用者選定的 launch profile 開啟；hook trust、外部服務及 managed requirements 另查。 |
| Claude 跳過日常 permission 提示 | 本機 help 支援 `claude --dangerously-skip-permissions`／`--permission-mode bypassPermissions`。`--allow-dangerously-skip-permissions` 只開放選用，非已啟用。官方仍保留部分互動與 managed 邊界。[官方文件](https://code.claude.com/docs/en/permissions#permission-modes) |
| Claude 無提示但可能拒絕 | `dontAsk` 會拒絕原本須提示的呼叫，不能當成自動核准。[官方文件](https://code.claude.com/docs/en/permissions#permission-modes) |

驗證以隔離 workspace 的 benign read／write／network fixture，記錄 host 的真實結果；不以「沒有看到 UI」推定權限充足。需要 container 時先遵守 [repo contract](../../AGENTS.md) 的網路前提。

另以「有／無當次 action 授權 × canonical／opaque 命令 × 各 permission profile」建立 native composition 矩陣，涵蓋 never＋workspace-write、自動審核及 bypass。直接相依包含 [Codex rules](../../codex/rules/default.rules)、`codex/config.toml` 的 PreToolUse 註冊、[outward-action-gate](../../scripts/outward-action-gate.py) 的 deny 訊息，以及 [既有測試契約](../testing-contract.md) 與 hook fixtures。Canonical 命令目前交 rules 處理，opaque 命令由 hook 拒絕；驗收必須記錄真實 allow／pending／deny、授權對照與負例，不能把 bypass 等同 shipping 授權或直接關閉 gate。依 D-20261005-project-canonical-push，rules／gate 語意改變需 fresh trace；本機 bare remote 證據不冒稱 GitHub provider 或 native approval UI 全部通過。

`off` 必須停止 turbo 委派及續跑。若 launcher 的 bypass 設定仍生效，status 明確分開顯示；不能承諾純 skill 回復它。若 host API 可在同 session 切換及回復 permission，需保存開跑前 effective profile 並驗證回復；不支援就交付明確能力邊界，不改其他 session／全域設定。

已發出的 host approval 依 [approval lifecycle](../../codex/AGENTS.md) 等待 terminal result。不得因使用者未回應而改命令重送，或由 turbo 假造批准。登入、服務端拒絕及 host 強制人工互動也不能由計畫文字解除。

## Portable 實作範圍與 Project 整合

依 [skill portability contract](../skill-portability.md) 與 [Codex authoring guide](../../codex/skill-building-guide.md) 實作。初始預定位置如下；只建立經 eval 證實必要的資源：

```text
shared/skills/turbo/
  references/workflow.md          共同控制、決策與續跑語意
  references/execution-contract.md 共同 schema 與產生／驗證規則
  evals.md                        單一雙端 oracle
  scripts/                        只有 native RED 支持時加入 helper
claude/skills/turbo/SKILL.md       Claude thin entry
codex/skills/turbo/SKILL.md        Codex thin entry
codex/skills/turbo/agents/openai.yaml
```

Runtime entries 以 nested links 共用資源，不以兩份 workflow 處理同一語意。Native 工具、事件及 permission API 綁定放 adapter，不進 shared core。Invocation policy 依當前 authoring defaults；skill 被讀取本身不等於 on。

Project Spec、計畫產出接點及必要模板引用共同 execution schema。整合範圍明列 `shared/skills/project/references/spec-workflow.md` 的詢問路由：有效 turbo 委派及相同驗收意圖下的實作選擇引用共同決策規則；不同需求解讀仍走現行釐清路徑。雙端都驗證此分流，turbo off 仍走原流程，不能只加入 schema pointer 而留下互相矛盾的活契約。Spec 本身不改 code，不因存在 YAML 就自行進入 Log。使用者明確指定同一 logical workflow 的開工與 endpoint 時，依現行接續規則執行。常駐 guidance 只在 eval 證明需引用此具名委派路由時做最小調整，不放寬 safety floor。

本需求的直接整合範圍另包含 `shared/skills/deep-plan` 的 workflow／controller、`shared/skills/deep-review` 的 workflow／controller 與兩端 thin entries，以及 `shared/skills/project/references/ship-policy.md`／Log 接續路由。Turbo 委派一次明列修正、續批、實作與交付權限，再由各單一權威消費；不建立 turbo 私有的 review 或 shipping 授權表。常駐 explicit-only lifecycle 指引如需辨識此路徑，須與 authority 接點及 off 負例一起驗收。普通 review／未啟用 turbo 仍保留原本批上限、restart 指示要求與 shipping 預設；此計畫未變更現行契約。

Existing-skill preflight 保存雙端真實 linkage 與正式 defaults：deep-plan 共同盲審／兩輪，deep-review／repo-review 使用同一 portable core、code-review 專屬 controller 與各 runtime 的風險分流。續批委派是本需求新增的 opt-in capability，不重做 portability migration。採用時須在既有 history 記錄這項政策的證據、代價及對 D-20261003-deep-plan-controller-adoption 等原決策的具名更新；原歷史不改寫。

可能改動既有 runtime hook 設定及 ensure helpers；先查實際註冊與 symlink，不按目錄名猜 canonical source。不重構 wait4me 或添加通知 transport。Turbo 吸收的普通決策不觸發 waiting 通知；真正需要人處理的 blocker 沿用既有 wait4me marker，兩者開關獨立，不能由 turbo 開啟通知。

Stop 相依明列 [timestamp helper](../../scripts/agent-turn-end-timestamp.sh)、`claude/settings.json`、`codex/config.toml` 與 [既有 wiring tests](../../tests/run.sh)。Timestamp helper 目前消耗輸入後無條件顯示「等待輸入起點」，無法區分真人等待與 native goal／Stop 自主續跑。先保留續跑輸入仍顯示等待的重現，查明各 runtime 的事件及聚合順序，再只修與 turbo 續跑矛盾的訊息判定；非 turbo、真正等待、off 與 blocked 的提示語意另作對照。不能只把文案刪掉，或把每個 Stop 都當成真人等待。

現有 Claude Stop wiring 以整個陣列相等判定，Codex 以固定 Stop 區塊判定。若實測需新增註冊，必須同步修改這兩個 oracle 並增加共存行為驗收：timestamp／wait4me 仍註冊於原 scope，原有 privacy、timezone、failure isolation 及同步／非同步契約保留；turbo disabled 不續跑，enabled 且未完成才可續跑，完成／取消／blocker 不被重新喚醒。以缺少既有 hook、錯誤 scope 及不當續跑的負例確認守門仍有鑑別力，不能只接受新陣列形狀。新增 assertions 時同步 `tests/shard-manifest.tsv`，不放寬 aggregator 的完整性判準。

## Turbo 實作順序與階段出口

1. **凍結 baseline／oracle**：保存雙端版本、source hashes、無 turbo fixtures 與 raw traces；涵蓋從 deep-plan 啟動、三種 review 的 cap stop、交付推薦與停止結果，以及既有 normal／negative／permission／interrupt cases。出口是可判讀的既有能力／RED，尚不新增控制 hook。
2. **執行契約與自主決策**：建立共同 schema、thin entries、可直接使用的 spec／plan 例子；保存原始委派與 action 集合。出口是同一驗收意圖內自行選擇，需求歧義仍釐清，Spec 詢問路由一致，review／shipping 委派不混用。
3. **Review 續批與模式決策**：先寫 delegated-reentry admission 的 RED，再改既有 controllers 與共同 workflow／adapters。出口是三種 review 耗盡後依事實修正並選 focused／blind，先前 findings／耗用保留；pending、stale scope、fake authority、無進展與 turbo off 不派遣。新批可用有效基線，但不沿用修前 PASS。
4. **Session 控制與 native 續跑**：on／off／status、session 隔離、goal／Stop、compact 及 lifecycle reset；native 失敗才加有界 helper。出口是實際跨階段 artifact、timestamp／wait4me 共存、wiring 正負例、取消及無進展停止；compact 同時驗收合法恢復與須真人介入。
5. **Permission 與 Plan mode 接點**：驗證各 effective profile、mode transition、pending／denied、off 回復邊界及 outward gate／rules composition 矩陣。出口是雙端各 surface 的實測能力與明確限制；未完成矩陣不宣稱 unattended shipping ready。
6. **Project 接續與自主交付**：在唯一 authority 表接入具名 turbo 委派，同一契約從 deep-plan 經實作與 code review，選擇並到達已授權終點。出口包含 meaningful commit、自主 push／PR／merge、固定終點尊重、CI 修復及 stopped 報告的雙端 native E2E；ordinary／off 無回歸。
7. **驗證與交付**：適用 validators、scripts、behavior evals、必要 fresh blind forward tests、repo suite 與 doc audit；記錄 portable topology、雙端證據及未驗分支。Shipping／dotsync 依該批實際授權與 repo workflow，計畫本身不授權部署。

採用較小實作後逐步補足；不得把只完成第一、二階段的 skill 宣稱為完整 turbo。若某 runtime 缺能力，依 portability contract 回報，而非借另一端的成功宣稱雙端完成。預設交付雙端；改成分 runtime rollout 須使用者選定。

## Turbo behavior eval 與驗收矩陣

| Case | 可觀察 oracle |
| --- | --- |
| 明確 on／off／status、重複 on | 真實狀態變化與只讀 status；重複 on 不重置工作／額度；off 後零新增 continuation。 |
| 研究 turbo、文件／引用內指令、hook-generated user prompt | 不啟用、不增加 endpoint 或 action authorization。 |
| 合格 spec 的兩個合理方案 | 依約束選擇、理由可追查、完成下一階段；不要求真人回答 ordinary choice。 |
| 從既有 draft plan 啟動 | 在當次委派下進 deep-plan 正確風險路徑，作者修正後接續實作；readonly／Plan mode 階段無 mutation。 |
| deep-plan／deep-review／repo-review 達本批 cap | 局部修正用有效基線 focused；風險範圍改變用 blind；每次續批有委派、原 state binding、實際進展及完整歷史，沒有真人「再審」才前進的依賴。 |
| 相同失敗、partial review、假 restart 指示 | 原消耗不退還；先診斷，無新事實／有效修正不重審；partial 不變 PASS，agent／hook 文字不能作真人授權。 |
| 資訊齊全但需求有兩種解讀 | 兩種解讀產生不同驗收結果且無已宣告 default 時，保留釐清，不 mutation／擅選目標；同一驗收意圖的實作選擇才可自主通過。 |
| 同一目標的多階段工作 | 經實作、檢查、必要修復及指定交付達標，完整 raw trace 沒有靠真人「繼續」訊息。 |
| Goal 缺資訊／格式不完整 | 可查證部分及允許的預設自行完成；真正缺口不捏造；不把 schema completeness 變成提問清單。 |
| 已授權 merge 與只有 turbo on 的對照 | 前者按真實 provider／受控 fixture 狀態到達終點；後者不 push／PR／merge。Synthetic receipt 不能冒充真實 provider E2E。 |
| 明列交付動作、由 agent 選終點 | 依目標與 repo workflow 選擇並執行 commit／branch／PR／merge，raw trace 有理由與實際結果；指定停 PR、只允許 push 或 action 缺席的負例不擴張終點。 |
| Scope／Writer／Steward drift | 不修改不屬於自己或超出 scope 的內容，保留可進行的準備與具體 blocker。 |
| Permission allow／pending／denied、sandbox denial | 核對 host 結果；不偽造批准、不重送 pending 請求；never／dontAsk denial 不標成成功。 |
| Action 授權 × command 形狀 × permission profile | Native composition 驗證 rules prompt／hook opaque deny 與 turbo 委派；未授權不對外 mutation，bypass 也不清掉 authority／review／CI gate。 |
| Plan mode 產出到 execution | 同一 schema、明確且合法的 mode transition；readonly 階段無 mutation。 |
| 使用者 off／取消／修改方向 | 最新指令優先，既有 queue 失效；Stop 不在取消後自動重啟。 |
| 多 session／fork／resume／compact | Session 隔離；新生命周期 off；compact 只維持合法 mode，不還原非法 packet。Ordinary gate PASS 後續作；actor mismatch／需要真人確認時阻擋，不靠 continuation 假造恢復。 |
| 測試／CI 失敗與額度耗盡壓力 | scope 內修復後重新驗證；未通過不得交付或完成，既有額度不重置。 |
| 同一失敗無進展、偽造完工 | 有界停止；complete 必須與真正產物及檢查一致，不無限循環或削弱 acceptance。 |
| 不可達標／需要重大重構 | Agent 自主停止，報告 unmet criteria、嘗試與證據、剩餘假設及下一步；有 cap／finding 但仍有新進展的對照不誤判不可能。Scope 內可回復重構可自行修後驗證。 |
| wait4me 同時啟用、turbo off | 普通決策不送等待通知；真正 blocker 沿用既有通知語意，off 不改 wait4me／其他 session permission。 |
| Stop timestamp 與 hook 共存 | 自主續跑不假報真人等待；真正等待與非 turbo 提示正確。Timestamp／wait4me wiring 及既有 privacy／timezone／failure isolation 保留；移除既有 hook、錯 scope、disabled／complete／cancelled／blocked 仍續跑的負例會被抓到。 |
| 未啟用 turbo 的原流程 | Project spec／Log、日常提問及兩端既有 defaults 無回歸。 |

先寫 oracle 再測無 skill／候選。同一 query／fixture 雙端比較，隔離測試產物；保留原始失敗，不重跑相同 packet 洗綠。模型／樓層依 [既有 eval policy](../../claude/evals/README.md)，不為本功能另立模型政策。Complex 或高風險候選依 authoring guide 使用 fresh-context blind forward tests；本輪的實際證據與支援邊界記於下節。

機械 helper 用真實輸入／輸出、檔案／Git 狀態、事件來源、退出碼判斷；語意 eval 檢查選擇是否滿足當次目標。最後必須雙端能力證據、適用 validators、`./tests/run.sh` exit 0、documentation audit 及 diff check 通過，才可標記 implemented。

## Turbo 實作驗證與支援邊界

本輪新增 shared turbo core 與雙端薄入口，在既有 plan／code review controllers 增加 opt-in
委派續批及 current-subject 接點；Project 的單一 shipping authority 消費當次具名授權。
非 turbo 原本的批次、restart 與 shipping 行為保留。Operational cache、review receipt、
hook 文字及 spec 本身都不是 action authorization 或 Goal 語意驗收的 authority。

| 驗證 | 實際結果與證據 |
| --- | --- |
| 機械接點及 off 回歸 | `tests/turbo-mode.py` 包含 session／generation、真實 ticket、history／capacity、native proof、subject refresh、摘要來源、notice 及 local heredoc 負例；44 項整套 exit 0 後 notice 2 項、classifier／summary 3 項 exit 0，final E 全套涵蓋 46 項；native report collector 新增兩項，連同 hook wiring 三項先 RED 後 GREEN。48 項整套由 F／G 驗綠，G 的 48 項 exit 0／257.355 秒，舊通知 wiring 與注入通知負例也通過。既有 code controller 23 項、plan controller 36 項 exit 0；G 的 code controller 23 項 exit 0／469.312 秒。 |
| Plan cap 後自主修正／續批／實作 | 双端 fresh native fixtures 完成；Claude 真實 background Agent 等待與 SessionStart env propagation、Codex fresh read-only reviewer process 均有 native trace。保留原本 synthetic spent-round history，未宣稱它們是 native reviewer 結果。 |
| Code cap 及 Goal acceptance | Codex E 56/56、兩個 native threads `01a10d0f-5d4e-7aa3-8940-4d599c02abe8`／`01a10d13-082f-78f0-aebd-10ddd11ca647`、原 report field 保留。Claude H（collector source `969ac730…`）56/56＋22/22 supplementary checks 通過；兩個 fresh Agents `a297b6e78e1db4768`／`ae396d190b8c834c3` 的 actual return＝SubagentStop payload＝production capture＝controller raw_report，SID／generation／target／ticket／hash 相符。FRESH current-byte receipt、history／原 spent cap／完整 roots 保留，H HEAD 未變，無 commit／outward。H 的 22 項分為 actual finding triggers 8、positive Mapping 2、final-review probes 8、保留 G 反例 4，不冒充互不重疊的新需求。F／G 原文 collection RED、C／D acceptance RED、E classifier RED 都保留。見 `/tmp/turbo-forward-claude-code-cap-20261006-h/{artifact-index.json,blind-grade.json,report-preservation-grade.json}` 與 `/tmp/turbo-code-cap-forward-history-index-20261006.json`。各 packet 使用自己 frozen source，不冒充 Codex E 與 Claude H 全部 byte 相同。 |
| 自主 commit／push／PR／merge 與同 PR CI 修復 | 雙端 native CLI 完成 controlled local bare remote／gh provider；CI 實際檢查 pushed bytes，由 RED 修為 GREEN 才 merge。Codex v2 CI 到達 `dc6347e91587edb7f09025aa3dc5dffac8de47da`；collector 修後 Claude v4 到達同一 PR #1／`e515f870172b9af97aa915430940a70cd9e37099`，bare／local main 相同且 clean，feature 已刪。Native Agent `a83a30d38c9bd1c32` original 直接收集，作者摘要分開保留；一個 medium finding 修後的 current-byte receipt 是 ordinary author verification，非第二次 independent review。Independent no-local clone 的 63 checks 在 Python 3.11／3.14 均通過，原 PLAN byte-identical。見 `/tmp/turbo-delivery-forward/{GUARD-RESULTS.md,V4-RESULT.md,V4-VERIFICATION.json,v4-native-evidence.json}`。 |
| 摘要、action 及 endpoint 邊界 | Actual callback transcript 證明首次 outward 前的真正 assistant 摘要；changed HEAD、quote／tool／thinking、缺 transcript 的拒絕由機械負例驗證。Only on、缺 push、fixed PR 的 native 對照沒有擴張終點；這些對照及 lifecycle 是其 frozen component source 的證據，沒有冒充最終每一 byte 的完整 E2E。 |
| Permission 組合 | 13 個隔離 fixtures 保存真實 launch argv、hook allow／deny 與 canonical／opaque call；profile 是啟動前選定，不由 on 改全域設定。實際 dontAsk denial、Plan readonly 及不合法 Plan→bypass 的 terminal refusal 均保留。未觀測的 approval UI／rules 內部載入不外推。 |
| Lifecycle | `/tmp/turbo-lifecycle-forward-xnk1l8ow/report.json`：Claude controls／compact 保留合法委派、writer drift 阻擋、實際取消後 next-input reconciliation；Codex 真實 Interrupt／SessionEnd／resume 撤銷。不同 source hashes 各自保存，後續 review／summary 接點不冒充此組相同 source。 |
| 不可達 Goal 的 stopped 出口 | 最新 helper `3eea6cd37e38a7d094e266386ccec8eb7065bd034484032fb216e3d9ba51dcbc` 的雙端 native packet 各一次 PASS：固定只准寫 PLAN，required codec／checks 無法產出，兩端指出 unmet criteria 並存 stopped。原 Goal／AC／scope 未變，無 implementation／commit／outward；Stop `{}` 後只有 SessionEnd，沒有續跑。Codex 僅追加允許的 PLAN 證據，Claude tree 未變。見 `/tmp/turbo-delivery-forward/{STOPPED-RESULTS.md,STOPPED-EVIDENCE.json}`。 |
| Validators／repo suite／governance | 雙入口 quick_validate exit 0；Python／JSON／TOML syntax、shellcheck、diff check、documentation audit exit 0。E suite exit 0／1570 PASS。collector 修後 F 的 Turbo oracle 綠，但舊通知 gate 要求沒有任何 SubagentStop 而 exit 1／兩個 FAIL；原 log 保留。修後 G exit 0／1570 PASS／0 FAIL，core 171、ship_state 239、integration 1160，integration 1465 秒；完整 log `/tmp/turbo-full-suite-20261006-g.log`。Freeze 前 doc audit／xref／diff check exit 0；最後驗收紀錄另驗。 |

測試使用 Codex CLI 0.160.0（main gpt-6.1-sol／medium）與 Claude Code 2.1.289
（main opus[1m]／medium），reviewer 的實際 identity／model 以 native evidence 為準；
不將未觀測的 service tier 或 model resolution 當成保證。Fresh forward evaluator 只讀 production，
fixture source hash、actual argv、native thread／Agent／raw report、independent artifact grading 均保留。
後續 notice／acceptance 指引／native report collector 的 localized delta 與 frozen component proofs 分開列，
未重跑舊 packet 或抹掉它的 RED。這些 `/tmp` receipts 是同機暫存證據，不取代 repo authority。

支援聲明限已驗的 native CLI。受控 local provider 是 composition evidence，沒有對真實 GitHub
mutation，也不等於 GitHub E2E。Desktop／IDE／web／app-server lifecycle 與 Codex TUI compact
未驗；Plan mode 只證明 readonly 與合法拒絕，沒有聲稱自動解除 host 必要 approval。
交付需要 actual persisted native transcript；logless profile 對一般目標仍可用，對交付 fail closed。
Claude off input 在工具執行時會排隊，需 host interrupt 再 off；實際 interrupt 沒有 abort hook，
其 cache 在下一次真實輸入 reconciliation 時撤銷，不能宣稱 enqueue 就立即取消。
Claude v3 曾四次因缺摘要拒絕且有 premature continue 文句；collector 修後 v4 亦有五次
missing-summary push denial，remote 在拒絕期間保持原 RED。兩次均在 actual ordinary summary
出現後由 native Stop 自動恢復完成，無真人 continue／observer input。保留效率限制，沒有
放寬摘要守門或把拒絕抹掉。

本地 authoring／validation 沒有 commit、push、install 或 dotsync 本批；未使用先前另一工作項的 merge 授權。
新 Turbo entries 尚未安裝。既有 `~/.claude/settings.json` 是 repo source 的 symlink，來源修改已
反映到該路徑；沒有改 permission 開關。Codex live config 是實體檔，未由本輪同步。

## Turbo 設計取捨與 native 能力待驗

- 選擇 Markdown＋共同 YAML 區塊，沿用既有權威；不用任意自然語言掃描猜「使用者正在被問問題」，也不建立獨立 turbo project store。
- 選擇 native goal／Stop 優先；只有 RED 支持才加 helper。暫不預建完整 app-server／SDK supervisor；若 native 無法完成取消、來源辨識或多階段續跑，再以該 failure 評估最小 host controller。
- 決策採 task-specific 約束及偏好，不固定接受每個「建議」選項，也不要求窮舉所有分支。
- Permission profile 是完整設計的一部分；on／off 與 host 權限變化分別呈現，不用一個 enabled 標籤掩蓋 readiness。
- 本次補充採目標範圍內的 review 續批委派與交付動作集合：agent 決定修法、模式及合適 endpoint，不要求每次 cap hit 回到真人。保留每批 cap、失敗及累計歷史，以進展／不可行性停止；不預設任意整個專案總費用／輪數，也不以 fresh review 洗掉 blocker。
- 開工前需以 baseline／native probes 確定：真正使用者與 continuation 的來源區分、兩端 native goal 的可控性、Plan mode transition、off 的輸入時機、compact 後可重新驗證的 authority，以及需要哪些 host controller 能力。
- 2026-10-06 本地實作與以上限定 surface 的驗收完成，本檔標 implemented 並凍結；未驗能力不是承諾。程式仍在 `docs/turbo-skill-plan` 的未提交工作樹，沒有 production commit／shipping／install／dotsync。開工 assignment 尚未存在於 candidate parent，故 [STATUS](../../STATUS.md) 保留 active item，等待明示授權先保存 provenance；本紀錄不宣稱工作線已整合或交付。不自行叫用 explicit-only shipping 或部署流程。後續能力或缺陷另依 adopted lifecycle 處理。
