<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-18)

---

## 進行中

### B-20260807-gap-09 · Antigravity CLI macOS provisioning

- **Context**：`agy` 目前只手動安裝在部分 Mac；backlog 記錄的 Homebrew cask 為
  `antigravity-cli`，但 `setup-mac-env.sh` 尚未承接新機 provisioning，造成機器間漂移。
- **Goal**：重新驗證現行 cask／binary 與 macOS setup 契約，讓新機 setup 可安裝 Antigravity CLI。
- **Acceptance Criteria**：先以隔離 Homebrew fixture 取得「新機 setup 未要求安裝
  `--cask antigravity-cli`」的 RED；最小修正後 fixture 轉綠，且 Bash／zsh 呼叫路徑與完整 suite 通過；
  不改 `brewup` 對 `auto_updates` cask 的預設更新語意。
- **Constraints**：測試不得安裝真實 cask；首次執行仍需人在 Mac console 完成系統核可，不把該互動偽裝成
  setup 可自動完成；不沿用已排除的 Gatekeeper 預防方案，也不強制 `brewup --greedy`。
- **進度**：ROOT CAUSE CONFIRMED；Bash／zsh fixture 由 integration `1077/4` RED 轉為 `1081/0`，完整 suite
  `1485/0`，core `165/0`，ShellCheck、syntax 與 doc audit 通過；實作與 milestone 已完成，等待 shipping。
- **下一步**：由 Project Log 將 code、tests、README、backlog 結案與 milestone 組成受控 commit，送 PR 並以
  macOS＋Ubuntu required CI 驗證。
- **關聯**：B-20260807-gap-09;B-20260807-gap-04;M-20260918-antigravity-cli-provisioning
- **Writer**：codex:antigravity-cli-provisioning
- **Workspace**：branch=feat/antigravity-cli-provisioning
- **Write Scope**：`setup-mac-env.sh`, `tests/run.sh`, `tests/shard-manifest.tsv`, `README.md`,
  `STATUS.md`, `docs/backlog.md`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**：codex:antigravity-cli-provisioning

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
