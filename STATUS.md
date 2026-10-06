<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-06)

---

## 進行中

### turbo-skill

- **Writer**：`codex:turbo-skill-plan`
- **Workspace**：`branch=docs/turbo-skill-plan`
- **Write Scope**：`shared/skills/{turbo,deep-plan,deep-review,project}/`、雙端對應 skill entries／links、`codex/config.toml`、`claude/settings.json`、必要 lifecycle／ensure／timestamp 接點、`tests/` 的相關 oracle／runner、使用說明與本工作項的 adopted dossier／history；不包含其他工作項、全域 permission 開關或部署。
- **Dossier Steward**：`codex:turbo-skill-plan`
- **Goal**：依 [turbo 計畫](docs/plans/2026-10-05-turbo-skill.md)，建立 portable session mode，從 plan review 持續到實作、code review 與已授權交付；遇到 cap 自主修正及選模式續批，無法達標或無進展時停止並說明。
- **Acceptance Criteria**：雙端 on／off／status 與 session 隔離；既有 review controllers 的 delegated-reentry 保留歷史、原批上限及有效結果／receipt；同目標的自主選擇與一次具名交付授權；native 續跑、取消及 permission／outward gate 組合證據；turbo off 回歸、behavior evals、validators、repo suite 與 documentation audit 全綠。補強雙端 help／--help 與啟用提示：能發現命令、goal 路徑、四種 allow 值與範例；help 不啟用或擴權，bare 維持 status。未驗 native surface 不宣稱支援。
- **Constraints**：沿用 kernel 與唯一 review／shipping authority；來源／scope／ownership／host permission 不由 artifact 自授；本批使用者明示 `$project --merge`，交付依原 scope／同 PR 與 required gates；不含 dotsync／全域 permission 修改。原 deep-plan journal 保留，未把本次開工指示冒充新 review-batch 指示。
- **Progress**：原核心本地驗收完成，G suite exit 0／1570 PASS，詳見 M-20261006-turbo-skill-local。新增唯讀 help、啟用提示與 README 參數表：雙端 help v2 的範例經实际 parser 通過，idle-on v3 證明 on／idle／無 goal／allow 空集合及 help hint，未知權限未再推定 launch profile。首輪原文與反例保留；雙入口 validator、doc／xref 及 diff checks 通過，詳見 M-20261006-turbo-public-help。
- **Next**：依本批 `$project --merge` 先保存 assignment 與成果，再建立可驗證的結案 candidate、補齊測試快照並開 PR；required checks 通過後以 rebase merge 完成。原 implemented plan 凍結，介面 delta 記於既有 state／history。原 review journal 私人產物保持原位、不提交；新 entries 未安裝，不包含部署。

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
