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

- **M-20261005-deep-plan-document-repair-local · 2026-10-05 Deep-plan 文件修正與 checkpoint 本機驗收**：#264 的 canonical plan／明列 SPEC、STATUS 修正可在同批或明示 focused restart 後，以 unstaged／staged／committed 狀態續審；controller 保存 worktree／index／HEAD 實際差異，public launcher 能傳遞 focused packet 與不含原 finding 的 blind delta。未宣告文件、程式、其他 repo、alias／symlink／mode／checkpoint ancestry、處置與 cap 防護維持；逐 commit 核對也拒絕程式修改再 revert。舊 v1 journal 只有整份原 snapshot hash 可證明時才附加文件基線，原 rounds／results／票證／計數不改。
  - 日期來源:direct
  - 驗收:舊 source staged plan RED 保留於 `/tmp/issue-264-red-xubq8191.log`；追加 v1 由新 controller 完成一輪後留下空基線欄位的案例，先重現 import 被遮住，再修正取值分支。最後 36 routing＋2 repair-context、雙入口 quick_validate 通過；最後 `./tests/run.sh` exit 0、1568 PASS／0 FAIL、280 秒，log `/tmp/issue-264-final-suite-h2ynrs84.log`。後續只追加驗收紀錄與 STATUS，另驗 doc audit／xref，不宣稱它們在原 suite 快照內
  - Native:固定同一 query／fixture，Codex gpt-6.1-sol／xhigh／default（CLI 0.160.0）與 Claude opus[1m]→claude-opus-5-5[1m]／high（CLI 2.1.289）的正向與程式漂移拒絕共 4／4；追加空基線修復後，同兩 target 的 v1 接續 2／2。正常只保留下一份 reserved ticket，拒絕不消耗額度；所有 target repo／Git metadata、原 results／batch／policy／count 均保持，未 dispatch reviewer。兩份 source copy 的 hashes／raw traces／outcomes 分別保留於 `/tmp/issue-264-forward.ku4sKh`、`/tmp/issue-264-forward-v1.EKef26`，禁讀 eval／原 checkout 的工具命中均零
  - 限制:Native 是 synthetic prior results 的 controller preparation／證據傳遞驗證，不是真實 review 歷史、finding 品質或 GO 判定；未改正式 blind／兩輪 defaults。相依集合固定於初始宣告，v1 原 dirty 文件內容／index 不能精確重建時 fail closed，不猜基線
  - 範圍:branch=fix/deep-plan-document-repair；本機實作與驗收完成，active assignment 保留；未 commit／push／PR／merge／部署
  - 放棄:全 Markdown 排除、reset snapshot、重建 journal、用最終 tree 相同放過程式 checkpoint、以機械 green 外推模型品質
  - 重議:相同允許狀態再被拒絕、未宣告漂移可取 ticket、審查執行期間漂移未使結果失效、或可證明的 v1 基線仍不能無損接續
  - 關聯:#264;deep-plan-document-repair;D-20261005-deep-plan-document-repair-baseline;D-20261003-deep-plan-controller-adoption;tests/deep-plan-routing.py

- **M-20261005-deep-plan-document-repair-completion · 2026-10-05 Deep-plan 文件續審修復實作結案、送出 pending**：#264 的實作、回歸測試與 assignment 已先保存於 `46bb471bae77024f2cbbdc6c4e688308908c6061`；本次結束 `codex:deep-plan-document-repair` 工作線，移除已驗收 active item。完整 locked repo set 只有 dotfiles；post-completion view 沒有其他 active contract 指向此 actor，既有 paused backlog 不變。本紀錄只確認實作結案，使用者本輪 `$project --merge` 的 PR／required CI／merge endpoint 尚待達成。
  - 日期來源:direct
  - 驗收:shipping 前補跑 `./tests/run.sh` exit 0、1568 PASS／0 FAIL；`/tmp/issue-264-ship-pqvdncns` 保存 suite.log、前後一致的完整 input snapshots 與 helper REUSE receipt。v1 雙端 native 的原 source hashes／入口 links／CLI versions 核對一致，精確受測 source inputs 經 test-evidence helper REUSE；此前 36 routing／2 repair-context、雙 validator 與 native 4＋2 的限制沿用本機驗收紀錄。純結案文件另驗 doc／xref
  - 範圍:branch=fix/deep-plan-document-repair；本機 implementation complete、shipping endpoint pending；未部署
  - 放棄:同一 commit 建立又移除唯一 assignment；以當前 snapshot 冒充過去測試；把 native 機械成功外推 reviewer 品質；endpoint 未達成先記已 merge
  - 重議:completion candidate authority、doc audit 或 required CI 失敗；#264 同樣文件 checkpoint 或 drift 拒絕契約再現回歸
  - 關聯:#264;deep-plan-document-repair;46bb471bae77024f2cbbdc6c4e688308908c6061;D-20261005-deep-plan-document-repair-baseline;M-20261005-deep-plan-document-repair-local

- **M-20261005-legacy-terminal-disposition-local · 2026-10-05 #267 legacy review-terminal 有界結案本機驗收完成**：先以隔離跨工具 fixture 證明祖先進 default 後，fresh 唯讀 PASS 仍被同一舊訊號攔截，terminal-clear 無 mutation authority。Shared controller 新增 exact legacy disposition 與 archive 重驗；Project 辨識同一原訊號已明示結案，Log 不再承諾單純重跑可清除。舊歷史／receipt／controller／額度保留；新訊號、stale／partial／historical review、綁定不符或不可驗 archive 維持拒絕，處置不授予新批 review PASS 或 shipping。
  - 日期來源:direct
  - 驗收:controller 23 tests；`./tests/run.sh` exit 0、1568 PASS／0 FAIL、297 秒，log `/var/folders/t5/4b3mtjj52fvdplz5f15mf_ym0000gp/T/issue-267-full-tests-4e1laf_7.log`；shellcheck、diff check、文件治理通過。Codex project／repo-review 與 Claude deep-review 適用 quick_validate 通過；Codex validator 不接受 Claude project 既有原生 frontmatter，未修改正確 adapter metadata。全套後追加本輪驗收文件／STATUS，另驗 doc／xref；terminal fixture 補保存操作前 controller snapshot，另驗 setup，不回填既有 packet 或偽造未捕捉的 suite input receipt
  - Native:Codex gpt-6.1-sol／high／default（CLI 0.160.0）與 Claude claude-opus-5-5[1m]／high／Standard（CLI 2.1.289）的 t-request／t-dispose／t-closed 六個有效 outcomes 通過。原版 `/tmp/issue-267-native-before`、修後 `/tmp/issue-267-native-after`、Codex 權限修正後 fresh `/tmp/issue-267-native-metadata` 保留 source／prompt／trace／actual artifacts。首批 Codex t-dispose 318.9 秒 permission BLOCKED 保留，沒有改判；runner 只開放該 fixture 的 .git/deep-review leaf，fresh 227.1 秒補驗成功。受測五個 shared files 與採用 source byte-identical
  - Forward:blind fresh-context `/tmp/issue-267-forward` 完成，parent 核對只新增指定 archive／anchor pointer／journal event；HEAD／index／branch／origin refs、原 PASS／findings／history／receipt／attempts／repairs 保留。未重跑 review 或作外向操作
  - 限制:controller PASS 為 supplied replay evidence；native 驗 disposition／authorization 接線，不冒充完整 review、finding 品質、live consumer 或 GitHub shipping E2E。沒有全面 prose ablation；pure final evidence 不重跑有效 captures
  - 範圍:branch=fix/issue-267-legacy-review-terminal；本機 implementation complete，active assignment 保留；未 commit／push／PR／merge／部署，未改 live consumer metadata
  - 放棄:刪整份 marker／重設 budget；以舊照送或普通 merge 自動結案；以無關 autofix 取得清除權；將 CLI exit 0 或 parent 手動操作當 native 成功；移除 sandbox 繞過 denial
  - 重議:合法處置後同一訊號再攔截無關批次、新 marker 可借舊 receipt 放行，或當次結案／shipping 授權被混用
  - 關聯:Issue#267;D-20261005-legacy-terminal-disposition;X-20261005-legacy-disposition-native-sandbox;shared/skills/deep-review/evals.md;shared/skills/project/references/pressure-tests.md;tests/review-repair-controller.py

- **M-20261005-legacy-terminal-disposition-completion · 2026-10-05 #267 實作工作線結案，送出 endpoint pending**：實作與 exact active assignment 已保存於 `ecd6551d76acc37a025ad4bafdefbf41f31ea946`；同 steward 結束 `codex:issue-267-legacy-review-terminal` 工作線、移除 completed active item。完整 locked repo set 只有 dotfiles，post-completion 沒有其他 active contract 指向該 actor，既有 paused backlog 不變。使用者本輪明示 `$project --merge`；本紀錄僅確認實作結案，PR／required CI／merge endpoint 尚未達成。
  - 日期來源:direct
  - 驗收:Log 的 test-evidence helper 對原 suite log 回 NEED_TEST，因缺少當時 input anchor；補跑全套 exit 0、1568 PASS／0 FAIL、303 秒，351 inputs 前後一致、同環境 helper REUSE。證據根 `/var/folders/t5/4b3mtjj52fvdplz5f15mf_ym0000gp/T/issue-267-ship-qgq3h0un` 保存 suite.log、before／after snapshots、environment、execution 與 helper receipts。保留 frozen native runtime 的 48 個 source inputs 核對支持六個有效 replay outcomes REUSE；未重跑模型，首次 sandbox BLOCKED 不改判。全套後只更新 assignment／completion 文件，另驗 doc／xref
  - 限制:沿用 local milestone 的 supplied-PASS replay、validator adapter 與 forward 範圍；不外推完整 native review 或 live consumer 驗收。Scanner 的 unused fixture copy 有 incidental executable-mode 差異，legacy fixture 沒有 adopted config 且原 trace 零 scanner execution，保留 broad comparison 與 runtime scope 判定，不改 source／既有 packet 洗綠
  - 範圍:branch=fix/issue-267-legacy-review-terminal；implementation complete、shipping pending，未部署、未修改 consumer metadata
  - 放棄:同一 commit 建立又移除唯一 assignment；補造原 suite snapshot；為純結案文件重跑有效 native captures；endpoint 未達成先記已 merge；移除或忽略 shipping gates
  - 重議:completion candidate authority、文件治理或當前 PR HEAD required checks 失敗；本批引入且原 scope 內缺陷依同 PR 有界修復接續
  - 關聯:Issue#267;ecd6551;D-20261005-legacy-terminal-disposition;X-20261005-legacy-disposition-native-sandbox;M-20261005-legacy-terminal-disposition-local

- **M-20261006-turbo-native-delivery-local · 2026-10-06 Turbo 雙端完成受控交付及同 PR CI 修復**：fresh native CLI 在當次明列 commit／push／PR／merge 的隔離 fixture 完成合適終點；雙端已有 all-actions 與 seeded CI 修復的實際 local bare ref／provider 結果，required checks 真正檢查 pushed bytes，未 commit／push default branch 或 force。Claude v3 真實 reviewer `aef9ca0c322eaaafe`，先補實際 assistant Ship 摘要再由 native Stop 接續，無真人 continue，merge 到 `fddc44de6b025c6a770c375ff897d8bd1f56f5b3`；Codex v2 同 PR 修 CI 並用兩個真實 reviewer threads，merge 到 `dc6347e91587edb7f09025aa3dc5dffac8de47da`。摘要 guard 的原始 denied calls 保留，未弱化成接受 thinking／tool echo。
  - 日期來源:direct
  - 證據:`/tmp/turbo-delivery-forward/{GUARD-RESULTS.md,V3-RESULT.md,guard-evidence.json}`；Claude callback snapshot `1791218825413439000.jsonl` SHA `c7ce925e30ec0744e5d32962dc6091a9f961715a27f217d2b147a1e0bab2f3ba`
  - 範圍:controlled local gh provider／bare remote 的 native composition，非真實 GitHub E2E；各 frozen source hash 不冒充最終所有 byte 相同。Claude 曾四次 missing-summary deny，後來自動恢復完成，仍有效率限制。Production 本批未 commit／push／deploy。
  - 關聯:turbo-skill;D-20261006-turbo-native-evidence-transitions;X-20261006-turbo-summary-host-blame

- **M-20261006-turbo-skill-local · 2026-10-06 Turbo portable skill 本地實作與限定 native CLI 驗收完成**：新增 shared core、雙端薄入口與既有 deep-plan／deep-review／repo-review／Project 的 opt-in 接點，沒有 fork workflows。當前 session on／off／status、同 Goal 修正續批、當次具名交付及 evidence-backed stopped 出口均有雙端原生證據。Claude H collector 從 actual SubagentStop 保存完整原文；兩個 fresh Agents 的 return／callback／private capture／controller raw_report 逐字相同，56/56 acceptance 與 22 supplementary checks、current-byte receipt／history／原 cap 同時成立。Claude v4 同 PR 修 CI／medium finding，original 4633 bytes 與作者摘要分存，controlled merge 到 `e515f870172b9af97aa915430940a70cd9e37099`；no-local clone 的 63 checks 在 Python 3.11／3.14 全綠。Codex code-cap E 及 seeded CI v2 證據依其 frozen component source 保留，未冒充最終每一 byte 的 E2E。
  - 日期來源:direct
  - 驗收:final G 完整三 shard exit 0、1570 PASS／0 FAIL，含 Turbo 48 tests；integration 1465 秒。雙入口 quick_validate、syntax、ShellCheck、freeze 前 doc／xref audit 與 diff check exit 0。F 的兩個舊通知 gate FAIL 已根因修正，collector 共存與 timestamp／wait4me 誤接負例均綠；原始 model／mechanical RED、missing-summary denials、original reports 及 native IDs 未洗掉
  - 證據:`/tmp/turbo-full-suite-20261006-g.log`、`/tmp/turbo-doc-audit-20261006-before-freeze.log`、`/tmp/turbo-xref-20261006-before-freeze.log`；`/tmp/turbo-h-root-verification-20261006.json`、`/tmp/turbo-v4-root-verification-20261006.json` 與 plan 的各 packet receipt；current helper SHA `969ac730ed18081862683f2e49ef174b4c1c234d55bd23381c41c9bb54d0848d`
  - 範圍:Codex CLI 0.160.0／Claude Code 2.1.289 的限定 native surfaces；交付只驗 controlled local gh provider／bare remote，未操作真實 GitHub。Desktop／IDE／web／app-server／TUI compact 未驗，logless delivery fail closed；Claude queued off 需 interrupt，取消 cache 在 next-input reconciliation 撤銷。V4 五次 missing-summary denial 後由 native Stop 自動恢復，效率限制保留
  - 保存:plan implemented 並凍結；production 尚未 commit／push／install／dotsync，新 Turbo entries 未安裝。既有 Claude settings symlink 已映出 source 修改，未改 global permission；Codex live config 未同步。Active assignment 尚未存在於 candidate parent，保留至明示授權先保存，未宣稱整合／shipping／workline closure
  - 關聯:turbo-skill;D-20261006-turbo-native-report-collection;X-20261006-turbo-author-report-rewrite;X-20261006-turbo-subagent-hook-blanket-check;docs/plans/2026-10-05-turbo-skill.md

