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

- **M-20261001-ready4quit-git-evidence-fail-closed · 2026-10-01 ready4quit Git 證據誤判修正候選完成**：隔離測試先證明 `git status` 單獨失敗時 helper 會把空 stdout 當成乾淨，以及自訂 fetch refspec 漏刷 baseline 時會假 CLEAN；四項斷言取得 RED，另補兩項 PR default ref 過期的回歸斷言。修正後 status 失敗及必要 tracking ref 無法證明新鮮時回報 UNKNOWN；標準 wildcard fetch 保持既有單次刷新，自訂 refspec 才額外核對遠端 OID。同步更新 eval 的 explicit-only 觸發與 target repo shipping 預期，修復一處既有 JSON 跳脫錯誤，保留舊執行紀錄的歷史語境。Codex 入口 validator、doc-governance audit、serial 與 parallel 測試均通過，兩套測試各為 1548 PASS、0 FAIL；本筆只記本地候選，尚未發佈或取得雙端 live behavior eval。
  - 日期來源:direct
  - 放棄:把成功 fetch remote 直接等同所有 tracking ref 新鮮；把失敗的 status 空輸出解讀為 clean；依舊版自然語句觸發 oracle 改動現行 explicit-only 入口
  - 重議:custom refspec 的遠端驗證造成實測收尾延遲，或雙端 live behavior eval 出現與現行 oracle 不符的結果時，以該證據重新評估
  - 關聯:D-20260823-portable-ready4quit-skill;shared/skills/ready4quit/scripts/git-hygiene.sh;shared/skills/ready4quit/evals.md;tests/run.sh;tests/shard-manifest.tsv

- **M-20261001-wait4me-codex-diagnostics-control-probe · 2026-10-01 #250 診斷與控制通知候選**：隔離 Codex `Stop` 實測可收到 session ID 與最後訊息；工具終端及 hook 都能連 loopback fixture，但同時對私網 Gateway TCP 回 `OSError:65`，目前無法證明 hook 專屬網路隔離。`codex exec --ephemeral` 的背景 Stop 連入口紀錄都沒有，同一 probe 的同步 Stop 完整執行；因此 Codex Stop 改為 5 秒上限的同步 hook。共用 helper 為 enabled Stop 留 owner-only 去敏階段、sender exit 與網路錯誤類別，off／session 結束時清除診斷；fake capture 實測只送一次，loopback 拒絕連線時為 `send-failed rc=75 kind=connection-refused` 且沒有 sent marker。依使用者追加需求，bare／`on` 與已啟用的 `status` 各發一則測試通知，分開回報開關與 Gateway acknowledgement；off 的 status 不發，失敗不假報送達。隔離 Codex 的真實 UserPromptSubmit 取得一筆 capture；完整 `./tests/run.sh` 為 1557 PASS、0 FAIL。本筆只記本地候選，#250 的私網因果來源及裝置收件尚未驗收。
  - 日期來源:direct
  - 放棄:根據舊的 host control 推論當前 LAN 正常；開放整個 LAN 或憑猜測建立 relay；把 Gateway acknowledgement 當成 Stop marker 與裝置收件的全部證據
  - 重議:同時段 host terminal 可連但 Codex Stop 不可連時，依去敏階段與錯誤類別定位第一個不同邊界；使用者在新 session 收到 on/status probe 但收不到 blocking Stop 時，改查 marker 與 lifecycle
  - 關聯:Issue#250;D-20260929-wait4me-session-hook-boundary;shared/skills/wait4me/scripts/wait4me-hook.sh;shared/skills/wait4me/scripts/wait4me-send.py;shared/skills/wait4me/evals.md;tests/run.sh

- **M-20261001-wait4me-system-python-private-path · 2026-10-01 #250 私網發送 interpreter 差異定位與候選修正**：使用者在一般 Terminal 執行同一 sender 回 exit 0 且確認裝置收件，排除 Gateway 離線與使用者整體網路中斷。Codex 工具內的 `nc` 與 `/usr/bin/python3` 可連相同私網目標，Homebrew Python 3.13／3.14 回 `OSError:65`；系統 Python 執行原 sender 回 0。先加入 PATH 中 Python stub 使整合 shard 為 1147 PASS／1 FAIL，再將 sender shebang 固定到本機已實測可連線的 `/usr/bin/python3`，同一 hook 的 live `on` probe 取得 Gateway acknowledgement；完整 suite 1558 PASS／0 FAIL、雙端 skill validator 通過。這只證明修復可重現的 interpreter-specific 連線失敗，不推論 OS 權限內因，亦不把直接 hook probe 當成新 session 的 Codex Stop 裝置收件驗收；#250 維持 open。
  - 日期來源:direct
  - 放棄:以一般公網可連推論所有私網都通；以工具中 Homebrew Python 失敗推論 Codex 所有子程序都無私網；未證實前修改廣域網路權限
  - 重議:支援系統缺 `/usr/bin/python3` 或版本低於 sender 所需時，選可用且經私網實測的替代；新 session 的 Codex Stop 仍無裝置收件時，依去敏階段找下一個邊界
  - 關聯:Issue#250;shared/skills/wait4me/scripts/wait4me-send.py;shared/skills/wait4me/evals.md;tests/run.sh;tests/shard-manifest.tsv

- **M-20261001-wait4me-modern-python-system-curl · 2026-10-01 #250 移除舊系統 Python 固定執行路徑**：本機 `/usr/bin/python3` 是 3.9.6，Python 3.9 已在 2025-10-31 結束上游支援；因此前一筆以系統 Python 修復的候選改為讓 PATH 中 Python（本機 3.14.7）處理輸入、由已實測可連私網的 `/usr/bin/curl` 送 POST。API key 與 JSON body 經 stdin config 交給 curl，不進 argv 或暫存檔；verbose 只在程序內用於去敏錯誤分類，不輸出原文。先以 Python socket 封鎖 fixture 取得 sender 失敗的 RED，再以新傳輸通過整合 shard；特殊字元金鑰仍原樣送達 fake Gateway。另以 HTTP 401 fixture 確認錯誤輸出只含安全類別。新版 `on` hook 直接測試取得 live Gateway `probe=accepted`；完整 suite 1559 PASS／0 FAIL、雙端 skill validator 與文件稽核通過。這些證據不等於裝置收件或新 session 真實 Codex Stop 已驗收，#250 維持 open。
  - 日期來源:direct
  - 放棄:長期固定已終止上游支援的系統 Python；在 argv 或磁碟暫存檔放金鑰；把 Gateway acknowledgement 當裝置收件
  - 重議:若 curl 在目標主機缺席或不能連私網，依該主機實測修正 transport；若新 session Codex Stop 未送達，先看 owner-only 去敏診斷階段
  - 關聯:Issue#250;M-20261001-wait4me-system-python-private-path;shared/skills/wait4me/scripts/wait4me-send.py;shared/skills/wait4me/evals.md;tests/run.sh
