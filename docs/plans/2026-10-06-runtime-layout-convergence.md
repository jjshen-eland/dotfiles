# Runtime 安裝結構收斂與資料遷移

- 工作項：runtime-layout-convergence
- 日期：2026-10-06
- 狀態：in-progress
- 種類：implementation plan
- 需求來源：使用者要求同版 dotfiles 的新裝／升級／重跑得到相同受管理 runtime 結構，並於 2026-10-06 指示「開工」。
- Writer／Dossier Steward：`codex:runtime-layout-convergence`
- Workspace：`branch=refactor/runtime-layout-convergence`
- 原規劃／盤點基線：`338da91fc3a2ba6ce2487e63d0f8ab4b6c527ab1`
- 接續基線：`79269535b3a3a741a87c3f7a8bb1c8a161ce2fcd`；#271 已經 PR #272 合併，接續時 runtime setup／helpers 尚未實作。原盤點維持其採集時間與限制，apply 前仍須重新量測。
- 需求／驗收權威：[STATUS.md](../../STATUS.md)「Runtime 目錄收斂與 legacy 遷移」。使用者「開工」授權本地實作／驗證，PR #273 已合併 origin/main `744356df`，使用者現已明示本批「14 個目標的遷移部署與驗收」。
- 本地階段：migration／共用 entry 與隔離驗收完成，serial／parallel 各 1576 PASS／0 FAIL；證據與原生驗證邊界見 M-20261006-runtime-layout-local-acceptance。shipping 已完成（PR #273，required macOS／Ubuntu CI 通過）；14 目標遷移已取得本批授權，resolver cleanup 須待全體遷移驗收，計畫維持 in-progress。

## Runtime 現況與影響邊界

兩份 setup 的行內 helper 整目錄連結 Claude skills 與 Codex rules；Codex helper 刪除既有目的地。dotsync／brewup 已共用 Codex skills、guidance、config helper，未部署 Claude skills、rules 或遷移 handoff。brewup 也是 allup 的日常部署路徑，須一起接入。sysup 只更新 apt，不 pull dotfiles，沒有適用的 runtime 階段。

handoff 已 portable：兩端薄入口的 references／scripts 指向 `shared/skills/handoff`，不重做移植。resolver 沿用 legacy-only、拒絕不同實體的雙 store、接受同實體 alias。survey 會 prune archive，不能拿來盤點原始資料。

D-20260823-portable-handoff-skill 要求安全 migration／locking behavior evidence 才可取代 legacy resolver；只取代 default store 部分，保留 claims／authorization／archive provenance／consume-once。D-20260912-neutral-portable-skill-core 的分層不改；D-20260912-codex-config-three-layer-merge 的原 helper／manifest／鎖／原子合併不重寫；M-20261001-handoff-frontmatter-anchor-verify 的 frontmatter gate 保留。

2026-10-06 已以唯讀 lstat／逐檔 checksum／mode／mtime 及 ps 盤點 inventory 14 目標，初次快照為 /tmp/runtime-layout-inventory-20261006.json；補充可重算的逐檔 manifest 為 /tmp/runtime-layout-inventory-detailed-20261006.json（SHA256 8e5af9d63f6d3d0c07078881ced63068646ad38820e9c06a9962d516cd5c3b2f），採集程式為 /tmp/runtime-layout-inventory-reader-20261006.py，程式 SHA256 存在 evidence；同機暫存非 durable authority，沒有寫入或 prune store。全數 revision 為基線；13 個遠端的 Claude skills／Codex rules 是整目錄 link，本機兩者為實體 root；14 個 Codex shared skills roots 均為實體。正式 handoff store 全數不存在，因此目前新增放行的「雙實體 store 合併」格真實成員為零，不把 fixture 當成 live 成員。legacy-only store 有 eagle06（6 檔）、macs（18 檔）、db01（空 archive，0 檔）、macmini（1 檔）；其餘 10 個目標沒有 store。13 個遠端 ps 成功且無 codex／claude 程序，本機觀測 12 個，屬會被新增 offline guard 攔下的成員。數量是此次 snapshot，不是部署時 quiescence 保證；apply 前重新量測。先在隔離 home／repo fixtures 實作／測試，不變更目前 runtime。

## Canonical layout 與 ownership

