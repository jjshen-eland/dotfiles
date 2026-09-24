# 關鍵決策歸檔 — 2026-09

## 事件記錄（event-time）

- **D-20260901-container-network-collision-safety · 2026-09-01 container E2E 採 first-attach CIDR gate 與跨 runtime kernel**:2026-09-01 的 Codex inline E2E 為保留 production literal `10.10.12.150`，明確建立與 macOS host LAN 相同的 `10.10.12.0/24` 並 attach containers；OrbStack 把 CIDR 留在 PF isolation table，Docker network removal 未回收該 entry，造成 LAN／SSH 中斷約 3.5 小時。共同 kernel 現要求 first attach 前證明 CIDR 不與 host／LAN／VPN／production routes 重疊，inline／temporary E2E 不豁免；不得複製 production/LAN CIDR 保留 IP literal，改用 auto allocation＋DNS/test config。macOS／OrbStack cleanup 未檢查 isolation table 前不算完成，只報告碰撞且不自行刪除無關 firewall entries。三份 runtime-native kernel 以 deterministic gate 防漂移，G13 用無 shell/write runner 驗證 Claude Code 與 Codex fresh sessions 都會 STOP 並提出安全替代。
  - 日期來源:direct
  - 放棄:以 `--internal` 或 cleanup trap 當無撞網證明；為模擬 production identity 複製正式 CIDR；只設 Docker default-address-pools（明示 `--subnet` 可繞過）；只寫 Claude memory／單一 runtime 規則；自動刪除所有 PF isolation 殘留
  - 重議:container runtime 能在 first attach 前機械拒絕所有 host route overlap 並可靠回收 isolation state；或 G13 出現跨 runtime 回歸
  - 關聯:claude/evals/contract-evals.md;AGENTS.md;claude/CLAUDE.md;codex/AGENTS.md;tests/kernel-gate.py;tests/run.sh

- **D-20260902-container-residue-detection-layer · 2026-09-02 容器網路撞網的補強加在既有偵測層，不新增 preflight script、daemon 設定或 wrapper**:追完第二種殘留後評估三種候選補強，結論是只擴充既有 `check-network-isolation-collisions.py`，其餘都不做。獨立 pre-flight CIDR 檢查腳本的**強制力是 0**——肇事的是 agent 當場寫的 inline E2E，它不會呼叫一個沒被告知存在的腳本；若規則有效到能讓 agent 記得跑該腳本，同一條規則也能讓它記得自己比對一次路由表。腳本降低的是遵守成本，而 2026-09-01 的失效模式是「根本沒想到要做」，不是「想做但太麻煩」，故對該失效模式無作用。OrbStack `default-address-pools` 只約束**自動配發**，顯式 `--subnet` 完全繞過它，而已發生的事故正是顯式 `--subnet`；它防的是尚未發生的風險，與已發生成因無關。唯一有強制力的是攔截 `docker network create` 的 wrapper，但需改 PATH、影響所有 docker 操作、且 compose 不走 CLI，為單一事件裝設代價不成比例。決定性的前提有二:規則層已在三份全域指令的 Safety floor（見 D-20260901），是此環境約束力最高的位置;且全 repo 掃描確認磁碟上沒有任何帶硬編碼 LAN 網段的 `--subnet` 或 compose `subnet:`，不存在「誰跑到就復發」的地雷。
  - 日期來源:direct
  - 放棄:獨立 pre-flight CIDR 檢查腳本（強制力 0，不改變漏掉的機率，只降低遵守成本）;`default-address-pools`（擋不住顯式 `--subnet`，與已發生成因無關）;攔截式 docker wrapper（代價與單一事件不成比例）;cron 事後巡檢（同一支唯讀偵測已可按需執行，另立排程只增加維護面且無法更早發現）
  - 重議:同一形狀再次發生（代表規則層不足，屆時才上 wrapper）;或出現不需改 PATH、能在 daemon 層拒絕特定 subnet 的機制;或磁碟上開始出現帶硬編碼 LAN 網段的 compose／script
  - 關聯:D-20260901-container-network-collision-safety;M-20260902-missing-interface-route-detection;scripts/check-network-isolation-collisions.py

- **D-20260902-git-identity-directory-boundary · 2026-09-02 git commit 身分改由目錄分界決定，規則進共用層、值留機器層**:本 repo 歷史累積四種作者身分，其中 `jjshen@jjshen-mba.local` 是 git 在找不到 `user.email` 時依 `username@hostname` 靜默捏造的產物；2026-09-02 盤點證實 m4mini 至今仍處於同一狀態（`user.email` 為空、無 `useConfigOnly`），所以這不是歷史問題而是進行中的缺陷。決定把分界規則（`user.useConfigOnly = true` 與三條 `includeIf`）放進 dotfiles 散佈的 `git/config`，指向固定檔名 `~/.gitconfig-work` / `~/.gitconfig-personal`；email 值屬機器層，由新增的 `scripts/setup-git-identity.sh` 生成（600 權限、不進 git），該腳本並移除 `~/.gitconfig` 殘留的寫死 `[user] email`——殘留值會贏過分界，讓分界外的 repo 安靜地用錯身分，正是要消滅的「能動但錯了」。目錄分界為 `~/Projects` 公司、`~/SideProjects` 個人、`~/.dotfiles` 工作（它不在任何專案根底下、origin 在工作帳號、全機隊共有，故需要自己一條規則）。分界外**刻意沒有 fallback 身分**：失敗長相從「靜默用錯身分」換成「當場 commit 不了」，是吵的那一種。`useConfigOnly` 判為共用層是因為它不含任何身分資訊，卻是整套設計裡唯一有強制力的一格，留在機器層等於每台自己決定要不要有安全網、而漏掉的那台是無聲的。散佈時序安全：12 台機器的寫死 email 排在 `[include]` 之前，includeIf 目標檔不存在時 include 被靜默略過，故拉到新設定後不會突然無法 commit；唯一當場被擋的是 m4mini，而那正是目的。
  - 日期來源:direct
  - 放棄:把 email 放進 repo（dotfiles 是公開 bootstrap `dot.bitpod.cc` 的來源）;`useConfigOnly` 留在機器層（漏設無聲）;為 macs 的 `~/Projects/isdotgd` 開 per-repo 例外（例外允許一個，規則就退化成慣例——改為搬進 `~/SideProjects`）;追溯改寫既有 commit 的錯誤身分（已 push、rewrite 成本高）;維持「請在各機器 `~/.gitconfig` 設定」這種只指路不給規範的寫法（實測結果就是每台各自為政）
  - 重議:出現「必須在兩個根之外長期工作」的常態需求（屆時要決定是加第四條 includeIf 還是接受 per-repo 覆蓋）;或 git 提供比 `gitdir:` 更適合的條件（例如依 remote owner 判定）
  - 關聯:docs/plans/2026-09-02-git-identity-boundary.md;B-20260902-identity-fleet-rollout;git/config;scripts/setup-git-identity.sh;docs/repo-guide.md

