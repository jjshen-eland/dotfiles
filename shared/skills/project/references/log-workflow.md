# Project Log — 唯讀盤點

只做範圍解析與狀態偵測。先讀 [ship-policy.md](ship-policy.md) 辨識 exact endpoint；
本階段不寫文檔、不切 branch、不 commit、不 push／PR／merge／cleanup。
需要互動時使用 workflow 的 Runtime adapter。Explicit endpoint 不豁免 STOP。

## Step 0：範圍鎖定

### 引數前處理（依**形狀**分類，不靠優先序記憶）

引數逐 token 依形狀歸類 —— **形狀規則的好處是不需要記「誰先誰後」**，同一個字不會因為位置不同而有兩種讀法：

| 形狀 | 是什麼 | 例 |
|---|---|---|
| `--` 開頭 | **flag**（模式或送出說法） | `--log` `--merge` `--pr` |
| `resume=`／`as=`／`to=` 開頭 | **authority／transfer control token** | `resume=codex:integration` `as=owner:repo-maintainer` `to=codex:beta` |
| 裸字，且是模式名 | 模式（僅限**第 1 個** token） | `spec` `log` `transfer` |
| 裸字，且命中說法表 | **送出說法**（見 `ship-policy.md`「說法表」） | `merge` `bypass merge` |
| 含 `/` 或 `.` 開頭，或存在的路徑 | repo 或 module —— 交給 `resolve` | `.` `~/Projects/krepo` `./docs/plans` |
| 其餘裸字 | 可能是 repo basename（session 記憶）→ **不命中就停下問** | `krepo` `dotfiles` |

**Module 過濾一律走路徑形式。** 裸字**永遠不會**被當成 module —— 那條舊路徑會在打錯字時靜默縮小 Step 2 的掃描範圍（掃不到的文檔不會報錯，只是沒被同步）。要以 `merge`／`pr` 這種字面當 module，寫 `./merge`、`docs/pr`。

repo / module 的判定交給腳本（**the script IS the path/realpath/toplevel logic — do not re-derive it**）：

```
<project-scripts>/ship-state.sh resolve <token>
```

- `resolve: REPO <root>` → 鎖定該 repo，**跳過多 repo 偵測互動**。
- `resolve: MODULE` → 當 module 過濾（Step 2 用），不鎖定。
- `resolve: UNKNOWN` → 比對 session 記憶中的 repo 根 basename（`krepo`、`dotfiles`）——命中即鎖定；**不命中 → 停下問使用者這個字是什麼意思，NEVER 自行當成 module 或忽略**。

flag 與裸說法**等價**（`--merge` ≡ `merge`），兩者都只是 Step 4 的授權來源；差別僅在 flag 靠形狀就無歧義。**說法也可以出現在對話裡、不必寫進引數**（見 Step 4 路徑 A）——那條路徑沒有 flag 形式，這是刻意的。

鎖定單一 repo 後 → 直接進 Step 1（不問多 repo 清單）。

### 多 Repo 偵測（無 repo 引數時）

依本 session 記憶列出所有涉及變更的 repo（**不掃 `~/Projects/`**）：

1. 回憶 session 中改過檔案的所有 repo 根目錄 + pwd 所在 repo。**獨立於使用者明列的 closed set 偵測**：
   exact roots 是下一步的比較基準，不是這一步的過濾器。即使使用者只明列 A/B，若 pwd 位於有待送出變更的
   C，也要把 C 列入偵測；不得自行以「C 不相關」排除。
2. **單一呼叫**確認全部 repo 狀態：`<project-scripts>/ship-state.sh <repo1> <repo2> ...`（先把
   `<project-scripts>` 展開為 shared workflow 所解析的絕對路徑；default branch 偵測、三點/兩點變更集、
   upstream 邊界、protection 判定全在腳本內）。Step 1 直接沿用同一份輸出，**不重跑**。