| 路徑 | 形式及管理邊界 |
| --- | --- |
| `~/.claude/skills` | 實體目錄；repo 有 SKILL.md 的 entries 逐項連結到 Claude adapters；synced／未知名稱／第三方保留 |
| `~/.agents/skills` | 實體目錄；repo Codex adapters 逐項連結；第三方保留 |
| `~/.codex/skills` | system／第三方保留；僅清理新入口驗證成功且確實指向本 repo adapters 的舊鏈 |
| `~/.codex/rules` | 實體目錄；repo default.rules 連結為 dotfiles.rules，其餘 repo rules 用 dotfiles-<name>；default.rules 為可寫實體檔，既有個人授權 bytes 保留，新裝為空檔 |
| `~/.agents/handoffs` | 實體正式 store；active／archive／相關檔案保留，不改 claims／格式 |

Claude guidance/settings、Codex guidance/config 仍依 repo 權威；config.local.toml、登入、hook trust、plugins 不搬移。正式 layout authority 寫在 docs/repo-guide.md，其他安裝文檔指向它。保留明示 HANDOFF_DIR；CODEX_HOME/config override 沿原 helper 語意，不建立第二套 config。

## 共用部署與分階段切換

新增 standard-library `scripts/ensure-runtime-layout.py` 與共用 shell entry，串接 layout 和原 config merge。macOS／Linux setup、dotsync 本機／遠端、brewup 呼叫同一 entry；移除 setup 破壞性 inline runtime linking。原 Codex helper 直接呼叫介面與測試保留，但部署入口不再自行重複安裝流程。

CLI 有 inventory（預設唯讀）、dry-run、apply、verify、指定 transaction 的 recover／rollback。明列 actions、blocked targets、CLI capability、backup／receipt。缺 CLI 可準備檔案但不能稱載入已驗證。layout／config 失敗反映共用入口非零及 dotsync 終判；brewup 保留套件更新不中止、helper 警告可見的契約。

先交付 migration 與共用入口，保留現行 handoff resolver。合併 origin/main、取得部署授權、14 目標遷移驗收後，才實際刪除 legacy fallback；不能把 canonical-only skill 提前散佈。

## Migration transaction 與停止條件

每個受管理 root 一個 transaction；兩個 handoff root 屬同一 transaction。lock／receipt／unique backup 在 discovery root 外，私有部署操作紀錄不保存行為授權、不取代專案 authority。receipt 記 schema、id、before／candidate／after fingerprints、各路徑與 rename 步驟，原子寫入。

1. lstat source、target、parents；拒絕不明 root alias、特殊檔、parent 穿入 repo。已知整 root symlink 只操作 link 本身，不能把 resolve 到 repo 的來源搬走／刪除。正確 entry 依 inode／resolved identity 判斷。
2. ownership 不靠名稱：managed-name 實體副本須與 current repo 或可取得的 historical Git tree 的完整 bytes／link manifest 相符才可備份接管。未知／自訂差異停止該 root。其他名稱保留 bytes／mode／mtime／link；shallow clone 缺舊 blob 就 unknown，不自動 fetch。
3. 需要搬移既有 runtime root／handoff 資料時，檢查已知 Claude／Codex writer processes；有 writer 或 process inventory 失敗就停止該 target，列出 PID／命令，區分互動工作與常駐 app-server daemon。結束互動工作不等於 daemon 已退出；使用者須透過所屬 app 的正常退出／停止方式關閉，從普通 terminal 重新 inventory，確認無 writers 才重跑。agent 不自動 kill、不豁免 daemon，也不以等待或結束對話冒充解除阻擋。copy＋digest 不能證明沒有 open-file writer；agent 不得自行假稱 quiescent。未知非合作 writer 另由 before／after snapshots／inode guards 偵測，不宣稱防禦惡意程序。
4. 同 filesystem sibling stage 建候選，完整保留資料／mtime／mode；不跟隨子 symlink 搬外部內容，handoff symlink 缺可驗證安全 mapping 就停止。snapshot 含類型／lstat identity／內容；copy 前後須一致。stage 驗證、備份位置可寫且不會覆蓋、最後原 snapshot 再驗才 commit。
5. receipt 先記 intent 再 rename；舊 target 留在 discovery 外 backup，stage 換入 target，verify 後記 committed。每一步 failure 非零且保留 stage／原資料／receipt，不猜成功；一般重跑不刪 backup。
6. recover 僅在 recorded PID 不存在、現狀精確匹配已記步驟時釋放 stale lock並恢復／續作。未知狀態停止。rollback 要求 installed target 與 receipt 相符且 writers 關閉；target／backup 有後續修改就拒絕，不能刪新 checkpoint／個人規則。
7. 不冒稱跨 root 原子：blocked root 不妨礙其他安全 root，最後彙總非零與已成功範圍。canonical 第二次 apply 不改 inode／bytes／mtime，不造新 backup。