- **D-20260902-gh-protocol-host-scoped · 2026-09-02 `gh/config.yml` 的 `git_protocol` 改寫成與實際生效值一致，不再假裝它能決定 protocol**:實測 2026-09-02——`gh/config.yml` 寫 `https`、`~/.config/gh/hosts.yml` 寫 `ssh`，`gh config get git_protocol` 回 `https`，但 `gh auth status` 與實際 clone 走的都是 ssh。**host 層勝過全域**，而 hosts.yml 由 `gh auth login` 寫、含 token、不能進 repo，所以 dotfiles 那行從來沒有作用過，只是一行會誤導人的死設定。改成 `ssh` 並在檔內寫明優先序與後果。連帶事實：`git_protocol` 是 host 層級、兩個 GitHub 帳號共用、無法分帳號設定，因此 `gh repo clone dev-bitpod-cc/<repo>` 必然產出 `git@github.com:dev-bitpod-cc/...`＝走預設 key＝工作身分，症狀是「連得上但權限不對」。收尾沿用既有的 `scripts/migrate-github-remotes.sh --apply`（它本就有 `github.com:dev-bitpod-cc/*` → `github-me:` 的換寫），只把預設搜尋根補上 `~/SideProjects`。gh 的 active 帳號是**第三個**互不相干的層（`gh` 完全不看 SSH alias，帳號不對時得到 `Could not resolve to a Repository` 而非權限錯誤），本批只補文件。
  - 日期來源:direct
  - 放棄:把 `git_protocol` 設成 https 並期待它生效（host 層會蓋掉）;把 hosts.yml 納入 dotfiles（含 token）;為個人帳號另設 protocol（`gh` 不支援分帳號）;本批做依 cwd 自動切 gh 帳號的 helper（wrap `gh` 要改 PATH、影響所有操作且會攔到非預期子命令；只覆蓋部分子命令則覆蓋不全等於沒有——見 `B-20260902-gh-account-autoswitch`）
  - 重議:`gh` 支援 per-account `git_protocol`，或提供不需 wrap 的 repo-aware 帳號解析
  - 關聯:D-20260902-git-identity-directory-boundary;B-20260902-gh-account-autoswitch;gh/config.yml;scripts/migrate-github-remotes.sh;docs/repo-guide.md

- **D-20260907-declared-path-coverage-and-shared-actor-rule · 2026-09-07 doc-governance 的配置一致性檢查以「機制自己掃的路徑」為判準，actor key 規則採複本＋漂移 gate 而非收緊**:issue #165 指出兩個沉默缺口——`plan_dir`／`history_paths` 指向的路徑可以沒有任何 class，`audit --ship` 仍全綠；以及 `active_item_contract` 只驗欄位存在／非空／非 unassigned／跨 item 一致，不驗值的形狀，於是被中文註解裝飾過的 `Dossier Steward` 讓 audit 全綠、`steward-authority.py` 回 exit 2 BROKEN，而修 `STATUS.md` 需要的正是那個已 BROKEN 的 authority gate。三個判斷:(1) 涵蓋檢查用**探針路徑**表述——`docs/plans/probe.md` 與 `decisions-2000-01.md` 丟進 scanner 自己分類檔案的同一套 glob 語意，不另立一套匹配規則，否則檢查與實際分類會各自演化。(2) 補上涵蓋檢查後**立刻與既有 dead-glob 檢查互斥**:空的 `docs/plans/` 沒有 class 被報 coverage、加了 class 被報 `class glob 無匹配`，兩條無法同時滿足，而 issue 的建議 3（「即使該目錄當下還沒有檔案也要建 class」）在 scanner 上因此做不到。解法是把「為宣告機制而前置存在的 glob」豁免於 dead-glob——它不是 stale，是還沒有檔案;無關的死 glob 照報。(3) `ACTOR_RE` 在 `scripts/doc-governance.py` 與 `claude/skills/project/scripts/steward-authority.py` 各留一份複本:前者逐字 vendored 進每個受治理的 repo，import skill tree 會讓 vendored core 失去自足性;依 `AGENTS.md`「Documentation authority」那條「沒有可驗證的 import 就保持短複本並機械檢查漂移」，漂移改由 `tests/run.sh` 抽兩份 regex literal 比對，並實測改一個 byte 會紅。正規化沿用 `steward-authority.py` 的 strip 空白再 strip 反引號，所以反引號裝飾不再繞得過 unassigned 檢查，兩個 gate 對同一個值給相同答案。
  - 日期來源:direct
  - 放棄:讓涵蓋檢查只在 `plan_dir` 底下真的有檔案時才觸發（那正是本 issue 的病——有檔案時 `unclassified:` 本來就會報，等於什麼都沒加）;在 `active_item_contract` 新增 `actor_fields` 配置鍵（缺省即無驗證，已 rollout 的 repo 不會自己長出來，重演同一個沉默缺口）;把 `ACTOR_RE` 收緊到能擋沒有空白的 CJK 裝飾（會同時改變 `steward-authority.py` 在所有 repo 的執行期行為，超出本 issue 範圍——見 `B-20260907-actor-key-decoration-limit`）;讓 `doc-governance.py` import `steward-authority.py`（vendored core 不得依賴 skill tree）;為了讓 19 個既有測試轉綠而放寬涵蓋檢查（那些 fixture 本來就不是合法配置，改的是 fixture 不是判準）
  - 重議:`plan_dir`／`history_paths` 之外再出現同型的「配置宣告了一個機制、卻沒有對應 class」的鍵;或 dead-glob 檢查本身需要區分「前置宣告」與「真的 stale」以外的第三種狀態
  - 關聯:M-20260907-doc-governance-silent-config-gaps;B-20260907-governed-repo-declared-path-gaps;B-20260907-actor-key-decoration-limit;scripts/doc-governance.py;claude/skills/project/scripts/steward-authority.py;docs/doc-governance-rollout.md;tests/run.sh

