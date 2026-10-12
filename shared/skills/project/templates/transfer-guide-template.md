<!--
移交指南模板 — /project transfer 使用
位置慣例:填完後放 <repo>/docs/transfer.md,之後由 Log 送出(本體不含機密,可上 git)。
目標:接手者只靠 fresh clone 與本指南就能掌握全貌,不需要移交人在場。每節寫事實與指向,不寫「問我」。
Credentials 一律分離:值放 gitignored 檔或密碼管理器,以私訊/密碼管理器交付,絕不進 git;本指南只記名稱與存放位置。
接手驗收題組的預期答案放 gitignored 的 tmp/transfer-acceptance.json,不寫進本指南或任何 tracked 檔。
-->

# <專案名> 移交指南

> 目的:讓 <接手者> 只靠 repo 掌握全貌、自行建立環境與維運,並通過接手驗收題組。
> 移交人:<name>|接手者:<name 或 未指名>|目標日:YYYY-MM-DD
> 狀態:草稿／可移交（缺項見第 10 節；全部解除才改為可移交，該次變更由 Log 送出）

---

## 0. 待決策事項(移交前雙方確認)

<!-- 每項決策:選項攤開、拍板後打勾。範例列常見類別,依專案增刪 -->

| 編號 | 決策 | 選項 | 決定 |
|------|------|------|------|
| D1 | API key / LLM 來源 | 自申請 / 走 gateway / 共用既有 | ☐ |
| D2 | 資料庫存取範圍 | 唯讀帳號範圍、schema 界線 | ☐ |
| D3 | 外部服務帳號 | 誰申請、誰核准 | ☐ |
| D4 | Repo 權限模式 | fork / collaborator / transfer ownership | ☐ |
| D5 | 驗收通過後的合併與切換 | 誰 review、誰 merge、何時切 owner | ☐ |

## 1. 系統組成與外部依賴

- **一句話**:<這個 repo 做什麼、給誰用>
- **組成**:<主要模組／服務與各自的入口檔>
- **外部依賴**:<DB、向量庫、gateway、第三方 API；各自的用途與連線設定位置>
- **必讀**:`STATUS.md`(進行中工作)、`CLAUDE.md`／`AGENTS.md`(慣例)、`README.md`(安裝)

## 2. 環境建置與驗證

<!-- 每步附可執行的驗證指令與預期結果 -->

1. <clone 與依賴安裝:uv sync / bun install>
2. <.env 設定:對照 .env.example;值見第 4 節的存放位置>
3. <外部依賴連線驗證指令>
4. <測試指令與預期結果:uv run pytest → N passed>
5. <起服務 + 冒煙測試指令>

## 3. 部署、排程與維運

- **在哪裡跑**:<主機／環境、部署方式與指令>
- **排程**:<cron／timer：在哪台主機、何時、跑什麼、設定檔路徑>
- **掛了先看哪**:<log 位置、health check、常見故障與處置>
- **誰會收到通知**:<告警與通知管道>

## 4. 外部帳號、權限與 credential 清單

<!-- 只記名稱、用途、存放位置與誰能核發;值絕不寫進本檔 -->

| 名稱 | 用途 | 存放位置 | 誰核發／誰能撤銷 |
|------|------|----------|------------------|
| <ENV_KEY 或帳號> | <用途> | <密碼管理器 vault／gitignored 檔路徑> | <人或角色> |

- 交付管道:<密碼管理器分享／私訊>；選 repo 內 gitignored 檔時，metadata helper 已驗證 untracked、gitignored、
  非 symlink、private mode

## 5. 進行中的工作

- 指向 `STATUS.md`「進行中」：每個工作項的 Goal／進度／下一步已更新到接手者能直接接續，本節不另抄。
- 未合併的 branch／worktree：<逐條列出 branch 與處置；沒有就寫「無」>

## 6. 決策與死路入口

- 查詢方式:<`scripts/doc-governance.py find '<問題>'` 範例，或 legacy repo 的對應位置>
- 關鍵決策與死路:<D-*／X-* ID 與一句話結論>

## 7. 已知風險與技術債

- <上線中的風險與對應處置>
- 技術債與缺口:<`docs/backlog.md` 的 B-* ID 或 legacy 位置>

## 8. 支援期限與聯絡方式

- <移交人可支援到哪天、用什麼管道聯絡、之後找誰>

## 9. 接手驗收題組

<!-- 只放題目與作答方式；預期答案在移交人保存的 tmp/transfer-acceptance.json -->

接手者在只有 fresh clone 的環境作答，不問移交人。答案寫成 `{"<題號>": "<答案>"}` 的 JSON 交給移交人判分；
指令題的答案是一行可在 clone 根目錄執行的唯讀本地驗證指令（例如跑測試）；部署、排程與對外服務都是問答題。

1. **Q1**（指令）:<例：寫出跑完整測試的指令>
2. **Q2**（問答）:<例：夜間同步在哪台主機、幾點執行？設定檔在哪？引用路徑>
3. **Q3**（問答）:<例：為什麼不用 X？引用對應的 D／X ID>

## 10. 移交準備度與步驟

- [ ] fresh clone 能只靠 repo 內的指引完成第 2 節並跑過測試
- [ ] adopted repo 的 `audit --ship` 通過；程式碼與 tracked 檔無硬編碼 secret
- [ ] 移交人已知的 private-only project decision／dead end／progress／blocker 已寫進既有 repo authority
- [ ] safety／Git／cross-runtime stable preference 已列為 instruction promotion candidate，不塞 project dossier 或 private-memory pointer
- [ ] 在途工作皆已合併，或已有記理由的 decision record 明確放棄
- [ ] 第 9 節題組已建立，`tmp/transfer-acceptance.json` 已被 gitignore 且未 tracked
- **缺項**:<none 或逐筆列出>

移交步驟：

1. 本指南與 audit 補寫的紀錄由 project Log 送出。
2. 接手者以 fresh clone 作答第 9 節，移交人以 `grade-handover.py` 判分全數通過。
3. Repo 權限調整:<接手者升 admin / transfer;移交人降權或留顧問>（本 workflow 不代做）。
4. Authorization 不移交：push／PR／merge／deploy／message 每個 outward action 都由執行當下的使用者指令重新取得。