- **M-20261006-turbo-public-help · 2026-10-06 Turbo 可發現的說明介面通過双端 native 檢查**：保留使用者接受的額外 `--allow` 授權；新增 shared workflow 的唯讀 help／--help 路由、on／status 的 action set 與 help 提示、README 人用命令表與範例。雙端薄入口同步 help trigger，Codex metadata 的起始 prompt 是 `$turbo help`。原 controller／hook／permission／shipping authority 未改，bare 維持 status；沒有新增內部 helper 命令或重複 quick-reference。
  - 日期來源:direct
  - 驗收:保留 first-help／idle-on 的部分成功與反例，fresh v2 的雙端 help only-read、無 control／bind／review／shipping，所有 on command blocks 經实际 parser 通過；v3 的雙端 actual control output 均 on／idle／goal null／allow 空集合，回覆含 help hint，unknown 未被推定 launch profile。六個初始／v2／v3 fixture 組別的實態與完整 raw logs 保留，首輪錯誤沒有改判
  - 證據:`/tmp/turbo-public-help-{v2,v3}-verification-20261006.json`、`/tmp/turbo-public-help-{v2,v3}-20261006-results.json` 與各 packet 的 frozen hashes／argv／native.jsonl；雙入口 quick_validate exit 0，doc audit／xref v2 exit 0，diff check exit 0。兩端 HEAD 不變／tree clean／frozen source 不變。Help v2 及 idle-on v3 依各自 frozen source，最後 delta 只在 acknowledgement 的 unknown guard，不冒充每個 packet 所有 bytes 相同
  - 範圍:Codex CLI 0.160.0／repo production model，Claude Code 2.1.289／opus[1m]，实际 Claude resolved `claude-opus-5-5[1m]`；native CLI 功能檢查，不宣稱 host UI 已渲染 metadata／flags completion。核心仍以 G 的 1570 PASS 為既有證據，本次未改 scripts、md 節名或搬權威，針對人用介面做 native／validators／doc checks，未以原 suite 冒充新 help 驗收
  - 保存:未 commit／push／install／dotsync，新入口尚未安裝；原 implemented plan 與原始評估 journal 凍結，active assignment 保留至明示授權先保存
  - 關聯:turbo-skill;D-20261006-turbo-public-help;X-20261006-turbo-help-copyable-commands;M-20261006-turbo-skill-local
  - 計數澄清:上述六個組別按三個版本乘兩平台計；初始各兩個 case，v2／v3 各一個 case，實際共八個獨立 fixtures／native invocations，沒有把分組數冒充 case 數

- **M-20261006-turbo-delivery-candidate · 2026-10-06 Turbo 工作線完成並準備交付 candidate**：本批使用者明示 `$project --merge`。Assignment 與原始驗證紀錄已保存於 `62c1f88edfdb77f6ffe8e04552dd1deca1691e58`，實作保存於 `aee046f024ba25a0ea82a4f3bb29cd907cbcbde9`；以原 assignment fingerprint 重驗 `codex:turbo-skill-plan` 的 current-session binding PASS 後移除唯一 completed active item。完整鎖定集合只有 `.dotfiles`，post-completion view 沒有 remaining active item 指向 retiring actor。
  - 日期來源:direct
  - 驗收:本批 `./tests/run-parallel.sh` actual exit 0，1570 PASS／0 FAIL（core 171、ship_state 239、integration 1160，integration 287 秒）；測試前後完整 tracked input 與 symlink target 快照一致，Project test-evidence helper exit 0／REUSE，非補造舊 G 的輸入。原 native component matrices、help v2／idle-on v3 與各原始 RED 均依其已記錄的 frozen source 保留
  - 證據:`/tmp/turbo-project-suite-20261006.log`、`/tmp/turbo-project-suite-{before,after,evidence}-20261006.json`；本次 authority PASS 使用實際 full HEAD 與原 fingerprint
  - 邊界:本紀錄只表示實作、驗收與結案 candidate；PR／required CI／rebase merge endpoint 尚未達成。交付授權只限本批同 repo／同 PR／同目標／同 session，CI 修復提交最多兩次；沒有 bypass、force-push、default branch push、permission 修改或 dotsync 部署。私人 plan-review journal 原位保留且本機排除，不提交／刪除／改判；原 implemented plan 凍結
  - 放棄:同一 commit 建立又移除唯一 assignment；把既有成功 log 的當前 snapshot 冒充過去 inputs；僅以 local suite 綠就跳過當前 PR HEAD required CI；未到 endpoint 就宣稱 shipped
  - 重議:completion candidate authority、doc audit 或當前 PR HEAD required checks 失敗；必要原 scope 內 CI 修復依同批授權接續，不重置額度
  - 關聯:turbo-skill;62c1f88;aee046f;M-20261006-turbo-skill-local;M-20261006-turbo-public-help;docs/plans/2026-10-05-turbo-skill.md

- **M-20261006-runtime-layout-plan-preflight · 2026-10-06 Runtime 收斂計畫、真實集合盤點與差異重現已建立**：依使用者「開工」在 `refactor/runtime-layout-convergence` 撰寫本項唯一 implementation plan；兩份 setup、dotsync 本機／遠端及 brewup 納入共用部署，sysup 因只有 apt 不新增 runtime 階段。隔離執行原 Codex helper／setup link 函式均 exit 0，但 Claude 新 entry 缺失、rules 仍為整 root link、既有 runtime approval bytes 遺失，證實差異不能由 exit 0 判完成。14 目標唯讀盤點全數成功、revision 皆為 `338da91`；正式 handoff store 均不存在，新增雙 store 合併放行格目前為零。legacy-only 為 eagle06（6 檔）、macs（18 檔）、db01（0 檔）、macmini（1 檔）；本機 snapshot 有 runtime processes，不具 offline migration 條件。deep-plan 兩輪各兩位 fresh reviewers、transport／admission 有效；集合證據及跨 active/archive 再啟用風險已補正，第二輪新增的 CI assertion manifest／parallel runner 相依已補入計畫，本批仍 NO-GO、等待明示修後續審。尚未實作、變更 runtime、commit 或散佈。
  - 日期來源:direct
  - 放棄:以同相對路徑無碰撞推定雙 store 無生命週期衝突；只跑 serial suite 即推定平行 CI 可用；未遷移 fleet 就移除 handoff fallback
  - 重議:同範圍修後續審通過後實作；部署前重新盤點 writer／data snapshot，不把此次量測當 quiescence 授權
  - 關聯:STATUS.md;docs/plans/2026-10-06-runtime-layout-convergence.md;D-20260823-portable-handoff-skill;M-20261001-pr249-shard-manifest-synchronized

- **M-20261006-deep-plan-repair-evidence-spec · 2026-10-06 #271 合法文件續審修復規格已建立**：使用者明示 `$project spec #271` 後，由現有 `codex:runtime-layout-convergence` steward 建立獨立 active contract，涵蓋 focused repair、blind restart、合法文件 checkpoint、fresh native reviewers／admission 及反向 controls。Runtime 收斂的新批已依原始使用者選項 restart，prepare 尚未保留 ticket 就因 STATUS delta 的「第一輪／第二輪」被 `no_pressure` 拒絕；與 #271 本文／補充的直接因果一致，沒有新 reviewer 結果。完整續審流程是否還有缺口列為待查證，沒有宣稱已修好或 GO；runtime 計畫／原 journal／findings 保留，待此修復後合法接續。本輪只有規格與必要 active-state 更新，沒有 code／commit／外向動作。
  - 日期來源:direct
  - 放棄:另開重複 issue；只讓某個詞通過就宣告完整流程已修好；刪改 canonical 歷史、換 blind 或重建 journal 迴避拒絕
  - 重議:原 RED、#264 checkpoint、native lifecycle 或反向 controls 仍未通過時維持未完成；新因果證據才調整最小修法
  - 關聯:#271;#264;#268;STATUS.md;D-20261003-deep-plan-controller-adoption;D-20261005-deep-plan-document-repair-baseline;M-20261005-deep-plan-document-repair-local;M-20261006-runtime-layout-plan-preflight

- **M-20261006-deep-plan-repair-evidence-preflight · 2026-10-06 #271 原行為重現與獨立計畫查證完成、續審自我依賴已定位**：現行來源的合法歷史矩陣 12 assertion failures、forged document data 1 failure 均保留；Turbo 前 #268 合併版相同合法矩陣仍 12 failures、0 errors，排除 Turbo 是本拒絕來源。未實作計畫取得兩份 fresh、完整、有效 admission 的查證；canonical 指令未取得命令權限的完成判定有一條可查證 medium 與一條同根因判斷 medium 建議，已補 native 固定 blocker／指令 fixture oracle。修後 prepare 未保留新 ticket：document delta 無壓力命中，卻將原 reviewer finding 引用的「最後一次審查」判為 `review-pressure-in-input`。沒有新 reviewer、GO 或修復程式；原 journal／findings 留存，需明示改採 bootstrap 修復及修後續審順序。
  - 日期來源:direct
  - 放棄:因歷史字詞消失就假稱合法續審；刪改 reviewer 原始 finding 以取得 ticket；重建 journal；把有效 initial reviewer set 當修後 GO
  - 重議:使用者明示 bootstrap／續審順序後再修；原 RED、反向 controls、完整 native lifecycle 或 admission 仍失敗時維持未完成
  - 關聯:#271;deep-plan-repair-evidence;docs/plans/2026-10-06-deep-plan-repair-evidence.md;D-20261006-deep-plan-evidence-control-boundary;M-20261006-deep-plan-repair-evidence-spec

- **M-20261006-deep-plan-bootstrap-native-red · 2026-10-06 使用者授權 bootstrap、最小邊界修復與 native RED 已保留**：使用者選 `1`，授權先在 #271 feature branch 修最小 data／control 邊界、驗證與獨立 code review，再沿原 journal 新批續審；不授權 shipping。合法歴史矩陣及 forged data／caller pressure／原 finding controls 已轉綠；獨立 code review 的 bytecode 自製 source drift 有新 assertion RED，修為不寫 cache 的 source import，保留真正 bytes／link drift 檢查。Native Codex 原生 baseline 與 committed repair／focused admission 有效，未修完的 fixture suite finding 仍正確 NO-GO；新批 canonical GO／降級指令有完整 delta，兩位 fresh reviewers 均保留 wire blocker、揭露實際 exposure。Claude 原生首輪因 reviewer 判斷層 findings 缺 evidence 被 parent／controller 正確拒絕，invalid journal 與原文未改；共同 template 以原四欄 typed JSON contract 承重，再以改版 source／新 fixture 驗證。此時尚無雙端完整 GREEN 或原 #271 修後 GO。
  - 日期來源:direct
  - 放棄:把 code review 後作者修正說成第二份獨立 PASS；補造缺失 reviewer evidence；重派原 invalid ticket；以移動中的 suite 輸入宣稱最終快照全綠
  - 重議:完整 native lifecycle／反向 controls 與最終 repo checks 通過，再以原 journal 做使用者已授權的新批計畫續審；任一相關有效性缺口未修前維持未完成
  - 關聯:#271;deep-plan-repair-evidence;D-20261006-deep-plan-evidence-control-boundary;M-20261006-deep-plan-repair-evidence-preflight

- **M-20261006-deep-plan-bootstrap-verified · 2026-10-06 #271 bootstrap 與雙端完整原生驗證完成**：最小 source-bound data／caller-control 修復保留原 findings、canonical 歷史與所有非文件／checkpoint／ticket guards。41 routing tests、repair-context、双入口 validator 通過；完整 serial／parallel 各 exit 0、1570 PASS／0 FAIL，受測 source snapshot 在執行中取得且至完成無 repo 編輯。改版 source 的 native gpt-6.1-sol／claude-opus-5-5[1m] 共 14 有效 complete sets、28 不同 IDs，實際 blocking baseline 經合法作者修正／文件 checkpoint 到 focused admission 與同 journal 明示新批 blind；新 finding 正常判 NO-GO，不以結果有效冒充 GO。Canonical GO／降級指令反例四位均保留可查證 blocker，source identity 未改。原始資料在 `/tmp/issue-271-native-v2-20261006/`、suite logs／evidence 在 `/tmp/issue-271-final-{serial,parallel}-evidence.json`；固定 oracle 不外推通用抗注入，canonical exposure、Claude control 部分 baseline metadata exposure 及 directive 額外 checkpoint 澄清均保留。獨立 code review 的 bytecode drift 與 consumer suite 缺漏已由作者修復驗證；修後 assess 因 scope drift 拒絕，沒有修後獨立 PASS receipt。下一步執行使用者已授權的原 #271 journal 新批計畫續審，尚無其 gate 或 shipping。
  - 日期來源:direct
  - 放棄:把 native fixture GO 當原 #271 計畫 GO；宣稱 canonical 歷史完全隔離；把執行中 snapshot 說成啟動前 capture；冒稱修後獨立 code-review PASS
  - 重議:原 journal 續審依實際完整 findings 判 gate；新增實質 code 或驗證缺口才擴大測試，suite 後驗收文件更新另經文件 audit
  - 關聯:#271;deep-plan-repair-evidence;M-20261006-deep-plan-bootstrap-native-red;D-20261006-deep-plan-evidence-control-boundary

- **M-20261006-deep-plan-bootstrap-reentry-gate · 2026-10-06 #271 授權原 journal 續審有效、本批 NO-GO 與文件處置已留證**：按使用者選項 `1` 保留原 journal 的舊結果、IDs、baseline、policy／count／cap 後 restart；兩輪各兩位 fresh reviewers、同 prompt、read-only snapshots／artifact hashes 與 admission 均有效。第一輪两位皆有 verifiable medium，同根因為 shared workflow／現行 eval oracle 的隔離宣稱未同步（eval 2/2、workflow 1/2），已補原計畫的剩餘相依工作。第二輪一位新增 STATUS 第 3 項驗收同類 medium、另一位無 findings，依法為 NO-GO；已核對并修正 STATUS 與原計畫的資料／控制措辭，原分類／結果未改。兩份 skill 文件維持未改，不能將計畫處置當成修後實作驗收；本批額度已滿，Turbo 未啟用，未再派 reviewer。原始 manifest／處置為 `/tmp/issue-271-plan-reentry-review-{1,2}.json` 與 `/tmp/issue-271-plan-reentry-dispositions-1.json`；下一批建議同範圍 focused，需新的使用者明示授權，不用舊 `1` 再授權一批。
  - 日期來源:direct
  - 放棄:因已有測試全綠而忽略新的活契約矛盾；按較有利 reviewer verdict 判 GO；同批 stealth 修改 protected skill 檔；自動續批或重設 journal
  - 重議:同 Goal 文件處置取得新授權後沿原 journal 查證；GO 後同步剩餘 workflow／eval oracle 與必要驗證
  - 關聯:#271;deep-plan-repair-evidence;M-20261006-deep-plan-bootstrap-verified;D-20261006-deep-plan-evidence-control-boundary