- **D-20260909-dossier-byte-budget-cjk · 2026-09-09 dossier 的 byte 上限從 24576 提到 30720，理由是 CJK 密度讓它比行數上限先開火**:`DOSSIER_MAX_BYTES` 原本以 krepo 收斂後的 ~85B/行反推 24KB，對齊 `DOSSIER_MAX_LINES=300`。但那個密度來自英數為主的 dossier；純中文一個字 3 bytes，sumo 的 `STATUS.md` 實測 **90.9 B/行**，300 行需要 27.3KB——結果 byte flag 在 **270 行**就開火，比行數上限早約一成。兩個代理因此互相矛盾：行數說還有空間、bytes 說當次收斂，而 flag 的收斂順序又把「蒸餾」列為最後手段，實務上卻逼著 agent 去砍理由與實測數字（本次 sumo 連續三輪 ship 都在削既有決策條目才擠得下新紀錄）。改成 30720 ≈ 300 行 × ~102B/行，讓 bytes 退回它原本的角色：**巨型單行架空行數代理時的後盾**，而不是中文 dossier 的實質行數上限。`DOSSIER_ENTRY_MAX_BYTES=800` 不動——5 行中文條目約 450–500 bytes，該上限仍有餘裕，且它防的是「一條塞多個決策」，與語言密度無關。
  - 日期來源:direct
  - 放棄:加逐專案 override（`ship-state.sh` 的門檻刻意是單一數值來源，逐專案覆蓋會讓「這裡為什麼沒被擋」變成要一個個查的問題）;把 byte 上限直接由 `DOSSIER_MAX_LINES × 密度常數` 算出（省不了決定密度的那一步，卻多一層間接）;維持 24576 並要求中文 dossier 自行蒸餾（那正是本次觀察到的失敗形狀）
  - 重議:出現英數為主的 dossier 因新門檻而長期超過 300 行卻不被擋的實例;或 dossier 改為以 token 數而非 bytes 計量
  - 關聯:claude/skills/project/scripts/ship-state.sh;tests/run.sh;sumo/STATUS.md

- **D-20260909-prod-tier-excluded-from-inventory · 2026-09-09 租賃機房 prod 主機刻意不進 `scripts/inventory.conf`，只擴充 `@cert-authority` 涵蓋範圍**:AI Search 新資訊服務系統的五台生產主機（`10.20.150.11-15`）落在租賃機房，與辦公環境（dev／stage）是不同信任域。本 repo 的 fan-out 腳本以 inventory 全體為預設目標——`dotfiles-sync.sh` 在每台 `git pull` 個人 dotfiles，`sign-host-keys.sh` 預設全體，`sign-user-key.sh --all` 亦然——而 `add-new-host.sh` Phase B 更會 `scp` `id_personal` 與 `id_github_com` 的**私鑰**到目標主機。`id_personal` 的憑證 principals 為 `jjshen,elsysman,root,admin,masterman` 且 `Valid: forever`，在同一信任域的辦公機隊是刻意保留的後路（CA 憑證失效時仍可登入），跨到對外機房則變成單台失陷即可回打整個辦公室機隊 root 與 GitHub org 的路徑，信任方向由最低流向最高。因此 inventory 維持 14 台（office 層），prod 的 `Host` 區塊改由 `ais-infra` repo 維護、寫入機器本地 `~/.ssh/config.local`（`ssh/config` 已 `Include` 它）。本 repo 只擴充 `ssh/known_hosts` 的 `@cert-authority` 涵蓋 `10.20.*.*`——那是純本機信任設定、不外送任何東西，卻是 host certificate 能被驗證的必要條件（原樣式不含該網段，會靜默退回逐條 fingerprint 提示）。順帶訂正 `docs/add-new-host.md` 早已與 `known_hosts` 不符的涵蓋清單（列了不存在的 `10.10.40.*`），並在該文件加註本流程只適用辦公環境。
  - 日期來源:direct
  - 放棄:把五台加進 inventory 再讓三支 fan-out 腳本認得分層（要改三支既有腳本並維護一份「哪些是 prod」的判斷，耦合仍在，且分層判斷本身會成為新的漂移面）;倚賴「記得不要加 `--all`」這種非機械性防線（本 repo 既有的 fail-closed 風格正是為了不依賴記憶）;把 prod 的 Host 區塊也放進 `ssh/config`（它由 `inventory.conf` 生成，留一份就等於留全部）
  - 重議:fan-out 腳本改為預設 fail-closed 且私鑰散佈改成 opt-in 時（屆時單一 inventory 才不再有信任外溢）;或 prod 與 office 合併為同一信任域
  - 關聯:ssh/known_hosts;docs/add-new-host.md;scripts/add-new-host.sh;scripts/inventory.conf

- **D-20260912-cross-runtime-outward-gate · 2026-09-12 push／merge gate 採共同語意 classifier＋runtime-native 控制面**:Claude Code 與 Codex 都保留既有高自主模式；共同 `outward-action-gate.py` 只分類真的 Git push／send-pack 與 GitHub PR merge，Claude PreToolUse 對 direct／wrapper 皆回 `ask`。Codex 的 PreToolUse 不支援 ask，故 direct canonical argv 由 execpolicy `prefix_rule(... decision="prompt")` 處理，shell wrapper、compound command 與 `git -C` 等無法由 prefix 精確表示的形狀則由 hook `deny` 並要求改用 canonical command 重送。Codex prefix rule 的已知保守邊界是 direct `git push --dry-run` 也會提示；若要排除它只能犧牲 direct canonical UX 或新增獲准 wrapper，代價高於一次無副作用 prompt。
  - 日期來源:direct
  - 放棄:關閉 Claude Auto／Codex danger-full-access；用共同 hook 在 Codex 回 ask（產品不支援且會 fail-open）；把所有 GitHub write 一律 tool-level prompt（超出本次只鎖 push／merge 的決定）；為排除 `--dry-run` 強迫所有真 push 改走自訂 wrapper
  - 重議:Codex PreToolUse 支援 ask，或 execpolicy 支援 suffix／negative predicate；任一 runtime 的 hook input／decision schema 改變；classifier 出現新的實際 bypass
  - 關聯:docs/plans/2026-09-11-cross-runtime-portability.md;scripts/outward-action-gate.py;claude/settings.json;codex/config.toml;codex/rules/default.rules;tests/run.sh

