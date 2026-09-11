#!/usr/bin/env bash

set -euo pipefail

EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904

usage() {
    cat >&2 <<'EOF'
usage:
  review-scope.sh capture --repo <path> --mode <working-tree|branch|range|audit> [--base <ref>] [--range <a>..<b>] [--path <relative-path>]...
  review-scope.sh verify --manifest <directory>
  review-scope.sh autofix-check --manifest <directory>
  review-scope.sh show --manifest <directory>
EOF
    exit 2
}

hash_file() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        echo "error: shasum or sha256sum is required" >&2
        return 1
    fi
}

read_value() {
    local manifest="$1" key="$2"
    [ -f "$manifest/$key" ] || {
        echo "error: invalid manifest (missing $key): $manifest" >&2
        return 1
    }
    sed -n '1p' "$manifest/$key"
}

validate_manifest() {
    local manifest="$1"
    [ -d "$manifest" ] || {
        echo "error: manifest is not a directory: $manifest" >&2
        return 1
    }
    [ "$(read_value "$manifest" version)" = "2" ] || {
        echo "error: unsupported manifest version: $manifest" >&2
        return 1
    }
    [ -f "$manifest/paths.nul" ] && [ -f "$manifest/subjects.nul" ] \
        && [ -f "$manifest/guidance.nul" ] || {
        echo "error: incomplete manifest: $manifest" >&2
        return 1
    }
}

validate_pathspec() {
    case "$1" in
        ""|/*|..|../*|*/../*|*/..)
            echo "error: --path must stay inside the repository: $1" >&2
            return 1
            ;;
    esac
}

load_paths() {
    local paths_file="$1"
    PATHS=()
    while IFS= read -r -d '' item; do PATHS+=("$item"); done < "$paths_file"
}

append_paths() {
    local payload="$1" item
    printf '%s\0' paths >> "$payload"
    for item in "${PATHS[@]+"${PATHS[@]}"}"; do printf '%s\0' "$item" >> "$payload"; done
}

append_untracked() {
    local repo="$1" payload="$2" list_file file digest
    list_file="$(mktemp "${TMPDIR:-/tmp}/deep-review-untracked.XXXXXX")"
    if [ "${#PATHS[@]}" -gt 0 ]; then
        git -C "$repo" ls-files -z --others --exclude-standard -- "${PATHS[@]}" > "$list_file"
    else
        git -C "$repo" ls-files -z --others --exclude-standard > "$list_file"
    fi
    while IFS= read -r -d '' file; do
        if [ -L "$repo/$file" ]; then
            digest="link:$(readlink "$repo/$file")"
        elif [ -f "$repo/$file" ]; then
            digest="file:$(hash_file "$repo/$file")"
        else
            digest=other
        fi
        printf '%s\0%s\0' "$file" "$digest" >> "$payload"
    done < "$list_file"
    rm -f "$list_file"
}

