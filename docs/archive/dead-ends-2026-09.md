# 死路歸檔 — 2026-09

## 事件記錄（event-time）

- **X-20260907-stale-core-scan-false-baseline · 2026-09-07 用舊 scanner 掃已換新內容的 worktree，被當成「這個問題本來就存在」的證據**:散佈新版 doc-governance core 時，`krepo` 與 `krepo-judicial` 出現 `governance surface bytes` 超標。為了判斷是既有問題還是本次造成，做法是 `git show origin/main:scripts/doc-governance.py > oldcore.py` 再 `python3 oldcore.py --root <worktree> audit`——**但那個 worktree 已經被複製上新 core 了**。舊 scanner 於是對「新內容」給出同樣的 finding，被讀成「用它們自己的舊 core 掃也是紅的 ⇒ 既有問題、與本次換版無關」。實際上 `origin/main` 兩者都在 budget 內（63732 與 63105，上限 65536），超標**完全**由 core 從 55462 增為 57915 bytes 造成;算式一減即現形:63732 − 55462 + 57915 = 66185，與觀察值逐位元相符。錯誤結論寫進了 `docs/backlog.md` 並隨 PR #170 進入 `main`，另外連帶推出第二個錯誤主張——「刻意不調高 budget，調門檻消音是本治理明文禁止的事」——而 `docs/document-governance.md`「Surface budget」其實明文允許 correctness fix 移到下一個 binary tier、且禁止只加剛好夠用的量，方向正好相反。
  - 日期來源:direct
  - 放棄:把「換掉工具、但沿用同一份已被汙染的受測內容」當成對照組;以「舊工具也報同一條」推論成因;在未實際取 `origin/main` 內容量測前就下「既有問題」的結論
  - 重議:出現需要判斷「這條 finding 是新引入還是既有」的同型情境時，先確認**受測內容**取自哪個 ref，而不是只確認工具版本
  - 關聯:B-20260823-fleet-rollout-remaining;M-20260907-doc-governance-silent-config-gaps;docs/document-governance.md
