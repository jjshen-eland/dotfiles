<!--
backlog.md — 專案未結案待辦（技術債 + 已知缺口）。發現即記；解決或放棄後寫 D/X/M history
record、保留 B-* 關聯，再移除本檔條目。decision／dead end 不留在 STATUS.md 或本檔。
-->

# Backlog

待辦清單:技術債與已知缺口(更新日期:2026-09-15)

> **為什麼與 `STATUS.md`／history 分家**：三者生命週期不同。STATUS 只留 active／paused；history
> event 發生後 append-only；backlog 只留未結案狀態，直到做掉或明確放棄才會消失。
>
> **本檔刻意沒有 bytes／行數門檻**；治理靠 stable ID、關閉關聯與 repo-local audit。

## 關閉與歸檔慣例

- **償還／解決**：寫 `M-*` record，`關聯` 保留原 `B-*`，再移除本檔條目。
- **變成決策**：寫 `D-*` record（含理由與重議條件），再移除本檔條目。
- **明確放棄**：寫 `X-*` record，再移除本檔條目。
- **不刪**未解決的條目；看不順眼、過長或暫時不做都不是關閉條件。

## 技術債

- **B-20260902-gh-account-autoswitch** · [ ] **`gh` 的 active 帳號沒有依 repo 自動切換**（2026-09-02 加）。
  `gh` **完全不看 SSH alias**，active 帳號不對時的長相是 `Could not resolve to a Repository`
  ——不是權限錯誤，是「查無此 repo」（對那個帳號來說它確實不存在），所以第一次撞到很難聯想。
  現況只補了文件（`docs/repo-guide.md`「GitHub 多帳號：三個互不相干的層」），要人自己
  `gh auth switch`。
  ⚠️ **本批刻意不做 helper**，理由是兩條路都不乾淨：wrap `gh` 要改 PATH、影響所有 `gh` 操作、
  且有把非預期子命令攔下的風險；只在 shell function 覆蓋部分子命令則**覆蓋不全等於沒有**
  （漏掉的那個子命令仍會用錯帳號，而且症狀一模一樣）。
  - **觸發條件**：跨帳號操作變成常態、或同一個症狀再查錯方向一次。屆時傾向做成
    **唯讀提示**（進錯帳號時警告，不自動切），先驗證偵測那半是否可靠。

- **B-20260822-debt-30** · [ ] **文檔治理收尾順序:先釘正確性、再用真 repo 逼出缺口、最後才調 ranking**(2026-08-22 加)。
  依序:① immutability 刪除軸兩格 oracle(**2026-08-22 完成**,見 `M-20260822-immutability-removal-oracles`)
  → ② canary rollout(**2026-08-22 完成**,見 `M-20260822-doc-governance-adopted`,缺口已回填 checklist)
  → ③ 檢索 ranking:`B-20260821-debt-28`(單檔洗版)**已於 2026-08-22 關閉**;`B-20260821-debt-27`(程序型
  文件召回)仍開,但已分成「跨語言」與「權重形狀」兩個子問題,見該條。
  ⚠️ **順序理由**:27/28 打到的正是「不知道標題時找不找得到」,而那是第二個 repo 第一次用才會撞到的面;
  沒有真實 rollout 語料就調 ranking,等於對 dotfiles 自己的語料過擬合。
  ⚠️ **原 plan §6 的 steady-state rollout gate 已由 `D-20260822-rollout-gate-replacement` 取代**:canary
  (dotfiles 之後的第一個採用者)可立即開始;qualifying ship 記入 `docs/rollout-ledger.md`,**canary 之後的
  其餘 repo** 才要求 steady-state 證據。月份 shard 正確性不受影響,維持 blocking。
  ⚠️ 該記錄以「batch 1」指稱 canary,與 checklist 的形狀批次序是不同軸,已由
  `D-20260823-canary-role-not-batch-number` 校正——**讀到「batch 1」一律讀作「canary repo」**。(舊敘述以 `git log --merges` 為證據,在 squash merge 下恆為 0,
  已證偽:採用 commit 後實際有 2 次 ship。)

