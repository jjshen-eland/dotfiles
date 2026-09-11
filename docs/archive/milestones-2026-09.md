# 里程碑歸檔 — 2026-09

## 事件記錄（event-time）

- **M-20260901-container-network-collision-safety · 2026-09-01 Claude Code／Codex container-network 撞網防線完成**:shared kernel 已同步到 portable `AGENTS.md`、Claude 全域來源與 Codex 全域來源；kernel gate 新增必要指紋與實際 RED fixture，會阻止三份同步但安全條款被抽掉的假綠。G13 以真實事故作 observed RED：第一版 Claude GREEN、Codex 只過 3/4 且漏 cleanup isolation-table check；未放寬 oracle，將條文最小收緊為「未檢查 isolation table 就不算 cleanup 完成」後，Codex 與 Claude fresh sessions 都滿足四項判準。行為 eval 未給 shell/write 能力、沒有建立 Docker network；`./tests/run.sh` 最終 1243 PASS／0 FAIL，doc-governance ship audit 與 clean-clone verification 隨同本 work item 完成。
  - 日期來源:direct
  - 放棄:把 Codex 第一輪 3/4 當足夠；只以文字存在取代 runtime 行為驗證；在 eval 中真的重建肇事 network
  - 重議:G13 任一 runtime 回歸；kernel native loading 或 OrbStack isolation 行為改變；或 deterministic host-route preflight 能取代 prose gate
  - 關聯:D-20260901-container-network-collision-safety;claude/evals/contract-evals.md;tests/kernel-gate.py;tests/run.sh

- **M-20260902-agent-turn-end-timestamps · 2026-09-02 Claude Code／Codex 等待輸入時間戳完成**:兩個 runtime 的主 agent `Stop` hook 已接到同一支 `scripts/agent-turn-end-timestamp.sh`，每次完成回應、回到等待使用者輸入時，以共用 `systemMessage` JSON 顯示 `🕒 等待輸入起點：YYYY-MM-DD HH:MM:SS GMT+8`。Script 強制 `Etc/GMT-8`、不回顯 hook input，且 `date`／stdout 失敗仍 exit 0；只接主 agent `Stop`，不接 subagent。Codex 0.152.1 已成功解析 live config，live hook 區塊與 repo 版一致且未覆蓋本機模型、reasoning、Computer Use notify 與 project trust；Claude settings 由既有 symlink 即時生效。先寫 RED 後實作，`./tests/run.sh` 最終 1253 PASS／0 FAIL。
  - 日期來源:direct
  - 放棄:對 Claude hook 寫 `/dev/tty`（官方明示 hook 無 controlling terminal）；只用 Codex `notify`（無法與 Claude 共用 UI 輸出契約）；以整檔 repo config 覆蓋 live Codex config（會遺失本機 drift 與 trust）
  - 重議:任一 runtime 取消 `Stop` 的 `systemMessage` 支援；Codex hook trust lifecycle 改變；或產品提供非 warning 樣式的原生 turn-end 文字列
  - 關聯:STATUS.md;claude/settings.json;codex/config.toml;scripts/agent-turn-end-timestamp.sh;tests/run.sh

