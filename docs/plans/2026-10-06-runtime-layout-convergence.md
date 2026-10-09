# Runtime 安裝結構收斂與資料遷移

- 工作項：runtime-layout-convergence
- 日期：2026-10-06
- 狀態：in-progress
- 種類：implementation plan
- 需求來源：使用者要求同版 dotfiles 的新裝／升級／重跑得到相同受管理 runtime 結構，並於 2026-10-06 指示「開工」。
- Writer／Dossier Steward：`codex:runtime-deployment-output`
- Workspace：`branch=fix/runtime-deployment-output`
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
| `~/.claude/skills` | 實體目錄；repo 有 SKILL.md 的 entries 逐項連結到 Claude adapters；未知名稱／第三方保留，雲端同步依權威 settings.json 停用；本輪僅處理具名 eagle08 synced cache |
| `~/.agents/skills` | 實體目錄；repo Codex adapters 逐項連結；第三方保留 |
| `~/.codex/skills` | system／第三方保留；僅清理新入口驗證成功且確實指向本 repo adapters 的舊鏈 |
| `~/.codex/rules` | 實體目錄；repo default.rules 連結為 dotfiles.rules，其餘 repo rules 用 dotfiles-<name>；default.rules 為可寫實體檔，既有個人授權 bytes 保留，新裝為空檔 |
| `~/.agents/handoffs` | 實體正式 store；active／archive／相關檔案保留，不改 claims／格式 |

Claude guidance/settings、Codex guidance/config 仍依 repo 權威；config.local.toml、登入、hook trust、plugins 不搬移。正式 layout authority 寫在 docs/repo-guide.md，其他安裝文檔指向它。保留明示 HANDOFF_DIR；CODEX_HOME/config override 沿原 helper 語意，不建立第二套 config。

2026-10-07 使用者回報 Claude literal default 出現 Custom model，並選擇只收省略 model 的修正。依 D-20261007-claude-model-default-unset 修訂目前表示方式，模型政策以 docs/repo-guide.md 為權威；原初始化成功紀錄保留，新增原生選單唯一性作驗收，不回填舊測試。外部 UI 的 high effort／排序變更先私有備份後還原，本機 settings.local.json 與 session 覆寫保留。

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
7. 測試編排依現行 root AGENTS.md 與 docs/testing-contract.md，新增／調整案例放入所屬模組，以實際 exit 與模組完成結果驗證。2026-10-09 CI 重構已取代固定 shard assertion manifest 及 serial／parallel 雙跑要求（D-20261009-ci-system-redesign）；此處僅由 Dossier Steward 更新共用測試相依，不續作 Runtime 產品實作。doc-governance ship／xref audit、diff check 通過，保留受測來源與實際 exit。舊 helper 的安全行為 oracle 仍須承接；history／implemented plans 不改寫。
8. 新批 shipping／部署授權與 origin/main 前，不在本機／遠端 apply 此版。inventory 14 目標，macs 本機只計一次，逐台記 revision／layout／writers／CLI／data snapshots；不自動關 runtime、trust hooks、安裝 CLI。
9. canary 後全 fleet，逐台 verify／rerun；有 CLI 原生只讀載入，無 CLI capability-limited，不冒稱全功能可用。14 目標 migration 通過後才移除 fallback，再依同樣 shipping／deployment gate 驗證；最後 freeze implemented、移除 active item。

## 交付邊界

需要新產品決策、ownership 衝突、writer／snapshot 不明、collision、Write Scope 越界時停受影響工作並列證據；安全同項工作可繼續。本地測試全綠可交付 migration／共用部署實作，STATUS 明列尚待 shipping、fleet migration、後續 cleanup，不能以本地綠冒充專案完工。

## 2026-10-06 本批 fleet 驗收快照

首批十二台版本 `744356df2caae0cf63b76692798390474267f4a6`；接續 eagle08 為 PR #275 已合併的 `ee9312d0b272a48e91b282d342de081e04404bb6`。以共用 entry 部署，不執行完整 setup 或 brewup 套件更新；eagle08 的具名測試 daemon 另有本輪明示處置，見下文。be01（無 CLI）及 eagle06（有 legacy 資料／雙 CLI）先通過 canary，才續其餘十台。下表的「通過」含 apply／verify／共用 entry 重跑均 exit 0、source 不變、個人設定／第三方／原生內容在 migration 階段保留、重跑含 inode 無變動、committed receipts／retained backups／無 stage residue 核對。