path_is_selected() {
    local candidate="$1" selected
    [ "${#PATHS[@]}" -eq 0 ] && return 0
    for selected in "${PATHS[@]+"${PATHS[@]}"}"; do
        case "$candidate" in "$selected"|"$selected"/*) return 0 ;; esac
    done
    return 1
}

build_subjects() {
    local repo="$1" mode="$2" base="$3" head="$4" output="$5" tmp item
    tmp="$(mktemp "${TMPDIR:-/tmp}/deep-review-subjects.XXXXXX")"
    : > "$tmp"
    case "$mode" in
        range)
            if [ "${#PATHS[@]}" -gt 0 ]; then
                git -C "$repo" diff --name-only -z "$base" "$head" -- "${PATHS[@]}" > "$tmp"
            else
                git -C "$repo" diff --name-only -z "$base" "$head" > "$tmp"
            fi
            ;;
        working-tree)
            if [ "${#PATHS[@]}" -gt 0 ]; then
                git -C "$repo" diff --name-only -z "$head" -- "${PATHS[@]}" >> "$tmp"
                git -C "$repo" ls-files -z --others --exclude-standard -- "${PATHS[@]}" >> "$tmp"
            else
                git -C "$repo" diff --name-only -z "$head" >> "$tmp"
                git -C "$repo" ls-files -z --others --exclude-standard >> "$tmp"
            fi
            ;;
        branch)
            if [ "${#PATHS[@]}" -gt 0 ]; then
                git -C "$repo" diff --name-only -z "$base" -- "${PATHS[@]}" >> "$tmp"
                git -C "$repo" ls-files -z --others --exclude-standard -- "${PATHS[@]}" >> "$tmp"
            else
                git -C "$repo" diff --name-only -z "$base" >> "$tmp"
                git -C "$repo" ls-files -z --others --exclude-standard >> "$tmp"
            fi
            ;;
        audit) git -C "$repo" ls-files -z --cached --others --exclude-standard > "$tmp" ;;
        *) return 1 ;;
    esac
    : > "$output"
    while IFS= read -r -d '' item; do
        path_is_selected "$item" && printf '%s\0' "$item" >> "$output"
    done < "$tmp"
    rm -f "$tmp"
}

guidance_applies() {
    local candidate="$1" subjects="$2" mode="$3" directory subject selected
    case "$candidate" in */*) directory="${candidate%/*}" ;; *) directory="" ;; esac
    [ -z "$directory" ] && return 0
    while IFS= read -r -d '' subject; do
        case "$subject" in "$directory"|"$directory"/*) return 0 ;; esac
    done < "$subjects"
    if [ "$mode" = audit ]; then
        [ "${#PATHS[@]}" -eq 0 ] && return 0
        for selected in "${PATHS[@]+"${PATHS[@]}"}"; do
            case "$directory" in
                "$selected"|"$selected"/*) return 0 ;;
                *) case "$selected" in "$directory"|"$directory"/*) return 0 ;; esac ;;
            esac
        done
    fi
    return 1
}

build_guidance() {
    local repo="$1" source="$2" head="$3" mode="$4" subjects="$5" output="$6"
    local candidates candidate basename object
    candidates="$(mktemp "${TMPDIR:-/tmp}/deep-review-guidance-candidates.XXXXXX")"
    if [ "$source" = head ]; then
        git -C "$repo" ls-tree -r --name-only -z "$head" > "$candidates"
    else
        git -C "$repo" ls-files -z --cached --others --exclude-standard > "$candidates"
    fi
    : > "$output"
    while IFS= read -r -d '' candidate; do
        basename="${candidate##*/}"
        case "$basename" in AGENTS.md|CLAUDE.md) ;; *) continue ;; esac
        guidance_applies "$candidate" "$subjects" "$mode" || continue
        if [ "$source" = head ]; then
            object="$(git -C "$repo" rev-parse --verify "$head:$candidate" 2>/dev/null)" || {
                echo "error: cannot resolve historical guidance: $candidate" >&2
                return 1
            }
        else
            [ -f "$repo/$candidate" ] || continue
            object="$(git hash-object -- "$repo/$candidate")"
        fi
        printf '%s\0%s\0%s\0' "$source" "$candidate" "$object" >> "$output"
    done < "$candidates"
    rm -f "$candidates"
}

compute_fingerprint() {
    local repo="$1" mode="$2" base="$3" head="$4" guidance="$5" subjects="$6" output="$7"
    local payload status_file
    payload="$(mktemp "${TMPDIR:-/tmp}/deep-review-payload.XXXXXX")"
    status_file="$(mktemp "${TMPDIR:-/tmp}/deep-review-status.XXXXXX")"
    {
        printf 'mode\0%s\0base\0%s\0head\0%s\0' "$mode" "$base" "$head"
        append_paths /dev/stdout
        printf 'subjects\0'; cat "$subjects"
        printf 'guidance\0'; cat "$guidance"
    } > "$payload"
    case "$mode" in
        range)
            if [ "${#PATHS[@]}" -gt 0 ]; then
                git -C "$repo" diff --binary --no-ext-diff "$base" "$head" -- "${PATHS[@]}" >> "$payload"
            else
                git -C "$repo" diff --binary --no-ext-diff "$base" "$head" >> "$payload"
            fi
            ;;
        working-tree|branch|audit)
            if [ "${#PATHS[@]}" -gt 0 ]; then
                git -C "$repo" status --porcelain=v2 -z --untracked-files=all -- "${PATHS[@]}" > "$status_file"
                git -C "$repo" diff --binary --no-ext-diff "$base" -- "${PATHS[@]}" >> "$payload"
            else
                git -C "$repo" status --porcelain=v2 -z --untracked-files=all > "$status_file"
                git -C "$repo" diff --binary --no-ext-diff "$base" >> "$payload"
            fi
            cat "$status_file" >> "$payload"
            append_untracked "$repo" "$payload"
            ;;
        *) rm -f "$payload" "$status_file"; return 1 ;;
    esac
    hash_file "$payload" > "$output"
    rm -f "$payload" "$status_file"
}

