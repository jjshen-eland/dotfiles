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

- **M-20260912-cross-runtime-portability · 2026-09-12 macOS／Ubuntu 與 Claude Code／Codex 收斂計畫完成本地實作**:四個可分離批次完成：(1) GitHub Actions 以 macOS 15＋Ubuntu 24.04 matrix 執行完整 suite，Linux setup 在 mutation 前拒絕非 Ubuntu 24.04+；(2) Claude ask 與 Codex prompt/deny 組合鎖住 push／merge，safe read-only 命令不受影響；(3) Codex config 三層原子 merge 與 dotsync 逐目標聚合終判；(4) portable resources 移到無 `SKILL.md` 的 `shared/skills/`，兩端只留 entry／metadata／runtime assets，Codex 個人 discovery 改為 `$HOME/.agents/skills` 並保守清理 repo-owned legacy links。Claude 原生 component validator 通過，9 個 Codex adapters 通過 OpenAI validator，doc-governance ship audit OK，完整 suite `PASS=1396 FAIL=0`。本里程碑只代表本地實作完成；remote CI、push、PR、merge 與 dotsync fleet rollout 仍依計畫邊界另取授權。
  - 日期來源:direct
  - 放棄:繼續由 Claude tree 擔任 shared canonical owner；whole-skill symlink；整批刪除 legacy Codex skill root；以尚未執行的 remote CI 冒充雙 OS 已驗證
  - 重議:任一 runtime 的 skill discovery、nested symlink、hook schema 或 config layering contract 改變；GitHub runner 映像退役；或 remote matrix 首跑揭露 host-specific failure
  - 關聯:D-20260912-cross-runtime-outward-gate;D-20260912-codex-config-three-layer-merge;D-20260912-neutral-portable-skill-core;docs/plans/2026-09-11-cross-runtime-portability.md;shared/skills;scripts/ensure-codex-skills.sh;tests/run.sh

- **M-20260912-ci-run-34676591841-repair · 2026-09-12 跨平台 CI 首跑揭露的兩層環境依賴完成修復**:run 34676591841／34676604555 先揭露 Ubuntu runner 接受預裝 ShellCheck 0.9.0、兩端皆缺 `rg`；workflow 改由同一個 Homebrew step 明示安裝 `shellcheck`／`ripgrep`／`yq`。PR #179 的下一輪 34700793684 證明工具已一致，但兩端仍同為 `PASS=1323 FAIL=74`；警告 `remote HEAD refers to nonexistent ref` 將第二層收斂到 bare Git fixture 依賴本機 `init.defaultBranch=main`。以 command-scope config 強制 `master` 在本機重現同一批 74 failures，先加反向 gate 穩定列出 29 個未明示 fixture，再逐一以 `-b main`／`-b trunk` 固定 intended default；未用 workflow 全域 Git 設定掩蓋不可攜 fixture。一般環境、強制 `master` 與 `--no-local` clean clone 的完整 suite 均為 `PASS=1399 FAIL=0`，doc-governance ship audit 為 `OK`；PR #179 head `3f68d41` 的 run 34703503410 最終 macOS 15、Ubuntu 24.04 皆成功。
  - 日期來源:direct
  - 放棄:在 workflow 設 `git config --global init.defaultBranch main`（只會讓 CI 與本機一起掩蓋 fixture 的隱性依賴）；沿用 runner 預裝工具；跳過或放寬失敗 assertions
  - 重議:GitHub runner 不再提供 Homebrew；Git 移除 `git init --bare -b`；或新增 fixture 需要刻意測未設定 remote HEAD 的錯誤情境
  - 關聯:M-20260912-cross-runtime-portability;jjshen-eland/dotfiles#179;tests/run.sh;docs/testing-contract.md;.github/workflows/test.yml
- **M-20260913-auto-mode-drift-collation · 2026-09-13 auto-mode drift checker 的 collation 誤報收斂，真漂移 slot 補齊**:`check-claude-auto-mode-drift.sh`（M-20260912 當天建立）在 brewup 上每次噴 41 行漂移，其中 40 行是假的。兩層病灶:(1) `extract_slots` 把 `sort` 釘在 `LC_ALL=C`，`comm` 卻沿用互動 shell 的 `LC_COLLATE=zh_TW.UTF-8`——`comm` 對亂序輸入不報錯也不回非零，而是把同一行同時印進「只在左邊」與「只在右邊」兩欄，21 個 slot 有 20 個雙欄出現;(2) `### Org-wide`／`### User-specific` 是 `claude/settings.json` 刻意寫的章節標題、無 `label: value` 形狀，卻進了 slot 比對而永遠誤報。修法是兩支 `comm` 補 `LC_ALL=C`，`extract_slots` 加 `select(index(":"))` 濾掉標題。選 `index(":")` 而非 `^\*\*` 是刻意的:Claude 若改 slot 格式，前者退化成「全部報成 missing」（吵、看得見），後者兩側同時變空而**靜默失效**——這支腳本的價值全在它會出聲。唯一真漂移 `**Host containment**` 是 Claude 新版內建 slot，以預設原文補進 `autoMode.environment`（該機為一般開發機、預設文字即事實）。守門測試原本用 `alpha`／`beta`／`gamma` 純 ASCII fixture，兩種 collation 排序剛好一致故恆綠;改用真實形狀（`**Name**` ＋ `### 標題`）並自動挑一個排序行為與 C 不同的 locale（實測選到 `zh_TW.UTF-8`）。先以 stash 還原修復前腳本實測三條斷言全紅，再確認修後全綠。`claude/known-hazards.md` 新增「`sort` 與 `comm` 的 collation 必須一致」節，`claude/CLAUDE.md` 補對應觸發形狀一行（規則不在 always-on 就不生效）。
  - 日期來源:direct
  - 放棄:用 `^\*\*` 前綴濾 slot（Claude 改格式時兩側同時變空、靜默失效）;只在 `comm` 之一補 locale;把 `### 標題` 也當 slot 並要求 settings.json 拿掉分節
  - 重議:`claude auto-mode defaults` 改用非 `label: value` 的 environment 格式;或 slot 名開始合法包含前置冒號
  - 關聯:M-20260912-outward-gate-and-auto-mode-drift;B-20260816-debt-08;scripts/check-claude-auto-mode-drift.sh;claude/known-hazards.md;claude/CLAUDE.md;claude/settings.json;tests/run.sh

