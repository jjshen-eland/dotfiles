#!/usr/bin/env bash
#
# setup-git-identity.sh — 生成機器層的 git 身分檔，讓 dotfiles 的目錄分界規則能生效
#
# 用法：
#   setup-git-identity.sh --check                     # 只報告，零 mutation
#   setup-git-identity.sh [--apply] [--name <n>] [--work-email <e>] [--personal-email <e>]
#
#   預設 **dry-run**（只印計畫），`--apply` 才動手。
#
# exit code：0 = 完成／檢查通過；1 = STOP 或檢查發現問題（零 mutation）；2 = 用法錯誤
#
# 為什麼身分要拆成「共用規則」＋「機器層值」兩層：
#   `git/config` 由 dotfiles 散佈到全機隊，**不能含 email**（那是身分、且兩個身分的值不同）。
#   所以共用層只放 `user.useConfigOnly` 與三條 `includeIf`（指向固定檔名），值由本腳本在
#   各機器生成。兩個檔名是**契約**：改名要同時改 `git/config`。
#
# 為什麼要有這支腳本，而不是叫人自己寫 ~/.gitconfig：
#   1. **漏設是靜默的**。沒有 `useConfigOnly` 時 git 直接用 `<user>@<hostname>` 捏造作者，
#      不報錯、不詢問。本 repo 歷史已有一筆 `jjshen@jjshen-mba.local` 是這樣進來的，
#      而 2026-09-02 盤點時 m4mini 仍處於同一狀態。
#   2. **舊的寫死身分會贏過分界**。`~/.gitconfig` 裡若還留著 `[user] email`，分界**外**的
#      repo 會安靜地用它——那正是這次要消滅的「能動但錯了」。`--apply` 會一併移除它。
#   3. 十幾台機器各手設一次就是十幾次出錯機會。
#
set -uo pipefail

WORK_FILE="${HOME}/.gitconfig-work"
PERSONAL_FILE="${HOME}/.gitconfig-personal"
GLOBAL_FILE="${HOME}/.gitconfig"
SHARED_FILE="${HOME}/.dotfiles/git/config"

# 目錄分界（必須與 git/config 的 includeIf 一致）
WORK_ROOTS=("${HOME}/Projects" "${HOME}/.dotfiles")
PERSONAL_ROOTS=("${HOME}/SideProjects")

if [ -t 1 ]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; BLUE=''; RED=''; NC=''
fi
info() { echo -e "${BLUE}▶${NC} $1"; }
ok()   { echo -e "${GREEN}  ✅${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠️${NC}  $1"; }
err()  { echo -e "${RED}  ❌${NC} $1"; }

die_usage() {
    cat >&2 <<'USAGE'
用法：
  setup-git-identity.sh --check
  setup-git-identity.sh [--apply] [--name <n>] [--work-email <e>] [--personal-email <e>]
USAGE
    exit 2
}
die_stop() { echo "verdict: STOP（$1）"; exit 1; }

APPLY=0
CHECK=0
ARG_NAME=""
ARG_WORK=""
ARG_PERSONAL=""

while [ $# -gt 0 ]; do
    case "$1" in
        --apply)           APPLY=1 ;;
        --check)           CHECK=1 ;;
        --name)            shift; [ $# -gt 0 ] || die_usage; ARG_NAME="$1" ;;
        --work-email)      shift; [ $# -gt 0 ] || die_usage; ARG_WORK="$1" ;;
        --personal-email)  shift; [ $# -gt 0 ] || die_usage; ARG_PERSONAL="$1" ;;
        -h|--help)         die_usage ;;
        *)                 echo "error: 未知參數「$1」" >&2; die_usage ;;
    esac
    shift
done

[ "$CHECK" -eq 1 ] && [ "$APPLY" -eq 1 ] && { echo "error: --check 與 --apply 互斥" >&2; die_usage; }

# 讀某個身分檔的欄位（該檔可能不存在）
read_field() {
    local file="$1" key="$2"
    [ -f "$file" ] || return 0
    git config --file "$file" --get "$key" 2>/dev/null
}

# 讀 ~/.gitconfig 裡**寫死**的身分：在非 repo 的目錄執行，讓所有 gitdir 條件都不命中，
# 於是取回的就是舊的寫死值（沒有則為空）。
read_legacy() {
    local key="$1"
    [ -f "$GLOBAL_FILE" ] || return 0
    (cd / && git config --global --get "$key" 2>/dev/null)
}