capture() {
    local repo="" mode="" base_ref="" range="" manifest root base head path_arg
    local base_type base_is_ancestor merge_base baseline head_is_current branch guidance_source
    local subjects guidance
    PATHS=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --repo) [ "$#" -ge 2 ] || usage; repo="$2"; shift 2 ;;
            --mode) [ "$#" -ge 2 ] || usage; mode="$2"; shift 2 ;;
            --base) [ "$#" -ge 2 ] || usage; base_ref="$2"; shift 2 ;;
            --range) [ "$#" -ge 2 ] || usage; range="$2"; shift 2 ;;
            --path) [ "$#" -ge 2 ] || usage; validate_pathspec "$2"; PATHS+=("$2"); shift 2 ;;
            *) usage ;;
        esac
    done
    [ -n "$repo" ] && [ -n "$mode" ] || usage
    root="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" || {
        echo "error: not a Git repository: $repo" >&2; exit 3;
    }
    root="$(CDPATH='' cd -- "$root" && pwd -P)"
    head="$(git -C "$root" rev-parse --verify 'HEAD^{commit}')"
    case "$mode" in
        working-tree|audit) [ -z "$base_ref$range" ] || usage; base="$head" ;;
        branch)
            [ -n "$base_ref" ] && [ -z "$range" ] || usage
            base="$(git -C "$root" merge-base "$base_ref" "$head" 2>/dev/null)" || {
                echo "error: cannot establish merge base for $base_ref and HEAD" >&2; exit 4;
            }
            ;;
        range)
            [ -n "$range" ] && [ -z "$base_ref" ] || usage
            case "$range" in *...*) echo "error: use an explicit two-endpoint range (a..b), not three-dot" >&2; exit 4 ;; esac
            case "$range" in *..*) ;; *) echo "error: --range must be a..b" >&2; exit 4 ;; esac
            base_ref="${range%%..*}"; path_arg="${range#*..}"
            [ -n "$base_ref" ] && [ -n "$path_arg" ] && [ "$path_arg" != "$range" ] || {
                echo "error: --range must contain two non-empty endpoints" >&2; exit 4;
            }
            base="$(git -C "$root" rev-parse --verify "$base_ref^{object}" 2>/dev/null)" || {
                echo "error: invalid range base: $base_ref" >&2; exit 4;
            }
            head="$(git -C "$root" rev-parse --verify "$path_arg^{commit}" 2>/dev/null)" || {
                echo "error: invalid range head: $path_arg" >&2; exit 4;
            }
            ;;
        *) usage ;;
    esac
    base_type="$(git -C "$root" cat-file -t "$base" 2>/dev/null)" || exit 4
    case "$base_type" in commit|tree) ;; *) echo "error: range base must be a commit or tree" >&2; exit 4 ;; esac
    baseline=no; [ "$base" = "$EMPTY_TREE" ] && baseline=yes
    if [ "$base_type" = commit ]; then
        if git -C "$root" merge-base --is-ancestor "$base" "$head" 2>/dev/null; then
            base_is_ancestor=yes; merge_base=n/a
        else
            base_is_ancestor=no
            merge_base="$(git -C "$root" merge-base "$base" "$head" 2>/dev/null || true)"
            [ -n "$merge_base" ] || merge_base='(none)'
        fi
    elif [ "$baseline" = yes ]; then
        base_is_ancestor=yes; merge_base=n/a
    else
        base_is_ancestor=n/a; merge_base=n/a
    fi
    if [ "$(git -C "$root" rev-parse --verify 'HEAD^{commit}')" = "$head" ]; then head_is_current=yes; else head_is_current=no; fi
    branch="$(git -C "$root" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"; [ -n "$branch" ] || branch='(detached)'
    if [ "$mode" = range ]; then guidance_source="head"; else guidance_source="worktree"; fi

    manifest="$(mktemp -d "${TMPDIR:-/tmp}/deep-review-scope.XXXXXX")"
    subjects="$(mktemp "${TMPDIR:-/tmp}/deep-review-subject-list.XXXXXX")"
    guidance="$(mktemp "${TMPDIR:-/tmp}/deep-review-guidance-list.XXXXXX")"
    build_subjects "$root" "$mode" "$base" "$head" "$subjects"
    build_guidance "$root" "$guidance_source" "$head" "$mode" "$subjects" "$guidance"
    printf '%s\n' 2 > "$manifest/version"
    printf '%s\n' "$root" > "$manifest/repo"; printf '%s\n' "$mode" > "$manifest/mode"
    printf '%s\n' "$base" > "$manifest/base"; printf '%s\n' "$head" > "$manifest/head"
    printf '%s\n' "$base_type" > "$manifest/base-type"; printf '%s\n' "$base_is_ancestor" > "$manifest/base-is-ancestor"
    printf '%s\n' "$merge_base" > "$manifest/merge-base"; printf '%s\n' "$baseline" > "$manifest/baseline"
    printf '%s\n' "$head_is_current" > "$manifest/head-is-current"; printf '%s\n' "$branch" > "$manifest/branch"
    printf '%s\n' "$guidance_source" > "$manifest/guidance-source"
    printf '%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$manifest/created-at"
    : > "$manifest/paths.nul"; for path_arg in "${PATHS[@]+"${PATHS[@]}"}"; do printf '%s\0' "$path_arg" >> "$manifest/paths.nul"; done
    cp "$subjects" "$manifest/subjects.nul"; cp "$guidance" "$manifest/guidance.nul"
    compute_fingerprint "$root" "$mode" "$base" "$head" "$guidance" "$subjects" "$manifest/fingerprint"
    rm -f "$subjects" "$guidance"
    printf 'manifest: %s\nrepo: %s\nmode: %s\nbase: %s\nhead: %s\n' "$manifest" "$root" "$mode" "$base" "$head"
    printf 'base-type: %s\nbase-is-ancestor: %s\nmerge-base: %s\n' "$base_type" "$base_is_ancestor" "$merge_base"
    printf 'baseline: %s\nhead-is-current: %s\nbranch: %s\nguidance-source: %s\n' "$baseline" "$head_is_current" "$branch" "$guidance_source"
    printf 'fingerprint: %s\n' "$(read_value "$manifest" fingerprint)"
}