- **M-20260913-project-merge-authorization-ci · 2026-09-13 Claude Project merge 零重問與 PR-only required CI 完成本地實作**:先以組合 RED 重播 `c086aca` 後 `/project --merge` 的 push＋merge 會觸發 2 次 Claude approval UI，再只移除 Claude outward hook/runtime path，Codex gate、classifier 與其他改動保留；修後組合斷言為 0。PR workflow 保留 macOS 15＋Ubuntu 24.04，移除 `push: main` 重複完整 run；GitHub main branch protection 已將 `suite (macos-15)`、`suite (ubuntu-24.04)` 綁定 GitHub Actions app 15368 並設 required、admins enforced、strict false。三個原慢區段改以唯讀背景 gate 與 fixture 主流程重疊，本機完整 suite 由約 200 秒降至 119.51 秒，`PASS=1403 FAIL=0`；ShellCheck、Codex Project validator、`git diff --check` 亦通過。feature branch 尚未 push 或 merge。
  - 日期來源:direct
  - 放棄:整顆 `git revert c086aca`;排程重跑相同 main suite;縮小 tests/shellcheck 掃描集合
  - 重議:remote PR 雙平台首跑顯示並行造成 host-specific failure；或 GitHub Actions context／branch protection 漂移
  - 關聯:D-20260913-project-merge-authorization-ci;c086aca;.github/workflows/test.yml;claude/settings.json;scripts/outward-action-gate.py;tests/run.sh

- **M-20260914-project-no-checks-reported-eval · 2026-09-14 Project `BLOCKED + no checks reported` 缺口完成可重跑覆蓋**:`ship-paths.md` 的三分流本來已正確，缺的是 Scenario 29 第三控制臂的正式 fixture。u4 現新增 `gh-stub-blocked-no-checks`：與全綠／pending 控制臂同為 `mergeStateStatus=BLOCKED`，但 `gh pr checks --required` 精確輸出 no-checks 並回 1，`ship-state.sh` 同時給 `required-policy: none`；oracle 因此能證明這不是 failed check，而是與 CI 無關的 protection 阻擋，裸 `merge` 應停下並提供 `bypass merge` 回程。先以舊 builder 實測 setup 成功但 fixture 不存在得到 RED，修後 targeted u4 建置 0.66 秒並逐項轉綠；完整 suite `PASS=1412 FAIL=0`，Codex skill validator、Claude frontmatter／shared topology、ShellCheck 與 doc-governance 均通過。`B-20260815-debt-10` 已自 backlog 移除。
  - 日期來源:direct
  - 放棄:只在 Scenario prose 提到第三臂而不提供 fixture；讓 CI 每次建立全量 sandbox（基線 18.28 秒）；把 exit 1 一律視為 failed check 或 no-checks
  - 重議:`gh pr checks` 的 no-checks 訊息或 exit contract 改變；Project 不再以 `ship-state.sh` 提供 required-policy evidence；或 u4 targeted builder 與全量 builder 產物漂移
  - 關聯:B-20260815-debt-10;M-20260826-project-watch-transport-error;claude/evals/setup-sandboxes.sh;claude/evals/README.md;shared/skills/project/references/pressure-tests.md;shared/skills/project/references/ship-paths.md;tests/run.sh
- **M-20260913-identity-fleet-rollout-complete · 2026-09-13 git identity 主機隊 rollout 結案**:`inventory.conf` 全部 14 台與家中 MacBook 的既有 `verdict: OK` 證據完成主機隊收斂；依 `D-20260913-company-mac-nonblocking-identity-rollout`，休眠且不在 inventory 的公司 MacBook 改為恢復使用時才本機補跑，不再是 rollout blocker。`B-20260902-identity-fleet-rollout` 已自 backlog 移除。
  - 日期來源:direct
  - 放棄:把公司 MacBook 未喚醒誤記為已驗證；以遠端 mutation 換取形式上的全數完成
  - 重議:同 `D-20260913-company-mac-nonblocking-identity-rollout`
  - 關聯:B-20260902-identity-fleet-rollout;D-20260913-company-mac-nonblocking-identity-rollout;D-20260902-git-identity-directory-boundary;M-20260902-git-identity-directory-boundary;scripts/setup-git-identity.sh;scripts/inventory.conf

- **M-20260913-dotfiles-remote-migration-retired · 2026-09-13 dotfiles owner 一次性 remote migration 完整退役**:`B-20260815-debt-09` 的全機隊移除條件早已成立；本批刪除 `ensure-dotfiles-remote.sh`，移除 brewup、dotsync 本機與遠端共三個呼叫點，並把原 23b 遷移行為測試改成「helper 不存在且 steady-state 無引用」的防復活 gate。該 gate 先以 helper／引用仍在得到兩項 RED，再於移除後轉綠；在最新 `main` 重建後完整 suite `PASS=1402 FAIL=0`，既有 dotsync helper 警告聚合與逐目標終判維持不變。`B-20260815-debt-09` 已自 backlog 移除。
  - 日期來源:direct
  - 放棄:只刪腳本而留下呼叫點；只刪行為測試而不留下退役契約；順手移除仍服務其他 helper 的 warning aggregate
  - 重議:dotfiles 再次移轉 owner 且需要 bounded fleet migration；屆時建立新的 migration item，不復活舊 helper
  - 關聯:B-20260815-debt-09;scripts/brewup.sh;scripts/dotfiles-sync.sh;tests/run.sh

