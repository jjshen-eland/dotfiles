@AGENTS.md

# Shell 環境配置指引

本檔只保留**本專案的 Claude Code／shell 事實**（工具、腳本、SSH 架構、主機清單）。共同 agent
契約由首行原生 import root `AGENTS.md`；2026-08-24 的 G1c clean-room 五臂各 2/2 驗證 import 與
Claude-specific precedence，且 transcript 零探索。

## 快速安裝

- **macOS 新機**：`curl -fsSL dot.bitpod.cc | sh`（Xcode CLT → clone → setup）
- **macOS 已有 repo**：`./setup-mac-env.sh`
- **macOS 系統偏好**：`./write-mac-defaults.sh`（選用，獨立執行）
- **Linux Ubuntu**：`./setup-linux-env.sh`

## 測試

- 弱模型 skill eval 的沙盒與手動 runner：`claude/evals/README.md`；各情境在 skill 自己的 `evals.md`。
- Claude-specific harness 地雷與已知不對稱仍以各 eval oracle 的當下說明為準；共同 test command 與 gate
  契約已由首行 import 載入，不在本檔重述。

## 重要規則

1. **原生命令未被替換**：`ls`, `cat`, `find`, `grep` 仍可正常使用
2. **不要假設單字母別名**：此環境不使用 `l`, `c` 等別名
3. **Linux 注意**：工具透過 Homebrew 安裝，`fd` 和 `bat` 是原名（保留 fdfind/batcat fallback alias）
4. **PATH 已包含**：`~/.local/bin`（uv、Claude Code 安裝於此）
5. **API Keys**：存放於 `~/.env`（權限 600，會自動載入）
6. **Git 設定**：`~/.gitconfig` 只放機器特定項 ＋ 一行 `include.path` 引入 `git/config`；
   身分走目錄分界（`~/Projects` 公司、`~/SideProjects` 個人、`~/.dotfiles` 工作），
   email 值在機器層的 `~/.gitconfig-work` / `~/.gitconfig-personal`（`scripts/setup-git-identity.sh` 生成，不進 git）。
   **分界外沒有 fallback 身分**——`Author identity unknown` 是刻意擋下，不是故障；詳見 `docs/repo-guide.md`「Git 身分與專案目錄分界」
7. **SSH keys**：`id_github_com`（GitHub 工作＝`github.com` 預設）、`id_personal`（GitHub 個人＝`github-me`，兼 `authorized_keys` fallback）、`id_autogen`（內網 cert）

## 延遲載入的 repo facts

工具、平台、更新同步、SSH 架構、inventory、內網工具與 runtime 詳情見 `docs/repo-guide.md`。
