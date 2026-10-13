<!--
backlog.md — 專案未結案待辦（技術債 + 已知缺口）。發現即記；解決或放棄後寫 D/X/M history
record、保留 B-* 關聯，再移除本檔條目。decision／dead end 不留在 STATUS.md 或本檔。
-->

# Backlog

待辦清單:技術債與已知缺口(更新日期:2026-10-13)

> **為什麼與 `STATUS.md`／history 分家**：三者生命週期不同。STATUS 只留 active／paused；history
> event 發生後 append-only；backlog 只留未結案狀態，直到做掉或明確放棄才會消失。
>
> **本檔刻意沒有 bytes／行數門檻**；治理靠 stable ID、關閉關聯與 repo-local audit。

## 關閉與歸檔慣例

- **償還／解決**：寫 `M-*` record，`關聯` 保留原 `B-*`，再移除本檔條目。
- **變成決策**：寫 `D-*` record（含理由與重議條件），再移除本檔條目。
- **明確放棄**：寫 `X-*` record，再移除本檔條目。
- **不刪**未解決的條目；看不順眼、過長或暫時不做都不是關閉條件。

## 技術債

- **B-20260902-gh-account-autoswitch** · [ ] **`gh` 的 active 帳號沒有依 repo 自動切換**（2026-09-02 加）。
  `gh` **完全不看 SSH alias**，active 帳號不對時的長相是 `Could not resolve to a Repository`
  ——不是權限錯誤，是「查無此 repo」（對那個帳號來說它確實不存在），所以第一次撞到很難聯想。
  現況只補了文件（`docs/repo-guide.md`「GitHub 多帳號：三個互不相干的層」），要人自己
  `gh auth switch`。
  ⚠️ **本批刻意不做 helper**，理由是兩條路都不乾淨：wrap `gh` 要改 PATH、影響所有 `gh` 操作、
  且有把非預期子命令攔下的風險；只在 shell function 覆蓋部分子命令則**覆蓋不全等於沒有**
  （漏掉的那個子命令仍會用錯帳號，而且症狀一模一樣）。
  - **觸發條件**：跨帳號操作變成常態、或同一個症狀再查錯方向一次。屆時傾向做成
    **唯讀提示**（進錯帳號時警告，不自動切），先驗證偵測那半是否可靠。

- **B-20260916-sessionstart-behind-warning-field-observation** · [ ] **SessionStart 落後提醒尚無可歸因的真實事件證據**。
  現行 hook 與 deterministic multi-remote fixture 都仍有效，未觀察到行為缺口；但 hook 不留持久 log，Git reflog
  也沒有能同時證明「由 SessionStart 執行」與「當時 HEAD 真的落後」的日後記錄。
  **精確觸發**：下次在某 clone 的當前 branch 已設 upstream、remote 自然多出 commit，且正常啟動 Claude
  session 時，當下保留 hook stdout 以及 `HEAD..@{u}` 計數；若提醒正確則結案，若漏報或誤報則以該事件先取得
  RED 再修。不為清 backlog 人工推遠端、不新增持久監控或啟動噪音。此項由
  `B-20260820-debt-17` 拆出。
## 已知缺口

- **B-20261005-root-cause-first-sonnet-evidence** · [ ] **Sonnet robustness probe 在 evidence 不足時仍外推資料語意與排除結論**。
  原版及兩個 frozen wording candidates 的 insufficient case 都把未明單位的 aggregate 42/37
  當作缺五筆 records；v2 已拒絕 +24h 猜測修法，仍在對客戶的建議說法中把兩次修改無效稱為
  「已排除 timezone 與 inclusive range」。兩入口／shared linkage 有效，raw Read、source hashes、
  native artifacts 與 zero mutation 已核對，不能用未讀 skill、auth 或 transport 解釋。
  後續以 repo 實際 Claude target `opus[1m]` 補驗：原版重現同一 RED，v2 insufficient 轉綠且
  repair／continue／trace-only controls 通過；Codex v2 四案亦通過，因此正式 workflow 採用 v2。
  這不把 Sonnet 結果改判為 PASS；依中央模型角色政策，它是保留的非阻斷 robustness evidence，
  若未來明確承諾 Sonnet 為 target，仍須先處置本項。
  **下一項有區分力的驗證**：固定模型／runtime／任務與壓力，分別比較明示 count、明示 weighted sum、
  未指定 aggregation 的 task evidence，以及 skill 有／無的相同控制；另核對「patch 無效」是否被
  不當當成「假設已排除」。先區分 fixture 語意誘導、模型先驗與 instruction gate，暫不再堆 wording。
  **結案證據**：在 Sonnet 的獨立新 evidence 上保持量測定義／假設狀態未知，
  不推薦未知語意修法，並維持已授權修復、唯讀 scope 與 containment honesty；不能以標籤、零變更或
  CLI exit 0 替代。Raw Sonnet v2：`/tmp/root-cause-first-candidate-v2-terminal-20261005-125819`；
  Opus target：`/tmp/root-cause-first-opus-{completion,v2-insufficient,v2-controls}-20261005`；
  詳見 `docs/plans/2026-10-05-root-cause-first-model-behavior.md`。

