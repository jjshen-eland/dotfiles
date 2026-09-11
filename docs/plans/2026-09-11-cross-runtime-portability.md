# 跨平台與跨 runtime 收斂

- 日期：2026-09-11
- 狀態：implemented
- 工作項：cross-runtime-portability
- 種類：implementation
- 需求來源：使用者要求檢查 macOS／Ubuntu、Claude Code／Codex 設計並實作優化

## Goal

1. PR 持續在 macOS 與 Ubuntu 24.04 驗證，不再只靠單一實機。
2. 維持 Claude Auto 與 Codex 高自主設定，但 push／merge 必須走互動核准。
3. Codex config 在 setup、brewup、dotsync 後可重現合併 repo defaults、本機 state 與 local override，且不覆蓋 runtime state。
4. dotsync 對任一 requested target 的 pull、連線或 helper 失敗回非零，仍完成其餘目標並彙總。
5. portable skill 的 shared behavior/resources 移到 `shared/skills/`；兩端只留薄 adapter 與 runtime-only assets。
6. Codex 個人 skills 改由官方 `$HOME/.agents/skills` 發現，移除本 repo 管理的 legacy links 而不碰第三方內容。

## Selected design

- 四個可分離語意 commit：platform CI、push/merge gates、config/sync、neutral skill core。
- Linux 正式支援 Ubuntu 24.04+；其他 distribution 在任何套件 mutation 前 exit 2。
- Claude PreToolUse 直接回 `ask`；Codex canonical commands 由 rules prompt，隱藏在不透明 wrapper 的 guarded action 由 hook block 並要求改成 canonical command。
- Codex config 合併順序為 repo base → generated machine state → user `config.local.toml`，後者優先。
- Shared tree 不含 `SKILL.md`。`deep-review` 的 Claude entry、Codex `repo-review` entry 共用 `shared/skills/deep-review`。

## Acceptance

- `./tests/run.sh` 在 `macos-15` 與 `ubuntu-24.04` exit 0。
- `git status`、`gh pr view` 不觸發 outward gate；push、send-pack、PR merge 與已知 wrapper 變體不能無核准執行。
- 壞 TOML、concurrent config write 或缺少 merge dependency 時保留既有有效 config 並回非零。
- dotsync local/remote failure fixtures 都回非零且輸出逐機與總計；全綠才回零。
- 所有 portable adapter 的 shared links resolve 到本 worktree 的同一 neutral inode；沒有 duplicate eval oracle 或 whole-skill symlink。
- Claude/Codex skill validators、既有 behavior evals、doc audit 與完整 repo suite 全綠。

## Rollout boundary

本計畫只授權本地實作與 commit。每個遠端 push、PR、merge 與 dotsync fleet rollout 必須另外取得當前授權；只有進入 `origin/main` 的 revision 才能散佈。
