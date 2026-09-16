<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-16)

---

## 進行中

### ci-test-sharding

- **Context**：PR #211 的 required checks 在相同測試集合下為 Ubuntu 1m14s、macOS 3m02s；既有 workflow
  已讓兩個 OS 並行、取消 merge 後重跑，`tests/run.sh` 內也已把 ShellCheck 與 doc-governance 放到背景，
  但 macOS 仍受串行 fixture-heavy 區段主導。
- **Goal**：把完整測試集合拆成彼此隔離、可在每個 OS job 內平行執行的 shards，聚合所有結果並縮短
  macOS required check 的 wall time。
- **Acceptance Criteria**：
  1. 先保存現行 serial baseline、各區段耗時與 assertion manifest；以 RED 證明現行 runner 沒有隔離 shard／
     fail-closed aggregation 能力，再實作。
  2. macOS 15 與 Ubuntu 24.04 都執行與 serial baseline 相同的完整 assertion 集合；不得以 path filter、平台
     分流或抽樣減少覆蓋，且每項 assertion 恰執行一次、無遺漏或重複。
  3. 每個 shard 使用獨立 temp/state/output；任一 shard 非零、未產出完整 manifest、被 signal 中止或 aggregation
     本身失敗，都使整個 OS job 非零。失敗輸出保留 shard 身分與原始診斷。
  4. 保留既有 required contexts `suite (macos-15)`、`suite (ubuntu-24.04)` 與本地 `./tests/run.sh` 完整驗證入口；
     不恢復 `push: main` 的重複完整 run。
  5. 在完整集合與 fail-closed gates 全綠後，以 macOS required job 實測 wall time 對照 PR #211 的 3m02s；只有
     實測縮短才宣稱效能改善，runner noise 無法判定時保留數據並重測，不以推估冒充結果。
- **Constraints**：只改執行拓撲與必要的 test harness；不放寬 assertion、不改 production 行為、不把 macOS
  降成 smoke test。先辨識跨 section 的共享狀態與順序依賴，只有證明隔離的群組才能平行。
- **進度**：baseline 為 PR #211 Ubuntu 1m14s／macOS 3m02s；section 9 `ship-state.sh` 是 macOS 最大單一
  耗時來源（前次實測約 99.7s，含 46 次 `git init`、約 80 個 fixture roots 與 122 次相關呼叫）。2026-09-16
  已取得兩層 RED：`DOTFILES_TEST_SHARD=ship_state ./tests/run.sh` 仍從 section 1 開始，證明現行 runner 無隔離
  邊界；新聚合器行為測試 6/6 因 implementation 尚不存在而失敗，固定非零 rc、signal-like rc、缺 completion
  artifact、缺／重複 summary、身分錯置及 assertion count 漂移都必須 fail closed。最小實作已把 runner 切成
  `core=164`、`ship_state=239`、`integration=1024`，三者各自 0 FAIL，聚合 manifest 為 1427；serial 同樣為
  1427/0。相同本機環境下 serial wall time 135s、parallel 60s（縮短 75s，約 56%），未以此冒充 GitHub
  macOS runner 的結果。
- **下一步**：檢查 final diff 與 governance audit；待明示 `$project --pr` 後送 PR，以 required macOS job
  實測對照 PR #211 的 3m02s，通過後才記錄 completion milestone 並移除 active item。
- **關聯**：D-20260913-project-merge-authorization-ci
- **Writer**：codex:ci-test-sharding
- **Workspace**：branch=perf/ci-test-sharding
- **Write Scope**：tests/, .github/workflows/test.yml, STATUS.md, docs/testing-contract.md,
  docs/archive/milestones-2026-09.md
- **Dossier Steward**：codex:ci-test-sharding

---

## 暫停中

- **B-20260902-gh-account-autoswitch**：pending；維持 backlog 既有觸發條件，在條件實際發生前不開發、
  不結案。**恢復條件**：跨帳號操作成為常態，或相同症狀再次被查錯方向。
- **deep-plan-timeout-cleanup-flake**：pending；PR #207 已加入可分辨 `rc`、manifest、`pid_count`、live
  descendants 與 process states 的 diagnostics。相同 launcher／fixture 本機序列重播 40 次、並行壓力重播
  100 次，以及 macOS required check 初跑與單獨重跑均通過，根因維持 `UNCONFIRMED`，不修改 production
  launcher。**恢復條件**：macOS required check 再次輸出 `timeout diagnostics:` RED；依第一個 divergent
  conjunct 重建 active contract，再做單一最小修正。
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
