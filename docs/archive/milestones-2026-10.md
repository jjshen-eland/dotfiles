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

- **M-20261003-review-skills-completion-candidate · 2026-10-03 Review skills 評估工作線結案候選完成**：使用者本批明確叫用 `$project --merge`，audit runner、凍結 plan 與 event-time 紀錄已提交於 92216a3ad513e1d467d876c3fc2374cffd15efa4，該 parent 保留完整 writer／steward assignment。以原 fingerprint 與 pre-completion HEAD 重驗 current-session workline binding PASS；單一 locked repo 移除此已驗收項後無 remaining active item 或 retiring steward reference。此提交移除 completed active item、結束 codex:review-skills-model-behavior 工作線；paused gaps、backlog 與正式 review 指令均維持原狀。既有 full suite 1564／0、exit 0；candidate parent authority、clean clone 與 required CI 必須送出前／merge 前核對，PR／merge endpoint 尚 pending。
  - 日期來源:direct
  - 放棄:同一顆首次提交抹掉唯一 assignment；以 no-active-items PASS 取代 completion parent authority；在 endpoint evidence 前宣稱 shipped
  - 重議:completion gate、clean clone、required checks 或 merge 受阻時，保留本事件的 pending 事實並依本批 shipping contract 處理
  - 關聯:92216a3ad513e1d467d876c3fc2374cffd15efa4;M-20261003-review-skills-model-audit;D-20261003-review-skills-retain-core;docs/plans/2026-10-03-review-skills-model-behavior.md

- **M-20261003-deep-plan-model-audit · 2026-10-03 Deep-plan 新版模型內容評估本機完成**：完成 22 次 native 頂層 invocations（十二份原文／§4 控制 reviewer-stage，十次含補驗的 author flow），另 18 个原生獨立子審查。兩端 ordinary-ready／decision 正確分流；有效 Sol／Opus wire N2 × 兩輪修同一 scratch plan後 GO、無 repo 寫入；Sol alert 停待 blocking disposition，Opus alert 缺 severity／混層而正確停止、不輸出 gate。首批六個 Sol full child 因 shell capture 缺口不作模型證據，既有 --codex-bin 補驗保留另外六個明示 gpt-6.1-sol／high 原始 child commands／prompts／outputs。正式 skill／shared core／metadata／oracle 均不變，局部 ablation 無品質收益；模型過度外推及大型／production coverage 限制保留。
  - 日期來源:direct
  - 驗收:兩入口 quick_validate valid；repair-context focused tests 2/2；runner AST；三組 frozen source hashes、不變 target／Git snapshots、bytecode／symlink 補核；全套 ./tests/run.sh exit=0，PASS=1564 FAIL=0；doc-governance audit --ship、whitespace、history append-only、formal-source unchanged PASS
  - 證據:docs/plans/2026-10-03-deep-plan-model-behavior.md;tests/deep-plan-model-eval.py;`/tmp/deep-plan-{baseline,ablation,child-capture}-20261003`;`/tmp/deep-plan-final-suite-20261003.out`
  - 範圍:本機完成，branch=refactor/deep-plan-model-behavior；未 commit／push／PR／merge／deploy；B-20260924-workflow-review-residuals 不結案
  - 關聯:D-20261003-deep-plan-retain-core;X-20261003-deep-plan-checklist-ablation

- **M-20261003-deep-plan-completion-candidate · 2026-10-03 Deep-plan 評估工作線結案 candidate**：依本次 `$project --merge` 授權，先以 4efb0542e431904e505d3d19bbb19e7dae62e92d 提交 opt-in runner、frozen implemented audit plan、event-time D/X/M 與完整 assignment，再從 STATUS 移除已驗收的 deep-plan-model-behavior。本 repo 為唯一 locked root，其他 paused items 未改，post-completion 無 active contract 指向 retiring codex:deep-plan-model-behavior；本工作線結案，shipping endpoint 仍 pending。
  - 日期來源:direct
  - 驗收:本機完整 suite exit=0、1564/0，validator／repair-context／native trace 與實態驗收見 M-20261003-deep-plan-model-audit；completion candidate 仍須 parent authority／doc audit、乾淨 clone 與 required checks 通過後才可 merge
  - 放棄:首次提交就抹掉唯一 assignment；以 no-active-items 取代 completion parent provenance；endpoint 前宣稱 merged
  - 重議:completion gate、clean clone、required checks 或 merge 受阻時保留 pending 事實，依同批 shipping contract 處理
  - 關聯:4efb0542e431904e505d3d19bbb19e7dae62e92d;M-20261003-deep-plan-model-audit;D-20261003-deep-plan-retain-core;X-20261003-deep-plan-checklist-ablation;docs/plans/2026-10-03-deep-plan-model-behavior.md

