<!--
backlog.md — 專案未結案待辦（技術債 + 已知缺口）。發現即記；解決或放棄後寫 D/X/M history
record、保留 B-* 關聯，再移除本檔條目。decision／dead end 不留在 STATUS.md 或本檔。
-->

# Backlog

待辦清單:技術債與已知缺口(更新日期:2026-09-16)

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

- **B-20260916-sessionstart-behind-warning-field-observation** · [ ] **SessionStart 落後提醒尚無可歸因的真實事件證據**。
  現行 hook 與 deterministic multi-remote fixture 都仍有效，未觀察到行為缺口；但 hook 不留持久 log，Git reflog
  也沒有能同時證明「由 SessionStart 執行」與「當時 HEAD 真的落後」的日後記錄。
  **精確觸發**：下次在某 clone 的當前 branch 已設 upstream、remote 自然多出 commit，且正常啟動 Claude
  session 時，當下保留 hook stdout 以及 `HEAD..@{u}` 計數；若提醒正確則結案，若漏報或誤報則以該事件先取得
  RED 再修。不為清 backlog 人工推遠端、不新增持久監控或啟動噪音。此項由
  `B-20260820-debt-17` 拆出。
## 已知缺口

- **B-20260824-remote-human-contributor-path** · **單一 Dossier Steward 模型尚未定義跨機器真人
  contributor 的 commit 傳遞路徑**(2026-08-24 發現)。`D-20260824-cross-runtime-dossier-stewardship`
  的 v1 只實證同機 Claude／Codex worker：非 steward 不改 shared dossier、不 push，交 semantic commit
  給 steward cherry-pick；但真人同事在另一台機器時，若不能 push 專屬 feature branch，就沒有自然的
  commit 交換媒介。2026-09-16 以現行 feature branch／PR、Project authority gate 與可取得的 rollout repo
  紀錄重驗：Git 傳遞媒介存在，steward 評估 candidate commit 時也能列出 shared-surface 越界；但 worker
  no-push 契約與不辨 contributor 身分的 PR CI 尚不能合成一條已驗證的新路徑。可取得的 PR／commit 紀錄沒有
  remote-human contributor 實例，未觀察到實際傳遞阻塞或 authority drift，故不新增程序、eval 或 provider
  gate，也不把候選路徑宣告生效。**精確觸發**：第一位具名、跨主機真人 contributor 需要交付 commit，或
  首次出現非 steward PR；當下保留 exact SHA、declared scope 與 Dossier delta，實測 steward 能否 fetch、
  以現行 helper 排除 shared-surface 越界並 cherry-pick。任一步受阻，或越權 shared dossier mutation 未被攔下，
  才以該事件取得 RED 並設計最小 remote-contributor path。

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
