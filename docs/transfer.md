# Dotfiles 移交指南：delivery-overhead

> 移交準備日：2026-10-10
> Normalized invocation arguments：`transfer resume=codex:brewup-bun-global-update to=claude:delivery-overhead`
> Recorded preparation state：`PREPARED`
> Current steward：`codex:brewup-bun-global-update`
> Next steward：`claude:delivery-overhead`
> Canonical handover endpoint：`git@github.com:jjshen-eland/dotfiles.git` 的 `main`
> Conditional owner record：[D-20261010-transfer-delivery-overhead](archive/decisions-2026-10.md)
> Effective condition：包含本指南、全部 active-item 原子切換及 conditional owner decision 的 transfer commit 已 merged 至上述 endpoint，且 remote-visible ancestry 驗證通過。
> Effective transfer state：包含完整切換的 transfer commit 尚未抵達上述 endpoint 時為 `PREPARED`；remote-visible ancestry 證明抵達時為 `TRANSFERRED`。Recorded preparation state 保留準備事件，不於 merge 後改寫。

## 0. 準備結論與 runtime drift 處置

| 項目 | 已知事實 | 決定 |
|---|---|---|
| 主 checkout 的未提交 settings 變更 | `claude/settings.json` 相對本次基線新增 `modelSettings`、`skipWorkflowUsageWarning`；未輸出設定值，未拷貝至本移交 branch。當前 SHA-256 為 `8ae34a4189d3ea83bf22ef5db1a939c9c2a430842330251d03c3605b706aa638`。 | 使用者於 2026-10-10 明示「那是runtime drift」；依此確認將本機 runtime drift 排除於移交，原 checkout 保留原檔與 hash。此項 blocker 已解除。 |

本次 preparation 已達 `PREPARED`，目前沒有未解 blocker。Guide 記錄 pending transfer 計畫；
在包含完整切換的 transfer commit 抵達 canonical endpoint 之前，current steward 仍是唯一
shared-dossier authority，next steward 不得先寫。本次後續 Log 將所有 active coordination fields 與
上述 conditional owner record 收在同一 transfer commit；commit 抵達 endpoint 前，next fields 僅為 pending values。
本次移交涵蓋 `STATUS.md` 的三個 active items。接手後優先處理 item 3（#285）的完整交付耗時，
其他兩項保留各自未完成目標及限制。任何原 writer 的新 in-flight work 都要重新盤點；
不能靠本指南讓未整合工作自動成為接手者的負責範圍。

## 1. 系統全貌與權威入口

本 repo 是 macOS／Ubuntu 的 dotfiles、14 台 inventory 主機部署來源，以及 Claude／Codex
雙薄入口與 neutral shared skill core 的共同來源；目前工作以測試／交付成本、runtime layout
及 setup 工具歸屬為主。

- 行為與 Git 契約：[AGENTS.md](../AGENTS.md)；repo 事實與原生 import：[CLAUDE.md](../CLAUDE.md)。
- 安裝與工具入口：[README.md](../README.md)；SSH／runtime／環境 runbook：[repo-guide.md](repo-guide.md)。
- Active／paused 與 coordination：[STATUS.md](../STATUS.md)；未結案技術債：[backlog.md](backlog.md)。
- 文檔寫入與檢索：[document-governance.md](document-governance.md)。
- #285 的有效 plan：[workflow-verification-economy.md](plans/2026-10-08-workflow-verification-economy.md)。
- QA 判準：[testing-contract.md](testing-contract.md)；模組宣告：[suites.json](../tests/suites.json)。

### 已驗證的來源狀態

準備基線為 `e8e226dbe8b9818ad9123ac85ec6f25797d3def3`；本次 `git ls-remote --heads origin main`
回同一 full OID，provider 的 default branch 亦為 `main`。本次以 Git ancestry 與來源內容核對：