- **M-20260902-network-isolation-collision-detector · 2026-09-02 OrbStack PF isolation CIDR 機械偵測完成**:`scripts/check-network-isolation-collisions.py` 會唯讀取得 macOS `com.apple.internet-sharing/network_isolation` anchor 的 IPv4 table／rules 與本機介面網段，用實際 CIDR overlap 判斷而非字串相等；只豁免同一 anchor 明示 `pass quick` 的 exact managed interface/network pair，避免把 OrbStack 自己的 bridge 當事故。碰撞回 `verdict: STOP`／exit 1，列出 isolation、interface、local subnet、address 與 agent 處置；讀取、權限或解析證據不足回 STOP／exit 2，不冒充 CLEAN。輸出禁止自動刪 PF entry，要求 restart／firewall mutation 前另取授權；fixture 明示不是 live-host proof，CLEAN 也明示不涵蓋 routed／production／candidate CIDR。實機唯讀驗證 6 個 isolation CIDR、8 個 local subnet、4 個 managed exemptions，目前 CLEAN；完整 suite 1264 PASS／0 FAIL。
  - 日期來源:direct
  - 放棄:把所有 `bridge*` 介面一律忽略（可能漏掉真實 host bridge）；把 isolation table 與所有介面直接比對（會固定誤報 OrbStack managed bridge）；碰撞時自動 flush PF、刪 network 或重啟 OrbStack；把 fixture CLEAN 當 live host safety proof
  - 重議:OrbStack／macOS 改變 anchor、table 或 pass-rule 格式；需要納入 IPv6、routed-only/VPN production routes 或 first-attach candidate CIDR；或 PF table 可無權限可靠讀取
  - 關聯:D-20260901-container-network-collision-safety;scripts/check-network-isolation-collisions.py;tests/run.sh

- **M-20260902-missing-interface-route-detection · 2026-09-02 容器網路殘留的第二種形態（介面直連路由消失）納入同一支機械偵測**:同一次容器網路撞網會留下兩種互相獨立的殘留——PF isolation table entry（殘留 A）與**實體介面自己的直連網段路由被 bridge 接走且拆除時不還原**（殘留 B）。只清 A 會讓 B 帶著不同症狀存活:PF 讀起來完全 CLEAN，同網段主機卻完全連不進來，因為回包查不到 /24 直連路由而落到 default gateway，非對稱路徑被丟。2026-09-02 實機即為此形狀——`check-network-isolation-collisions.py` 當日回報 CLEAN 時 SSH 已斷，抓包顯示 SYN 由對方 MAC 直達、SYN-ACK 卻送往 gateway MAC，`10.10.12/24` 整條不在路由表、只剩兩條 /32 host route。偵測改為唯讀取 `netstat -rn -f inet`，對每張 UP+RUNNING、非 loopback／point-to-point、prefixlen<32 的介面要求其網段路由存在**且 Netif 綁在該介面本身**;網段還在但綁到 bridge 一樣判 STOP 並點名接管者（`claimed-by=`）。缺失回 `verdict: STOP`／`reason: MISSING_INTERFACE_ROUTE`／exit 1，附可直接執行的 `route -n add` 指令並明示該修復不持久、重開機同樣會重建。fixture mode 改為要求四項證據齊全（缺 `--routes-file` → exit 2），介面 flags 不可解析時不猜 UP／down 直接 fail closed。以 2026-09-02 故障當下的真實路由快照回放驗證:精確指出 en0 缺 `10.10.12.0/24`、零誤報;實機唯讀驗證 6 條直連路由目前 CLEAN;`./tests/run.sh` 1277 PASS／0 FAIL。
  - 日期來源:direct
  - 放棄:只檢查網段是否存在而不驗 Netif 綁定（會放行 bridge 接管，正是最難目視發現的形態）;用 `route get` 逐一探測（落到 default gateway 與正常直連在輸出上難以機械區分）;把 `--routes-file` 設為選填（fixture 模式會靜默跳過一整類檢查，等於製造假 CLEAN）;把路由檢查擴到 Linux（此腳本身分是 macOS PF 殘留偵測，混入跨平台路由檢查會失去單一職責）;偵測到缺失時自動補路由
  - 重議:macOS `netstat` destination 欄的 classful shorthand 或欄位順序改變;需要納入 IPv6 路由、ifscope／policy-based routing;OrbStack 改為拆除時自行還原介面路由;或出現持久化的修復手段使「不持久」的告警文案失真
  - 關聯:M-20260902-network-isolation-collision-detector;D-20260901-container-network-collision-safety;D-20260902-container-residue-detection-layer;scripts/check-network-isolation-collisions.py;tests/run.sh