- **D-20260912-codex-config-three-layer-merge · 2026-09-12 Codex live config 改為 base→runtime-only→local 三層 merge，不再由 setup 複製整檔**:`ensure-codex-config.py` 讓 repo base 擁有它明列的 leaf，從 live config 只保留 base／local 未管理的 state，最後由 `config.local.toml` 覆蓋；輸出首行嵌入 managed-path manifest，解決 local 或 base 刪除後舊值被下一輪誤認成 runtime-only 而復活的黏著問題。yq 同時充當 TOML parser／renderer；所有輸入與 render 都先驗證，lock 阻擋第二個 helper writer，replace 前再比 target digest 抓外部 writer，候選檔與 target 同目錄後以 `os.replace` 原子換入。dotsync 同步改為 local pull／helper 與每台 remote 各自記狀態、全部嘗試後聚合，任何失敗回 1。
  - 日期來源:direct
  - 放棄:直接 append local TOML（duplicate table/key 可產生壞 config）；整檔覆蓋 live config（遺失 project trust 與 runtime state）；把 live config 所有 base 以外欄位永遠視為 runtime state（刪掉的 local key 會復活）；dotsync 遇錯立即退出（其餘主機失去更新與診斷）
  - 重議:Codex 提供原生 include/overlay 或把 runtime state 移出 config.toml；yq 取消 TOML 支援；需要多 writer transactional API 取代 digest guard
  - 關聯:docs/plans/2026-09-11-cross-runtime-portability.md;scripts/ensure-codex-config.py;scripts/dotfiles-sync.sh;codex/README.md;tests/run.sh

- **D-20260912-neutral-portable-skill-core · 2026-09-12 portable skill 核心收旂到 runtime-neutral `shared/skills/`**:先前的 portable 設計已確立雙薄入口、nested linkage 與 single eval oracle，但共用 references/scripts/evals 的實體仍住在 `claude/skills/`，讓路徑名稱持續傳遞「Claude 擁有、Codex 借用」的錯誤訊號，也讓更換 canonical location 被誤當成重做移植。現在共用資源統一位於 `shared/skills/<behavior>/`，該棵不放 `SKILL.md`；Claude Code 與 Codex 各保留 runtime-native entry/metadata/assets，以 nested symlink 指向 neutral inode。`deep-review` 只搬已證明 portable 的 workflow/brief/scope/terminal/eval subset，Claude-only compatibility helpers 留在 Claude adapter；`deep-plan` 的 Codex launcher/schema 同樣留在 Codex adapter。Codex 個人 entries 改安裝到官方共用 discovery root `$HOME/.agents/skills`；只在新 link 驗證成功後移除仍 resolve 到本 repo adapter 的 legacy `$HOME/.codex/skills/<name>` symlink，不碰實體目錄、斷鏈或第三方 target。
  - 範圍:只取代下列舊決策的 canonical-location／ownership 部分；既有的 portable behavior contract、runtime adapter 差異與 eval 證據仍有效
  - 日期來源:direct
  - 放棄:繼續把 Claude tree 當共用核心（ownership 訊號錯誤）；whole-skill symlink（無法保留雙端 entry/metadata 差異）；在 shared tree 放第三份 `SKILL.md`（會變成未定義的第三入口）；整批刪除 `$HOME/.codex/skills`（會傷及 system 與第三方內容）；重寫已 portable skill（重演 X-20260825）
  - 重議:Agent Skills 標準提供無 adapter 複製且可攜帶 runtime metadata 的單一入口；任一 runtime 不再 follow nested symlink；或 `$HOME/.agents/skills` discovery contract 改變
  - 關聯:D-20260822-portable-deep-plan;D-20260823-portable-deep-review;D-20260825-portable-skill-authoring-default;X-20260825-deep-plan-duplicate-port;docs/skill-portability.md;shared/skills;scripts/ensure-codex-skills.sh;tests/run.sh

- **D-20260913-project-merge-authorization-ci · 2026-09-13 Project merge 授權優先於 Claude 無上下文 outward hook，CI 防線前移到 required PR checks**:`/project --merge` 已由 Project shipping table 定義為同輪 push 與 merge 的明確授權，但 Claude Bash PreToolUse hook 只看單一 shell command，無法取得 normalized invocation，因而對兩個已授權動作各再發一次 approval UI。撤回 `c086aca` 的 Claude hook/runtime response，保留共同 classifier 與 Codex canonical prompt／opaque deny；組合回歸把 Project `--merge` 執行 push＋merge 的額外 approval UI 數固定為 0。CI 保留 PR 的 macOS 15＋Ubuntu 24.04 完整 suite，取消 merge 後 `push: main` 的同套重跑；main 改由兩個 GitHub Actions matrix contexts 作 required checks，對 admins 生效但 `strict=false`，避免 base 更新強迫重跑。ShellCheck、doc-governance deterministic suite 與 fixture-heavy 主流程並行，只重疊獨立唯讀工作、不刪覆蓋。
  - 範圍:取代 `D-20260912-cross-runtime-outward-gate` 的 Claude hook 部分；其 classifier、Codex gate 與已知 `--dry-run` 保守邊界仍有效
  - 日期來源:direct
  - 放棄:讓 Claude hook 自行辨識先前 `/project --merge`（hook input 沒有 invocation context）;保留 merge 後完整重跑（壞 main 已發生且成本重複）;把 main run 改排程（PR 雙平台已覆蓋同一 suite，排程沒有新增環境維度）;開啟 strict required checks（會因 base 更新增加重跑與等待）;刪除慢測試換時間（失去既有 oracle）
  - 重議:Claude hook input 能可靠攜帶 normalized skill invocation 與同輪授權；PR 與 main 的執行環境或測試集合分化；或 GitHub required-check context 名稱、runner matrix 改變
  - 關聯:D-20260912-cross-runtime-outward-gate;M-20260912-outward-gate-and-auto-mode-drift;scripts/outward-action-gate.py;claude/settings.json;.github/workflows/test.yml;docs/testing-contract.md;tests/run.sh

