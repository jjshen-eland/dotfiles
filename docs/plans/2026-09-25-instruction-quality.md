# 規則與 skill 撰寫品質優化計劃

- 工作項：instruction-quality
- 日期：2026-09-25
- 狀態：draft
- 種類：implementation
- 需求來源：使用者要求在規格、功能及效果不變下改善效率、一致性與品質，先核對 [#229](https://github.com/jjshen-eland/dotfiles/issues/229) 再提出計劃。
- 本輪授權：查證與撰寫計劃；不含下列候選實作、模型 eval、commit、push 或部署。
- 查證基線：`b7e32ffde5dec543fb208a6f0a140e032f851747`；起始 working tree clean；#229 於 2026-09-25 查詢仍 OPEN、無 comments。
- Writer／Dossier Steward：`codex:instruction-quality`；Workspace：`branch=docs/instruction-quality-plan`。

## 目標與完成條件

改善 agent 理解與執行現有規格的可靠性，減少調和矛盾、追查例外、重複確認與重複讀取的成本。
文字長度、token、工具次數只是觀測值；不是刪減目標，也不能以變短抵銷完成品質或安全退步。

本計劃交付的完成條件：逐項提供原規格依據、與 #229 的相容性、候選 write scope、正常／安全驗證和停止條件。
後續實作的完成條件：保留所有適用的授權、觸發、scope、gate、結果與失敗語意；可觀察的執行或維護品質改善有證據，
受影響 production runtimes 無既定安全／完成契約退步，必要檢查通過。沒有改善證據的風格偏好不進最終 diff。

非目標：重做 #229、改 review 策略或風險門檻、增加 approval/helper/store、重定義 handoff 授權、改模型、
改 scripts 的產品行為、修無關 debt、追求零 findings、替所有 skill 套同一文體，或宣稱 #229 已完成。

## #229 相容性與已採用基線

Issue 原文允許替換治理機制；本次使用者要求更窄，只授權規格不變的品質規劃。
Issue 的初始數值預算要求也不能蓋過後續已記錄的使用者決策。核對來源如下：

| 來源 | 必須保留的結果及對本計劃的約束 |
| --- | --- |
| #229 Target operating principles／Necessary-interruption contract | 正常授權工作持續；必要問題具體、可單答續作；新 debt 不進 scope；驗證足夠就停止。不得把品質整理變成新治理門檻。 |
| `D-20260922-handoff-task-reference-authorization`；[handoff 已凍結計劃](2026-09-22-workflow-audit.md) | 當次明確續作意圖可引用經查證任務授權 local edit/test；不要求逐字 paths 或第二次同意；artifact 不帶舊 outward authority。H17 舊 ordering FAIL 與 H18 ignored-cache FAIL 不追溯改判，也不升格為新安全禁令。 |
| `D-20260924-single-review-delivery`／`D-20260924-single-pass-partial-delivery`；[現行 review oracle](../../shared/skills/deep-review/evals.md) | 一般工作一位 fresh reviewer 覆蓋完整具名 scope，修後作者驗證；不自動第二輪。具體高風險或明示 full 保留完整路徑。不得為本次文字建議重開已驗證整批。 |
| `D-20260924-remove-unrequested-eval-budget` | 不設定使用者未指定的 token／美元／整體 wall-time 上限；CLI cost 只作 telemetry。人工截斷不是工作流失敗；不可重跑相同材料洗綠。 |
| `D-20260925-task-continuity-and-steward-scope`；[已凍結交付計劃](2026-09-24-production-batch-boundary.md) | 保留明示順序接手、steward 同工作必要文件權責、assignment 先於 completion、同 session/context 完整且 SHA 相同的 reference 沿用，以及插問後接續。明示排除與真實活躍 writer 仍受保護。 |
| `D-20260925-project-numbered-text-options` | 已需要提問時保留完整動作／後果的 2–3 個編號選項；不退回「確認／停止」，也不新增預檢或詢問點。 |
| [既有 backlog](../backlog.md) 的 `B-20260924-workflow-review-residuals`／`B-20260924-workflow-verification-economy` | 高風險 review、generic 收尾、shipping 協定及接續仍有已知限制。此次不接管、結案或用文案修改宣稱解決。 |

上列 D-* 皆位於 [2026-09 決策記錄](../archive/decisions-2026-09.md)。歷史證據與 implemented plans 唯讀。

## 原評估建議的處置與候選 write scope

本表的「納入」只表示列入候選，不是已驗證缺陷或實作授權。每批只處理一個問題來源；
跨檔同一規則可同批對齊，不把獨立問題合成一次 before/after。

| ID／處置 | 原規格、問題與最小候選 | 候選 write scope | #229 相容性與驗證 |
| --- | --- | --- | --- |
| Q1 納入：shipping 詢問範圍 | 「零提問」應限定為不重問已決 endpoint；既有 authority、scope、受阻方法仍按原 gate 處理。先列出現行條件再改摘要，不加「凡不確定就問」。 | `claude/CLAUDE.md` 的 shipping pointer；`shared/skills/project/references/log-workflow.md` Step 4；`ship-paths.md` 說法表相關文字。 | 正常 `--pr` 停在 PR、`--merge` 走既定 endpoint、不重問；必要 conflict 按既有選項解決、單答續作；同批 CI 修復最多兩次提交的既有邊界不變。 |
| Q2 納入：通知失敗摘要 | pointer 的「靜默」不能涵蓋所有失敗。既有 workflow：缺設定 no-op；transport failure 有 secret-safe warning；主結果不變。依 P2 oracle 對齊摘要。 | `claude/CLAUDE.md` 的 nc-notify pointer；預設不動 shared notification core。 | 正常 start/done、主工作 fail、缺設定、transport error、secret-bearing fake；不連 live NC、不部署。保留 P2/P3 scope 與安全結果。 |
| Q3 條件式納入：handoff 保存分類 | Critical 的「只留 pointer」與 W2 carry-forward 要按資料種類與已沉澱證據對齊。先查 H1/H5/H5b：規則 promotion、任務決策、死路不能直接合成「所有未沉澱 facts 都放正文」。 | `shared/skills/handoff/references/workflow.md` Critical／W2；確有證據時才新增對應 current eval，不改歷史結果。 | H5 未授權 repo edit 時承接死路；H5b 已授權且已沉澱才用 verified pointer，mutation 先於 anchor；H1 規則 promotion 保持。H15b/H16/H17b/H18/H19 的現行意圖／局部續作／產品決策邊界不變。若分類無唯一既定答案，只暫停此項並提最小規格問題。 |
| Q4 納入：現行 oracle 與歷史區隔 | Project「待補情境」仍有已推翻的多 commit 詢問要求。只新增明確 current-status／supersession 導航，指向現行 Scenario 8；不刪除或改寫歷史 Expected、舊 PASS/FAIL、日期與結果。 | `shared/skills/project/references/pressure-tests.md` 新增狀態說明；既有文字原樣保留。 | 不建立新 merge 預設；檢查 active oracle 的唯一可判讀性與歷史完整性。先做文件核對；無行為變更不為此重跑整個 #229 native packet。 |
| Q5 納入：authoring 規則適用層級 | Codex「核心留 SKILL.md」及 Claude「一律私人安裝路徑」需明確限定，與 portable contract 的 shared core／thin adapters 對齊。 | `codex/skill-building-guide.md`、`claude/skill-building-guide.md` 的相關段落。 | 不重構 topology、不將 shared core 搬回入口、不為逐字一致複製 workflow；worktree 引用仍解析該 worktree。只處理本 repo 規格，未解產品事實才查官方來源。 |
| Q6 納入：跨 repo scope 確認 | 使用者已指定 repo/range 就保留；僅候選集合尚不確定時按既有 workflow 確認。常駐 pointer 不另建 scope resolver，也不要求重建 invocation。 | `claude/CLAUDE.md` 跨 Repo 工作流；shared review／Project 原流程作唯讀依據。 | named repo 不重問、explicit range 不縮放、named empty-diff repo 不遺漏；真正未定的跨 repo scope 仍問，不掃廣泛目錄、不增加 reviewer。 |
| Q7 次要候選：条件前置與資訊順序 | 套件工具先寫適用範圍／既有 lockfile 優先序，再寫 bun/uv；Project 分清首 token 裸模式名與任意位置 mode flag，引用既有分類表。 | `claude/CLAUDE.md` Package Management；`shared/skills/project/references/workflow.md` 模式分派。兩者分開交付。 | 保留新／自有專案政策與既有 lockfile 例外；保留現有 mode/path 規格。矛盾 mode flags 沒有既定解答時不自行新增 precedence。沒有可觀察收益就 defer。 |
| Q8 defer：歷史說明搬移／Project 拆檔 | 目前不足以證明搬移或拆檔改善完成率／成本；#229 已有 same-SHA 沿用機制，不能重做成另一個方案。 | 本輪無候選寫入。 | 必要 kernel 複本、原生 import、反例、完整讀取與 SHA/EOF 契約保留；有實際漏讀或額外成本證據再另案處理。 |

## 分項實作與驗證順序

1. **先釘選現行規格。** 從目前 HEAD、目標段落與既有 oracle 建立每項「輸入／條件 → 必做、禁止、輸出」對照。
   Q4 舊判準先標識，Q3 的類別先查清；不修改舊證據來迎合候選。不為此新建全 repo 規則清冊或永久 store。
2. **先做可獨立對齊的項目。** Q2、Q5，再 Q1/Q6；每項先取得 observed RED 或固定 production-runtime baseline。
   靜態矛盾是可查證的文件證據，不冒充已量到模型失敗。只新增重現所必需的案例，不把非阻斷風格觀察升格。
3. **條件成立才做 Q3/Q7。** 能從已採用規格得出唯一答案才改寫；需要新產品決策則提出一次可續行問題，
   獨立已授權工作繼續。正常路徑不新增人為停點、全案審查或逐檔批准。
4. **先讀 authoring 契約再改 skill。** 依 root AGENTS.md 讀 system skill-creator、當前 runtime guide 與 portability；
   查雙端 linkage、原 defaults 與選定 oracle。候選只在隔離 feature worktree／fixture 測，避免 global symlink 提前啟用。
5. **驗證修正及相依範圍。** 實作前記 exact model/runtime/version、prompt、fixture/hash、工具與重複次數；
   受影響兩端沿 #229 的 production targets（GPT-5.6 Sol/high、Claude Code Opus 5，實際 identifier 先核對）。
   before/after 設定一致；runtime-specific pointer 可單端，但理由與共用語意 controls 必須明列。
   模型不可用就記缺口，不擅自以 Astra 或其他模型代替驗收。受改動影響的既有弱模型安全案例同樣保留。
6. **按风险收斂。** 每個 root cause 先做一版最小候選；新失敗才做針對性修訂，不自動重派 reviewer或重跑無關案例。
   原問題、語意相依與必要檢查已過就交付該項；不足則回到具體證據／決策，不追求零 findings。
   不設定未授權的 token、美元或整體時間上限；既有 workflow 的 review／repair 次數限制不變。

此次不啟動以上 native eval。後續各批確定 write scope 後才選必要 scenarios／樣本數，不藉計劃預排全套 #229 重跑。
套用 skill 改動時，在目標 runtime 使用正確 validator；不以 Codex validator 不識別 Claude 原生欄位為由刪 metadata。
依 root 契約執行必要 `./tests/run.sh`（保留原 exit code）、doc audit 與 diff check；已通過且內容未變不重跑。

## 品質與效率的等價驗收

| 面向 | 合格證據 | 不接受的替代證據 |
| --- | --- | --- |
| 規格保真 | 每個改動都有既定 authority/oracle；允許／禁止行為、觸發、scope、輸出與 gate 條件不變。 | 作者覺得意思一樣、字數更少。 |
| 正常路徑 | 完成正確產物與原 endpoint；無新增重問、invocation 重建、無關檢查或 scope 擴張。 | 只證明危險動作被攔下。 |
| 必要互動 | 具體事實／原則／已完成工作／完整選項／續作步驟，答一次後續行；只阻斷依賴答案的工作。 | 一律零問題，或把內部 actor/token 問題丟給使用者。 |
| 安全與完成品質 | 與正常臂成對的 scope、ownership、outward、secret、只讀及真實完成證據維持。 | 以少測試或少 reviewer 本身當品質提升。 |
| 效率與維護品質 | 可歸因的重問、規則調和或重讀減少；或現行規格與歷史可正確分辨。tokens/tool/time 有原始值才比較。 | 捏造整體提速比例、用固定 timeout 判不收斂、把舊機制 FAIL 重判 PASS。 |

歷史 baseline 僅在來源版本、prompt、fixture、模型設定確實可比時沿用；否則只作背景，新增當前最小對照。
保留原 raw failures 和不完整觀察；新的 outcome evidence 另列，不用成功分項掩蓋其他失敗。

## 交付、回復與 scope 邊界

每項交付附：精確 diff、原規格與改寫映射、適用 runtime、正常／安全證據、可觀察改善、未驗證限制與 disposition。
未達標只撤回本項候選，保留其他已驗證且獨立的成果；不動使用者／其他 writer 的變更，不使用 destructive reset。
未確認語意維持原文，不先改 oracle；本計劃不授權變更 helper 行為、核准新規格或放寬既有安全結果。

本輪實際 write scope 只有此計劃與 STATUS.md 的本工作項。計劃交付後保持 draft，等待使用者指派實作；
不自動啟動 project/deep-plan/repo-review、不寫 GitHub comments、不 commit/push/merge/dotsync，不關閉 #229。