- **M-20260902-git-identity-directory-boundary · 2026-09-02 git commit 身分改由目錄分界機械決定，捏造身分這條路被封死**:分界規則進共用 `git/config`——`user.useConfigOnly = true` ＋ 三條 `includeIf`（`~/Projects` 工作、`~/SideProjects` 個人、`~/.dotfiles` 工作），指向固定檔名 `~/.gitconfig-work` / `~/.gitconfig-personal`，共用層**不含任何 email**。新增 `scripts/setup-git-identity.sh`（dry-run 預設、`--apply` 才動手、`--check` 唯讀）在各機器生成 600 權限的身分檔，並移除 `~/.gitconfig` 殘留的寫死 `[user] email`（先備份）——那個殘留會贏過分界，讓分界外的 repo 安靜地用錯身分。值的優先序為 flag → 既有身分檔 → `~/.gitconfig` 舊值 → 互動提問，讓 12 台寫死工作 email 的機器一鍵繼承而不必重打；真的無值可繼承時 STOP 且零 mutation。`--check` 的解析驗證一定在**真的 repo 裡**做:`includeIf gitdir:` 要有 repo 才會被求值，站在非 repo 目錄問或用 `GIT_DIR=` 指不存在路徑都回空值，那是「沒有 repo 可判定」不是分界壞了。連帶:`proj` 與 `migrate-github-remotes.sh` 預設根都補上 `~/SideProjects`，兩個專案根改由 setup 腳本建立;`gh/config.yml` 的 `git_protocol` 由無效的 `https` 改為與實際生效值一致的 `ssh` 並寫明 `hosts.yml` host 層優先;`setup-mac-env.sh`／`setup-linux-env.sh` 移除「請自己 `git config --global user.email`」這段已與新設計矛盾的舊指引，改為 include → 建目錄 → 身分檢查的順序;`add-new-host.sh` 與 `docs/add-new-host.md` 補上新主機的身分收尾。macs 的 `~/SideProjects` 已建立、`~/Projects/isdotgd`（個人 repo 坐在公司目錄）已搬入。`tests/run.sh` 新增第 23c 節 31 條，用三個沙盒 home 實測**真的 git repo** 的 `GIT_AUTHOR_IDENT` 而非設定檔長相，含「收斂前分界外確實取用寫死身分」這條前提釘樁與「分界外 → `Author identity unknown`」這格核心斷言;全 repo 1308 PASS／0 FAIL。
  - 日期來源:direct
  - 放棄:用設定檔內容比對代替實測 `GIT_AUTHOR_IDENT`（測不到 include 順序與 includeIf 求值）;在單一沙盒裡同時測「繼承 legacy」與「無值 STOP」（前者會先把 legacy 清掉，後者於是恆綠——首跑即以假綠形式出現）;`GIT_DIR=` 指向不存在路徑當作分界探針（回空值，會被誤讀成分界失效）
  - 重議:出現必須在兩個根之外長期工作的常態需求;或 git 提供依 remote owner 判定身分的條件
  - 關聯:D-20260902-git-identity-directory-boundary;D-20260902-gh-protocol-host-scoped;B-20260902-identity-fleet-rollout;B-20260902-gh-account-autoswitch;docs/plans/2026-09-02-git-identity-boundary.md;scripts/setup-git-identity.sh;git/config;tests/run.sh

