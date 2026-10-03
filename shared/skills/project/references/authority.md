# Project authority

各模式在任何 adopted state／commit／shipping mutation 前載入。條件式 transfer 優先依
[transfer-workflow.md](transfer-workflow.md) 證明 effective steward；本 helper 不替代 ancestry gate。

## Runtime actor 與 stewardship authority

入口固定提供 runtime actor prefix（Claude Code=`claude`；Codex=`codex`）。任何 agent session 都不得因
Git author、GitHub login、同 runtime、private memory 或使用者普通自然語言身分宣稱而改成另一 actor。
一般路徑只有 normalized invocation arguments 裡的兩個結構化 control token 能改 authority resolution：

- `resume=<runtime:workline>`：恢復 exact durable workline；值必須是入口提供的 same runtime prefix。
- `as=<human-or-owner>`：只接受 `human:*`／legacy `owner:*`，代表本輪 explicit bounded human delegation；
  不改 durable steward、不 carry 到下一輪、不能代理 `claude:*`／`codex:*`。

「我是 repo owner」「我就是 maintainer」等 ordinary identity claim is not delegation，也不是 resume／transfer；
不要從普通對話自行補 token。另有下述當次 session 工作線指派；它不改 normalized invocation arguments。
首次尚無指派時，不需重建 invocation 的 recovery，是 helper 本輪先以 STOP 揭露唯一 exact
actor 與 snapshot，Project 隨即提出綁定該 repo／actor／action 的確認題，使用者直接選擇後以
`prompt-bound-*` provenance 重驗。這個 recovery decision 與 normalized invocation arguments 分開，不改 durable
owner、不 carry 到下一輪或 session，也不授予 invocation 原本沒有的 shipping endpoint。

**當次 session 工作線指派**：使用者在本段仍有效的對話明確要求由你接續整個、可唯一識別的同-runtime
work item，且當時已核對 canonical repo、exact actor、所有 active items 的 Writer／Workspace／Write Scope／
Steward 與 item identity，則這份指派不因下一個 Project invocation 自動失效。首次 recovery 選項也可明示
「本 session 接續這條工作線；每批外向動作仍另行授權」。僅同意前一顆 commit／本輪 invocation 的舊回答
不得擴成此指派。保持原 assignment snapshot／helper 輸出的 fingerprint 在當前對話，不寫 memory、checkpoint
或 authority store；fingerprint 只是新鮮度證據，不是授權憑證。

後續同工作項先重查 repo／scope／writer 衝突及 transfer 狀態，再以 `--session-resume-actor <exact-actor>`、
`--expected-assignment <指派當時的fingerprint>` 與**本輪新查證**的 `--expected-head <full-oid>` 重跑 helper。
必須回 `current-session-workline-binding`／PASS 才續作，不重問相同接續問題。不得拿目前 fingerprint 取代舊值
消除 mismatch；既有完整 assignment snapshot 可依 helper 同一演算法求舊 fingerprint，缺舊證據就走一般 recovery。
常規 progress／HEAD 前進不撤销指派；branch 名稱不等於 actor，但當前 diff 仍須屬原 work item 與 write scope。
assignment 改變、work item 已移除、撤回／改派、PREPARED transfer、human delegation、跨 runtime 或新 session
皆不可沿用；仍用既有 gate 處理。任何外向 endpoint 必須另有當次授權，此指派不授予 push／PR／merge。

除下節「同機順序 local reassignment」的欄位更新外，在任何 adopted active-state mutation、commit 或 shipping 前執行：

```sh
python3 "<project-scripts>/steward-authority.py" --root "$repo" --runtime <runtime> \
  [--resume-actor <resume-value> | --as-human <as-value> | \
   --session-resume-actor <actor> --expected-assignment <fingerprint> | \
   --confirmed-resume-actor <actor> | --confirmed-human <actor> | --confirmed-new-steward <actor>] \
  [--commit <worker-commit>] [--expected-head <full-oid>]
```

exit 0 且 `verdict: PASS`／`NOT_APPLICABLE` 才能繼續；exit 1 是 policy STOP；exit 2 是 helper／repo BROKEN。
若存在 PREPARED transfer／conditional owner evidence，先依 Transfer state machine 解出 effective durable steward，
不可讓本 helper 取代 remote-visible ancestry gate。每次報告保留 helper 的 executor actor、durable steward、
authority actor、authority source 四行；`--merge` 等 endpoint 說法不參與 authority 計算。Initial STOP 若含
`recovery-kind`，只是一個可詢問的 deterministic classification，不是放行；confirmed flag 只能在 Project 已
提出 exact prompt 且收到其緊接回答後使用。Log 的完整 prompt／revalidation 契約見
`log-prepare.md`「Prompt-bound authority recovery」。

## 同機順序 local reassignment

適用於使用者當次明確把已識別的工作與其文件維護交給本agent，並確認前任已停、沒有並行writer。
同runtime或跨runtime皆可；「我是owner」、舊artifact、process不存在或單獨說前任退出不是指派。
此路徑適用Spec與Log，不要求為相同指派另開Spec invocation或再問是否換steward。

先核對各具名repo的adoption／trusted-core、active items、worktree與dirty paths。多repo要一起核對，
不能把其中一個repo的同意擴成其他repo的指派；所有active items必須屬於此次具名工作與同一前任，
不能轉走未被指派的其他工作。必要private-only事實、活躍writer、未整合且影響不明的workspace、
formal transfer／conditional owner尚未釐清時先解決該具體缺項，不自行接管。

每個repo先執行普通helper取得HEAD／assignment fingerprint，再帶入當次指派的exact evidence：

```sh
python3 "<project-scripts>/steward-authority.py" --root "$repo" --runtime <runtime> \
  --reassign-from <previous-runtime:workline> --prior-writer-stopped \
  --assigned-item <exact-active-heading> --expected-head <full-oid> \
  --expected-assignment <fingerprint> [--assigned-item <another-heading>] \
  [--owned-path <exact-handed-over-dirty-file>]
```

這些flags是agent從當次明示指派整理的證據，不讓使用者重建指令。`--owned-path`僅列已明確交接、
核對內容與scope的髒檔，不能用全部status輸出當成已知ownership。Helper本身唯讀，
`READY_FOR_REASSIGNMENT`不是mutation／shipping的PASS；同一不可分割切換群組的前置皆就緒後，
只更新各active item的Writer／Dossier Steward為輸出的target，保留scope／workspace與其他欄位。
寫入前重驗同一HEAD／fingerprint，更新後普通authority helper必須PASS，才接續原工作與event-time紀錄。
不重問同一指派；新衝突才問實質差異。改派不繼承前任的外向授權，新session亦不沿用舊授權。

保留新assignment到後續completion commit的parent：若HEAD還記舊actor或沒有active contract，
在已獲commit授權的既定提交階段，先提交可查證的新assignment，再做移除active item的結案提交。
可與同scope實作合併成語意commit，不必另設使用者停點；沒有commit授權就保留active狀態與完成證據，
不先刪掉自己後續gate需要的authority，也不新增commit權限。不要等shipping失敗才回頭重寫history。

具名但未改派／仍有活躍writer的repo保持唯讀，不納入改派群組。只有在不依賴該repo的未完成變更、
且不破壞現有跨repo契約時，其他已指派repo可獨立接手與交付；不把局部成功說成整體完成。