- **M-20261003-deep-plan-compat-completion · 2026-10-03 Deep-plan runner 相容性修復後重建結案 candidate**：同一 --merge 批次在首次 clean-clone setup TypeError 後，以 f5f0c1f25adce3fa5c6b89b835fddf978cfab7b1 修正新 runner 的 tarfile filter keyword 能力判定並保留原 assignment，再次移除本工作項。Python 3.9.6／3.14.8 各完整建立十四 packets、核對 linked entry／oracle exclusion／exact §4 ablation／model subset，並拒絕 existing root、session restart、source drift；native dispatch 禁止哨兵確認沒有額外呼叫模型，原 failure evidence 轉綠。原始模型評估與 frozen plan 不改；唯一 locked repo 的 post-completion 沒有 active reference 指向此 retiring actor，paused items 原樣保留。Endpoint 尚 pending，仍需修復後 clean clone／required checks／parent authority 通過後 merge。
  - 日期來源:direct
  - 驗收:兩 interpreter automatic setup／negative guards exit=0；首次 candidate clone suite exit=0；doc-governance audit --ship／staged whitespace 通過；修復後 clone 與 required checks 待本次 shipping gate，不預填成功
  - 證據:/tmp/deep-plan-ship-smoke-20261003.py;tests/deep-plan-model-eval.py;D-20261003-deep-plan-runner-python-compat
  - 放棄:跳過 setup failure 直接送出；改寫既有 audit plan／commits／history；用 no-active-items 洗掉 completion parent authority
  - 重議:修復後 clean clone／checks／merge 受阻時依同批 contract 處理，保留 pending 事實
  - 關聯:f5f0c1f25adce3fa5c6b89b835fddf978cfab7b1;M-20261003-deep-plan-completion-candidate;D-20261003-deep-plan-runner-python-compat;M-20261003-deep-plan-model-audit

- **M-20261003-deep-plan-state-routing-local · 2026-10-03 Deep-plan 狀態控制本機交付**：shared review-state helper、兩薄入口、Codex ticket admission、portable repair packet 與 opt-in native corpus 完成。20 個 routing tests 守上限、有效基線、原始 result IDs／shape、pressure 投影、漂移與新批次轉移；multi-repo 排序及 restart 基線兩個新缺陷都先重現再修正。未改普通風險 route、reviewer N／模型或正式預設。
  - 日期來源:direct
  - 驗收:20 routing＋2 repair-context tests、兩端 quick_validate 通過；完整 ./tests/run.sh exit 0，PASS=1565 FAIL=0，log `/tmp/deep-plan-routing-suite-final-20261003.log`；doc-governance audit --ship 通過。Native 14 原 arm 加 2 個僅修 transport 缺陷的補驗，12 個原生 child；cap 雙端零派遣、target repos 含 Git metadata 不變
  - 證據:docs/plans/2026-10-03-deep-plan-state-routing.md;tests/deep-plan-routing.py;tests/deep-plan-model-eval.py;`/tmp/deep-plan-routing-native-20261003-evidence`;`/tmp/deep-plan-routing-native-order-fix-20261003`
  - 限制:Native 內容與來源暴露不是全綠，見 adoption decision；保留兩輪與盲審預設，不以合成第三輪推導自然收斂率，既有 review residual backlog 未結案
  - 範圍:本機 branch=feat/deep-plan-state-routing；未 commit／push／merge／部署。無 commit endpoint 授權，依 project workflow 保留 active assignment 與完成證據，避免後續 completion parent 失去 provenance
  - 關聯:D-20261003-deep-plan-controller-adoption;D-20261003-deep-plan-state-routing-direction