- **M-20260914-linux-suite-continuous-verification · 2026-09-14 Linux 完整 suite 已納入每個 PR 的持續驗證，B11 結案**:`B-20260815-debt-11` 原先記錄 Linux 分支雖可手動執行、卻沒有任何固定流程。現行 GitHub Actions 已在每個 PR 以 macOS 15＋Ubuntu 24.04 matrix 執行完整 `./tests/run.sh`，test contract 與 section 25 regression gate 禁止移除任一平台或恢復 merge 後 `push: main` 的重複 run；`main` protection 仍要求 `suite (macos-15)` 與 `suite (ubuntu-24.04)`（GitHub Actions app 15368，`strict=false`）。PR #183 再次實證 Ubuntu `1m10s`、macOS `1m47s` 均成功；本地最終 suite `PASS=1402 FAIL=0`、ship audit `OK`。因此 Linux failure 不再依賴人工碰巧執行才會被看見，B11 已自 backlog 移除。
  - 日期來源:direct
  - 放棄:把 `tests/run.sh` 掛進 dotsync／brewup（散佈流程過重且失敗語意混雜）；只以一次本機 Linux run 結案（沒有持續性）；恢復 `push: main` 同套重跑（成本重複且壞 main 已發生）
  - 重議:PR workflow 不再跑 Ubuntu 完整 suite；required contexts 被移除或改名；或 Linux 支援基線離開 Ubuntu 24.04
  - 關聯:B-20260815-debt-11;M-20260912-cross-runtime-portability;M-20260912-ci-run-34676591841-repair;D-20260913-project-merge-authorization-ci;.github/workflows/test.yml;docs/testing-contract.md;tests/run.sh

- **M-20260914-cqs-grep-pipefail-repair · 2026-09-14 crawl-quality assertion 的 macOS pipefail 偽失敗完成根因修復**:B11 結案 PR #184 首輪 Ubuntu 24.04 通過、macOS 15 卻在 600-source assertion 得到 `PASS=1401 FAIL=1`；job `103824000828` 同行先報 `tests/run.sh:6754: echo: write error: Broken pipe`。`cqs_grep` 原以 `echo "$out" | grep -q` 搜尋約 28KB 輸出，`grep -q` 命中後提早退出會讓上游 `echo` 收到 SIGPIPE，`pipefail` 因此把真命中翻成失敗。受控大型輸出重現 pipeline rc=141、herestring rc=0；修復只把 helper 改為 `grep -q ... <<< "$out"`，不動 crawl-quality engine 或抽樣演算法。原 assertion 與本地完整 suite `PASS=1402 FAIL=0`、ship audit `OK`；PR 的雙平台 required checks 仍作最終 merge gate。
  - 日期來源:direct
  - 放棄:直接 rerun 等 timing 偶然轉綠；停用 `pipefail`；縮短或吞掉 600-source fixture 輸出；順手擴張成全部 B13 pipeline debt 的機械清理
  - 重議:`cqs_grep` 再引入 early-exit pipeline；或其他大型輸出 assertion 出現同型 SIGPIPE 證據
  - 關聯:B-20260815-debt-11;B-20260811-debt-13;M-20260914-linux-suite-continuous-verification;PR #184;tests/run.sh

- **M-20260914-xref-heading-body-fallback-composition · 2026-09-14 xref 節名改壞與 body fallback 的組合防線完成驗證**:`B-20260814-debt-12` 原始突變是將 `docs/dead-ends.md` 的 `## 分工` 改名，因 target 內文仍含「分工」而讓正向 xref 假綠。後續加入的 `requires_inbound` 反向節級孤兒 gate 已實際封住此形狀：在 `--no-local` 隔離 clone 將該 heading 改為「證據分層」後，只掃 `STATUS.md` 的正向檢查零 finding，完整 repo scan 則精確報「證據分層—節級孤兒」。`tests/run.sh` 新增同型組合 fixture，同時釘住合法 body fallback 不誤報、改名後 heading 仍報孤兒；完整 suite `PASS=1403 FAIL=0`。因現行實作已滿足缺口，本批不改 scanner，B12 自 backlog 移除。
  - 日期來源:direct
  - 放棄:收窄成 heading-only（會打壞合法的逐行內文規則引用）；要求突變同時刪掉 target 內文的同詞（只是讓測試避開真實失效面）；重複實作第三層 scanner
  - 重議:`requires_inbound` 反向掃描被移除；`docs/dead-ends.md` 不再是證據層；或合法 body fallback 語意改變
  - 關聯:B-20260814-debt-12;docs/dead-ends.md;scripts/doc-governance.py;tests/run.sh;docs/testing-contract.md

- **M-20260914-printf-grep-pipeline-retirement · 2026-09-14 tests/run.sh 的 printf-to-grep-q 潛伏 pipeline 完成清除**:`B-20260811-debt-13` 於 2026-08-11 記錄 20 處，本次重新盤點為 21 處；新增的第 21 處來自後續 stub 參數判斷，失效機制與原債相同。先新增拆開 scanner token 以避免自命中的 source gate，修前精確列出 21 hits 並回 1；再將 21 處等價改為 `grep -q ... <<< "$value"`，pattern、fixture 輸出與斷言正反向皆不變，修後 source gate 為 0 hits。`bash -n`、repo 參數的 ShellCheck 與完整 suite `PASS=1404 FAIL=0` 均通過；B13 自 backlog 移除。
  - 日期來源:direct
  - 放棄:關閉 `pipefail`；只修目前輸入較大的局部位置；把本項擴張成所有 `echo`/`find`/`sed` producer pipeline 的無邊界清理
  - 重議:source gate 被移除或收窄；或其他 producer 出現大輸入 SIGPIPE 的可重現證據，屆時以新 work item 處理而不重開 B13
  - 關聯:B-20260811-debt-13;M-20260914-cqs-grep-pipefail-repair;tests/run.sh;docs/testing-contract.md

- **M-20260914-handoff-final-anchor-order · 2026-09-14 handoff 的 dirty 錨點改為 durable mutation 後的最終 snapshot**:`B-20260809-debt-14` 的 root cause 由 2026-08-09 H5 實查、同輪 H8 對照與現行 control flow 確認：舊 W2 先蓋 `dirty=1`，舊 W3 再獲授權修改 `STATUS.md`，因此 artifact 寫出「`dirty=1` 就是兩個未 commit 檔案」的矛盾。新增 H5b 組合行為 oracle，並將 shared write flow 重排為 W2 durable routing／所有合法 repo mutation → W3 final anchors → W4 artifact；anchors 後 repo state 若改變必須丟棄舊輸出重跑。source-order gate 修前為 `route=0 anchor=0 artifact=0`、exit 1，修後為 `78 < 102 < 114`；雙 runtime validator、Bash syntax、repo 參數 ShellCheck、doc audit 與完整 suite `PASS=1405 FAIL=0` 均通過。未授權 repo mutation 與 portable topology 不變；B14 自 backlog 移除。
  - 日期來源:direct
  - 放棄:只加一條「記得更新 dirty」告誡；修改 `handoff-anchor.sh` 的計數語意；以 2026-08-23 未授權零 mutation 契約宣稱所有合法寫入路徑都已消失
  - 重議:write mode 重新允許 anchors 後的 repo mutation；或 live H5b 顯示 ordering 契約仍無法讓 artifact 與 final porcelain 一致
  - 關聯:B-20260809-debt-14;M-20260823-portable-handoff-skill;shared/skills/handoff/evals.md;shared/skills/handoff/references/workflow.md;tests/run.sh

