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