- **B-20260821-debt-27** · [ ] **檢索對程序型文件的語意召回偏弱**。Round 6 以 20 條不複製標題的
  query 探測 reference／policy／skill／eval／plan／backlog，僅 4/20 命中；本批八列 oracle 必須使用
  高辨識度 body 詞才能穩定進 top 5。後續需另以行為需求設計 ranking 改進，禁止把目標標題塞回 query
  製造假綠。
  ⚠️ **2026-08-22 用兩個語料（dotfiles ＋ canary）重量：hit@5 12/20 → 13/20**（per-file cap 帶來的，
  見 `M-20260822-retrieval-source-diversity`）。剩下的 miss **不是同一個問題，要分開處理**：
  - **跨語言**：`docs/document-governance.md` 全篇英文（語言政策要求），中文問題與它 token 交集為零
    ——**任何 ranking 改動都碰不到這一格**，要嘛加別名層、要嘛接受它只能用英文問。
  - **權重形狀**：title 命中 ×200、body ×20，而程序型文件的 section 標題是結構性的
    （「0. 前置」「2. history 遷移」），主題詞只在 body；history 條目的短標題塞滿領域詞，於是恆勝。
  - 已試過並否決：文件 H1 當弱訊號（`X-20260822-doc-h1-token-signal`，淨零）、body 覆蓋率取代全含加分
    （單獨無增益，疊在 cap 上反而 −1）、IDF 加權與兩種 H3 分節（`X-20260823-retrieval-idf-and-h3-chunking`，
    dotfiles 那半 hit@5 由 7 退到 4/5/5）。
  ⚠️ **2026-08-23 診斷再收窄一次：主因是分節方式，不是權重比值。** 實測 canary 的
    「重訊分類判準只有一份」是 **H3**，埋在 H2「MOPS 重訊爬蟲知識」底下；查「分類規則的正本放在哪一份」
    時，它的 H2 母節排第 26、標題命中數 0——**H2 才是檢索單位，H3 標題只是 body（每命中 ×20 而非 ×200）**。
    這一格**改排序治不好**，正解在作者面：要被找到的東西放 H2。已寫進 `docs/document-governance.md`。
  - **下一步候選（未做）**：canary 的 `CLAUDE.md` 有四條陷阱是 H3，值得提為 H2 再量一次——那會是
    「作者面修正能不能取代 ranking 修正」的第一個直接證據。
  - 現有 ratchet：`tests/fixtures/doc-governance/title-free-recall.tsv`（dotfiles 那 10 條，hit@5 ≥6）。
    **提高門檻只能用新寫的 query 重新量。**
- **B-20260821-debt-26** · [ ] **文檔治理 Round 3 非阻斷後續**。本批不順手擴張核心：xref 待處理
  ignored dirs、alias stale 的 finding/error 語意、正反向 section 比對、shell heredoc fence 與兩份
  `alias_sources` 推導；CLI 待決定 positional files、ship 輸出順序與 adoption 診斷；測試待解除固定
  backlog ID、補 repo-wide audit 與 route portability；另須讓 Codex always-on 接上 event-time 記錄規則。
- **B-20260820-debt-25** · [ ] **文檔治理 Round 2 非阻斷後續**（2026-08-20 加）。本批只修會讓
  gate、檢索、ship 或 agent 行為失真的 blocking findings；其餘待獨立處理：補 `supersedes` 反向邊的
  搜尋呈現、定義 glob class 的 `requires_inbound` 語意、決定 `mode: governance` 是否保留、提供
  worktree trusted-core mismatch 的操作指引，以及縮短 canonical-title 檢索測試的成長成本。
- **B-20260819-debt-01** · [ ] **決策/死路的機械召回**(2026-08-19 加,**獨立候選**)。現況是檢索靠人自覺、沒有機械觸發。
  領域索引(本批要做的那個)是**人工維護、粗粒度**的版本;機械化版本是
  **`PreToolUse` hook + 以檔案路徑為鍵的倒排索引**——要動 `xref-gate.py` 時,自動把
  「提過它的 N 條決策/死路」注入 context,**不必你想到要查**。這正是死路「要在你沒想到要查
  的當下擋住你」的機械層；同 `D-20260811-symmetric-rules-as-signal`「文字是最易被跳過的那層，
  訊號化才接得住」的判準。
  ⚠️ **本地 file-based 向量庫(sqlite-vec / LanceDB / vectorlite)不是這條的重點**:語料才
  ~200 條/300KB,暴力算 cosine 就夠,連 DB 都不需要;而**精確路徑比對比語意相似更準**。
  向量只在「動的東西與決策沒有字面重疊」時才有增益。三條硬約束(git 唯一媒介/隨 repo 移交/
  不引入第二份權威)**都不違反**——索引是衍生物、gitignored、可從 md 重建,故不在 2026-08-14
  否決 mem0/Zep/Letta 那條的範圍內;新成本是 embedding 模型這個 runtime 依賴。
  ⚠️ **2026-08-19 觸發條件重寫**:原本寫「等領域索引跑一陣子後仍然發生」,而領域索引所屬的
  分片計畫三版皆被判不通過 ⇒ **該條件永遠不會成立,是循環依賴**(第三方審查抓出)。
  **新觸發條件:本條升為獨立候選,不依賴分片計畫。** 它解的是「儲存」與「召回」拆開之後的
  召回那一半,與分片(只解儲存)正交。⚠️ 設計上須用 `permissionDecision: deny` 擋第一次呼叫
  再讓模型重讀,**不要只回 `additionalContext`**——官方文件**未載明**該欄位相對於工具執行的
  時序,不賭未定義行為。`Bash` 寫檔旁路需另有 fixture。