verify() {
    local manifest="$1" repo mode base head source actual current_head subjects guidance
    validate_manifest "$manifest"
    repo="$(read_value "$manifest" repo)"; mode="$(read_value "$manifest" mode)"
    base="$(read_value "$manifest" base)"; head="$(read_value "$manifest" head)"
    source="$(read_value "$manifest" guidance-source)"; load_paths "$manifest/paths.nul"
    current_head="$(git -C "$repo" rev-parse --verify 'HEAD^{commit}' 2>/dev/null)" || {
        echo "verdict: BLOCKED"; echo "reason: repository or HEAD is unavailable"; return 5;
    }
    if [ "$mode" != range ] && [ "$current_head" != "$head" ]; then
        echo "verdict: BLOCKED"; echo "reason: HEAD drifted from $head to $current_head"; return 5
    fi
    if ! git -C "$repo" cat-file -e "$base^{object}" 2>/dev/null || ! git -C "$repo" cat-file -e "$head^{commit}" 2>/dev/null; then
        echo "verdict: BLOCKED"; echo "reason: an immutable endpoint is no longer available"; return 5
    fi
    subjects="$(mktemp "${TMPDIR:-/tmp}/deep-review-verify-subjects.XXXXXX")"
    guidance="$(mktemp "${TMPDIR:-/tmp}/deep-review-verify-guidance.XXXXXX")"
    build_subjects "$repo" "$mode" "$base" "$head" "$subjects"
    build_guidance "$repo" "$source" "$head" "$mode" "$subjects" "$guidance" || {
        rm -f "$subjects" "$guidance"; echo "verdict: BLOCKED"; echo "reason: applicable guidance cannot be re-established"; return 5;
    }
    if ! cmp -s "$manifest/subjects.nul" "$subjects" || ! cmp -s "$manifest/guidance.nul" "$guidance"; then
        rm -f "$subjects" "$guidance"; echo "verdict: BLOCKED"; echo "reason: review subjects or applicable guidance drifted"; return 5
    fi
    actual="$(mktemp "${TMPDIR:-/tmp}/deep-review-verify.XXXXXX")"
    compute_fingerprint "$repo" "$mode" "$base" "$head" "$guidance" "$subjects" "$actual"
    rm -f "$subjects" "$guidance"
    if [ "$(read_value "$manifest" fingerprint)" != "$(sed -n '1p' "$actual")" ]; then
        rm -f "$actual"; echo "verdict: BLOCKED"; echo "reason: review scope content or index state drifted"; return 5
    fi
    rm -f "$actual"; echo "verdict: FRESH"; echo "manifest: $manifest"
}