- **M-20260914-b15-retained-test-criteria-already-satisfied · 2026-09-14 B15 的兩條 testing 判準確認早已進入現行權威**:`B-20260820-debt-15` 源自 2026-08-10 將已結案技術債歸檔時留下的「仍須保留兩條 live 判準」項目；翌日 commit `d5c1564` 已把 repo-local 測試權威與「便宜 gate 趁乾淨加入」的理由移入 `docs/testing-contract.md`，但 item 未同步結案，2026-08-16 又隨 dossier/backlog 分流被搬成未結案債。現況重驗：root `CLAUDE.md` 的首行 `@AGENTS.md` 由 kernel gate 的四個 RED fixture 守住，`AGENTS.md` Repo specifics 仍承接必跑時機與 exit-code 契約，xref audit 為零 finding；shellcheck gate 仍涵蓋 `claude/evals/*.sh`，其「納入時零 findings」與便宜守門理由仍在 testing contract。B15 無剩餘實作，從 backlog 移除。
  - 日期來源:direct
  - 放棄:再新增一份 always-on 規則或重複 gate；只因 backlog 未勾選就假設 2026-08-11 的落地不存在；把 literal 路徑 `CLAUDE.md` 固化成不允許 root 原生 import 的舊架構
  - 重議:root `CLAUDE.md` 不再原生載入 repo-local 測試契約；xref／kernel gate 被移除；或 shellcheck coverage 不再包含 `claude/evals/*.sh`
  - 關聯:B-20260820-debt-15;3c7e0a6;d5c1564;f2e7aa0;CLAUDE.md;AGENTS.md;docs/testing-contract.md;tests/kernel-gate.py;tests/run.sh

- **M-20260914-b16-obsolete-punctuation-debt-closed · 2026-09-14 B16 中文標點風格債因失去可辨識範圍而結案**:`B-20260808-debt-16` 最早只是 2026-07-16 R4 non-blocking 清單中一句「新增 prose」的風格建議，未指名檔案、批次、希望格式或失敗案例；2026-08-08 已明記其 target 不可考且會隨新 prose 移動。現況的寬鬆掃描在 54 個 Markdown 檔、約 1,734 行命中中文與 ASCII 標點相鄰，其中包含指令、識別字與 Markdown 結構，無法從命中反推原始缺口。Repo 也沒有以行為 oracle 或風格契約要求全形／半形統一；因此不做大面積 prose churn、不新增主觀 lint gate，將 B16 以不再適用結案並從 backlog 移除。
  - 日期來源:direct
  - 放棄:推測已不可考的原始 prose 批次；一次重寫全 repo Markdown；在沒有失敗 oracle 時加入標點 style gate
  - 重議:未來採用明確的中文標點 style guide，並指定受管路徑與可重現 formatter/linter oracle；或出現由標點造成的可重現功能／呈現失敗
  - 關聯:B-20260808-debt-16;1d96e452;f2e7aa0;docs/backlog.md;STATUS.md

- **M-20260914-project-pressure-evals-s8-s12 · 2026-09-14 Project S8／S9／S10／S12 壓力情境完成可重跑覆蓋**:`claude/evals/setup-sandboxes.sh project-pressure` 現可獨立建立四個沙盒：S8 重用既有 keyword repo constructor，S9 以明示 user-owned diff 與 protection UNKNOWN 固定 light path，S10 僅使用 fixture-only 假 credentials，S12 同時製造 `<300` 行、`>30 KiB`、巨型 decision entry 與三種 section 佔比訊號。fresh Claude／Codex 行為 eval 中，S8 明示 merge 均為零次 approval UI、S9 均守住 branch-first 與未授權不 push；S10 baseline 分別出現「整批拒絕而未繼續 safe transfer」與「Transfer mode 仍 commit」，S12 baseline 分別出現「違反 veto 改寫 STATUS」與「把非 STOP hygiene flag 升格成 STOP」。最小修正限於 Claude entry routing、Transfer 子請求分流與 legacy dossier flag 帶入 Step 4，修後雙 runtime 四情境全綠；fixture deterministic gate、ShellCheck、雙 runtime skill validation、doc-governance ship audit 皆通過，完整 suite `PASS=1419 FAIL=0`。B19 已自 backlog 移除。
  - 日期來源:direct
  - 放棄:為每個 scenario 複製整棵既有 fixture；為製造 RED 放寬 oracle；把 ownership 不明的首輪 S9 STOP 當成 behavior failure；未觀察失敗就廣寫 Project prose
  - 重議:任一 scenario 再次 regression；dossier 尺寸門檻或 Transfer mode 邊界改變；或 runtime 不再遵守 entry-to-shared-core routing gate
  - 關聯:B-20260820-debt-19;X-20260914-project-s9-ambiguous-fixture-ownership;claude/evals/setup-sandboxes.sh;claude/evals/README.md;claude/skills/project/SKILL.md;shared/skills/project/references/pressure-tests.md;shared/skills/project/references/workflow.md;shared/skills/project/references/log-workflow.md;docs/testing-contract.md;tests/run.sh

