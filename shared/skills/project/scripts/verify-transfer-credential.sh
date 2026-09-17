#!/usr/bin/env bash
# Verify only the filesystem/Git metadata of one repo-local credential artifact.
# Never read or print the artifact's contents.

set -u

usage() {
    echo "usage: verify-transfer-credential.sh <repo> <repo-relative-artifact>" >&2
    echo "verdict: BROKEN"
    exit 2
}

stop() {
    printf 'artifact: %s\n' "$artifact_rel"
    [ -n "${mode:-}" ] && printf 'mode: %s\n' "$mode"
    printf 'reason: %s\n' "$1"
    echo "verdict: STOP"
    exit 1
}

[ "$#" -eq 2 ] || usage
repo_arg="$1"
artifact_rel="$2"

repo="$(git -C "$repo_arg" rev-parse --show-toplevel 2>/dev/null)" || {
    echo "reason: repository-unavailable"
    echo "verdict: BROKEN"
    exit 2
}
repo="$(CDPATH='' cd -- "$repo" && pwd -P)" || {
    echo "reason: repository-unresolvable"
    echo "verdict: BROKEN"
    exit 2
}

case "$artifact_rel" in
    ''|/*|~*|*$'\n'*|*$'\r'*|*$'\t'*) stop "artifact-path-invalid" ;;
esac

candidate="$repo/$artifact_rel"
[ ! -L "$candidate" ] || stop "artifact-is-symlink"
[ -e "$candidate" ] || stop "artifact-missing"
[ -f "$candidate" ] || stop "artifact-not-regular-file"

parent="$(CDPATH='' cd -- "$(dirname -- "$candidate")" && pwd -P)" || stop "artifact-parent-unresolvable"
artifact_abs="$parent/$(basename -- "$candidate")"
case "$artifact_abs" in
    "$repo"/*) ;;
    *) stop "artifact-outside-repository" ;;
esac
artifact_rel="${artifact_abs#"$repo"/}"

if git -C "$repo" ls-files --error-unmatch -- "$artifact_rel" >/dev/null 2>&1; then
    stop "artifact-is-tracked"
fi
git -C "$repo" check-ignore -q -- "$artifact_rel" || stop "artifact-is-not-ignored"

mode="$(stat -f '%Lp' "$artifact_abs" 2>/dev/null || stat -c '%a' "$artifact_abs" 2>/dev/null)" || {
    echo "artifact: $artifact_rel"
    echo "reason: mode-unavailable"
    echo "verdict: BROKEN"
    exit 2
}
case "$mode" in
    [0-7][0-7][0-7]) ;;
    [0-7][0-7][0-7][0-7]) mode="${mode#?}" ;;
    *)
        echo "artifact: $artifact_rel"
        echo "reason: mode-malformed"
        echo "verdict: BROKEN"
        exit 2
        ;;
esac

case "$mode" in
    [0-7]00) ;;
    *) stop "group-or-other-permissions-present" ;;
esac

printf 'artifact: %s\n' "$artifact_rel"
echo "tracked: no"
echo "ignored: yes"
echo "symlink: no"
printf 'mode: %s\n' "$mode"
echo "verdict: PASS"
