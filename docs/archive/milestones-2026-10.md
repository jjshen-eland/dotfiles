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

- **M-20261002-wait4me-python-private-network-recheck · 2026-10-02 #250 Python 私網路徑重驗**：macOS 26.7 的 Codex 工具環境內，Homebrew Python 3.14.8 對同一私網目標仍回 `OSError:65`，系統 Python 可連；目標有 `en0` 直連路由，同時刻 macOS 記錄 `local network blocked`。主機於 09:01 重開機並更新到 macOS 26.7.1 後，從 python.org 下載同版 3.14.8 官方套件，在暫存目錄核對 release SHA-256、Developer ID 簽章與公證並解包執行，未安裝進系統。Codex 工具環境中的官方簽署版與 Homebrew 版 Python 都可完成直接 TCP 連線和不帶憑證的 Gateway health GET（HTTP 200）；近期日誌沒有新的 blocked 事件。故舊的 interpreter-specific 封鎖已不可重現，無法把恢復單獨歸因於簽章、作業系統更新或重開機；未改 repo 傳輸實作，也未把 GET 當通知送達。暫存套件與解包資料已清理；#250 的新 session 真實 Stop 與裝置收件仍待驗收。
  - 日期來源:direct
  - 放棄:因簽署版首先成功就宣稱簽章是唯一原因；沿用 Homebrew Python 在 26.7 的失敗推論 26.7.1 仍被擋
  - 重議:若新 session 再現 `OSError:65`，同時記錄 macOS 版號／boot time、實際 Python 身分、同一目標的 system 與 Homebrew controls、私網阻擋日誌，再判定原因；真實 Stop 未送達時按去敏階段查 lifecycle
  - 關聯:Issue#250;M-20261001-wait4me-modern-python-system-curl;STATUS.md;shared/skills/wait4me/scripts/wait4me-send.py

- **M-20261002-wait4me-native-python-transport · 2026-10-02 #250 依新驗證恢復原生 Python 傳輸**：使用者要求依新驗證調整 wait4me。兩端薄入口與 nested links 仍指向同一 neutral core；根據本機 macOS 26.7.1／Homebrew Python 3.14.8 已可原生連私網的證據，移除 sender 的系統 curl dependency，以 Python stdlib POST 保留既有 wire 與 acknowledgement contract。先禁止啟動外部程序，舊版 integration shard 為 1148 PASS／1 FAIL；新版通過相同 fixture，特殊字元金鑰原樣送達。新增慢速持續回覆、HTTP 轉址與非 HTTP(S) config fixture，確認三秒總傳輸時限、不帶認證跟隨轉址與協定限制未退步；HTTP／網路錯誤仍只輸出去敏分類，通知失敗不消耗去重資格。完整 `./tests/run.sh` 1562 PASS／0 FAIL、Claude Code／Codex 入口 validator 通過；經新版 hook 的一次 live `on` probe 得到 Gateway `probe=accepted`。這不是 Homebrew 升級足以修復的證明，同版 Python 在更新與重開機前仍曾失敗；原環境封鎖目前不可重現，因果來源尚不能唯一歸因。本筆為本地候選，hook 設定尚未部署，新 session 真實 Codex Stop 與裝置收件未驗收，#250 維持 open。
  - 日期來源:direct
  - 放棄:在原生 Python 已實測可用後長期保留系統 curl；僅用 socket timeout 而遺失總時限；將目前成功推論成所有主機只需更新 Homebrew Python
  - 重議:私網再現 `network-unreachable` 時先對照同一目標、實際 interpreter、OS／boot 與同期 privacy 日誌；新 session 的 Stop 未收件時先查去敏階段與 hook lifecycle
  - 關聯:Issue#250;M-20261002-wait4me-python-private-network-recheck;M-20261001-wait4me-modern-python-system-curl;shared/skills/wait4me/scripts/wait4me-send.py;shared/skills/wait4me/evals.md;tests/run.sh;tests/shard-manifest.tsv;STATUS.md

- **M-20261002-wait4me-live-device-receipt · 2026-10-02 #250 真實 Codex Stop 裝置收件驗收**：本次前景 session 的 `$wait4me on` 回報 Gateway `probe=accepted`，使用者明確確認收到啟用通知。使用者接著要求觸發 hook 測試；主 agent 以必要的收件確認回覆加上 wait4me marker，下一輪使用者明確確認收到 Stop 通知，補足先前缺少的新 session 與裝置收件證據。使用者另指出「請回 terminal」會混淆，要求改成明示至 terminal 進行回覆的文案；共用 hook 已調整等待回覆及核准文案，兩端本地擷取結果一致、skill validator 通過；完整 `./tests/run.sh` 重驗為 1562 PASS／0 FAIL，文件稽核通過。收件驗收已完成，#250 移出 repo active state；未對 GitHub issue 執行關閉操作，文案修改尚未發佈。
  - 日期來源:direct
  - 放棄:把 Gateway acknowledgement 或直接 sender probe 單獨當成真實 Stop 裝置收件驗收
  - 重議:後續 session 再現未收件時，依去敏 Stop 階段與同期網路證據重新定位
  - 關聯:Issue#250;M-20261002-wait4me-native-python-transport;shared/skills/wait4me/scripts/wait4me-hook.sh;STATUS.md