- **B-20260819-debt-02** · [ ] **handoff `survey`／`list` 等價 gate 的前綴白名單是寫死的**(2026-08-19 加)。
  `tests/run.sh` 那條「survey 的 active 區段與 list 逐字等價」用
  `grep -E '^(active: |  path: |  title: )'` 兩邊比對,**任何新增的縮排子行都不在名單內、
  天生豁免於這道 gate**。本次(mtime 時戳)只加欄位、未加子行故未受影響,但附錄評估過的
  「錨點 repo 欄」(`repos: dotfiles, krepo`——多份 active 時最強的辨識訊號)一旦要做,
  必須連同這個缺陷一起處理:擴白名單、或改成「比對兩邊全部 active 相關行」。
  ⇒ 該欄本次刻意不做,理由與取捨見 `docs/plans/2026-08-19-handoff-active-mtime.md`。
- **B-20260819-debt-05** · [ ] **`deep-plan` 的模型層級待一個獨立決定**(2026-08-19 加,與下一條同型)。2026-08-19 首次真實執行
  跑在 **Opus**(session 模型),而全部 evals 校準在 **Sonnet**(樓層)。兩個後果性質不同:①**成本**
  ——第二輪與 N 都動不得(理由見 `shared/skills/deep-plan/field-log.md`「C2 — 第二輪不能砍，但它審的是處置而非計畫」),
  模型是唯一沒動過的降本槓桿;②**可比性**——強模型會自己補上規則要求的行為,**跑在 Opus 的觀察
  一律不能拿來判「某條規則有沒有作用」**。要決定的是「預設釘 Sonnet、需要時才升」還是「維持吃
  session 模型、只在 field log 記下當次模型」。⚠️ 不該在檢討裡順手改——同下一條。
- **B-20260818-debt-06** · [ ] **`deep-plan` 的 N 預設值待一個獨立決定**(2026-08-18 加)。E1 實測阻斷級聯集 N=2→5.00、
  N=3→6.00,**判準寫的「沒有新增就維持 2」條件不成立**,而它只定義了那一個分支 ⇒ 預設維持 2 未動。
  要決定的是成本 vs 覆蓋:多出來的**全是嚴重度分歧、不是新問題**(核心那條 4/4 全中、四臂結論一致),
  但每加一個 reviewer 約多 1.7 條 findings。⚠️ **同批還有第二格沒定義到**:E3 的判準要求
  「(c) 佔多數**且**含阻斷級」才判上限不足,實測落在「(c) 少數卻含唯一阻斷」——兩格都**不可事後補**,
  要改判準是新的一次決定。逐條數據見該 skill `evals.md` 的 E1／E3 節。
- **B-20260817-debt-07** · [ ] **`deep-plan/evals.md` 未經 2026-08-17 那場 `/deep-review`**(batch 條款禁止 eval 檔進 reviewer
  prompt)。要不要單獨審是獨立決定,尚未做。⚠️ 2026-08-18 該檔又大幅擴充(P8–P12 ＋ 八次實跑紀錄),
  未審的面積比當初更大。
- **B-20260820-debt-17** · [ ] **「tests/stub 有覆蓋、實戰未驗」一組**(遇到對應情境時順手確認即可,不必專程做):
  SessionStart hook 落後提醒(真實落後的 clone);autocodex exec 的 resume 分支(exit 4 救援階梯,
  三輪實跑皆一次成功、只有 stub 覆蓋,F15(b) 待真實空報告);review-anchor 的 stale STOP 與
  codex-next 冪等(F16 b/c,待 autofix 迭代中真的 rebase/重試);repo-review 新契約(F16–F18 規格
  覆蓋,待多輪 autofix 確認弱模型不會退回每輪帶 `--autofix`)
- **B-20260820-debt-18** · [ ] Scenario 11 的「merge 但無 PR」分支只在 SKILL body 一行指標帶到 ship-paths,GREEN 實測中
  弱模型未展開讀——非違規故未補;重現才加明示(Iron Law)