| 目標 | 部署 revision | Layout／重跑 | 原生 discovery | Handoff 資料 |
| --- | --- | --- | --- | --- |
| eagle03 | 744356df | 通過 | Codex／Claude 通過 | 正式空 store |
| eagle06 | 744356df | 通過（資料 canary） | Codex／Claude 通過 | 六檔／mode／mtime 完整搬移 |
| eagle07 | 744356df | 通過 | Codex／Claude 通過 | 正式空 store |
| eagle08 | ee9312d | 通過；具名處置後 fresh apply／verify／rerun | Codex／Claude 各 11 adapters；temporary cloud opt-out | 正式空 store |
| eagle09 | 744356df | 通過 | Codex／Claude 通過 | 正式空 store |
| macs | 未 apply（本輪 repo 基線 ee9312d） | blocked：原觀測 13 writers，須停止後 fresh 重驗 | 未驗 | 18 檔留在 legacy，未變更 |
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

兩個 blocked 目標初末 runtime roots 相同。eagle08 的 `claude/settings.json` 修改及 `claude/skills/synced/` 未追蹤內容，須使用者／writer 明示處置；不能自動覆蓋或自行認領。macs 的真實 ps `1622 -2 /usr/libexec/dhcp6d` 重現 parser failure，隔離 RED 保存在 `/tmp/runtime-layout-negative-uid-red-20261006.log`；一行修正接受 signed UID，26 cases 驗同 UID writer 仍列出／阻擋、malformed UID 仍失敗，真實 inventory 已列 13 writers，未在本機 apply。修正的完整 serial（408.167s）／parallel（328.435s）均 exit 0、1576 PASS／0 FAIL；parallel core 171／ship_state 239／integration 1166。376 tracked source paths 各次啟動前凍結、結束後相同；raw logs 與 evidence 在 /tmp/runtime-layout-deployment-{serial,parallel}-20261006.*。全套後只更新 STATUS／此 plan／event-time 紀錄，另驗文件，不將舊 inputs 倒填為收尾文字。修正與紀錄已經 PR #275 完成交付至 origin/main `ee9312d`，required macOS／Ubuntu CI 通過。原十二台結果及兩個 blocked 初末快照保留；本輪 eagle08 有新的具名程序／drift／cache 處置與驗收，其他 writers 仍須由 owning app 正常停止後從普通 terminal 重新 inventory。13／14 不足以移除 fallback，active plan 保持 in-progress。

inventory 外兩部 MacBook 依 D-20260917-terminal-macbooks-outside-inventory 維持自主更新，不新增中央 fan-out；目前未量測其 runtime，不沿用 identity rollout 的歷史驗收或休眠狀態作為本項結果。建議另追蹤兩部終端的本機 runtime 驗收，追加 acceptance 範圍尚待確認；現行 14 台表已含 eagle08 接續結果，13 台通過、macs 一台 blocked。legacy cleanup 前須釐清額外終端是否仍依賴舊 store。

macs 與兩部 MacBook 的本機流程：先保存工作並由所屬 app 正常停止 Claude／Codex 互動程序和常駐 daemon，從普通 Terminal 確認 repo 為 clean main；本批修正合併後依序執行以下命令，任一步非零即保留現場並處理該原因。未知 repo 修改先分類，不自動 stash／reset。

```sh
cd ~/.dotfiles &&
git pull --ff-only &&
python3 scripts/ensure-runtime-layout.py inventory &&
DOTFILES_DIR="$PWD" bash scripts/ensure-runtime.sh &&
python3 scripts/ensure-runtime-layout.py verify
```

再重跑 common entry／verify，核對 data checksum／mode／mtime、retained backups 與 receipts 無新增；有 CLI 的端於新 cwd 驗原生 discovery，缺 CLI 明示能力缺項。eagle08 已依本輪明示處置解除阻擋並完成 fresh 驗收，見接續結果。完整 setup／brewup 不是本批必要操作；brewup 的 helper 失敗可警告後仍 exit 0，不能只用 brewup exit 作 runtime 驗收。