- **B-20260924-workflow-verification-economy** · **#229 整合case完成但verification／文件收尾仍有額外成本**。
  2026-09-24同一多步驟task兩primary均一答恢復且不擴scope；Opus仍在文件only變更後重跑suite兩次，另做一次mutation check，
  測試接tail未保留原exit；root獨立suite／semantic exit0只能證實產物正確，不能讓程序瑕疵變GREEN。
  Opus完成項仍留fixture的Active，且兩端未選的「合併」選項仍需補子決策；沒有全面驗收所有互動／文件生命周期。
  PR #233 前後已再次觸發：active contract 提早移除導致 local candidate 重建確認，merge 子任務結束後仍
  有上層工作卻自行結束回合，後續解釋也未接續。不能再以「等待新實例」擱置。新的本地 CI 修復 stage
  兩 primary before 已可直接完成，反證不足以用刪 STOP 文案修好整體問題；見 [接續稽核](plans/2026-09-24-ci-continuation.md)。
  使用者選定的隔離 Stop prototype 已完成 8 項 deterministic 與雙 primary 六組 native 測試；最多一次自檢
  生效且對照未越權，但沒有 early-stop RED，反而重複完成訊息／必要問題。因此不正式安裝，不追加相似
  probes；中斷缺口未結案，raw artifacts 與啟用所缺證據見同一接續稽核。
  Lifecycle 候選亦未採用：歷史 commit 已重現契約 ancestry 缺失，但雙端驗收被 fixture 缺陷污染。
  使用者依 D-20260924-continuation-bounded-closeout 選擇先收斂交付，不追加本批模型測試；
  不把修好的 fixture 預檢當行為通過，也不把剩餘缺口留成等待一句「繼續」的工作。
  **觸發條件**：日常同類工作再次出現無新失敗的重複驗證、exit masking或完成後重新要「繼續」時，保留實際trace與scope，優先刪除或合併該步；
  不為此重跑已完成的整合fixture，不靠新增always-on規範宣稱修好。詳見[整合驗收](plans/2026-09-23-coordination-audit.md)。
  **真實交付補證（2026-10-13）**：Codex PR #329 從「繼續」至交付 14:49.7，本地 suite 132.515 秒、CI 152 秒，
  測試完成至 PR、CI 完成至 merge、merge 至回報合計約 6:57；尚無端到端加速證據。口徑、回合空檔與比較限制見
  [M-20261013-pr329-delivery-measurement](archive/milestones-2026-10.md)。沒有在正式 Log 重跑整批 suite，
  也不能以 null `task_complete` 判成模型主動 early stop；本项仍 open，優先調查實際非測試階段的成本，
  不以重跑舊 fixture、追加規則或不同工作量的樣本宣稱已改善。
  **跨 repo 對照（2026-10-13）**：[kapi-infra／krepo-common 實測](archive/milestones-2026-10.md)（`M-20261013-cross-repo-delivery-measurement`）
  已補：kapi-infra 四筆 Claude 小提交扣使用者等待後中位 3:46.4；krepo-common 同批三筆 CI 17–21 秒。
  但前者多為暖 context，後者屬跨 repo 批量送出，且 kapi-infra 的舊 Codex 案亦有 32:45.1；
  不把 runtime／互動／CI 版本差異當 dotfiles 特有根因。下一步以 PR #329 非測試階段的 exact trace 調查，
  或取得固定條件的真實對照；本項不因此結案。

