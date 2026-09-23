# Deep Plan shared workflow

## Purpose and invariants

先以具體風險決定尚未實作的 implementation plan 需要哪種開工路徑。一般工作用明確驗收與可回復的小增量；
只有下節觸發完整審查時，你才是 orchestrator、由獨立 fresh reviewers 查證，不得自行冒充獨立 review。

下列 round invariants 與 §2–6 僅適用完整審查路徑：

- 每輪預設 `N=2`；只有使用者明確要求更廣抽樣時才增加。
- 每輪 reviewer 都必須是全新 context。建立與等待的順序由載入本文件的 runtime entry 約束；沒有有效 reviewer handles 時 fail closed。
- reviewer 只回報，不改寫計畫。Reviewer verdict 不是 approval。
- 最多兩輪；不得用第三輪追求表面收斂。
- target repositories 在 reviewer 工作期間唯讀。不得修改本 skill、eval、field log 或無關 repo。
- reviewer prompts 不含前輪 findings、作者解釋、round number、進度提示或 plan 內文。

完整路徑追蹤：artifact/repo 已確認、第一輪完成、findings 已處置、第二輪完成、gate 已回報。

## 1. Confirm artifact and scope

確認輸入是既有且尚未實作的 plan/spec，並辨識所有目標 repo。已寫 code 改走 code review；要產生 plan 改走 planning workflow。

Reviewer 必須能從檔案讀取計畫：已有 canonical plan 就直接使用；只在對話中時遵循目標 repo 的文件慣例，否則放在不會隨 repo ship 的明確 scratch artifact。不得用 heredoc、echo 或 printf 寫入使用者提供的 plan text。落點跟目標 repo，不跟目前 cwd。

多 repo 計畫交給同一組 reviewers，讓每位 reviewer 查跨 repo 一致性。

## 1a. Risk route before reviewer dispatch

先讀計畫及其直接相關的 repo contract／實作，核對此次變更的影響，不先載入完整 reviewer brief 或派人。
以下任一成立就進 §2–6：

- 使用者明確指定完整審查、兩輪或 reviewer 數量。
- 有難以回復的持久資料／production state 變更，或驗證／回復失敗會造成重大不可逆損失。
- 改變 security／permission 邊界，或實際改變告警、豁免、過濾、SLA等放行／攔下的行為。
- 不相容的跨repo／對外介面，或需要協調切換才能避免資料錯誤、失去既有能力或服務中斷。
- 已找到關係到上述重大後果、但尚未能查明的具體事實缺口；不要用「尚有任何未知」代替風險證據。

記錄觸發原因與指向的變更／repo證據。計畫長、步驟多、跨repo、缺永久test carrier、既有無關缺陷，
本身不構成高風險；不得因本地可回復increment而盤點所有歷史債。相反地，「只是小改」或拆小步驟不能
隱藏實際權限、資料或介面後果。判準是否改變看產品行為，不因刪除非目標工作清單就當成放寬安全判準。

沒有觸發時，不啟動 §2–6，直接核對既有計畫是否足以指定下一個increment的目標／非目標、修改邊界、
可執行驗收及回復方式；已寫清楚不另建spec、補架構或新增文件。真正的產品歧義提出一個最小決策問題與
選項，標 `NEEDS-DECISION`；查證到會違反既定驗收的問題則具體指出待修正處，不靠完整review猜答案。
條件足夠就回 `READY-FOR-INCREMENT`，簡述核對依據、下一個increment及停止驗證的條件，明說未進行獨立
多輪審查，不冒稱完整review `GO`、實作測試通過或release approval。這不修改原Goal、shipping gates或授權；
只要求審查時不改code，已另外授權後續實作時可接著做原scope，不為切換階段再問一次。發現新的實質高風險
才重新分流，不以「再看一次可能更安心」重開探索。

## 2. Dispatch a review round

完整讀取同一 references 目錄中的 `reviewer-prompt.txt` 與 `planner-brief.md`。每位 reviewer 的任務都必須由
這份 shared template 產生，只替換 plan、repo、brief 的 absolute paths 與 criteria placeholder；不得增刪或
改寫其他語意。`REPO_ABSOLUTE_PATHS` 每個 repo 各佔一行並縮排兩格。

若計畫改動告警、權限、豁免、過濾、SLA 或其他放行／攔下判準，將
`criteria-impact-prompt.txt` 的完整內容代入 `CRITERIA_IMPACT_PARAGRAPH`；其他計畫代入空字串，也不替 reviewer
客製焦點。依 runtime entry 先建立本輪全部 fresh reviewers，取得有效 handles 後才收取結果；無法建立時停止，
不由 orchestrator 補審。

## 3. Synthesize without filtering

只有在本輪恰有 N 份可歸因的完整 reviewer results 時才進入 synthesis；任何 reviewer error、partial result、
缺少四個輸出 sections，或 finding 缺少問題／層別／嚴重度／證據任一欄，都視為 orchestration failure 並停止，
不得把 malformed finding 當成 non-blocking 或用其他 reviewer 補位。

按「同一件事」合併 findings，不按措辭或嚴重度合併。保留每位 reviewer 的證據與原始層別／嚴重度，標出獨立命中數；單一 reviewer finding 也完整保留。分類不同就並陳，不自行降級、柔化、壓掉或發明 finding。

只有「可查證」且嚴重度為阻斷／高／中的 finding 會 blocking。判斷層或低級 findings 照列但不擋開工。

## 4. Obtain explicit dispositions

每條 blocking finding 必須取得一種處置：

- 修正：更新同一份 canonical plan，由作者修改，不另建 revision。
- 駁回：提供可查證 repo evidence 證明是 false positive。
- 接受 trade-off：記錄代價與重議條件到 repo 既有決策存放處；沒有既有存放處時放入本次報告的獨立處置節，不代建新 store。

`noted`、沉默、條件式 approval 都不算處置。以「既有 X 也如此」駁回，或要新增測試固定被質疑的行為時，重新查 X 的理由是否適用於新情境。沒有完整處置就停止；未獲授權時不得代作者改 plan 或選 trade-off。

## 5. Fresh second round and gate

處置完成後，以相同 N、相同 prompt 和已更新的同一 artifact 建立另一組 fresh reviewers。Prompt 不提第二輪、前輪 finding 或修正；仍依 runtime entry 先取得本輪有效 handles。

- 沒有 blocking finding：`GO`。
- Blocking findings 全部精確對應已接受且已記錄的 trade-offs：`GO`，逐條列殘留風險。
- 有新 blocking finding 或舊 finding 未有效處置：`NO-GO`。

兩輪後停止。若阻斷集中在缺少的事實，先取得事實；若已動到 Goal、核心判準或架構，退回 spec/Goal 決策。Finding 變少不是收斂證據。

## 6. Report

回報 `GO`／`NO-GO` 與直接理由、合併 findings（原始分類、獨立命中數、證據、處置）、已驗證與未驗證宣稱、第二輪新 findings，以及接受的殘留風險。若不通過，說明要補哪項事實或回到哪個 spec/Goal 決策。不要附 skill telemetry 或無關 shipping 提醒。