3. 顯示確認前先檢查是否有 **closed repo-set evidence**。這只是省略重複互動的 session-local evidence，
   不是 durable authority；只有以下條件**全部**成立才可沿用：
   - 當前明確任務，或同一段未壓縮對話中緊接且成功完成的 Project Spec，已列出並接受一組 exact canonical
     repo roots；checkpoint、runtime memory、basename 推測或較早且中間已有 scope 指令的紀錄都不算。
   - 第 1 項重新偵測出的 canonical root 集合與該組證據完全相同，且使用者此後沒有增刪 repo。
   - 第 2 項對完整集合的單次重驗沒有 missing／UNKNOWN／路徑歧義；結果能逐一對回同一組 roots。

   三項全成立時，顯示鎖定集合與重驗摘要，標明證據來源；集合**完全相同就不顯示三種確認路徑、不再詢問
   repo range**，直接沿用第 2 項輸出進 Step 1。若重新偵測多出或少了 repo，只列受影響的 roots、保留未變的
   交集並**只詢問 repo-set delta**要加入、保留或移除；在此選擇前不得推進到任何 commit／push／PR／merge，
   本輪 `--merge` 也不代替範圍選擇。不得連帶重問已驗證集合。missing／UNKNOWN／歧義
   仍停在該 delta，不得猜測。沿用或處理 delta 均不得授予 `as=`／`resume=` authority、shipping authorization、
   endpoint 或任何 STOP 豁免。
4. 沒有可沿用的 closed repo-set evidence 時，展示清單並明列三種互斥確認路徑；第一項是預設建議，
   不把 `ok` 的語意藏在自由回答裡：
   ```
   本次涉及 2 個 repo：
     1. krepo（領先 default 2 commit）
     2. pilot-api（3 檔未提交）
   - 全部偵測到的 repos（建議）：處理上列完整集合
   - 只處理指定 repos：從上列集合收窄
   - 補充其他 repos：解析並加入漏列的 repo
   ```
   使用者選「全部偵測到」後，在**同一次 Project invocation** 鎖定剛展示的集合並直接進 Step 1，沿用
   第 2 項的 `ship-state.sh` 輸出；不得要求重新輸入 `/project`／`$project`、逐一補 repo paths 或重跑相同
   detection。範圍回覆只決定 repo 集合，不寫回 normalized invocation arguments，也不授予 `as=`／`resume=`、
   shipping authorization 或任何 STOP 豁免。選「只處理指定」時才過濾既有集合；選「補充其他」時才用
   `resolve` 解析新增 repo 並補取其狀態。
5. context 被壓縮 → closed repo-set evidence 不可用；以 pwd 的 repo 為底讓使用者補充，使用者指定的 repo
   即使無變更也納入。
6. 全部 repo 既無領先 default 的 commit 又無 working tree 變更 → **勿直接結束**：先逐 repo 依 Step 1 第 2 項的 **docs-only mode** 判定（session 有已 ship 變更的 repo 仍納入，跑文檔同步）。git 無變更**且** session 記憶亦無已 ship 工作 → 才告知並結束。
7. **單一 repo → 跳過此步，直接 Step 1。**

## Step 1：唯讀偵測與下一階段

沿用 Step 0 的 `ship-state.sh` 輸出；單 repo 鎖定時在此直跑一次，不逐條重跑其 Git／gh 偵測。
變更集取 `files-vs-default` + `working-tree`，不是只有未 push commits。

- 偵測成功、無 STOP，且各 repo `changes: NONE`、本 session 沒有已 ship 但文檔未同步工作：如實回報無工作，結束。
- Git 無變更但本 session 有已 ship 的工作：屬 docs-only，從具名已 ship commits 重建受影響檔案，
  進結案準備確認文件；不能只憑 clean tree 跳過。
- 有變更、docs-only 或需處置的 gate：先讀 workflow 的 Log 結案 prerequisite，進
  [log-prepare.md](log-prepare.md) Step 1，沿用這次偵測。STOP 只容許該 gate 的合法準備／修復。
- 無 remote、provider／authority 不明不可假造 no-work；保留偵測錯誤並按 preparation 的 STOP 分流。

`origin` 代表 canonical remote：有 origin 用它，否則第一個；沒有 remote 停下告知。
多 remote 若是 fork（push 與 PR/protection 目標不同），或 GitHub Enterprise，先讀
[ship-exceptions.md](ship-exceptions.md)，不猜 endpoint／身分。Unknown protection 視為 protected。