autofix_check() {
    local manifest="$1" repo head base_type base_is_ancestor baseline current branch
    validate_manifest "$manifest"
    if ! verify "$manifest" >/dev/null; then
        echo 'autofix-safe: no'; echo 'autofix-reason: scope-drift'; return 5
    fi
    repo="$(read_value "$manifest" repo)"; head="$(read_value "$manifest" head)"
    base_type="$(read_value "$manifest" base-type)"; base_is_ancestor="$(read_value "$manifest" base-is-ancestor)"
    baseline="$(read_value "$manifest" baseline)"; current="$(git -C "$repo" rev-parse --verify 'HEAD^{commit}')"
    branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
    if [ "$current" != "$head" ]; then echo 'autofix-safe: no'; echo 'autofix-reason: requested-head-not-current'; return 5; fi
    if [ -z "$branch" ]; then echo 'autofix-safe: no'; echo 'autofix-reason: detached-head'; return 5; fi
    if [ "$base_type" = tree ] && [ "$baseline" != yes ]; then echo 'autofix-safe: no'; echo 'autofix-reason: arbitrary-tree-base'; return 5; fi
    if [ "$base_is_ancestor" != yes ]; then echo 'autofix-safe: no'; echo 'autofix-reason: base-not-ancestor'; return 5; fi
    echo 'autofix-safe: yes'; echo 'autofix-reason: structurally-safe'
}

show_manifest() {
    local manifest="$1" key source path object
    validate_manifest "$manifest"
    for key in repo mode base head base-type base-is-ancestor merge-base baseline head-is-current branch guidance-source created-at fingerprint; do
        printf '%s: %s\n' "$key" "$(read_value "$manifest" "$key")"
    done
    load_paths "$manifest/paths.nul"
    if [ "${#PATHS[@]}" -eq 0 ]; then echo "paths: (all)"; else for key in "${PATHS[@]+"${PATHS[@]}"}"; do printf 'path: %s\n' "$key"; done; fi
    while IFS= read -r -d '' source && IFS= read -r -d '' path && IFS= read -r -d '' object; do
        printf 'guidance: %s %s %s\n' "$source" "$object" "$path"
    done < "$manifest/guidance.nul"
}

[ "$#" -gt 0 ] || usage
command="$1"; shift
case "$command" in
    capture) capture "$@" ;;
    verify|autofix-check|show)
        [ "$#" -eq 2 ] && [ "$1" = --manifest ] || usage
        case "$command" in verify) verify "$2" ;; autofix-check) autofix_check "$2" ;; show) show_manifest "$2" ;; esac
        ;;
    *) usage ;;
esac