## 已知缺口

- **B-20260824-remote-human-contributor-path** · **單一 Dossier Steward 模型尚未定義跨機器真人
  contributor 的 commit 傳遞路徑**(2026-08-24 發現)。`D-20260824-cross-runtime-dossier-stewardship`
  的 v1 只實證同機 Claude／Codex worker：非 steward 不改 shared dossier、不 push，交 semantic commit
  給 steward cherry-pick；但真人同事在另一台機器時，若不能 push 專屬 feature branch，就沒有自然的
  commit 交換媒介。未決：是否新增受限 remote-contributor path（只推專屬 branch／開 PR、禁止改 shared
  dossier 與自行 merge、PR 附 Dossier delta，由 steward 補 canonical state），以及它與既有 branch
  protection、scope ownership、`project transfer` 後協作如何進 behavior eval。**在新決策與 RED oracle
  出現前，不把這個候選路徑當成已生效規則。**

- **B-20260813-gap-01** · **codex reviewer 跑得動測試、但跑不完**(2026-08-13 C1 實測):PR #94 的 profile 解決了「建不了 cache」
  (events 實查真跑了三次),但 sandbox 內 `PASS=956` vs 主機 `983`,伴隨 `cloned an empty repository`
  ——建 git fixture 在 `:read-only`+tmpdir-write 下仍受限。**「能啟動」≠「跑得完」**;那個中途計數正是同輪
  假 `verification: executed` 的來源(被讀成「全部通過」,漏掉 `TEST_RC=1`)。調 profile 前先看這條。
- **B-20260807-gap-02** · **eval 的受測 subagent 拿不到 deferred tools,部分契約在沙盒中無法構造**:2026-08-07 實測——
  主 session 的 `CronList`／`TaskOutput` 正常,探針 subagent(`Tools: *`)對同一批 `select:` 一律得
  `No matching deferred tools found`。凡「該工具查得成」才成立的情境因此做不出來,ready4quit
  **Q4c**(`RECALLED + ✓`,需最低證據等級剛好是 RECALLED)至今無 GREEN 證據。symlink 前置已解除,
  但手動驗證二度失敗,並暴露原程序自身兩個錯(`~/.dotfiles` 當 pwd 讓 Git 衛生恆 ⚠;「全新且安靜的
  session」自相矛盾——無對話歷史時回憶型面向只會落 PARTIAL)。**v3 程序見
  `shared/skills/ready4quit/evals.md`,別再照舊程序跑。**
- **B-20260811-gap-03** · **同型處置的 self-report 擋得住靜默跳過,擋不住填了但敷衍**(2026-08-11 落地兩軸拆分＋五個終態
  報告必填「同型處置紀錄」表之後的殘留面):**表格內容無法機檢**,`tests/run.sh` 第 1f 節只驗
  **結構**(模板覆蓋率、表頭形狀、引用行不複述軸名等,逐項以該節為準)。R5 終止路徑為何不補
  behavior eval 見 `docs/archive/decisions-2026-08.md`「同型掃描的 R5 終止路徑刻意不設 behavior eval」。

- **B-20260807-gap-04** · **Mac 上 brewup 會被 codex cask 掛死(Gatekeeper)**:2026-08-07 第三次發作。復原已有入口
  `brewfix`(唯讀診斷,`--fix` 才動手);機制、鑑別法、三條走不通的預防路徑全文見
  `claude/known-hazards.md`「cask 升版卡死」,**此處不重述**。**仍未解**:確切觸發條件未知且事後無法重現
  (同版本內容換路徑執行正常),要重現只能等該 cask 真正出新版。**未決**:預先設 xattr `0x0040`
  技術上可行,但前提已被負面結果動搖、代價卻是確定的(拿不到 tarball 簽章身分)——
  **用確定的代價換不確定的效果,暫不做**,優先靠已實證的復原路徑。

- **B-20260810-gap-05** · **kernel 的「fallback conventions 由 repo 勝出」對 host repo 實務上不可達**(2026-08-10 G6 樓層
  重跑的新 RED):Sonnet 兩次都用 Conventional Commits,而該 repo 明文拒絕它——**根因不是違抗,是
  `AGENTS.md`/`CONTRIBUTING.md` 的 tool_use 皆為 0,它沒看過那條規則**。safety floor 是被載入的
  文字所以穩;deference 卻要求一個「先去讀檔」的動作,沒有東西保證它發生(與 G1b 同一失效面)。
  **觸發:真的要在別人的 repo 常態工作時**——候選解三條與代價見
  `claude/evals/contract-evals.md`「這條 RED 的根因不是違抗，是那個檔從頭到尾沒被打開」。
