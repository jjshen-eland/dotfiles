# Git 身分與專案目錄分界的收斂

- 日期：2026-09-02
- 狀態：in-progress
- 工作項：git-identity-boundary
- 種類：implementation
- 需求來源：issue #161「統整 review：公司／個人身分分界、git 全域設定、GitHub 連線 protocol」

> **spec 定稿**（2026-09-02 記錄，同日開工）。進度與下一步留在 `STATUS.md`「進行中」。

## Context

本 repo 歷史累積了**四種**作者身分：兩個個人 email、一個公司 email，以及
`jjshen@jjshen-mba.local`——最後這個不是信箱，是 git 在找不到 `user.email` 時依
`username@hostname` **自動捏造**的。它不報錯、不詢問，就這樣進了 commit。

實測（git 2.x、macOS）：

| 設定 | `git commit` 行為 |
|---|---|
| 無 global、無 repo-local `user.email` | 靜默用 `<user>@<hostname>` 提交 |
| 同上 ＋ `user.useConfigOnly = true` | `Author identity unknown` 直接擋下 |

**這不是假設性風險，2026-09-02 盤點時機隊上仍有一台處於同一狀態**：

| 主機 | `user.email` | `useConfigOnly` | 專案目錄 |
|---|---|---|---|
| eagle03/06/07/08/09、db01、ap01/02、macmini、agent01、fe01、be01 | `<工作 email>`（寫死在 `~/.gitconfig`） | 無 | `~/Projects` |
| **m4mini** | **（空）** | 無 | 只有 `~/.dotfiles` |
| macs（公司主力開發機） | `<工作 email>`（寫死） | 無 | `~/Projects` |
| 家中 MacBook | `includeIf` 分流 | 有 | `~/Projects` ＋ `~/SideProjects` |

觸發點是使用者的工作重心遷移：agentic engineering 從個人興趣變成公司主力工作方式，現在
約 90% 是公司專案，主力開發機是公司的 macs（在家時由 MacBook ssh 過去）。設定卻是沿著那段
歷程逐步長出來的，沒有人一次想清楚。2026-09-02 在家中 MacBook 本機 clone 一個私人專案時，
目錄與 git 設定的混亂才浮出來。

`git/config` 當時只有一句「`user.name` 和 `user.email` 請在各機器的 `~/.gitconfig` 設定」
然後就停住——**怎麼設**沒有規範，於是每台機器各自為政。全 repo 搜不到 `includeIf` 或
`useConfigOnly` 任何字樣。

## Goal

1. 沒有任何一台機器能再靜默產出捏造身分。
2. 「這個 repo 該用哪個身分」有一條機械規則，不靠記憶。
3. 規則隨 dotfiles 散佈；身分值留在機器層、不進 git。

## 決策

### D1 — 目錄分界：`~/Projects` 公司、`~/SideProjects` 個人、`~/.dotfiles` 工作

`~/.dotfiles` 需要自己一條規則，因為它**不在**任何專案根底下。判為工作身分的理由：它的
origin 在工作帳號（`jjshen-eland/dotfiles`）、全機隊 15 台都有它、90% 的使用場景在公司機器。

兩個根由 setup 腳本 `mkdir -p` 建立。**沒建立時「分界」只是一句文件裡的話**——`proj` 跳不
到個人專案，就會有人把它放回 `~/Projects` 圖方便。

⚠️ **已知反例**：macs 的 `~/Projects/isdotgd` 是個人 repo（`git@github-me:dev-bitpod-cc/isdotgd.git`）
坐在公司目錄裡。處置是搬到 macs 的 `~/SideProjects`，不是為它開一條 per-repo 例外——
**例外一旦允許一個，規則就退化成慣例**。

### D2 — 兩層切法：規則進共用層，值留機器層

- 共用層 `git/config`（dotfiles 散佈）：`user.useConfigOnly = true` ＋ 三條 `includeIf`，
  指向**固定檔名** `~/.gitconfig-work` / `~/.gitconfig-personal`。不含任何 email。
- 機器層：那兩個檔由 `scripts/setup-git-identity.sh` 生成，權限 600，不進 git。

檔名是**契約**：改名要同時改 `git/config`，否則 include 會靜默失效（git 對不存在的
include path 不報錯）——但失敗方向是安全的，落到 `useConfigOnly` 擋下。

**為什麼 `useConfigOnly` 屬於共用層**：它不含任何身分資訊，卻是整套設計裡唯一有強制力的
一格。留在機器層等於每台機器自己決定要不要有安全網，而漏掉的那台是無聲的。

**為什麼要一支腳本，不是叫人自己寫 `~/.gitconfig`**：
1. 漏設是靜默的（見 Context 的表）。
2. `~/.gitconfig` 裡殘留的寫死 `[user] email` 會**贏過分界**——分界外的 repo 會安靜地用它，
   那正是要消滅的「能動但錯了」。`--apply` 一併移除它並備份。
3. 十幾台機器各手設一次就是十幾次出錯機會。

### D3 — `gh` 的 `git_protocol` 不是 dotfiles 能決定的，文件照事實寫