- **D-20260913-company-mac-nonblocking-identity-rollout · 2026-09-13 公司 MacBook 改為非阻斷、喚醒後才本機收斂的 identity rollout 邊界**:`inventory.conf` 14 台與家中 MacBook 已完成並通過 `setup-git-identity.sh --check`；休眠中的公司 MacBook 不在 inventory，使用者明確決定它不再阻塞主 rollout。這不把該機宣告為退役：若恢復用它開發，應在第一次 commit 前於該機執行 `brewup`、`setup-git-identity.sh --apply` 與 `--check`，但不為結案喚醒機器或執行遠端 mutation。
  - 日期來源:direct
  - 放棄:繼續讓一台不在管理 inventory、長期休眠的端點無限阻塞已完成的主 rollout；把它虛構成已退役或已驗證；為了結案遠端喚醒並改寫設定
  - 重議:公司 MacBook 恢復為日常開發端點；或被正式納入 inventory／集中端點管理
  - 關聯:B-20260902-identity-fleet-rollout;D-20260902-git-identity-directory-boundary;M-20260902-git-identity-directory-boundary;scripts/setup-git-identity.sh;scripts/inventory.conf

- **D-20260915-retain-codex-plugin-as-optional-bridge · 2026-09-15 Codex Claude plugin v1.0.6 保留為按需 bridge，不作 repo canonical review layer**:重新盤點實體 artifact 後確認 plugin 有八個 commands，不是 B20 舊前提的「只剩 transfer」：`transfer` 把目前 Claude JSONL session 匯入持久 Codex thread 並產生 `codex resume`，不同於 Project 的 durable owner transfer 與 handoff 的同機 checkpoint；`rescue` 提供含 current-session resume、background、model／effort routing 的一般任務委派，repo-local exec／skills 沒有等價的 Claude slash-command context bridge，且本機 state 有 2026-04-12 至 2026-07-04 的 24 筆 completed task jobs；`review`／`adversarial-review` 與 portable deep-review／repo-review 高度重疊，故只算 convenience、不是治理權威；`status`／`result`／`cancel`／`setup` 是上述 job/runtime 的支援面。三個 bundled skills（CLI runtime、result handling、GPT-5.4 prompting）、rescue agent、session hooks 與 lazy broker 都是 bridge 的實作支援，不另算獨立保留理由。現況 setup 為 ready/direct、沒有 active shared runtime，Stop hook 雖註冊但 `stopReviewGate=false`；隔離的 upstream suite 91/91 通過，包含 transfer、task、review、background jobs、broker 與 hooks。官方可支援的「縮減」只有維持 Stop review gate 關閉，沒有 per-command enable/disable；手改 cache 或拆 plugin 會製造未受支援的 fork。因此保留完整 `codex@openai-codex` 啟用與既有 brewup/install 管理，不改 repo config，也不解除安裝或刪 plugin data；canonical review 仍走 repo-local deep-review／repo-review，plugin 只在需要 session import 或 Claude→Codex 任務橋接時按需使用。
  - 日期來源:direct
  - 放棄:沿用「只剩 transfer」舊前提直接移除（漏掉已實際使用的 rescue 與其 session-aware orchestration）；把八個 commands／三個 skills 的數量本身當保留理由；把重疊的 plugin review 升為 canonical workflow；手改 plugin cache、command files 或 hooks 假造細粒度縮減；開啟 Stop review gate（目前無需求且會增加每次 Stop 的時延與阻擋面）；因歷史 broker 問題移除整個 plugin（2026-07-20 證據只支持 deep-review 改走 headless exec）
  - 重議:Claude Code 或 Codex 提供等價的 native session import／session-aware delegation；plugin 正式支援 per-capability enable/disable；bridge 再出現無 watchdog 的卡死／idle 成本；或到 2026-12-31 仍沒有新的 rescue／transfer 使用證據
  - 關聯:B-20260820-debt-20;docs/archive/decisions-2026-07.md;D-20260823-portable-deep-review;D-20260823-portable-handoff-skill;M-20260824-memory-independent-transfer;claude/settings.json;scripts/brewup.sh;scripts/claude-plugin-install-hints.sh

- **D-20260915-b27-cross-language-boundary · 2026-09-15 B27 不以全域翻譯層修單一英文政策的中文查詢**:事前固定的四條中文 query 對全英文 `docs/document-governance.md` 均未直接命中，但 top 5 已回傳中文的 decision、dossier、testing contract 或 template，可回答其中三類問題；樣本只涵蓋一份語言政策要求英文的文件，不能支持一套全域翻譯字典。B27 保留 lexical、pointer-free 的 `find`，不新增 `query_aliases`、答案詞注入或中英對照 ranking；跨語言問題先由同語言權威／關聯來源承接，真正必須直達的主題仍應使用承重且具主題詞的 H2。
  - 日期來源:direct
  - 放棄:以四題建立全域中英字典（過擬合且沒有未知詞行為）；在 config 注入 query 對 answer path（oracle 洩漏）；把英文治理規範改成雙語（違反既有定向英文政策）
  - 重議:至少三個獨立真實 repo 持續出現「同語言替代來源也無法回答」的跨語言 miss，且有可預註冊、非答案注入的共同詞彙層
  - 關聯:B-20260821-debt-27;tests/fixtures/doc-governance/b27-current-baseline.tsv;X-20260822-doc-h1-token-signal;X-20260823-retrieval-idf-and-h3-chunking