- **M-20260915-b21-validator-path-regression-guard · 2026-09-15 quick_validate.py 的 context-independent 路徑與防回歸證據完成**:`B-20260721-debt-21` 的執行期問題已由 2026-08-24 commit `e2f1afec` 修正：文件改用 `uv run --no-project --with pyyaml python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>`。2026-09-15 從 repo root 與無關 `/tmp` 各實跑一次，兩者皆以同一 system validator 驗證 `codex/skills/project` 並回 `Skill is valid!`。但既有 gate 只 grep `uv ... python` 前綴與 PyYAML 說明；把絕對 script path 退回舊 `$skill-creator/scripts/quick_validate.py` 的不落盤 mutant 仍假綠，證明原 failure mode 未受保護。最小修正只讓 gate 精確要求絕對 system path 並拒絕 context-dependent 舊形式；同一 mutant 轉為 RED、正常 guide 維持 GREEN，未修改 guide、system validator 或任何 repo-local skill。B21 已自 backlog 移除。
  - 日期來源:direct
  - 放棄:因現行指令能跑就直接結案（路徑仍可無聲退化）；重寫已正確的 authoring guide；新增另一支 validator wrapper；安裝 PyYAML 到 system Python；擴張其他 skill-authoring 規則
  - 重議:Codex system skill discovery root 或 `CODEX_HOME` 契約改變；`quick_validate.py` 移出 system skill；或 gate 再次無法攔下 context-dependent mutant
  - 關聯:B-20260721-debt-21;M-20260824-memory-independent-transfer;e2f1afec;codex/skill-building-guide.md;docs/testing-contract.md;tests/run.sh

- **M-20260915-b22-old-round-ab-no-decision-value · 2026-09-15 擴大舊 Sonnet 輪次 A/B 已無現行決策價值**:`B-20260805-debt-22` 要求為 2026-08-05 每組 `n=3` 的盲測擴樣，以判斷「最後一輪」提示是否導致 reviewer 降低 blocking 數量。現行設計已不以該效應量為前提：2026-08-04 的收件 transcript 直接證明後期 prompt 曾洩漏 review cap、把任務從發現問題改成收旂判斷；`D-20260823-portable-deep-review` 後的 portable workflow 則以 fresh-context independence 排除 prior findings、pass number 與 remaining budget，P5／P15 為其 behavior oracle，`D-20260912-neutral-portable-skill-core` 又將其收旂為雙 runtime neutral core。決策矩陣三格皆不改變契約：正向結果只增強現狀；零效應不能推翻已觀察的 cap 洩漏與任務放寬；反向的 finding／blocking 數量增加也不證明正確率或召回率較高——舊實驗未驗證 findings，且六個樣本全部判 FAIL。因此不為舊模型與舊編排預註冊或執行新樣本，不修改 skill、gate 或 eval；舊 A/B 仍保留為「方向一致但未證實」的歷史證據，B22 自 backlog 移除。
  - 日期來源:direct
  - 放棄:擴大舊 Sonnet 樣本；把同一 `n=3` 設計原樣搬到當代模型；以未驗證真假的 finding 數量作為改寫隔離契約的門檻；把舊弱證據改寫成「已證實」或「無效應」
  - 重議:觀察到隱藏 pass 資訊會降低已獨立驗證的 true-positive recall，或新的產品需求要求 reviewer 感知階段；屆時以新 work item 預註冊直接量測正確率／召回率的當代實驗，不重開舊的 count-only A/B
  - 關聯:B-20260805-debt-22;D-20260823-portable-deep-review;M-20260823-portable-deep-review;D-20260912-neutral-portable-skill-core;shared/skills/deep-review/references/workflow.md;shared/skills/deep-review/evals.md

- **M-20260915-b23-model-floor-policy-reconciled · 2026-09-15 多模型 eval 指引收斂至現行模型樓層政策**:`B-20260820-debt-23` 的實際原文建立於 2026-08-05，以當時「Haiku／Sonnet／Opus 全測」為發布門檻並要求跑舊 deep-review d1／d2／d3 三模型批次；2026-08-07 後的唯一權威已改為 Sonnet 是 PASS 樓層、Haiku 是加分、Opus／更強模型只診斷過度解釋。八份 canonical skill eval 盤點確認 deep-review、root-cause-first、project 仍殘留舊必跑措辭，deep-plan 重複現行規則，其餘五份沒有另立門檻；四個指引與 skill-building guide 的兩處規則已改為只指向 `claude/evals/README.md`，真正需要樓層模型判定規則作用的 project Scenario 17 仍保留 Sonnet-specific 要求。舊 d1／d3 又屬 2026-08-23 已退役的 legacy 編排，d2 的現行 scope gate 已由 portable P2 承接；Haiku PASS／FAIL、Opus 有／無過度解釋與跨模型分歧都不能由該批次直接改變現行驗收或產品規則。因此不預註冊、不執行舊多模型批次，也不新增 behavior rule／gate；靜態 drift RED 已轉 GREEN，七個適用的 system validator、canonical linkage、doc-governance 與完整 suite `PASS=1419 FAIL=0`，B23 自 backlog 移除。
  - 日期來源:direct
  - 放棄:直接重跑舊 d1／d2／d3 三模型批次；把 Haiku 或 Opus 一律升成發布門檻；在每份 eval oracle 複製模型政策；因 Codex validator 不接受 Claude 專屬 frontmatter 就刪除 `/project` 必要欄位
  - 重議:現行 portable fixture 在 Haiku 出現會影響使用者安全或核心功能的可重現 RED；Opus／更強模型出現造成錯誤行為或顯著成本的過度解釋；或 `claude/evals/README.md` 的模型樓層權威正式改版。屆時為該具體決策預註冊最小實驗，不恢復全套三模型必跑
  - 關聯:B-20260820-debt-23;D-20260823-portable-deep-review;D-20260825-portable-skill-authoring-default;M-20260915-b22-old-round-ab-no-decision-value;claude/evals/README.md;claude/skill-building-guide.md;shared/skills/deep-plan/evals.md;shared/skills/deep-review/evals.md;shared/skills/root-cause-first/evals.md;shared/skills/project/references/pressure-tests.md