- **M-20261006-deep-plan-focused-go · 2026-10-06 #271 明示新批續審 GO、剩餘契約同步已實作**：使用者再次選 `1` 明示同 Goal focused 續審，原 journal 保留前兩批、原 IDs／結果／policy／cap，新批 policy focused、N=2、最多兩輪。Focused 修後查證無 findings，無新修正時依 controller 用獨立查證完成第二輪；四份 fresh typed results／transport／admission 均有效、零 findings，gate GO。原始結果為 `/tmp/issue-271-focused-review-{1,2}.json`，授權原文記錄為 `/tmp/issue-271-focused-authorization-20261006.json`；不把 reviewer 建議當授權。隨後同步 workflow 及現行 eval oracle 的過度隔離宣稱，限定不額外投影 reviewer results／controller 壓力，保留 canonical 歷史及 exposure 邊界。Code／reviewer prompt 未變；bootstrap native 證據仍綁原 source，不外推最終文件 identity，正進行最後文件與 repo 驗證。
  - 日期來源:direct
  - 放棄:無 finding 時偽造 repair packet；把新批 policy 寫成正式預設已改；重寫前批 NO-GO；以計畫 GO 冒充最終驗收或 shipping 授權
  - 重議:最終 diff 改變 runtime 行為／判準時須新 oracle 與必要雙端 forward；純隔離宣稱修正以 source／prompt hashes、回歸與文件 audit 驗收
  - 關聯:#271;deep-plan-repair-evidence;M-20261006-deep-plan-bootstrap-reentry-gate;D-20261006-deep-plan-evidence-control-boundary

- **M-20261006-deep-plan-repair-local-completion · 2026-10-06 #271 本地修復、計畫續審與最終驗收完成**：合法 canonical 歷史／原 finding 保留，caller 控制與來源核對分離，非法漂移、checkpoint／ticket／typed results／cap guards 保持。原 journal 的明示 focused 新批兩輪／四位 fresh reviewers 無 findings、gate GO；其後完成 workflow／現行 eval oracle 的隔離宣稱同步，未改 code／reviewer prompts 或正式 defaults。最終 serial／parallel 各 terminal exit 0、1570 PASS／0 FAIL；373 輸入於啟動前凍結，完成後完全一致，兩端 validator、文件／xref 與 diff 檢查通過。完整 logs／fingerprints：`/tmp/issue-271-contract-sync-{serial,parallel}-evidence.json`，snapshot SHA `b281d296216a7b2a75ba2ee1cf31949d064d643498b6be3eaa1ad619b1823482`。Native bootstrap 的 14 sets／28 IDs 與限制保持，最終 frozen-source 比對僅 workflow 說明不同，code／reviewer prompt／entries／schemas bytes 相同；eval oracle 未向 native 受測者提供。此後的 STATUS／計畫／milestone 結案文字另經文件 audit，不以全套 REUSE 掩蓋文件差異。計畫 implemented 並凍結，active assignment 留待本批 shipping；未 commit／push／PR／merge／部署，未修改原 NC／runtime journal，也未宣稱 fleet 遷移或修後獨立 code-review PASS。
  - 日期來源:direct
  - 放棄:用 bootstrap 快照代替最終文件版本測試；將 pure wording 同步冒稱新 native source 全綠；為零 prose findings 再重開 reviewer 批次；把本地驗收當外向授權
  - 重議:真實合法續審仍拒絕、caller guard 被繞過、或 canonical 指令使 reviewer 漏／降級具體問題時，以新原始證據重現後修正；後續 shipping／跨工作線接續另核對當批授權及最新基線
  - 關聯:#271;deep-plan-repair-evidence;M-20261006-deep-plan-focused-go;M-20261006-deep-plan-bootstrap-verified;D-20261006-deep-plan-evidence-control-boundary

- **M-20261006-deep-plan-repair-completion-candidate · 2026-10-06 #271 修復已提交、結案 candidate 準備送審**：本輪使用者明示 `$project --merge`，授權本批 commit／feature push／PR／rebase merge，未授權部署。實作與已核對的既有規劃文件先提交為 `cc9a54a4f73b6ac1691d09665ffa018a79a5e46e`，parent 中保留兩項 active assignment；現在僅移除已完成的 #271，runtime 收斂維持 active／draft、原 journal 與 findings 保留。這是同一 steward 的工作項結案，不是 runtime actor retirement 或 ownership transfer。Code／reviewer prompts 相對前次完整 suite 未變；test-evidence 指出 STATUS／milestone／implemented plan 的結案文字差異，未宣稱全套 REUSE。雙端原生驗證、計畫 GO、獨立 code review 的作者修正及無修後獨立 PASS 等限制沿用 M-20261006-deep-plan-repair-local-completion。結案文件完成後核對 doc／xref、candidate parent authority，並驗當前送出內容；尚未 push、PR 或 merge，endpoint pending。
  - 日期來源:direct
  - 放棄:同一 commit 抹掉唯一 assignment；把剩餘 runtime 項目說成完工；endpoint 未抵達就宣稱 shipped；將舊全套結果的當前 snapshot 冒充過去 inputs
  - 重議:completion candidate authority、文件 audit 或當前 PR HEAD required CI 失敗；同 scope 的必要 CI 修復依本輪具名授權有界接續
  - 關聯:#271;deep-plan-repair-evidence;cc9a54a;M-20261006-deep-plan-repair-local-completion;M-20261006-runtime-layout-plan-preflight;docs/plans/2026-10-06-deep-plan-repair-evidence.md