## Handoff 合併與 legacy 契約

legacy-only 移至正式位置；canonical-only 驗證；雙實體 store 先檢查跨 store 的 workline／provenance，再逐相對路徑合併。active 用完整 filename stem，archive 候選涵蓋 date-only／seconds 前綴的兩種解讀；歧義／frontmatter 不一致只能更保守攔截，不能讓消歧抬高信任。不同 store 的非同路徑資料若可能屬同一工作線（尤其 active 對 archive、相同 claims 的不同 archive 名），整個 transaction 停止，不能自行判新一輪或重新 activate；合法的單一 store 內既有 active/archive 共存不改。完全相同的相對路徑須類型／bytes／mode／mtime 相符才去重，否則也停止。只有跨 store 身分不相交的獨有資料才合併。身分判定只用來 conservative conflict gate，不另定正常 survey/predecessor 的解析契約。已知同實體 alias 特判，正式 root 最後為實體、legacy path 移到 backup；無 store 新建。archive 與附帶檔案全納入 checksum，不只 *.md。

不改 archive 命名／frontmatter：YYYYMMDD 與 seconds 前綴、數字開頭 slug 消歧需要 reader；未有無歧義 conversion oracle 前保留。無 slug／錨點的 metadata 降級語意保留，這是資料信任契約。mtime 驅動 active 排序／archive TTL，不能重設。

fleet 驗收後 cleanup 固定正式 store，舊 store／migration residue 明示 needs-upgrade 非零，不自行搬移；HANDOFF_DIR 仍合法。event-time decision 以 supersedes:D-20260823-portable-handoff-skill 僅取代 default fallback 部分，記留下的 readers 與重議條件。

## 驗證與 rollout 順序

1. 持久資料搬移／回復失敗有不可逆風險，採 deep-plan 完整獨立兩輪。本項新增 migration 放行／阻擋判準，帶 criteria-impact review；首次已量測的集合與空格見現況節；apply 前重新量測實際 target／file／writer 集合，未知成員 blocked，不宣稱 fleet 已安全。
2. RED 先執行現行 setup runtime sections 與升級 helpers 的隔離 fixture，assert Claude 新 entry 缺失、rules root 形式／可寫位置不同。原 helper 真執行，缺新 module 的 import error 不算重現。保存輸出／snapshots；其他安全案例是 regression controls，不冒稱全 baseline RED。
3. inventory／ownership／dry-run：fresh、whole-root／per-entry links、historical pristine copy、未知碰撞、source alias、broken parents、system／synced／第三方保全。
4. transaction tests：每個 receipt／rename 邊界故障、中斷 recovery／rollback、並行 lock、外部更新／inode 替換、跨 filesystem／symlink escapes。來源可回復，未知狀態拒絕。
5. handoff single／split／alias 合併 checksum／mtime／anchors 不變；新增 active 對 archive 的已消費副本、同工作線跨 store、不確定数字 slug、相同內容不同 archive 名的 conflict fixtures，明確配對無交集 workline 的可合併 control；雙端 bundled helper survey／predecessor／verify normalized outcomes 一致、consume-once／frontmatter 假錨點 regressions。fixture 用新日期或明設 TTL，不拿 live survey 清原資料來驗收。
6. 共用入口 stub package／git／SSH／process 工具，走真正 local／remote invocation；fresh／upgrade／rerun 比較 managed layout，native state／config 三層／缺 CLI 可觀察。同步遷移 tests/run.sh 的 deployment wiring assertions：四個部署脚本不再要求直接出現 ensure-codex-guidance.sh，setup 的實際 clone 路徑傳遞改驗共用 entry；setup／brewup 的 config helper 名稱與 dotsync 本機＋遠端兩處的舊 helper 計數改驗共用 entry 的實際呼叫與其內部 config/guidance 接線。brewup helper-failure fixture 和 dotsync 本機／SSH fixtures 改帶真實共用 entry，僅隔離其下游工具，驗證 guidance／config 失敗確實傳入 entry，再分別產生 brewup 可見警告且繼續套件更新、dotsync 非零終判；不以保留舊名稱註解或空 stub 讓 wiring assertion 假綠。獨立舊 helper 的備份／安全／幂等行為測試仍保留。兩端 validator、deterministic tests、雙 runtime blind forward eval，受測者只拿 raw fixture／skill，不洩漏 oracle／預定修正。
7. 新增或調整 assertion 時同步 tests/shard-manifest.tsv 的各 shard 期望值，不放寬 tests/shard-aggregate.py 判準；同時跑完整 ./tests/run.sh 與 ./tests/run-parallel.sh，核對總數／各 shard 計數和真實 exit，避免 serial 全綠卻 CI count drift。doc-governance ship／xref audit、diff check 通過，保留 inputs fingerprint 與實際 exit。CI 相依依據為 M-20261001-pr249-shard-manifest-synchronized。舊 helper 直接測試、原安全 oracle 不刪；history／implemented plans 不改寫。
8. 新批 shipping／部署授權與 origin/main 前，不在本機／遠端 apply 此版。inventory 14 目標，macs 本機只計一次，逐台記 revision／layout／writers／CLI／data snapshots；不自動關 runtime、trust hooks、安裝 CLI。
9. canary 後全 fleet，逐台 verify／rerun；有 CLI 原生只讀載入，無 CLI capability-limited，不冒稱全功能可用。14 目標 migration 通過後才移除 fallback，再依同樣 shipping／deployment gate 驗證；最後 freeze implemented、移除 active item。

