# Shell 環境設定工具

跨平台（macOS + Ubuntu 24.04+）的現代化開發環境自動配置工具。

## 檔案結構

```
config/
├── README.md              # 本文件（快速入門）
├── CLAUDE.md              # Claude Code 環境指引（自動讀取）
├── bootstrap.sh           # 雙平台一鍵 bootstrap（macOS + Ubuntu 24.04+）
├── claude/                # Claude Code 共用設定與 skills
├── codex/                 # Codex 共用設定、rules、skills
├── setup-mac-env.sh       # macOS 開發環境安裝腳本 (v5.0)
├── write-mac-defaults.sh  # macOS 系統偏好設定腳本 (v1.0)
└── setup-linux-env.sh     # Linux Ubuntu 安裝腳本 (v5.0, Homebrew)
```

## 快速開始

### macOS（新機一鍵安裝）

```bash
curl -fsSL dot.bitpod.cc | sh
```

自動完成：Xcode CLT 安裝 → clone repo → 執行環境設定。

### Linux（新機一鍵安裝）

```bash
curl -fsSL dot.bitpod.cc | sh
```

自動完成：apt 前置依賴 → clone repo → Homebrew 安裝 → 執行環境設定。

### 忘記安裝指令時

```bash
curl help.bitpod.cc
```

會印出正解 `curl -fsSL dot.bitpod.cc | sh`（純提醒、不執行任何動作）。

> **Cloudflare 設定**：
> - `dot.bitpod.cc` 302 redirect 至
>   `https://raw.githubusercontent.com/jjshen-eland/dotfiles/main/bootstrap.sh`（安裝器）
> - `help.bitpod.cc` 由 Cloudflare Worker 回傳純文字提醒（腳本見 `docs/cloudflare-help-worker.js`）

### macOS（已有 repo）

```bash
# 開發工具環境
./setup-mac-env.sh

# macOS 系統偏好設定（選用，可獨立執行）
./write-mac-defaults.sh
```

### Linux Ubuntu（已有 repo）

```bash
chmod +x setup-linux-env.sh
./setup-linux-env.sh
```

## 功能特色

- **工具分層**：預設 core 支援 Codex／Claude Code；`-p workstation` 加裝互動式便利工具
- **Homebrew 統一管理**：macOS 和 Linux 都透過 Homebrew 安裝工具，來源一致；版本依主機與專案需求管理
- **智能 PATH 管理**：自動統合、去重、依優先級排序
- **既有主機對齊**：有工具歸屬紀錄、預演與檢查；不必重跑完整 setup
- **跨平台一致**：macOS (zsh) 和 Linux (bash) 使用相同工具和別名

## 使用者自訂設定

腳本會建立 `.local` 檔案來保留使用者設定：

| 平台 | 個人設定檔 | 個人 PATH |
|------|-----------|-----------|
| macOS | `~/.zshrc.local` | `~/.zprofile.local` |
| Linux | `~/.bashrc.local` | `~/.bash_profile.local` |

這些檔案不會被覆寫，重複執行腳本時設定會保留。

## PATH 優先級

`shell/environment.sh` 共用於 Bash／Zsh：保留既有非系統 PATH 的順序（包括啟用中的
venv、mise、nvm 等），再補 `~/.local/bin`、`~/.bun/bin`、`~/.npm-global/bin`、
`~/.cargo/bin`、`~/go/bin`、Homebrew 與可用的 CUDA，最後是系統目錄；移除重複與空項。
不在每次 shell 啟動呼叫 brew，也不在非互動 shell 載入 prompt／fzf／direnv hook。

Bash 的普通 `bash -c` 不讀 `.bashrc`；Codex／Claude Code 可明示使用
`~/.dotfiles/scripts/dev-env.sh <command> [args...]` 取得相同 fallback。
專案環境仍依 repo 指令啟用，例如 `uv run`、`mise exec --` 或已授權的 `direnv exec .`；
不設定全域 `BASH_ENV`，不自動信任 `.envrc`。個人 startup 設定仍可覆寫 PATH。

## 安裝的工具

唯一清單是 [dev-tools.tsv](scripts/dev-tools.tsv)。setup 預設 `core`；加上 `-p workstation`
會包含 core 與 workstation。已有健康可用的同名能力不強制換安裝來源。