- **M-20261006-runtime-layout-resumed · 2026-10-06 #271 合併後接回 runtime 一致性專案**：使用者要求回到原 dotfiles 一致性工作；同一 `codex:runtime-layout-convergence` writer／steward 在既有 feature branch fast-forward 到 `79269535b3a3a741a87c3f7a8bb1c8a161ce2fcd`，working tree 起初乾淨。#271 的 PR #272 已 MERGED、issue 已 CLOSED，兩平台 required CI 通過；不將其交付授權擴至本項。原 runtime journal 第 1 批兩輪／四位 reviewers、原 findings 與第 2 批原始 blind 授權保持；新批目前零 tickets／reviewers，接續該批而非再 restart。原 blocking finding 的 CI assertion manifest／parallel runner 相依已補正；逐檔 manifest SHA 與原計畫一致，仍是 dated snapshot、不代表 apply 時 quiescence。持久資料遷移與 SPLIT 放行判準改變維持完整、criteria-impact 的審查路徑；尚無本項 code／主機遷移或新 gate 結論。
  - 日期來源:direct
  - 放棄:重設 journal 或沿用原 NO-GO 作 GO；把 #271 protected source／history 變更假稱 focused 文件 checkpoint；把上一批 merge 授權擴為本項 shipping／部署
  - 重議:新的實質 Goal／判準決策、缺必要集合證據、有效 reviewer／admission 缺口或原 cap 耗盡時，按既有 workflow 處理
  - 關聯:runtime-layout-convergence;#271;M-20261006-runtime-layout-plan-preflight;M-20261006-deep-plan-repair-completion-candidate;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-plan-go · 2026-10-06 Runtime 目錄收斂規劃可進入本地實作**：沿用已授權的第二批與原 journal，兩輪共四位 fresh reviewers。首次 verifiable/medium finding 指出 deployment wiring assertions／brewup fixtures 仍固定舊 helper 接線；同一 canonical plan 補齊真實共用 entry、實際 clone 傳遞及 config／guidance 失敗傳遞驗收；judgment/low daemon 建議亦補明手動正常退出與重新 inventory，不放寬 offline guard。後續兩位均無 findings，transport／admission 與受審來源前後不變性核對通過，gate GO。Reviewer 已揭露 STATUS／document delta／history exposure，不能宣稱完全未接觸歷史結論。本項只獲本地實作／驗證授權；migration 程式、原生載入與 fleet 尚未驗收，不承接 #271 shipping endpoint。
  - 日期來源:direct
  - 放棄:保留舊 helper 名稱註解讓新接線測試假綠；把 daemon 退出條件豁免；用 plan GO 冒充 migration／fleet 完工
  - 重議:實作發現不可回復資料風險、核心 Goal／判準變更或必要集合證據不足
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-resumed;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-local-candidate · 2026-10-06 Runtime layout 共用 entry 與隔離候選完成**：新增 standard-library layout 工具及 ensure-runtime.sh，兩份 setup／brewup／dotsync 本機與遠端改共用；保留原 Codex guidance／三層 config merge、舊 helper 獨立安全 oracle 及 handoff resolver。Inventory／dry-run 唯讀、ownership／process／parent guards、私有 receipts／sibling backups、explicit recover／rollback、第二次 no-op 均有隔離 fixture。Baseline 真實兩格 assertion RED；新增 date-only provenance 誤判、無錨點同 bytes 不同名漏攔及 inventory 後 parent alias 置換分別先 RED 再修。22 個 unit cases（含十個安裝與四個 rollback boundary subcases）通過；真實部署接線的開發 integration 唯一失敗曾是新追加的無錨點案例，已修，其結果未冒充最後全綠。雙 runtime production targets 各 h-read／h-archive，四個 fresh native session 的實際 helper calls／artifact／Git state 核對通過：遷移 checksum／mode／mtime 相同，active 唯讀不 consume，archive 不重複 consume，不承接舊 commit／push claims。Native source 為未改的 7926953 handoff adapters/core；使用明示 repo-local skill／HANDOFF_DIR，host transport 非通用 sandbox，不宣稱全域 discovery／rules loading。最後全套 serial／parallel 與 docs／xref 待終驗；沒有 commit／push／PR／merge／本機或 fleet apply，fallback 留待部署驗收後清理。
  - 日期來源:direct
  - 放棄:把 created 同日當 checkpoint 同來源；以檔名不同允許同 bytes 舊 claims 重現；只在 inventory 檢查 parents、不在 transaction 再核對；以明示 fixture 載入冒充全域 runtime 驗收
  - 重議:最後 suite／manifest／資料保全或 native fixtures 失敗；主機 apply 時 writer／ownership／snapshot 不明則先停止該 root
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-plan-go;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-transaction-validation · 2026-10-06 Runtime 遷移錯誤狀態攔截已驗證**：追加 readonly probes 發現 inventory 未列 writers，以及 recover 可跳過未知步驟而誤報 committed；缺 stage 的 receipt 亦會在拒絕前先搬動 target。原始失敗與 fixtures 保留，修為 process 清單可觀察、operation 集合／input scope／stage／snapshot shape 及 step 在 mutation 前正向驗證。24 個 unit cases 通過，未知 receipt 不搬原 store，保留新 checkpoint 與備份。首次固定輸入 serial／parallel 各 1575 PASS／1 FAIL，342 source leaf files／34 directory links 前後相同；唯一 suite 失敗為本項新條目泛用標題搶占 unrelated lookup，entry_score 的 title 權重與 counterfactual 已核對，僅修正本次新標題為 runtime 工作項的具體結果，原 facts／ID／日期與既有歷史保持。原 title-free corpus gate 再驗通過，未改 search core、query、答案、門檻或 metadata alias。修正版 full suite 待重跑。Final migration controls 已重建四個 native 輸入，bytes／mode／mtime 與已驗證的原生輸入相同；未改 handoff skill source，不冒稱新的全域 discovery／rules loading。
  - 日期來源:direct
  - 放棄:未知 receipt 跳步後回成功；先搬資料再檢查 receipt 缺欄位；隱藏 writer 或假稱關對話即離線；為檢索測試降低門檻、改 query 或擴改 search core
  - 重議:修正版 full suite、來源不變性或資料保全失敗，先保留原始證據並修正 causal source
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-local-candidate;M-20261006-runtime-layout-plan-go;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-config-parent-guard · 2026-10-06 Codex home 別名拒絕後的 helper 寫入已攔截**：隔離共用 entry 重現 `.codex` parent 指向 fixture repo 時，layout 非零拒絕但 config helper 仍改寫 source；原 RED 保存於 `/tmp/runtime-layout-config-parent-red-20261006.log`。新增唯讀 native-home parent guard，兩個既有 helper 只在 guard 通過後執行，其他安全 root 仍可完成；獨立 helper 契約未改。25 個 unit cases exit 0，repo bytes／identity 保持且安全 roots 完成。當前 migration SHA 的四份 controls 重建產物與已驗 native 輸入 bytes／mode／mtime 相同，證據 `/tmp/runtime-layout-native-final-controls-v2-20261006/evidence.json`；handoff source 未改，保留明示 skill／HANDOFF_DIR 的驗證邊界。修正版全套待終驗，未在真實 host apply 或交付。
  - 日期來源:direct
  - 放棄:只攔 layout 卻讓後續 helper 穿過同一 parent alias；因單一 Codex root blocked 就停止所有安全 root；將 fixture 能力外推 fleet 已遷移
  - 重議:共用 entry 的來源保護、修正版 full suite 或資料保全失敗時，先保留原始失敗再修 causal source
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-transaction-validation;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-local-acceptance · 2026-10-06 Runtime 共用部署與資料搬移候選已完成本地驗收**：修正版完整 serial／parallel 均 terminal exit 0、1576 PASS／0 FAIL（core 171、ship_state 239、integration 1166）；342 source leaf files／34 directory links 在啟動前凍結、完成後相同，記錄更新前亦核對 current 相同。Raw logs 與 inputs evidence 保存於 `/tmp/runtime-layout-final-{serial,parallel}-v2-20261006.{log,evidence.json}`，前次 1575／1 的失敗證據保留。25 個隔離 unit cases 通過，涵蓋來源／個人資料保全、writers、十個安裝與四個 rollback boundary subcases、recover、未知 receipt、parent alias 和 no-op；真實 common entry 的 brewup／local／remote fixtures 驗失敗傳遞。ShellCheck、doc-governance ship／xref、title-free retrieval corpus、authority gate、diff 檢查通過。兩端共四個 native handoff cases 的 artifact／Git／helper trace 及當前 migration controls 相符；未改 7926953 handoff source，只驗明示 skill／HANDOFF_DIR，不代表全域 discovery／rules loading 或 fleet 已遷移。此後僅更新 STATUS／本 in-progress plan／此 event-time 記錄，另驗文件，不將先前全套冒稱覆蓋新記錄；未宣稱修後獨立 code-review PASS。本地候選可交付，尚未 commit／push／PR／merge／真實 host apply；14 目標 rollout 與 resolver cleanup 仍屬後續，active assignment 保留。
  - 日期來源:direct
  - 放棄:改 aggregator 門檻迎合 count drift；把失敗 log 覆蓋成成功；全套後更新紀錄卻冒稱 source 全同；以 fixture 或本地綠宣稱全機隊完工
  - 重議:本批 shipping checks 或 fresh fleet ownership／writer／snapshot 不符時，停止受影響動作並保留資料；resolver cleanup 須先完成 14 目標遷移驗收
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-config-parent-guard;M-20261006-runtime-layout-local-candidate;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-delivery-candidate · 2026-10-06 Runtime 共用入口與搬移工具準備交付**：使用者明示本批 `$project --merge`，授權此次 feature commit／push／PR／rebase merge 及同 PR 原 scope 內最多兩次必要 CI 修復，不包含主機部署。唯讀盤點為單一 dotfiles repo、17 個已核對本工作線的未提交檔案、protected main 與兩平台 required contexts；無 review residue／terminal。Exact `codex:runtime-layout-convergence` 的原 assignment fingerprint 與當前 HEAD 重驗 `current-session-workline-binding`／PASS，active assignment 與 in-progress plan 保留，因 fleet 遷移與 resolver cleanup 尚未完成。既有 serial／parallel 各 1576／0 的 helper 比對僅指出 STATUS／plan／本月 milestone 收尾文字變更，程式及受驗 skill source 未變；補驗文件與 xref，不冒稱全套 REUSE 或修後獨立 code-review PASS。當前尚未 commit／push／PR／merge，endpoint pending；原失敗與 native exposure／loading 限制保留於既有 acceptance records。
  - 日期來源:direct
  - 放棄:把此批 merge 授權擴成 fleet apply；過早移除 active assignment 或 fallback；覆蓋原失敗與檢查證據；把收尾文件的新 snapshot 倒填為過去全套 inputs
  - 重議:authority／doc audit／當前 PR HEAD required checks 或 provider gates 失敗時，依既有有界同批修復處理，不 bypass 或自動擴 scope
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-local-acceptance;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-merged-deployment-authorized · 2026-10-06 Runtime 搬移工具合併與 fleet 部署授權**：PR #273 已 rebase merge 至 origin/main `744356df2caae0cf63b76692798390474267f4a6`；candidate `296ef96baa5fc4e28fa7a69a40f4357032be08e0` 與 merged tree 相同，required macOS／Ubuntu CI 通過。使用者另明示本批「14 個目標的遷移部署與驗收」，此為當批 runtime 部署授權，不含套件更新、kill writers、未知資料覆蓋或新 code shipping。fresh raw no-follow inventory 完成 14 目標，reader／逐台證據在 `/tmp/runtime-layout-fleet-20261006`；macs 計一次。12 個遠端 clean／無 writers，eagle08 有修改的 claude/settings.json、untracked synced skills 與 3 個 writers，保留現場；macs 有 13 個 writers，另重現 dhcp6d UID -2 使 production ps parser 非零，未放寬 guard。原盤點保留其採集時間；先 be01 無 CLI canary，再 eagle06 的六檔 handoff／雙 CLI canary，尚未 apply。
  - 日期來源:direct
  - 放棄:以原盤點冒充當下無 writers；自動 reset 遠端本機修改；以 merge 授權冒充部署或新批 shipping；遇單台 blocked 就放棄其他安全目標
  - 重議:canary、資料保全、origin revision 或 writer／ownership 不符時停止受影響目標並保留證據；14 目標通過前不移除 fallback
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-local-acceptance;M-20261006-runtime-layout-delivery-candidate;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-canary-accepted · 2026-10-06 Runtime 首批兩台搬移與原生 discovery 通過**：be01（Linux、無 CLI／無 store）與 eagle06（Linux、雙 CLI／六檔 legacy handoff）均 fast-forward 至 origin/main 744356df，common entry apply／verify／rerun／verify-rerun exit 0。Source snapshots 前後相同；runtime roots、個人設定重跑後含 inode／mode／mtime／bytes 相同，eagle06 receipts／retained backups 也相同。六檔 handoff 整體 content／mode／mtime 搬到正式 store，legacy path 已移出 discovery。eagle06 Codex 0.154.0 原生 skills/list 在新暫存 cwd、不追加 skill roots 的情況列出 11 個 user adapters，system skills 仍可見；原生 execpolicy parser 讀正式 rules 全集後 gh pr merge 為 prompt，未執行命令，未冒稱直接觀測 session 自動 rules enforcement。Claude 2.1.269 metadata-only initialize 列出 11 個 user adapters；temporary no hooks/tools/MCP、無 model turn／persisted session，不改 hook trust。其 account tokenSource none，不冒稱登入／模型 API 可用。be01 只有 layout 能力，不安装 CLI。初次 Claude probe 的空 MCP schema 錯誤已保留 attempt1，改 probe 為 mcpServers 空表後握手成功；未修改 production source。逐台 raw receipts／snapshots／native response 保存於 /tmp/runtime-layout-fleet-20261006；可繼續其他十台 safe targets，blocked macs／eagle08 保留。
  - 日期來源:direct
  - 放棄:把 CLI 缺席或 metadata-only 握手冒充模型可用；以 explicit rules parser 冒充自動 enforcement；使用 live handoff survey 清資料來驗收；重跑產生新 backups
  - 重議:其餘 targets 的 writer／dirty tree／snapshot 不符停止該台；全體遷移驗收前保留 legacy resolver
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-merged-deployment-authorized;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-fleet-twelve-accepted · 2026-10-06 Runtime 十二台正式 store 與逐台載入驗收**：兩台 canary 後，共 eagle03／eagle06／eagle07／eagle09／db01／ap01／ap02／macmini／m4mini／agent01／fe01／be01 十二台 fast-forward 至 744356df，common entry apply／verify／rerun／verify-rerun 全 exit 0。每台三個 committed transactions 的 candidate／before backups 正確、stage 不存在，重跑不新增 receipts／backup。Source 與個人設定在 migration 前後相同；handoff 的七檔及 db01 空 archive 保留 content／mode／mtime，舊 store 移出 discovery。8 Codex／10 Claude 原生 metadata-only discovery 驗出 11 repo adapters，macmini 另四個 plugin skills 可見。Codex 原生 parser 驗 gh pr merge 為 prompt，未執行命令／模型 turn，未冒稱自動 enforcement；無 CLI 能力缺項明列。原生啟動後 .system 重建與部分 auth／Claude cache 變化另記，三階段 manifest 證明 migration 未變更它們，native 後 managed／handoff／第三方仍相同。初次 audit 將 native system lifecycle 與 macmini 額外插件當失敗，原 log 留 attempt1；依 sources／phases 改 evidence reporter，不改 production guard。macs 13 writers／18 檔 legacy、eagle08 3 writers／dirty repo 各 blocked，初末 runtime roots 相同；本批是 12／14，未移除 fallback。逐台表在原 in-progress plan，raw evidence 路徑及 SHA 同表。
  - 日期來源:direct
  - 放棄:自動 autostash／reset 遠端未知修改；把 .system 的 native 生命周期冒充資料搬移失敗或宣稱全樹不變；要求 user skills 僅有 repo entries 而遺失第三方；以 12 台冒稱全 fleet 完工
  - 重議:解除兩台 writer／修改與本機 parser 的交付阻擋後，fresh 再驗；14 目標通過前保留 fallback
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-canary-accepted;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-negative-uid-repair · 2026-10-06 Runtime 程序清單支援 macOS 負 UID 的本地修正**：真實 ps exit 0，但 dhcp6d UID -2 被 isdigit 拒絕，production inventory 非零且未列 writers；隔離端到端 RED 在修改前保存。只改 UID 欄位 validation 接受 -?\d+，PID／三欄／malformed input／same-user writer guard 不放寬。26 cases exit 0（8.204s），同 UID daemon／malformed UID controls 仍 blocked、離線 legacy 搬移可成功；真實本機 inventory process ok 且列出 13 個 writers，handoff 仍 blocked，未 apply。Raw RED／GREEN／live report 在 /tmp/runtime-layout-negative-uid-{red,green,live-fixed}-20261006.*。Full serial／parallel 待終驗，修正尚未交付 origin/main，需要新批具名 shipping 授權；未修改 skill／fallback。
  - 日期來源:direct
  - 放棄:跳過全 ps inventory、隱藏當前 writers 或忽略所有 parse errors 來繞過本機阻擋；在 origin/main 前散佈修正
  - 重議:完整 suites、source invariance 或 malformed／writer controls 不符時保留失敗證據，停止交付；本機 app／daemon 正常退出後才可遷移
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-fleet-twelve-accepted;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-layout-negative-uid-acceptance · 2026-10-06 Runtime signed UID 修正完整測試已通過**：原 RED → 一行 causal repair → 26 cases 後，完整 serial／parallel 均 exit 0、1576 PASS／0 FAIL；耗時 408.167s／328.435s，parallel core 171／ship_state 239／integration 1166。376 tracked source paths（含 34 directory links）各次凍結 before／after 相同；raw logs 與 JSON evidence 在 /tmp/runtime-layout-deployment-{serial,parallel}-20261006.*。再次按各 host 的 repo SKILL.md entry 名稱對照原生 metadata，8 Codex／10 Claude 的 11 adapters 完整一致，macmini 四個 extra plugin skills 保留；證據 /tmp/runtime-layout-native-adapter-names-20261006.json。Doc ship audit／diff 已通過，終驗後只更新 STATUS／原 plan／此 event 記錄並另驗 docs，不冒稱 full suite 的 inputs 涵蓋新記錄。修改保留在 refactor/runtime-layout-convergence，尚未 commit／push／PR／merge；deployment authorization 不擴成新 shipping。Fleet 維持 12／14，macs／eagle08 的阻擋與 fallback 保持。
  - 日期來源:direct
  - 放棄:用 parser 修正豁免 real writers；將 full suite 前後 fingerprints 改成收尾文字；把此批 deployment 擴為新批 code shipping；宣稱 14 台完工
  - 重議:新批 shipping gate 或剩餘兩台 fresh writer／ownership／snapshot 不符，停止受影響動作並保留資料
  - 關聯:runtime-layout-convergence;M-20261006-runtime-layout-negative-uid-repair;M-20261006-runtime-layout-fleet-twelve-accepted;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-eagle08-runtime-disposition · 2026-10-06 Eagle08 已完成具名程序與 runtime drift 清理**：本輪明示授權後，以 pidfd 綁定並再次驗證 PID 18379／18483 的 UID／exe／app-server／啟動身分，兩個測試 daemon 均 TERM 正常退出，未用 SIGKILL；fresh ps 無 writers。僅 claude/settings.json 的 opus drift／格式修改還原 HEAD bytes，設定檔 symlink 保持。已識別雲端 synced cache 的 284 entries 移至 /home/jjshen/.runtime-layout-disposition/eagle08-cloud-sync-20261006T144807Z，前後 mode／mtime／bytes manifest 相同，SHA256 59f99e9e1680a6ac107911646fb06b86ff9f2c58aab1e1f2361b5d01e3868f0d；runtime drift 原檔亦保存於該私有備份。git status clean；原始與清理後 snapshots 在 /tmp/runtime-layout-fleet-20261006/eagle08-resume-{before-cleanup,clean}.json，具名處置 raw result 同目錄 eagle08-authorized-disposition.json。目錄 migration 尚未 apply；新權威同步 opt-out 仍待本地驗證／具名交付，不把 cache 清理冒稱永久停用。
  - 日期來源:direct
  - 放棄:pkill 所有同名程序；PID 不核身就 signal；留下 synced 讓 source 持續 dirty；把 restore 擴到其他未知修改；將一次 cache 清理當成同步政策已部署
  - 重議:新 writers、repo drift、backup identity／checksum 不符或 origin revision 移動時，停止受影響操作；新 opt-out 未交付前維持永久停用 pending
  - 關聯:runtime-layout-convergence;D-20261006-runtime-cloud-sync-disposition;M-20261006-runtime-layout-fleet-twelve-accepted;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-eagle08-runtime-accepted · 2026-10-06 Eagle08 接續遷移驗收，layout 達十三台**：具名 daemon／drift／cloud cache 處置完成後，eagle08 fast-forward 至 origin/main ee9312d，update／dry-run／common entry apply／verify／rerun／verify-rerun 全 exit 0。Source 保留；三個 committed receipts 的 candidate／before backups 正確、無 stage residue；重跑 roots／私人設定／receipts 含 inode 相同。Codex config 由既有 merge helper 首次重新序列化，四階段完整／managed／unmanaged TOML 語意相同，mode 0600，重跑及 native 後 bytes／inode 不再改變；其他 protected 在 migration 階段相同。首次 reporter 的全 protected bytes 比較把受管理 serialization 算成失敗，原 evidence 保留 acceptance.attempt1，核對 production helper 後修正 task reporter 的角色分離，沒有修改 production guard。Codex 0.160.1／Claude 2.1.291 metadata-only 原生 discovery 各 11 repo adapters；explicit rules parser prompt，未執行 merge／model turn。Claude probe 用 temporary per-process cloud opt-out；.claude.json 原生 cache 改變另列，.system 未重建，managed roots 保留且 synced 不存在，settings 檔案 symlink 保持。Raw artifacts 在 /tmp/runtime-layout-fleet-20261006/eagle08-resume-*.json；acceptance SHA256 54372cf2c121e1475488a32257b82b62cdff6af66ad23e3539b5df71bf093167，artifact-manifest SHA256 a45f032ab288704c19e683a217984036c7c1ec06bb81c5e720401b06cb572fc7。原十二台 evidence 未覆寫。Layout 現為 13／14，macs 尚 blocked；權威雲端 opt-out 的新設定未交付，不宣稱永久停用或全專案完成。
  - 日期來源:direct
  - 放棄:把受管理 TOML serialization 當成私人設定遺失；以語意保全豁免其他私人檔案的 bytes／inode；覆寫初次失敗 evidence；用 temporary CLI 設定冒充永久部署；以十三台通過移除 fallback
  - 重議:新設定交付後仍須核對遠端 false 與 settings symlink；macs 需 fresh writer／data 驗收；額外終端相容影響未釐清前不移除 fallback
  - 關聯:runtime-layout-convergence;M-20261006-eagle08-runtime-disposition;M-20261006-runtime-layout-fleet-twelve-accepted;D-20261006-runtime-cloud-sync-disposition;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-cloud-sync-validated · 2026-10-06 Claude 雲端 opt-out 與十二台 cache absence 驗證通過**：權威 claude/settings.json 補 syncClaudeAiSkills=false，JSON 語意比對僅新增該鍵，其他設定不變；原 missing-key RED 在 /tmp/runtime-cloud-sync-red-20261006.json。Eagle08 原生 Claude 2.1.291 metadata-only probe 支援 temporary false、載入 11 repo adapters 且無 cloud commands，未驗 account 背景下載週期，不冒稱永久設定已部署。本輪完整 ./tests/run.sh exit 0、1576 PASS／0 FAIL，368.272s，376 tracked inputs 的原始 before／after 相同；raw log SHA256 a96f5dbbece32872cf81be3f8eb32d8cd8c25a47751faca5f5bff7021fdaa2e2，證據 /tmp/runtime-cloud-sync-serial-20261006.{log,evidence.json}。使用者再要求先查其他十二台後提交／dotsync；唯讀檢查 eagle03／eagle06／eagle07／eagle09／db01／ap01／ap02／macmini／m4mini／agent01／fe01／be01 的 runtime 與 repo 各 synced／syncd 四路徑，全數不存在、repo clean、settings opt-out 尚未設定。逐台 raw 及 summary 在 /tmp/runtime-layout-fleet-20261006，cloud-sync-twelve-precheck.json SHA256 bf382964668fa9dbf52b59bcf65bbdf4b6d910a34af3154a3adc6d27e08d6c4b。測試後追加驗收紀錄另驗 docs，不倒填 full suite snapshot。Commit／dotsync 已具名授權，shipping endpoint 尚未明示；新設定未進 origin/main 前不執行無法散佈修正的 dotsync。
  - 日期來源:direct
  - 放棄:用 cache 當下不存在冒充永久同步停用；以 temporary override 冒充來源已交付；因 commit／dotsync 授權自行擴成新批 push／PR／merge；覆寫原始測試 inputs
  - 重議:本批 shipping gate 或 dotsync／fresh post-deploy 失敗時保留現場；逐台核對 source revision、false 與 symlink，macs 未遷移仍保持明列
  - 關聯:runtime-layout-convergence;D-20261006-runtime-cloud-sync-disposition;M-20261006-eagle08-runtime-accepted;docs/plans/2026-10-06-runtime-layout-convergence.md;claude/settings.json

