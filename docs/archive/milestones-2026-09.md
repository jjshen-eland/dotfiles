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