- **M-20261003-deep-plan-routing-completion · 2026-10-03 Deep-plan 狀態控制工作線結案 candidate**：依本次 `$project --merge` 授權，先以 49ac6061e36299187b2773abd9040355e4f9424b 提交實作、測試、implemented plan 與完整 assignment，再從 STATUS 移除已驗收的 deep-plan-state-routing。唯一 locked root 為 dotfiles，post-completion 沒有 active contract 指向 retiring codex:deep-plan-state-routing，其他 paused items 不變；本工作項結案，PR／merge endpoint 仍 pending。
  - 日期來源:direct
  - 驗收:本機完整 suite exit 0、1565/0；20 routing＋2 transport tests、雙 validators、native 實態及限制見 M-20261003-deep-plan-state-routing-local。Candidate 仍須 parent authority、doc audit、乾淨 clone 與 required checks 通過後才可 merge
  - 放棄:同一 commit 抹掉唯一 assignment；以 no-active-items 洗掉 completion parent provenance；未取得 remote-visible evidence 就宣稱已 merge
  - 重議:completion gate、clean clone、required checks 或 merge 受阻時，保留 pending 事實並依本批 shipping contract 處理
  - 關聯:49ac6061e36299187b2773abd9040355e4f9424b;M-20261003-deep-plan-state-routing-local;D-20261003-deep-plan-controller-adoption;docs/plans/2026-10-03-deep-plan-state-routing.md

- **M-20261003-deep-plan-ci-repair-candidate · 2026-10-03 PR #258 的 manifest 修復候選，endpoint pending**：`84dd13e6fa165ecf34792c2c483b04f705cb133c` 將 integration assertion manifest 更新為 1155，並保留同一工作線的 active assignment。原始 CI summaries 重播已由 mismatch／exit 1 轉為 aggregate 1565／0、exit 0；首輪兩平台 failure 保留為失敗證據。單 repo post-completion view 無其他 active item 指向本 actor，paused gaps 原樣保留；此候選移除修復完成的 active item，以修復 parent 重驗 completion authority。修復與配套結案共兩顆追加 commit，不重寫歷史，frozen plan 不變；新 clean-clone parallel suite 及新 HEAD required CI 仍待驗證，尚未 merge。
  - 日期來源:direct
  - 放棄:放寬聚合器；以 serial suite 代替平行聚合驗證；把舊 HEAD 結果套在新 HEAD；以候選完成冒充 endpoint
  - 重議:parallel suite、authority 或 required CI 未通過時，保留 failure 並依本批額度處理
  - 關聯:84dd13e6fa165ecf34792c2c483b04f705cb133c;X-20261003-deep-plan-ci-shard-manifest;PR#258;tests/shard-manifest.tsv

- **M-20261003-review-repair-controller-completion-candidate · 2026-10-03 Code-review controller 工作線結案 candidate**：依本次 `$project --merge` 授權，先以 8844744dbf6eddb5175db6b7eb8134a6b8b17bb2 提交 controller、雙入口、測試、implemented plan 與完整 assignment，再移除 STATUS 的 review-repair-controller。本 repo 為唯一 locked root，post-completion 無 active contract 指向 retiring codex:review-repair-controller，paused items 不變；本機實作交付，PR／merge endpoint 仍 pending。
  - 日期來源:direct
  - 驗收:沿用相同程式內容的完整 parallel suite exit 0、1566 PASS／0 FAIL（含 18 項 controller 行為測試）及雙入口 quick_validate。34 次 native parent captures 的程式產物、cap／readonly／ownership 結果與原始 RED 均保留；結案文件另驗 doc audit，candidate 仍須 parent authority 與 required CI 通過後才可 merge，不因 Log 再跑相同本機 suite／native 矩陣
  - 限制:共同預設保留 blind／三次修復，focused opt-in；Sonnet packet 改寫／path 傳遞、Sonnet／Opus 摘要替代原報告、Codex encrypted task body 限制未解，已補入既有 B-20260924-workflow-review-residuals，不宣稱完整 isolation／receipt 品質或該 backlog 結案
  - 放棄:同一 commit 抹掉唯一 assignment；以 no-active-items 取代 completion parent provenance；為 shipping 重跑無變更測試或追加 prose review；未取得 remote-visible evidence 就宣稱已 merge
  - 重議:completion／doc／required CI／merge gate 受阻時，保留 pending 事實，依本批 shipping contract 處理具體原因
  - 關聯:8844744dbf6eddb5175db6b7eb8134a6b8b17bb2;D-20261003-review-repair-controller-adoption;D-20261003-review-repair-controller-direction;B-20260924-workflow-review-residuals;docs/plans/2026-10-03-review-repair-controller.md