使用者本輪澄清 eagle08 的兩個 Codex app-server daemon（18379／18483）為已完成測試，明示可 kill；只對再次核對身分的這兩個程序先 TERM、必要時 KILL，不擴到其他 runtime。`claude/settings.json` 的 model 及格式改動為 runtime drift，可還原；`claude/skills/synced/` 是已識別的雲端 cache，使用者明示停用同步並刪除該目錄。清理先移出 repo／discovery 至同機私有備份，確認無 writers 後才按 origin/main 已交付版本遷移。`~/.claude/settings.json` 保持檔案 symlink，skills discovery root 維持新設計的實體目錄與逐項 repo symlinks。原 source 缺 `syncClaudeAiSkills: false` 的 evidence 在 /tmp/runtime-cloud-sync-red-20261006.json；官方設定支援已核對。先補權威設定與驗證，未進 origin/main 的新設定不得散佈；即使 layout 驗收通過，也不能把單次 cache 清理宣稱為永久停用完成。關聯 D-20261006-runtime-cloud-sync-disposition。


本輪 eagle08 接續結果（M-20261006-eagle08-runtime-accepted）：update／dry-run／apply／verify／rerun／verify-rerun 全 exit 0；source snapshots 相同、三個 committed receipts 的 candidate／before backups 正確、stage 無殘留，重跑 roots／settings／receipts 含 inode 相同。既有 config merge helper 首次重新序列化 native/config.toml（before SHA256 650a00a57fa618f415a4a49dae755948de65dfc55cdcabb91294caa93104f375 → after 8b7a8a43125cd1ed9c8b26a5b956a8dc013f584ffb33029994db7fbb68c6aacd），四階段 managed／unmanaged／完整 TOML 語意相同且 mode 0600，重跑不再寫入；其他 protected 個人檔在 migration 階段不變。初次 reporter 將受管理 config bytes 也要求保留而失敗，原 evidence 留 acceptance.attempt1，不改 production helper 或安全 guard。Codex 0.160.1／Claude 2.1.291 原生 metadata-only discovery 各列出 11 repo adapters；explicit rules parser 為 prompt，未執行 merge／模型 turn。Claude probe 只在該程序 temporary settings 設 cloud opt-out；未將未交付 source 部署到遠端，也未驗 10 分鐘背景下載週期。Native startup 後只有 .claude.json cache 改變，.system 未重建，managed roots／私人設定保留且 synced 不存在。Settings 檔案 symlink 保持；永久停用仍待新設定具名 shipping／部署。Raw artifacts 為 /tmp/runtime-layout-fleet-20261006/eagle08-resume-*.json；acceptance.json SHA256 54372cf2c121e1475488a32257b82b62cdff6af66ad23e3539b5df71bf093167，artifact-manifest.json SHA256 a45f032ab288704c19e683a217984036c7c1ec06bb81c5e720401b06cb572fc7（兩檔均有 eagle08-resume- 前綴）。首批十二台的 acceptance／manifest 原檔與 hash 未覆寫。


權威同步 opt-out 的本輪驗證：settings.json 的 JSON 語意與 HEAD 比對，唯一差異為 syncClaudeAiSkills=false，其他設定相同。完整 ./tests/run.sh exit 0、1576 PASS／0 FAIL，耗時 368.272s，376 tracked inputs 在 before／after 相同；raw log／原始 input snapshot 為 /tmp/runtime-cloud-sync-serial-20261006.{log,evidence.json}。使用者要求先查其他十二台後再提交／dotsync；唯讀 lstat 查十二台的 runtime 與 repo 各 synced／syncd（四路徑）均不存在，git status 皆 clean，settings 當時都尚未設 opt-out。Raw per-host evidence 在 /tmp/runtime-layout-fleet-20261006/<host>-cloud-sync-precheck.json，summary cloud-sync-twelve-precheck.json SHA256 bf382964668fa9dbf52b59bcf65bbdf4b6d910a34af3154a3adc6d27e08d6c4b。這是採樣時 absence，未冒稱未來不再下載；native false probe 的邊界見前段。測試完成後追加此驗收結果，再獨立驗 doc ship／xref／retrieval，不倒填 full suite 的 inputs。使用者本輪具名授權 commit／dotsync，但新設定仍需本批明示 shipping endpoint，進 origin/main 後才散佈。