- **M-20260907-doc-governance-silent-config-gaps · 2026-09-07 doc-governance 三個沉默的配置缺口收斂，audit 與 authority gate 判準對齊**:`self_governance_findings` 新增 `plan_dir has no matching class` 與 `history_paths has no matching class`，以探針路徑走 scanner 自己的 glob 語意判涵蓋;`class_findings` 的 dead-glob 檢查同步豁免這些前置宣告的 glob，讓「即使目錄還沒有檔案也要建 class」實際做得到，無關的死 glob 仍照報。`status_findings` 的 `active_item_contract` 改以共用 `ACTOR_RE` 驗 `Writer` 與 `Dossier Steward` 的形狀，`unassigned` 檢查也走同一條正規化路徑，反引號裝飾的繞過因此消失。`ACTOR_RE` 的兩份複本由 `tests/run.sh` 新 gate 逐字比對（已實測改一個 byte 會紅）。以 issue 回報的真實壞值端到端驗證:同一份 `STATUS.md` 先前 `audit --ship` exit 0、`steward-authority.py` exit 2，現在兩者都拒絕且理由一致。`tests/test_doc_governance.py` 新增 5 條（兩個缺口、兩條靜默、一條釘住 dead-glob 豁免與死 glob 的界線），並修正 `base_config`——19 個既有 fixture 缺 `plan_dir`／`history_paths` 的 class，本來就不是合法配置，改為「只在未涵蓋時注入」以免與各測試自帶的 class 撞成 multi-class。`docs/doc-governance-rollout.md` 補上這個例外的操作說明。先寫 RED 後實作，全 repo 1309 PASS／0 FAIL，dotfiles 自身 `audit --ship` OK。
  - 日期來源:direct
  - 放棄:同 `D-20260907-declared-path-coverage-and-shared-actor-rule` 的放棄欄;另外本批刻意只做 dotfiles 這側的 scanner，下游已 rollout 的 repo 配置不在範圍（見 `B-20260907-governed-repo-declared-path-gaps`）
  - 重議:下游 repo 補完 class 後仍出現同型 finding;或 rollout 需要一份「標準 class 清單」逐項確認要或不要（issue #165 附帶觀察的 `analysis`／`script-guides` 缺漏走的是同一個成因）
  - 關聯:D-20260907-declared-path-coverage-and-shared-actor-rule;B-20260907-governed-repo-declared-path-gaps;B-20260907-actor-key-decoration-limit;scripts/doc-governance.py;tests/test_doc_governance.py;tests/run.sh;docs/doc-governance-rollout.md

- **M-20260908-fleet-governance-rollout-closeout · 2026-09-08 九個 repo 的文檔治理 fleet rollout 完成**:從 GitHub `main` 建立九個 fresh clones，逐 repo 確認 clone HEAD 等於 remote SHA；trusted `scripts/doc-governance.py`、`docs/document-governance.md` 與 kernel／route／portable managed blocks 全部逐 byte 相同，root `CLAUDE.md` 的首個非空白行全為 `@AGENTS.md`，九個 `audit --ship` 均為 rc=0。Remote main 分別為 `krepo@3418e491`、`krepo-common@10099b5b`、`krepo-mops-major-news@52392988`、`krepo-mops-disclosure@9e3a3a83`、`krepo-judicial@86343848`、`kapi-protocol@69bac314`、`kapi-gateway@592c751b`、`krepo-tej-export@968a9b1b`、`krepo-mops-financial-statements@9e6fdad5`；八個 agent-contract suites 合計 26 passed，TEJ（無獨立 agent-contract test）以完整 suite 55 passed／3 skipped加上逐 byte／native-import gate驗證。`B-20260823-fleet-rollout-remaining` 的關閉條件全數成立並自 backlog 移除。
  - 日期來源:direct
  - 放棄:沿用 2026-08-25 的七 repo 舊快照；用既有 working trees 取代 fresh clones；把裸 `uv sync` 未安裝 pytest 誤判成 contract failure
  - 重議:trusted core 或任一 managed block 再次改動時建立新的 bounded rollout item，不重開本歷史記錄
  - 關聯:B-20260823-fleet-rollout-remaining;elandcomtw/krepo#190;elandcomtw/krepo-common#53;elandcomtw/krepo-mops-major-news#52;elandcomtw/krepo-mops-disclosure#45;elandcomtw/krepo-judicial#62;elandcomtw/kapi-protocol#19;elandcomtw/kapi-gateway#52;elandcomtw/krepo-tej-export#10;elandcomtw/krepo-mops-financial-statements#30

