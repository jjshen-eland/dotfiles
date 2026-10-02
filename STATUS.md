<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-03)

---

## 進行中

### review-skills-model-behavior — Deep-review／Repo-review 新版模型內容品質

- **目標**：以 gpt-6.1-sol／Opus 5.5 檢查現行指令是否有無效重述或妨礙表現；以行為品質決定保留／最小修正，不以 token 減量為目標。
- **驗收**：固定雙端 native baseline、單一變因對照、實態與工具 trace 核對；只採有可歸因收益且安全邊界成立的候選。必要 validator、相關測試及文檔 audit 通過。
- **進度**：28 次 fresh native invocations 與獨立實態 audit 已記錄於 plan；checklist／位置候選無可歸因品質收益，不採用。正式 entries／shared core／oracle 維持原文；ordinary、明確 permission full、ownership BLOCKED 有分項證據，未外推為完整 isolation／production 驗收。
- **下一步**：最終 full suite 1564／0、exit 0，doc audit／authority PASS；已收到本批 `$project --merge` 授權。先提交 audit 與 assignment，再結案並核對 candidate parent authority、required CI 與 merge endpoint。
- **Writer**：`codex:review-skills-model-behavior`
- **Workspace**：`branch=refactor/review-skills-model-behavior`
- **Write Scope**：`shared/skills/deep-review/**`、`claude/skills/deep-review/**`、`codex/skills/repo-review/**`、`tests/review-skills-model-eval.py`、`tests/shard-manifest.tsv`、`STATUS.md`、`docs/plans/2026-10-03-review-skills-model-behavior.md`、`docs/archive/{decisions,dead-ends,milestones}-2026-10.md`
- **Dossier Steward**：`codex:review-skills-model-behavior`

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