使用者續指定 repo 的雙端模型都改為 default／等效 default：Claude 權威 model 改為 default；Codex 既有未指定 model 的表示方式保持並補註解（模型政策權威見 docs/repo-guide.md，D-20261006-runtime-model-defaults）。不改 Codex 三層合併，機器／session 選擇仍能覆寫。隔離 native metadata-only initialize 接受從來源讀出的 Claude default 與 cloud false；未發模型 turn，未宣稱帳號的 default 實際解析到哪個模型。Codex 以真實 merge helper 驗 fresh（model 不存在）、saved runtime model 保留、local model 優先，三案重跑 bytes／inode／mtime 不變；JSON 語意只改 model，雲端 opt-out 與其他設定保留。Evidence /tmp/runtime-model-defaults-20261006.evidence.json，source snapshots 前後相同。這次只改設定值／註解與紀錄，沿用先前 full suite 對未改程式的結果，新增定向驗證並另驗文件；不把前次 1576 PASS 宣稱覆蓋新 model 值。


M-20261006-runtime-settings-deployed 的本輪交付／部署：PR #276 在 2026-10-06T15:52:45Z rebase merge，main `b6299f5650aedb2a584c1e43b9d8777fdbdd5cf2`；required macOS 9m16s／Ubuntu 3m37s 通過，Actions run 37489655850。送出 candidate `c1f1b31` 與 merged main 的 tree 同為 `94d3181f11ba609b93b8a80073d7d99d25ce800a`；本地 main 同步、該 PR 原 branch 已清。具名 dotsync 共嘗試本機與 inventory 14 targets（macs self-target 在驗收數只算一次），exit 1、5.846s、local=failed／remote_ok=13／remote_failed=1。逐台 fresh 核對 14 台 revision／clean main／source 與 runtime Claude default／cloud false／settings symlink，Codex base 均無 model。13 台遠端 runtime verify exit 0，無 writers、cache 四路徑均 absent，受管理 roots／私人設定／handoff 資料／maintenance／committed receipt candidate 與 retained backups 保留。這是設定／layout 層證據；未重發模型 turn 或驗 10 分鐘背景下載週期，CLI 未升級。

macs fresh 部署前／後均有 8 writers，16 檔 legacy handoff、roots／maintenance 相同；先前 18 檔是較早、仍有活躍 owning app 的採樣，不把跨時間差異歸因此部署。apply 與 verify 明確 blocked，synced 仍在 ~/.claude/skills，repo synced／syncd 不存在。既有 ensure-runtime.sh 在 layout blocked 後仍跑 guidance／config；config merge 如 D-20260912-codex-config-three-layer-merge，將受管理 model_reasoning_effort high 收斂為 repo medium，saved gpt-6.1-sol 保留、mode 0600，managed／unmanaged hash 相同、post actual 精確等於 pre expected。反證 control 只把 post effort 改回 high 即重現 pre actual semantic hash，其他 protected files 完全相同。因此首版 reporter 要求 managed config bytes／inode 不變過廣，原 settings-deployment-acceptance.attempt1.json 保留；只修 task reporter 的角色核對，不改 production helper 或安全 guard，也未重跑 dotsync。

私有 raw artifacts 在 /tmp/runtime-layout-fleet-20261006：<host>-settings-{presync,predeploy,postsync}.json、<host>-settings-{presync,postsync}-policy.json、settings-dotsync-result.json／settings-dotsync.log、macs-settings-config-diagnosis.json 與 settings-deployment-acceptance.json。Dotsync log SHA256 `420771df8c518df2959a6732ec680b961a85e0ed910515194979d8754c4b9493`；診斷 SHA256 `7aaf197a3a1c9a661da4070ea35b149189144e7c14f1918e69836ee5432f049f`；最終 acceptance SHA256 `041e72ae6fe13d795d2582552508a82d5d75f045a2c7c52c03090e1937be5fc3`，初次過廣比較 SHA256 `0660aae0f216ef675f35a6927985a66e21e9c02245fb5f0e5c1cbcb7ce3eaa9d`。最終 config policy 14 台、layout 13 台；macs blocked 與本機 cache 明列。部署後記錄尚待後續具名 shipping，不對新 PR 沿用本批 endpoint；fallback 與 active plan 保留。


M-20261007-macs-runtime-layout-accepted 的本機離線接續驗收：使用者選擇修正版流程並在普通 terminal 執行；來源 main 固定為 PR #276 的 b6299f5，紀錄 workspace 回到 refactor/runtime-layout-convergence（原 ec3db82 本地交付紀錄保留）。Native daemon stop 回 stopped；PID 4711 updater 以 boot／UID／start time／executable／exact role 核身後 TERM，退出時沒有其他 runtime writers，不使用 KILL 或刪 PID／lock。前次 fresh verify 仍有該 updater、正式 store 不存在且無 receipt，不將手動命令已執行冒充成功；修正版 inventory 無 writers、handoffs=needs-upgrade，其餘 roots unchanged。Common entry 首次 committed transaction 2a82d9a58bd64651ac1031074a2d9e8a，verify／common entry rerun／verify-rerun 通過，兩次 verify 都無 writers、全 roots unchanged。正式 ~/.agents/handoffs 為實體 store，18 檔及 archive 的 checksum／mode／mtime 與 receipt 的原 inputs 一致，legacy 入口 absent；原 sibling backup 含 inode 與 before 精確相同，candidate／backup／stage checks 全綠。原備份不刪，重跑未新增 receipt。