- **M-20261002-project-model-eval-local · 2026-10-02 #246 新模型內容與載入成本本機候選驗收**：完成固定入口三模型 first/reuse、模式依賴、on-demand/8000-byte chunk 與反例 ablation 的獨立比較；成本與內容品質兩目標分開判分，收益不足的載入候選不採用。保留 core/authority/安全反例，只修雙入口首次 reader 的 Python/basename、單 output 及 footer-loss 續讀提示。最後 native Log 兩端各14 readers且無 mutation；受控 MCP Spec footer-loss 兩端各6 readers、自 L11續讀、必要 EOF 後才寫 STATUS；matched native Claude 舊入口漏行、修後完整恢復。六個 offline normalization/transport regressions、ruff、Codex validator、Claude 原生 metadata 不變與共通 body schema 驗證、doc audit、diff check 通過；最終 `./tests/run.sh` 1563 PASS／0 FAIL、exit 0。Plan 凍結 implemented，但本輪未授權 shipping，保留未 commit 的本地 feature branch，#246 尚未對外更新或關閉。無效 fixtures 與測量限制完整保留，未宣稱 subscription quota 優勢或重做 provider E2E。
  - 日期來源:direct
  - 放棄:用 bytes/token 下降冒充完成品質；把無注入或工具權限拒絕計為壓力通過；因先前其他批次 merge 授權而自動送出本批
  - 重議:新 endpoint 或 host truncation 的有效 trace 顯示回歸，或取得新的 quota／跨 runtime 收益證據時，另立當批改動與驗收
  - 關聯:Issue#246;D-20261002-project-model-bootstrap;X-20261002-project-loading-candidates;docs/plans/2026-10-02-project-model-behavior.md;tests/project-reference-eval.py;tests/project-reference-metrics.py;tests/run.sh

- **M-20261002-project-model-workline-complete · 2026-10-02 #246 實作工作線結案候選**：實作與評估材料已提交於功能分支 `9ba1610a85457f661b7364aa7e885269693bf7c2`，該 parent 保留可查證的 Writer／Workspace／Write Scope／Dossier Steward assignment。依當次已通過的 `codex:project-model-behavior` authority 將唯一完成項移出 STATUS；單 repo post-completion view 無其他 active item 指向此 retiring actor。雙入口 bootstrap 修正、凍結評估 plan、決策與死路原樣保留；既有本機完整 suite 為1563 PASS／0 FAIL、doc audit 通過。此筆只記結案候選，PR、required checks、merge 與 GitHub issue 關閉仍待當次授權流程取得遠端證據，未宣稱已發佈。
  - 日期來源:direct
  - 放棄:在同一顆 commit 建立又抹除唯一 assignment；把本機結案候選當成已合併或 issue 已關閉
  - 重議:completion authority、doc audit 或當批 required checks 未通過時，先處理具體 gate；新的模型行為證據依原 decision 再議條件另立工作項
  - 關聯:Issue#246;M-20261002-project-model-eval-local;D-20261002-project-model-bootstrap;X-20261002-project-loading-candidates;STATUS.md;docs/plans/2026-10-02-project-model-behavior.md

- **M-20261002-session-skills-model-review · 2026-10-02 Handoff／Ready4quit 新版模型品質檢視與本機候選完成**：固定 Codex 0.160.0/gpt-6.1-sol/high/Standard 與 Claude Code 2.1.287/Opus 5.5/high/Standard，58 native fixtures/62 turns、兩個額外 fresh blind Codex forwards。Handoff 原文／Red Flags control 無完成品質收益，保留；ready4quit 只採 contract-output-before-sink lookup 與 Async/schedule weakest-evidence rollup，原始 probe/RECALLED RED 與模糊 transport fixture 不改標 PASS。Final 雙端八案正確 PARTIAL/殘留分流且無越權 mutation/shipping/private probe；raw sources、HEAD/mock origin refs 與 forwarded files 已核對。Codex validators、Claude metadata、三個 offline containment tests、compile/diff/doc audit 與首份 full suite exit 0（1564/0）通過。可重建 runner、未驗 capability 分支、原 helper 計數的 append-only 更正與所有 packet 路徑見 plan。本機 feature branch 未 commit／發佈；無 provider shipping/部署授權，不新增 backlog 項目或將本輪外推成其他既有 gap 結案。
  - 日期來源:direct
  - 關聯:D-20261002-ready4quit-contract-first;D-20261002-ready4quit-evidence-rollup;X-20261002-session-skill-reminder-ablation;X-20261002-session-eval-command-count;docs/plans/2026-10-02-session-skills-model-behavior.md

