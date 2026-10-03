<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-03)

---

## 進行中

### deep-plan-state-routing — 依審查狀態選模式與有界修後驗證

- **Writer**：`codex:deep-plan-state-routing`
- **Workspace**：`branch=feat/deep-plan-state-routing`
- **Write Scope**：shared/skills/deep-plan, codex/skills/deep-plan, claude/skills/deep-plan, tests/deep-plan-routing.py, tests/deep-plan-repair-context.py, tests/deep-plan-model-eval.py, tests/run.sh, docs/testing-contract.md
- **Dossier Steward**：`codex:deep-plan-state-routing`
- **Context**：兩端現行皆先做風險分流；完整路徑每輪 N=2、最多兩輪，第二輪盲審，focused transport
  尚未啟用。本次使用者要求把首次／再審原因／輪次納入模式選擇，並明示避免深井及 prose 審查、可機械化的
  控制必須實際下沉；另提出兩輪只有一次審查間修正機會的取捨。既有評估未比較 focused／blind，不能直接背書改預設。
- **Goal**：以同一 shared 規則支援全面盲審與 focused 修後驗證；根據有效審查基線、再審原因、實際變更及
  本批輪次選擇或建議下一步，兩 runtime 具有相同產品語意。可確定的狀態／計數／完整性控制由可測 helper
  承擔，agent 負責有證據的語意判斷；以完成品質決定 focused 及其輪次候選是否啟用。
- **Acceptance Criteria**：
  1. 保留 ordinary 的 READY-FOR-INCREMENT／NEEDS-DECISION 分流。需要獨立審查且沒有有效首次基線時
     採全面盲審；有有效基線及可追溯的修正／處置時採 focused，覆蓋原 finding、實際修改、同類問題與語意相依。
     新 finding 本身不觸發全審；Goal／核心判準／架構或範圍實質變更使基線失效時，先回決策再全面盲審。
     明示再次盲審仍被尊重；首次無 finding／無修正不得偽造 repair packet，也不藉此默改既有輪數政策。
  2. 分開記錄 reviewer 數 N、已開始輪次、有效完成輪次與修後驗證次數。N=2 不變；現行兩輪為基線，
     候選是首次盲審加最多兩次 focused（總計最多三輪、兩次審查間修正），不是每案強制跑滿三輪。
     第三輪須有實際修正可驗且仍屬原範圍；已通過即結束，缺事實先補事實，重訂方案先回決策。
     上限仍 NO-GO 時不得再 dispatch，只輸出阻擋原因、所需修正／決策及下批建議模式；換模式、session、
     runtime 或重呼叫不得清零。失敗／partial 不當有效審查，也不能藉重試無限增加派遣；重開批次需新的明示指示。
  3. 實作共享機械判定入口，檢查 typed state、plan／repo scope 身分、基線及 packet 完整性、輪次與合法轉移，
     輸出 dispatch 許可、模式、reason code、剩餘輪次或停止／補證據的結果。兩個 adapter 在 dispatch 前確實
     呼叫並使用結果；用假的 dispatch 邊界驗證 STOP 時零派遣，不能只新增 helper 或 SKILL.md 文字而不接線。
     控制器狀態與 reviewer 輸入分離，以固定允許欄位產生 prompt／repair packet；輪次、上限、剩餘機會、
     「最後一次／沒機會再修」及預定 verdict 不進受控 reviewer 輸入，也不編入自動產生的路徑名稱。
  4. Goal／架構是否改變及語意相依仍須 agent 以 repo／plan diff 證據判讀；helper 不靠關鍵字猜測、不將
     hash 一致當成審查內容正確，也不自行推定使用者授權。缺少、陳舊或矛盾證據不得靜默進 focused／放行。
     狀態沿用可攜的既有 review 產物並只補必要欄位，不另建 dossier／中央服務，也不依賴私人 session 記憶。
     Reviewer 獨立分類，orchestrator 不因輪次或交付壓力降級。使用者回報 Claude reviewer 得知剩餘修正機會
     時有降級傾向，列為隔離契約來源，不當本次重現證據；若目標文件／檢索結果自帶審查進度，記錄實際暴露與
     review-validity 限制，不冒稱已隔離，也不為隱藏進度改寫 canonical plan 或只追加「不要受影響」提醒。
  5. 先固定行為 oracle 與可重現反例，再改 source。機械案例至少涵蓋首次、有效修後、基線失效、明示盲審、
     上限後停止、切換 runtime／重呼叫不清零、錯配／過期 packet 與無效輪次；測可觀察結果，不用字串存在代表行為。
     用不同輪次／剩餘機會但相同審查資料的 controller inputs，驗證輸出的 reviewer payload 相同，並以夾帶
     輪次／最後機會訊息的 packet 反例驗證攔截；native trace 核對實際傳遞，不能只驗 template 或自述隔離。
     Native 案例核對真問題漏報、誤阻擋、修正引入問題、未列同類／跨檔相依與範圍擴張；repair packet 不是可信結論。
  6. 分離模式與輪次兩個變因：先在相同有效首次基線／修訂／N／模型設定下比較第二輪 blind 與 focused；
     再只以確有第二次修正需求的案例核對 focused 兩輪停止與條件式第三輪，不把放寬上限的效果歸因於模式。
     開跑前固定有限案例與預期行為，雙端實際 trace／artifact 為證；不重跑已綠案例、不追加輪次追求零 finding，
     失敗保留根因與限制。不得以字數、finding 數、CLI exit 或 agent 自述判品質，也不自行設定美元／token／總時限。
  7. 兩端通過相同正常／安全 oracle 才啟用共同預設；若只有局部成功，保留正式預設並列出差異，
     不冒稱全體完成。Validator、相關機械測試、完整 ./tests/run.sh 及文檔 audit 通過；沒有可歸因收益就不啟用候選。