- **B-20260924-workflow-review-residuals** · **#229 完整高風險review與大型工程驗收仍有限制**。
  後續single-pass四案已完成；原harness自行設定USD4／600秒截斷，不能據此判定工作流不收斂，
  亦非使用者訂閱帳號限制。去除上限後原session接續完成；雙端一般一次review＋作者驗證已啟用。
  2026-09-25已區分steward必要文檔維護與implementation scope，並要求completion parent保留新assignment，
  不再為同工作文件逐檔擴scope／重問。Opus與明示Project入口Sol的focused產物驗證通過；generic Sol
  未載入Project漏接手仍FAIL，不能宣稱任意commit請求皆可靠。Opus先前shipping安全案有略讀必要reference、省略required
  flag及pipeline遮蔽exit的偏離。這些不抹去review與closeout分項成功，但不擴稱所有shipping協定
  已修好；原patch現為歷史快照，新增已驗證部分已進source。
  實作及逐案限制見下方同一實作紀錄。主agent回答插問以final
  結束回合亦已實際復發，不能宣稱整體接續已解；不另加模型輪次或規則洗綠。
  歷史delivery-mechanism packet曾執行八case；Sol after正常一答修好兩repo但人工600秒內
  未完成修後review/shipping，Opus after正常收到答案時已近USD4且修復命令未執行。共同授權候選與
  runtime focused當時均未採用；人工上限造成的失敗推論已撤銷，歷史helper／transport與diff保存於
  [本批實作紀錄](plans/2026-09-24-production-batch-boundary.md)。不追加同packet來換綠燈。
  舊版另實證不相關backlog／Write Scope擴張、producer重複改派確認，以及read-only consumer的
  `.git` terminal anchor寫入；新版Opus安全case亦有角色更新晚於code edit的順序缺口。
  已保留的risk activation、same-session binding、local reassignment與terminal顯示修復，不代表完整review已驗收。
  原Opus完整code-review曾在reviewer曝光作者目標／plan後仍PASS；Sol terminal replay未在固定預算內完成；
  full deep-plan的收斂／prompt transport及大型真實code-review非收斂尚未獲得替代機制的完整證據。
  使用者已選「首次全面、修後聚焦」；2026-09-24 code-review候選的Opus正常／安全與Sonnet安全可完成，
  Sol正常before／after均600秒未完成、safety240秒未完成，故候選未採用。scope helper的stdout sandbox
  阻塞已獨立修好，不把它當作上述完成率問題已解。詳見[修後驗證紀錄](plans/2026-09-24-review-followup-design.md)。
  本輪依D-20260924-workflow-bounded-delivery不追查、不加規則、不重跑原packet；正確程式產物仍保留，無效獨立review不得當shipping證據。
  2026-10-03 code-review controller 已落實有界 admission／repair preflight／current receipt，雙端修正後 ordinary、
  blind／focused 的程式產物及 cap／ownership controls 通過；保留共同 blind／三次修復預設，focused 明示 opt-in。
  仍未解：Sonnet 改寫 generated packet 或只傳 path；Sonnet／Opus 用摘要替代原報告；Codex native task body
  加密使逐字 transport 核對不可得。機械欄位／snapshot 驗證不代表內容忠實或全域隔離，原始 RED 保留，
  不以 34 次 native 終態或小型 fixture 宣稱本項結案。證據與具體重議條件見
  [controller 實作紀錄](plans/2026-10-03-review-repair-controller.md)及 D-20261003-review-repair-controller-adoption。
  **觸發條件**：下一個真正需要full review的日常工作，或新的機制能提出包含正常完成與安全控制的固定驗收；保留exact scope／prompt／工具結果／終態後只修該root。
  不重跑本次同一packet或單純加時洗綠；新證據需能區分修後範圍成本與runtime完成／等待成本。
  **驗收邊界**：小型同機Spec與parallel controls不能外推完整Log／shipping、跨host或所有必要互動；遇實際該路徑失敗再重議。
  證據：[review audit](plans/2026-09-23-review-convergence-audit.md)、[coordination audit](plans/2026-09-23-coordination-audit.md)。

- **B-20260807-gap-04** · **Mac 上 brewup 會被 codex cask 掛死(Gatekeeper)**:2026-08-07 第三次發作。復原已有入口
  `brewfix`(唯讀診斷,`--fix` 才動手);機制、鑑別法、三條走不通的預防路徑全文見
  `claude/known-hazards.md`「cask 升版卡死」,**此處不重述**。**仍未解**:確切觸發條件未知且事後無法重現
  (同版本內容換路徑執行正常),要重現只能等該 cask 真正出新版。**未決**:預先設 xattr `0x0040`
  技術上可行,但前提已被負面結果動搖、代價卻是確定的(拿不到 tarball 簽章身分)——
  **用確定的代價換不確定的效果,暫不做**,優先靠已實證的復原路徑。