# ---------------------------------------------------------------- --check ----
if [ "$CHECK" -eq 1 ]; then
    rc=0
    info "共用規則"
    if [ -f "$SHARED_FILE" ] && grep -q 'useConfigOnly' "$SHARED_FILE"; then
        ok "$SHARED_FILE 已含 useConfigOnly 與 includeIf"
    else
        err "$SHARED_FILE 未含身分規則——先跑 setup-mac-env.sh / setup-linux-env.sh 更新 dotfiles"
        rc=1
    fi
    if (cd / && git config --global --get-all include.path 2>/dev/null) | grep -q 'dotfiles/git/config'; then
        # shellcheck disable=SC2088  # 訊息裡的 ~ 是給人看的字面路徑，實際路徑一律用 ${HOME}
        ok "~/.gitconfig 已 include dotfiles 共用設定"
    else
        # shellcheck disable=SC2088  # 訊息裡的 ~ 是給人看的字面路徑，實際路徑一律用 ${HOME}
        err "~/.gitconfig 沒有 include.path → 共用規則整層沒生效"
        rc=1
    fi

    info "機器層身分檔"
    for pair in "work:$WORK_FILE" "personal:$PERSONAL_FILE"; do
        label="${pair%%:*}"; file="${pair#*:}"
        e="$(read_field "$file" user.email)"
        n="$(read_field "$file" user.name)"
        if [ -n "$e" ] && [ -n "$n" ]; then
            ok "${label}: ${n} <${e}>"
        elif [ -f "$file" ]; then
            err "${label}: ${file} 存在但缺 name 或 email"
            rc=1
        else
            warn "${label}: ${file} 不存在 → 該分界下的 repo 會被 useConfigOnly 擋下"
        fi
    done

    legacy_email="$(read_legacy user.email)"
    legacy_name="$(read_legacy user.name)"
    if [ -n "$legacy_email" ] || [ -n "$legacy_name" ]; then
        # shellcheck disable=SC2088  # 訊息裡的 ~ 是給人看的字面路徑，實際路徑一律用 ${HOME}
        err "~/.gitconfig 仍有寫死身分（name=${legacy_name:-∅} email=${legacy_email:-∅}）"
        echo "     → 分界外的 repo 會安靜地用它。跑 --apply 移除，或："
        echo "       git config --global --unset-all user.email; git config --global --unset-all user.name"
        rc=1
    else
        # shellcheck disable=SC2088  # 訊息裡的 ~ 是給人看的字面路徑，實際路徑一律用 ${HOME}
        ok "~/.gitconfig 無寫死身分（分界外會被擋下，符合設計）"
    fi

    info "各分界的實測解析"
    # ⚠️ 一定要在**真的 repo 裡**問。`includeIf gitdir:` 要有 repo 才會被求值：站在
    # `~/Projects` 這個非 repo 的目錄下問，或用 `GIT_DIR=` 指一個不存在的路徑，
    # 兩者都會回空值——那是「沒有 repo 可判定」，不是「這個分界壞了」。
    probe_root() {
        local root="$1" expect_file="$2" repo="" resolved expected
        [ -d "$root" ] || { printf '  %-28s （目錄不存在）\n' "$root"; return 0; }
        if [ -d "$root/.git" ]; then
            repo="$root"
        else
            for d in "$root"/*/; do
                [ -d "$d/.git" ] || continue
                repo="${d%/}"; break
            done
        fi
        if [ -z "$repo" ]; then
            printf '  %-28s （目前無 repo，未實測；預期 → %s）\n' "$root" "$(basename "$expect_file")"
            return 0
        fi
        resolved="$(git -C "$repo" config --get user.email 2>/dev/null)"
        expected="$(read_field "$expect_file" user.email)"
        if [ -z "$resolved" ]; then
            printf '  %-28s ❌ 被擋下（%s 未設）\n' "$root" "$(basename "$expect_file")"
            rc=1
        elif [ -n "$expected" ] && [ "$resolved" != "$expected" ]; then
            printf '  %-28s ❌ %s（預期 %s）\n' "$root" "$resolved" "$expected"
            rc=1
        else
            printf '  %-28s %s   ← 實測自 %s\n' "$root" "$resolved" "$(basename "$repo")"
        fi
    }
    for root in "${WORK_ROOTS[@]}"; do probe_root "$root" "$WORK_FILE"; done
    for root in "${PERSONAL_ROOTS[@]}"; do probe_root "$root" "$PERSONAL_FILE"; done

    echo "---"
    [ "$rc" -eq 0 ] && echo "verdict: OK" || echo "verdict: 有問題（見上）"
    exit "$rc"
fi

# ---------------------------------------------------------------- 值解析 ----
# 優先序：flag > 既有身分檔 > ~/.gitconfig 的寫死值（僅作 work 預設）> 互動提問
NAME="$ARG_NAME"
[ -n "$NAME" ] || NAME="$(read_field "$WORK_FILE" user.name)"
[ -n "$NAME" ] || NAME="$(read_field "$PERSONAL_FILE" user.name)"
[ -n "$NAME" ] || NAME="$(read_legacy user.name)"

WORK_EMAIL="$ARG_WORK"
[ -n "$WORK_EMAIL" ] || WORK_EMAIL="$(read_field "$WORK_FILE" user.email)"
[ -n "$WORK_EMAIL" ] || WORK_EMAIL="$(read_legacy user.email)"

PERSONAL_EMAIL="$ARG_PERSONAL"
[ -n "$PERSONAL_EMAIL" ] || PERSONAL_EMAIL="$(read_field "$PERSONAL_FILE" user.email)"

if [ -t 0 ]; then
    [ -n "$NAME" ]       || { printf 'git user.name: '; IFS= read -r NAME; }
    [ -n "$WORK_EMAIL" ] || { printf '工作 email: ';    IFS= read -r WORK_EMAIL; }
    if [ -z "$PERSONAL_EMAIL" ]; then
        printf '個人 email（沒有就直接 Enter 跳過）: '
        IFS= read -r PERSONAL_EMAIL
    fi
fi

[ -n "$NAME" ]       || die_stop "缺 user.name——用 --name 指定，或在互動終端執行"
[ -n "$WORK_EMAIL" ] || die_stop "缺工作 email——用 --work-email 指定，或在互動終端執行"

# ---------------------------------------------------------------- 計畫 ----
write_identity_file() {
    local file="$1" label="$2" email="$3"
    umask 077
    cat > "$file" <<EOF
# ${label}身分 —— 由 ~/.dotfiles/git/config 的 includeIf 依目錄自動載入。
# 機器層檔案，**不進 git**；重生成請跑 ~/.dotfiles/scripts/setup-git-identity.sh
[user]
	name = ${NAME}
	email = ${email}
EOF
    chmod 600 "$file"
}

legacy_email="$(read_legacy user.email)"
legacy_name="$(read_legacy user.name)"

info "計畫"
echo "  write: ${WORK_FILE}      ← ${NAME} <${WORK_EMAIL}>"
if [ -n "$PERSONAL_EMAIL" ]; then
    echo "  write: ${PERSONAL_FILE}  ← ${NAME} <${PERSONAL_EMAIL}>"
else
    echo "  skip:  ${PERSONAL_FILE}（未提供個人 email；~/SideProjects 下的 repo 會被擋下）"
fi
if [ -n "$legacy_email" ] || [ -n "$legacy_name" ]; then
    echo "  unset: ~/.gitconfig 的寫死身分（name=${legacy_name:-∅} email=${legacy_email:-∅}）"
fi

if [ "$APPLY" -eq 0 ]; then
    echo "---"
    echo "（dry-run——加 --apply 才實際執行）"
    exit 0
fi

# ---------------------------------------------------------------- 執行 ----
info "執行"
write_identity_file "$WORK_FILE" "工作（work）" "$WORK_EMAIL"
ok "已寫入 ${WORK_FILE}"
if [ -n "$PERSONAL_EMAIL" ]; then
    write_identity_file "$PERSONAL_FILE" "個人（personal）" "$PERSONAL_EMAIL"
    ok "已寫入 ${PERSONAL_FILE}"
fi

if [ -n "$legacy_email" ] || [ -n "$legacy_name" ]; then
    backup="${GLOBAL_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$GLOBAL_FILE" "$backup"
    (cd / && git config --global --unset-all user.email 2>/dev/null)
    (cd / && git config --global --unset-all user.name  2>/dev/null)
    ok "已移除 ~/.gitconfig 的寫死身分（備份：${backup}）"
fi

echo "---"
echo "驗證：$0 --check"
exit 0
