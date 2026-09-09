# 新主機加入開發環境

> 完整流程文件（自 `CLAUDE.md` 抽出，該處留摘要）。單一入口：`scripts/add-new-host.sh`。

## 前提條件（使用者在新主機上已完成）

- `curl -fsSL dot.bitpod.cc | sh`（自動 clone dotfiles + 執行平台對應的 setup script）
- 能從本機 SSH 連線（使用者需先用 `ssh-copy-id` 放臨時公鑰）
- 新主機 IP 需在 `ssh/known_hosts` 的 `@cert-authority` 涵蓋範圍內（`10.10.*.*`、`10.20.*.*`、`10.200.*.*`、`172.17.*.*`、`172.18.*.*`），否則先擴充

> ⚠️ **本流程只適用辦公環境（dev / stage）**。`10.20.*.*` 是租賃機房的生產環境，雖然共用同一個 Host CA，但**不走這支腳本**——Phase B 會把 `id_personal` 與 `id_github_com` 的**私鑰**送到目標主機，而 `id_personal` 的憑證 principals 含 `root`／`admin` 且永不過期。放到對外機房等於單台失陷即可回打整個辦公室機隊與 GitHub org。生產環境的上線流程與分層定義見 `ais-infra` repo。

## 主要流程

在**有 iCloud CA 的管理 Mac** 上，從 `~/.dotfiles` 目錄執行：

```bash
./scripts/add-new-host.sh <alias> <ip>
```

腳本自動完成：

1. **Phase A（metadata）**：驗證 → 寫入 `inventory.conf` → 重生 `ssh/config` → 套用 `~/.ssh/config` → 更新本機 `/etc/hosts`（需 sudo）→ git commit（不 push）
2. **Phase B（金鑰部署 + CA 簽署）**：部署 `id_personal` / `id_github_com` / `authorized_keys` / `ssh/config` / `known_hosts` 到新主機 → `sign-host-keys.sh` → `sign-user-key.sh`

Phase B 結束後，手動完成 Phase C：

```bash
git push
./scripts/dotfiles-sync.sh                      # 同步到所有主機
./scripts/render-etc-hosts.sh --remote <host>   # 更新其他主機 /etc/hosts（每台逐一，選用）
```

## 降級情境：沒 iCloud CA 的 Mac

腳本會偵測到 CA 缺失，只跑 Phase A 並提示：

```
Phase A 已完成。在有 CA 的管理機上執行：
    cd ~/.dotfiles && git pull
    ./scripts/add-new-host.sh --resume <alias>
```

先在無 CA Mac commit + push，再到管理機 `--resume` 接著跑 Phase B。

## 預覽模式

```bash
./scripts/add-new-host.sh --dry-run <alias> <ip>    # 只印出會做什麼，不動檔案
```

## 驗證

- 本機 → 新主機 SSH（cert 認證，不應要求密碼）
- 新主機 → 既有主機 SSH（`ssh <host> "ssh <other_host> hostname"`）
- `/etc/hosts` 解析（`ssh <new_host> "getent hosts <any_host>"`）

## 使用者仍需手動完成

- 新主機上填寫 `~/.env`（API keys 等機密）
- 新主機上設定 git 身分：`cd ~/.dotfiles && ./scripts/setup-git-identity.sh --apply`
  （身分值是機器層的，dotfiles 散佈不過去；沒設就會被 `useConfigOnly` 擋下——那是刻意的，
  總比靜默產出 `<user>@<hostname>` 的假作者好。**不要**直接寫 `~/.gitconfig` 的 `[user] email`，
  它會贏過目錄分界。詳見 `docs/repo-guide.md`「Git 身分與專案目錄分界」）

> **known_hosts 清理**：bootstrap 階段 SSH 連線會在本機 `~/.ssh/known_hosts` 留下個別 host fingerprint。`dotfiles-sync.sh` 會用 repo 的 `ssh/known_hosts`（僅含 `@cert-authority` + GitHub）覆蓋本機和所有遠端主機的 known_hosts，自動清除這些殘留條目。
