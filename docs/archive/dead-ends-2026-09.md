# 死路歸檔 — 2026-09

## 事件記錄（event-time）

- **X-20260907-stale-core-scan-false-baseline · 2026-09-07 用舊 scanner 掃已換新內容的 worktree，被當成「這個問題本來就存在」的證據**:散佈新版 doc-governance core 時，`krepo` 與 `krepo-judicial` 出現 `governance surface bytes` 超標。為了判斷是既有問題還是本次造成，做法是 `git show origin/main:scripts/doc-governance.py > oldcore.py` 再 `python3 oldcore.py --root <worktree> audit`——**但那個 worktree 已經被複製上新 core 了**。舊 scanner 於是對「新內容」給出同樣的 finding，被讀成「用它們自己的舊 core 掃也是紅的 ⇒ 既有問題、與本次換版無關」。實際上 `origin/main` 兩者都在 budget 內（63732 與 63105，上限 65536），超標**完全**由 core 從 55462 增為 57915 bytes 造成;算式一減即現形:63732 − 55462 + 57915 = 66185，與觀察值逐位元相符。錯誤結論寫進了 `docs/backlog.md` 並隨 PR #170 進入 `main`，另外連帶推出第二個錯誤主張——「刻意不調高 budget，調門檻消音是本治理明文禁止的事」——而 `docs/document-governance.md`「Surface budget」其實明文允許 correctness fix 移到下一個 binary tier、且禁止只加剛好夠用的量，方向正好相反。
  - 日期來源:direct
  - 放棄:把「換掉工具、但沿用同一份已被汙染的受測內容」當成對照組;以「舊工具也報同一條」推論成因;在未實際取 `origin/main` 內容量測前就下「既有問題」的結論
  - 重議:出現需要判斷「這條 finding 是新引入還是既有」的同型情境時，先確認**受測內容**取自哪個 ref，而不是只確認工具版本
  - 關聯:B-20260823-fleet-rollout-remaining;M-20260907-doc-governance-silent-config-gaps;docs/document-governance.md

- **X-20260907-unreadable-tool-exclusion-argument · 2026-09-07 以「沒有人會讀這支腳本」主張把 vendored core 排除在 governance surface 之外，誤讀了它的定位**:`krepo`／`krepo-judicial` 因 core 增量撞線後，主張「core 57915 bytes 佔 budget 88%，而它是工具、不是要人讀的治理 prose ⇒ 不該計入 `governance_surface`」。`docs/document-governance.md`「Surface budget」的原文卻是 `a maintenance ceiling`——量的是整個治理機制的**維護面**，不是人類閱讀負擔;core 一改就要同步九個 repo，正是維護成本的證據。更關鍵的是這個提案的形狀:把已知成本移出量測以讓數字轉綠，與同一段明文警告的 `growing the Markdown denominator would otherwise loosen the gate without simplifying governance` 是同一種手法，只是改分子而非分母。另外「機制有問題」是由**單一次**撞線推出的，未達本 repo 自己要求的改規則證據門檻。獨立 reviewer（Codex）以上述三點駁回，並提出更好的替代:拆成 canonical core 與 repo-local 兩個指標分別設限，而非排除。**保留下來的有效觀察**是量測口徑而非成本歸屬:同一筆 +2453 bytes 在 9 個 repo 只擋下 2 個，且擋不擋得下取決於各 repo 自己的 config 大小（與 core 無關的變數），另外 4 個已 merge 的 repo 無聲吃下——「阻止 core 無聲成長」在 target repo 端只有 2/9 成立，檢查點該在 core 所在的 dotfiles。
  - 日期來源:direct
  - 放棄:以「沒有人會讀」作為排除計量的理由（維護面不等於閱讀面）;由單一次撞線推論機制錯誤;把「擴容到下一個 binary tier」描述成臨時消音（它是文件明列的預定流程）;把這次擴容稱作根因修復
  - 重議:能證明「core 與 repo-local 拆成兩個指標後，仍擋得住 core 無限制成長，且更能捕捉 repo-specific 複雜度」時，才值得走 `/project spec`
  - 關聯:B-20260823-fleet-rollout-remaining;X-20260907-stale-core-scan-false-baseline;docs/document-governance.md

- **X-20260914-project-s9-ambiguous-fixture-ownership · 2026-09-14 S9 fixture 未標示預置 diff 的 ownership，測到 kernel STOP 而非 light path**:首輪 Codex S9 沙盒只留下 README typo correction，卻沒有告知 fresh runtime 這是使用者交付的 current task。Agent 依 kernel 將未知來源 working-tree change 視為他人改動而停止；這是正確安全行為，不能拿來判定 Project 的 branch-first／push-authorization regression。fixture prompt 補上 ownership 後重跑，才得到建立 feature branch、default branch 與 origin 不變、未 push 的有效 S9 證據。
  - 日期來源:direct
  - 放棄:把第一輪 Codex STOP 當成 Project regression;放寬 unknown working-tree safety gate
  - 重議:fixture 再次需要測未知來源 working-tree change；屆時另建 scenario，不復用 S9
  - 關聯:B-20260820-debt-19;shared/skills/project/references/pressure-tests.md;claude/evals/setup-sandboxes.sh

- **X-20260917-contract-eval-cwd-leak · 2026-09-17 Claude contract fixture 未先切換 cwd，誤在真實 repo 產生兩顆無效 commit**:首批 Claude Code 直接呼叫只隔離 `HOME` 與 `CLAUDE_CONFIG_DIR`，wrapper 漏了 `cd "$fixture/work"`；兩個 process 繼承 dotfiles cwd，分別產生 `ff20eda` 與 `8edaf27`，修改的是真實 `README.md`。這兩輪不是 Claude root-contract 實驗、完全作廢；用戶授權後已建 `rescue/b05-claude-cwd-mistake-20260917` 保留證據，將 B05 branch 回復到 `cdd246d`，清除 README diff 且保留 STATUS Spec。後續 fresh fixtures 以 subshell 先切 exact absolute cwd，並另存 `cwd.txt`後才呼叫 runtime。
  - 日期來源:direct
  - 放棄:把誤寫真實 repo 的輸出算入 Claude 實驗；未留 rescue ref 就改寫 branch；因兩顆 README commit 內容看似合理就留在 B05 scope
  - 重議:再寫任何直接呼叫 agent CLI 的隔離 harness 時，先以可比對的 absolute cwd 證據與 parent HEAD 錨點分離 fixture 失敗與 host-repo mutation
  - 關聯:B-20260810-gap-05;rescue/b05-claude-cwd-mistake-20260917;ff20eda;8edaf27