- **M-20261004-project-test-evidence-reuse · 2026-10-04 Project 測試證據沿用工作線結案 candidate**：實作及 assignment 已在 a6ce6413de492951281ed9486273cced4c575c2c；共同 Log 使用唯讀 helper 比對成功結果與已聲明輸入，資料相同即沿用，失效才補受影響檢查，不建立永久快取。本 repo 為唯一 locked root，移除已完成 item 後無其他 active contract 指向 codex:project-test-evidence-reuse；PR／merge endpoint 在本筆寫入時仍 pending。
  - 日期來源:direct
  - 驗收:13 個 Git／filesystem checks 在 Python 3.14／3.9 通過，最後完整 parallel suite exit 0、1567／0；雙端六個 native cases 的額外測試數均為 unchanged=0、changed=1、unknown=1。此次 Log 核對原始工具結果、run log 與原內容 hashes，helper 回 REUSE；沒有重跑本機 suite／native 矩陣。結案文檔另跑 doc／xref audit，required CI 仍待目前 PR HEAD 驗證
  - 邊界:結果真實性、完整相依範圍與未記錄環境仍需核對；保留條件式 clean clone 與 required CI。Skill 載入量只做盤點，未將長度推定為失誤根因或全面重寫 skills
  - 放棄:因進入 merge 階段重測同一內容；以摘要冒充實際執行；同顆 commit 抹掉唯一 assignment；未達 remote endpoint 先宣稱已送出
  - 重議:completion／doc／required CI 或 merge gate 受阻時，保留 pending 事實並依本批 shipping contract 處理
  - 關聯:a6ce6413de492951281ed9486273cced4c575c2c;D-20261004-project-reuse-mechanical-adoption;D-20261004-project-reuse-mechanical-check;shared/skills/project/references/pressure-tests.md

- **M-20261004-project-routing-candidate · 2026-10-04 Project 分階段載入工作線結案候選**：實作與 evidence 已提交於功能分支 `fb6ba7ec837f9d57d4841b8bf790574848831bfd`，parent 保留 `codex:project-reference-routing` 的 active assignment。依當次 authority PASS 將唯一已驗收工作項移出 STATUS，完整單 repo post-completion view 無其他 active item 指向此 actor。雙端 noop 15→3 reader calls、约少 87% bytes；測試沿用、截斷修正版、Transfer 壓力、本機 provider 的 PR 終點／CI 查詢失敗停止，以及修復 fixture 後的獨立 authority gate 均有原始證據。沿用原 suite 中通過的 integration 1157／0、ship_state 239／0 與 core 其他 cases；文件相關 RED 的兩個定向補驗通過，不把原 full-run exit 1 改寫成全套 exit 0。既有七個 offline checks、validator 與 native 結果保持適用；本輪僅為結案文件補 doc／xref 檢查。此筆是結案候選，PR、required CI 與 merge 尚待本次 --merge 流程取得遠端證據。
  - 日期來源:direct
  - 放棄:因進入 Log 重跑輸入未變的 suite／native eval；在同一 commit 建立又移除唯一 durable assignment；把本機結案當作已合併
  - 重議:當批 completion authority、文件稽核或 required CI 未通過時，處理具體失敗再續行；新的行為缺口依既有 decision 條件評估
  - 關聯:project-reference-routing;D-20261004-project-stage-routing;docs/plans/2026-10-04-project-reference-routing.md;STATUS.md