實測（2026-09-02）：`gh/config.yml` 寫 `https`、`~/.config/gh/hosts.yml` 寫 `ssh` →
`gh config get git_protocol` 回 `https`，但 `gh auth status` 與實際 clone 走的都是 **ssh**。
**host 層勝過全域**，而 hosts.yml 由 `gh auth login` 寫、含 token、不能進 repo。

所以 repo 裡那行從來沒有作用過，是一行會誤導人的死設定。改成與現實一致的 `ssh`，並在檔內
寫明優先序與後果。

`git_protocol` 是 host 層級、兩帳號共用、無法分帳號設定，所以
`gh repo clone dev-bitpod-cc/<repo>` 必然產出 `git@github.com:dev-bitpod-cc/...`＝走預設
key＝工作身分，症狀是「連得上但權限不對」。收尾用既有的
`scripts/migrate-github-remotes.sh --apply`（它本來就有 `github.com:dev-bitpod-cc/*` →
`github-me:` 這條換寫規則），只需把預設搜尋根補上 `~/SideProjects`。

### D4 — gh 多帳號切換先補文件，自動切換 helper 列 backlog

`gh` **完全不看 SSH alias**；active 帳號不對時的長相是 `Could not resolve to a Repository`
（不是權限錯誤——對那個帳號來說該 repo 確實不存在）。先把「症狀 → `gh auth switch`」與
「兩帳號 scopes 必須一致」寫進 `docs/repo-guide.md`。

依 cwd／remote owner 自動切 active 帳號的 helper **不在本批**：它要嘛 wrap `gh`（改 PATH、
影響所有 `gh` 操作、有把非預期指令攔下的風險），要嘛只在 shell function 覆蓋部分子命令
（覆蓋不全等於沒有）。真實痛感只出現過在少數幾次跨帳號操作，代價與收益不成比例。列為
`B-20260902-gh-account-autoswitch`。

## Acceptance Criteria

1. `git/config` 含 `useConfigOnly` 與三條 `includeIf`，且**不含任何 email**。
2. `scripts/setup-git-identity.sh --check` 在本機回 `verdict: OK`；
   `--apply` 能生成兩個 600 權限的身分檔並移除 `~/.gitconfig` 的寫死身分（含備份）。
3. 在 `~/.dotfiles`、`~/Projects/*`、`~/SideProjects/*` 三處分別解析到正確 email；
   三個根之外的 repo 得到 `Author identity unknown` 而非捏造身分。
4. `proj` 同時掃兩個根；兩個根由 setup 腳本建立。
5. `gh/config.yml` 的 `git_protocol` 與實際生效值一致，且檔內寫明 hosts.yml 優先。
6. `migrate-github-remotes.sh` 預設根含 `~/SideProjects`。
7. `docs/repo-guide.md` 同時涵蓋連線身分與 commit 身分兩半，並列出 GitHub 多帳號那三層。
8. `./tests/run.sh` 全綠（以 exit code 判）。

## 遷移順序（跨機器）

```
1. 本批進 origin/main                      ← 散佈的前提，本地 branch 未 push 時 dotsync 是空轉
2. 各機器 brewup / dotsync 拉到新 git/config
3. 各機器跑一次：
     ./scripts/setup-git-identity.sh --apply --name <n> --work-email <e> [--personal-email <e>]
4. macs 額外：建 ~/SideProjects 並把 isdotgd 搬過去
```

⚠️ **第 2 步之後、第 3 步之前的空窗是安全的**：12 台機器 `~/.gitconfig` 的寫死 email 排在
`[include]` 之前，includeIf 指向的檔案還不存在時 include 被靜默略過，寫死值仍生效 ⇒ 不會
突然無法 commit。**唯一會當場被擋下的是 m4mini**（它本來就沒有身分，被擋正是本批的目的）。

## 風險與回退

改的是 commit 身分解析，改錯的長相是「commit 不了」（吵、當場知道）而不是「用了錯身分」
（靜默）。這個方向是刻意選的。

回退：`git revert <本批 commit>` ＋ 各機器重新 `brewup`。機器層的 `~/.gitconfig` 有
`--apply` 當下產生的 `.bak.<timestamp>` 備份。

⚠️ 與 2026-08-06 那批 SSH 收斂不同，**本批不影響 GitHub 連線**，所以回退路徑不會被自己弄壞
（遠端機器仍拉得到修正）。

## 明確不做

- **不追溯修正既有 commit 的錯誤身分**。已 push、rewrite 成本高，且四種身分的存在本身就是
  這份決策的證據。
- **不為 macs 的 `~/Projects/isdotgd` 開 per-repo 例外**（見 D1）。
- **不做 gh 自動切帳號 helper**（見 D4）。
- **不把身分值放進共用設定層**：`git/config` 不含 email，兩個身分檔不進 git。dotfiles repo
  是 **public** 的（`jjshen-eland/dotfiles`，也是 `dot.bitpod.cc` bootstrap 的來源），
  所以連散文都用 `<工作 email>` 佔位，不新增實際位址——工作信箱在本 repo 早有既存出現
  （`claude/skills/send-mail/`），個人信箱則從未出現，別讓它從這批開始。