- **M-20261006-runtime-model-defaults-validated · 2026-10-06 雙端 repo default 模型設定本地驗證通過**：Claude model 由 opus[1m] 改為 default，Codex 繼續省略 model 並註解其等效 default 策略。JSON 與 HEAD 語意比對只有 model 改變，syncClaudeAiSkills=false 及其他設定相同；Codex TOML 可解析且不固定 model。隔離 native Claude metadata-only 初始化接受來源讀出的 default／cloud false，無模型 turn／production apply，不宣稱帳號 default 的實際模型。真實 Codex merge helper 驗 fresh 不生成 model、runtime 已保存模型保留、local 模型優先，三案重跑 bytes／inode／mtime 都相同；只寫暫存 target，未修改本機 live config。七項 checks exit 0，declared source inputs 前後相同；raw evidence /tmp/runtime-model-defaults-20261006.evidence.json，native raw response /tmp/runtime-model-defaults-native-20261006.json（私有）。變更是設定值／註解與紀錄，另驗 doc audit／xref／retrieval；前次 full suite 不冒稱覆蓋新模型設定。
  - 日期來源:direct
  - 放棄:用 literal default 填入 Codex 模型 ID；清除 runtime-only／local 模型選擇；以 metadata-only 初始化宣稱帳號模型已實際推論
  - 重議:新設定原生解析／合併或文件 audit 失敗則停止交付；永久散佈仍待當批 origin/main gate，macs 遷移阻擋不因模型改值而解除
  - 關聯:runtime-layout-convergence;D-20261006-runtime-model-defaults;D-20261006-runtime-cloud-sync-disposition;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261006-runtime-settings-deployed · 2026-10-06 Default 模型與雲端 opt-out 已交付並逐台同步**：PR #276 在 2026-10-06T15:52:45Z rebase merge 至 b6299f5，required macOS 9m16s／Ubuntu 3m37s 全綠（run 37489655850）；candidate 與 merged tree 相同，本地 main 同步、原 PR branch 清理。來源進 origin/main 後執行已具名授權的 dotsync，exit 1、5.846s、local=failed／remote_ok=13／remote_failed=1（macs self-target 在 14 目標只計一次）。Fresh 14 台 source revision 與 clean main、Claude default／cloud false／settings symlink、Codex base 無 model 均確認；13 台遠端 common entry／verify 通過，cache 四路徑 absent、roots／私人設定／handoff／receipts／retained backups 含 inode 保留。macs 8 writers 阻擋 handoff apply／verify，部署前後 16 legacy 檔與 roots／maintenance 相同、runtime synced cache 保留；未 kill 或擴張 eagle08 清理授權。既有 merge helper 將 managed effort high → repo medium，saved gpt-6.1-sol／unmanaged state／其餘私人檔保留、mode 0600；single-field control 重現 pre actual hash，post actual=pre expected，根因是 reporter 把 managed config 也要求 bytes／inode 不變，初次失敗另保留，不改 production helper／guard。Raw evidence 在 /tmp/runtime-layout-fleet-20261006，最終 settings-deployment-acceptance.json SHA256 041e72ae6fe13d795d2582552508a82d5d75f045a2c7c52c03090e1937be5fc3；完整 artifact pointers 與限制見 plan。設定層核對 14 台、layout 13／14，不宣稱 model turn／背景同步週期或全專案完成。
  - 日期來源:direct
  - 放棄:以 dotsync 部分成功冒稱 exit 0；為本機 handoff 解除 writer guard；以設定 false 冒稱現有 cache 已清除或背景週期已驗；將正常 managed default 收斂當成私人資料損毀；丟棄首次失敗 evidence；對新 PR 沿用既有 merge 授權
  - 重議:macs 無 writers 後 fresh 盤點／遷移／cache 核對，額外終端相容範圍釐清前不移除 fallback；新 drift 或 source 移動須重新驗受影響目標
  - 關聯:runtime-layout-convergence;PR#276;D-20261006-runtime-model-defaults;D-20261006-runtime-cloud-sync-disposition;D-20260912-codex-config-three-layer-merge;M-20261006-eagle08-runtime-accepted;docs/plans/2026-10-06-runtime-layout-convergence.md


- **M-20261007-macs-runtime-layout-accepted · 2026-10-07 macs 離線遷移驗收，layout 達十四台**：使用者選擇修正版離線流程後自行從普通 terminal 執行；來源固定 PR #276 main b6299f5，native daemon 正常 stop，核對 updater PID 4711 的 boot／UID／start time／executable／role 後 TERM，無其他 writers、不用 KILL／刪 lock。Common entry committed handoffs transaction 2a82d9a58bd64651ac1031074a2d9e8a，verify／common entry rerun／verify-rerun 全綠；18 個 handoff 檔與 archive 的 checksum／mode／mtime 保留，正式 store 實體、legacy 入口 absent、原 sibling backup 含 inode 與 receipt before 一致、無 stage 殘留、重跑不新增 receipt。雙端原生 metadata-only discovery 各列 11 repo adapters，Codex rules parser prompt；Claude 不用 temporary cloud override，按已部署 user false 在啟動時將 215 個 cloud skill 檔搬到 native .trash，bytes／mode／mtime／inode 保留，清除 3 個同步索引，synced／syncd 四路徑 absent。首次全 root 不變 reporter 的失敗保留；對照確認僅已識別 synced→trash／索引清除／skills root mtime 與 .claude.json cache 改變，其餘 managed entries／handoff／receipts／backup／source／私人設定保留，不改 production helper／guard。Raw /tmp/macs-runtime-rollout-20261007.mt8BvI；acceptance SHA256 d5d55970dce4e8e6b2676a852c6cc102e3cb91e4e301a6e452ed540505ab3c37、manifest SHA256 4d00627425d3299f8c58bc55d07ce4a31c31e9168a2ed60a160cc2944751483f。現行 inventory layout 14／14，缺 CLI 邊界沿原表；未驗 model turn／背景週期，trash 非永久備份，兩部 inventory 外終端及 legacy cleanup 尚待，不宣稱專案結案。
  - 日期來源:direct
  - 放棄:因 updater 常駐關閉 writer guard；以重啟成功冒稱 migration；未核身就 kill／刪 lock；把 native cloud opt-out 的預期 cleanup 當成私人資料遺失或放寬其他 root 保全；覆寫首版 reporter 失敗；以 native trash 冒充永久保留全部 218 cache 檔；為新紀錄沿用舊 push／merge 授權
  - 重議:兩部 inventory 外終端的 runtime／legacy store 影響須先釐清再移除 fallback；新 writer、data／receipt mismatch、source 或設定 drift 則重驗受影響目標
  - 關聯:runtime-layout-convergence;M-20261006-runtime-settings-deployed;M-20261006-eagle08-runtime-accepted;D-20261006-runtime-cloud-sync-disposition;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261007-claude-native-default-verified · 2026-10-07 Claude 模型選單唯一 Default 驗證通過**：使用者選擇第 1 項，只收省略 model。外部 UI 原檔先備份，repo settings 精確等於 HEAD JSON 移除 model，modelSettings.high 與排序回寫還原；syncClaudeAiSkills=false、hooks／permissions／其餘設定相同，settings symlink 與本機 settings.local.json bytes 保留，Codex base 仍無 model。本機 Claude 2.1.289 literal metadata-only RED 實際 exit 1（兩列 default、一列 Custom model），unset control 與修後 source probe 都 exit 0（推薦 Default 一列、Custom model 零列）。修後 source response /tmp/claude-default-fix-20261007.88lvqtc4/source-green.json，SHA256 e4a7c7a6a8fac80f560b6b89765f47c3ae74cf665b68550309fad0822e783988；probe 在隔離 HOME、無 tools／hooks／MCP／persisted session／model turn，僅來源的模型表示與 cloud false 帶入候選設定。既有初始化成功記錄與 raw response 保留，不冒稱 literal default 推論失敗；本輪修正仍只在本地 feature，未 push／merge／dotsync。
  - 日期來源:direct
  - 放棄:將 settings 字串與 SDK 序列化值混為原生選單同一選項；以舊 initialize success 或 full suite 冒稱唯一性已驗；順便納入 UI high effort 或清除 local/session 覆寫
  - 重議:原生選單再出現重複列或來源／local 設定有新 drift，重驗受影響範圍；fleet 修正須新的當批交付與部署授權
  - 關聯:runtime-layout-convergence;D-20261007-claude-model-default-unset;M-20261006-runtime-model-defaults-validated;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261007-claude-default-native-291 · 2026-10-07 Claude 2.1.291 原生 Default 補驗通過**：本輪 $project --merge 交付檢查時目前 CLI 為 2.1.291，不假定既有 2.1.289 紀錄覆蓋當前環境。以現行 binary 補驗 literal default RED exit 1（default 兩列／Custom model 一列）與 repo 省略 model GREEN exit 0（推薦 Default 一列／Custom model 零列）；來源 snapshot 與 CLI／probe binary fingerprints 前後相同，Project test-evidence helper 對 GREEN 回 REUSE，environment matched。仍是隔離 HOME、無 tools／hooks／MCP／session persistence／model turn 的 metadata-only 選單驗證；CLI 安裝／升級不是本批操作。Raw /tmp/project-merge-20261007._r02ruzn，GREEN response SHA256 e4a7c7a6a8fac80f560b6b89765f47c3ae74cf665b68550309fad0822e783988、normalized execution evidence SHA256 e0e0c74356c5c0bdf793ad395261b4b788a6135b2c66175578385f6d045ded46；CLI binary SHA256 9a1d2ed6bb4421e8fc80c892c0413f293be3ee50ae3d7dda1a7622197a056690。本輪 endpoint 已獲 --merge 授權，當下 PR／required CI／merge 尚待，不宣稱來源或 fleet 已交付。
  - 日期來源:direct
  - 放棄:只因 repo inputs 相同就假定外部 CLI 環境相同；把 RED 的 exit 1 當成可沿用的成功測試；以選單 metadata 宣稱模型 turn 或 fleet rollout
  - 重議:required CI 或 provider gates 未通過時維持 pending；環境 fingerprints 或來源變動時重驗受影響檢查
  - 關聯:runtime-layout-convergence;D-20261007-claude-model-default-unset;M-20261007-claude-native-default-verified;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261007-ci-confidence-local-validation · 2026-10-07 CI 可信度修正通過本地完整驗證**：branch fix/ci-test-confidence 上修正七項原始回歸：hosts 異常 marker 保全、all-up 及兩支 signing scripts 失敗聚合、CI 結構判準、heredoc scanner error／delimiter 語意與 parallel descendants 清理；11 組隔離測試含合法 controls，另覆蓋候選 supervisor 的 spawn signal race，以及 CI dependency continue-on-error、matrix 順序與 custom shell 邊界。原始九組 RED exit 1（30 failures／1 timeout error），lint RED 固定 76 inputs／53 canonical files，修後檔案聯集保持且每個實體檔只掃一次。serial exit 0，1574 PASS／0 FAIL（407s）；定稿 parallel exit 0，172／239／1163，共 1574（最長 shard 332s）；最後補充 controls 的 core 補驗 exit 0（172／0，40s）。日誌 /tmp/ci-confidence-serial.log、/tmp/ci-confidence-parallel-verified.log、/tmp/ci-confidence-core-final.log；沒有真實 SSH／SCP／CA／package mutation，沒有 container attach。變更未 commit／push，雙 OS PR CI 未執行，故記本地驗證而非完成交付或關閉 active contract；native/model eval 不在此證據範圍。
  - 日期來源:direct
  - 放棄:以頂層斷言數下降或舊 baseline 全綠當品質提升；以本地 macOS 宣稱 Ubuntu／PR provider 或 native/model 已驗證；沿用其他批次 shipping 授權
  - 重議:首次具名 delivery 的 required CI、環境 drift 或新增可重現假綠／誤紅時重驗受影響 gates，保留其 raw exit 與 controls
  - 關聯:D-20261007-ci-confidence-regression-first;D-20261007-ci-supervisor-signal-flag;CI 測試可信度與必要覆蓋;docs/testing-contract.md

- **M-20261007-ci-section-profile · 2026-10-07 macOS integration 的 section 時間基線已量測**：依使用者「開始，先量測」在本地 macOS 26.7.1 arm64／32 logical CPUs／Python 3.14.8／Homebrew Bash 5.3.20，使用外部 stdout observer 跑原 tests/run.sh 的 integration，未修改 runner／分片／assertions。Foreground section wall time 以原 header 邊界與 monotonic clock 量測（selector interval 0.05s）；全程 322.540s、1163 PASS／0 FAIL、exit 0，run.sh SHA256 69aff0bac839c461f488255790529a3c915d2c34f97956e2270346851214804a 前後相同。12b deep-plan 84.917s、12bb deep-review 79.139s、turbo 45.249s、12c project 32.052s 合計 241.357s（74.8%）；連續候選區間 9b–12b／12bb–16／turbo–結尾為 93.392／124.123／105.023s。此為單次本機基線與切分候選，不是 CPU exclusive time 或 GitHub macos-15 實測／效能承諾；fixture 依賴與並行 CPU／I/O 成本尚須驗證。Raw log／JSON／observer 位於 /tmp/ci-section-profile.3x4qgj/，JSON 帶 environment、source hash 與 rebuild argv；重建命令為 python3 /tmp/ci-section-profile.3x4qgj/profile.py /Users/jjshen/.dotfiles /tmp/ci-section-profile.3x4qgj。本輪未實作分片或刪測試、未送出 CI。
  - 日期來源:direct
  - 放棄:以 assertion 數平均分片；把 GitHub 彙總時才印出的 log timestamps 當 section 執行時間；對整套開 xtrace 造成 I/O 干擾；用本機 32-core 的比例直接承諾 hosted wall time
  - 重議:來源／環境 drift、重複基線有顯著變異、切點 fixture 依賴未能隔離或 hosted profiling 排名不同時，以新實測重新配平
  - 關聯:M-20261007-ci-confidence-local-validation;M-20260916-ci-test-sharding;CI 測試可信度與必要覆蓋;tests/run.sh