| 分層 | 工具與用途 |
|------|------------|
| core | git、gh、Node、Bun、Python 3.11+、uv、jq、Mike Farah yq、ripgrep、fd、ShellCheck、actionlint、ast-grep、hyperfine、direnv、just、tmux、lftp、rsync、git-delta、Codex、Claude Code |
| workstation | wget、htop、tree、HTTPie、bat、fzf、eza、zoxide、tlrc、tokei、sd、lazygit、dust、watchexec、shfmt |
| 專案選用 | SwiftLint、xcbeautify、Antigravity CLI、mise；Ruff／Playwright 依專案安裝及鎖版 |

新增 actionlint 檢查 workflow、ast-grep 做結構化搜尋；使用完整 `ast-grep` 命令，避免 Linux 的
`sg` 同名問題。git-delta 保留 core，因共用 Git 設定會呼叫它。
Claude Code 使用官方原生 installer，Codex 使用 Homebrew cask。
macOS 若僅有過舊的系統 Python，setup 會另裝 Homebrew `python` 並讓 fallback PATH 使用新版；
不修改 Apple 的 `/usr/bin/python3`。3.11 是本 repo 使用標準庫 `tomllib` 的最低門檻，
安裝目標仍是 Homebrew 提供的當前 `python`，不是鎖定 3.11。自行管理的 Python／專案 venv
保留優先權，版本不符則回報，不自動升級。

JavaScript／TypeScript 新專案預設 Bun，Python 新專案預設 uv。既有專案遵守其 lockfile、
`packageManager` 與 runtime 版本；npm／pnpm／yarn／Node 都是有效選項，不另外產生第二種 lockfile。

## 既有主機工具對齊

更新邊界是「setup 納管」與「本機自行管理」；工具集合對齊不等於全面升級版本。
來源合併至 `origin/main`、同步到目標主機後，在該主機執行：

```bash
~/.dotfiles/scripts/align-dev-environment.sh plan
# 確認列出的安裝／移除／shell 變更後，使用相同參數 apply
~/.dotfiles/scripts/align-dev-environment.sh apply
~/.dotfiles/scripts/align-dev-environment.sh check
```

- `plan` 不寫設定、不安裝／移除；列出 `UNMANAGED`、缺項與 `REMOVE_MANAGED`。
  `check` 遇到缺項、失效工具或待移除納管項目回傳非零。安裝失敗也必須非零。
- 新安裝的直接工具記錄在 `~/.local/state/dotfiles/tools.tsv`，保存 profile 與本機保留項目。
  預設沿用已存 profile；只有明示 `--profile core|workstation` 才切換。
- **舊 setup 沒有可靠的逐台歸屬紀錄**。既有工具預設不接管；首次須核對 `plan` 與本機用途，
  用重複的 `--adopt <package>` 明示接管原 setup 工具；`--keep <package>` 永久保留為本機工具。
  名稱用清單中的 package 欄，例如 `ripgrep`、`git-delta`、`oven-sh/bun/bun`。
  未確認歸屬的工具保留，不宣稱舊清單已完全收斂。
- 例如 `plan --profile core --adopt tree --keep fzf` 會預告移除已確認屬於舊 setup 的 tree，
  並保留主機工作需要的 fzf；檢視後以相同參數 `apply`，再無參數 `check`。
  setup 工具若也被個人工作依賴，先 `--keep`；無法自動推論 shell script 的依賴。
- 只移除已記錄且不在選定清單的直接套件，不用 `--force`、`--ignore-dependencies`、
  `autoremove` 或 `bundle cleanup`。Homebrew 依賴阻擋移除時保留並回報。
  不做全面 upgrade；僅已納管且能力檢查失敗的工具可具名升級。
  若安裝／具名升級需要改動既有 Homebrew 相依套件則停止該項。
  套件安裝可能部分完成；修正原因後可重跑，紀錄成功項目，沒有全機交易回滾。
- shell 對齊只在 `.zshenv`／`.bashrc` 接上共用環境，保留個人內容並留下
  `.bashrc.dotfiles-backup-*`／`.zshenv.dotfiles-backup-*` 備份；修改過的管理區塊、symlink 或語法錯誤會阻擋。
  需要回復時先檢視對應備份與現檔差異，再還原該檔；工具移除不會自動回滾。

14 台採先盤點、核對歸屬，再各選一台 macOS／Linux 試跑，驗證 Codex／Claude Code 子命令
可找到工具且本機專案照常執行，最後分批處理其餘主機。每台保存 revision、plan、apply／check
exit code；未連線或未確認歸屬者標記待完成。本批不透過 `dotsync` 自動安裝或移除套件。
`brewup` 仍是原有的全面版本更新命令，會升級自行安裝的套件；**不要用它執行這次有界對齊**。

### 便捷別名

