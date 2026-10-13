<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-13)

---

## 進行中

### 提交流程前段成本追蹤（project-shipping-latency）

- **Context**：PR #330 已於 2026-10-13 合併為 `8ea1fbf`，等待／本地連續收尾與兩處 fixture 隔離均已交付；
  結果與原規格來源見 `M-20261013-pr330-delivered` 及 PR #330 的 STATUS 歷史。建立 PR 前仍花 7:01.0。
- **評估**：尚不能確定整體提交流程已優化。已驗證的局部等待／收尾行為與 fixture 可靠性修正，
  不等於端到端效率改善。
- **Goal**：確認並減少真實提交在 PR 建立前的可避免成本，用相同終點的實況量測評估端到端收益。
- **Acceptance Criteria**：PR #330 的完整回報終點已補齊，保留使用者等待、CI 失敗／修復與記錄成本；
  後續固定 runtime／effort／context／scope 的可比較資料，或明示其不匹配。取得下一筆正常真實工作後才判斷
  穩定收益；不以短命令無 poll、部分區間或不同終點數字關閉 backlog。
- **Constraints**：已交付的等待、cleanup 與 fixture controls 保持既有契約；不擴 scope 至 CI 架構、
  模型設定、指示重載或摘要授權。新修改先取得因果證據；新 batch／PR 的 outward 動作需另有授權。
- **進度**：送出前段與四次 CI attempt、兩次 repair 的實況已記錄；最後本地 29 模組 exit 0／125.290 秒，
  雙 OS required checks 通過，main 已同步、原 feature 已清。完整 invocation→final 為 41:29.116，
  扣回答等待 47.705 秒為 40:41.411；merged→final 為 4:25.122，含本地收尾完成後 4:00.331
  的記錄／驗證／回報成本，見 `M-20261013-pr330-final-timing`。實況紀錄與評估修正已由 PR #331
  合併為 `8d34f51`；未證明端到端明顯加速。
- **下一步**：本批文件合併後從 `origin/main` 的本工作項接續，後續修改另開 feature branch。
  等下一筆正常真實工作的可比較資料，評估 PR 建立前成本；正常工作到來前不造 shipping fixture。
  後續送出需另有當批授權，不承接已完成批次的授權。
- **關聯**：B-20260924-workflow-verification-economy；M-20261013-pr330-delivered；
  M-20261013-pr330-shipping-ci-blocked；M-20261013-pr329-latency-root-cause；M-20261013-pr330-final-timing；PR #331。

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