- **D-20260916-deep-review-self-report-accepted-limit · 2026-09-16 deep-review 同型處置表的內容誠實度維持人工證據、接受不可機檢限制**:盤點現行契約與 2026-08-11 後可取得的 Git／GitHub 實證，未找到同時具備「終態表完整、實際殘留同型問題、流程仍放行」的案例。最接近的 PR #123 確有後輪補 removal axis，但持久紀錄未保存完整終態表，且合併前另以九格機械重驗收斂，不能倒推成填表敷衍。F22／F23 已覆蓋可構造的修復行為；R5 預造未實際執行的四輪修復仍只會測到 fixture 缺陷。因此維持結構 gate 與人工查證，不新增內容評分器或 R5 behavior eval。
  - 日期來源:direct
  - 放棄:以自然語言完整度評分冒充行為 oracle；預造無法誠實填寫的 R5 修復歷史；把缺少持久終態表自行補推為失敗證據
  - 重議:保留下來的真實終態報告三軸皆填，之後卻證明同一規則仍有漏修且當時流程放行；屆時以該 exact report、commit 與殘留取得 RED
  - 關聯:B-20260811-gap-03;PR#123;docs/archive/decisions-2026-08.md;shared/skills/deep-review/evals.md;shared/skills/deep-review/references/report-templates.md;tests/run.sh

- **D-20260917-terminal-macbooks-outside-inventory · 2026-09-17 兩部 MacBook 刻意作為 inventory 外的自主更新終端**:`B-20260809-gap-10` 的未決問題是兩部 MacBook 未納入 `inventory.conf` 屬於刻意邊界或尚未修復的缺口。現行證據支持前者：`inventory.conf` 服務可穩定 SSH 連線並接受 fan-out 管理的辦公機隊，常離線的筆電納入後只會讓 `dotsync`／`allup` 持續出現非行動性失敗。`docs/repo-guide.md` 已給 inventory 外機器明確的本機 `git pull`＋`brewup` 路徑，2026-08-15 也實測兩機皆為 function 版，`brewup.sh` 能在 pull 換掉自身時當輪 re-exec；這是受支援的主動更新模型，不是遺漏實作。家中 MacBook 已完成現行 identity rollout，長期休眠的公司 MacBook 則依 `D-20260913-company-mac-nonblocking-identity-rollout` 在恢復使用時才本機收斂。因此不建立 laptop-specific fan-out、不為清 backlog 製造持久監控或離線噪音，並移除該 backlog 條目。
  - 日期來源:direct
  - 放棄:把常離線終端加入辦公機隊 inventory；來回打洞的 laptop-only fan-out 清單；只為偵測偶發本機漏跑而新增持久監控或啟動告警；將休眠中公司 MacBook 虛構為已驗證或退役
  - 重議:任一 MacBook 恢復為常態開發節點且本機更新模型造成可重現的行為漂移；需要從中央穩定觀測或管理終端；或 inventory fan-out 日後能對長期離線節點靜默降級且不稀釋真失敗訊號
  - 關聯:B-20260809-gap-10;D-20260913-company-mac-nonblocking-identity-rollout;M-20260913-identity-fleet-rollout-complete;docs/repo-guide.md;scripts/brewup.sh;scripts/inventory.conf

- **D-20260918-biz-chat-backlog-out-of-scope · 2026-09-18 非正式 biz-chat 不再由 dotfiles backlog 追蹤**:`B-20260820-gap-08` 原本混合兩個 ownership：dotfiles 的 Project transfer credential artifact guard，以及 biz-chat 自身的 tracked literals、`.env.example`、transfer path 與 credential rotation。前者已由 `M-20260917-gap-08-dotfiles-transfer-guard` 與後續 portability 修正完成；剩餘內容只屬於 biz-chat。使用者確認 biz-chat 不算正式專案並決定直接關閉，因此不在 biz-chat 建立 backlog／issue，也不繼續以 dotfiles 作為跨 repo 提醒清單；移除 B08，但不撤回既有 metadata-only、fail-closed transfer guard。
  - 日期來源:direct
  - 放棄:把非正式 repo 納入完整 project-governance；在 biz-chat 建立 backlog／issue；繼續讓 dotfiles 承擔它無 authority 修正的 target-local debt；讀取或搬運任何 secret 值
  - 重議:biz-chat 日後成為正式維護專案、出現實際跨機器移交需求，或其 credential／transfer 狀態造成可重現的部署或接手阻塞；屆時以 biz-chat 為 target 另案建立狀態，不復活 dotfiles 的跨 repo backlog
  - 關聯:B-20260820-gap-08;M-20260917-gap-08-dotfiles-transfer-guard;M-20260917-gap-08-ci-portability-fixed

- **D-20260920-claude-auto-mode-contract-maintenance-boundary · 2026-09-20 Claude Auto mode 的契約維護採精確 allow、結構化編輯與不可跨越的 Kernel 邊界**:Issue #228 的 2026-09-18 證據顯示唯讀 `record-path` 曾被判 `[Security Weaken]`，已明確授權且只改 repo-specific 契約文字的 Python heredoc 曾被判 `[Self-Modification]`，相同內容換 `Edit` 則通過；但 Claude Code 2.1.278 的 Opus／Sonnet 重播已無 denial，官方 built-in `Self-Modification` 規則也明載 exact user request 應放行，因此歷史 classifier 根因維持 UNCONFIRMED，不把本批宣稱為上游修復。Local containment 分成兩層：`autoMode.allow` 只涵蓋 `doc-governance.py` 的 `find`／`record-path`／`report`／`audit`，明寫 `record-path` 只計算並輸出 path／ID、排除 transcript 內先前已修改 script、其他 subcommand、redirection／writer pipeline 與 import；always-on Claude contract 則把 exact authorization 限在具名 repo-specific edit，managed Kernel／higher-priority instructions／permissions／hooks／Auto rules 一律不隨之放寬，正式修改只用 `Edit`／`Write`。G14 將 classifier 與 contract 分臂：A/C/D 在 Sonnet GREEN，B 因模型拒絕產生 heredoc tool call 而只取得內容 GREEN、classifier UNVERIFIED，不拿未送進 classifier 的命令冒充證據。
  - 日期來源:direct
  - 放棄:寬放 `Bash(scripts/doc-governance.py *)` 或 `python3 ... *`（未來寫入子命令與本輪竄改 script 會一起繞過 classifier）；把使用者的 repo-specific 授權延伸成 Kernel／permission 授權；只把慣例放進按需載入的 skill-building guide；因現版重播已綠就刪除 observed incident；把 `Edit` 通過推論成 Bash classifier 也通過
  - 重議:任一精確相同的 helper／contract-edit 情境在 supported Claude Code 再次產生 denial；`doc-governance.py` 任一列出的 subcommand 開始寫檔；Auto mode config scope／precedence 改變；或能以公開 classifier harness 穩定直送 tool input、讓 G14 B 取得可歸因結果
  - 關聯:Issue#228;M-20260920-issue-228-auto-mode-containment-complete;claude/settings.json;claude/CLAUDE.md;claude/evals/contract-evals.md;claude/evals/setup-sandboxes.sh;tests/run.sh