新暫存 cwd 的 metadata-only 原生 probe，Codex／Claude 各載入 11 repo adapters，Codex 全 native rules parser 對 gh pr merge 回 prompt（未執行命令）；Claude 使用已部署的 user settings，沒有 temporary cloud opt-out override。Native Claude 啟動時依 syncClaudeAiSkills=false 將已下載 skills 移至 ~/.claude/skills/.trash 並移除 synced；[官方行為說明](https://code.claude.com/docs/en/skills#skills-synced-from-claudeai) 與本機 2.1.289 schema 一致。215 個 skill 檔案的內容／mode／mtime／dev／inode 完整移到 trash，3 個 .bucket-*／manifest.json／.last-complete-round 同步索引由 runtime 清除；runtime 與 repo 的 synced／syncd 四路徑 absent。首次 reporter 要求 native startup 全 root bytes／inode 不變而失敗，保留 native-preservation-attempt1.json；逐項反證僅 Claude skills root mtime、identified synced→trash、三個索引清除及 .claude.json cache 改變，其他 managed entries、handoff、native skills／rules、私人設定、receipt／backup／source 相同，沒有放寬 production guard。原生 trash 會受 retention 清理，不宣稱永久備份或所有 218 個 cache 檔仍在；metadata-only 不宣稱 model turn、登入模型推論或 10 分鐘背景週期。

Raw evidence 為 /tmp/macs-runtime-rollout-20261007.mt8BvI，含 user run.log／inventory／verify／verify-rerun、committed receipt 原始指紋、pre-native／post-native snapshots、native responses、保留的失敗 reporter 與定向 acceptance。acceptance.json SHA256 d5d55970dce4e8e6b2676a852c6cc102e3cb91e4e301a6e452ed540505ab3c37；artifact-manifest.json SHA256 4d00627425d3299f8c58bc55d07ce4a31c31e9168a2ed60a160cc2944751483f；receipt SHA256 71516f8d91daf8362378509fb26e9e39d157e82a82718756ff839cd015362304。現行 inventory layout 14／14 已驗（缺 CLI 能力邊界沿上表），原十三台 evidence／歷史 blocked 快照未覆寫。Inventory 外兩部 MacBook 仍未量測、追加驗收範圍待確認；其 legacy store 相容影響未釐清前保留 fallback，本 plan 不結案。本輪只補驗收紀錄，未追加 source 改動或新的 push／PR／merge。

## 2026-10-07 日常部署輸出接續

使用者選擇原 writer 已停止、由本輪接續，assignment 已同步至 STATUS；本批授權為輸出摘要的本地修正與驗證，不能沿用舊 rollout／shipping 授權。驗收以 STATUS 新增的第 9 項為權威。基線重現及取捨見 D-20261007-runtime-deployment-summary；先新增隔離行為回歸取得 RED，再改 formatter 與共用入口。未執行 live runtime apply 或 brewup 套件更新；legacy cleanup 仍待原驗收邊界釐清，不因本批輸出修正結案。

本批 formatter／共用 entry 與 33 個隔離案例已驗；最終 serial／parallel 各 1575 PASS／0 FAIL、terminal exit 0，349 個 tracked 檔案內容快照前後與兩 runner 間一致。無 CLI 環境的摘要測試過度指定已先重現再修正，原初輪 serial 與 failure controls 保留；完整驗收及 raw evidence 指向 M-20261007-runtime-deployment-output-local。全套後只補此段與 STATUS／milestone，再驗文件，不將原 input snapshot 倒填為收尾文字。使用者續以 `$project --merge` 指定輸出摘要與 inventory 檢查紀錄的來源交付；交付前完整 parallel 補驗與可核驗 snapshots 見 M-20261007-runtime-output-shipping-candidate，fleet 部署仍另待當批授權，未延伸成 legacy cleanup 或額外終端的完整 native 驗收。
