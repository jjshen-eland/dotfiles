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