- **D-20260922-handoff-current-grant-candidate · 2026-09-22 #229 第一個候選只調整 handoff 當次授權辨識**：正式 GPT-5.6 Sol/high 與 Claude Code Opus 5 各兩個完整 fixture baseline 都在當次已明列 repo／兩檔／local test 授權後重問一次；候選 1 只將既有 R3.5 改成先比對 verified plan 與 current grant，涵蓋才不重問。Normal-path 前後各 2/2 完成，所需 user turns 2→1；尚待 safety controls，不代表已接受或 rollout。原 H15 的 vague grant、stale claim 與 consume-before-consent oracle 保留，新增 H16 normal／H17 scope-gap controls；不改 kernel、模型預設、portable topology 或 helper 安全語意。
  - 日期來源:direct
  - 放棄:刪掉整個 authorization gate；把 Sol/medium 探索結果當 Sol/high 正式驗收；以 no-findings prose review 放行；將 review/stewardship 等其他根因混入本批
  - 重議:任何 primary-runtime／較弱模型安全控制回歸；scope/ownership conflict 被 current grant shortcut 掩蓋；或同一授權中斷只是被搬到別處
  - 關聯:GitHub #229；D-20260830-codex-trusted-approval-flow；X-20260830-handoff-resume-unbounded；docs/plans/2026-09-22-workflow-audit.md；shared/skills/handoff/evals.md

- **D-20260922-handoff-task-reference-authorization · 2026-09-22 #229 當次續作請求可引用查證後的任務範圍授權本地 edit/test**：使用者在「直接完成 verified scope 內的本地修改與測試」與「即使範圍清楚也再列檔案確認」間明選 1。當次請求是授權來源，交接只是待查證的 task data；不得把當次引用任務誤稱為使用者逐字明列 paths，也不得繼承 artifact 舊 commit／push／merge claim。實際 scope、ownership 或決策衝突仍須有用的單次詢問，outward／irreversible／destructive 邊界不變。supersedes:D-20260830-codex-trusted-approval-flow 僅其 unconditional resume batch 部分；trusted config／pending approval lifecycle 不變。原兩版候選未滿足當時 oracle 的結果保留，不追溯改判；新 contract 限一版調整與事先固定的雙端 safety/normal eval，尚未接受或 rollout。
  - 日期來源:direct
  - 放棄:要求使用者重述已查證任務的 exact paths 才認當次授權；把 H15 第二次回答本身永久當安全 outcome；把 stale grant 或單純讀取／檢查請求當作續作授權；為消除重問而略過 verify、live scope／writer conflict
  - 重議:read-only／明確縮限 scope 被突破；模型沿用舊 outward claim；當次引用任務被偷換成任務擴張；必要詢問回答後仍不能續作
  - 關聯:GitHub #229；D-20260922-handoff-current-grant-candidate；X-20260830-handoff-resume-unbounded；docs/plans/2026-09-22-workflow-audit.md；shared/skills/handoff/evals.md

- **D-20260923-project-session-workline-binding · 2026-09-23 #229 同session工作線指派與逐批action授權分離**：使用者在當次session明確接續整條same-runtime工作項，且原durable assignment已查證時，後續Project invocation不再強制重問resume。既有authority helper以獨立provenance及canonical root／active item identity／Writer／Workspace／Write Scope／Steward fingerprint重驗，HEAD每輪重新查證；routine progress與commit前進不抹掉指派，assignment改變或item移除則STOP。Fingerprint是freshness而非authentication，不存成authority store；human delegation、cross-runtime、PREPARED transfer、session替換與各批outward authorization維持原邊界。雙primary native Spec before重問、after完成，scope-change反例及一次新指示後續作皆有產物證據；不宣稱完整shipping或模型wall time改善。supersedes:D-20260825-project-prompt-bound-authority-recovery 僅其對明示整條workline指派也一律限單invocation的部分；單次prompt確認原義不變。
  - 日期來源:direct
  - 放棄:刪除initial authority gate；用branch名稱當永久actor；將舊單次resume擴成長效授權；只重用resume flag而不驗scope／writer freshness；新增private receipt／lease／daemon；逾時後反覆重跑guided-options求綠
  - 重議:正常工作因binding失效仍反覆問相同問題；scope／owner變動或新session沿用舊binding；舊endpoint被繼承；完整Log／多repo實作暴露新的正常路徑或安全回歸
  - 關聯:GitHub #229；D-20260824-project-steward-authority；D-20260825-project-prompt-bound-authority-recovery；docs/plans/2026-09-23-coordination-audit.md；shared/skills/project/references/pressure-tests.md；tests/project-session-binding.py

- **D-20260923-risk-triggered-plan-review-direction · 2026-09-23 使用者選擇風險觸發完整計畫審查**:一般工作以明確驗收條件及小增量推進；有具體高風險才啟動完整多輪審查。先以隔離prototype驗證雙日常runtime的正常／安全路徑，未通過前不改production defaults；本決策不是略過既有安全、使用者明示完整review或outward authorization的許可。
  - 日期來源:direct
  - 放棄:維持每份計畫無條件完整多輪；重跑已reject的finding措辭候選求綠
  - 重議:normal path錯誤跳過具體高風險，或雙runtime原型無法在固定budget內正確完成
  - 關聯:docs/plans/2026-09-23-review-convergence-audit.md;GitHub #229

