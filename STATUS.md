<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-13)

---

## 進行中

### PR #329 提交延遲改善（project-shipping-latency）

- **Context**：正式提交的延遲調查與跨 repo 對照已完成；以 `M-20261013-pr329-latency-root-cause`
  為基準。已確認短命令過早 yield 增加結果取回回合；本地收尾亦有多次操作間隔。
  global instructions 切換、長 context、模型／provider 耗時與摘要歧義的個別影響尚未分離。
- **Goal**：減少 Project 正式送出中可避免的結果等待與本地收尾往返，保持既有安全及驗證契約，
  並用真實交付記錄確認收益；不以 skill／文檔類 repo 的性質直接解釋延遲。
- **Acceptance Criteria**：
  1. 短命令等待：以已觀察的 2–5 秒命令重現原先 1 秒 yield 的額外取回回合；修後在工具正常等待
     範圍內完成者，同次 call 取得 exit／結果，額外 poll 回合為 0。超時仍正確接續等待，失敗 exit
     不被吞掉；suite／CI 等長任務保留進度回報能力。先重現，再驗修後行為。
  2. 本地收尾：列出 merge 結果確認後同步、核對、cleanup 的相依與停止條件；能在同一次執行中
     安全接續的本地步驟減少模型往返。以正常路徑及同步失敗、ref 不符、非預期工作樹變更驗證：
     成功才繼續，失敗不進入後續清理，也不誤報完成。保留每個 push 的獨立 outward call、canonical
     cwd、merge exact-head 與 mandatory non-watch recheck；實作不以呼叫合併繞過 gate。
  3. 行為驗證：若需修改 skill，依 repo authoring route 對實際失敗做 focused before／after eval，
     以工具軌跡與結果判定，不以新增文字或 static gate 通過代替。整批測試依 root 測試契約選擇，
     文件治理 audit 通過；不因本次優化增加每次送出的模型驗收或重複 suite。
  4. 真實收益：下一筆獲當批送出授權的真實工作，記錄 invocation → final、使用者等待、CI、
     本地 suite、三個既有分段、命令 exit → 結果取回間隔及模型／tool 回合數；程序區間取聯集，
     不重複加總重疊時間。附 runtime／reasoning、context 熱度、scope 與版本，對照 PR #329；
     條件不匹配時只報本筆觀察。沒有真實修後資料時標示「行為已驗、端到端收益未驗」，
     不將全部 395.144 秒當可回收時間，亦不據此關閉整條 backlog。
- **Constraints**：首批實作範圍為上述等待及本地收尾機制；
  CI 架構、測試選擇器、模型／reasoning 設定、指示重載與摘要授權契約的變更不在首批範圍。
  後者若仍有瓶頸，先補因果證據再修訂本契約。不重開已結案的 #285／#279，不改其他 repo，
  不為取得耗時製造人工 shipping fixture；新增 helper 或指引的成本也納入評估。
- **進度**：2026-10-13 首批本地實作已完成：Codex 短命令採預設等待，共享本地收尾改為明確成功鏈；
  14 個執行案例及 Codex／Claude 的正常與 pull 失敗 focused forward 通過。第一候選在 Claude 的
  條件式 shell 中未能停止，已先重現再修正。開發整批 29 模組 exit 0（133.598 秒）。本輪使用者
  明示 `$project --merge`，正式最終 commit set 的 29 模組亦 exit 0（128.043 秒）。PR #330 已開，
  HEAD `84368cc`；macOS required check 兩次因既有 review fixture 的 maintenance.lock 競態失敗，
  Ubuntu 通過，未 merge。使用者選擇 1，已明示把 fixture maintenance 修復納入同 PR；
  配置／背景 maintenance 的 RED 已重現，repo-local 隔離修復的 17 個案例 exit 0（25.646 秒）。
  修復尚待最終 commit set 與 hosted required checks 驗證。前段到 PR 仍花 7:01.0；
  真實修後完整交付及端到端收益未驗。
- **下一步**：接續 `docs/pr329-delivery-measurement`，先核對 PR #330 的 `84368cc` 與本地觀測紀錄。
  完成 `tests/review-primary-native-eval.py` 的 fixture 隔離修復驗證，再更新同 PR、重驗全部 required
  checks、rebase merge 與本地清理；不盲目重跑／bypass。此修復將是同批第 1 次 CI 修復提交，
  最多兩次；前兩次執行同 HEAD 的 job 不算修復提交。
  本輪授權只依 Project shipping table，不能由本契約延伸到下一批。不得以 focused fixture 耗時結案。