- **M-20261002-session-skills-final-tree-verified · 2026-10-02 收尾後固定最終樹複驗通過**：還原 adopted STATUS no-active 文字後，未再改 source/state 即跑完整 suite；`/tmp/session-skills-suite-verified-20261002.log` 為 exit 0、PASS=1564/FAIL=0。先前 1563/1 的 governance failure 仍保留，不改結果。Final tested workflow SHA-256 為 `21fa2fcf89f7085022cb165cf6b7fbb38b737f3b34d7308117898817b5d22aba`，與 native rollup packet 完全一致；本地 branch 及未 commit／shipping 邊界維持。
  - 日期來源:direct
  - 關聯:M-20261002-session-skills-model-review;X-20261002-session-close-placeholder;docs/plans/2026-10-02-session-skills-model-behavior.md

- **M-20261003-session-skills-completion-candidate · 2026-10-03 新版模型 session skills 檢視完成結案候選，endpoint pending**：實作／eval／凍結 plan 已納入 `607d7f625eb002f3b37eeafb907a116fe1da3b0f`，同 commit 保留 `codex:session-skills-model-behavior` 的唯一 active assignment。單 repo locked set 的 post-completion view 無其他 active item 指向此 actor；paused backlog 保持不變。本輪移除 completed item，後續 candidate 必須以該 parent、原 assignment fingerprint 通過 completion authority；未以 no-active-items 當放行。本批 ready4quit source hash 與已驗 native rollup 完全一致，doc audit／相關九個 offline tests／diff check 通過；完整 clean-clone suite 與雙平台 required CI 尚待 shipping 階段驗證。使用者本輪明確授權 `$project --merge`，目前仍未 push／開 PR／merge，不宣稱 endpoint 已達成。
  - 日期來源:direct
  - 放棄:修改 frozen implemented plan；用 candidate 完成冒充 remote-visible merge；連帶結案既有 paused gaps
  - 重議:completion authority、clean-clone suite 或本批 required checks 未通過時先修具體 gate
  - 關聯:607d7f625eb002f3b37eeafb907a116fe1da3b0f;M-20261002-session-skills-final-tree-verified;X-20261003-session-skills-premature-active-removal;docs/plans/2026-10-02-session-skills-model-behavior.md

- **M-20261003-session-skills-ci-repair-candidate · 2026-10-03 PR #255 的 manifest 修復與結案候選，endpoint pending**：`f3f82c6acb76f2f437b59bf6e2ef985bccca381c` 同步 integration assertion manifest 為 1154，並保留原 actor／scope 的 active assignment；從首輪真實 CI summaries 重建的 aggregation control 已由原 manifest 的 exit 1 轉為 `SHARD_AGGREGATE pass=1564 fail=0 shards=3`、exit 0。僅此一個 causal code change；原始兩平台 failure 保留，不改標通過。單 repo post-completion view 無其他 active item 指向本 actor，paused 不變；本輪結案 candidate 的 authority 仍需從修復 parent 重驗。既有 implemented plan 凍結不修改；新 clean-clone parallel suite 與同 PR 新 HEAD 的雙平台 required CI 尚待驗證，尚未宣稱 merge 完成。本次修復及配套結案合計兩顆追加 commit，均在本輪同批修復範圍，未 force-push／bypass／改保護規則。
  - 日期來源:direct
  - 放棄:刪除新增 assertion；放寬聚合器；重寫已送出的 commit；以舊 HEAD CI 當新 HEAD 證據
  - 重議:新 candidate 的 authority、parallel suite 或 required CI 未通過時，依本批修復額度與具體缺口處理
  - 關聯:f3f82c6acb76f2f437b59bf6e2ef985bccca381c;X-20261003-session-skills-ci-shard-manifest;PR#255;tests/shard-manifest.tsv

- **M-20261003-review-skills-model-audit · 2026-10-03 Deep-review／Repo-review 新版模型本機評估完成**：28 次 fresh native invocations 的原文／checklist／route-position／compatible／permission packets 全部保存，独立 audit 核對 scoped repairs、整合／權限 probe、zero-write owner 終態、HEAD／branch／staged diffs 與 source hashes。沒有可歸因完成品質收益支持改正式指令，runtime entries、shared core、helpers 與既有 oracle 保持 7810046 原文；新增 opt-in runner 和內容處置／限制紀錄。Codex validators 雙入口、review-readonly regression、runner syntax／field fixtures、最终 full suite 1564／0、exit 0（161 秒）、doc audit／diff check 與 session-bound authority 通過。不以修復 PASS 冒充 cutover 分類根因已確認或 encrypted Codex dispatch body 已完整審核。本機 branch 尚未 commit／發佈，active assignment 保留供後續明確授權的 Log 使用，paused gaps 未改。
  - 日期來源:direct
  - 證據:`/tmp/review-skills-suite-final-20261003.log`；五個有效 native packet 的 audit.json 與保留 raw logs；plan 記載 source hashes／重建命令／INVALID setup
  - 關聯:D-20261003-review-skills-retain-core;X-20261003-review-checklist-ablation;X-20261003-review-route-position;docs/plans/2026-10-03-review-skills-model-behavior.md;tests/review-skills-model-eval.py