- **M-20261005-root-cause-first-codex-baseline · 2026-10-05 Root-cause-first 原版 Codex 六案通過，Claude 驗收受認證阻塞**：完成 portable preflight，保留雙 thin entries、單一 neutral workflow 與既有 compatibility pointers。凍結 `0cf91a495855b255f44936af39bbb9316458b35f` 後，Codex CLI 0.160.0／gpt-6.1-sol／high 六個 fresh cases 的正常修復、兩次失敗後接續唯讀診斷、證據不足、containment、不可重播 trace 與 negative 邊界通過；34 次 fixture shell calls 的 raw=sent、source hashes、Git control 與獨立 probe 已核對。未重現需要修改正式 core 的 RED。Claude Code 2.1.289 六個 native launches 均因 OAuth expired／refresh failed 在模型執行前終止，零 input/output tokens；全部記 INVALID_NATIVE，不能外推為 skill failure 或新版雙端通過。Runner 後續 batch 在同模型首次 native failure 後停止剩餘 cases。兩入口 validators 與 offline fixture／admission checks 通過，完整 suite 尚待本輪收尾；active assignment 保留，未 commit／push／部署。
  - 日期來源:direct
  - 放棄:以舊 Claude PASS 或本輪單端 PASS 冒充雙端新版驗收；把 authentication failure 當 skill RED；在沒有新行為失敗時擴寫正式指令；自動修改 credentials 或改換認證來源
  - 重議:使用者恢復 Claude 登入後，以同一 frozen oracle 新建 Claude packet；只補未取得的 Sonnet 六案及 Opus 代表案，不重跑已完成 Codex cases
  - 關聯:D-20260825-portable-root-cause-first;M-20260825-portable-root-cause-first;docs/plans/2026-10-05-root-cause-first-model-behavior.md;shared/skills/root-cause-first/evals.md;tests/root-cause-first-model-eval.py
  - 同輪後續驗收:完整 `./tests/run.sh` exit 0，1567 PASS／0 FAIL，258 秒；`/tmp/root-cause-first-suite-20261005.log`。Doc audit／whitespace 通過；Python 3.9 setup 與原始 runner hash、拒絕 source drift／重複 packet／existing root 也通過。不改 Claude authentication blocker 或雙端未完成的結論。

- **M-20261005-root-cause-first-claude-baseline · 2026-10-05 Claude 互動終端補驗完成，保留 Sonnet 行為缺口**：使用者終端 fresh auth exit 0／claude.ai、Keychain flags=7，成功取得 Sonnet 5.5 六案與 Opus 5.5 三案。這是 daemon flags=2／auth unavailable 的正向環境控制，確認使用者原本已登入；未修改 credentials、Keychain 或 daemon。兩端三份 repair 的原始 failure 與獨立 controls 通過；containment 沒有越權或冒充根治，diagnose-only 全部零 mutation。但 Sonnet insufficient 把 aggregate 差額外推為五筆事件、trace-only 無證據斷言舊版無事故，兩次失敗門檻亦有解讀偏差，不能宣稱全批行為綠。保留三案原始輸出，以 frozen candidate 精簡重寫現有 evidence 範圍與 terminal-state 條件；正式 core 尚未變更，候選需雙端驗證後才決定採用。
  - 日期來源:direct
  - 證據:`/tmp/root-cause-first-terminal-20261005-113420` 的 manifest、raw native JSONL、before／after、audit；CLI 2.1.289，resolved models 為 claude-sonnet-5-5／claude-opus-5-5，high；source／runner hashes、全部 Git control、raw=sent 與 mutation scope 已核對
  - 邊界:模型自己的部分測試命令接 pipeline 而遮蔽 exit；外部 audit 以直接 subprocess 核對，仍紅的 resolver probe 如實保留。不把 Sonnet 正確主結論等同每句 evidence claim 正確；單次候選比較也不證明所有規則均有邊際價值
  - 放棄:因使用者登入可用就重試 daemon；把 native terminal success 當品質全綠；不記錄模型的證據外推；以未驗候選替換正式 skill
  - 重議:候選是否消除具體偏差且不使正常修復／唯讀診斷 false STOP；若不改善，保留失敗、回到具體原因，不重跑同一 packet 洗綠
  - 關聯:X-20261005-claude-daemon-auth-classification;M-20261005-root-cause-first-codex-baseline;docs/plans/2026-10-05-root-cause-first-model-behavior.md