- **關聯**：B-20260924-workflow-verification-economy；M-20261013-pr329-latency-root-cause；
  M-20261013-pr329-delivery-measurement；M-20261013-cross-repo-delivery-measurement；
  M-20261012-project-process-reduction-complete；D-20261009-small-change-delivery-spec（歷史，
  已由 D-20261009-ci-system-redesign 取代其設計上限）；D-20261013-project-shipping-latency-local；
  M-20261013-project-shipping-latency-local；M-20261013-pr330-shipping-ci-blocked；PR #329；PR #330。

## 暫停中

- **#309 內容契約與移交給同事**：P1、P2、P2b、P3、P5 已完成（[計畫](docs/plans/2026-10-12-content-continuity-redesign.md)、D-20261012-steward-identity-removed），剩兩個 repo 待補 P1／P2b，見計畫「待補 repo」；**恢復條件**：使用者告知 krepo-mops-financial-statements 開發完成且工作樹淨空，或 kapi-nc-v2 通過驗證、取代現行 NC 成為生產 repo 並採用文件治理。
- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。

## 歷史入口

- 決策：`docs/archive/decisions-2026-10.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-10.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- 「3. Deep-review reviewer 分工投影修復（#274）」的結案契約入口：[M-20261007-deep-review-primary-contract](docs/archive/milestones-2026-10.md)；原 spec 保存在 implementation commit `d36d2b7ea5f22d4196d964423844d29074b1eb9e`。
- 「CI 最慢分片量測與保守縮時驗證（#279）」的結案契約與後續正式採用邊界：[M-20261008-ci-critical-path-measurement-complete](docs/archive/milestones-2026-10.md)。
- 「CI controller 靜態重分配本地採用（#279）」的歷史契約與驗收：[M-20261008-ci-controller-core-local](docs/archive/milestones-2026-10.md)；舊五分片已由 selector／平台矩陣取代，#279 已結案，同 source 多輪 hosted 對照未完成的邊界見 [結案說明](https://github.com/jjshen-eland/dotfiles/issues/279#issuecomment-6128293263)。
- 「brewup 自動更新 bun 全域套件」的本地結案契約與驗收：[M-20261008-brewup-bun-global-update-local](docs/archive/milestones-2026-10.md)；已完成本批本地來源，尚未取得 push／PR／merge／部署授權。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 「移除 turbo skill 與其他 skill 的耦合」的結案與散佈結果：[M-20261011-turbo-retired](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-11-turbo-retirement.md` 已凍結。
- 「/project 流程減量與驗證成本（#285）」的結案與量測：[M-20261012-project-process-reduction-complete](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-12-project-process-reduction.md` 已凍結。
- 「Codex 真實送出 PR #329 的流程／CI 成本」：[M-20261013-pr329-delivery-measurement](docs/archive/milestones-2026-10.md)；未取得端到端加速證據，後續追蹤見 `B-20260924-workflow-verification-economy`。
- 「kapi-infra／krepo-common 的真實提交對照」：[M-20261013-cross-repo-delivery-measurement](docs/archive/milestones-2026-10.md)；區分 runtime、暖 context、使用者等待與批量送出，不以 PR 牆鐘代替獨立交付。
- 「PR #329 非測試延遲根因」：[M-20261013-pr329-latency-root-cause](docs/archive/milestones-2026-10.md)；已定位短命令 yield／模型往返造成完成結果延遲取回，行為修復與修後收益尚未驗證。
- 「Setup 工具與 agent shell 環境對齊」的結案與 14 台驗收：[M-20261010-setup-fleet-complete](docs/archive/milestones-2026-10.md)；未做的 adopt／keep 整理見 D-20261012-setup-adopt-review-dropped。
- 「Runtime 目錄收斂與 legacy 遷移」的結案與 14 台驗收：[M-20261012-runtime-layout-complete](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-06-runtime-layout-convergence.md` 已凍結。
- 「`~/.agents` 狀態目錄治理與審查紀錄搬出 repo／`/tmp`」的結案與 14 台驗收：[M-20261012-agents-state-registry-complete](docs/archive/milestones-2026-10.md)；登記表在 `docs/repo-guide.md`。
- 「審查診斷的執行隔離（#315）」的結案契約與驗收：[M-20261013-review-execution-snapshot-local](docs/archive/milestones-2026-10.md)，合併與 14 台散佈驗收見 [M-20261013-review-execution-snapshot-fleet](docs/archive/milestones-2026-10.md)；決策 D-20261013-review-execution-snapshot，情境為 deep-review `evals.md` P24。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
