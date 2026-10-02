<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-02)

---

## 進行中

### #246 Project 載入成本與新版模型行為評估

- **Writer**：`codex:project-model-behavior`
- **Workspace**：`branch=refactor/project-model-behavior`
- **Write Scope**：`STATUS.md`, `docs/plans/2026-10-02-project-model-behavior.md`, `claude/skills/project/`, `codex/skills/project/`, `shared/skills/project/`, `tests/`, `docs/testing-contract.md`, `docs/archive/decisions-2026-10.md`, `docs/archive/dead-ends-2026-10.md`, `docs/archive/milestones-2026-10.md`
- **Dossier Steward**：`codex:project-model-behavior`
- **目標**：依 #246 量測 Project 必讀 reference 的真實載入成本；另依本次使用者要求，評估新版模型已自行遵循的贅述與會妨礙表現的指令。後者以完成品質與行為為目標，不以刪減 token 為目標。
- **成功條件**：固定模型／runtime／版本、prompt 與隔離 fixture，保存雙端首次及同 session 再叫用的原始 trace、reader calls、實際 tokens、載入與整體時間；區分模式／endpoint 的必要載入依賴。內容候選以保留／移除／改寫的獨立對照驗證，保留無 skill 或未注入該條指令的控制組，檢查正常完成、false STOP、scope、授權與失敗語意。只採用有行為收益且既有安全 oracle 不退步的最小修正；Scenario 31、相關 pressure/helper tests、雙端 fresh eval、validator、repo tests 與 doc audit 通過。證據不足時保留原文並記錄，不以文字縮短替代成功。
- **限制**：不重做 #240 provider E2E 或 #229 已結案／其他 backlog 範圍，不改 kernel safety floor、shipping／transfer authority 或 canonical topology，不調高 chunk 上限繞過截斷、不用摘要或 memory 替代必要內容，不設定未授權的 token／費用／總時間預算；shipping authorization 只由當次明確 invocation 判定，不由本狀態檔授予或跨 session 沿用。
- **進度**：已保存三模型固定入口 first/reuse、模式依賴及獨立候選對照。6.1 Sol／5.6 Sol 正常終態相同，Standard credit 等價合計 7.19165／17.81768；訂閱 quota 無可歸因證據，不聲稱配額優勢。模式拆分、8000-byte chunk 與反例表刪除不採用。只修雙入口 reader 呼叫及首段截斷提示；shared core／12000-byte chunk／四份 Log 必讀與 endpoint authority 原樣保留。最終兩端 normal Log、MCP footer-loss Spec 及 matched native Claude pressure 均完整讀到 EOF、mutations 只在必讀完成後，scope 與 HEAD 符合 oracle。最終完整 suite 1563 PASS／0 FAIL（exit 0），六項 offline regressions、ruff、雙入口 validator／metadata 檢查、doc audit 與 diff check 通過；評估 plan 已凍結。
- **下一步**：先提交實作與可查證的 assignment，再依 Project completion gate 移除本 active item 並記候選結案里程碑；送出仍須當次 endpoint 授權、doc audit 及 required checks 通過。GitHub #246 尚未關閉。
- **關聯**：Issue#246;D-20260822-portable-project-skill;M-20260822-portable-project-skill;D-20260825-portable-skill-authoring-default;D-20260925-instruction-quality-scope;D-20261002-project-model-bootstrap;X-20261002-project-loading-candidates;M-20261002-project-model-eval-local;shared/skills/project/references/pressure-tests.md;docs/plans/2026-10-02-project-model-behavior.md

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
- 里程碑：`docs/archive/milestones-2026-10.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
