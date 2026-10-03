#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat >&2 <<'EOF'
usage:
  review-terminal.sh record --repo <path> --reason <token> --head <commit>
  review-terminal.sh clear --repo <path> --state <controller-state>
  review-terminal.sh show --repo <path>
EOF
    exit 2
}

anchor_path() {
    local repo="$1" gitdir
    gitdir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || {
        echo "error: not a Git repository: $repo" >&2
        return 3
    }
    printf '%s/deep-review/anchor\n' "$gitdir"
}

rewrite_without_terminal() {
    local anchor="$1" tmp
    tmp="${anchor}.tmp.$$"
    if [ -f "$anchor" ]; then
        awk '!/^terminal_/' "$anchor" > "$tmp"
    else
        : > "$tmp"
    fi
    printf '%s\n' "$tmp"
}

record_terminal() {
    local repo="$1" reason="$2" head="$3" anchor tmp
    case "$reason" in
        ""|*[!A-Za-z0-9._-]*) echo "error: --reason must be a non-empty token" >&2; return 4 ;;
    esac
    head="$(git -C "$repo" rev-parse --verify "$head^{commit}" 2>/dev/null)" || {
        echo "error: invalid --head commit" >&2
        return 4
    }
    anchor="$(anchor_path "$repo")" || return $?
    mkdir -p "$(dirname "$anchor")"
    tmp="$(rewrite_without_terminal "$anchor")"
    {
        printf 'terminal_reason=%s\n' "$reason"
        printf 'terminal_head=%s\n' "$head"
        printf 'terminal_at=%s\n' "$(date +%s)"
    } >> "$tmp"
    mv "$tmp" "$anchor"
    printf 'terminal: RECORDED\nanchor: %s\nterminal_head: %s\n' "$anchor" "$head"
}

clear_terminal() {
    # Legacy endpoint-only callers cannot prove paths, dirty content or a valid
    # reviewer result. Keep their signal; the controller owns receipt validation.
    echo 'terminal: PRESERVED'
    echo 'reason: a current controller PASS receipt is required; ancestry alone is insufficient'
    return 5
}

show_terminal() {
    local anchor
    anchor="$(anchor_path "$1")" || return $?
    if [ -f "$anchor" ]; then
        sed -nE '/^terminal_(reason|head|at)=/p' "$anchor"
    else
        echo "terminal: NONE"
    fi
}

[ "$#" -gt 0 ] || usage
command="$1"
shift
repo="" reason="" head="" base="" state=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo) [ "$#" -ge 2 ] || usage; repo="$2"; shift 2 ;;
        --reason) [ "$#" -ge 2 ] || usage; reason="$2"; shift 2 ;;
        --head) [ "$#" -ge 2 ] || usage; head="$2"; shift 2 ;;
        --base) [ "$#" -ge 2 ] || usage; base="$2"; shift 2 ;;
        --state) [ "$#" -ge 2 ] || usage; state="$2"; shift 2 ;;
        *) usage ;;
    esac
done
[ -n "$repo" ] || usage

if [ -n "$state" ]; then
    script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
    case "$command" in
        clear) exec python3 "$script_dir/review-control.py" terminal-clear --state "$state" --repo "$repo" ;;
        record) exec python3 "$script_dir/review-control.py" terminal-record --state "$state" --repo "$repo" --reason "$reason" ;;
        *) usage ;;
    esac
fi

case "$command" in
    record) [ -n "$reason" ] && [ -n "$head" ] && [ -z "$base" ] || usage; record_terminal "$repo" "$reason" "$head" ;;
    clear) [ -n "$base" ] && [ -n "$head" ] && [ -z "$reason" ] || usage; clear_terminal "$repo" "$base" "$head" ;;
    show) [ -z "$reason$head$base" ] || usage; show_terminal "$repo" ;;
    *) usage ;;
esac
