# Codex 全域設定

本目錄是 `~/.codex/` 的 source of truth，只納入可跨 Linux / macOS 共用、可重建的設定。

## 納入版控

- `config.toml`：Codex 共用預設值
- `AGENTS.md`：Codex 個人全域 guidance；setup/dotsync 連結到 `~/.codex/AGENTS.md`
- `rules/`：不含機器路徑的通用核准規則
- `skills/`：團隊共用 skills
- `skill-building-guide.md`：本 dotfiles 的 Codex skill authoring、eval、validation 與發布流程

## 不納入版控

- `auth.json`
- `history.jsonl`
- `sessions/`
- `shell_snapshots/`
- `log/`
- `logs_*.sqlite`
- `state_*.sqlite`
- `models_cache.json`
- 任何機器相依的 project trust 與本機 token

## 本機設定

若需要保留本機專案信任或其他機器相依設定，請放在：

`~/.codex/config.local.toml`

`setup-linux-env.sh` 與 `setup-mac-env.sh` 會：

1. 以 `codex/config.toml` 作為 repo-managed base
2. 從既有 `~/.codex/config.toml` 保留 base／local 未管理的 runtime-only state（例如 project trust）
3. 最後套用 `config.local.toml`，讓明示的本機 override 優先
4. 驗證完整 TOML 後原子更新 `config.toml`；壞輸入、缺 yq 或並行 writer 都保留原檔並回非零

產出檔首行含 helper 使用的 managed-path manifest，讓 local/base 刪除的鍵不會在下次被誤認成
runtime state 而復活；請勿手改該註解。setup、`brewup`、`dotsync` 都呼叫同一支 helper。

## 跨機散佈

setup、brewup 與 dotsync 共用 `scripts/ensure-runtime.sh`，統一 layout 與原 guidance／config helpers。
正式目錄、rules 的個人可寫位置、ownership gates、備份及 recover／rollback 用法見
[Runtime 正式結構與遷移](../docs/repo-guide.md#runtime-正式結構與遷移)。
`ensure-codex-skills.sh` 保留獨立介面與既有行為測試；日常部署採共用 entry 的 migration gate。