- **M-20260915-b24-spec-flow-validated · 2026-09-15 Project spec 到實作的即時記錄契約實戰驗證完成**:以剛完成的 B23 當代實戰重建時序：active contract 在實作前已寫入 Context、Goal、Acceptance Criteria、Constraints 與四個 coordination fields；feature branch、skill-authoring preflight、八份 canonical eval 盤點、決策矩陣、驗證結果與下一步都在 active item 存續期間更新，並非到 shipping 才首次重建。PR #194 的最終 commit `41ed4e1f53cb0656cfe2928577398390cb10f4d6` 只改七個已宣告 scope 內檔案；當 B23 舊的「三模型全測」前提被現行模型樓層政策推翻後，實作收旂為 pointer 漂移修正，沒有為完成過時 spec 而執行 d1／d2／d3 批次。Doc-governance 自然語言路由與 repo 全文關鍵詞搜尋沒有找到其他「照過時 spec 執行」或「擅自擴 scope」的 observed failure；後續曾固定的 Project RED 屬 shipping hint、steward lifecycle 等其他契約，不觸發 B24 的改規則門檻。因此依 Iron Law 不新增程序、指令或 eval，B24 自 backlog 移除。
  - 日期來源:direct
  - 放棄:為增加心理安全感而重放舊 spec 情境或擴大樣本；在沒有 observed failure 時補 project prose／behavior eval；把 B23 單次成功外推成所有 mid-work re-spec 情境都已窮盡驗證
  - 重議:後續出現可重現的「active spec 已被新證據推翻，agent 仍照舊驗收執行」／「未先更新 contract 就擴大實作 scope」／「進度只在 ship 時從記憶補寫」的 observed RED；屆時以新 work item 固定最小重現，不復活泛化的「多跑幾次」待辦
  - 關聯:B-20260721-debt-24;M-20260915-b23-model-floor-policy-reconciled;PR#194;41ed4e1f53cb0656cfe2928577398390cb10f4d6;docs/archive/decisions-2026-07.md

- **M-20260915-doc-governance-round2-revalidated · 2026-09-15 doc-governance Round 2 五項非阻斷後續完成重驗**:`B-20260820-debt-25` 的五項舊候選逐項以現行實作與行為重跑。`supersedes` 不需另建反向索引：查舊 `D-20260822-portable-deep-plan` 時，預設五筆內同時出現原 record 與含 `supersedes:<舊 ID>` 的 `D-20260825-deep-plan-empty-wait`，查新 ID 則現行 record 排第一，使用者可由任一端找到現行結論。`mode: governance` 保留：它不是廢棄假設，至少 `ais-infra` 的現行 adopted config 仍用它分類 `docs/document-governance.md`，trusted scanner 的 `report` 可正常解析。worktree trusted-core 的 self-hosted common-dir 允許路徑與外部 mismatch fail-closed／resync 指引均已有 deterministic test 且重跑通過。canonical-title oracle 現涵蓋 1,051 entries／841 個唯一標題，單測約 2.0 秒；新增一個條目的邊際計算為毫秒級，沒有足以改寫 oracle 或加入不穩定效能門檻的 observed cost。唯一真缺口是 `requires_inbound:true` 搭配 glob class 時被 `evidence_layers()` 整類略過：兩檔孤兒 fixture 先得到零輸出的 RED，再改為從 tracked Markdown 與 class matching 展開，兩條 finding 均轉綠，literal path 行為不變；human contract 同步明定 glob 會套用到每個 matched file。doc-governance 模組 81 tests、ship audit 與完整 suite `PASS=1419 FAIL=0`；B25 已自 backlog 移除。
  - 日期來源:direct
  - 放棄:為 `supersedes` 重複建立專用索引；移除仍有 adopted consumer 的 `governance` mode；修改已正確的 Project trusted-core skill 路徑；只因理論上的二次成長就改寫 canonical-title oracle或加跨機不穩定的時間門檻；讓 `requires_inbound` 對 glob 靜默失效
  - 重議:舊 ID 查詢不再於預設結果內呈現 superseding record；所有 adopted config 都不再使用 `governance` mode；linked worktree 的 common-dir 判定或 resync 指引回歸；canonical-title 單測出現可重現的 CI 成本；或 glob evidence layer 再次漏掃 matched file
  - 關聯:B-20260820-debt-25;D-20260822-portable-deep-plan;D-20260825-deep-plan-empty-wait;X-20260907-stale-core-scan-false-baseline;scripts/doc-governance.py;tests/test_doc_governance.py;docs/document-governance.md

- **M-20260915-doc-governance-round3-revalidated · 2026-09-15 doc-governance Round 3 十二項非阻斷後續完成重驗**:`B-20260821-debt-26` 逐項依現行行為重驗，四個可重現缺口均先取得 RED 再做最小修正：（1）legacy／compat xref 在 Git repo root 改以 Git tracked／non-ignored files 作 full-scan sources，ignored generated files 不再誤報，同時保留 non-Git fixture directory 的相容行為；（2）`.sh` xref 排除 heredoc payload，heredoc 內 `#` 範例不再當真 comment，terminator 後真 pointer 仍照掃；（3）real retrieval corpus 不再綁 live B26／B02，backlog semantic 與 stable-ID 改用 synthetic repo fixture；（4）deterministic suite 直接執行 current repo `audit --ship`，不再容許 synthetic tests 全綠而真 repo 留有 unclassified finding。七條 alias 中六條仍承接 immutable history，唯一未使用的 `STATUS.md「死路」` alias 已移除；不新增沒有行為收益的 unused-alias error。其餘候選已有現行證據：正反向 section 組合由 B12 gate 覆蓋；兩份 `alias_sources` 對合法 config 推導相同八個來源；positional files、ship finding priority、adoption diagnostics、route portability 與 Codex event-time always-on 均有 regression gate 並重跑通過。doc-governance 模組 84 tests 與完整 suite `PASS=1419 FAIL=0` 均通過；B26 已自 backlog 與 active state 移除。
  - 日期來源:direct
  - 放棄:把舊十二項全部當功能開發；為等價 `alias_sources` 推導做純重構；把任何 unused alias 升成全域 error；讓 real retrieval oracle 改綁另一個遲早關閉的 live `B-*`；讓 Git ignored output 或 shell heredoc data 進入 xref source
  - 重議:legacy full scan 再納入 Git ignored path；heredoc terminator 後真 pointer 被漏掃；synthetic suite 再次放過 actual repo audit finding；backlog retrieval fixture 再綁 live debt；或兩處 `alias_sources` 在合法 config 出現可重現差異
  - 關聯:B-20260821-debt-26;M-20260914-xref-heading-body-fallback-composition;M-20260915-doc-governance-round2-revalidated;scripts/doc-governance.py;tests/test_doc_governance.py;tests/fixtures/doc-governance/retrieval.tsv;docs/document-governance.md;docs/testing-contract.md

