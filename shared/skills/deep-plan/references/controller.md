# 審查控制器

本文件只供 orchestrator 使用。Reviewer 只取得控制器產生的 `prompt.txt` 內容。

## 開始與接續

以載入的 skill directory 解析 `scripts/review-state.py`。確認完整審查的 plan／所有 repo 後執行：

```sh
python3 <skill-dir>/scripts/review-state.py open --plan <absolute-plan> --repo <absolute-repo>
python3 <skill-dir>/scripts/review-state.py status --plan <absolute-plan>
```

多 repo 重複 `--repo`；使用者明示增加 reviewer 時，`open` 帶 `--count N`。控制器預設是現行兩輪盲審；
使用者選擇修後 focused 時加 `--policy focused`；只有明示選擇三輪才加 `--max-rounds 3`。
同一 plan 的 companion journal 位於 plan 旁 `.<plan-name>.review/control.json`，跨 session／runtime 沿用。
`open` 對既有 journal 不清零，也不更換 policy／limit／scope。這是本次 review 的 operational artifact，
不要提交其私人路徑／raw reviews，跨主機續作須依目標 repo 慣例攜帶審查證據。

狀態、輪次、上限、ticket、authorization evidence 都只交給 orchestrator。
NEVER include controller output, progress, remaining opportunities or a predicted verdict in reviewer input.
NEVER delete, rename or reinitialize a journal to obtain another review round.

## 準備一輪

由 plan 與 repo 證據判定再審原因；控制器不以關鍵字代替此語意判斷：

- 無有效首次基線：`--reason initial`，全面盲審。
- 原範圍內修正／處置：`--reason repair --repair <absolute-json>`。依本批 policy 做盲審或 focused。
- 明示另一份盲審意見，或首次無 findings：`--reason independent`；有 blocking finding 仍須提供處置 JSON。
- Goal／核心判準／架構或範圍已實質改變：先回到決策，`--reason scope-change` 不派遣。
- 缺不可省的事實：先取得事實，`--reason missing-facts` 不派遣。

```sh
python3 <skill-dir>/scripts/review-state.py prepare --plan <absolute-plan> --reason <reason>
```

判準類計畫另帶 `--criteria-impact-review`。只有 exit 0 且 `ok:true` 的 ticket 可交 runtime adapter。
`prepare` 先保留輪次，失敗／partial 也不能反覆派遣；mode 及 reviewer prompt 由 helper 產生。
每輪全部 reviewers 使用 `prompt` 指向的同一檔案全文；不得手工重寫。`ticket` 是控制資料，不給 reviewer。
在同一 policy 下，新 finding 不自動升為盲審，輪次也不決定 finding 的層別或嚴重度。

## 處置 JSON

先依 workflow 取得每條 blocking finding 的合法處置。`status` 提供原始 result IDs、findings 與
`plan_sha256`，JSON 只含以下欄位；不加入作者辯護、輪次、成本或「最後一次」訊息：

```json
{
  "baseline_sha256": "先前受審 plan 的 SHA256",
  "dispositions": [
    {"finding": "reviewer-id:0", "action": "fixed", "evidence": ["檔案:行號或實測證據入口"]}
  ],
  "contracts": ["受影響契約的證據入口"]
}
```

finding index 從 0 開始；action 是 `fixed`／`rejected`／`accepted`。重複命中仍保留每位 reviewer 的原始紀錄，
各自對應處置。Helper 檢查形狀、完整性及版本，產生實際 plan diff 並投影允許欄位；不能證明處置本身為真
或 accepted 已獲授權，這仍依 workflow 查證。Focused packet 不包含 reviewer IDs、controller state 或 verdict。
已知輪次／剩餘機會用語會被攔下；這不是任意自然語言的完美過濾器。

## 完成與停止

Runtime adapter 須讓一輪依序經過 `reserved → running → complete`，或保留失敗狀態。
Review期間 plan、repo 證據、prompt、brief 與 packet 的變動皆使結果無效。
`finish` 接受恰 N 份 `{ "id": "native-reviewer-id", "review": { ... } }` 的 JSON array；review 欄位
為 `findings`、`verified_claims`、`unverified_claims`、`recommendation`，分類依 reviewer brief。
若原始輸出缺欄位，回報失敗，不補造分類；原始 IDs／輸出保留供核對。有效 complete set 不等於 GO，
最終 finding／disposition gate 仍由 workflow 決定。

達上限只回報阻擋原因、待補事實／修正／決策與下批建議模式，不再 dispatch。Focused 第三輪能力只接受
原範圍內有實際 plan diff 的修正；不因仍有 findings 自動增加上限。正式 policy 尚未啟用此候選。
同目標且有有效基線的局部修正，建議下一批 focused；核心方案已改變或原基線不再涵蓋風險，先決策再建議
全面盲審。缺必要事實則先補事實，不能靠換模式代替。建議模式本身不授權開新批次。
新的使用者明示指示才可 `restart --authorization-evidence <file> --expected-state-sha <status-sha>`；
該 evidence 是原始指示的記錄，不是 helper 授權，restart 保留先前批次、policy 及 reviewer IDs。
新指示明確選擇 policy／limit 時才帶對應旗標。新批次仍可用上一批的有效基線做 repair；額度更新不抹除證據。
NEVER manufacture authorization evidence or silently change policy to bypass an exhausted batch.

若 reviewer 從目標文件／檢索讀到審查進度或作者預定 verdict，列明實際暴露及 review-validity 限制，
不得以「它說會忽略」冒充隔離成功；不要改寫 canonical plan 來隱藏這些來源。
