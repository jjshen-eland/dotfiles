# 里程碑歸檔 — 2026-10

## 事件記錄（event-time）

- **M-20261001-issue-229-backlog-status-corrected · 2026-10-01 #229 backlog 現況校正候選完成**：PR #247 已 rebase merge 至 `main`（交付 SHA `a3c4170`／`195732e`）、兩平台必要檢查通過，GitHub #229 已按凍結批次條件關閉。`docs/backlog.md` 的 `B-20260928-project-merge-continuation` 原本仍稱本輪未送出且 #229 open；本工作項校正發佈事實，保留尚缺有效 native packet 的 first-delta safety 案例。原單顆本地候選 `98663aa` 缺 active steward，依使用者確認建立 assignment 後重建；本筆記錄時修正仍待本次 PR／merge，未宣稱已交付。
  - 日期來源:direct
  - 放棄:把 B-* 的未完成 safety 案例一併關閉，或把原候選在無 durable steward 時原樣送出
  - 重議:剩餘 first-delta safety 案例取得有效雙端 normal／safety 證據時，依原 backlog 驗收處置
  - 關聯:Issue#229;PR#247;B-20260928-project-merge-continuation;STATUS.md;docs/backlog.md

- **M-20261001-handoff-frontmatter-anchor-verify · 2026-10-01 Handoff 錨點驗證限縮至 frontmatter**：`verify` 原本全檔搜尋 `created:`／`anchor:`，隔離 fixture 證明正文範例可造成假 FRESH 或假 STALE-RISK，缺少 `dirty=N` 的錨點也會假 FRESH。先新增三組回歸測試取得 RED，再讓 helper 只讀檔案開頭且完整封閉的 frontmatter，並驗證錨點四欄與 `dirty=N` 數值格式。實際盤點本機 26 份既存 active/archive 交接檔皆有合法 frontmatter；修後逐份驗證均無 `BAD-ANCHOR`、未知日期或 `UNVERIFIABLE`。Claude Code／Codex 共用同一 helper，雙入口 validator 通過；全 repo `./tests/run.sh` 為 1542 PASS、0 FAIL，文件稽核通過。本筆只記本地功能分支候選，未宣稱已發佈。
  - 日期來源:direct
  - 放棄:繼續全檔搜尋並試圖排除 fenced code（正文仍可有一般文字範例，且無法構成 metadata 邊界）
  - 重議:出現合法舊交接檔沒有封閉 frontmatter，或新錨點 schema 與既有檔案不相容時，以該實檔增補 fixture 後調整
  - 關聯:D-20260823-portable-handoff-skill;M-20260823-portable-handoff-skill;shared/skills/handoff/scripts/handoff-anchor.sh;tests/run.sh

- **M-20261001-pr249-shard-manifest-synchronized · 2026-10-01 PR #249 的 integration assertion manifest 已與新增回歸測試同步**：首輪 required run `36798375305` 的 Ubuntu 24.04、macOS 15 都在 integration shard `1138 PASS／0 FAIL` 後，因 `tests/shard-manifest.tsv` 仍要求舊值 1132 而失敗；差額正是本次新增的六個 assertion。最小修正只把 integration 期望值調為 1138，不移除測試或放寬 aggregate 判準。本機 `./tests/run-parallel.sh` 以三 shard 合計 `1542 PASS／0 FAIL` 通過，serial `./tests/run.sh` 已在相同程式內容下 `1542 PASS／0 FAIL`；同 PR 新 head 的 required CI 仍待重驗，未宣稱已合併。
  - 日期來源:direct
  - 放棄:只重跑同一個失敗 run；減少新增 assertion 以符合舊計數；放寬 fail-closed aggregator
  - 重議:新 head 的任一 required OS 出現不同失敗，或之後 integration 斷言數再次漂移
  - 關聯:PR#249;run:36798375305;M-20261001-handoff-frontmatter-anchor-verify;tests/shard-manifest.tsv;tests/run.sh