## 交付邊界

需要新產品決策、ownership 衝突、writer／snapshot 不明、collision、Write Scope 越界時停受影響工作並列證據；安全同項工作可繼續。本地測試全綠可交付 migration／共用部署實作，STATUS 明列尚待 shipping、fleet migration、後續 cleanup，不能以本地綠冒充專案完工。

## 2026-10-06 本批 fleet 驗收快照

版本 `744356df2caae0cf63b76692798390474267f4a6`；以共用 entry 部署，不執行完整 setup、brewup 套件更新或 kill writers。be01（無 CLI）及 eagle06（有 legacy 資料／雙 CLI）先通過 canary，才續其餘十台。下表的「通過」含 apply／verify／共用 entry 重跑均 exit 0、source 不變、個人設定／第三方／原生內容在 migration 階段保留、重跑含 inode 無變動、committed receipts／retained backups／無 stage residue 核對。

| 目標 | 部署 revision | Layout／重跑 | 原生 discovery | Handoff 資料 |
| --- | --- | --- | --- | --- |
| eagle03 | 744356df | 通過 | Codex／Claude 通過 | 正式空 store |
| eagle06 | 744356df | 通過（資料 canary） | Codex／Claude 通過 | 六檔／mode／mtime 完整搬移 |
| eagle07 | 744356df | 通過 | Codex／Claude 通過 | 正式空 store |
| eagle08 | 338da91f | blocked：3 writers、repo 本機修改 | 未驗 | 無 store，未變更 |
| eagle09 | 744356df | 通過 | Codex／Claude 通過 | 正式空 store |
| macs | 744356df | blocked：13 writers；負 UID 修正尚未交付 | 未驗 | 18 檔留在 legacy，未變更 |
| db01 | 744356df | 通過 | Codex／Claude 通過 | 空 archive／mode／mtime 完整搬移 |
| ap01 | 744356df | 通過 | Codex／Claude 通過 | 正式空 store |
| ap02 | 744356df | 通過 | Claude 通過；Codex 缺 CLI | 正式空 store |
| macmini | 744356df | 通過 | Codex／Claude 通過；四個額外 plugins 保留 | 一檔／mode／mtime 完整搬移 |
| m4mini | 744356df | 通過 | 兩端缺 CLI，capability-limited | 正式空 store |
| agent01 | 744356df | 通過 | Codex／Claude 通過 | 正式空 store |
| fe01 | 744356df | 通過 | Claude 通過；Codex 缺 CLI | 正式空 store |
| be01 | 744356df | 通過（無 CLI canary） | 兩端缺 CLI，capability-limited | 正式空 store |