| 工作 | 已在基線內的證據 | 仍未完成 |
|---|---|---|
| Runtime layout | 既有 rollout／native discovery 結果依 STATUS 與 M-20261007-macs-runtime-layout-accepted；Claude Default 修正 `9d31d8b` 已進 main。 | 額外 MacBook 的識別／revision／原生載入、legacy fallback cleanup、模型設定 fleet 同步仍依原 item 契約。 |
| #285 delivery overhead | Controller 去重 `17efb21204576b13ba0725ca2be1a3a0a6545f21`、deep-plan 批次 snapshot `61afb0d291fb2e996d3901bc5b72792d89b29c81` 已在 main；M-20261009-deep-plan-batched-snapshot-local 保留局部收益與限制。 | 完整交付指令至最終回報、hosted／其他重型模組的成本仍 active；本地模組收益不代表整體完成。 |
| Setup／fleet | 修正 `792f1541775eba9b35693a16868a98c82b86f461`、13／14 紀錄 `632d2ef61c1e8242797d712fab22039a3b7c4258`、14／14 紀錄 `e8e226dbe8b9818ad9123ac85ec6f25797d3def3` 均在 main。 | 舊工具歷史歸屬、用途核對與退役未完成；不自動 adopt／升級／移除。 |

STATUS 與上述 event-time records 的「本地未送出／等待舊批授權」文字是當時的紀錄；
當前已整合的來源以以上 exact commits 與 ancestry 為證據。歷史記錄不改寫，也不提供新的外向授權。

舊 `rescue/root-cause-first-candidate-942034f` 是保留的失敗 candidate：
X-20261005-root-cause-first-completion-provenance 記載受控重建；本次比對其三個產品／eval 檔
與已合併 `e84aa1137b93d16f62f66c56492efbf55100afbc` 無差異。此 ref 不是待移交實作，
不自行刪除或再次整合。

## 1.1 Portable-knowledge audit

- [x] Root contracts、setup／QA 指令、active／paused、backlog、plan 及 history 路由可由 committed repo 定位。
- [x] `.doc-governance.json` 與 scanner 同時存在；worktree 與原 checkout 的 scanner byte-identical，Git common-dir 相同。
- [x] `resume=codex:brewup-bun-global-update` 的 authority helper 回 `PASS`；executor／durable steward／authority actor 均為該 actor，source 為 `explicit-same-runtime-resume`。
- [x] 本 session 已知的來源核對、runtime drift 處置、mapping 與 next steps 已寫入本指南；沒有已知但只留在 private memory 的必要 project fact。
- [x] 未讀取另一 runtime 的 private memory；memory on/off 不影響 QA 或 readiness。
- [x] Active writer 的主要實作與 setup 事後紀錄已在基線；主 checkout 未提交 settings 變更已由使用者確認為 runtime drift 並排除於移交。
- [x] 主 checkout settings 的新增內容已取得明確 disposition，原檔保留。
- [x] 本次 fresh clone QA 完成，30 個模組 exit 0（結果與環境控制見第 3 節）。
- **Known residue**：none；第 0 節的 runtime drift 為已明確排除的本機內容。
- **Instruction promotion candidates**：none；本次沒有新的 safety／Git／cross-runtime preference 需要變更既有契約。

檢索範例（從 repo root 執行）：

```sh
python3 scripts/doc-governance.py find 'D-20261009-ci-system-redesign'
python3 scripts/doc-governance.py find 'M-20261009-deep-plan-batched-snapshot-local'
python3 scripts/doc-governance.py find 'M-20261010-setup-fleet-complete'
python3 scripts/doc-governance.py find 'X-20261005-root-cause-first-completion-provenance'
python3 scripts/doc-governance.py find 'legacy handoff store cleanup MacBook'
```

## 2. 環境建置與 credentials separation

1. 從 canonical GitHub repo clone；先讀 root contracts、README 與 STATUS。核對本指南的基線是否為 clone HEAD 的 ancestor。
2. 用 `scripts/dev-env.sh python3 --version`、`git --version`、`shellcheck --version` 確認 README 所述本地 QA 能力；Python 至少 3.11。agent shell 未載入 startup 時使用 README 的 `dev-env` 入口。缺工具時按 README 的 core setup 指引處理，不以測試成功為理由執行全機隊 setup／更新。
3. 先跑第 3 節的 repo-local QA；這些 checks 不需要另一 runtime 的 private memory、SSH 私鑰或 API key 值。
4. 新機安裝與真實主機 alignment 按 README／repo-guide 的適用流程，另取得當批外向授權；本次準備未執行 setup、登入、SSH、套件安裝、inventory apply 或部署。

