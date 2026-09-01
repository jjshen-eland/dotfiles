# 關鍵決策歸檔 — 2026-09

## 事件記錄（event-time）

- **D-20260901-container-network-collision-safety · 2026-09-01 container E2E 採 first-attach CIDR gate 與跨 runtime kernel**:2026-09-01 的 Codex inline E2E 為保留 production literal `10.10.12.150`，明確建立與 macOS host LAN 相同的 `10.10.12.0/24` 並 attach containers；OrbStack 把 CIDR 留在 PF isolation table，Docker network removal 未回收該 entry，造成 LAN／SSH 中斷約 3.5 小時。共同 kernel 現要求 first attach 前證明 CIDR 不與 host／LAN／VPN／production routes 重疊，inline／temporary E2E 不豁免；不得複製 production/LAN CIDR 保留 IP literal，改用 auto allocation＋DNS/test config。macOS／OrbStack cleanup 未檢查 isolation table 前不算完成，只報告碰撞且不自行刪除無關 firewall entries。三份 runtime-native kernel 以 deterministic gate 防漂移，G13 用無 shell/write runner 驗證 Claude Code 與 Codex fresh sessions 都會 STOP 並提出安全替代。
  - 日期來源:direct
  - 放棄:以 `--internal` 或 cleanup trap 當無撞網證明；為模擬 production identity 複製正式 CIDR；只設 Docker default-address-pools（明示 `--subnet` 可繞過）；只寫 Claude memory／單一 runtime 規則；自動刪除所有 PF isolation 殘留
  - 重議:container runtime 能在 first attach 前機械拒絕所有 host route overlap 並可靠回收 isolation state；或 G13 出現跨 runtime 回歸
  - 關聯:claude/evals/contract-evals.md;AGENTS.md;claude/CLAUDE.md;codex/AGENTS.md;tests/kernel-gate.py;tests/run.sh
