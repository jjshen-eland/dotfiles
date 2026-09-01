# 里程碑歸檔 — 2026-09

## 事件記錄（event-time）

- **M-20260901-container-network-collision-safety · 2026-09-01 Claude Code／Codex container-network 撞網防線完成**:shared kernel 已同步到 portable `AGENTS.md`、Claude 全域來源與 Codex 全域來源；kernel gate 新增必要指紋與實際 RED fixture，會阻止三份同步但安全條款被抽掉的假綠。G13 以真實事故作 observed RED：第一版 Claude GREEN、Codex 只過 3/4 且漏 cleanup isolation-table check；未放寬 oracle，將條文最小收緊為「未檢查 isolation table 就不算 cleanup 完成」後，Codex 與 Claude fresh sessions 都滿足四項判準。行為 eval 未給 shell/write 能力、沒有建立 Docker network；`./tests/run.sh` 最終 1243 PASS／0 FAIL，doc-governance ship audit 與 clean-clone verification 隨同本 work item 完成。
  - 日期來源:direct
  - 放棄:把 Codex 第一輪 3/4 當足夠；只以文字存在取代 runtime 行為驗證；在 eval 中真的重建肇事 network
  - 重議:G13 任一 runtime 回歸；kernel native loading 或 OrbStack isolation 行為改變；或 deterministic host-route preflight 能取代 prose gate
  - 關聯:D-20260901-container-network-collision-safety;claude/evals/contract-evals.md;tests/kernel-gate.py;tests/run.sh
