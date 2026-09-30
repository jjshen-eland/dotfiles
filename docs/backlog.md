<!--
backlog.md — 專案未結案待辦（技術債 + 已知缺口）。發現即記；解決或放棄後寫 D/X/M history
record、保留 B-* 關聯，再移除本檔條目。decision／dead end 不留在 STATUS.md 或本檔。
-->

# Backlog

待辦清單:技術債與已知缺口(更新日期:2026-09-29)

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

- **B-20260928-project-merge-continuation** · **#229 Scenario 36 的主要修復已驗證，剩餘
  first-delta safety coverage 與本輪發佈待完成**。原始 RED：2026-09-25–28 同一
  Codex session 以 `krepo-common` 為起點完成 KB Platform 八 repo workline；排除環境說明中的文字後，
  使用者共明確輸入 10 次 `$project --merge`，8 次在實際 shipping 前停下，合計產生 10 個
  確認：3 個 repo-set 範圍選擇、7 個 actor／workline／resume 選擇。至少 8 個是正常路徑
  false STOP：三次 repo set 已由當前任務或緊接的 Spec 封閉，五次是同 session、同 workline
  且 Writer／Workspace／Write Scope 無變更時重複 resume。2026-09-28 11:00 剛在 Spec 確認
  Common／Disclosure steward，12:03 的 `--merge` 仍再問一次，是
  `D-20260923-project-session-workline-binding` 的直接真實回歸。樣本中沒有一次真正需要
  formal Project Transfer。

  2026-09-29 新增 `kapi-infra` 實例：HEAD `21043519cb885237bceae482f7c2128a44de57b2`，
  durable steward 是 `codex:ais-infra-org-readiness`，current branch actor 是
  `codex:infra-closeout-44-45-86`，authority gate 在 outward 前要求「接續／停止」。
  這個 mismatch 足以支持先停下重驗，但不能單憑這段輸出斷言「必須問使用者」：
  若同一 session 有可驗證的 Spec／workline binding，應自動對回 durable steward 續行；
  只有 binding 不存在、過期或有真實 assignment delta 時才把選擇交回使用者。

  兩個其餘中斷是混合情境：Protocol 缺 active contract 且候選修改 shared dossier，當下
  需先建 contract／重建候選；Disclosure 候選由錯誤 actor 修改 steward-only 文件，當下也需
  重建，但候選是同 session 自行產生，應在 authoring 前解析 durable steward，不應把自造的
  actor drift 延後成使用者決策。這些證據表示 9/23 的 Spec／helper fixture 通過不能外推
  full Log／shipping，現行 multi-repo Step 0 的無條件 range selection 也是獨立成本。

  **分 root cause 改善狀態**：

  1. `closed repo-set reuse` 於 2026-09-29 形成候選、後經 PR #240 合併：當前使用者任務或同一
     未壓縮 workline 中緊接 Spec 的 exact canonical roots，重新 discovery 與 `ship-state.sh`
     重驗完全一致時略過 Step 0 range 問題；只對新 repo、遺漏 repo、UNKNOWN 或範圍衝突
     詢問 delta。此分項有 production RED、deterministic gate 與 1503／0 suite 證據；不能單獨
     外推為下列 binding／provenance 已修復。
  2. `workline-binding propagation` 於 2026-09-29 形成候選、後經 PR #240 合併：Spec helper exact PASS
     後按 canonical root 封存 current-session packet，下一次 Log 先以原 assignment fingerprint
     與本輪 HEAD 重驗；完全一致就不回退 branch-derived actor 或重問 `resume=`。新 session、壓縮
     context、item／Writer／Workspace／Write Scope／Steward／transfer delta 仍走既有 recovery。
     Fresh Claude 首輪暴露「Spec 本輪新建 contract 沒有建 assignment」的缺口，已改為
     新建 exact same-runtime contract 後直接用 original fingerprint／full HEAD 建立 binding；
     Claude／Codex fresh normal 重驗皆 PASS。
  3. `candidate actor provenance` 於 2026-09-29 形成候選、後經 PR #240 合併：任何 shared dossier
     mutation／commit 前先取得 durable-authority PASS；若錯 actor candidate 已存在，只有 current-session
     binding PASS、candidate 是 pre-candidate HEAD 的單一直接子 commit、tree clean、無 remote-tracking
     ref、Step 1 證明未 push／無 PR 且無使用者／worker／parallel work 混入，helper 才回
     `candidate-rebuild: READY`。
  4. `completion authority` 的 fresh RED 顯示，active item 移除後可以 plain
     `no-active-items` 重跑 helper 洗成 PASS，並在 endpoint 前誤寫 shipped。新
     `--completion-parent` 要求候選是原 assignment parent 的 clean direct child，且同時輸出
     `completion-candidate: READY`／PASS；兩 primary normal 均通過，milestone 保留 endpoint pending。
  5. `Ship 摘要 ordering` 的第一版 prose gate 仍有 fresh RED：Claude 把「結案 gate 通過」
     當成摘要，先 push local fixture branch 才回報。Step 5 現以緊鄰且以字面
     `Ship 摘要：` 開頭的 assistant content 作 outward entry oracle；一般狀態更新不算。
     Fresh after 的先後順序已 PASS，但「路徑=PR」被當成 ship route，摘要漏了 exact canonical
     roots，故該輪仍是 partial FAIL。新 gate 要求每 repo 獨立列
     `repo root: /absolute/canonical/path`，basename 或 ship route 不能代替。最後新 session
     的 raw events 已驗證兩個 exact roots 與完整摘要緊鄰第一個 push，此 sub-oracle PASS。
  6. 如果仍有真實 gate，一次只列出有 delta 的 repo 並合併詢問；已驗證的 repo 繼續授權範圍內
     準備，不連帶重問。

  **不放寬邊界**：新 session 只有 checkpoint／memory、真實 Writer 衝突、scope 變更、
  PREPARED transfer、無 active contract 且無當次指派，仍必須停；registry publish、production
  deploy／service stop、ACL／schema／credential 變更與刪除仍要各自的明確授權。
  **驗收**：當 exact repo set 與 actors 剛由 Spec 確認，且重驗無 delta，緊接的
  `$project --merge` 必須零 scope／resume 問題並直接到 endpoint；另以新 repo、真實 writer
  衝突、scope 變更與 production action 作 safety arms。15 個 helper controls 與完整 suite
  1508／0 已通過；兩 primary fresh normal 已驗證 binding／completion，Claude 另驗證
  exact-root Ship 摘要在 push 前緊鄰出現；safety 也證明
  scope、checkpoint、dirty／remote-visible candidate、deploy／delete 不越權。最後 literal-summary
  fresh after 已通過 exact canonical roots 與 push ordering 驗收。真實 GitHub PR／兩平台 required checks／
  rebase merge／本地同步已由 PR #240 驗證；原本未取得的 new-repo delta native packet 於 2026-09-30
  在雙 primary fresh fixture 重現 RED：從有未送出 commit 的 C 啟動，明列 A/B 為 closed roots，兩端都
  靜默排除 C 並先推送 A/B local bare feature refs。Step 0 最小修正後，雙端 delta 均只問 C、
  且三個 repo 的 tree／index／HEAD／remote refs 不變；雙端 normal 均零 range 重問並推送 A/B
  local feature branches，provider 缺席時不直推 main。修正與原始 trace 雜湊見
  [#229 驗收計畫](plans/2026-09-30-issue-229-closure-evidence.md)。本輪新修正已在本地 feature branch
  提交 `314fac4`，尚未 push／PR／merge；其餘
  Scenario 36 safety arms 仍有 fixture 在第一個語意 delta 前停下的限制，需依相同獨立 oracle
  補有效 native packet，故此項與 #229 目前仍 open。
  關聯 Scenario 36／GitHub #229／PR #240。

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
  **觸發條件**：下一個真正需要full review的日常工作，或新的機制能提出包含正常完成與安全控制的固定驗收；保留exact scope／prompt／工具結果／終態後只修該root。
  不重跑本次同一packet或單純加時洗綠；新證據需能區分修後範圍成本與runtime完成／等待成本。
  **驗收邊界**：小型同機Spec與parallel controls不能外推完整Log／shipping、跨host或所有必要互動；遇實際該路徑失敗再重議。
  證據：[review audit](plans/2026-09-23-review-convergence-audit.md)、[coordination audit](plans/2026-09-23-coordination-audit.md)。

- **B-20260824-remote-human-contributor-path** · **單一 Dossier Steward 模型尚未定義跨機器真人
  contributor 的 commit 傳遞路徑**(2026-08-24 發現)。`D-20260824-cross-runtime-dossier-stewardship`
  的 v1 只實證同機 Claude／Codex worker：非 steward 不改 shared dossier、不 push，交 semantic commit
  給 steward cherry-pick；但真人同事在另一台機器時，若不能 push 專屬 feature branch，就沒有自然的
  commit 交換媒介。2026-09-16 以現行 feature branch／PR、Project authority gate 與可取得的 rollout repo
  紀錄重驗：Git 傳遞媒介存在，steward 評估 candidate commit 時也能列出 shared-surface 越界；但 worker
  no-push 契約與不辨 contributor 身分的 PR CI 尚不能合成一條已驗證的新路徑。可取得的 PR／commit 紀錄沒有
  remote-human contributor 實例，未觀察到實際傳遞阻塞或 authority drift，故不新增程序、eval 或 provider
  gate，也不把候選路徑宣告生效。**精確觸發**：第一位具名、跨主機真人 contributor 需要交付 commit，或
  首次出現非 steward PR；當下保留 exact SHA、declared scope 與 Dossier delta，實測 steward 能否 fetch、
  以現行 helper 排除 shared-surface 越界並 cherry-pick。任一步受阻，或越權 shared dossier mutation 未被攔下，
  才以該事件取得 RED 並設計最小 remote-contributor path。

- **B-20260807-gap-04** · **Mac 上 brewup 會被 codex cask 掛死(Gatekeeper)**:2026-08-07 第三次發作。復原已有入口
  `brewfix`(唯讀診斷,`--fix` 才動手);機制、鑑別法、三條走不通的預防路徑全文見
  `claude/known-hazards.md`「cask 升版卡死」,**此處不重述**。**仍未解**:確切觸發條件未知且事後無法重現
  (同版本內容換路徑執行正常),要重現只能等該 cask 真正出新版。**未決**:預先設 xattr `0x0040`
  技術上可行,但前提已被負面結果動搖、代價卻是確定的(拿不到 tarball 簽章身分)——
  **用確定的代價換不確定的效果,暫不做**,優先靠已實證的復原路徑。
