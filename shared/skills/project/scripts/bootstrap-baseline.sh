#!/usr/bin/env bash
#
# bootstrap-baseline.sh — prepare one explicitly selected local baseline ref for an empty remote
#
# Usage: bootstrap-baseline.sh <repo-path> <intended-default> <commit-or-ref>
#
# This helper is the mutation half of Project bootstrap selection. It creates at most one local
# branch ref. It never switches HEAD, changes commits or the working tree, pushes, fetches, or
# changes remote settings. The caller must have obtained the branch name and baseline boundary
# from target authority / the current confirmation UX, then rerun ship-state.sh before any push.

set -uo pipefail

if [ $# -ne 3 ]; then
    echo "用法：$0 <repo-path> <intended-default> <commit-or-ref>" >&2
    exit 2
fi

repo="$1"
default="$2"
candidate="$3"

stop() {
    echo "verdict: STOP（${1}）"
    exit 1
}

if ! git -C "$repo" rev-parse --show-toplevel >/dev/null 2>&1; then
    stop "不是 git repo（或路徑不存在）"
fi
if ! git check-ref-format --branch "$default" >/dev/null 2>&1; then
    echo "用法錯誤：intended default '${default}' 不是合法 branch 名" >&2
    exit 2
fi

remotes="$(git -C "$repo" remote)"
if printf '%s\n' "$remotes" | grep -qx origin; then
    remote=origin
else
    remote="$(printf '%s\n' "$remotes" | head -1)"
fi
[ -n "$remote" ] || stop "無 remote，無法驗證 bootstrap 前提"

heads="$(git -C "$repo" ls-remote --heads "$remote" 2>&1)"
heads_rc=$?
if [ "$heads_rc" -ne 0 ]; then
    stop "ls-remote 失敗 rc=${heads_rc}：$(printf '%s' "$heads" | head -1)"
fi
if [ -n "$heads" ]; then
    heads_n="$(printf '%s\n' "$heads" | wc -l | tr -d ' ')"
    echo "remote-heads: ${heads_n}（確認後 remote 已改變）"
    stop "remote 已非空；baseline selection snapshot 過期，重新執行 ship-state"
fi
echo "remote-heads: 0"

baseline="$(git -C "$repo" rev-parse --verify --end-of-options "${candidate}^{commit}" 2>/dev/null)" || baseline=""
[ -n "$baseline" ] || stop "baseline candidate '${candidate}' 不存在或不是 commit"
head="$(git -C "$repo" rev-parse --verify 'HEAD^{commit}' 2>/dev/null)" || head=""
[ -n "$head" ] || stop "HEAD 尚無 commit，無法驗證 baseline ancestry"
if ! git -C "$repo" merge-base --is-ancestor "$baseline" "$head"; then
    stop "baseline ${baseline} 不是目前 HEAD ${head} 的 ancestor"
fi

if git -C "$repo" show-ref --verify --quiet "refs/heads/$default"; then
    existing="$(git -C "$repo" rev-parse "refs/heads/$default^{commit}" 2>/dev/null)" || existing=""
    if [ "$existing" != "$baseline" ]; then
        stop "local ${default} 已存在於 ${existing:-UNKNOWN}，與明示 baseline ${baseline} 不同；不覆寫 ref"
    fi
    echo "baseline: READY（${default}@${baseline} 已存在；零 mutation）"
    echo "verdict: READY（重跑 ship-state.sh；本 helper 未 push）"
    exit 0
fi

porcelain_before="$(git -C "$repo" status --porcelain)"
branch_before="$(git -C "$repo" symbolic-ref --short -q HEAD)" || branch_before="DETACHED"
git -C "$repo" branch "$default" "$baseline" \
    || stop "建立 local ${default}@${baseline} 失敗；未 push"

porcelain_after="$(git -C "$repo" status --porcelain)"
branch_after="$(git -C "$repo" symbolic-ref --short -q HEAD)" || branch_after="DETACHED"
actual="$(git -C "$repo" rev-parse "refs/heads/$default^{commit}" 2>/dev/null)" || actual=""
if [ "$porcelain_after" != "$porcelain_before" ] || [ "$branch_after" != "$branch_before" ] \
    || [ "$actual" != "$baseline" ]; then
    echo "verdict: STOP（postcondition 失敗：local ${default} 已建立，請人工檢查；未 push）"
    exit 1
fi

echo "baseline: PREPARED（${default}@${baseline}；HEAD 仍在 ${branch_after}；working tree 未動）"
echo "verdict: READY（重跑 ship-state.sh；本 helper 未 push）"