- **M-20260915-b27-title-free-recall-revalidated · 2026-09-15 程序型文件 title-free recall 以現行雙語料重驗並修正真缺口**:以 dotfiles `8341350` 與 fresh canary `5b6db0c` 重跑舊 20 題，並事前固定 12 條新 query；B26 的 Git-ignore／xref 修正未改變 find 的 H2 分節與 scoring。新基線為跨語言 0/4、作者 H2 1/4、權重形狀 2/4；其中一條預期 path 已因內容歸屬改變而失效。兩個真缺口先取得獨立 RED：D／X／M 首行冒號後正文被誤算成 title，且 reason query 對任何弱 history 命中固定加 800。修正為只取粗體 label 作 history title、正文仍供 body 搜尋，並將 reason boost 改為 `min(score, 800)`；兩條 regression gate 轉綠，舊 dotfiles 維持 6/10、canary 由 1/10 升至 2/10，新作者 H2 組由 1/4 升至 2/4。唯讀 H3→H2 對照達 4/4，證明剩餘作者面 miss 應由承重 H2 修正，不重開全域 H3 chunking／IDF／H1 方案；跨語言 0/4 依 `D-20260915-b27-cross-language-boundary` 不建立單一文件過擬合的翻譯層。doc-governance 模組 86 tests、ship audit 與完整 suite `PASS=1419 FAIL=0` 均通過；B27 與其已完成全部步驟的 umbrella B30 自 backlog 移除。
  - 日期來源:direct
  - 放棄:把舊 expected path 當永恆 oracle；以全域翻譯字典修四題；恢復已證偽的 H1／IDF／H3 ranking 候選；只改固定 800 boost 而忽略正文被當 title 的共同根因
  - 重議:history label／body 邊界或 reason-query source diversity 回歸；至少三個獨立 repo 出現同型跨語言 miss；或作者改用承重 H2 後仍有可重現、會影響實際查找的 miss
  - 關聯:B-20260821-debt-27;B-20260822-debt-30;D-20260915-b27-cross-language-boundary;X-20260822-doc-h1-token-signal;X-20260823-retrieval-idf-and-h3-chunking;scripts/doc-governance.py;tests/test_doc_governance.py;tests/fixtures/doc-governance/b27-current-baseline.tsv;docs/document-governance.md;docs/testing-contract.md

- **M-20260915-b01-history-recall-current-routes-sufficient · 2026-09-15 現行 always-on 路由已能阻止重走 outward hook 死路**:以不洩漏 stable ID、archive 標題或舊結論的真實任務重驗 B01：要求將 Claude Code 與 Codex 的 push／send-pack／PR merge 統一掛上同一個 PreToolUse hook。先以相同自然語言手動執行 `doc-governance.py find`，前五筆內即召回 `D-20260913-project-merge-authorization-ci`，證明 lexical retrieval 不是缺口。Claude Code 2.1.272／Sonnet fresh plan-mode baseline 雖先寬搜現行檔案、未以 `find` 作第一個命令，但在任何 repo 改動前找到 D-20260912 與取代它的 D-20260913，正確拒絕重掛 Claude hook；Codex CLI 0.154.0 fresh read-only baseline 先讀 root `AGENTS.md`，再實際執行 `doc-governance.py find`，同樣以零 repo 改動保留 Claude Auto、Project `--merge` 零額外 approval UI 與 Codex outward gate。雙 runtime 都沒有出現「因未主動查歷史而做錯」的 observed miss；Claude 的檢索順序偏差沒有改變處置，不足以依 Iron Law 新增 deny hook、路徑倒排索引或更長 prose。B01 自 backlog 移除，現行 classifier／hook 不修改。
  - 日期來源:direct
  - 放棄:沒有 observed failure 仍實作舊 PreToolUse deny＋路徑倒排索引；對 Claude Auto 重掛無 Project invocation context 的 outward hook；把未改變結果的首次檢索順序偏差當成行為 RED；引入 embedding／向量庫
  - 重議:出現可重現的「相關歷史可被 `find` 召回，但 Claude 或 Codex 在任何檢索前就執行相衝突改動」，且 lookup 會改變最終處置；屆時以該真實案例取得 RED，不自動復活舊 hook／index 設計
  - 關聯:B-20260819-debt-01;D-20260811-symmetric-rules-as-signal;X-20260825-deep-plan-duplicate-port;D-20260912-cross-runtime-outward-gate;D-20260913-project-merge-authorization-ci;AGENTS.md;scripts/doc-governance.py;docs/testing-contract.md;tests/run.sh

- **M-20260915-b02-handoff-equivalence-gate-revalidated · 2026-09-15 handoff survey／list 等價 gate 舊候選完成重驗**:`B-20260819-debt-02` 原本只為未實作的 `repos:` 子欄預留，並非已觀察到的介面漂移。現行 `emit_active` 仍是 `list` 與 `survey` 的單一 active 輸出來源，完整輸出只有 `active:`、`path:`、`title:` 三種行，既有 gate 的固定前綴恰好覆蓋全部現行欄位；Git history／blame 亦確認 B02 建立後未新增 active 子欄或分叉輸出。portable topology、兩端薄入口、shared script／eval oracle 與完整 suite `PASS=1419 FAIL=0` 均重驗通過，沒有可重現且具行為成本的 RED。因此不加入 `repos:`、不擴白名單、不修改 handoff skill／eval／測試，B02 自 backlog 移除。
  - 日期來源:direct
  - 放棄:為未實作的 `repos:` 欄預先修改 gate；以人工注入未存在的子欄製造 mutation-only RED；把單一 `emit_active` 重構成更複雜的區段 parser；在沒有 observed behavior gap 時增加 skill prose 或 eval
  - 重議:active 清單實際新增第四種輸出行；`list`／`survey` 不再共用 `emit_active`；或出現兩入口對同一 active store 產生不同可觀察結果但現行 gate 仍放過的真實案例
  - 關聯:B-20260819-debt-02;D-20260819-handoff-active-mtime;D-20260819-handoff-no-ranking;docs/plans/2026-08-19-handoff-active-mtime.md;shared/skills/handoff/scripts/handoff-anchor.sh;shared/skills/handoff/evals.md;tests/run.sh

