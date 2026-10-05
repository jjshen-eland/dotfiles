<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-10-05)

---

## 進行中

### Project push 指令與 Codex outward gate 相容

- **Writer**: codex:project-canonical-push
- **Workspace**: branch=fix/project-canonical-push
- **Write Scope**: shared/skills/project/references, shared/skills/project/scripts/ship-state.sh, tests
- **Dossier Steward**: codex:project-canonical-push
- **Context**: `$project --merge` 的正常送出範例使用 `git -C <repo> push`，但既有 Codex hook 將此形式判為
  opaque 並拒絕；本輪本機對照證實它不匹配 push prefix rule，而直接 `git push` 匹配 `prompt`。
  force-with-lease 範例及 `ship-state.sh` 的 bootstrap-cmd 同樣產生帶 `-C` 的 push。
- **Goal**: Project 首次送出 push 即使用符合 gate 的 canonical command，消除指令形狀造成的
  blocked／重試，同時維持精確 repo 綁定與既有送出安全契約。
- **Acceptance Criteria**:
  1. 正常 PR／branch push、force-with-lease 及 bootstrap helper 輸出的送出指令，均由工具工作目錄
     綁定已查證的 canonical repo root，獨立執行直接 `git push`；保留 explicit remote／branch、upstream
     與已錨定的 expected SHA。不能把 `cd`、wrapper 或其他命令與 push 合併，也不能依賴未知 cwd。
  2. 先固定舊範例／helper 輸出遭 gate 拒絕的 RED；修後組合驗證證實首次 push 不再觸發 opaque deny，
     並匹配既有執行政策。opaque 指令仍受阻，canonical action 仍依政策進行 approval；pending approval
     不被當成失敗或觸發重試。dry-run 維持既有語意與保守 approval 邊界。
  3. Claude Code 與 Codex 對同一 fixture／oracle 都通過；正式 target 遵循 `claude/evals/README.md`
     「模型樓層政策」，保存原始 trace 與 alias／resolved model／effort／service tier／CLI。
     native trace 證明 repo 綁定、首次指令形狀及被推送的 branch 正確，不能僅以靜態文字判綠。
  4. 授權、default branch 保護、Ship 摘要、bootstrap 條件與 force-with-lease 的 expected SHA 不變；
     測試僅使用隔離 fixtures／本地 bare remotes，包含不同 repo／含空白路徑的綁定 control。
     受影響 regressions、雙入口 validator、doc audit 與 `./tests/run.sh` 均以 exit code 通過。
- **Constraints**: 修正限於 Project 的指令生成、共用 reference 與必要 eval／regression；不放寬
  `scripts/outward-action-gate.py`、Codex rules 或 runtime approval policy，不新增送出權限。
  修改 skill 前完成 repo 的 authoring preflight；先重現再做最小修正，不以補救重試冒充根因修復。
  使用者已明示 `$project --merge`；依 Project gates 完成本批 commit／feature push／PR／required CI／merge，
  不含部署或其他 repo。
- **進度**: 正常／lease／bootstrap 的 push 改為工具工作目錄綁定 repo 的 direct command；Log 上游
  三個漏修範例也已改為指向單一 command authority。原 focused 五案雙平台 10／10、上游 normal／lease
  四個有效 captures 通過；reader FAIL、capacity error 與無效 bootstrap 原 packet 如實保留。
  雙薄入口與 hook／rules 未改，5 個組合／oracle controls 通過；最後一次 full suite exit 0（1568／0），
  351 個 inputs 前後一致、243 秒，未 commit／push。
- **下一步**: 將 assignment 存入實作 commit 的 ancestry，再做
  結案 commit 與 candidate authority gate，送至已授權 PR／required CI／merge endpoint。
- **關聯**: D-20260912-cross-runtime-outward-gate; D-20260913-project-merge-authorization-ci;
  D-20261005-claude-target-model-roles; D-20261005-project-canonical-push;
  X-20261005-project-opaque-push; X-20261005-project-bootstrap-fixture;
  M-20261005-project-canonical-push-local; X-20261005-project-push-upstream-coverage

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