- **Constraints**：使用者於 Spec 完成後明示「開工」，授權本項實作與隔離驗證；未授權 push／PR／merge／部署。
  後續動 skill 前完整讀 system skill-creator、Codex authoring guide 與 portability contract。保留 fresh reviewers、
  findings 原分類／證據、disposition、唯讀與授權契約；不改 reviewer 模型／N，不重做 portable migration，
  不擴成其他 review／shipping skill 改版。禁止用 deep-plan 自審本項目或全文 prose review 追求收斂；
  規則新增須有 observed failure 或本項明確安全契約，驗收通過即停止，不因「可能更完整」擴張。
- **進度**：2026-10-03 本機實作與固定驗收完成：共享 controller／雙 adapter 接線，20 個 routing tests、
  2 個 repair-context tests、雙 validators、完整 suite exit 0（1565/0）。14 個 native 原 arm 與 2 個只修
  transport 缺陷的補驗已核對；採機械控制及 opt-in focused，跨 runtime 預設均維持盲審／兩輪。Codex
  workflow 暴露與 Claude 原始分類／查證限制列於 implemented plan，不聲稱完整隔離或模式品質全綠。
- **下一步**：無進一步實作／評測；保留本機變更及 assignment，待使用者另行指定 lifecycle endpoint。
  本次未 commit／push／merge／部署，後續封存须先將 assignment 保留在 completion parent。
- **關聯**：D-20261003-deep-plan-state-routing-direction；D-20261003-deep-plan-retain-core；
  D-20260924-review-repair-verification-choice；M-20260915-b06-deep-plan-reviewer-count-reassessed；
  M-20260915-b07-deep-plan-eval-review-reassessed；B-20260924-workflow-review-residuals。

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。
- **B-20260824-remote-human-contributor-path**：pending；現行 feature branch／PR 可作為 Git 傳遞媒介，
  Project authority gate 也能在 steward 評估 candidate commit 時列出 shared-surface 越界；但既有 worker
  契約仍不允許自行 push，PR CI 亦不依 contributor 身分判斷 stewardship。可取得的 dotfiles 與三個已 rollout
  repo 的 PR／commit 紀錄沒有 remote-human contributor 實例，未觀察到傳遞阻塞或 authority drift，故不新增
  程序、eval 或 provider gate。**恢復條件**：第一位具名、跨主機真人 contributor 需要交付 commit，或首次出現
  非 steward PR；保留其 exact SHA、declared scope 與 Dossier delta，實測 steward fetch／shared-surface 檢查／
  cherry-pick。任一步受阻，或越權 shared dossier mutation 未被攔下，才以該事件取得 RED 並做最小修正。

## 歷史入口

- 決策：`docs/archive/decisions-2026-10.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-10.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
