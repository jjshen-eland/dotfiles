# 死路歸檔 — 2026-10

## 事件記錄（event-time）

- **X-20261002-project-loading-candidates · 2026-10-02 #246 不採用 mode split、較小 chunk 或安全反例刪除**：Spec/Transfer 原樣按需拆分的 v1 在 Claude noop 漏 ship-paths；v2 加 route guard 後讀齊，但 Claude input 823860/65.56s 高於舊版 776994/54.41s，跨 runtime 收益不足。8000-byte 單一改法令 reader 從14增至20、兩端 input 上升，維持12000。獨立移除 Rationalization table/Red Flags 的已 commit normal Log，兩端都與舊版同樣正確確認終點、不 push/merge，未顯示完成品質改善，保留。無 skill 6.1 Sol 控制能守兩個局部授權/STOP 案例，但不是 domain contract 可刪的證據。fixture 舊 dirty prepare 未明示來源，不能把 STOP 算 false STOP；Python hook 可被 Codex -S 避開、PATH shim 被 login shell 改寫、MCP 的 auto/未設定 approval 被拒，都保存為無效材料，不計通過。改用官方設定的 local MCP 工具與 fresh fixture 才得到有效截斷對照。候選 patches、有效/無效 roots 與再議條件均在 plan；production shared core 無改動。
  - 日期來源:direct
  - 放棄:以少 bytes/少 tokens 冒充品質改善；用較快的一臂掩蓋漏讀或較慢的一臂；重跑相同材料洗綠
  - 重議:同 normal/safety oracle 下能穩定改善雙 runtime 完成行為或載入成本，且完整必讀與授權不退步時；需保存新 trace 與根因變因
  - 關聯:Issue#246;D-20261002-project-model-bootstrap;docs/plans/2026-10-02-project-model-behavior.md;tests/fixtures/project-reference-candidates/;tests/project-reference-eval.py
