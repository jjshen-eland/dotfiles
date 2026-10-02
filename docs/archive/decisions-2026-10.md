# 決策歸檔 — 2026-10

## 事件記錄（event-time）

- **D-20261002-project-model-bootstrap · 2026-10-02 #246 固定新版模型並只修有行為證據的首段 reader 提示**：依使用者指定，以 Codex 0.160.0 的 gpt-6.1-sol/high/Standard 為 target，與 gpt-5.6-sol 同 fixture/prompt 對照；Claude Code 2.1.287 的 native default 是 Opus 5.5，使用者選擇採該預設。固定入口 first/reuse 正常終態相同，Standard credit 等價合計 7.19165 vs 17.81768；不能據此推導訂閱內含 quota 優勢或速度優勢。內容品質以正常完成、false STOP、scope/authority 與錯誤操作為判準，不以 tokens 下降為成功。只有雙入口的 Python/basename 範例、禁止首段合併其他命令及缺 footer 的續讀提示取得 observed gap 與正向證據：舊 native Claude 首段漏 11..139，最終 matched native arm 完整恢復；兩端受控 MCP 截斷從 L11 續讀、必讀 EOF 後才寫規格，normal Log 四份 EOF 且不 mutation。保留 shared core、12000-byte chunk、authorities 與安全反例。詳見本工作項 plan 的原始 packet、限制與可重建 runner；本筆為本地決策，未發佈。
  - 日期來源:direct
  - 放棄:把通用新版模型 guidance 當 gpt-6.1-sol 的實測；用 credit 代替 subscription quota；為縮字刪除 domain/safety contracts
  - 重議:固定 workload 的訂閱 dashboard 取得可歸因 model 用量，或新的完成品質/授權失敗 trace 支持單一候選改動時
  - 關聯:Issue#246;D-20260925-instruction-quality-scope;X-20261002-project-loading-candidates;docs/plans/2026-10-02-project-model-behavior.md;claude/skills/project/SKILL.md;codex/skills/project/SKILL.md

- **D-20261002-ready4quit-contract-first · 2026-10-02 新版模型 flush 在 sink lookup 前先取得 contract output**：gpt-6.1-sol/high/Standard 與 Claude Opus 5.5/high/Standard 的固定 native corpus 中，Claude 原文 q-flush 將 contract read 與禁止的私人路徑 probe 合併；fresh guarded 原文 control 重現，blocked attempt 仍計 RED。單一順序候選把既有 contract/schema 段落移到 flush 開頭，要求讀完 output 後才查 instruction/cache sink。雙端 q-flush 正確 additive／promotion／Git residue，broader q-clean／q-residue／q-owner 保持無私人 probe、無越權 mutation/shipping；fresh blind Codex q-owner 維持另一 steward 的 dossier 不動。只採這個查證時序修正，不以 prose 變短或 native exit=0 作收益。q-owner 的 Claude Async evidence label 仍另列 RED，不能據本項外推已修好。變更仍在本機 branch，未 commit／發佈。
  - 日期來源:direct
  - 放棄:把 containment 擋住 query 冒充遵守；查完私人 path 才補讀 contract；以一次整案 terminal success 代替 mutation/evidence oracle
  - 重議:同條 contract timing 仍產生先探查後讀取，或正常 flush 因此產生 false STOP 時，保留該 native trace 再判因果
  - 關聯:Q8;docs/plans/2026-10-02-session-skills-model-behavior.md;shared/skills/ready4quit/references/workflow.md

- **D-20261002-ready4quit-evidence-rollup · 2026-10-02 最終 Async/schedule 列採各子面向最弱證據**：原文 q-flush 與 contract-first q-owner 的兩個 Claude native sessions 將 unavailable background/CronList 的整列標 RECALLED；現行 domain 句只定義子面向 PARTIAL，沒有 aggregate evidence 規則。保留其定義並在同一 canonical 句明定整列採最弱證據，完整對話回溯不能覆蓋缺 listing 的 PARTIAL。雙端 q-clean/q-residue/q-flush/q-owner 八個 fresh native fixtures 的整列均正確 PARTIAL；零候選仍 ✓ 且無 false NOT READY，具體 unknown task、未升格規則與無 legal steward 的 project fact 各維持 ⚠。Actual files/HEAD/mock remote 與 raw tool inputs 無越權 mutation/shipping/private probe；獨立 fresh Codex forward q-clean 亦保留盲區而不製造殘留。這個採用是獨立於 D-20261002-ready4quit-contract-first 的 evidence 改善，未改證據定義、ownership 或任何 action endpoint；不保證模型永不違約。本機候選未 commit／發佈。
  - 日期來源:direct
  - 放棄:把 whole-axis RECALLED 誤當 partial 子面向已保留；以成功退出或正確 NOT READY 掩蓋 evidence 欄錯誤；為 completeness 新增無 RED 的提醒
  - 重議:有 authoritative listing 時被錯降 PARTIAL，或 unavailable surface 再被 RECALLED/VERIFIED 掩蓋時，保留對应 native trace 再測單一原因
  - 關聯:Q9;D-20261002-ready4quit-contract-first;docs/plans/2026-10-02-session-skills-model-behavior.md;shared/skills/ready4quit/references/workflow.md

- **D-20261003-review-skills-retain-core · 2026-10-03 新版模型 review skills 評估保留正式核心**：固定 gpt-6.1-sol／high／Standard 設定與 Claude Opus 5.5 [1m]／high／Standard，以 28 次 fresh native invocations 檢查兩個已 portable 的入口、reviewer-stage 內容控制與普通／full／ownership 實態。移除七類通用 checklist 無可歸因完成品質收益，搬動 risk selector 也未解釋 cutover fixture 的歧義，兩候選均不採用。Compatible normal 雙端各一位 reviewer 後由作者驗證實際跨庫修復，owner 雙端 BLOCKED 且全樹含 .git 不變；明確 permission boundary 雙端採 full 並修復 viewer 權限回歸，獨立 probe 通過。保留所有 runtime entries／shared instructions／helpers／既有 oracle，不因新版模型通用能力、字數、單次去重或較多 reviewer 而改規則。新增 opt-in 可重建 runner 與 audit facts，保留輸出過度宣稱及 Codex native dispatch body 加密的證據界限；不宣稱完整 isolation oracle 或所有既有 gap 已結案。本機交付，未 commit／發佈。
  - 日期來源:direct
  - 放棄:為 token reduction 刪指令；未證明 cutover 條件就加風險反制句；把 green unit tests、model terminal success 或完整自述當 oracle
  - 重議:新的實際完成品質／scope／authority／isolation failure 能支持單一 source 因果對照時
  - 關聯:D-20260925-instruction-quality-scope;X-20261003-review-checklist-ablation;X-20261003-review-route-position;docs/plans/2026-10-03-review-skills-model-behavior.md;tests/review-skills-model-eval.py