```bash
# 檔案列表
ll    # eza -l
la    # eza -la
lt    # eza --tree

# Git
gs    # git status
gd    # git diff
ga    # git add
gc    # git commit
gp    # git push
gl    # git pull

# 系統更新
brewup  # macOS/Linux: brew update && upgrade + dotfiles pull + Claude plugins + bun update -g
sysup   # Linux: apt update && upgrade && autoremove
```

### fzf 快捷鍵

- `Ctrl+R` - 搜尋命令歷史
- `Ctrl+T` - 搜尋檔案
- `Alt+C` - 切換目錄

## 注意事項

1. **原生命令保留**：`ls`, `cat`, `find`, `grep` 仍可使用
2. **Linux fd/bat 別名**：保留 fallback alias（`fdfind` → `fd`, `batcat` → `bat`），但 Homebrew 安裝的是原名，不會觸發
3. **需要新終端**：執行腳本後，開啟新終端視窗以啟用配置

## Claude Code 整合

setup 腳本會安裝 Claude Code（官方安裝腳本）與 Codex（Homebrew cask）。執行腳本後，Claude Code 會自動讀取 `CLAUDE.md` 了解環境中可用的工具。

## Codex 整合

執行 `setup-mac-env.sh` 或 `setup-linux-env.sh` 時，會將 `claude/` 與 `codex/` 內的共用設定同步到對應的 home 目錄。

- Claude：同步到 `~/.claude/`
- Codex：同步到 `~/.codex/`

其中 `~/.codex/config.local.toml` 保留本機相依設定，不納入版控。
Skills、個人 rules 與 handoff 的正式位置，以及既有機器的安全遷移／回復用法，見
[Runtime 正式結構與遷移](docs/repo-guide.md#runtime-正式結構與遷移)。setup、dotsync 與 brewup 共用入口。

## Turbo 自主執行

在 Codex 對話中輸入下列指令；Claude Code 把 `$turbo` 換成 `/turbo`。這是 skill 對話指令，
不是 shell command。不知道有哪些選項時，輸入 `$turbo help` 或 `$turbo --help`。

| 指令 | 功能 |
| --- | --- |
| `$turbo help`／`$turbo --help` | 顯示命令、參數與範例；不啟用或改變授權 |
| `$turbo on [PLAN.md] [--allow actions]` | 啟用並接續計畫審查、實作與驗證；缺少可確認目標時等待任務 |
| `$turbo off` | 撤銷之後的自動續跑 |
| `$turbo status`／`$turbo` | 查模式、目標、目前授權、進度與阻擋原因 |

`PLAN.md` 是可省略的計畫路徑；範例中的方括號表示可選，不要照打。
`--allow` 可用值為 `commit,push,pr,merge`，以逗號分隔。它設定當次目標可選的交付動作，
不是要求每個動作都必須執行；精確分派依下方 shipping authority。

```text
$turbo on PLAN.md
$turbo on PLAN.md --allow commit
$turbo on PLAN.md --allow commit,push,pr
$turbo on PLAN.md --allow commit,push,pr,merge
```

依序為沒有新增交付授權、允許本地 commit、最多到 PR、允許 agent 視需要 merge。
重複 on 不擴大授權或重設額度；更改集合需先 off，再以新 on 明列。
On／status 回覆會列目前授權並提示 help。重新開啟／resume 的 session 預設 off。
Spec／計畫格式見 [Turbo execution contract](shared/skills/turbo/references/execution-contract.md)。

要委任 agent 選擇交付動作，啟動時明列 `--allow commit,push,pr,merge`；終點及必要 gate 依
[Project 唯一授權表](shared/skills/project/references/ship-policy.md)。只有 on 不授權送出。
無人值守另需選定 [permission profile](shared/skills/turbo/references/permissions.md) 並確認 hooks
已載入／受信任；skill 開關不會改動全域 permission，也不能核准 host 的必要人工要求。

目前 native 驗證涵蓋兩端 CLI。交付需保留 runtime 的實際 session transcript；
`--ephemeral`／`--no-session-persistence` 可處理一般目標，但交付會因缺少摘要證據而停下。
Claude 執行中的工具需要先用 host interrupt，再送 `off`；排入輸入佇列的 `off` 不會立即取消工具。
Desktop／IDE／web 的 hook 與權限接點需另外驗證。

## 版本資訊

- **版本**：v5.0
- **更新日期**：2026-10-09
- **支援系統**：macOS (zsh), Ubuntu 24.04+ (bash)
- **套件管理**：Homebrew（兩平台統一）