原生驗證使用各台實際 HOME、新暫存 cwd，未追加 repo-local skills 或 extra user roots。Codex skills/list 與 Claude metadata-only initialize 列出 user adapters；前者原生 parser 讀正式 rules 全集，gh pr merge 為 prompt，沒有執行 merge 命令，未直接觀測 session 自動 enforcement。後者 temporary no tools／hooks／MCP，沒有 model turn 或 persisted session，不改 hook trust；tokenSource none，不宣稱模型登入。8 台 Codex 啟動後原生 .system 被 CLI 重建，部分 auth／Claude cache 亦改變；pre-apply → post-apply → post-rerun 的原生／個人 snapshots 相同，與 native startup 分階段核對，所有 managed roots／handoff／第三方 entries 在 startup 後相同。CLI binary 版本未升級。

Raw snapshots／helper exits／receipt checks／native responses／artifact manifest 在 `/tmp/runtime-layout-fleet-20261006`；acceptance.json SHA256 `25df5ed7135092d7e49982a39eab02003f3d7ff992d6d13ae2de06a2b33a9943`，artifact-manifest.json SHA256 `e6ba2e367ca40871dfeab23567c89f3c93a3e1a9c3dcd7e608b0f32f390294f0`。暫存 evidence 不是授權或跨機 authority；此表／STATUS 保持 durable 結果。初次過廣的 native 後全樹比較與 exclusive user count audit 失敗另留 attempt1，不覆蓋原始 evidence。

兩個 blocked 目標初末 runtime roots 相同。eagle08 的 `claude/settings.json` 修改及 `claude/skills/synced/` 未追蹤內容，須使用者／writer 明示處置；不能自動覆蓋或自行認領。macs 的真實 ps `1622 -2 /usr/libexec/dhcp6d` 重現 parser failure，隔離 RED 保存在 `/tmp/runtime-layout-negative-uid-red-20261006.log`；一行修正接受 signed UID，26 cases 驗同 UID writer 仍列出／阻擋、malformed UID 仍失敗，真實 inventory 已列 13 writers，未在本機 apply。修正的完整 serial（408.167s）／parallel（328.435s）均 exit 0、1576 PASS／0 FAIL；parallel core 171／ship_state 239／integration 1166。376 tracked source paths 各次啟動前凍結、結束後相同；raw logs 與 evidence 在 /tmp/runtime-layout-deployment-{serial,parallel}-20261006.*。全套後只更新 STATUS／此 plan／event-time 紀錄，另驗文件，不將舊 inputs 倒填為收尾文字。使用者現以 `$project --merge` 授權修正與紀錄的本批交付，endpoint 尚待完成；origin/main 前不散佈。所有 writers 需由 owning app 正常停止，從普通 terminal 重新 inventory；agent 不 kill。12／14 不足以移除 fallback，active plan 保持 in-progress。

inventory 外兩部 MacBook 依 D-20260917-terminal-macbooks-outside-inventory 維持自主更新，不新增中央 fan-out；目前未量測其 runtime，不沿用 identity rollout 的歷史驗收或休眠狀態作為本項結果。建議另追蹤兩部終端的本機 runtime 驗收，追加 acceptance 範圍尚待確認；現行 14 台表維持 12 台通過、2 台 blocked。legacy cleanup 前須釐清額外終端是否仍依賴舊 store。

macs 與兩部 MacBook 的本機流程：先保存工作並由所屬 app 正常停止 Claude／Codex 互動程序和常駐 daemon，從普通 Terminal 確認 repo 為 clean main；本批修正合併後依序執行以下命令，任一步非零即保留現場並處理該原因。未知 repo 修改先分類，不自動 stash／reset。

```sh
cd ~/.dotfiles &&
git pull --ff-only &&
python3 scripts/ensure-runtime-layout.py inventory &&
DOTFILES_DIR="$PWD" bash scripts/ensure-runtime.sh &&
python3 scripts/ensure-runtime-layout.py verify
```

再重跑 common entry／verify，核對 data checksum／mode／mtime、retained backups 與 receipts 無新增；有 CLI 的端於新 cwd 驗原生 discovery，缺 CLI 明示能力缺項。eagle08 另須先處置已識別的本機修改並重新查 writers，才可 pull／apply。完整 setup／brewup 不是本批必要操作；brewup 的 helper 失敗可警告後仍 exit 0，不能只用 brewup exit 作 runtime 驗收。
