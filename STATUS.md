<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-03)

---

## 進行中

### review-repair-controller — 有界審查與修復復發控制

- **Writer**: codex:review-repair-controller
- **Workspace**: branch=feat/review-repair-controller
- **Write Scope**: shared/skills/deep-review, codex/skills/repo-review, claude/skills/deep-review, tests/review-repair-controller.py, tests/review-readonly.py, tests/review-skills-model-eval.py, tests/run.sh, tests/shard-manifest.tsv, docs/testing-contract.md, docs/deep-review-spec.md
- **Dossier Steward**: codex:review-repair-controller
- **Context**: 使用者要求檢視 deep-review／repo-review 的深井與 prose 審查、機械下沉、漸進／盲審分流及上限，並回報「修復引入下一次 finding」與「同根因漏修而再次被指出」兩種浪費。基線 `a94a8efa8ee64e1054831e55c6c5fb87627360ec` 的兩入口共用 portable core：ordinary 為一次獨立審查加作者驗證；full 修後預設再盲審，focused 分支尚未啟用；上限是預設 3、最多 5 次修復，不能誤稱審查輪數。現有 scope／drift checks 已機械化，同類掃描與修後驗證仍主要依流程文字。合成 helper probe 顯示可反覆 capture／autofix-check，且 terminal clear 僅 ancestry 不足以證明原範圍已審完；這是介面反例，尚非 native 模型失敗證據。
- **Goal**: 在共同核心落實 code-review 專用的有界派遣與修復驗證，減少可在下一次 reviewer 前攔下的復發；保留獨立發現真問題、跨庫完整性與唯讀安全，以實際行為決定模式和上限，不以零 finding、少字或更快結案當品質。
- **Acceptance Criteria**:
  1. **模式與流程狀態分離**：兩 runtime 共用語意。保留 ordinary 一次 reviewer 後作者驗證；full 的首次獨立審查建立有效盲審基線，修後可依實際變更與受影響契約選 focused，明示全審／第二意見則走盲審。Full 仍限已確認範圍，不擴成整庫掃描；Git 增量不是修復覆蓋證明。缺事實、結果不完整、需要決策與達上限均為控制狀態，不能藉換模式放行。
  2. **派遣與計數實際接線**：共享 controller 綁定 batch、scope bundle、版本及 reviewer assignment，派遣前原子保留並消耗一次性 ticket，完成時驗完整結果集與 fresh reviewer identities。分開記派遣組數、有效完成組數、reviewer 人數、修復嘗試及機械驗證；partial／invalid 結果不能當完成，也不得退票形成免費重試。重新叫用、換 runtime／session、重 capture、換模式或自行引入錯誤均不自動重置上限；單元 gate 必須驗實際 admission／finish 接線而非只有文句。
  3. **範圍與證據固定**：scope bundle 含全部已確認 repo、精確 endpoints／paths、dirty／untracked snapshot 與 guidance，合法修復以可查證的前後版本銜接；不沿用 stale baseline、不漏 repo 或縮小原 finding 的契約。Controller 狀態不得寫入唯讀 target（含 `.git`），不靠目標 repo 新增治理檔才可審查；保留可獨立完成的局部工作與未覆蓋部分的明確狀態。
  4. **修復前後可追溯**：保留 reviewer 原始 finding／severity 與主代理 disposition，將後續 finding 依修前修後證據連到未完整修復的原根因、修復引入或揭露、獨立新問題或尚待查證。不能以晚發現、文字相似或模型自述直接定因。同根因復發須先查修法、輸入不變量及相依覆蓋；區分設計問題與修復方法不完整，不因到頂就推論架構錯誤，也不改寫原始 finding 使它消失。
  5. **修後先驗證，再花 reviewer**：下一次派遣前，檢查原觸發條件、有限同類命中集合、開放輸入的 invariant／邊界及 semantic dependents；可由 test／lint／schema／資料比對判定者實際執行並綁修後 snapshot。已知相關檢查失敗、scope 漂移或證據不完整時維持修復／BLOCKED，不能派 reviewer 代做已知驗證。修復本身亦有上限，不把無限修補藏在機械 preflight；不為補表格擴成無關技術債或反覆重跑未受影響的全套檢查。
  6. **Reviewer 不接收收斂壓力**：由固定允許欄位產生 packet，focused 取得原 finding、實際修復差異、相依契約及證據；排除已審／剩餘次數、最後機會、預定 verdict 與作者辯護，名稱亦不透露輪次。保留 native 實際輸入輸出與原始 severity，不以事後正規化掩蓋失敗；另外記載 reviewer 主動讀取 workflow／目標文件的資訊暴露，不能把 payload 無 budget 宣稱為全域隔離。
  7. **終態與上限可信**：terminal clear 須綁完整有效 review receipt、原範圍與當前修後內容，不能只憑 ancestry 清除未覆蓋的阻擋；唯讀流程不得新增／清除 target signal。舊 signal 無充分證據時保留並說明。FAIL 與 BLOCKED 分開；到頂仍未通過時停止派遣，保留 finding／修復軌跡及下一步建議。使用者另行明示新批次後才可續審：有效基線與局部修正可建議 focused，範圍／核心契約改變或基線無效才建議盲審，不自動重開也不抹掉既有證據。
  8. **模式與上限分開比較**：現行 full「初審＋預設 3 次修復、最多 5 次」作基線；「首次盲審＋最多 2 次 focused＝最多 3 組審查、2 次審查間修復」只是待驗候選。明確定義第二意見、無效派遣及 repair preflight 的計費邊界，不能形成旁路。較早完成即停止；雙 runtime 在相同固定案例有可歸因品質收益且安全反例通過，才採用相關候選，否則保留預設或 opt-in，不把增加輪次本身當改善。
  9. **以有界行為驗收**：先固定 corpus／oracle 並取得 RED，再做最小修正。案例涵蓋修復引入退化、同根因多處漏修、不同寫法的語意相依、獨立新 finding 及本來正確的 negative controls；檢查首次修復產物與工具軌跡，不能只看最終 tree。機械反例包含重複／過期 ticket、partial set、超限零派遣、跨 session／runtime、scope drift 與錯範圍 terminal clear；兩端 native 驗正常與安全路徑，保留原始失敗。開跑前固定有限案例矩陣，只有具體新缺陷才重跑受影響案例；不另加使用者未要求的金額／token／工作時間上限，不展開 prose 自審。通過 relevant checks、`./tests/run.sh`、parallel shard manifest 一致性及 doc audit；語意根因／同類掃描的真實完整性仍以證據判斷，不新增自然語言評分器假裝機械保證。