- **M-20260911-pipestatus-shell-boundary · 2026-09-11 pipeline 狀態指引補齊 Bash／zsh 邊界**:`claude/known-hazards.md` 不再把 Bash 專用的 `PIPESTATUS` 當成無條件備選；跨 shell 的首選改為先將輸出寫入暫存檔、立刻保存 `$?`，再另外格式化輸出，並明列 Bash 使用 `PIPESTATUS`、zsh 使用小寫 `pipestatus`。先以 `false | true` 對照確認 zsh 的 `${PIPESTATUS[0]}` 為空、`${pipestatus[1]}` 為 1，而 Bash 的 `${PIPESTATUS[0]}` 為 1；再加入文件契約 gate，舊文字穩定 RED 2、修後 GREEN。`scripts/doc-governance.py audit --ship` 回 `OK`，`./tests/run.sh` 1311 PASS／0 FAIL。
  - 日期來源:direct
  - 放棄:只把 `PIPESTATUS` 改成 zsh 的 `pipestatus`（會把同一個跨 shell 缺口反向留下）；以 `pipefail` 當成前段命令的通用狀態（多段 pipeline 時語意不同）
  - 重議:互動命令執行 shell 改變；或文件改為只服務單一明示 shell
  - 關聯:jjshen-eland/dotfiles#176;claude/known-hazards.md;tests/run.sh

- **M-20260912-outward-gate-and-auto-mode-drift · 2026-09-12 Claude Code／Codex push／merge 互動閘門與 Claude policy 漂移訊號完成**:先以 20 個 RED 固定 direct push、send-pack、PR merge、三種 opaque wrapper、四種 safe negative、兩端 hook output 與 Codex rules；實作後 Claude 保留 Auto 並回 ask，Codex 保留 danger-full-access 且 direct rule 經 `codex execpolicy check` 實測為 prompt、opaque command 回 deny。另將 `B-20260816-debt-08` 的無訊號缺口收斂為 `check-claude-auto-mode-drift.sh`：`claude update` 後比對 defaults／config slot 名，漂移時列雙向差異但永遠不自動改 policy 或讓 brewup 失敗。完整 suite 1350 PASS／0 FAIL。
  - 日期來源:direct
  - 放棄:只 grep 設定檔長相而不跑 classifier output；漂移時自動重寫 `settings.json`；把 checker failure 算成 package update failure
  - 重議:同 D-20260912-cross-runtime-outward-gate；或 Claude `autoMode.environment` 支援 `$defaults`／覆寫語意，屆時刪除全量複本與 checker
  - 關聯:D-20260912-cross-runtime-outward-gate;B-20260816-debt-08;scripts/check-claude-auto-mode-drift.sh;scripts/brewup.sh;tests/run.sh

- **M-20260912-codex-config-and-dotsync-exit · 2026-09-12 Codex config 原子收斂與 dotsync 精確終判完成**:三層 fixture 證明 local 最終優先、repo-managed leaf 更新、top-level／nested runtime-only state 保留、local 刪除不復活且重跑 byte-identical；壞 local TOML、缺 yq、writer lock 與 render 期間外部改寫四條 RED 都回 1 且原檔不動。setup mac/Linux、brewup、dotsync 已統一呼叫 helper，兩份 setup inline merge 移除。dotsync E2E stub 證明任一 remote 失敗與 local pull 失敗都回 1、仍跑完所有 requested hosts 並輸出 local／remote 聚合；全綠才回 0。完整 suite 1379 PASS／0 FAIL。
  - 日期來源:direct
  - 放棄:只測 TOML 長相不測刪除／race；讓 helper warning 維持 dotsync exit 0；失敗時取消其餘背景同步
  - 重議:同 D-20260912-codex-config-three-layer-merge；或 dotsync 改用集中式部署工具並有等價逐目標終判
  - 關聯:D-20260912-codex-config-three-layer-merge;scripts/ensure-codex-config.py;scripts/dotfiles-sync.sh;tests/run.sh