- **B-20260820-gap-06** · **`codex/AGENTS.md` 與 root `AGENTS.md` 同名不同角色**(來源檔 vs repo-resident 契約):改
  `codex/**` 時兩份都被當 guidance 餵進 reviewer——**重複但無害,改名已 DROP、此實害就這樣接受**
  (理由見 `docs/archive/decisions-2026-08.md`)。
- **B-20260820-gap-07** · 爬蟲配置類 STATUS.md 撞名(npm-cs/knowledge-builder):源頭在 general-rag-cs template,
  改名(CRAWL-CONFIG.md)需動 template 腳本——另開工作項。
- **B-20260820-gap-08** · biz-chat 移交檔三台路徑漂移(tmp/ vs handoff/,皆已 gitignored)+credentials 明文散於三台。
- **B-20260807-gap-09** · **`agy`(Antigravity CLI)只手動裝在 macs,未寫進 `setup-mac-env.sh`**:2026-08-07 因 gemini-cli
  已於 2026-06-18 停服而改裝其後繼(`brew install --cask antigravity-cli`,binary 名 `agy`)。
  後果:新機器跑 setup 不會裝、macmini/m4mini 目前也沒有。該 cask 標 `auto_updates`,故 `brewup`
  不會升它(除非 `--greedy`)。**它沒有 `generate_completions_from_executable`,不會踩 codex 那個
  Gatekeeper 坑**,但首次執行仍會走核可流程——要裝就在該機 console 前跑一次。
- **B-20260809-gap-10** · **兩部個人 MacBook 不在 `inventory.conf`**(公司／家中,經 VPN ssh 進 macs),`dotsync`／`allup`
  涵蓋不到——兩機已各自補齊,**留下的是結構性事實**:要跟上得在該機本地跑 `brewup`,不會有人幫
  它們 pull,而**漏跑是無聲的**(skill／地雷／模板停在舊版)。**加進 inventory 這條路今天不可用**:
  2026-08-09 查 tailnet 沒有它們,且常離線的筆電會讓每次 dotsync 都帶 ❌、稀釋訊號。
  **待確認是刻意(終端設備不入清單)還是缺口。**

- **B-20260907-governed-repo-declared-path-gaps** · **已 rollout 的 repo 有配置缺口，等各自的 session 補**(2026-09-07 加)。
  issue #165 實測六個 repo:`krepo-tej-export` 與 `krepo-mops-financial-statements` 的 `plan_dir` 指向
  `docs/plans` 卻沒有 `plans` class;`krepo-mops-financial-statements` 的 `STATUS.md` Dossier Steward 欄被中文
  註解裝飾過。成因不是粗心，是 rollout 方法論「classes 對著該 repo 現有 canonical paths 寫」的必然後果——
  rollout 當下沒有那個目錄就不會建 class。**scanner 側已於 `M-20260907-doc-governance-silent-config-gaps`
  修完**，這兩個 repo 下次跑 `audit --ship` 會自己報出來，故此處**不列修復步驟**，只記「本 repo 已知但
  刻意未跨 repo 動手」。附帶觀察同源:`analysis`（`docs/analysis/*.md`）與 `script-guides`（`scripts/*/README.md`）
  在部分 repo 缺漏，但它們沒有 `plan_dir` 那種矛盾證據，機械偵測不到——**未決**:rollout 是否該對照一份
  標準 class 清單逐項確認要或不要。

- **B-20260907-actor-key-decoration-limit** · **`ACTOR_RE` 擋得住空白、擋不住無空白的裝飾**(2026-09-07 加)。
  規則是 `^(claude|codex|human|owner|external|unassigned):[^\s:][^\s]*$`，所以
  `` `codex:kb-x`（使用者於2026-09-01具名移交terminal scope） `` 因為含空白被兩個 gate 一致拒絕，
  但 `codex:ui（暫代）` 這種**沒有空白**的中文裝飾會**同時通過** `audit` 與 `steward-authority.py`。
  後果比原缺口輕（兩個 gate 至少一致，不會再出現「audit 綠、authority BROKEN」的死結），但
  `derived_actor` 的 `writer.startswith(f"{runtime}:")` 仍會靜默不匹配、退回 branch 推導。
  **未決**:收緊 `ACTOR_RE`（例如限定 ASCII 字元集）會改變 `steward-authority.py` 在所有已 rollout repo 的
  執行期行為，需要先盤點各 repo `STATUS.md` 的實際寫法才知道會擋掉誰;2026-09-07 判為超出 issue #165 範圍。