- **D-20260923-project-local-reassignment · 2026-09-23 #229 同機明確改派不強制遠端Transfer**：單repo唯一active item、前任已停且使用者當次明確改派工作與文件維護、clean matching feature workspace、無其他writer／未整合work／pending transfer時，Project Spec先只更新Writer與Dossier Steward，再以原authority helper PASS後續作。改派來源是當次指示，不是冒充舊actor或繼承action授權。雙primary正常與活躍writer反例完整通過，Sonnet安全分類保留；候選1失敗紀錄不改判。supersedes:D-20260824-project-steward-authority 僅窄同機順序改派被無條件導向正式Transfer的部分；其他authority、parallel與endpoint安全邊界不變。
  - 日期來源:direct
  - 放棄:無條件刪除authority／transfer會失去真衝突防護；另建helper／store無必要證據；重複執行必然因舊actor而STOP的pre-mutation probe不產生新的授權證據。
  - 重議:normal或conflict regression、單repo前提不足以防止in-flight遺失、或真實多item／跨repo接手需要新機制時；不把本次小fixture外推為完整遠端移交或shipping驗收。
  - 關聯:GitHub #229;docs/plans/2026-09-23-coordination-audit.md;shared/skills/project/references/pressure-tests.md;D-20260923-project-session-workline-binding

- **D-20260923-review-terminal-native-display · 2026-09-23 #229 修正macOS terminal evidence空白輸出**：native terminal-boundary replay暴露既有anchor三欄存在而show空stdout/exit0；system-tool probe確認BSD sed BRE alternation是第一個差異點。只改成portable ERE，使兩runtime共用helper輸出原有reason/head/time，不改terminal schema、record/clear、workflow verdict或review budget。此為獨立observability修復，不把原污染後PASS或Sol收尾逾時歸成同因。
  - 日期來源:direct
  - 放棄:新增治理警語或terminal裁判helper；要求agent每次手讀anchor繞過show；安裝GNU工具當必要前提；用小型replay替完整code-review PASS背書
  - 重議:macOS/Linux system-tool output回歸、anchor唯讀性或clear coverage改變、完整native流程仍把已知無效review判PASS時另依原root處理
  - 關聯:Issue#229;docs/plans/2026-09-23-review-convergence-audit.md;shared/skills/deep-review/evals.md;D-20260823-portable-deep-review

- **D-20260923-review-validity-causal-boundary · 2026-09-23 #229 搜尋恢復越界與review有效性分開處置**：原Opus verification dispatch已明禁父目錄；限定雙repo的grep遇zsh未quote glob錯誤後，Grep改搜父目錄，實際回傳作者目標與plan。Reviewer自揭露仍報無blocking，parent亦知隔離不足仍PASS。接受這條實際工具／結果路徑，拒絕把它當成缺少隔離警語或terminal顯示問題；沒有新行為證據前不改brief／workflow、不重跑已正確分類的cold packet。
  - 日期來源:direct
  - 放棄:宣稱前輪finding正文必已曝光（tool output多為Omitted long matching line）；把正確程式判成缺陷以再修；只搬走eval trace就宣稱一般runtime隔離修好；以追加治理文字取代機制證據
  - 重議:替代機制能在相同native條件保住搜尋失敗恢復的範圍、完成正常跨repo檢查，且真實污染不能產生有效獨立PASS時；現有完整流程FAIL仍保留
  - 關聯:Issue#229;docs/plans/2026-09-23-review-convergence-audit.md;D-20260923-review-terminal-native-display

- **D-20260924-workflow-bounded-delivery · 2026-09-24 #229 從擴張稽核收斂為有界交付**：使用者明確要求保留已驗證改善、不重測，優先已授權工作持續推進與review不擴張目標；只用一個雙primary多步驟任務驗收，失敗列限制而不疊加規則／補跑。局部audit或experiment結束不再當作需要使用者說「繼續」的邊界；只有真實產品選擇、衝突、缺能力／授權或約定交付完成才交回。此次是執行契約收斂，不假稱全域runtime行為已修，也不更動kernel。
  - 日期來源:direct
  - 放棄:持續追查reviewer污染佔據全部工作；重測已綠案例；以新增治理文件數量當進展；未驗證的prose候選落地
  - 重議:本輪整合case或日常工作出現可歸因新失敗時，針對原root與實际授權邊界處理，不重開全流程優化
  - 關聯:Issue#229;docs/plans/2026-09-23-coordination-audit.md;docs/plans/2026-09-23-review-convergence-audit.md

- **D-20260924-review-repair-verification-choice · 2026-09-24 #229 選擇首次全面審查、修後聚焦受影響契約**：使用者明選首次完整獨立審查後，只驗實際修復與semantic dependents；具體新風險才擴大。先以code-review autofix單一候選驗收，deep-plan不混改。Fresh context、初次完整coverage、scope drift、必要checks與真實blocker仍承重；修後定位資訊不等於作者結論可信。此為方向決定，不宣稱candidate已通過或#229結案。
  - 日期來源:direct
  - 放棄:每次修復後重新抽樣整份未變scope；完全取消review；把聚焦驗證冒稱又一次完整盲審
  - 重議:相同task的雙primary驗收或安全對照失敗；新風險跨出已知依賴範圍；初次coverage或delta來源不可驗證
  - 關聯:Issue#229;docs/plans/2026-09-24-review-followup-design.md;D-20260924-workflow-bounded-delivery

- **D-20260924-continuation-bounded-closeout · 2026-09-24 #229 接續候選收斂交付、不追加模型驗收**：使用者選擇先交付已驗證改善與明列限制，不追加 lifecycle 候選驗收預算。Stop prototype 機制可用但未證明效率提升，lifecycle 候選有歷史 failure evidence 但模型驗收受 fixture 缺陷污染；兩者均不採用、不部署。保留既有改善與 backlog，不以文件整理冒充 #229 完成。當前 active contract 僅保留待提交／結案證據；本選項不授予 commit／push／merge。
  - 日期來源:direct
  - 放棄:修好 harness 就自動重開模型批次；以部分成功洗綠；再加 always-on 規則；要求使用者用「繼續」確認同一收斂方向
  - 重議:使用者另行決定新的限定驗收工作；不得自動重設本批已耗預算或重測已綠改善
  - 關聯:Issue#229;B-20260924-workflow-verification-economy;docs/plans/2026-09-24-ci-continuation.md