- **M-20261005-root-cause-first-candidate-codex · 2026-10-05 Evidence／terminal-state 候選完成 Codex 定向驗證**：只在 frozen workflow 重寫兩條已觀察缺口對應的 bullet，兩入口／metadata／shared linkage 不變；Codex 六案通過，修復五個 tests 與獨立 probe 綠，四個唯讀案例全樹不變，containment 僅新增隔離測試且明報 BLOCKED／7 個 failures，沒有假報根治。27 次 fixture shell calls raw=sent，source hashes、artifact snapshot、Git control 與所有 commands 已核對。新增 setup-only workflow override 同時保存 base／candidate hashes 與精確 diff；admission controls、雙入口 validator 與新版 runner 的完整 suite exit 0、1567／0（234 秒）通過。正式 core 未套用；Sonnet 候選尚待使用者可用終端執行，不能以 Codex 或原版 Opus 綠替代。
  - 日期來源:direct
  - 證據:`/tmp/root-cause-first-candidate-codex-20261005`；`/tmp/root-cause-first-candidate-suite-20261005.log`；candidate SHA-256 ca7078c0b71892bf8b2c4604820079ec5ba9e6d83c20c5320a6db06fa37ed12b；runner SHA-256 3e405732191f1af85cab66d83e8364a325eee26dd1e6630fe276d2a98c77e01c
  - 下一步:`python3 -B /tmp/root-cause-first-claude-candidate-20261005.py`，只補 Sonnet 六案；driver 固定 hashes、先驗 fresh auth，daemon fail-closed 已驗且零模型執行，未改 credentials／Keychain／daemon
  - 邊界:compound shell commands 仍可能遮蔽模型內部測試 exit；audit 用直接 subprocess 重驗並保留真正紅燈。本批是定向候選比較，沒有聲稱全面 ablation 或模型輸出永遠可靠
  - 關聯:M-20261005-root-cause-first-claude-baseline;docs/plans/2026-10-05-root-cause-first-model-behavior.md

- **M-20261005-root-cause-first-v2-codex · 2026-10-05 第二候選 Codex 四案通過，Claude floor 尚待補驗**：針對第一候選未消除的 aggregate／containment 外推，只重寫同一 evidence bullet；保持 terminal-state 候選、原始 query／fixture／oracle。Codex repair 的六 tests 與獨立 probe 綠；continue、insufficient、trace-only 全樹唯讀，分別保持接續診斷、量測定義未知與只確認算術機制。31 次 shell calls raw=sent，全部 Git control 不變；兩入口 validator 通過。Runner hash 未變，沿用完整 suite 1567／0，未重跑無變化的全套。正式 core 保持原版，Sonnet v2 四案未執行。
  - 日期來源:direct
  - 證據:`/tmp/root-cause-first-candidate-v2-codex-20261005`；candidate SHA-256 c3a27a1d845a54fa103593069acc89e3f72d007c124df72e1bc41ea67bf5b4f8；可用終端的固定 hash driver 為 `/tmp/root-cause-first-claude-candidate-v2-20261005.py`
  - 邊界:沒有測試 daemon restart／no-daemon 是否解決本機 Keychain 差異；官方 CLI 有該選項不代表實測成功。候選也不能在 Sonnet 未驗時宣稱雙端完成
  - 關聯:X-20261005-root-cause-first-quantity-candidate;docs/plans/2026-10-05-root-cause-first-model-behavior.md

- **M-20261005-root-cause-first-captures-complete · 2026-10-05 原版及兩候選預定 capture 完成，品質 gate 仍有 RED**：使用者終端完成 v2 Sonnet 最後四案；原版 Codex／Sonnet 各六案、Opus 三案，v1 雙端各六案，v2 雙端各四案，共 35 個有效 native captures。另保留原先八個 authentication-stage INVALID_NATIVE，不混入行為評分。兩候選未消除 Sonnet insufficient 的 evidence 外推，均不採用，正式雙入口／shared core 保持原版；不宣稱雙端品質全綠。Runner、凍結 oracle 與原始結果已具備，最新完整 suite exit 0、1567／0 的輸入保持適用，文件另做 audit；未 commit／push／部署。
  - 日期來源:direct
  - 邊界:沒有全面 prose ablation、完整 plugin catalog implicit trigger 或任何 production runtime 修復；daemon Keychain 與會話 ownership 的既有觀察不外推為已修好
  - 下一步:待決定將本輪 review 留在已知缺口，或先做能區分失敗機制的新控制；不再堆第三次 wording patch，詳見 B-20261005-root-cause-first-sonnet-evidence
  - 關聯:X-20261005-root-cause-first-v2-evidence;docs/plans/2026-10-05-root-cause-first-model-behavior.md;tests/root-cause-first-model-eval.py

