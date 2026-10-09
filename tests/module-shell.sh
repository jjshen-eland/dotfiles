#!/usr/bin/env bash
# Public fixture bindings are consumed by dynamically sourced modules.
# shellcheck disable=SC2034
#
set -uo pipefail

# 全域 `core.hooksPath` 生效後，本檔的 74 個 `git init` fixture（含**刻意造在 main 上的
# 誤 commit**）會被 default-branch guard 擋下——連「證明救援路徑有效」的那個 fixture 都造不出來。
# 逃生變數只停用 guard、**不會**跳過 repo 自己的 hook，故不影響任何 chain 相關斷言。
# ⚠️ 第 24 節要測「無變數→擋」的那幾條必須用 `env -u DOTFILES_PRECOMMIT_OFF` 反向解除。
export DOTFILES_PRECOMMIT_OFF=1

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1   # 相對路徑的 source 解析與 git 操作以 repo 根為基準（從外部目錄執行時避免 SC1091 誤報）
# Resolve shared-core symlinks once; distinct runtime wrappers stay in scope.
shopt -s nullglob
if [ "${1:-}" = lint ] || [ "${1:-}" = shell-contract ]; then
gate_file_output="$(python3 "$ROOT/tests/shell-gate-files.py" "$ROOT")" || exit 1
SHELL_GATE_FILES=()
while IFS= read -r gate_file; do
    SHELL_GATE_FILES+=("$gate_file")
done <<< "$gate_file_output"
fi
FIX="$ROOT/tests/fixtures"
# mktemp 失敗必須當場中止：本腳本沒有 set -e，而下面的 `cd "$TMP"` 在 TMP 為空時**回傳 0
# 且不改目錄**，pwd -P 於是交出當下 cwd（第 35 行剛切到 repo 根）——EXIT trap 就會
# `rm -rf` 掉整個 repo。空值 fallback 到 cwd + 破壞性指令，是這裡唯一不能省的檢查。
TMP="$(mktemp -d)" || { echo "mktemp -d 失敗（TMPDIR 不存在或不可寫？）" >&2; exit 1; }
[ -n "$TMP" ] && [ -d "$TMP" ] || { echo "mktemp -d 未產生可用目錄：'${TMP}'" >&2; exit 1; }
# macOS 的 mktemp 給 /var/...（symlink），而腳本的照抄行印 git --show-toplevel 的 realpath
# （/private/var/...）——不正規化，所有「整行照抄」斷言都會因路徑前綴不同而假紅。
TMP="$(cd "$TMP" && pwd -P)"
background_pids=""
# ShellCheck does not treat a trap's function name as a direct invocation.
# shellcheck disable=SC2329
cleanup() {
    for background_pid in $background_pids; do
        kill -0 "$background_pid" >/dev/null 2>&1 && kill "$background_pid" >/dev/null 2>&1
        wait "$background_pid" >/dev/null 2>&1 || true
    done
    rm -rf "$TMP"
}
trap cleanup EXIT

PASS=0
FAIL=0
GITC=(git -c user.name=test -c user.email=test@test -c commit.gpgsign=false)
SS_SCRIPT="$ROOT/claude/skills/project/scripts/ship-state.sh"
RS_SCRIPT="$ROOT/claude/skills/deep-review/scripts/review-state.sh"


ok() { PASS=$((PASS + 1)); echo "  ✅ $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  ❌ $1"; }

# assert_eq <名稱> <期望> <實際>
assert_eq() {
    if [ "$2" = "$3" ]; then ok "$1"; else
        bad "$1"
        echo "     expected: $(printf '%q' "$2")"
        echo "     actual:   $(printf '%q' "$3")"
    fi
}
# assert_rc <名稱> <期望exit> <實際exit>
assert_rc() {
    if [ "$2" -eq "$3" ]; then ok "$1"; else bad "$1（期望 exit=$2，實際 exit=$3）"; fi
}

[ "$#" -eq 1 ] && [ -f "$ROOT/tests/modules/$1.sh" ] || exit 2
# shellcheck disable=SC1090
source "$ROOT/tests/modules/$1.sh"
module_rc=$?
printf 'MODULE_RESULT name=%s pass=%s fail=%s\n' "$1" "$PASS" "$FAIL"
[ "$module_rc" -eq 0 ] && [ "$FAIL" -eq 0 ] && [ "$PASS" -gt 0 ]
