<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-01)

---

## 進行中

### #250 wait4me Codex Stop 通知未送達

- **Writer**：`codex:main`
- **Workspace**：`branch=fix/wait4me-codex-hook-network`
- **Write Scope**：`STATUS.md`, `shared/skills/wait4me/scripts/wait4me-hook.sh`, `shared/skills/wait4me/scripts/wait4me-send.py`, `shared/skills/wait4me/references/workflow.md`, `shared/skills/wait4me/evals.md`, `codex/config.toml`, `claude/settings.json`, `tests/run.sh`, `tests/shard-manifest.tsv`, `docs/archive/milestones-2026-10.md`
- **Dossier Steward**：`codex:main`
- **成功條件**：真實 Codex Stop 的去敏階段、exit 與錯誤類別可查；`on` 與已啟用的 `status` 各發一則測試通知，明確分開開關與 Gateway 回覆；以正常終端與 hook 同時段對照定位私網首次差異後才修其因果來源；假 Gateway 驗證僅需回覆時送一次、普通完成不送、失敗不誤報送達；真實環境完成一次使用者收件驗收。
- **狀態**：本地修正候選與自我測試已完成；隔離 Codex Stop 可送 fake capture、連線拒絕會留 `send-failed`，同步 Stop 排除 ephemeral session 取消背景 hook 的實測失效。2026-10-01 實際 NC 測試已載入設定，但 sender 回 `network-unreachable`（exit 75），未取得 Gateway 確認；同一執行環境可連公開 TLS，卻對兩個本機網段的多個目標皆回 `OSError:65`，私網 NC 目標的 ARP 未解析。工具命令在較少限制模式重試仍同樣失敗；這只定位到目前執行環境的私網路徑，不代表使用者網路離線，也尚不能判定是 Codex 網路代理、macOS 權限或目的端網路所致。下一步須以本機一般 Terminal 同時段對照同一 sender，再依第一個不同邊界修正；真實收件仍待驗證，#250 維持 open。

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