- **M-20261005-root-cause-first-opus-v2-adopted · 2026-10-05 Opus target 補驗使 v2 取得正式採用證據**：daemon restart 後 Claude OAuth 在同一 Codex execution context 可實際呼叫模型；以 baseline `0cf91a4`、原 runner 與 frozen oracle 補 `opus[1m]` 原版 insufficient／trace-only／negative。三案均解析為 `claude-opus-5-5[1m]`、high／Standard；後兩案通過，insufficient 重現將未明 aggregate 42−37 說成缺五筆的核心 RED。既有 frozen v2 讓同案先確認 count／sum 與來源條件，拒絕 +24h、零 mutation，並保持 repair／continue／trace-only 三個 controls 通過；repair 原三 tests 及獨立 probe 全綠。連同既有 Codex v2 四案，正式 shared workflow 採用 exact v2 兩個 hunks，SHA-256 `c3a27a1d845a54fa103593069acc89e3f72d007c124df72e1bc41ea67bf5b4f8`。兩入口 validator、完整 suite 1567／0（exit 0，243 秒）及文件 audit 通過；Sonnet insufficient 仍保留 backlog，未改判。本地候選完成，commit／PR／merge endpoint 待 Project 流程處理。
  - 日期來源:direct
  - 證據:`/tmp/root-cause-first-opus-completion-20261005`；`/tmp/root-cause-first-opus-v2-insufficient-20261005`；`/tmp/root-cause-first-opus-v2-controls-20261005`；`/tmp/root-cause-first-opus-adoption-suite-20261005.log`;docs/plans/2026-10-05-root-cause-first-model-behavior.md
  - 邊界:一次 target RED→GREEN 不證明模型永不外推；Sonnet robustness 尚紅；未全面重跑不受兩個 hunks影響的 containment／negative 候選案，也不以原生 exit 0 代替 raw final、Git 實態與 independent probe
  - 放棄:因 Sonnet probe 紅便否定明選 Opus target；以原版 Opus 三個代表案冒充完整 target；第三次堆措辭；重跑相同 packet 洗綠
  - 重議:Opus target 在相同 oracle 再現量測語意外推或 false STOP；Codex 對應案回歸；正式支援範圍新增 Sonnet；或 shared wording 對正常修復／containment 造成新行為成本
  - 關聯:D-20261005-claude-target-model-roles;X-20261005-root-cause-first-v2-evidence;B-20261005-root-cause-first-sonnet-evidence;shared/skills/root-cause-first/references/workflow.md

- **M-20261005-root-cause-first-workline-complete · 2026-10-05 Root-cause-first 本地評估結案，保留 Opus／Codex 驗收與 Sonnet 缺口**：Opus target 與 Codex 的 frozen v2 insufficient／repair／continue／trace-only 驗收支援兩個 shared workflow hunks 採用；正式驗收模型角色決策、native runner 與凍結 implemented plan 保留。Guided recovery 已把 active assignment 存於 `d85812b`，11 個非 STATUS 交付檔在新增 recovery 紀錄前與原 candidate byte-identical；同 steward 移除 completed active item。Fresh full suite exit 0、1567 PASS／0 FAIL、229 秒，349 個 inputs 前後快照一致；後續純結案文件另驗 doc／xref。Sonnet insufficient RED 仍保留於 backlog，未改判；PR／required CI／merge endpoint pending，本地結案不代表已送出。
  - 日期來源:direct
  - 證據:`/tmp/root-cause-first-project-suite-20261005.log`；`/tmp/root-cause-first-project-suite-evidence-20261005.json`；同一 environment 的 test-evidence helper REUSE；D-20261005-claude-target-model-roles；M-20261005-root-cause-first-opus-v2-adopted
  - 放棄:把歷史 Sonnet RED 改寫為 PASS；為純結案文件重跑既有模型 captures；將本地 candidate 完成當作 PR／merge 完成；將 active contract 在同一 commit 建立又刪除
  - 重議:completion candidate authority、doc audit 或本 PR required checks 未過時處理具體 blocker；行為重議依正式模型決策及既有 backlog
  - 關聯:root-cause-first-model-behavior;X-20261005-root-cause-first-completion-provenance;B-20261005-root-cause-first-sonnet-evidence;docs/plans/2026-10-05-root-cause-first-model-behavior.md

