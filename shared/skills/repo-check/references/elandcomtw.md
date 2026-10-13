# elandcomtw repo 規範

Profile：`elandcomtw-v1`，使用者指定的 skill 預設規範；不宣稱全部已在組織 server 強制。
每次查證 live GitHub 設定與 target 契約；snapshot 只說明已知形狀，不用舊資料判當輪納管。
若 `org-governance` 有已發布權威內容，引用其 revision 作組織政策證據；空白或不可讀不取消本 profile。

## 歸屬、連線與權限

| ID | 要求與判準 |
|---|---|
| E-REMOTE | canonical 屬 `github.com/elandcomtw`；其他 owner → FAIL；personal fork origin 可接受，但應有已確認公司 parent/upstream |
| E-PUSH | push destination 明確、符合工作流；unrelated org／多重未說明 pushurl → FAIL；fork 與 canonical 分列 |
| E-SSH | 開發預設 `git@github.com:elandcomtw/<repo>.git`；HTTPS／其他 alias → WARN，明示核准可 PASS；CI 授權 App／HTTPS 可接受 |
| E-IDENTITY | 分別有工作作者／連線／API 身分證據；无作者／生成假信箱 → FAIL；公司身分來源不明 → UNKNOWN，不硬編個人帳號、信箱 domain 或 key 名 |
| E-PRIVATE | 預設 private；public 未有核准證據 → FAIL；核准公開 → PASS |
| E-ACCESS | 2FA、最小權限與 repo 建立權限依當輪 org 政策；不可見 → UNKNOWN，不用 token scopes 代替 |

## 結構與文件

| ID | 必須內容與適用範圍 |
|---|---|
| E-DOCS | 非空、維護中 repo 有用途／使用／驗證 README、可供 clone 使用的 repo ignore、共同 agent 契約 AGENTS；docs repo 提供文件驗證即可 |
| E-CLAUDE | 使用 Claude Code 者有 CLAUDE 載入共同契約；未使用 → N/A |
| E-RUNTIME | 程式／套件有依賴、runtime 宣告、可重現測試入口與適用 lockfile；不固定 src/tests 名稱；新案偏好 Bun／uv，既有 toolchain 優先，不造第二種 lockfile |
| E-CONFIG | 需要環境設定者有無秘密範例及欄位說明；安全文件範例可代替 `.env.example` |
| E-DEPLOY | 服務有啟動、健康檢查、部署及復原方式；library 不強求 deploy script |
| E-COMPAT | 跨 repo 套件有版本、發布與消費者介面契約 |
| E-STATE | 已採用治理者依 target schema 維持 config/scanner 成對、有效狀態及歷史；未採用 → N/A，半套 → FAIL；不另建 stores |

空 repo 為待初始化，不套所有產品要求；文件基線已建立但未開始產品時，按 documentation bootstrap
階段列產品開工前待補。Archived 依封存用途查秘密／歸屬，不因停 CI 判 FAIL。
檔案存在不等於內容有效；缺適用的必備內容為 FAIL。

## Ignore 與秘密

| ID | 要求與判準 |
|---|---|
| E-SECRET | 真實 `.env`、私鑰、token、敏感本機資料不得追蹤；有敏感用途證據的 tracked path → FAIL／待核實；不印內容，不把安全 `.env.example` 當秘密 |
| E-IGNORE | 依賴、venv、cache、暫存、log、可重建產物按工具鏈由 repo ignore 規則涵蓋；僅靠 global/info exclude → FAIL；不盲目忽略所有 data/dist |
| E-KEEP | lockfile、migration、安全設定範例、必要 fixture 不被誤忽略；有理由的資料／發布產物依 repo 契約 |

## PR、CI 與實態

E-PROTECTION：維護中產品 repo 應有可驗的 default PR、禁止刪除／non-fast-forward、linear history
保護。欠納管 → FAIL，讀不到 → UNKNOWN；不以 ruleset 名稱代替匹配。
E-CI：程式 repo 有適合類型的 CI，required checks/workflows 與 trigger／實際結果匹配。
缺 required observation → UNKNOWN；證實名稱／trigger 不匹配 → FAIL。Docs baseline 不發明 unit-tests。

已查證 snapshot（2026-10-13）：

- org 要求 2FA，default repository permission=`none`，members 不能建 repo。
- `main-protection-core` 按 repo 名單匹配 actual default，要求 PR、禁止刪除／non-fast-forward、linear
  history，允許 squash/rebase；approval=0，push 後 dismiss stale reviews。
- `required_check_profile=unit-tests` 另套 required context=`unit-tests`、strict up-to-date，
  `do_not_enforce_on_create=false`。Core 與 CI 分別納管；property 空不等於無其他 required CI。
- property schema 說明：先觀察 current default tip 的 matching successful check 才啟用 profile。
- AIS 三個 repo 有專屬規則：`ais-platform`／`ais-platform-deploy` 要 1 approval 與 Code Owner，
  `ais-platform-internal` 要 1 approval；checks／merge methods 依当輪 effective rules。

不把 snapshot 寫成全 repo approval=1／unit-tests 通則，不自行改 properties／rulesets 或 bypass。
聚合 org/repo rules 與 classic protection；server bypass 資格不等於使用者授權。

證據入口：[org settings](https://github.com/organizations/elandcomtw/settings/profile)、
[rulesets](https://github.com/organizations/elandcomtw/settings/rules)、
[properties](https://github.com/organizations/elandcomtw/settings/custom-properties)、
[org-governance](https://github.com/elandcomtw/org-governance)。語意參考
[rule layering](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
及 [ignore tracking](https://docs.github.com/en/get-started/git-basics/ignoring-files)，不取代 live evidence。

## 一次文件基線

E-BOOTSTRAP：允許在確認完全空白的公司 remote，將核准 README、CONTRIBUTING 及可選通用
agent／ignore 文件建立為 `main`。明示初始化才載入 `initialize.md`；核准範圍與操作依該流程及上層契約。