Credentials plan：接手者自行使用 runtime 原生登入、既有 SSH agent，或由使用者以密碼管理器
配置其必要存取；沒有 credentials local artifact，沒有秘密交付／權限調整。
本 repo 沒有 tracked `.env.example`／`.env.sample`；等價的非秘密設定入口是 root CLAUDE、
README、repo-guide 與 runtime config。`~/.env`、SSH 私鑰、Git 機器身分與 runtime auth 都在 repo 外。
`.gitignore` 的 `.env`／`.env.local` 保持；本次沒有讀取或複製這些秘密檔案。

本次掃描 tracked regular text files 的常見完整 token 與 private-key 模式，325 個檔案零匹配；
89 個 symlink 沒有追讀外部內容。這是指定模式的檢查，不聲稱枚舉未知 private stores 或所有秘密格式。
若後續改選 local artifact，依 Project credential helper 的 metadata-only gate 驗證，先更新 credential plan。

## 3. Fresh clone QA 與接手驗收

本次 fresh clone 以 `git clone --no-local` 從 committed 準備基線建立，沒有帶入原 checkout 的
settings 變更；僅套用本次移交文件 overlay。以下指令可由接手者獨立重跑：

```sh
scripts/dev-env.sh ./tests/run.sh
scripts/dev-env.sh python3 scripts/doc-governance.py audit --ship
git diff --check
```

- **本次 full-suite 結果**：`scripts/dev-env.sh ./tests/run.sh` exit 0，30 個模組全通過，wall 111.672 秒；415 個 input paths 的 bytes／mode／link metadata 前後一致。
- **當前文檔 audit**：新指南首次因 `unclassified: docs/transfer.md` 被拒；在既有 `project-doc` 清單加入這個 exact path 後，`audit --ship` exit 0，檢索可定位指南與 STATUS 移交入口。最後紀錄文字另驗當前文件內容，沒有重跑未變的程式／測試全套。
- **原生模型／雙 OS／live fleet**：本次未重跑，不將本機 QA 解讀為這些驗收。

環境診斷為 `ROOT CAUSE CONFIRMED`：最初直接執行 `./tests/run.sh` 的 agent shell 選到
`/Library/Developer/CommandLineTools/usr/bin/python3` 3.9.6，`import tomllib` 失敗；
該輪只有 turbo 模組 exit 1，其他 29 個模組通過，完整 exit 1／122.960 秒。
用 repo 的 `dev-env` 入口，原生 control 能以 Homebrew Python 3.14.8 載入 `tomllib`；
兩次 full-suite 的來源 snapshot 完全相同，第二輪全部通過。沒有新增 fallback、安裝 Python、
改測試或改產品程式，移交指令依 README 使用已存在的入口。

同機 raw QA evidence 保存於 `/var/folders/t5/4b3mtjj52fvdplz5f15mf_ym0000gp/T/dotfiles-transfer-qa-d2byd4pd`：
`python39-full-suite.log`／`python39-qa-result.json` 保留失敗；`full-suite.log`／`qa-result.json`
保留修正執行環境後的結果；兩輪各有 before／after snapshots。這些暫存檔是可選重查證據，
不是跨主機必要 authority；遺失時依上述 repo-local commands 重跑。

接手者需要能定位三個 active items、重現 #285 的真實交付時間測量，並區分歷史 hosted
觀察與固定來源對照。第一個小變更仍按當前 active scope、skill authoring route 與 repo QA
契約處理；本指南不新增 implementation 或 outward-action authorization。

## 4. Pending active-item mapping 與正式切換

下表 current 欄位保留 transfer 前的完整 mapping。本次 transfer commit 將 STATUS 與兩份
active plan 的 coordination metadata 更新為 next values；在 endpoint condition 成立前，
effective authority 仍依 current mapping。下列 next workspaces 在準備時沒有
同名 local branch；它們是供接手者各工作項使用的獨立 feature branch，尚未建立。
`docs/transfer-delivery-overhead` 只是準備 branch，不能成為 next writer 的產品 workspace。