- **M-20261005-project-canonical-push-local · 2026-10-05 Project 首次 push 指令完成雙平台本機驗收**：保留舊版 normal 的雙端首次 opaque deny RED 後，將實際 push 的 repo 綁定移到工具工作目錄、argv 改為 standalone `git push`；bootstrap helper 分別輸出 workdir 與 command。正式雙薄入口、outward hook／rules、送出授權、bootstrap 與 expected-SHA lease 邊界未放寬。Opus target 與 Codex 的 normal／lease／bootstrap／pending／unauthorized 共 10／10 PASS，完整 reference EOF、first-command／workdir、實際 local bare refs 與 lease 均核對；初次無效 bootstrap fixtures 保留，未混入驗收。4 個組合 regression、雙入口適用 validator、shellcheck 與完整 suite exit 0（1568 PASS／0 FAIL，234 秒）通過，351 個測試輸入快照一致。本機 feature branch `fix/project-canonical-push` 實作完成，active assignment 保留；未 commit／push／PR／merge。
  - 日期來源:direct
  - 證據:`/tmp/project-canonical-push-red-20261005`；`/tmp/project-canonical-push-green-20261005`；`/tmp/project-canonical-push-bootstrap-20261005`；`/tmp/project-canonical-push-acceptance-20261005.json`；`/tmp/project-canonical-push-suite-20261005.log`；`/tmp/project-canonical-push-suite-20261005.evidence.json`；shared/skills/project/references/pressure-tests.md「Scenario 40 — Push 首次指令與 outward gate 相容」
  - 邊界:驗收為 Step 5 指令生成／Git／gate composition，pending 是 transport 模擬，非 native approval UI 或 live GitHub E2E；full suite 後僅驗收紀錄與 STATUS 追加，另驗 doc／xref，不冒充新文件已包含於原快照
  - 放棄:放寬 hook 接受 opaque command；以終端成功掩蓋首次拒絕；重跑同 packet 洗綠；用缺 metadata 的 bootstrap fixture 判 skill 回歸；以 Codex-only validator 改掉 Claude 原生 frontmatter
  - 重議:正式 target 再現首次 opaque push、repo 綁定錯誤、lease SHA 漂移或 pending 重試；工具不能可靠提供 target cwd；或正式 support／shipping scope 改變
  - 關聯:D-20261005-project-canonical-push;X-20261005-project-opaque-push;X-20261005-project-bootstrap-fixture;D-20261005-claude-target-model-roles

- **M-20261005-project-canonical-push-workline-complete · 2026-10-05 Project canonical push 工作線完成本地結案準備**：實作 commit `357dc49` 已保存 exact active assignment；同 steward `codex:project-canonical-push` 驗證整個 locked repo set 只有本 work item，post-completion 無 dead stewardship reference，再移除 completed item。上游 log-prepare 的三個衝突範例現只指向 single command authority；原 focused 五案雙端 10／10 與上游 normal／lease 四個有效 captures 支援本批採用，所有 reader FAIL／capacity error／bootstrap-invalid 原 packet 保留。5 個機械 regression／oracle controls 通過，最新 full suite exit 0、1568 PASS／0 FAIL、243 秒，351 inputs 前後一致，helper 同 environment REUSE；後續純結案文件另驗 doc／xref。PR／required CI／merge endpoint pending，尚未 push。
  - 日期來源:direct
  - 證據:`/tmp/project-canonical-push-upstream-acceptance-20261005.json`；`/tmp/project-canonical-push-final-suite-20261005.log`；`/tmp/project-canonical-push-final-suite-20261005.evidence.json`；shared/skills/project/references/pressure-tests.md「Scenario 40 — Push 首次指令與 outward gate 相容」
  - 放棄:同一 commit 建立又移除唯一 assignment；把未達成的 endpoint 記成已送出；放寬 hook／rules；只以 model terminal success 判驗收；以不同 ref 拼法否定正確 anchored lease
  - 重議:completion candidate authority、doc audit 或 required CI 未過；正式 target 再現 first-command／repo binding／lease／pending 回歸時以新 raw evidence 處理
  - 關聯:project-canonical-push;357dc49;D-20261005-project-canonical-push;M-20261005-project-canonical-push-local;X-20261005-project-push-upstream-coverage
