# 死路歸檔 — 2026-10

## 事件記錄（event-time）

- **X-20261002-project-loading-candidates · 2026-10-02 #246 不採用 mode split、較小 chunk 或安全反例刪除**：Spec/Transfer 原樣按需拆分的 v1 在 Claude noop 漏 ship-paths；v2 加 route guard 後讀齊，但 Claude input 823860/65.56s 高於舊版 776994/54.41s，跨 runtime 收益不足。8000-byte 單一改法令 reader 從14增至20、兩端 input 上升，維持12000。獨立移除 Rationalization table/Red Flags 的已 commit normal Log，兩端都與舊版同樣正確確認終點、不 push/merge，未顯示完成品質改善，保留。無 skill 6.1 Sol 控制能守兩個局部授權/STOP 案例，但不是 domain contract 可刪的證據。fixture 舊 dirty prepare 未明示來源，不能把 STOP 算 false STOP；Python hook 可被 Codex -S 避開、PATH shim 被 login shell 改寫、MCP 的 auto/未設定 approval 被拒，都保存為無效材料，不計通過。改用官方設定的 local MCP 工具與 fresh fixture 才得到有效截斷對照。候選 patches、有效/無效 roots 與再議條件均在 plan；production shared core 無改動。
  - 日期來源:direct
  - 放棄:以少 bytes/少 tokens 冒充品質改善；用較快的一臂掩蓋漏讀或較慢的一臂；重跑相同材料洗綠
  - 重議:同 normal/safety oracle 下能穩定改善雙 runtime 完成行為或載入成本，且完整必讀與授權不退步時；需保存新 trace 與根因變因
  - 關聯:Issue#246;D-20261002-project-model-bootstrap;docs/plans/2026-10-02-project-model-behavior.md;tests/fixtures/project-reference-candidates/;tests/project-reference-eval.py

- **X-20261002-session-skill-reminder-ablation · 2026-10-02 不以新版模型名義刪除無品質收益的重述**：handoff 移除 Red Flags 但保留 Critical/W/R 的局部控制，以及 ready4quit 移除 sync 比喻/催促重述的控制，沒有可歸因的正常完成、scope 或安全收益。Handoff 的 active/archive 接續、只讀、未決產品選擇、直接 policy drift、write-side carry-forward 維持既有分流；transport stand-in 的 drift case 不能用來要求停止獨立 timeout tests。Ready4quit 控制並未證明 generic prose 造成私人 probe/證據彙總錯誤，Codex q-residue 還多跑一次 hygiene helper。保留原文，不以字數/token 下降採用候選。fixture 異常、原始 RED、分支差異都保留，沒有反覆跑同 packet 洗綠。
  - 日期來源:direct
  - 證據:`/tmp/session-skills-{baseline,ablation}-20261002` 的 native traces/source hashes/actual artifacts；可重建 runner 與限制見 plan
  - 放棄:文字看似重複就認定新版模型已內建；用 CLI exit=0 或更短 output 宣稱品質改善
  - 重議:新的真實 false STOP／scope/safety failure 能支持一個具體 source ablation 時
  - 關聯:D-20261002-ready4quit-contract-first;D-20260925-instruction-quality-scope;docs/plans/2026-10-02-session-skills-model-behavior.md

- **X-20261002-session-eval-command-count · 2026-10-02 更正 helper 字樣計數，不把讀腳本算重跑**：前筆 X-20261002-session-skill-reminder-ablation 所述 Codex q-residue「多跑一次 hygiene helper」不正確；raw trace 的兩次 path 字樣分別是 execute 與 `cat`，只有一次真實 helper execution。原 audit 用 command substring 計數造成 false positive，已改由實際 helper verdict schema 核對，並提供可重建的 `audit` action。其他 ablation 無可歸因品質收益的結論不靠此計數成立；不把讀腳本算品質回歸。
  - 日期來源:direct
  - 證據:`/tmp/session-skills-ablation-20261002/gpt-6.1-sol/q-residue/host-transport.jsonl`；一份 RESIDUE output，另一份是 shell source
  - 放棄:把 command string 出現 helper 路徑當 execution evidence
  - 重議:helper output schema 改變，或出現不具 schema 的實際執行時，人工核對 raw trace，不猜 call count
  - 關聯:X-20261002-session-skill-reminder-ablation;tests/session-skills-model-eval.py;docs/plans/2026-10-02-session-skills-model-behavior.md

- **X-20261002-session-close-placeholder · 2026-10-02 STATUS 收尾沿用 scanner 接受的既有 no-active 文字**：收尾暫以「(無)」代替 active item，觸發 `STATUS active content outside H3 item`。已還原原 repo 的「目前無進行中項目。」並直接 audit exit 0；第二輪 full suite 的背景 governance scan 在修正前已取得舊內容，因此保留該 1563/1、exit 1 結果，不能改標通過。後續在固定 final tree 重跑 suite，這是文件 schema 修正後驗證，不是重跑模型洗綠。
  - 日期來源:direct
  - 證據:`/tmp/session-skills-suite-final-20261002.log` 的 test_current_repo_ship_audit_is_clean、STATUS.md:15；修正後 direct audit 無 findings
  - 放棄:用任意 no-active placeholder 取代已採用 schema；在背景 scanner 執行期間改狀態後把它的舊輸出當 final snapshot
  - 重議:repo scanner 或 adopted no-active schema 明確改變時
  - 關聯:M-20261002-session-skills-model-review;docs/plans/2026-10-02-session-skills-model-behavior.md

- **X-20261003-session-skills-premature-active-removal · 2026-10-03 本機交付不能先移除尚未 commit 的唯一 assignment**：前輪本機評估完成後已移除 active item，但 HEAD 仍無該工作線的 durable assignment；ordinary helper 的 no-active-items/PASS 不能充當含 shared history／plan 的 completion candidate authority。本輪 `$project --merge` 先恢復原工作線的 writer／steward 與待 shipping 驗收，普通 helper 以 active-writer-workspace-match/PASS 核對，再保留 assignment 於實作 commit，後續單一結案 candidate 必須由 completion parent 重驗。未重寫既有 commit、未補造早期 assignment 已 commit 的證據；frozen implemented plan 不修改。
  - 日期來源:direct
  - 放棄:把 no-active-items/PASS 當 steward evidence；同一顆 commit 新建又移除唯一 assignment；本機驗收即提前清掉 shipping gate 所需的 active state
  - 重議:未來本機交付尚無 commit 授權時，保留 active item 與完成證據，待 Log 提交階段再結案
  - 關聯:M-20261002-session-skills-final-tree-verified;docs/plans/2026-10-02-session-skills-model-behavior.md;shared/skills/project/references/log-workflow.md
