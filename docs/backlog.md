<!--
backlog.md — 專案未結案待辦（技術債 + 已知缺口）。發現即記；解決或放棄後寫 D/X/M history
record、保留 B-* 關聯，再移除本檔條目。decision／dead end 不留在 STATUS.md 或本檔。
-->

# Backlog

待辦清單:技術債與已知缺口(更新日期:2026-09-24)

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

- **B-20260924-workflow-verification-economy** · **#229 整合case完成但verification／文件收尾仍有額外成本**。
  2026-09-24同一多步驟task兩primary均一答恢復且不擴scope；Opus仍在文件only變更後重跑suite兩次，另做一次mutation check，
  測試接tail未保留原exit；root獨立suite／semantic exit0只能證實產物正確，不能讓程序瑕疵變GREEN。
  Opus完成項仍留fixture的Active，且兩端未選的「合併」選項仍需補子決策；沒有全面驗收所有互動／文件生命周期。
  **觸發條件**：日常同類工作再次出現無新失敗的重複驗證、exit masking或完成後重新要「繼續」時，保留實際trace與scope，優先刪除或合併該步；
  不為此重跑已完成的整合fixture，不靠新增always-on規範宣稱修好。詳見[整合驗收](plans/2026-09-23-coordination-audit.md)。

- **B-20260924-workflow-review-residuals** · **#229 完整高風險review與大型工程驗收仍有限制**。
  已保留的risk activation、same-session binding、local reassignment與terminal顯示修復，不代表完整review已驗收。
  原Opus完整code-review曾在reviewer曝光作者目標／plan後仍PASS；Sol terminal replay未在固定預算內完成；
  full deep-plan的收斂／prompt transport及大型真實code-review非收斂尚未獲得替代機制的完整證據。
  本輪依D-20260924-workflow-bounded-delivery不追查、不加規則、不重跑原packet；正確程式產物仍保留，無效獨立review不得當shipping證據。
  **觸發條件**：下一個真正需要full review的日常工作，或新的機制能提出包含正常完成與安全控制的固定驗收；保留exact scope／prompt／工具結果／終態後只修該root。
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