- **Constraints**: 原 `$project spec` 僅建立文件；使用者隨後明示「開工」，授權本工作項實作及驗證，未授權 commit／push／PR／merge／部署，前一工作項的 merge 授權不沿用。Skill-authoring route 已完整讀取。只處理當前 portable review 流程，不重啟已無收益的 checklist ablation、不復活 legacy commit-count loop、不建通用 workflow framework／新 dossier store；不順便修改 deep-plan、project、root-cause-first 或全域規則。既有 B-20260924-workflow-review-residuals 不整筆宣稱結案。
- **進度**: 2026-10-03 controller／雙入口／terminal receipt 已接線；18 項行為測試與完整 suite 1566 PASS／0 FAIL。已核對 34 次 native parent captures，ordinary／blind／focused 修正後皆一次修復完成，cap 零新 reviewer、readonly 含 .git 不變。共同預設仍盲審／三次修復（最多五次），focused 明示 opt-in；實測不足以支持改預設。原始報告揭露 content-hash 誤報，已先 RED 後修正，完整 suite 再次 1566／0；雙端 affected focused 重跑均 2 reviewer／1 repair，actual hashes 與獨立 probe 通過。Codex encrypted task body、Sonnet packet 改寫與兩個 Claude 模型的 report 摘要仍為明示限制，不宣稱完整 isolation／receipt 品質通過。證據見 docs/plans/2026-10-03-review-repair-controller.md。
- **下一步**: 本機 controller 實作與有界驗證已交付；原始報告忠實保留／完整 isolation 未全通過，保留上述限制。等待使用者另行指定本批 Log／shipping endpoint；不自行 commit、送出或追加審查。
- **關聯**: D-20261003-review-repair-controller-adoption;D-20261003-review-repair-controller-direction;D-20261003-review-skills-retain-core;D-20261003-deep-plan-controller-adoption;D-20260924-review-repair-verification-choice;D-20260916-deep-review-self-report-accepted-limit;B-20260924-workflow-review-residuals;X-20261003-deep-plan-ci-shard-manifest

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
