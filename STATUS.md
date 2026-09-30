<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-30)

---

## 進行中

### #229 原驗收證據對照與新增 repo delta 驗證

- **Writer**：codex:issue-229-closure-evidence
- **Workspace**：branch=test/issue-229-closure-evidence
- **Write Scope**：STATUS.md, docs/plans/2026-09-30-issue-229-closure-evidence.md, docs/backlog.md, docs/archive/*-2026-09.md, shared/skills/project/references/{log-workflow,pressure-tests}.md
- **Dossier Steward**：codex:issue-229-closure-evidence
- **Context**：#229 的 Project 真實 GitHub endpoint 已由 PR #240 驗證；Scenario 36 新增 repo delta 缺有效雙 primary native packet，驗證與 review 成本殘留另在 backlog。
- **Goal**：用固定隔離案例補足可驗證缺口，逐條對照 #229 原驗收條件，再決定能否結案。
- **Acceptance Criteria**：Codex GPT-5.6 與 Claude Code Opus 5 的 normal／新增 repo delta 均有原生 trace 與獨立 Git oracle；新增 repo 未確認前零 mutation／outward，僅詢問差異；#229 每條驗收有已通過證據或具體未通過理由；文件與遠端 issue 不宣稱未驗證部分完成。
- **Constraints**：不操作 production 或真實專案 repo；fixtures 僅在隔離暫存目錄；先保存有效行為 RED 與明確 oracle 再修 Project，不擴大既有 #229 題目；repo push／PR／merge 須另有授權。
- **進度**：2026-09-30 雙 primary 的新增 repo 臂均取得有效修前 RED；Step 0 最小修正後，Codex／Claude 的 normal 與 delta 四個 fresh native arms 均依獨立 Git oracle 通過。Project validator、doc audit、diff check 與完整 suite 1536 PASS／0 FAIL、exit 0。PR #240 已證真實舊版 provider endpoint；#229 umbrella 其餘原驗收仍未完成，逐項對照見計畫。
- **下一步**：保存本輪 semantic commit，再以 parent 中的 active authority 結案本工作項並寫 milestone；#229 umbrella 與 backlog 殘留維持 open。
- **關聯**：Issue#229;PR#240;B-20260928-project-merge-continuation;B-20260924-workflow-verification-economy;B-20260924-workflow-review-residuals

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

- 決策：`docs/archive/decisions-2026-09.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-09.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-09.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
