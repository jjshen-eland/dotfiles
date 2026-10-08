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
├── setup-mac-env.sh       # macOS 開發環境安裝腳本 (v3.1)
├── write-mac-defaults.sh  # macOS 系統偏好設定腳本 (v1.0)
└── setup-linux-env.sh     # Linux Ubuntu 安裝腳本 (v4.0, Homebrew)
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

- **33+ 現代化工具**：eza, bat, fd, ripgrep, fzf, zoxide, git-delta, lazygit, dust, direnv, just, watchexec 等
- **Homebrew 統一管理**：macOS 和 Linux 都透過 Homebrew 安裝工具，版本一致、更新方便
- **智能 PATH 管理**：自動統合、去重、依優先級排序
- **冪等性**：重複執行不會破壞使用者設定
- **跨平台一致**：macOS (zsh) 和 Linux (bash) 使用相同工具和別名

## 使用者自訂設定

腳本會建立 `.local` 檔案來保留使用者設定：

| 平台 | 個人設定檔 | 個人 PATH |
|------|-----------|-----------|
| macOS | `~/.zshrc.local` | `~/.zprofile.local` |
| Linux | `~/.bashrc.local` | `~/.bash_profile.local` |

這些檔案不會被覆寫，重複執行腳本時設定會保留。

## PATH 優先級

從高到低：
1. `~/.local/bin` - 使用者本地程式
2. `~/.bun/bin` - Bun（主要 JS runtime）
3. `~/.npm-global/bin` - npm 全域套件（相容性備用）
4. `~/.cargo/bin` - Cargo (Rust)
5. `~/go/bin` - Go
6. conda/nvm/pyenv 路徑
7. Homebrew 路徑
8. 系統路徑

## 安裝的工具

### 核心工具
git, gh, wget, htop, tree, tmux, bun, node, python3, uv, jq, yq

### 現代化 CLI
| 工具 | 用途 | 取代 |
|------|------|------|
| eza | 彩色檔案列表 | ls |
| bat | 語法高亮檔案查看 | cat |
| fd | 快速檔案搜尋 | find |
| rg (ripgrep) | 快速內容搜尋 | grep |
| fzf | 模糊搜尋 | - |
| zoxide | 智能目錄跳轉 | cd |
| delta | Git diff 美化 | - |
| lazygit | Git TUI 介面 | - |
| dust | 磁碟空間分析 | du |
| direnv | 目錄環境變數自動載入 | - |
| just | 任務執行器 | make |
| watchexec | 檔案變更監控執行 | - |
| lftp | SFTP 傳檔（續傳／mirror／並行） | sftp |

### AI CLI

| 工具 | 安裝方式 | 更新方式 |
|------|----------|----------|
| claude (Claude Code) | 官方安裝腳本 → `~/.local/bin` | `claude update`（`brewup` 已涵蓋） |
| codex (OpenAI Codex) | `brew install --cask codex`（macOS/Linux 皆支援） | `brew upgrade`（`brewup` 已涵蓋） |
| agy (Google Antigravity CLI) | `brew install --cask antigravity-cli`（macOS） | cask 標記 `auto_updates`；`brewup` 不強制 `--greedy` |

`agy` 首次執行需在 Mac console 完成系統核可；遠端或無人值守 setup 不會代替這個互動步驟。

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

- **版本**：v4.0
- **更新日期**：2026-07-07
- **支援系統**：macOS (zsh), Ubuntu 24.04+ (bash)
- **套件管理**：Homebrew（兩平台統一）
