<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-02)

---

## 進行中

### Git 身分與專案目錄分界的收斂（issue #161）

- **Writer**: `claude:git-identity-boundary`
- **Workspace**: `branch=feat/git-identity-boundary`
- **Write Scope**: `STATUS.md`, `CLAUDE.md`, `git/config`, `gh/config.yml`, `setup-mac-env.sh`, `setup-linux-env.sh`, `scripts/setup-git-identity.sh`, `scripts/migrate-github-remotes.sh`, `scripts/add-new-host.sh`, `docs/repo-guide.md`, `docs/plans/2026-09-02-git-identity-boundary.md`, `docs/backlog.md`, `docs/archive/decisions-2026-09.md`, `docs/archive/milestones-2026-09.md`, `tests/run.sh`
- **Dossier Steward**: `claude:git-identity-boundary`
- **Success Criteria**: 分界規則（`useConfigOnly` ＋ 三條 `includeIf`）進共用 `git/config` 且不含任何 email；`scripts/setup-git-identity.sh` 能生成／檢查機器層身分檔並清除 `~/.gitconfig` 的寫死身分；三個根各自解析到正確 email、根外得到 `Author identity unknown` 而非捏造身分；`proj` 與 `migrate-github-remotes.sh` 兩個根都涵蓋；`gh/config.yml` 的 `git_protocol` 與實際生效值一致並寫明 hosts.yml 優先；`docs/repo-guide.md` 同時涵蓋連線身分與 commit 身分；`./tests/run.sh` 以 exit code 判全綠。完整 spec 見 `docs/plans/2026-09-02-git-identity-boundary.md`。
- **進度**: 本機（家中 MacBook）已驗證 `--check` 回 `verdict: OK`；程式碼與文件變更完成。
- **下一步**: 進 `origin/main` 後，各機器 `brewup` 拉新 `git/config`，再逐台跑 `setup-git-identity.sh --apply`。macs 的 `~/SideProjects` 已建立、`isdotgd` 已搬入（2026-09-02）。逐機狀態見 `B-20260902-identity-fleet-rollout`。
- **關聯**: `B-20260902-identity-fleet-rollout`, `B-20260902-gh-account-autoswitch`

---

## 暫停中

（目前無暫停中項目。）

## 歷史入口

- 決策：`docs/archive/decisions-2026-09.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-08.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-09.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