- **M-20261007-ci-shards-local-validated · 2026-10-07 五 shard 完整驗證與本機加速通過**：branch fix/ci-test-confidence 按 section 基線把原 integration 切成 plan／review／runtime，保留原 serial 順序與 integration 聚合入口；跨段 Git fixtures／review-state 路徑獨立初始化。完整 parallel exit 0、1574 PASS／0 FAIL，monotonic wall time 136.994s；core／ship_state／plan／review／runtime 的 runner elapsed 為 42／56／104／137／116s，最長 shard 由前版 332s 降至 137s（約 59%）。完整 serial exit 0、1574／0，wall time 414.120s。逐段 assertion 順序及完整多重集合相同，只正規化成功 local-fetch 文案的實測秒數；原值與原始 log 保留。新三段與舊 integration log 的 112／383／668 條順序精確相同，五段 assertion body bytes 保持（review-state 路徑宣告移至共同前置）；無測試移除，manifest 合計不變。11 組隔離 controls 在 Bash 5.3／3.2 均 GREEN，實際五 shard runner 的 INT／TERM／child interruption／spawn race 清理通過；Bash 3.2 dispatch smoke 確認 all／integration／unknown 的選段及 exit。量測環境同本機基線，run.sh SHA256 edf4b86a3c33b0780287d02482d49a5f87ce55964bf8347e22b4672f746a358a，四個 runner／manifest／test fingerprints 前後相同。Raw logs、JSON、body audit、comparison 與 rebuild scripts 位於 /tmp/ci-shard-optimization.s1bblvei/；重跑 python3 /tmp/ci-shard-optimization.s1bblvei/measure.py parallel（或 serial），再以 compare.py 比對。未 commit／push，未執行 GitHub 雙 OS PR CI；不將本機 32-core 單次改善當 hosted 效能承諾。
  - 日期來源:direct
  - 放棄:只核對總數而漏掉重複／遺失的 assertion；為了輸出完全相同而改原始 log；以本地結果冒稱 GitHub macOS／Ubuntu 完成
  - 重議:hosted wall time／CPU／I/O 顯著不同、來源／環境 drift 或新跨段依賴時，以新實測重新配平並重驗完整集合／exit
  - 關聯:D-20261007-ci-measured-integration-split;M-20261007-ci-section-profile;CI 測試可信度與必要覆蓋;docs/testing-contract.md

- **M-20261007-ci-required-accepted · 2026-10-07 CI 必要覆蓋與五分片通過雙 OS 驗收**：PR #278 implementation HEAD 291a029aaa0d6091cd91e25c08d8163a2fc5e883 的 required non-watch checks exit 0，macos-15／ubuntu-24.04 各 1574 PASS／0 FAIL、五 shards 為 172／239／112／383／668；七項原始 RED 與合法 controls、本地完整 serial／parallel 的 assertion 聯集與順序、lint canonical 聯集、Bash 3.2／5.3 cleanup 均已有實跑證據。依全部 AC 結案「CI 測試可信度與必要覆蓋」，移除其 active item；Runtime 目錄收斂工作與原 Writer／Dossier Steward 保留，不宣稱該 workline 結束。Actions run 37566369060 的 Run complete suite 步驟為 macOS 290s（03:21:50Z–03:26:40Z）／Ubuntu 112s；macOS job 306s。相同 macos-15 step 的前版 run 37512573724 基線為 470s／job 484s，單次 hosted 比較分別縮短約 38.3%／36.8%，不套用本機 32-core 的約 59% 比例。新 macOS 各 shard elapsed 為 225／111／238／289／251s，review 仍是最長段；可作後续配平依據，不新增本批實作。補驗 parallel 133.629s 的完整 input snapshot 前後一致，test-evidence helper REUSE／environment matched；raw local evidence 與雙 OS logs／API timestamps 保存在 /tmp/project-ci-merge.br78e7rr/。這是 implementation／required CI 驗收紀錄；結案文件 candidate 與最終 HEAD 的 required checks、PR rebase merge endpoint 尚待，沒有主機部署或 native/model eval。
  - 日期來源:direct
  - 放棄:以本機比例承諾 hosted 加速；因總數相同就忽略 assertions 遺失／重複；用舊 HEAD 的 CI 代替結案提交的 required checks；在 merge 前記錄已送出；順便結案 Runtime 工作或部署 fleet
  - 重議:後續同平台多次量測有顯著變異、review CPU／I/O 瓶頸、環境／來源 drift 或新跨段依賴時，先量測再調整並重驗完整集合與 exit；provider gate 未通過時維持 endpoint pending
  - 關聯:#278;291a029aaa0d6091cd91e25c08d8163a2fc5e883;M-20261007-ci-confidence-local-validation;M-20261007-ci-section-profile;M-20261007-ci-shards-local-validated;D-20261007-ci-measured-integration-split;docs/testing-contract.md;https://github.com/jjshen-eland/dotfiles/actions/runs/37566369060/job/112614904224;https://github.com/jjshen-eland/dotfiles/actions/runs/37566369060/job/112614904536

- **M-20261007-deep-review-primary-local · 2026-10-07 Deep-review primary responsibility 修復通過本地驗收**：#274 在 feature branch fix/deep-review-primary-responsibility 先保存 39-file／12–14–13 projection 與 incomplete structured report retention RED，再完成 structured disjoint primary admission、完整 aggregate immutable context、責任／completion 投影與 failed-set evidence 保留；ordinary subject responsibility 與既有 attempts／repair budgets 不變。11 個新 primary checks、23 個既有 controller checks、48 個 turbo checks 與雙入口 validators 通過。真實 Codex／Claude CLI native 矩陣共 12 fresh cases／32 reviewer identities：8 positive valid sets、3 expected own-required-fact BLOCKED、1 a4 ignored bytecode readonly RED 保留；原始 reports、process／session proof、frozen inputs 與 journal 已逐項核對。Blind f0–f3 的初始 Git metadata RED 另促成先獨立讀 references 再 inspection 的 loading barrier；fresh f4 的實際兩位 reviewers 與 aggregate PASS，parent pre-first-call 所有 target／Git entries content／mode／size／mtime_ns 完整一致。最終 ./tests/run.sh terminal exit 0、1575 PASS／0 FAIL（426s），raw /tmp/project-274-packaging-final-suite.log；前一 thin-entry 32 行 RED（1574／1、exit 1）保留，僅 token-identical reflow 回 29／30 行，未放寬 gate。治理 ship audit／xref 通過，plan 標 implemented 並凍結，active delivery pending 保留。Authority executor／steward／actor 均 codex:runtime-layout-convergence、active-writer-workspace-match／PASS；Runtime 目錄收斂 active item 對 HEAD 逐字相同。Native facts SHA256 5179ade2e378e99528745503615a58b93132dc7db80b312e8cd4d13bee4f19b5，f4 preservation SHA256 f0dce3064f1da98b90916bb9ce84d9a46f58edaec7d7cef232d303b7fef9bf9a。Codex CLI 0.160.1 的 native default resolved model／effort／tier 未曝，不猜具名模型；Claude CLI 2.1.291 實際 claude-opus-5-5[1m]／high(argv)／standard(usage)。未 commit／push／PR／merge／部署，未執行本批 GitHub 雙 OS required CI，原 NC batch／nonce／journal 未重跑或改寫。
  - 日期來源:direct
  - 放棄:以 broad packet 的其他 assignment 未查區域誤判 own incomplete；以縮小 aggregate subject 或忽略 own required facts 換 complete；把 fake transport／model 自評／author summary 算 native acceptance；刪除 bytecode／metadata RED、重建 failed batch 或退還 attempts 洗綠；以本地驗收冒稱外部交付
  - 重議:後续具名 delivery 的 required CI、環境／來源 drift 或新的 primary／readonly／identity 可重現 failure 時，保留原始 evidence 並先重現後修；原 NC live review 只有當批明示授權才重開
  - 關聯:#274;D-20261007-deep-review-primary-responsibility;X-20261007-review-python-isolated-bytecode;X-20261007-review-git-status-index-mtime;docs/plans/2026-10-07-deep-review-primary-responsibility.md;shared/skills/deep-review/evals.md

- **M-20261007-deep-review-primary-contract · 2026-10-07 Deep-review primary responsibility active contract 通過驗收並結案**：#274 的 7 項 AC 已有真實 controller regression、雙端 native matrix、原始報告／process／session／journal audit 與 blind pre-first-call metadata evidence，詳 M-20261007-deep-review-primary-local 與 frozen implementation plan。使用者本輪明示 $project --merge；先以 implementation commit d36d2b7ea5f22d4196d964423844d29074b1eb9e 保存本項 active assignment，再由同一 steward 在 direct-child 結案 candidate 移除本項。Runtime 目錄收斂仍 active，原 Writer／Workspace／Steward 與內容保持，並未結束 codex:runtime-layout-convergence workline。補驗 ./tests/run.sh terminal exit 0、1575 PASS／0 FAIL（421s），708 個完整 repo inputs 前後 snapshots 一致，test-evidence 回 REUSE／environment matched；raw／normalized evidence／rebuild runner 位於 /private/tmp/project-274-merge-fcyacqs2/。新 plan 的 trailing blank 只作 token-identical pre-commit 格式修正，相關 doc audit／xref 已補驗 REUSE；實作未再改動。Retained native audit 亦重驗 12 cases／32 fresh identities、facts SHA256 5179ade2e378e99528745503615a58b93132dc7db80b312e8cd4d13bee4f19b5 不變，current input evidence REUSE；不新增 native dispatch、不重開 failed batch。Pre-completion authority executor／durable steward／actor 均 codex:runtime-layout-convergence、current-session-workline-binding／PASS，parent assignment fingerprint 94fa4251025f212125f69be135a3594d8e989ed7b584aae491158a59cea433a5。結案 candidate 的 authority／doc／required CI 與 PR rebase merge endpoint 尚待，這筆只記當時本地驗收与 contract lifecycle，不宣稱已送出；部署與原 NC batch 重跑未包含在本輪。
  - 日期來源:direct
  - 後續:移除 active item 後首輪 adopted audit 取得 xref RED exit 1，凍結 plan 引用原 STATUS 標題。只在 STATUS 歷史入口保留原標題與結案 record／spec commit 指向，凍結 plan 不改；原 audit evidence 位於本批 completion-doc-audit-evidence.json，修後需重驗。
  - 放棄:在同一 commit 建立又刪除唯一 active assignment；把零 active 或 branch-derived actor 當結案權限；因實作結案而一併移除 Runtime 工作或退役仍被引用的 steward；以摘要取代輸入一致的 test evidence 或冒稱 required CI 已通過
  - 重議:當批 direct-child completion authority、required CI 或 provider gates 未通過時維持 endpoint pending；新來源／環境 drift 或可重現 scope／readonly／identity failure 先重現後修，依同 PR bounded repair 規則接續
  - 關聯:#274;M-20261007-deep-review-primary-local;D-20261007-deep-review-primary-responsibility;X-20261007-review-python-isolated-bytecode;X-20261007-review-git-status-index-mtime;docs/plans/2026-10-07-deep-review-primary-responsibility.md;d36d2b7ea5f22d4196d964423844d29074b1eb9e

- **M-20261007-runtime-deployment-output-local · 2026-10-07 Runtime 日常部署摘要通過本地驗收**：feature branch fix/runtime-deployment-output 先保存 unchanged 仍印 36 行 JSON 的隔離 RED，再以明示 --summary 串接共用 entry。正常成功只印一行；migration 明細含每個 committed root／transaction／receipt／retained backups；partial success、未知 ownership、writer／process inventory 失敗保留完整 JSON 與原非零，guidance／config failure 不消失，直接 layout CLI 仍預設 JSON。Runtime isolation 由 26 增至 33 個 unittest cases，全部通過，外層 shard assertion 數不變；缺 CLI 的獨立 PATH control 先重現新測試的過度指定，再修成功行預期，formatter／migration 不改。初輪 serial 1575／0、446.364s evidence 保留；最終完整 serial exit 0、1575 PASS／0 FAIL（447.404s），parallel exit 0、1575 PASS／0 FAIL（174.978s），五 shards 172／239／112／384／668。349 個 tracked 檔案內容在各 runner 前後及兩 runner 間一致，未放寬 aggregate／exit 判準。Raw logs／inputs 位於同機暫存 runtime-summary-validation-q4tdaemi；serial-final-evidence.json SHA256 497a3a36fcbc2fea1be05bfed9b76fb3392e3f2b5eaf7031780e19bbbe0a20b1、parallel-evidence.json SHA256 61fc579428c1cadbf6165f429d56d17605a27cb7e8b96d40abc66747c273b007。全套後只補驗收文件再獨立 audit，不倒填 inputs。本批無 live apply、brewup 套件更新、native/model probe、push／PR／merge 或 fleet 部署；legacy fallback cleanup 仍未完成，Runtime active contract 不結案。
  - 日期來源:direct
  - 放棄:直接吞掉成功與失敗的所有 stdout；以本機已安裝雙 CLI 的單一情境當 portable oracle；為了摘要放寬 writer／ownership／transaction 或 caller exit 契約；用初輪舊測試版本冒稱最終 candidate 已驗
  - 重議:本批取得 shipping／部署授權後按 repo 流程續行；新來源／環境 drift 或可重現摘要遺失診斷時先重現後修，完整 native 驗收與 legacy cleanup 另依原範圍完成
  - 關聯:D-20261007-runtime-deployment-summary;runtime-layout-convergence;scripts/ensure-runtime-layout.py;scripts/ensure-runtime.sh;tests/runtime-layout.py;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261007-inventory-handoff-cleanup-ready · 2026-10-07 Inventory 十四台 handoff legacy cleanup 遷移前提通過**：依使用者指定，透過 inventory helper 取得 14 目標，以唯讀 SSH probe 核對當前 committed layout source、正式／舊 store、檔案 manifest、receipt／backup、lock／stage 與真實程序 inventory。14／14 正式 ~/.agents/handoffs 為實體目錄、~/.claude/handoffs absent、handoff plan unchanged，parents 實體、無 handoff lock／stage／invalid receipt；每台一個 handoff receipt 且均 committed。macs／eagle06／macmini 分別有 18／6／1 archive Markdown，其他 11 台零檔，全 fleet 無 active Markdown；四台 macs／eagle06／db01／macmini 的 retained backups 與各 receipt before 完整指紋相同，canonical 檢查前後相同。雙 runtime 實際 adapter helper 14／14 解析到 repo shared helper 且 bytes 等於各自 HEAD，共同 SHA256 b4677a658442b4a6b6dc29d40e4b3d56cd2592a9ccb91c634ce238bc9b885f85。部署 source revision 為 macs 42f4507、eagle08 6ddb7a5、其餘十二台 b6299f5；盤點當時 repo 皆 clean。PR #275 signed UID parser 在全 fleet 真實 ps 與三項隔離 controls 通過：接受 -2 並偵測同 UID daemon、writer 仍阻擋 migration、malformed UID 仍拒絕。本機 dhcp6d UID -2 正常解析，仍列 14 個 runtime writers，其餘目標零 writers；不據此宣稱可在本機 live apply。Probe env 未設 HANDOFF_DIR，限定 shell rc／runtime local settings 掃描沒有 override 或舊路徑字樣，不擴成任意外部啟動環境保證。Raw readers、逐台報告與摘要位於同機私有暫存 handoff-cleanup-inventory-20261007-o2bluqxd；summary.json SHA256 e2ba286810bf1aba647ce966fffa364bff60f3f14ea6035e85d19bb83fdb1a6b，adapters-summary.json SHA256 71aa45e51bd2d1262bd6a39ba1bfa3428b4cc4e65c0e8daba9419f5d9a60e087。未執行 store／survey／apply／pull／套件更新／native CLI 啟動或遠端寫入；此為 inventory 內預設路徑 cleanup 前提盤點，fallback source 仍存在，inventory 外終端、cleanup 行為驗證與交付另待，不結案 Runtime active contract。
  - 日期來源:direct
  - 放棄:用會 mkdir／prune 的 store／survey 冒充唯讀盤點；把 retained backups 當未完成 stage 或刪除它們；以 parser 修正豁免 real writers；由 14 台盤點推論 inventory 外終端或尚未實作的 cleanup 已通過
  - 重議:新增舊 store／lock／stage、receipt／backup／adapter mismatch、source 或 store drift 時重驗受影響目標；實作前依原 plan 保留合法 HANDOFF_DIR 與 archive／metadata readers，額外終端範圍須先釐清
  - 關聯:runtime-layout-convergence;M-20261007-macs-runtime-layout-accepted;M-20261006-runtime-layout-negative-uid-repair;M-20261006-runtime-layout-negative-uid-acceptance;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261007-runtime-output-shipping-candidate · 2026-10-07 Runtime 輸出摘要與 inventory 紀錄交付候選補驗通過**：使用者明示 `$project --merge`，本批鎖定 dotfiles feature fix/runtime-deployment-output 的來源摘要與唯讀 inventory 紀錄，不包含 fleet 部署或 legacy resolver 移除。Authority helper 回 active-writer-workspace-match／PASS，executor、durable steward、authority actor 均 codex:runtime-deployment-output。先查原完整 serial／parallel 日誌與內容 snapshots；原 JSON 缺 standardized command／inputs，test-evidence 判 NEED_TEST，未將当前快照倒填為舊受測輸入。對 d4044af0aca379342f474f66db8025402f7965d0 補跑 bash tests/run-parallel.sh，exit 0、1575 PASS／0 FAIL、170.885s，五 shards 172／239／112／384／668；383 個 tracked literal input paths 含 symlink targets、execution bits 的 490 snapshot entries 在前後一致。正規化記錄含實際 command／exit／output／原 input snapshot／environment，test-evidence 回 REUSE、environment matched。Raw before／after／log／result／reuse 位於同機暫存 project-runtime-output-merge-20261007-_6g4l7ux；parallel-evidence.json SHA256 07a09f84051ddcf1a851d89045a23c6b8bab56d944bd8c93b576c1cfbe197daa。本次全套後僅補 STATUS／原 plan／此 milestone 並獨立補驗 doc／xref，不改程式／測試；PR required CI 與 rebase merge endpoint 在紀錄當下仍待，不宣稱來源已進 main，也不結案 Runtime active contract。
  - 日期來源:direct
  - 放棄:以作者摘要代替可核驗 test evidence；拿目前 snapshot 冒充過去受測 inputs；在 PR／CI 尚待时記錄已 merge；將來源交付擴為 live migration 或 fallback cleanup
  - 重議:本批 required CI／provider gates 失敗則依同 PR 有界修復接續；新 source／environment drift 重驗受影響範圍，兩次 CI 修復提交額度不重設
  - 關聯:runtime-layout-convergence;D-20261007-runtime-deployment-summary;M-20261007-runtime-deployment-output-local;M-20261007-inventory-handoff-cleanup-ready;docs/plans/2026-10-06-runtime-layout-convergence.md

