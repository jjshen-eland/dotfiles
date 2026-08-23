#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat >&2 <<'EOF'
usage:
  review-terminal.sh record --repo <path> --reason <token> --head <commit>
  review-terminal.sh clear --repo <path> --base <commit> --head <commit>
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
        awk '!/^terminal_(reason|head|at)=/' "$anchor" > "$tmp"
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
    local repo="$1" base="$2" head="$3" anchor terminal_head tmp
    base="$(git -C "$repo" rev-parse --verify "$base^{commit}" 2>/dev/null)" || {
        echo "error: invalid --base commit" >&2
        return 4
    }
    head="$(git -C "$repo" rev-parse --verify "$head^{commit}" 2>/dev/null)" || {
        echo "error: invalid --head commit" >&2
        return 4
    }
    anchor="$(anchor_path "$repo")" || return $?
    [ -f "$anchor" ] || { echo "terminal: NONE"; return 0; }
    terminal_head="$(sed -n 's/^terminal_head=//p' "$anchor" | head -1)"
    [ -n "$terminal_head" ] || { echo "terminal: NONE"; return 0; }
    if ! git -C "$repo" cat-file -e "$terminal_head^{commit}" 2>/dev/null \
        || ! git -C "$repo" merge-base --is-ancestor "$base" "$terminal_head" 2>/dev/null \
        || ! git -C "$repo" merge-base --is-ancestor "$terminal_head" "$head" 2>/dev/null; then
        echo "terminal: PRESERVED"
        echo "reason: reviewed endpoints do not prove coverage of $terminal_head"
        return 5
    fi
    tmp="$(rewrite_without_terminal "$anchor")"
    if [ -s "$tmp" ]; then
        mv "$tmp" "$anchor"
    else
        rm -f "$tmp" "$anchor"
        rmdir "$(dirname "$anchor")" 2>/dev/null || true
    fi
    echo "terminal: CLEARED"
}

show_terminal() {
    local anchor
    anchor="$(anchor_path "$1")" || return $?
    if [ -f "$anchor" ]; then
        sed -n '/^terminal_\(reason\|head\|at\)=/p' "$anchor"
    else
        echo "terminal: NONE"
    fi
}

[ "$#" -gt 0 ] || usage
command="$1"
shift
repo="" reason="" head="" base=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo) [ "$#" -ge 2 ] || usage; repo="$2"; shift 2 ;;
        --reason) [ "$#" -ge 2 ] || usage; reason="$2"; shift 2 ;;
        --head) [ "$#" -ge 2 ] || usage; head="$2"; shift 2 ;;
        --base) [ "$#" -ge 2 ] || usage; base="$2"; shift 2 ;;
        *) usage ;;
    esac
done
[ -n "$repo" ] || usage

case "$command" in
    record) [ -n "$reason" ] && [ -n "$head" ] && [ -z "$base" ] || usage; record_terminal "$repo" "$reason" "$head" ;;
    clear) [ -n "$base" ] && [ -n "$head" ] && [ -z "$reason" ] || usage; clear_terminal "$repo" "$base" "$head" ;;
    show) [ -z "$reason$head$base" ] || usage; show_terminal "$repo" ;;
    *) usage ;;
esac