- **M-20260915-b05-deep-plan-model-policy-reassessed · 2026-09-15 deep-plan 不釘特定 SOTA，品質門後才以成本排序**:`B-20260819-debt-05` 的舊二選一把 Claude 真實執行的 session 模型、Claude 行為 eval 的樓層與跨 runtime 的 production reviewer 混成同一問題。現行 Claude Code background Agent 未指定 model／effort 時繼承主 session，且可由環境或 per-invocation 設定覆寫；Codex deterministic launcher 則以 `codex exec --ignore-user-config` 隔離使用者設定，未帶 `--model` 或 reasoning override，故使用該 CLI 版本的 runtime default，而不是 repo `codex/config.toml` 的 `gpt-5.4`／`medium`。兩端模型名稱、能力階與預設更新週期不可直接映射。決策矩陣因此分開處理：production review 先以 verdict、blocking recall 與 finding correctness 為 hard gate，只有已通過者才以成本／延遲排序；Claude 規則作用 eval 繼續以 `claude/evals/README.md` 的中央樓層為權威；既有 Codex P17 forward 只證明 fresh／parallel／read-only／fail-closed orchestration，沒有拿它比較模型效果。現況沒有 lower-cost 候選通過同一品質 oracle 的證據，也沒有因 Claude session 繼承、Codex runtime default 或 reasoning effort 造成錯誤 gate／顯著成本的 observed failure；因此不重跑舊 Sonnet／Opus、不做付費 Codex A/B、不釘模型 alias／snapshot、不新增 deep-plan prose、launcher override、eval 或 static gate。SOTA 發布本身不觸發此項重做；只有模型／effort 的具體選擇會改變現行驗收或設計決策時，才為該 runtime 預註冊最小實驗，記錄 exact model、effort、CLI/runtime version 與品質結果，再比較綠燈候選成本。B05 自 backlog 與 active state 移除。
  - 日期來源:direct
  - 放棄:把 Claude 的 Sonnet／Opus 名稱映射成 Codex 樓層；為省成本在沒有品質證據時降級 reviewer；把當前 SOTA 名稱寫死在 portable skill；因每次新模型發布就重跑全套；把 production review 紀錄當成規則作用 A/B
  - 重議:現行 fixture 上出現可重現的 model／effort 相關品質 RED；兩個候選均通過品質門但成本或延遲有顯著差異；runtime default／alias 變更造成 gate 漂移；模型退役迫使既有明示設定失效；或中央模型樓層權威正式改版
  - 關聯:B-20260819-debt-05;M-20260915-b23-model-floor-policy-reconciled;M-20260915-b22-old-round-ab-no-decision-value;D-20260825-portable-skill-authoring-default;claude/evals/README.md;shared/skills/deep-plan/evals.md;shared/skills/deep-plan/field-log.md;claude/skills/deep-plan/SKILL.md;codex/skills/deep-plan/SKILL.md;codex/skills/deep-plan/scripts/launch-reviewers.py;codex/config.toml;tests/run.sh

- **M-20260915-b06-deep-plan-reviewer-count-reassessed · 2026-09-15 deep-plan 每輪預設維持 N=2**:`B-20260818-debt-06` 以現行雙 runtime topology 與「經驗證、N=3 獨有、會改變 GO／NO-GO 的 blocking finding」重新解讀既有證據。Claude／Codex 已是雙薄入口、單一 shared workflow／brief／prompt；兩端只在 fresh reviewer lifecycle 上分工，預設皆為 N=2。E1 同一 frozen `dp1` fixture 的四個 i.i.d. reviewer 雖使 raw 阻斷聯集由 N=2 的 5.00 增至 N=3 的 6.00，但增量全是同一問題的嚴重度分歧，不是新問題；核心 blocker 4/4 命中且 4/4 判阻斷，四臂均為 NO-GO，因此依新 oracle 的決策相關獨有增益為 0。E3 第二輪出現第一輪未見的唯一 blocker，必須先有 Step 4 修訂才存在，證明第二輪價值而非第三位同輪 reviewer 價值；歷史 field log 只有 N=2 無對照觀察，也不能證成 N=3。決策矩陣只有「第三位在相同有效 fixture 上獨有命中已查證 blocker、把 N=2 的 GO 翻成 NO-GO，且跨獨立樣本穩定重現」會調高預設；raw finding 增量、severity disagreement、相同 verdict 或無可比對資料皆維持 N=2。現況沒有 N=2 造成錯誤 GO 的 observed failure，portable 化與 deterministic launcher 也只改 orchestration／fail-closed evidence，沒有產生 reviewer-count RED；依 skill-authoring 的 observed-gap 門檻不為理論可能性執行新付費批次，也不修改 skill、eval、launcher 或 gate。B06 自 backlog 與 active state 移除。
  - 日期來源:direct
  - 放棄:以 raw blocking／finding 聯集成長當成調高 N 的品質證據；把 severity disagreement 算成獨有缺陷；把第二輪 blocker 倒推成同輪 N 不足；為沒有 observed miss 的理論可能性重跑跨 runtime 付費批次
  - 重議:出現經事後驗證會實際放行壞計畫、且同輪第三位 reviewer 能穩定獨有攔下的 N=2 false negative；或相同 frozen fixture／model／effort 的預註冊比較在多個獨立樣本重現 N=2 GO→N=3 NO-GO。屆時先保留 raw outputs 與 finding provenance，再以新 work item 決定是否調高
  - 關聯:B-20260818-debt-06;D-20260819-no-single-round-deep-plan;D-20260825-deep-plan-empty-wait;D-20260825-portable-skill-authoring-default;M-20260915-b05-deep-plan-model-policy-reassessed;shared/skills/deep-plan/evals.md;shared/skills/deep-plan/field-log.md;shared/skills/deep-plan/references/workflow.md;claude/skills/deep-plan/SKILL.md;codex/skills/deep-plan/SKILL.md
