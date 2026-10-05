<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-05)

---

## 進行中

### deep-plan-document-repair（#264）

- **Writer**：codex:deep-plan-document-repair
- **Workspace**：branch=fix/deep-plan-document-repair
- **Write Scope**：shared/skills/deep-plan, claude/skills/deep-plan, codex/skills/deep-plan, tests/deep-plan-routing.py, tests/deep-plan-repair-context.py
- **Dossier Steward**：codex:deep-plan-document-repair
- **Context**：[#264](https://github.com/jjshen-eland/dotfiles/issues/264) 的隔離診斷顯示，同範圍 findings
  要求同步修正 canonical plan、產品規格與 STATUS 時，已列入 repair packet `contracts` 的相依文件仍被
  `repo-baseline-drift` 拒絕。2026-10-05 補充證據另指出：明示 focused restart 成功後，stage／commit
  文件 checkpoint 仍會被擋下。已核對本 repo `29f76ed44fc1a689c803a3d38e113fc93684fa71`：snapshot
  在逐檔排除 plan 前納入完整 index，另比對 HEAD；新批 repair 仍沿用上一批有效 repo baseline。
  現有正向測試只涵蓋未 stage／commit 的 plan 修正，未涵蓋相依文件與文件 checkpoint。
- **Goal**：為原 scope 內、處置 findings 所需且明確宣告的文件修正建立受控續審路徑，涵蓋 working
  tree、index 與 HEAD；讓 reviewers 查證完整實際 delta，同時保留 repo drift、證據、票證與輪次防護。
- **Acceptance Criteria**：
  1. 同批在尚有額度時，canonical plan 與已宣告 SPEC／STATUS 的合法修正可直接進入下一輪；不強迫
     restart、不取得額外輪次。隔離 fixture 分別覆蓋 unstaged、staged、committed 文件狀態，且下一輪
     正常只消耗一次額度。預先已有 dirty 程式內容時，只有其內容、index 與 HEAD 投影皆未額外漂移才可續審。
  2. 已達上限後，只有使用者明示的新批次才可續作。合法文件 checkpoint 經實際差異核對後，focused
     repair 可接續上一批有效 plan baseline 與 findings；保留原始結果、處置、批次歷史、票證及各批計數，
     不要求再次 restart、改 blind 或重建 journal。
  3. Controller 與 workflow 使用同一文件宣告／允許契約，編輯前能判定修正邊界及不可接受情況。
     Reviewer 輸入可查證原始受審 baseline 到當前的全部文件 delta，涵蓋 plan、相依文件及合法
     index／HEAD checkpoint；不能只提供 contracts 路徑、作者摘要或宣稱。保持既有 policy 的盲審／focused
     分流，不把 controller 額度、進度或預定 verdict 傳給 reviewer。
  4. 未宣告文件、程式碼、其他 repo、非預期 HEAD／index 變動仍在 dispatch 前拒絕；宣告 Markdown、
     STATUS 或 contracts 名稱本身不能豁免漂移。路徑別名、symlink、越界路徑及重命名不能擴大允許集合；
     核對實際文件內容與 checkpoint 差異，不能只比較檔名或 dirty status。
  5. Admission 後至 reviewer 結果完成前，plan、相依文件、任一 repo 的 HEAD／index／內容、prompt、
     brief 或 packet 的任何變動仍使 ticket／結果失效；跨輪允許文件修正不等於放寬執行期間凍結。
  6. 真正 scope change、缺必要事實、無效／不完整 finding 處置、過期 baseline、失效／重用 ticket
     與已達上限仍拒絕；文件集合不能清零歷史、偷換 scope 或取得額外額度。
  7. 先以 isolated fixtures 固定 #264 正文及補充的允許／拒絕對照並取得 RED，再修復；透過 Codex／Claude
     兩入口驗證同一 shared controller 的 admission、完整 delta 與零派遣拒絕行為。既有 deep-plan
     routing／repair-context 回歸、文檔治理 audit 與 `./tests/run.sh` 皆以 exit code 通過；合成 fixture
     成功只證明機械行為，不宣稱真實 reviewer 品質提升。
- **Constraints**：不將所有 Markdown／STATUS 一概排除，不移除整體 repo drift guard；不改 reviewer
  數量、正式盲審／兩輪預設、嚴重度、GO 判準或外向授權。本項只處理 deep-plan 文件修正與 checkpoint
  續審，不擴展到 code-review controller。沿用原 canonical plan 與 journal，不修改已凍結 plan／history。
  修改 skill 前遵循本 repo skill authoring route；實作設計以復現與安全契約為依據，不為 prose 完整性加規則。
- **進度**：已實作宣告集合、三層文件 delta、逐 commit checkpoint 核對與舊 journal 精確基線接續。
  36 個 routing／2 個 repair-context 回歸、雙入口 validator、最後完整 suite exit 0（1568 PASS／0 FAIL）
  通過。雙端 native 正向／程式漂移拒絕 4／4，追加空基線欄位的 v1 接續修復後雙端補驗 2／2；
  target repo／Git metadata、原 results／計數均不變，未派 reviewer。證據與界線見
  M-20261005-deep-plan-document-repair-local。本機變更尚未 commit／push，保留 active assignment。
- **下一步**：待使用者明示 Project Log endpoint 後，先提交實作與 assignment，再依既有生命週期
  做結案與獲授權的送出；舊 dirty 文件基線若無法精確重建，維持 STOP，不猜測或清空 journal。
- **關聯**：#264（含 [2026-10-05 補充](https://github.com/jjshen-eland/dotfiles/issues/264#issuecomment-5988337613)）；
  #229；D-20261005-deep-plan-document-repair-baseline；M-20261005-deep-plan-document-repair-local；
  D-20261003-deep-plan-controller-adoption；D-20261003-deep-plan-state-routing-direction；
  M-20261003-deep-plan-routing-completion；shared/skills/deep-plan/references/controller.md；
  docs/plans/2026-10-03-deep-plan-state-routing.md（implemented，僅作歷史依據）。

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
