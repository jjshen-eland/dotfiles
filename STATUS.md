<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-05)

---

## 進行中

### Root-cause-first 雙 runtime 行為評估

- **Writer**：`codex:root-cause-first-model-behavior`
- **Workspace**：`branch=test/root-cause-first-model-behavior`
- **Write Scope**：`shared/skills/root-cause-first/`、`claude/evals/README.md`、`claude/evals/contract-evals.md`、`docs/skill-portability.md`、`tests/root-cause-first-model-eval.py`；本項 STATUS／plan、`B-20261005-root-cause-first-sonnet-evidence` 與 event-time history。
- **Dossier Steward**：`codex:root-cause-first-model-behavior`
- **Context**：Opus target 與 Codex 的 frozen v2 行為驗收已完成；本地 candidate `942034f` 的 active assignment 未保存於 commit ancestry，Project authority 因此 STOP。使用者已選擇 guided recovery，建立 contract 並受控重建尚未 push、無 PR 的同批 candidate。
- **Goal**：保留已驗證的 evidence／terminal-state 兩處修正、native eval runner 與模型角色決策，完成可查證的雙平台工作線結案及原授權 PR／merge。
- **Acceptance Criteria**：重建內容與原 candidate 相符；assignment 在 completion parent 可查證；completion authority PASS；保留 Opus／Codex 行為證據與 Sonnet RED backlog；full suite 與受影響文件檢查通過；同 PR 的 required checks 通過後才 merge。
- **Constraints**：不改既有 oracle、shared topology 或 skill 行為；只重建本地未送出的 `942034f`，不 force-push、不繞過保護或 CI；歷史記錄與 implemented plan 保留。
- **進度**：fresh full suite exit 0，1567 PASS／0 FAIL，349 個受測 inputs 前後快照一致；文件 ship audit 通過。正在為 recovery 保存 durable assignment。
- **下一步**：先提交本 contract，再由同 steward 重建 implementation／completion commit；重驗 authority、文件與 required CI 後依原 `$project --merge` 授權完成。
- **計畫**：`docs/plans/2026-10-05-root-cause-first-model-behavior.md`
- **關聯**：D-20261005-claude-target-model-roles；M-20261005-root-cause-first-opus-v2-adopted；X-20260930-mobile-questions-steward-candidate；B-20261005-root-cause-first-sonnet-evidence。

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
