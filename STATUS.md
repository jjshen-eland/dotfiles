<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-12)

---

## 進行中

目前無進行中項目。

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
- 「CI controller 靜態重分配本地採用（#279）」的結案契約與驗收：[M-20261008-ci-controller-core-local](docs/archive/milestones-2026-10.md)；hosted 效能仍待具名交付授權後驗證。
- 「brewup 自動更新 bun 全域套件」的本地結案契約與驗收：[M-20261008-brewup-bun-global-update-local](docs/archive/milestones-2026-10.md)；已完成本批本地來源，尚未取得 push／PR／merge／部署授權。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 「移除 turbo skill 與其他 skill 的耦合」的結案與散佈結果：[M-20261011-turbo-retired](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-11-turbo-retirement.md` 已凍結。
- 「/project 流程減量與驗證成本（#285）」的結案與量測：[M-20261012-project-process-reduction-complete](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-12-project-process-reduction.md` 已凍結。
- 「Setup 工具與 agent shell 環境對齊」的結案與 14 台驗收：[M-20261010-setup-fleet-complete](docs/archive/milestones-2026-10.md)；未做的 adopt／keep 整理見 D-20261012-setup-adopt-review-dropped。
- 「Runtime 目錄收斂與 legacy 遷移」的結案與 14 台驗收：[M-20261012-runtime-layout-complete](docs/archive/milestones-2026-10.md)；計畫 `docs/plans/2026-10-06-runtime-layout-convergence.md` 已凍結。
- 「`~/.agents` 狀態目錄治理與審查紀錄搬出 repo／`/tmp`」的結案與 14 台驗收：[M-20261012-agents-state-registry-complete](docs/archive/milestones-2026-10.md)；登記表在 `docs/repo-guide.md`。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