- **M-20261007-macos-archive-metadata-local · 2026-10-07 macOS 打包 AppleDouble 預設與單次覆寫完成本地驗收**：feature branch fix/macos-archive-metadata 先固化缺少環境預設／AppleDouble 忽略／網路磁碟設定的 RED，再修 setup 產出的 .zshenv、既有 Git 全域忽略與 macOS defaults entry；Claude always-on 只加觸發入口，known-hazards 留實測與嚴格打包診斷。實際非互動 zsh 與 bash child 取得 COPYFILE_DISABLE=1；macOS raw archive 無自動 AppleDouble，env -u 恢復，空字串仍抑制；strict flags 加 exclude 去除 xattr headers 與現成雜檔。Python 6 tests exit 0、1 skipped（實際 GNU/Linux tar 僅在 Linux 執行）；Linux defaults guard 以 stub 驗證無 defaults 呼叫，Linux bash 來源未改。完整 ./tests/run.sh exit 0、1576 PASS／0 FAIL、431s，含 shellcheck、bash syntax、doc governance 與 xref；raw log 位於 /tmp/dotfiles-mac-metadata-suite-20261007.log。來源驗收後移除此批 active item，不結案原 Runtime 工作；未執行本機 setup／defaults、主機 fan-out、push／PR／merge。
  - 日期來源:direct
  - 放棄:用 macOS 的 Linux stub 冒稱真實 GNU/Linux tar 已執行；把 COPYFILE_DISABLE 當成清除所有 xattr／現成雜檔；在未交付來源時套用本機或散佈設定
  - 重議:部署另依當批具名授權與 origin/main 前提；實際 Linux archive control 或新工具出現可重現污染時先固化 RED 再修
  - 關聯:D-20261007-macos-archive-metadata;setup-mac-env.sh;git/gitignore_global;write-mac-defaults.sh;claude/known-hazards.md;tests/test_mac_metadata.py

- **M-20261008-ci-critical-path-baseline · 2026-10-08 #279 完整基線與既有 hosted 成本完成量測**：從 c433abe2a1438ad8af8e8c1a8034f86e2f29f409 作 no-local clone，疊入當時兩份自有 spec 文件並保存 baseline-overlay.patch；正式 code 未改。本機 macOS arm64／32 logical CPUs，外部 observer 用 monotonic clock 與 0.05s stdout section boundaries 量測完整 serial 430.231s、parallel 155.932s，兩者各 1576 PASS／0 FAIL、exit 0；384 個 tracked inputs 的 content／symlink 指紋前後一致，serial／parallel 僅正規化兩個具名 fetch assertions 的實測秒數後多重集合相同，原始日誌及 6s 判準保留。Parallel core／ship_state／plan／review／runtime 為 41／55／101／156／109s；serial deep-review 106.050s，其中 controller suite 77.183s、primary scope 27.857s，deep-plan 83.133s、turbo 43.953s。Section 是含子程序等待的 foreground wall time，不能當 CPU exclusive time；parallel 的彙總 log timestamps 不用於 section timing。
  - 日期來源:direct
  - 證據:三輪既有 hosted run 37566369060／37567493290／37625167880 的 macOS suite／job 為 290／306、318／347、460／479s，Ubuntu 為 112／130、89／122、138／157s；六個 jobs 都以 review 最慢，來源 HEAD 各異，不視為同來源穩定性對照。API 未揭露純 queue time；job start delay 只列含排程／啟動的觀察值，不冒充純排隊時間。完整來源、環境、原始 logs、384-entry snapshots 與 rebuild argv 位於 /tmp/dotfiles-ci-profile.a7iOFZ/{serial-baseline-1,parallel-baseline-1}/result.json、hosted-summary.json；重建需 no-local clone 該 HEAD、apply baseline-overlay.patch，再以 observe.py <clone> <new-output-dir> all 或 parallel 執行。Observer 與 build scripts 同置該目錄，僅本工作暫存證據，未新增 repo store。
  - 放棄:用 hosted 彙總輸出的行時間當區段耗時；把不同來源的三輪耗時視為候選加速證據；以本機 32-core 比例承諾 hosted 改善
  - 重議:來源／環境 drift、重複對照變異，或 controller 移位改變 fixture／完整集合時，回到原始日誌與 frozen snapshots 查證
  - 關聯:#279;D-20261008-ci-critical-path-before-selection;M-20261007-ci-required-accepted;https://github.com/jjshen-eland/dotfiles/actions/runs/37625167880/job/112804967002;https://github.com/jjshen-eland/dotfiles/actions/runs/37625167880/job/112804967244

- **M-20261008-ci-critical-path-measurement-complete · 2026-10-08 #279 保守縮時量測與相容候選驗收完成，正式採用另待**：core 修正版三組完整 parallel 及完整 serial 均 1576 PASS／0 FAIL、exit 0；與基線的具名 assertions 多重集合相同，無遺失／重複，384 個 tracked contents／symlink 指紋前後一致（未把 permission bits 算進 fingerprint）。Legacy integration 實跑 1164／0、exit 0，集合與原順序均相同，修復初版漏測。獨立失敗副本令 controller exit 23，core 正確回 exit 1、173 PASS／1 FAIL，原診斷可見。既有 confidence suite 的 SIGTERM／SIGINT／child failure、spawn-race descendant cleanup 與 Bash 3.2 空 child array controls 隨完整測試通過；supervisor／聚合器／controller 23 cases 及 primary scope suite 的 bytes 未改。
  - 日期來源:direct
  - 契約保全:原 work item 為「CI 最慢分片量測與保守縮時驗證（#279）」；Writer／Dossier Steward codex:macos-archive-metadata，branch=docs/ci-critical-path-spec、Write Scope none。Goal 是交付有完整覆蓋及成本證據的建議，無收益亦可停止。驗收為 frozen SHA／inputs／環境與重建、最多兩候選及至少三組交錯對照、serial／parallel／受支援入口集合及失敗／signal／cleanup、變異與收益／成本判斷、既有 history／audit。使用者「開工」僅授權量測、repo 外隔離試驗與同項文件維護；不含正式 code 修改、commit／push／PR／merge。未新增 selector／治理或量測 store／skill 內容，branch protection／required check／雙 OS 完整 suite 與部署設定未改，無主機 fan-out。Runtime active item 不接續、writer／scope 不變；本量測項移出 active state，後續正式修改 tests 前須重新核對重疊 writer／scope 與授權。
  - 結果:baseline 中位數 181.6935s、範圍 164.3495–190.4371；候選 117.6620s、116.8221–118.0903；差 64.0315s／35.241%，配對省 47.5274／63.6032／72.7751s。三組原值、選擇／不選 ship、成本估計與有條件採用理由見 D-20261008-ci-core-controller-recommendation。本機 macOS 26.7.1 arm64、32 logical CPUs、512 GiB RAM、Python 3.14.8、Bash 5.3.20、Git 2.56.0、ripgrep 15.2.0、yq 4.54.1；各完整環境版本留在 result.json。Functional serial 410.845s 與失敗控制有短暫重疊，integration 389.4559s；這兩個 elapsed 僅是驗證記錄，不當縮時對照。全部配對效能量測在其前完成且逐一執行。
  - 證據與重建:暫存 /tmp/dotfiles-ci-profile.a7iOFZ 的 README.txt、evidence-files.sha256、frozen-trial-fingerprints.json、paired-v2-summary.json、serial-core-v2-validation、integration-core-v2 及 integration-core-v2-coverage.json、core-v2-driver-failure 及 failure-control-v2-summary.json；原始 raw.log／結果／來源 snapshots 均保留。No-local clone c433abe2a1438ad8af8e8c1a8034f86e2f29f409，開 reproduction feature branch，apply baseline-overlay.patch；以 observe.py <repo> <new-output> all／parallel 得基線，再 apply trial-core-v2.patch（SHA256 見決策）取得候選，另跑 integration。Compare.py 只正規化兩條具名 fetch 訊息的實測秒數，保留 success／failure 與 6s 判準；check_integration.py 另比原順序；failure_control_v2.py 的故障副本不影響 frozen 候選。這些 scripts／raw evidence 是本機暫存交付，不是新增 repo 常設機制。正式 repo 最後完整 ./tests/run.sh 為 1576／0、exit 0，具名 assertion 集合與基線一致、tracked contents／links 在該 run 前後一致，正式 code 與來源 SHA 未改；raw／snapshot 與獨立比對由 root-final-validation/{raw.log,result.json}、root-final-coverage.json 保存。測後僅校正本筆 unittest methods 為 23（AST 盤點）並填入結果 metadata，不改節名／權威位置；文件 audit 由既有 scanner 補驗。
  - 放棄:繼續第三候選／依賴圖選測；把初版不完整入口當可採用；以本機 35% 承諾 hosted 同幅改善；把測量完成冒稱實作或 CI 已交付
  - 重議:正式採用須取得本批 code／commit 授權，先處理 tests 既有 writer 的重疊範圍，再落地三檔小改與必要驗證。Hosted CI 需另具名 shipping 授權後觀察 macOS／Ubuntu 完整 suite／job；同來源、相同條件的 provider 效能證據仍缺，純 queue API 缺項仍保留。Hosted 未改善／回退時回復原分配，不擴成選測器；#279 未關閉。
  - 關聯:#279;D-20261008-ci-critical-path-before-selection;D-20261008-ci-controller-shard-trials;D-20261008-ci-core-controller-recommendation;X-20261008-ci-shard-move-integration-coverage;M-20261008-ci-critical-path-baseline

- **M-20261008-ci-controller-core-local · 2026-10-08 #279 Controller 靜態重分配完成本地採用驗收**：在 feature branch docs/ci-critical-path-spec 套用已驗 core 候選；tests/run.sh 抽成唯一 run_review_controller helper，core 同步執行，legacy integration 在原位置執行。Controller body、23 cases、timeout、supervisor、聚合器、workflow 與其餘 assertions 未改；manifest core／ship_state／plan／review／runtime 為 174／239／112／383／668，合計 1576。docs/testing-contract.md 記錄新歸屬、隔離 fixture 及 all 的分片執行順序，未新增 selector、benchmark、skill 規則或分片。
  - 日期來源:direct
  - 契約保全:原 work item 為「CI controller 靜態重分配本地採用（#279）」；Writer／Dossier Steward codex:macos-archive-metadata，branch=docs/ci-critical-path-spec，Write Scope tests/run.sh、tests/shard-manifest.tsv、docs/testing-contract.md。使用者選擇 1「正式採用，完成本地修改、驗證與 commit」，只授權本批本地終點；原 Runtime writer 停止已記於 STATUS，三檔由本 writer 接手、其餘 Runtime 工作不續作。Goal 是完整覆蓋及 legacy integration 語意保持後在 feature branch commit；驗收為候選 bytes／測試內容不變、clean clone 完整 parallel 與正式 checkout 完整 serial 各 1576／0 且 inputs 穩定、具名多重集合一致、以相同程式 bytes 核對既有 integration 順序及失敗／signal／cleanup controls、history 保存並移除 active item、文件 audit／diff 通過、只 stage 七個具名檔案並檢查 cached diff。七檔為上述三檔、STATUS.md 與當月 decisions／dead-ends／milestones 三個 history shards；前階段自有量測文件隨本批保存。無 push／PR／merge／部署授權，不承接前批 shipping。
  - 驗證:git clone --no-local 的乾淨副本 apply exact staged patch 後，index tree 與來源同為 5af3fe7191b0f06424235826c26f99d2f62e4c88；完整 parallel exit 0、1576 PASS／0 FAIL、120.5874s。正式 checkout 完整 ./tests/run.sh exit 0、1576／0、435.7915s。兩套具名 assertion 多重集合與 frozen 基線相同，只正規化兩條既有 fetch assertions 的實測秒數，保留原日誌與 6s 判準；384 個 tracked content／symlink 指紋在各 run 前後相同，不包含 permission bits。Runner／manifest 與候選 bytes 相同，全部 tracked code 與先前 integration-core-v2 受測來源相同，故重用已實跑 integration 1164／0、原順序及 controller exit 23 → core exit 1／173 PASS／1 FAIL 證據；既有 signal／cleanup／Bash 3.2 controls 隨完整 suite 再驗通過。全套後僅結案 dossier，程式／test contract 不再變動；結案後 core 分片 174／0、exit 0、106.9002s，含完整 repo 文件／xref gates，inputs 前後一致，證據保存於 core-dossier-final。測後僅補此驗證結果，文件 audit／diff 檢查另驗。
  - 證據與重建:同機暫存 /tmp/dotfiles-ci-adopt.2y1f3gs1 保存 staged.patch、clone-source.json、parallel-clean-clone／serial-formal 的 raw.log／result.json、parallel-coverage.json、serial-coverage.json 及 prior-controls-reconciliation.json。No-local clone c433abe2a1438ad8af8e8c1a8034f86e2f29f409，在 feature branch apply staged.patch，再用 /tmp/dotfiles-ci-profile.a7iOFZ/observe.py <clone> <new-output> parallel 或 all 重建本次來源驗收；staged.patch 是 dossier 結案前的實際受測來源，不冒稱包含測後紀錄。相容與故障原證據及候選 patch 仍在該 profile 暫存，相關來源已逐檔核對；未新增 repo store。本次 elapsed 僅作驗收紀錄，縮時判斷沿用 D-20261008-ci-core-controller-recommendation 的三組交錯對照，hosted CI 效能尚未驗證，#279 未關閉。
  - 放棄:重新改 controller 測試或 timeout；在程式 bytes 相同時重跑整輪效能對照；以完整 all 取代 legacy integration 的集合與原順序證據；把本地完成冒稱已交付或 hosted 同幅加速
  - 重議:取得本批具名 shipping 授權後觀察 macOS／Ubuntu 完整 suite／job；hosted 未改善或回退時恢復原分配，不擴為選測器。程式、fixture、來源或環境 drift 時重驗受影響 controls；Runtime 後續寫入仍依原 ownership／reassignment 規則。
  - 關聯:#279;D-20261008-ci-controller-adoption-local;D-20261008-ci-core-controller-recommendation;M-20261008-ci-critical-path-measurement-complete;X-20261008-ci-shard-move-integration-coverage;tests/run.sh;tests/shard-manifest.tsv;docs/testing-contract.md