| Work item | Current writer／workspace | Next writer／workspace | Write Scope（保留） | First next step |
|---|---|---|---|---|
| 2. Runtime 目錄收斂與 legacy 遷移 | `codex:runtime-deployment-output`／`branch=fix/runtime-deployment-output` | `claude:delivery-overhead`／`branch=fix/delivery-overhead-runtime-layout` | scripts/ensure-runtime-layout.py, scripts/ensure-runtime.sh, scripts/ensure-codex-config.py, scripts/ensure-codex-guidance.sh, claude/settings.json, codex/config.toml, shared/skills/handoff/, claude/skills/handoff/, codex/skills/handoff/, codex/README.md, docs/add-new-host.md, docs/skill-portability.md | 定位 D-20260917-terminal-macbooks-outside-inventory 及 STATUS 的未完成驗收；先取得兩部額外 MacBook 的識別／revision／legacy store 依賴事實，再決定原 plan 的 cleanup 前提，不能直接部署或刪除。 |
| 3. 小幅變更的驗證與交付成本改善（#285） | `codex:brewup-bun-global-update`／`branch=perf/delivery-cause-diagnosis` | `claude:delivery-overhead`／`branch=perf/delivery-overhead-verification` | tests/, shared/skills/project/, shared/skills/deep-review/scripts/review-control.py, shared/skills/deep-plan/scripts/review-state.py, AGENTS.md, docs/testing-contract.md, .github/workflows/test.yml | 讀有效 plan 與 D-20261009-ci-system-redesign，從 main 的 61afb0d 準備固定來源／環境的分段計時；先定位 reference 載入、QA、provider、merge／cleanup 及回報成本，再決定有可重現證據的下一個有界改動。 |
| 4. Setup 工具與 agent shell 環境對齊 | `codex:brewup-bun-global-update`／`branch=docs/setup-fleet-results` | `claude:delivery-overhead`／`branch=chore/delivery-overhead-setup` | setup-mac-env.sh, setup-linux-env.sh, scripts/dev-tools.sh, scripts/dev-tools.tsv, scripts/dev-env.sh, scripts/align-dev-environment.sh, scripts/ensure-shell-env.py, scripts/dotfiles-sync.sh, scripts/brewup.sh, shell/, tests/, README.md, docs/repo-guide.md, docs/testing-contract.md, claude/CLAUDE.md, codex/AGENTS.md | 先讀 M-20261010-setup-fleet-complete，將待辦限制在歷史工具歸屬／用途核對；依已有 plan／ledger 的非秘密事實列出需使用者判定的 adopt／keep，沒有當批授權不做 SSH／更新／移除。 |

三項的 current Dossier Steward 都是 `codex:brewup-bun-global-update`；next steward 都是
`claude:delivery-overhead`。重疊 scope 由同一 next actor 串行處理，不授權平行 writers。

本次 Transfer 已達 `PREPARED`，使用者隨後明確叫用本 branch 的 Project Log merge endpoint。
全部 active items 的 Steward／assigned Writer／Workspace／第一個 next step，與帶上述
effective condition 的 conditional owner `D-*` record 收在同一 transfer commit。
在 transfer commit 抵達 canonical endpoint 前，舊 steward 仍是唯一 shared-dossier authority；
checkpoint／本指南不代表鎖定或切換已完成。接手者使用 Project 時必須先驗 conditional-owner
record 與 remote-visible ancestry，不能只按 STATUS 字面欄位授權。

Transfer 準備階段未 commit、push、開 PR、merge、調整 repo 權限或執行部署；後續 Log 的
merge endpoint 來自使用者針對本 worktree 的新 explicit invocation。所有外向動作依當批
指令執行；授權不隨 owner 移交，接手者不能沿用 current steward 本批的送出授權。

## 5. 風險、暫停項與求助路徑

- `STATUS.md` 的兩個 paused backlog items 保留既有可觀察恢復條件，不因移交啟動。
- Historical plans／event-time records 不重寫；source ancestry 與當前有效限制有疑問時，先用 repo router 定位 stable ID。
- 原始效能／fleet logs 是同機暫存證據，遺失時明示不能重查，按 repo 指令重新測量，不把私人暫存變成必要 authority。
- 涉及未整合工作、其他 writer 或 private-only 必要事實時，回到 current steward／使用者明示處置，再重跑本流程。
- Setup、dotsync、brewup 的變更是部署來源；未進 canonical main 或未取得當批部署授權時，不能散佈。