- **M-20261008-brewup-bun-global-update-local · 2026-10-08 brewup bun 全域更新完成本地驗收**：尾段以一次 `bun update -g` 取代 outdated 查詢與表格提示；已安裝 bun 時保留原生命令輸出，無 bun 靜默略過，失敗顯示警告並維持 exit 0。README／repo guide／test contract 與 shard manifest 已同步，原只提示 milestone 保留，由新 decision 明確取代對應政策。
  - 日期來源:direct
  - 契約保全:工作項為「brewup 自動更新 bun 全域套件」；Writer／Dossier Steward codex:brewup-bun-global-update，branch=feat/brewup-bun-global-update。使用者選擇 1 確認原 writer／steward 停止並交接本批；Write Scope 為 scripts/brewup.sh、tests/run.sh、tests/shard-manifest.tsv、README.md、docs/repo-guide.md、docs/testing-contract.md，加 STATUS 與本月 decision／milestone 維護。Goal 為已安裝 bun 時納入原生全域更新；驗收為每次只執行一次 update -g、成功輸出可見、無 bun 略過、失敗診斷／警告與 exit 0、fixtures 全隔離、文件／history 同步、完整 serial／parallel 及 audit／diff 通過後本地提交。只授權本批本地修改、驗證與 commit，不執行真實套件更新／fleet 部署，不含 push／PR／merge，不加 --latest，也不接續 Runtime 遷移。
  - 驗證:先更新隔離 oracle，舊碼 runtime shard 為 664 PASS／5 FAIL、exit 1；失敗集中在命令未執行、成功輸出、失敗診斷與警告，無 bun control 仍通過。修後 10 個 bun 斷言全綠；完整 ./tests/run.sh 為 1577 PASS／0 FAIL、exit 0，完整 ./tests/run-parallel.sh 合計同為 1577／0、exit 0（runtime 669，manifest 同步）。Bash 語法、標準 suite 的 ShellCheck 與文件 gates 均通過；受測 patch 在兩套測試期間保持一致。結案後僅移除本 active item 並保存紀錄，程式與測試 bytes 不再修改；文件收尾 core 分片再驗 174 PASS／0 FAIL、exit 0，final doc-governance audit 與 diff 檢查通過。
  - 證據與重建:同機暫存 /tmp/brewup-bun-red.log、/tmp/brewup-bun-serial.log、/tmp/brewup-bun-parallel.log、/tmp/brewup-bun-core-final.log 與 /tmp/brewup-bun-tested.patch。以 27fc2ad3cb769b2344a0277aecb87c6ba5c28e43 建 feature branch、套用該 patch，再執行兩個完整 runner 可重建受測候選；patch 含結案前 active spec，不冒稱包含測後紀錄。
  - 放棄:以 outdated 表格作更新前置；新增跨範圍 --latest；更新真實環境作測試；以本地驗收宣稱來源已合併或已部署
  - 重議:另取得當批具名來源交付或部署授權後，依 repo shipping／origin/main 散佈規則處理；版本策略或 exit 契約改變時依新需求調整
  - 關聯:D-20261008-brewup-bun-global-update;scripts/brewup.sh;tests/run.sh;tests/shard-manifest.tsv;docs/repo-guide.md;docs/testing-contract.md;STATUS.md

- **M-20261008-workflow-verification-economy-local · 2026-10-08 #285 本地候選通過驗證**：把既有 18d 隔離 oracle 抽成共用獨立入口，Project evidence check 增加 compact 輸出，root 測試指引約束普通腳本一次完整驗證與測前來源保存、結果補記沿用。未改 hosted CI、selector、授權或 required checks。
  - 日期來源:direct
  - 契約保全:工作項 issue-285-workflow-verification-economy，Writer／Dossier Steward codex:brewup-bun-global-update，branch=perf/workflow-verification-economy，基線 92dc1b9c6e6a836146606d3cee12edd2505ecef6。使用者以「開工」授權本地診斷／修正／驗證，再選 1 將必要 tests/ 與 docs/testing-contract.md scope 交給本批，原 Runtime writer 保持停止；其餘 scope 為 shared/skills/project/、AGENTS.md 與既有 dossier／plan／history 維護。不含 commit／push／PR／merge／部署；active assignment 保留供後续 gate，plan 仍 in-progress 等真實交付量測。
  - 行為與成本:原樣 18d 對舊碼 29 PASS／5 FAIL、6.895s，現行 34／0、5.828s，取代原 runtime RED 的 108s 取得同組控制；獨立入口回歸另守 repo 外初始化。443-input 真實 record 的 full／compact verdict 及完整 changed_inputs 相同、exit 1，輸出 19,894→648 bytes；摘要不裁 snapshot 或未知／錯誤判定。一般脚本 native before 的 Codex 冗餘 serial＋parallel 2 次，v2 各端完整 1 次並保存一致測前／測後來源與真結果；docs-closeout 各端零新完整，Log reuse／changed／unknown 新測試次數各 0／1／1。Opus v1 snapshot 失敗仍重跑全套的 RED 保留，以測前 fail-fast 窄修正後只重測 ordinary。
  - 驗證:Python 3.14／3.9 的 evidence 15 tests、ShellCheck、CI confidence 11 tests、metrics 7 tests 通過；Codex validator PASS，Claude entry 由原生 CLI／repo packaging 驗證，未修改的 Claude frontmatter 不適用 Codex validator，未冒稱其 PASS。雙端 production target 為 gpt-6.1-sol／claude-opus-5-5[1m]，alias／resolved model、effort／tier／CLI version 於 native argv／summary。完整 serial／parallel 各 exit 0、1578／0、453.544499／137.808644s，695 個來源與環境前後一致；兩者重疊，wall time 不相加或當效能對照。Runtime 669 保持、core 新增一個 aggregate assertion 至 175。後续僅結果補記，另補 fresh 文件 gates，不再跑 core／全套。
  - 證據與限制:docs/plans/2026-10-08-workflow-verification-economy.md 與 Project Scenario 42 保存原始 before／v1 FAIL／v2 的 roots／判準；/tmp/workflow-285-final-verification 保存實際測前／測後 snapshot、logs、summary、environment、evidence、code projection、tested patch 與新檔 content／mode。小 native fixture 的 before→v2 wall time Codex 86.313→190.082s、Opus 34.961→67.141s，保存證據增加模型成本，不能宣稱 native 總 latency 下降。必要 references 未縮減；Codex ordinary 仍兩次輕量 doc check。尚未量測新候選的開 PR／hosted CI／merge／同步收益，不宣稱原 15 分鐘問題已全部解決。
  - 放棄:減少斷言或略過全套換速度；普通腳本自動套 runner parity；測後補造過去來源；一律排除 ignored 檔；永久 cache／新治理 store；以 fixture 結果估真實 merge 耗時
  - 重議:本批交付後再量測固定流程與證據準備成本；來源、fixture、必要 link target 或環境漂移時補受影響檢查。#279 hosted selector 另做，不擴大本項或接續 Runtime。
  - 關聯:GitHub #285;docs/plans/2026-10-08-workflow-verification-economy.md;shared/skills/project/references/pressure-tests.md;AGENTS.md;docs/testing-contract.md;tests/brewup-tests.sh;tests/test_brewup_entry.py;shared/skills/project/scripts/test-evidence.py

- **M-20261008-workflow-verification-economy-delivery-measured · 2026-10-08 #285 第一批交付及完整時間核對**：PR #287 已 rebase merge 到 origin/main，commit 112d37de7bdc2854f6a7d49e6e20a17bb4be3f57；本地 main 同步與本支清理完成，續 dotsync 本機及 inventory 14 台全成功、exit 0。不是 actor retirement，#285 與 Runtime 的既有 stewardship 保留。
  - 日期來源:direct
  - 驗證:原始成功證據與環境核對沿用，交付沒有新跑本地全套；尾端空白修正另驗 bash syntax／ShellCheck／18d 34 PASS，前後 inputs 一致。Ubuntu required CI 116 秒、macOS 197 秒，均一次通過，CI 修復提交 0 次；merge 前 non-watch required checks exit 0、exact PR HEAD／identity 與 CLEAN 狀態重查。
  - 量測:原始 user timestamp 18:03:11.481 到 final 18:23:29.878（Asia/Taipei），1218.397 秒；host ContextCompaction 386.375 秒，恢復到 PR 400.165 秒，PR 到 merge 256 秒，merge 到同步 25 秒，同步後紀錄與回報 75.878 秒。先前 1113 秒為首筆 clock 到同步的下界，完整邊界現已補足，不能拿下界比較完整交付。直接扣 compaction 的 832.022 秒是算術分解，非無 compaction 對照。
  - 接續:使用者同意診斷固定成本、同案例驗收與回填既有 issue／STATUS。恢復段含必要 ref 重讀、證據查證、staged check 非零後仍 commit 的修正、dependent HEAD／gate 錯誤平行與非 Git 輸出 OID 的重查。後兩者屬既有紀律偏離；只有新的 frozen native RED 才改 workflow，不為一次失誤追加規範。#285 仍 in-progress，總 latency 未改善，不移除 active 或未解決 backlog。
  - 證據:docs/plans/2026-10-08-workflow-verification-economy.md；/tmp/workflow-285-final-verification/shipping-session-measurement.json；原始 rollout-2026-10-08T15-08-21-01a11a57-75bb-7da1-b85e-9714aaa2952f.jsonl；PR #287／Actions run 37762509491
  - 接續控制:固定 92dc1b9／112d37d 的 gpt-6.1-sol 本地 README 收尾各沿用真實證據、0 新測試、1 feature commit、working tree clean、remote refs 未变、source hashes 穩定；preflight 均修正空白並通過後才提交。Before 130.384 秒／22 次工具呼叫，after 103.022 秒／19 次；各 12 reader calls、七份 refs 完整。只有一組小 fixture 且同機並行，未含 production PR／CI／compaction，不外推 latency 收益。失效的 .git 寫入隔離樣本與 stdin 污染樣本保留、不計正式比較。Normalized grade：/tmp/workflow-285-final-verification/prepared-closeout-grade.json。
  - 結果:GitHub #285 驗收條件 2–6 已回填，1 仍未完成、issue 保持 open。Production 執行紀律偏離已確認，正常控制未重現需新增規則的缺口；本輪只補記實測，無 skill／runner 改動。本地結果文件未 commit，未新增 push／PR／merge／部署。
  - 放棄:以 ignored 身分排除真實 inputs；以扣除 platform compaction 宣稱實測改善；削弱 authority／required CI 或追加無 RED 的規範
  - 重議:固定 source／同案例的操作與 wall time 驗收完成後判定下一個有證據的最小修正；新批 push／PR／merge／部署另需授權
  - 關聯:GitHub #285;PR #287;M-20261008-workflow-verification-economy-local;docs/plans/2026-10-08-workflow-verification-economy.md;STATUS.md

- **M-20261009-workflow-verification-economy-call-timeline · 2026-10-09 #285 開 PR 前工具區間量測**：使用者「繼續」後，沿原始 session 補完恢復到 PR 的 400.165 秒操作時間線；沒有新增修補或規範。
  - 日期來源:direct
  - 量測:30 次 call-return 區間合計 13.324 秒，納入可見背景命令且合併重疊後 21.235 秒；378.930 秒在可見區間外。Entry／refs 42.822 秒、盤點到初次 commit 169.738 秒、空白修正與第二次 commit 111.412 秒、HEAD／authority 修正及 PR 準備 43.311 秒、push／PR 32.882 秒，總和 400.165 秒。
  - 證據:原 session custom_tool_call／output、CommandExecution、GitHub PR #287 createdAt；/tmp/workflow-285-20261009-call-timeline/timeline.json 保存 source SHA、命令／exit、精確區間與 output bytes／截斷標記。Call 11 盤點與 call 17 staged diff 兩次截斷後局部重讀可核對。
  - 限制:區間外不是純模型思考，零寬 command record 不是完整 subprocess 計時；PR 時戳為秒級。操作區段不是可刪成本，三份結果文件的後續交付不等於原 15-file 實作的同規模對照。UNCONFIRMED，驗收條件 1 保持未完成。
  - 下一步:三份本地結果文件準備交付；新批 push／PR／merge 另需具名授權，舊 PR #287 merge endpoint 已完成，不從「繼續」推導 outward 權限。不擴至 #279／Runtime。
  - 關聯:GitHub #285;PR #287;M-20261008-workflow-verification-economy-delivery-measured;docs/plans/2026-10-08-workflow-verification-economy.md;STATUS.md

- **M-20261009-workflow-verification-economy-revert-local · 2026-10-09 #285 整批退版本地候選通過驗收**：依使用者明示完整撤回 PR #287 的流程／測試實作及後續空白修正，十二個非紀錄路徑內容與 mode 均還原至 92dc1b9c6e6a836146606d3cee12edd2505ecef6，三個新增測試檔移除；bun 全域更新與 #279 保留。serial／parallel 各 exit 0、1577 PASS／0 FAIL（core 174、runtime 669），測試前後 source patch／status 未變；治理／xref 與 Codex validator 通過。原量測、plan 與 history 保留，追加退版決定；不宣稱總耗時目標已達成。此為本地候選驗收，尚未 push／PR／merge／dotsync，active assignment 保留到具名交付。
  - 日期來源:direct
  - 證據:/tmp/workflow-285-revert-o4xlch4g/{serial.log,parallel.log,results.json,tested.patch,source-check.json}；兩 runner 同機並行，wall time 414.585／126.955 秒不作前後效能結論
  - 關聯:X-20261009-workflow-verification-economy-revert;docs/plans/2026-10-08-workflow-verification-economy.md;Issue#285;PR#287;PR#288
